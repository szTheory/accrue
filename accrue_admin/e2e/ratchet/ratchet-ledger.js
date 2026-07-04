"use strict";

/**
 * ratchet-ledger.js — shared append/fold helper for the forward-only finding ledger
 * (Phase 206, v1.56). This is the Wave-1 foundation both `ratchet-verify.mjs` (206-02) and
 * `phase-ratchet-ledger.mjs` (206-03) import: neither reimplements the
 * `ratchet-finding-event/1` lifecycle vocabulary, the append-only writer, or the
 * latest-event-wins fold defined here.
 *
 * Identity boundary (DRY, D-10): this module owns lifecycle/fold; `region-tags.js` owns
 * identity. `claim_key`/`finding_id`/`isAdmissibleToken` are imported, never reimplemented.
 *
 * SDK-free by contract: only `node:fs`/`node:os`/`node:path` plus `./region-tags.js` — no
 * network calls, no Anthropic SDK import, so this module's `runSelfTest()` proves DEDUP-03
 * collapse and the seq-monotonic tamper-evidence invariant with no ANTHROPIC_API_KEY.
 *
 * CommonJS (mirrors `region-tags.js`) so it is importable both by the ESM harness
 * (`import * as ledger from "./ratchet-ledger.js"`, cjs-module-lexer interop) and standalone
 * via `node accrue_admin/e2e/ratchet/ratchet-ledger.js` (runs the self-test).
 *
 * Lifecycle vocabulary (D-38): `event ∈ {confirm, resolve, verify-close, suppress, reopen}`
 * sets `status ∈ {open, resolved, verified-closed, suppressed}`. The event log is strictly
 * APPEND-ONLY — one NDJSON row per lifecycle event, monotonic `seq` int, never mutated or
 * deleted. `fold()` is latest-event-wins per `finding_id` in file order and asserts `seq` is
 * strictly increasing across the whole array as tamper-evidence against reorder/insertion
 * (T-206-01-01).
 *
 * Every append helper takes an explicit `ledgerPath` parameter — none hardcodes the real
 * committed `findings.ledger.ndjson` path — so `--self-test` (here and in every downstream
 * consumer) can target an `fs.mkdtempSync` scratch directory and never mutate the real
 * committed ledger.
 */

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { claimKey, findingId, isAdmissibleToken } = require("./region-tags.js");

// -----------------------------------------------------------------------------
// Closed enums (D-24/D-25, D-38, D-41)
// -----------------------------------------------------------------------------

/**
 * LENS_KEYS — the closed 7-value PER-LENS gate key (D-24/D-25, superseding the design
 * doc's earlier `[bucket]` shorthand): the 6 persona IDs from `ratchet-propose.mjs`'s
 * `PERSONAS` array verbatim, plus the bare `"design"` lens.
 */
const LENS_KEYS = [
  "persona:operator-founder",
  "persona:customer-support",
  "persona:finance-billing-ops",
  "persona:recovery-growth-ops",
  "persona:developer-integration",
  "persona:compliance-audit",
  "design",
];

/** EVENT_TYPES — the closed lifecycle event vocabulary (D-38). */
const EVENT_TYPES = ["confirm", "resolve", "verify-close", "suppress", "reopen"];

/** STATUS_VALUES — the closed lifecycle status vocabulary (D-38). */
const STATUS_VALUES = ["open", "resolved", "verified-closed", "suppressed"];

/**
 * SUPPRESSED_REASONS — the closed enum (D-41). `duplicate-of` is stored with a
 * `:<finding_id>` suffix (prefix-matched, like `persona-job-miss:<job>` in
 * `isAdmissibleToken`) rather than as a bare literal — see `isValidSuppressedReason`.
 */
const SUPPRESSED_REASONS = [
  "wont-fix-intentional",
  "duplicate-of",
  "out-of-scope",
  "false-positive",
  "accepted-residual",
  "wont-fix-cost",
];

/** EVENT_STATUS — internal event → status projection (D-38). Not exported. */
const EVENT_STATUS = {
  confirm: "open",
  resolve: "resolved",
  "verify-close": "verified-closed",
  suppress: "suppressed",
  reopen: "open",
};

/**
 * IDENTITY_FIELDS — the D-17 `ratchet-candidate/1` identity/locator fields carried
 * VERBATIM onto every `ratchet-finding-event/1` row (re-validated, never re-derived from
 * prose).
 */
