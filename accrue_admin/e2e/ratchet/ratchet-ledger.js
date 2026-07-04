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
const { claimKey, findingId, isAdmissibleToken, assertDimension } = require("./region-tags.js");

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
 * LEGAL_TRANSITIONS — WR-01: the closed lifecycle state-machine transition table, keyed by a
 * prior row's CURRENT `status`, valued by the set of `event`s legally appendable next. This is
 * enforced inside `appendLifecycleEvent` (below) so the sole trusted writer for the D-38
 * lifecycle vocabulary cannot append an illegal transition (e.g. `"resolve"` on a finding whose
 * latest status is already `"verified-closed"`, or `"suppress"` on one already `"resolved"`) —
 * closing the gap a future caller bug (e.g. Phase 207 orchestration) could otherwise silently
 * exploit, since neither `fold()` nor any verify-tooling re-checks transition legality; both
 * simply treat the last row as ground truth. `"open"` (the status `confirm`/`reopen` project
 * to) may only be followed by `resolve` or `suppress` — it is never itself a `reopen` target
 * (a finding that is already open cannot be "reopened"). Not exported — internal enforcement
 * detail; callers use the `event ∈ EVENT_TYPES` vocabulary via the append* wrapper functions.
 */
const LEGAL_TRANSITIONS = {
  open: ["resolve", "suppress"],
  resolved: ["verify-close", "reopen"],
  "verified-closed": ["reopen"],
  suppressed: ["reopen"],
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

/**
 * nextSeq(rows) — max existing `seq` + 1, or 1 for the first row (D-38, global counter).
 *
 * IN-01 — LOAD-BEARING INVARIANT, NOT ENFORCED IN CODE: `nextSeq`/`appendRow` re-read the
 * whole ledger file, compute the next `seq`, then append — this is race-free ONLY because
 * every current caller (`ratchet-verify.mjs`'s `main()`) writes strictly SEQUENTIALLY inside an
 * `await`-ed `for...of` loop, never `Promise.all`/concurrent. There is no file lock here. A
 * future refactor toward concurrent/parallel image processing against the SAME `ledgerPath`
 * would silently introduce duplicate/racing `seq` values (a classic read-then-write TOCTOU race)
 * with no test catching it until `fold()`'s seq-monotonic tamper-evidence check starts throwing
 * downstream. If parallel verification is ever introduced, add a real lock (e.g. an `O_EXCL`
 * lockfile) before removing this comment.
 */
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
 *
 * WR-06: also calls `assertDimension(row.dimension)` FIRST, before deriving `claim_key` — self-
 * consistency alone (does the stored `claim_key` match what `claimKey()` derives from the row's
 * OWN fields) does not enforce the "exactly 12 rubric dimensions, no 13th" milestone guardrail:
 * a row carrying a nonsensical `dimension` (e.g. `13`, `0`, or a non-numeric string) would
 * otherwise pass as long as its own `claim_key`/`finding_id` were computed the same way.
 */
function assertIdentity(row) {
  assertDimension(row.dimension);
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
 * for `appendResolved`/`appendVerifiedClosed`/`appendSuppressed`/`appendReopened`. Looks up
 * the finding's latest existing row (by `finding_id`, in file order), re-validates its
 * identity, validates the requested `event` is a LEGAL transition from the prior row's current
 * `status` (WR-01, `LEGAL_TRANSITIONS`) — rejecting e.g. a `"resolve"` on an already
 * `"verified-closed"` finding, or a repeated `"suppress"` on an already-`"suppressed"` one —
 * and carries every D-17 identity/carry field forward verbatim onto the new event row.
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
  if (!LEGAL_TRANSITIONS[prior.status] || !LEGAL_TRANSITIONS[prior.status].includes(event)) {
    throw new Error(
      `appendLifecycleEvent: illegal transition ${JSON.stringify(prior.status)} -> ${JSON.stringify(
        event
      )} for finding_id=${JSON.stringify(finding_id)}`
    );
  }

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

/**
 * appendReopened(finding_id, ledgerPath, extraFields) — WR-02: append a `reopen` event. Every
 * other event in the D-38 lifecycle vocabulary has a safe, identity-re-validating,
 * transition-checked (WR-01) wrapper; `"reopen"` previously had none, despite `EVENT_TYPES`/
 * `EVENT_STATUS` both including it — the only sanctioned way to append one was to hand-
 * construct a raw NDJSON row, bypassing `seq` computation, identity re-validation, and
 * carry-forward logic. Legal only from `resolved`/`verified-closed`/`suppressed` (never from
 * `open` — a finding that is already open cannot be "reopened"; see `LEGAL_TRANSITIONS`),
 * enforced by the same `appendLifecycleEvent` transition check as every other wrapper.
 */
function appendReopened(finding_id, ledgerPath, extraFields = {}) {
  return appendLifecycleEvent(finding_id, ledgerPath, "reopen", extraFields);
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
 *
 * WR-04: `lensKeyFor` throws on any unrecognized `lens_kind`/`persona_id` (by design — DEDUP-03
 * counting must never silently coerce a bad value). Since `candidates.ndjson` is bulk-produced
 * by an LLM-driven upstream stage, a single corrupted/unexpectedly-shaped `raised_by` value
 * anywhere in the file must NOT abort collapsing (and therefore verifying) every OTHER valid
 * candidate in the run — a disproportionate blast radius for an isolated data-quality problem.
 * Each row's `lensKeyFor` call is therefore wrapped in its own try/catch: an offending row is
 * skipped and logged, not propagated. If EVERY row in a `finding_id` group is malformed, the
 * whole group (having no valid lens to report) is dropped and logged rather than emitted with
 * an empty `raised_by_lenses`/zero `persona_frequency`.
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
    const raisedByLenses = [];
    for (const row of group) {
      let lensKey;
      try {
        lensKey = lensKeyFor(row.raised_by);
      } catch (err) {
        console.warn(
          `[ratchet-ledger] collapseByFindingId: skipping row with malformed raised_by for ` +
            `finding_id=${JSON.stringify(finding_id)}: ${err.message}`
        );
        continue;
      }
      raisedByLenses.push(lensKey);
    }

    const dedupedSortedLenses = Array.from(new Set(raisedByLenses)).sort();
    if (dedupedSortedLenses.length === 0) {
      console.warn(
        `[ratchet-ledger] collapseByFindingId: dropping finding_id=${JSON.stringify(finding_id)} — ` +
          `every row in its group had a malformed raised_by`
      );
      continue;
    }

    items.push({
      ...representative,
      finding_id,
      raised_by_lenses: dedupedSortedLenses,
      persona_frequency: dedupedSortedLenses.length,
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

  // (c2) WR-04 regression: a single malformed `raised_by` row must not abort collapsing the
  // rest of the batch. Fixture: the shared-finding group above gets ONE additional row with a
  // malformed raised_by (unrecognized lens_kind), plus a brand-new distinct finding_id whose
  // OWN group is 100% malformed rows (every row in that group has a bad raised_by).
  {
    const malformedRowFindingId = "f-fixture-shared0000001"; // reuse sharedFindingId's group
    const allBadFindingId = "f-fixture-all-bad000003";
    const candidateRowsWithMalformed = [
      ...candidateRows,
      {
        finding_id: malformedRowFindingId,
        surface: "dashboard",
        dimension: 2,
        region_tag: "kpi-row",
        overlay_tags: [],
        claim_key: "dashboard__d02__kpi-row__ov-none",
        raised_by: { lens_kind: "not-a-real-lens-kind" }, // malformed — lensKeyFor throws
        severity: "real",
        defect: "malformed raised_by row, must be skipped not fatal",
      },
      {
        finding_id: allBadFindingId,
        surface: "subscriptions-list",
        dimension: 4,
        region_tag: "data-table",
        overlay_tags: [],
        claim_key: "subscriptions-list__d04__data-table__ov-none",
        raised_by: { lens_kind: "not-a-real-lens-kind" }, // the ONLY row in this group — all bad
        severity: "real",
        defect: "entire group is malformed, must be dropped not fatal",
      },
    ];

    let collapsedWithMalformed;
    let threwUnexpectedly = false;
    try {
      collapsedWithMalformed = collapseByFindingId(candidateRowsWithMalformed);
    } catch {
      threwUnexpectedly = true;
    }
    assertSelfTest(
      "(c2) WR-04: collapseByFindingId never throws on a malformed raised_by row",
      !threwUnexpectedly
    );
    assertSelfTest(
      "(c2) WR-04: the fully-malformed finding_id group is dropped, not emitted",
      !collapsedWithMalformed.some((item) => item.finding_id === allBadFindingId)
    );
    const sharedItemAfterMalformedRow = collapsedWithMalformed.find(
      (item) => item.finding_id === malformedRowFindingId
    );
    assertSelfTest(
      "(c2) WR-04: the shared group's OTHER (valid) rows still collapse normally " +
        "(persona_frequency still 3 — the malformed 4th row contributed nothing, not a crash)",
      sharedItemAfterMalformedRow.persona_frequency === 3
    );
    assertSelfTest(
      "(c2) WR-04: distinctFindingId's own untouched valid group is still present in the output",
      collapsedWithMalformed.some((item) => item.finding_id === distinctFindingId)
    );
  }

  // (c3) WR-06 regression: a row whose `dimension` is OUT of the closed 1..12 rubric range
  // (e.g. `13` — the milestone's explicit "no 13th dimension" guardrail) but whose own
  // `claim_key`/`finding_id` were computed self-consistently (claimKey() itself does not range-
  // check dimension; it merely interpolates it) must now be rejected by `assertIdentity` (and
  // therefore `appendOpen`), where before this fix self-consistency alone was sufficient to pass.
  {
    const badDimension = 13;
    const badSurface = "dashboard";
    const badRegionTag = "kpi-row";
    const badOverlayTags = [];
    const badClaimKey = claimKey(badSurface, badDimension, badRegionTag, badOverlayTags);
    const badFindingId = findingId(badClaimKey);
    const badRow = {
      surface: badSurface,
      dimension: badDimension,
      region_tag: badRegionTag,
      overlay_tags: badOverlayTags,
      claim_key: badClaimKey,
      finding_id: badFindingId,
    };
    let threwOnBadDimension = false;
    try {
      assertIdentity(badRow);
    } catch {
      threwOnBadDimension = true;
    }
    assertSelfTest(
      "(c3) WR-06: assertIdentity rejects a self-consistent row whose dimension is out of 1..12 (13)",
      threwOnBadDimension
    );

    const scratchRoot = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-ledger-"));
    try {
      const scratchLedgerPath = path.join(scratchRoot, "findings.ledger.ndjson");
      let appendOpenThrew = false;
      try {
        appendOpen(
          {
            ...badRow,
            schema_version: "ratchet-candidate/1",
            raised_by: { lens_kind: "design" },
            raised_by_lenses: ["design"],
          },
          scratchLedgerPath
        );
      } catch {
        appendOpenThrew = true;
      }
      assertSelfTest(
        "(c3) WR-06: appendOpen rejects (and never writes) a row with an out-of-range dimension",
        appendOpenThrew && !fs.existsSync(scratchLedgerPath)
      );
    } finally {
      fs.rmSync(scratchRoot, { recursive: true, force: true });
    }
  }

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

  // (e) WR-01 regression: appendLifecycleEvent must reject illegal lifecycle transitions,
  // never silently corrupting a "terminal" or already-visited status.
  {
    const root2 = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-ledger-"));
    try {
      const ledgerPath = path.join(root2, "findings.ledger.ndjson");
      const surface = "subscriptions-list";
      const dimension = 4;
      const region_tag = "data-table";
      const overlay_tags = [];
      const claim_key = claimKey(surface, dimension, region_tag, overlay_tags);
      const finding_id = findingId(claim_key);
      const candidateRow = {
        schema_version: "ratchet-candidate/1",
        run_id: "run-fixture",
        round: 1,
        model: "fixture-model",
        bundle_sha256: "0".repeat(64),
        png_ref: "chromium-desktop/subscriptions-light.png",
        viewport: "chromium-desktop",
        theme: "light",
        state: "default-populated",
        cell_refs: [],
        surface,
        surface_type: "list",
        dimension,
        dimension_name: "state-coverage",
        overlay_tags,
        region_tag,
        claim_key,
        finding_id,
        severity: "real",
        job_blocking: true,
        defect_bucket: null,
        justification_token: "rubric-dim-below-bar",
        raised_by: { lens_kind: "design" },
        raised_by_lenses: ["design"],
        persona_frequency: 1,
        effort_hint: "small",
        defect: "fixture defect for illegal-transition self-test",
        suggested_fix: "fixture suggested fix",
      };
      appendOpen(candidateRow, ledgerPath);

      // open -> verify-close is illegal (LEGAL_TRANSITIONS.open only permits resolve/suppress).
      let openToVerifyCloseThrew = false;
      try {
        appendVerifiedClosed(finding_id, ledgerPath);
      } catch {
        openToVerifyCloseThrew = true;
      }
      assertSelfTest(
        "(e) WR-01: open -> verify-close is an illegal transition and throws",
        openToVerifyCloseThrew
      );

      // Now legally resolve it.
      appendResolved(finding_id, ledgerPath, { resolved_round: 1 });

      // resolved -> resolve (repeated) is illegal (LEGAL_TRANSITIONS.resolved only permits
      // verify-close/reopen, not a second resolve).
      let repeatedResolveThrew = false;
      try {
        appendResolved(finding_id, ledgerPath, { resolved_round: 2 });
      } catch {
        repeatedResolveThrew = true;
      }
      assertSelfTest(
        "(e) WR-01: resolved -> resolve (repeated) is an illegal transition and throws",
        repeatedResolveThrew
      );

      // resolved -> suppress is also illegal.
      let resolvedToSuppressThrew = false;
      try {
        appendSuppressed(finding_id, ledgerPath, { suppressed_reason: "out-of-scope" });
      } catch {
        resolvedToSuppressThrew = true;
      }
      assertSelfTest(
        "(e) WR-01: resolved -> suppress is an illegal transition and throws",
        resolvedToSuppressThrew
      );

      // No illegal-transition attempt above should have appended a row — the ledger must
      // still contain exactly the 2 legal rows (confirm, resolve).
      const rowsAfterIllegalAttempts = readLedgerRows(ledgerPath);
      assertSelfTest(
        "(e) WR-01: illegal-transition attempts never append a row (still exactly 2 legal rows)",
        rowsAfterIllegalAttempts.length === 2
      );

      // resolved -> verify-close IS legal and must succeed.
      appendVerifiedClosed(finding_id, ledgerPath);
      const foldedAfterLegalClose = fold(readLedgerRows(ledgerPath));
      assertSelfTest(
        "(e) WR-01: resolved -> verify-close is a legal transition and succeeds",
        foldedAfterLegalClose.get(finding_id).status === "verified-closed"
      );

      // (f) WR-02: appendReopened is now exported and enforces the same transition table —
      // verified-closed -> reopen IS legal and must succeed, going back to status "open".
      appendReopened(finding_id, ledgerPath);
      const foldedAfterReopen = fold(readLedgerRows(ledgerPath));
      assertSelfTest(
        "(f) WR-02: verified-closed -> reopen (appendReopened) is legal and reopens to status open",
        foldedAfterReopen.get(finding_id).status === "open"
      );
      assertSelfTest(
        "(f) WR-02: appendReopened row is event:reopen",
        foldedAfterReopen.get(finding_id).event === "reopen"
      );

      // open -> reopen is illegal — a finding that is already open cannot be "reopened" again.
      let openToReopenThrew = false;
      try {
        appendReopened(finding_id, ledgerPath);
      } catch {
        openToReopenThrew = true;
      }
      assertSelfTest(
        "(f) WR-02: open -> reopen (repeated) is an illegal transition and throws",
        openToReopenThrew
      );
    } finally {
      fs.rmSync(root2, { recursive: true, force: true });
    }
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
  appendReopened,
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