const IDENTITY_FIELDS = [
  "surface",
  "surface_type",
  "dimension",
  "dimension_name",
  "overlay_tags",
  "region_tag",
  "claim_key",
  "finding_id",
  "cell_refs",
  "png_ref",
  "viewport",
  "theme",
  "state",
];

/**
 * CARRY_FIELDS — the D-17 provenance/severity/prose fields carried forward verbatim
 * (non-identity, but travel with the row across every lifecycle event).
 */
const CARRY_FIELDS = [
  "run_id",
  "round",
  "model",
  "bundle_sha256",
  "severity",
  "job_blocking",
  "defect_bucket",
  "justification_token",
  "effort_hint",
  "defect",
  "suggested_fix",
];

// -----------------------------------------------------------------------------
// Pure helpers
// -----------------------------------------------------------------------------

/**
 * lensKeyFor(raisedBy) — map a candidate row's `raised_by` object
 * (`{lens_kind:"persona", persona_id}` or `{lens_kind:"design"}`) to its `LENS_KEYS`
 * string. Throws on an unrecognized `lens_kind` rather than silently returning `undefined`
 * (this is the gate key — silent coercion would corrupt DEDUP-03 counting).
 */
function lensKeyFor(raisedBy) {
  if (!raisedBy || typeof raisedBy !== "object") {
    throw new Error(`lensKeyFor: invalid raised_by: ${JSON.stringify(raisedBy)}`);
  }
  if (raisedBy.lens_kind === "design") return "design";
  if (raisedBy.lens_kind === "persona") {
    const key = `persona:${raisedBy.persona_id}`;
    if (!LENS_KEYS.includes(key)) {
      throw new Error(`lensKeyFor: unrecognized persona_id: ${JSON.stringify(raisedBy.persona_id)}`);
    }
    return key;
  }
  throw new Error(`lensKeyFor: unrecognized lens_kind: ${JSON.stringify(raisedBy.lens_kind)}`);
}

/**
 * isValidSuppressedReason(reason) — closed-enum check (D-41). `duplicate-of` is never
 * valid as a bare literal; it must carry a `:<finding_id>` suffix.
 */
function isValidSuppressedReason(reason) {
  if (typeof reason !== "string") return false;
  if (reason === "duplicate-of") return false;
  if (SUPPRESSED_REASONS.includes(reason)) return true;
  return reason.startsWith("duplicate-of:") && reason.length > "duplicate-of:".length;
}

/** pick(obj, keys) — shallow-copy only the OWN keys present in `obj`. */
function pick(obj, keys) {
  const result = {};
  for (const key of keys) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      result[key] = obj[key];
    }
  }
  return result;
}

/**
 * readLedgerRows(ledgerPath) — parse existing NDJSON lines. A missing or empty file is
 * treated as zero prior rows — never throws on absence (append helpers must work against a
 * not-yet-created ledger file / fresh mkdtemp scratch path).
 */
function readLedgerRows(ledgerPath) {
  let raw;
  try {
    raw = fs.readFileSync(ledgerPath, "utf8");
  } catch (err) {
    if (err && err.code === "ENOENT") return [];
    throw err;
  }
  const text = raw.trim();
  if (!text) return [];
  return text.split("\n").map((line) => JSON.parse(line));
}

/** nextSeq(rows) — max existing `seq` + 1, or 1 for the first row (D-38, global counter). */
function nextSeq(rows) {
  let max = 0;
  for (const row of rows) {
    if (typeof row.seq === "number" && row.seq > max) max = row.seq;
  }
  return max + 1;
}

/** latestRowForFindingId(rows, finding_id) — last row in file order matching finding_id. */
function latestRowForFindingId(rows, finding_id) {
  let latest = null;
  for (const row of rows) {
    if (row.finding_id === finding_id) latest = row;
  }
  return latest;
}

/**
 * assertIdentity(row) — re-derive `claim_key` via `claimKey()` from the row's OWN
 * `surface`/`dimension`/`region_tag`/`overlay_tags` fields and assert it equals the row's
 * stored `claim_key`; re-derive `finding_id` via `findingId()` and assert equality with the
 * row's stored `finding_id`. Throws a descriptive error on mismatch — never silently trusts
 * a hand-edited or corrupted row (T-206-01-02).
 */
function assertIdentity(row) {
  const derivedClaimKey = claimKey(row.surface, row.dimension, row.region_tag, row.overlay_tags);
  if (derivedClaimKey !== row.claim_key) {
    throw new Error(
      `claim_key mismatch for finding_id=${JSON.stringify(row.finding_id)}: stored=${JSON.stringify(
        row.claim_key
      )} derived=${JSON.stringify(derivedClaimKey)}`
    );
  }
  const derivedFindingId = findingId(derivedClaimKey);
  if (derivedFindingId !== row.finding_id) {
    throw new Error(
      `finding_id mismatch: stored=${JSON.stringify(row.finding_id)} derived=${JSON.stringify(derivedFindingId)}`
    );
  }
  return derivedFindingId;
}

/** appendRow(ledgerPath, row) — append exactly one JSON line. Never rewrite/truncate. */
function appendRow(ledgerPath, row) {
  fs.appendFileSync(ledgerPath, JSON.stringify(row) + "\n");
}

// -----------------------------------------------------------------------------
// Append helpers (D-38) — every function takes an explicit `ledgerPath`; none hardcodes
// the real committed `findings.ledger.ndjson` path.
// -----------------------------------------------------------------------------

/**
 * appendOpen(candidateRow, ledgerPath, extraFields) — append a `confirm` event (status
 * `open`) for a NEW finding. `candidateRow` is the (possibly `collapseByFindingId`-collapsed)
 * work item carrying the full D-17 identity fields. Re-validates identity via
 * `region-tags.js` and the `justification_token` via `isAdmissibleToken` before writing —
 * never silently writes a fabricated or malformed finding.
 */
function appendOpen(candidateRow, ledgerPath, extraFields = {}) {
  if (!candidateRow || typeof candidateRow !== "object") {
    throw new Error("appendOpen: candidateRow must be an object");
  }
  assertIdentity(candidateRow);
  if (
    candidateRow.justification_token != null &&
    !isAdmissibleToken(candidateRow.justification_token)
  ) {
    throw new Error(
      `appendOpen: inadmissible justification_token: ${JSON.stringify(candidateRow.justification_token)}`
    );
  }

  const rows = readLedgerRows(ledgerPath);
  const seq = nextSeq(rows);

  const raisedByLenses = Array.isArray(candidateRow.raised_by_lenses)
    ? Array.from(new Set(candidateRow.raised_by_lenses)).sort()
    : [lensKeyFor(candidateRow.raised_by)];

  const row = {
    schema_version: "ratchet-finding-event/1",
    seq,
    event: "confirm",
    status: "open",
    persona_frequency:
      candidateRow.persona_frequency != null ? candidateRow.persona_frequency : raisedByLenses.length,
    raised_by_lenses: raisedByLenses,
    effort_class: candidateRow.effort_hint != null ? candidateRow.effort_hint : null,
    guard_ref: null,
    confirmed_by: [],
    panel_votes: null,
    suppressed_reason: null,
    suppressed_note: null,
    resolved_round: null,
    ...pick(candidateRow, IDENTITY_FIELDS),
    ...pick(candidateRow, CARRY_FIELDS),
    ...extraFields,
  };

  appendRow(ledgerPath, row);
  return row;
}

/**
 * appendLifecycleEvent(finding_id, ledgerPath, event, extraFields) — shared implementation
 * for `appendResolved`/`appendVerifiedClosed`/`appendSuppressed`. Looks up the finding's
 * latest existing row (by `finding_id`, in file order), re-validates its identity, and
 * carries every D-17 identity/carry field forward verbatim onto the new event row.
 */
function appendLifecycleEvent(finding_id, ledgerPath, event, extraFields = {}) {
  const status = EVENT_STATUS[event];
  if (!status) {
    throw new Error(`appendLifecycleEvent: unrecognized event ${JSON.stringify(event)}`);
  }
  const rows = readLedgerRows(ledgerPath);
  const prior = latestRowForFindingId(rows, finding_id);
  if (!prior) {
    throw new Error(
      `appendLifecycleEvent: no existing row found for finding_id=${JSON.stringify(finding_id)} in ${ledgerPath}`
    );
  }
  assertIdentity(prior);

  const seq = nextSeq(rows);

  const row = {
    schema_version: "ratchet-finding-event/1",
    seq,
    event,
    status,
    persona_frequency: prior.persona_frequency != null ? prior.persona_frequency : null,
    raised_by_lenses: Array.isArray(prior.raised_by_lenses) ? prior.raised_by_lenses.slice() : [],
    effort_class: prior.effort_class != null ? prior.effort_class : null,
    guard_ref: prior.guard_ref != null ? prior.guard_ref : null,
    confirmed_by: Array.isArray(prior.confirmed_by) ? prior.confirmed_by.slice() : [],
    panel_votes: prior.panel_votes != null ? prior.panel_votes : null,
    suppressed_reason: prior.suppressed_reason != null ? prior.suppressed_reason : null,
    suppressed_note: prior.suppressed_note != null ? prior.suppressed_note : null,
    resolved_round: prior.resolved_round != null ? prior.resolved_round : null,
    ...pick(prior, IDENTITY_FIELDS),
    ...pick(prior, CARRY_FIELDS),
    ...extraFields,
  };

  appendRow(ledgerPath, row);
  return row;
}

/** appendResolved(finding_id, ledgerPath, extraFields) — append a `resolve` event. */
function appendResolved(finding_id, ledgerPath, extraFields = {}) {
  return appendLifecycleEvent(finding_id, ledgerPath, "resolve", extraFields);
}

/** appendVerifiedClosed(finding_id, ledgerPath, extraFields) — append a `verify-close` event. */
function appendVerifiedClosed(finding_id, ledgerPath, extraFields = {}) {
  return appendLifecycleEvent(finding_id, ledgerPath, "verify-close", extraFields);
}

/**
 * appendSuppressed(finding_id, ledgerPath, extraFields) — append a `suppress` event.
 * Requires `extraFields.suppressed_reason` to be one of `SUPPRESSED_REASONS` (or a
 * `duplicate-of:<finding_id>`-shaped value) — never writes a suppression with a
 * non-admissible or missing reason.
 */
function appendSuppressed(finding_id, ledgerPath, extraFields = {}) {
  const reason = extraFields.suppressed_reason;
  if (!isValidSuppressedReason(reason)) {
    throw new Error(`appendSuppressed: suppressed_reason not admissible: ${JSON.stringify(reason)}`);
  }
  return appendLifecycleEvent(finding_id, ledgerPath, "suppress", extraFields);
}

// -----------------------------------------------------------------------------
// fold() reducer (D-38) — the tamper-evidence check Wave-2's reducer and the independent
// CI verifier both depend on.
// -----------------------------------------------------------------------------

/**
 * fold(rows) — pure function over an array of already-parsed `ratchet-finding-event/1`
 * row objects (in file order). Asserts `row.seq` is strictly greater than every
 * previously-seen `seq` in the same array (throws `"seq not monotonic"` with the offending
 * row's `finding_id`/`seq` on violation — T-206-01-01) and returns a
 * `Map<finding_id, latestRow>` using latest-event-wins semantics: the LAST row seen for a
 * given `finding_id` (in file order) is its current state; earlier rows for the same
 * `finding_id` are superseded, never merged.
 */
function fold(rows) {
  const result = new Map();
  let maxSeq = -Infinity;
  for (const row of rows) {
    if (typeof row.seq !== "number" || !(row.seq > maxSeq)) {
      throw new Error(
        `seq not monotonic: finding_id=${JSON.stringify(row.finding_id)} seq=${JSON.stringify(row.seq)}`
      );
    }
    maxSeq = row.seq;
    result.set(row.finding_id, row);
  }
  return result;
}

/**
 * collapseByFindingId(candidateRows) — pure function over an array of Phase-205
 * `ratchet-candidate/1` rows. Groups by `finding_id`; for each distinct `finding_id` returns
 * ONE work item: `raised_by_lenses` is the sorted, de-duplicated array of every
 * `lensKeyFor(row.raised_by)` value among the group's rows; `persona_frequency` is
 * `raised_by_lenses.length`; every OTHER field is taken from the FIRST-encountered row in
 * the group (the representative) — collapse happens BEFORE any Opus verification call is
 * made downstream (Claude's Discretion: verify each distinct `finding_id` once, never pay
 * Opus per duplicate).
 */
function collapseByFindingId(candidateRows) {
  const groups = new Map();
  for (const row of candidateRows) {
    if (!groups.has(row.finding_id)) groups.set(row.finding_id, []);
    groups.get(row.finding_id).push(row);
  }

  const items = [];
  for (const [finding_id, group] of groups) {
    const representative = group[0];
    const raisedByLenses = Array.from(new Set(group.map((row) => lensKeyFor(row.raised_by)))).sort();
    items.push({
      ...representative,
      finding_id,
      raised_by_lenses: raisedByLenses,
      persona_frequency: raisedByLenses.length,
    });
  }
  return items;
}

// -----------------------------------------------------------------------------
// Self-test (D-05-style discipline, twins region-tags.js/phase200-scorecard.mjs)
// -----------------------------------------------------------------------------

/** assertSelfTest(name, condition, details) — verbatim shape of region-tags.js's helper. */
function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

/**
 * runSelfTest() — covers, in order: (a) fold() lifecycle chains, (b) fold() seq-monotonic
 * tamper detection, (c) collapseByFindingId() DEDUP-03 persona_frequency collapse, (d) a
 * real append-round-trip fixture via appendOpen/appendResolved/appendVerifiedClosed against
 * an fs.mkdtempSync scratch path. Zero network calls; zero mutation of any real committed
 * file.
 */
function runSelfTest() {
  // (a) fold() over a synthetic fixture exercising open -> resolved -> verified-closed for
  // one finding_id and a separate open -> suppressed chain for another.
  const chainRows = [
    { finding_id: "f-fixture-chain-a", seq: 1, event: "confirm", status: "open" },
    { finding_id: "f-fixture-chain-b", seq: 2, event: "confirm", status: "open" },
    { finding_id: "f-fixture-chain-a", seq: 3, event: "resolve", status: "resolved" },
    { finding_id: "f-fixture-chain-b", seq: 4, event: "suppress", status: "suppressed" },
    { finding_id: "f-fixture-chain-a", seq: 5, event: "verify-close", status: "verified-closed" },
  ];
  const folded = fold(chainRows);
  assertSelfTest(
    "(a) fold-lifecycle: open->resolved->verified-closed terminal status",
    folded.get("f-fixture-chain-a").status === "verified-closed"
  );
  assertSelfTest(
    "(a) fold-lifecycle: open->suppressed terminal status",
    folded.get("f-fixture-chain-b").status === "suppressed"
  );

  // (b) fold() throws on out-of-order / duplicate seq.
  let outOfOrderThrew = false;
  try {
    fold([
      { finding_id: "f-fixture-x", seq: 2, event: "confirm", status: "open" },
      { finding_id: "f-fixture-y", seq: 1, event: "confirm", status: "open" },
    ]);
  } catch {
    outOfOrderThrew = true;
  }
  assertSelfTest("(b) fold-seq-monotonic: out-of-order seq throws", outOfOrderThrew);

  let duplicateThrew = false;
  try {
    fold([
      { finding_id: "f-fixture-x", seq: 1, event: "confirm", status: "open" },
      { finding_id: "f-fixture-y", seq: 1, event: "confirm", status: "open" },
    ]);
  } catch {
    duplicateThrew = true;
  }
  assertSelfTest("(b) fold-seq-monotonic: duplicate seq throws", duplicateThrew);

  // (c) collapseByFindingId() over 4 synthetic candidate rows — 3 sharing one finding_id
  // across raised_by values mapping to persona:operator-founder/persona:customer-support/
  // design, plus 1 with a distinct finding_id.
  const sharedFindingId = "f-fixture-shared0000001";
  const distinctFindingId = "f-fixture-distinct00002";
  const candidateRows = [
    {
      finding_id: sharedFindingId,
      surface: "dashboard",
      dimension: 2,
      region_tag: "kpi-row",
      overlay_tags: [],
      claim_key: "dashboard__d02__kpi-row__ov-none",
      raised_by: { lens_kind: "persona", persona_id: "operator-founder" },
      severity: "real",
      defect: "shared defect, phrasing A",
    },
    {
      finding_id: sharedFindingId,
      surface: "dashboard",
      dimension: 2,
      region_tag: "kpi-row",
      overlay_tags: [],
      claim_key: "dashboard__d02__kpi-row__ov-none",
      raised_by: { lens_kind: "persona", persona_id: "customer-support" },
      severity: "minor",
      defect: "shared defect, phrasing B",
    },
    {
      finding_id: sharedFindingId,
      surface: "dashboard",
      dimension: 2,
      region_tag: "kpi-row",
      overlay_tags: [],
      claim_key: "dashboard__d02__kpi-row__ov-none",
      raised_by: { lens_kind: "design" },
      severity: "real",
      defect: "shared defect, phrasing C",
    },
    {
      finding_id: distinctFindingId,
      surface: "subscriptions-list",
      dimension: 4,
      region_tag: "data-table",
      overlay_tags: [],
      claim_key: "subscriptions-list__d04__data-table__ov-none",
      raised_by: { lens_kind: "persona", persona_id: "finance-billing-ops" },
      severity: "real",
      defect: "distinct defect",
    },
  ];
  const collapsed = collapseByFindingId(candidateRows);
  assertSelfTest("(c) collapse-persona-frequency: 2 distinct work items", collapsed.length === 2);
  const sharedItem = collapsed.find((item) => item.finding_id === sharedFindingId);
  assertSelfTest(
    "(c) collapse-persona-frequency: persona_frequency === 3",
    sharedItem.persona_frequency === 3
  );
  assertSelfTest(
    "(c) collapse-persona-frequency: raised_by_lenses contains all 3 lenses",
    ["persona:operator-founder", "persona:customer-support", "design"].every((lens) =>
      sharedItem.raised_by_lenses.includes(lens)
    )
  );
  assertSelfTest(
    "(c) collapse-persona-frequency: representative fields carried from first-encountered row",
    sharedItem.defect === "shared defect, phrasing A"
  );

  // (d) append-round-trip fixture: real appendOpen/appendResolved/appendVerifiedClosed
  // against an fs.mkdtempSync scratch path, wrapped in try/finally so cleanup never skips.
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-ledger-"));
  try {
    const ledgerPath = path.join(root, "findings.ledger.ndjson");
    const surface = "dashboard";
    const dimension = 3;
    const region_tag = "kpi-row";
    const overlay_tags = [];
    const claim_key = claimKey(surface, dimension, region_tag, overlay_tags);
    const finding_id = findingId(claim_key);

    const candidateRow = {
      schema_version: "ratchet-candidate/1",
      run_id: "run-fixture",
      round: 1,
      model: "fixture-model",
      bundle_sha256: "0".repeat(64),
      png_ref: "chromium-desktop/dashboard-light.png",
      viewport: "chromium-desktop",
      theme: "light",
      state: "default-populated",
      cell_refs: [],
      surface,
      surface_type: "dashboard",
      dimension,
      dimension_name: "spacing-rhythm",
      overlay_tags,
      region_tag,
      claim_key,
      finding_id,
      severity: "real",
      job_blocking: true,
      defect_bucket: null,
      justification_token: "rubric-dim-below-bar",
      raised_by: { lens_kind: "persona", persona_id: "operator-founder" },
      raised_by_lenses: ["persona:operator-founder"],
      persona_frequency: 1,
      effort_hint: "small",
      defect: "fixture defect for append-round-trip self-test",
      suggested_fix: "fixture suggested fix",
    };

    appendOpen(candidateRow, ledgerPath);
    appendResolved(finding_id, ledgerPath, { resolved_round: 2 });
    appendVerifiedClosed(finding_id, ledgerPath);

    const rows = readLedgerRows(ledgerPath);
    assertSelfTest("(d) append-round-trip: writes 3 NDJSON rows", rows.length === 3);
    assertSelfTest(
      "(d) append-round-trip: seq values are 1, 2, 3 in file order",
      rows.map((row) => row.seq).join(",") === "1,2,3"
    );

    const foldedRoundTrip = fold(rows);
    assertSelfTest(
      "(d) append-round-trip: fold() reports terminal status verified-closed",
      foldedRoundTrip.get(finding_id).status === "verified-closed"
    );
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }

  console.log("ratchet-ledger self-test passed.");
}

module.exports = {
  LENS_KEYS,
  EVENT_TYPES,
  STATUS_VALUES,
  SUPPRESSED_REASONS,
  lensKeyFor,
  appendOpen,
  appendResolved,
  appendVerifiedClosed,
  appendSuppressed,
  fold,
  collapseByFindingId,
  assertSelfTest,
  runSelfTest,
};

// Standalone runner: `node accrue_admin/e2e/ratchet/ratchet-ledger.js` executes the
// self-test and exits nonzero on any thrown assertion. No ANTHROPIC_API_KEY, no SDK.
if (require.main === module) {
  runSelfTest();
}
