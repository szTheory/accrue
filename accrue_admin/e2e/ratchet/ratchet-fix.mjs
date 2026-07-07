/**
 * ratchet-fix.mjs — the ORCH-03/ORCH-04 MUTATION half of the UI ratchet loop (Phase 207, v1.56).
 *
 * Two CLI modes, both a thin sequencing shell over the reused Wave-1/Wave-2 primitives — this
 * module reimplements ZERO lifecycle validation, ZERO guard-token grammar, ZERO fold semantics:
 *
 *   --apply-decisions [--round N] [--dry-run]
 *       Reads the maintainer-edited `decisions.json` checkpoint (D-42) the digest pre-filled, and
 *       for every `approve` row calls `appendResolved`; for every `reject` row validates its
 *       `suppressed_reason` against the closed enum via the REUSED `isValidSuppressedReason` and
 *       calls `appendSuppressed`. A single invalid/absent `suppressed_reason` aborts the ENTIRE
 *       batch (zero partial-apply — not even the valid approves before it in file order, D-43).
 *       On success writes `.fix-context.json` = `{round, scope}` for the finalize half to read.
 *
 *   --finalize-fixes
 *       Reads `.fix-context.json` for the round, folds the ledger, loads the scoped
 *       per-resolved-finding probe map (`probe-results.json`) written by `ratchet-fix-probe.spec.js`,
 *       and for every finding RESOLVED THIS ROUND whose probe verdict is `present === false` (the
 *       original defect is gone — the fix stuck) mints a guard via the REUSED 207-03
 *       `mintGuardRow`/`appendMintedRow` and promotes it to `verified-closed` via `appendVerifiedClosed`.
 *       A finding whose probe says the defect is still there (or has no probe entry) is left alone.
 *
 * D-50 boundary (HARD): this file is the mutation command. It advances findings that ALREADY exist
 * in the ledger and NEVER appends a net-new `open` row, NEVER runs the evaluator fan-out. The
 * "did the fix stick?" decision is made ONLY by the injected/loaded probe map — never a fresh
 * discovery pass — so it is structurally incapable of creating a net-new `open` row. (The grep
 * acceptance criterion enforces this: this file contains none of the evaluator-fan-out entry-point
 * names, nor the net-new-open ledger writer.)
 *
 * SDK-free by contract: only `node:*` plus `./ratchet-ledger.js` (lifecycle) and
 * `./ratchet-guard-mint.mjs` (guard minting). `--self-test` proves all four D-42/D-43/D-44/D-50
 * behaviors on `fs.mkdtempSync` scratch fixtures with ZERO live browser, ZERO API key, and ZERO
 * mutation of any real committed file.
 *
 * Usage:
 *   node e2e/ratchet/ratchet-fix.mjs --self-test
 *   node e2e/ratchet/ratchet-fix.mjs --apply-decisions [--round N] [--dry-run]
 *   node e2e/ratchet/ratchet-fix.mjs --finalize-fixes
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import {
  appendResolved,
  appendSuppressed,
  appendVerifiedClosed,
  isValidSuppressedReason,
  SUPPRESSED_REASONS,
  fold,
} from "./ratchet-ledger.js";
import { mintGuardRow, appendMintedRow } from "./ratchet-guard-mint.mjs";

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// -----------------------------------------------------------------------------
// Path constants — match `phase-ratchet-ledger.mjs`/`ratchet-digest.mjs`'s DEFAULT_PATHS
// exactly (single source of truth; never a divergent copy).
// -----------------------------------------------------------------------------

// __dirname === accrue_admin/e2e/ratchet/ — up 3 levels to the repo root (matches every sibling).
const REPO_ROOT = path.resolve(__dirname, "../../..");
const LEDGER_PATH = path.join(__dirname, "findings.ledger.ndjson");
const ROUNDS_PATH = path.join(__dirname, "rounds.ndjson");
const ROUND_OUTPUT_ROOT = path.join(__dirname, "../../test-results/ui-ratchet");
const FIX_CONTEXT_PATH = path.join(ROUND_OUTPUT_ROOT, ".fix-context.json");

/** resolveRoundDir(round) — `test-results/ui-ratchet/round-NN/` (zero-padded; twins the digest). */
function resolveRoundDir(round) {
  return path.join(ROUND_OUTPUT_ROOT, `round-${String(round).padStart(2, "0")}`);
}

// -----------------------------------------------------------------------------
// Small local IO helpers (twin the sibling ratchet scripts; never throw on an absent file).
// -----------------------------------------------------------------------------

function readNdjsonRows(p) {
  let raw;
  try {
    raw = fs.readFileSync(p, "utf8");
  } catch (err) {
    if (err && err.code === "ENOENT") return [];
    throw err;
  }
  const text = raw.trim();
  if (!text) return [];
  return text.split("\n").map((line) => JSON.parse(line));
}

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

/**
 * resolveRound(explicitRound, roundsRows) — the `--round` value if given, else the LATEST sealed
 * round found in `rounds.ndjson` (mirrors 207-01's max-over-rows pattern, WITHOUT the `+1`: this
 * resolves the round just measured, not the next one to open).
 */
function resolveRound(explicitRound, roundsRows) {
  if (explicitRound != null) return explicitRound;
  if (!roundsRows.length) {
    throw new Error("resolveRound: no rounds recorded in rounds.ndjson and no --round given");
  }
  return Math.max(...roundsRows.map((r) => r.round));
}

/**
 * scopeForRound(round, roundsRows) — the `scope` field of the LATEST `rounds.ndjson` seal row for
 * that round number (multiple epochs can reuse a round int; the last one wins). Falls back to the
 * `"all"` sentinel when the round is not (yet) sealed.
 */
function scopeForRound(round, roundsRows) {
  const matches = roundsRows.filter((r) => r.round === round);
  if (!matches.length) return "all";
  return matches[matches.length - 1].scope || "all";
}

// -----------------------------------------------------------------------------
// --apply-decisions (D-42/D-43)
// -----------------------------------------------------------------------------

/**
 * validateDecisionsBatch(rows, ledgerRows) — pure batch classifier. Splits the maintainer-edited
 * decision rows into `{approves, rejects, invalidRows}`. A `reject` row is `invalid` unless its
 * `suppressed_reason` passes the REUSED closed-enum check; any row whose `decision` is neither
 * `approve` nor `reject` is also `invalid`. When `ledgerRows` is supplied, this also preflights
 * the lifecycle conditions the append helpers would otherwise discover one row at a time: every
 * target finding must currently be `open`, and `duplicate-of:<finding_id>` suppressions must point
 * at a finding that exists in this ledger. The caller aborts the WHOLE batch iff `invalidRows` is
 * non-empty — so this pure function is what makes the "abort on ANY invalid row" behavior testable
 * before any append-only ledger mutation.
 */
function validateDecisionsBatch(rows, ledgerRows = []) {
  const approves = [];
  const rejects = [];
  const invalidRows = [];
  for (const row of rows) {
    const decision = row && row.decision;
    if (decision === "approve") {
      approves.push(row);
    } else if (decision === "reject") {
      if (isValidSuppressedReason(row.suppressed_reason)) {
        rejects.push(row);
      } else {
        invalidRows.push({ finding_id: row.finding_id, suppressed_reason: row.suppressed_reason });
      }
    } else {
      invalidRows.push({ finding_id: row && row.finding_id, decision, unknown_decision: true });
    }
  }

  if (Array.isArray(ledgerRows) && ledgerRows.length > 0) {
    const folded = fold(ledgerRows);
    const knownIds = new Set(ledgerRows.map((row) => row.finding_id).filter(Boolean));
    for (const row of approves.concat(rejects)) {
      const latest = folded.get(row.finding_id);
      if (!latest || latest.status !== "open") {
        invalidRows.push({ finding_id: row.finding_id, reason: "not-currently-open" });
      }
      if (typeof row.suppressed_reason === "string" && row.suppressed_reason.startsWith("duplicate-of:")) {
        const referencedFindingId = row.suppressed_reason.slice("duplicate-of:".length);
        if (!knownIds.has(referencedFindingId)) {
          invalidRows.push({
            finding_id: row.finding_id,
            suppressed_reason: row.suppressed_reason,
            reason: "dangling-duplicate-of",
          });
        }
      }
    }
  }

  return { approves, rejects, invalidRows };
}

/** buildBanner(approves, rejects) — the loud D-43 banner + a one-line suppression reason breakdown. */
function buildBanner(approves, rejects) {
  const lines = [`Applying ${approves.length} fixes, ${rejects.length} suppressions:`];
  if (rejects.length === 0) {
    lines.push("  suppressions by reason: (none)");
  } else {
    const counts = {};
    for (const r of rejects) {
      const key = r.suppressed_reason;
      counts[key] = (counts[key] || 0) + 1;
    }
    const parts = Object.keys(counts)
      .sort()
      .map((k) => `${k}×${counts[k]}`);
    lines.push(`  suppressions by reason: ${parts.join(", ")}`);
  }
  return lines.join("\n");
}

/**
 * applyDecisions({round, dryRun, ledgerPath, decisionsPath, roundsPath, fixContextPath}) — the
 * D-42/D-43 apply step. Validates the WHOLE batch first (aborting before ANY ledger mutation on a
 * single invalid reject), prints the loud banner, then — unless `dryRun` — applies each approve via
 * `appendResolved` and each reject via `appendSuppressed`, and writes `.fix-context.json`. `dryRun`
 * prints the same banner but mutates nothing (no ledger row, no `.fix-context.json`).
 */
function applyDecisions({ round, dryRun, ledgerPath, decisionsPath, roundsPath, fixContextPath }) {
  const rows = readJson(decisionsPath);
  if (!Array.isArray(rows)) {
    throw new Error(`applyDecisions: decisions file is not a JSON array: ${decisionsPath}`);
  }

  const ledgerRows = readNdjsonRows(ledgerPath);
  const { approves, rejects, invalidRows } = validateDecisionsBatch(rows, ledgerRows);

  // Abort the ENTIRE batch on ANY invalid row — zero partial-apply (D-43).
  if (invalidRows.length > 0) {
    const named = invalidRows
      .map((r) =>
        r.reason
          ? `${r.finding_id} (${r.reason}${
              r.suppressed_reason != null ? `, suppressed_reason=${JSON.stringify(r.suppressed_reason)}` : ""
            })`
          : r.unknown_decision
          ? `${r.finding_id} (unknown decision=${JSON.stringify(r.decision)})`
          : `${r.finding_id} (suppressed_reason=${JSON.stringify(r.suppressed_reason)})`
      )
      .join("; ");
    throw new Error(
      `applyDecisions: refusing the ENTIRE batch — ${invalidRows.length} row(s) are invalid: ${named}. ` +
        `Valid suppressed_reason values: ${SUPPRESSED_REASONS.join(", ")} (or duplicate-of:<finding_id>).`
    );
  }

  console.log(buildBanner(approves, rejects));

  if (dryRun) {
    console.log("--dry-run: no ledger rows written, no .fix-context.json emitted.");
    return { round, applied: 0, suppressed: 0, dryRun: true };
  }

  for (const row of approves) {
    appendResolved(row.finding_id, ledgerPath, { resolved_round: round });
  }
  for (const row of rejects) {
    appendSuppressed(row.finding_id, ledgerPath, {
      suppressed_reason: row.suppressed_reason,
      suppressed_note: row.suppressed_note != null ? row.suppressed_note : null,
    });
  }

  const scope = scopeForRound(round, readNdjsonRows(roundsPath));
  fs.mkdirSync(path.dirname(fixContextPath), { recursive: true });
  fs.writeFileSync(fixContextPath, JSON.stringify({ round, scope }, null, 2) + "\n");

  return { round, applied: approves.length, suppressed: rejects.length, scope, dryRun: false };
}

// -----------------------------------------------------------------------------
// --finalize-fixes (guard-mint + verify-close promotion, D-44/D-50)
// -----------------------------------------------------------------------------

/**
 * finalizeFixes({round, ledgerPath, repoRoot, probeResults}) — for every folded finding whose
 * LATEST status is `resolved` AND `resolved_round === round`, consult the injected per-finding
 * `probeResults` map: absent entry or `present === true` (defect still observable — fix did not
 * stick) → left alone; `present === false` (defect gone) → mint a guard from the freshly-PROBED
 * field values (D-44 — never guessed) via the reused `mintGuardRow`/`appendMintedRow`, then promote
 * to `verified-closed` via `appendVerifiedClosed` carrying the minted `guard_ref`. Advances only
 * findings that already exist in the ledger; never appends a net-new open row (D-50).
 */
function finalizeFixes({ round, ledgerPath, repoRoot, probeResults }) {
  const folded = fold(readNdjsonRows(ledgerPath));
  const result = { promoted: 0, minted: 0, ledgerCount: 0, leftResolved: 0 };

  for (const finding of folded.values()) {
    if (finding.status !== "resolved" || finding.resolved_round !== round) continue;

    const probe = probeResults ? probeResults[finding.finding_id] : undefined;
    if (!probe || probe.present !== false) {
      // No probe entry, or the probe still observes the original defect: the fix did not stick.
      result.leftResolved += 1;
      continue;
    }

    const { guard_ref, targetSpecPath, row } = mintGuardRow(finding, probe.probed || {});
    if (targetSpecPath && row) {
      appendMintedRow(targetSpecPath, row, repoRoot);
      result.minted += 1;
    } else {
      // ledger-count sentinel kind (D-40): no home spec, no file touch — the ledger IS the guard.
      result.ledgerCount += 1;
    }

    appendVerifiedClosed(finding.finding_id, ledgerPath, { guard_ref });
    result.promoted += 1;
  }

  return result;
}

// -----------------------------------------------------------------------------
// CLI wiring
// -----------------------------------------------------------------------------

function parseRoundArg(argv) {
  const idx = argv.indexOf("--round");
  if (idx === -1) return null;
  const value = argv[idx + 1];
  const num = Number(value);
  if (!Number.isFinite(num)) {
    throw new Error(`--round requires an integer, got ${JSON.stringify(value)}`);
  }
  return num;
}

function runApplyDecisionsCli(argv) {
  const explicitRound = parseRoundArg(argv);
  const dryRun = argv.includes("--dry-run");
  const roundsRows = readNdjsonRows(ROUNDS_PATH);
  const round = resolveRound(explicitRound, roundsRows);
  const decisionsPath = path.join(resolveRoundDir(round), "decisions.json");

  const res = applyDecisions({
    round,
    dryRun,
    ledgerPath: LEDGER_PATH,
    decisionsPath,
    roundsPath: ROUNDS_PATH,
    fixContextPath: FIX_CONTEXT_PATH,
  });

  console.log(
    `[ratchet-fix] apply-decisions round=${round} applied=${res.applied} suppressed=${res.suppressed}` +
      `${res.dryRun ? " (dry-run)" : ` scope=${res.scope}`}`
  );
}

function runFinalizeFixesCli() {
  const ctx = readJson(FIX_CONTEXT_PATH);
  const round = ctx.round;
  const probePath = path.join(resolveRoundDir(round), "probe-results.json");
  const probeResults = readJson(probePath);

  const res = finalizeFixes({
    round,
    ledgerPath: LEDGER_PATH,
    repoRoot: REPO_ROOT,
    probeResults,
  });

  console.log(
    `[ratchet-fix] finalize-fixes round=${round} promoted=${res.promoted} minted=${res.minted} ` +
      `ledger-count=${res.ledgerCount} left-resolved=${res.leftResolved}`
  );
}

// -----------------------------------------------------------------------------
// Self-test (D-42/D-43/D-44/D-50) — pure fixture proof, zero live browser, zero committed-file
// mutation. Twins the sibling ratchet scripts' assertSelfTest/runSelfTest shape.
// -----------------------------------------------------------------------------

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  // region-tags owns identity; require it only for building valid fixture rows in the self-test.
  const { claimKey, findingId } = require("./region-tags.js");

  function makeEventRow(seq, event, status, opts) {
    const overlay_tags = [];
    const {
      surface,
      surface_type,
      dimension,
      region_tag,
      resolved_round = null,
      defect_bucket = null,
      effort_class = "small",
    } = opts;
    const claim_key = claimKey(surface, dimension, region_tag, overlay_tags);
    const finding_id = findingId(claim_key);
    return {
      schema_version: "ratchet-finding-event/1",
      seq,
      event,
      status,
      persona_frequency: 1,
      raised_by_lenses: ["design"],
      effort_class,
      guard_ref: null,
      confirmed_by: [],
      panel_votes: null,
      suppressed_reason: null,
      suppressed_note: null,
      resolved_round,
      surface,
      surface_type,
      dimension,
      dimension_name: "fixture-dim",
      overlay_tags,
      region_tag,
      claim_key,
      finding_id,
      cell_refs: [],
      png_ref: "fixture.png",
      viewport: "chromium-desktop",
      theme: "light",
      state: "default",
      run_id: "run-fixture",
      round: resolved_round || 1,
      model: "fixture-model",
      bundle_sha256: "0".repeat(64),
      severity: "real",
      job_blocking: true,
      defect_bucket,
      justification_token: "rubric-dim-below-bar",
      effort_hint: effort_class,
      defect: "fixture defect",
      suggested_fix: "fixture fix",
    };
  }
  const makeOpen = (seq, opts) => makeEventRow(seq, "confirm", "open", opts);
  const makeResolved = (seq, opts) => makeEventRow(seq, "resolve", "resolved", opts);
  const writeRows = (p, rows) => fs.writeFileSync(p, rows.map((r) => JSON.stringify(r)).join("\n") + "\n");

  // buildBanner / validateDecisionsBatch pure checks.
  assertSelfTest(
    "buildBanner: all-approve reports M=0 suppressions loudly",
    buildBanner([{}, {}], []).startsWith("Applying 2 fixes, 0 suppressions:")
  );

  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-fix-"));
  try {
    const roundsPath = path.join(root, "rounds.ndjson");
    writeRows(roundsPath, [
      {
        schema_version: "ratchet-round-seal/1",
        round: 4,
        dry: false,
        epoch: 1,
        scope: "dashboard,subscriptions",
        bundle_sha256: "0".repeat(64),
        seq: 1,
      },
    ]);

    // (a) all-approve applies every row; loud banner with M=0; writes .fix-context.json.
    {
      const ledgerPath = path.join(root, "ledger-a.ndjson");
      const openA = makeOpen(1, { surface: "dashboard", surface_type: "dashboard", dimension: 6, region_tag: "kpi-row" });
      const openB = makeOpen(2, { surface: "subscriptions", surface_type: "list", dimension: 2, region_tag: "data-table" });
      writeRows(ledgerPath, [openA, openB]);
      const decisionsPath = path.join(root, "decisions-a.json");
      fs.writeFileSync(
        decisionsPath,
        JSON.stringify([
          { finding_id: openA.finding_id, decision: "approve", surface: "dashboard", summary: "x", region_tag: "kpi-row" },
          { finding_id: openB.finding_id, decision: "approve", surface: "subscriptions", summary: "y", region_tag: "data-table" },
        ])
      );
      const fixContextPath = path.join(root, ".fix-context-a.json");
      const res = applyDecisions({ round: 4, dryRun: false, ledgerPath, decisionsPath, roundsPath, fixContextPath });

      const folded = fold(readNdjsonRows(ledgerPath));
      assertSelfTest(
        "(a) all-approve: every row applied -> resolved",
        folded.get(openA.finding_id).status === "resolved" && folded.get(openB.finding_id).status === "resolved"
      );
      assertSelfTest("(a) all-approve: banner reported M=0 (0 suppressions)", res.suppressed === 0);
      assertSelfTest(
        "(a) all-approve: .fix-context.json carries round + the round's scope",
        fs.existsSync(fixContextPath) &&
          readJson(fixContextPath).round === 4 &&
          readJson(fixContextPath).scope === "dashboard,subscriptions"
      );
    }

    // (b) a mixed batch with ONE reject missing suppressed_reason aborts with ZERO rows written —
    // not even the valid approve that precedes it in file order.
    {
      const ledgerPath = path.join(root, "ledger-b.ndjson");
      const openC = makeOpen(1, { surface: "dashboard", surface_type: "dashboard", dimension: 6, region_tag: "kpi-row" });
      const openD = makeOpen(2, { surface: "subscriptions", surface_type: "list", dimension: 2, region_tag: "data-table" });
      writeRows(ledgerPath, [openC, openD]);
      const before = fs.readFileSync(ledgerPath, "utf8");
      const decisionsPath = path.join(root, "decisions-b.json");
      fs.writeFileSync(
        decisionsPath,
        JSON.stringify([
          // valid approve FIRST in file order — must NOT be applied when a later row is invalid
          { finding_id: openC.finding_id, decision: "approve", surface: "dashboard", summary: "x", region_tag: "kpi-row" },
          // reject with NO suppressed_reason — invalid, aborts the whole batch
          { finding_id: openD.finding_id, decision: "reject", surface: "subscriptions", summary: "y", region_tag: "data-table" },
        ])
      );
      const fixContextPath = path.join(root, ".fix-context-b.json");
      let threw = false;
      try {
        applyDecisions({ round: 4, dryRun: false, ledgerPath, decisionsPath, roundsPath, fixContextPath });
      } catch {
        threw = true;
      }
      assertSelfTest("(b) invalid reject aborts the batch (throws)", threw);
      assertSelfTest(
        "(b) ZERO rows applied — ledger byte-identical (not even the earlier valid approve)",
        fs.readFileSync(ledgerPath, "utf8") === before
      );
      assertSelfTest("(b) aborted batch writes no .fix-context.json", !fs.existsSync(fixContextPath));
    }

    // (b2) ledger-state preflight catches append-helper failures before any row is appended.
    {
      const ledgerPath = path.join(root, "ledger-b2.ndjson");
      const openG = makeOpen(1, { surface: "dashboard", surface_type: "dashboard", dimension: 6, region_tag: "kpi-row" });
      const openH = makeOpen(2, { surface: "subscriptions", surface_type: "list", dimension: 2, region_tag: "data-table" });
      writeRows(ledgerPath, [openG, openH]);
      const before = fs.readFileSync(ledgerPath, "utf8");
      const decisionsPath = path.join(root, "decisions-b2.json");
      fs.writeFileSync(
        decisionsPath,
        JSON.stringify([
          // valid approve FIRST in file order — must NOT be applied when a later row references
          // a duplicate target that appendSuppressed would reject.
          { finding_id: openG.finding_id, decision: "approve", surface: "dashboard", summary: "x", region_tag: "kpi-row" },
          {
            finding_id: openH.finding_id,
            decision: "reject",
            surface: "subscriptions",
            summary: "y",
            region_tag: "data-table",
            suppressed_reason: "duplicate-of:f-2222222222222222",
          },
        ])
      );
      const fixContextPath = path.join(root, ".fix-context-b2.json");
      let threw = false;
      try {
        applyDecisions({ round: 4, dryRun: false, ledgerPath, decisionsPath, roundsPath, fixContextPath });
      } catch (error) {
        threw = /dangling-duplicate-of/.test(error.message);
      }
      assertSelfTest("(b2) dangling duplicate-of aborts during preflight", threw);
      assertSelfTest(
        "(b2) ZERO rows applied after preflight failure — ledger byte-identical",
        fs.readFileSync(ledgerPath, "utf8") === before
      );
      assertSelfTest("(b2) preflight failure writes no .fix-context.json", !fs.existsSync(fixContextPath));
    }

    // (c) --dry-run mutates nothing: neither appendResolved/appendSuppressed nor .fix-context.json.
    {
      const ledgerPath = path.join(root, "ledger-c.ndjson");
      const openE = makeOpen(1, { surface: "dashboard", surface_type: "dashboard", dimension: 6, region_tag: "kpi-row" });
      writeRows(ledgerPath, [openE]);
      const before = fs.readFileSync(ledgerPath, "utf8");
      const decisionsPath = path.join(root, "decisions-c.json");
      fs.writeFileSync(
        decisionsPath,
        JSON.stringify([
          { finding_id: openE.finding_id, decision: "approve", surface: "dashboard", summary: "x", region_tag: "kpi-row" },
        ])
      );
      const fixContextPath = path.join(root, ".fix-context-c.json");
      applyDecisions({ round: 4, dryRun: true, ledgerPath, decisionsPath, roundsPath, fixContextPath });
      assertSelfTest("(c) --dry-run leaves the ledger byte-identical", fs.readFileSync(ledgerPath, "utf8") === before);
      assertSelfTest("(c) --dry-run writes no .fix-context.json", !fs.existsSync(fixContextPath));
    }

    // (d) finalizeFixes: mint a guard + promote to verified-closed ONLY for a resolved-this-round
    // finding whose probe says present:false; leave present:true / no-entry / other-round untouched.
    {
      const specRel = "accrue_admin/e2e/foundation-tokens.spec.js";
      const microcopySpecRel = "accrue_admin/e2e/admin-page-flow-phase200.spec.js";
      const fakeRepo = fs.mkdtempSync(path.join(root, "repo-"));
      const destAbs = path.join(fakeRepo, specRel);
      fs.mkdirSync(path.dirname(destAbs), { recursive: true });
      fs.copyFileSync(path.join(REPO_ROOT, specRel), destAbs);
      const microcopyDestAbs = path.join(fakeRepo, microcopySpecRel);
      fs.mkdirSync(path.dirname(microcopyDestAbs), { recursive: true });
      fs.copyFileSync(path.join(REPO_ROOT, microcopySpecRel), microcopyDestAbs);
      const microcopyBefore = fs.readFileSync(microcopyDestAbs, "utf8");

      const ledgerPath = path.join(root, "ledger-d.ndjson");
      const fx = makeResolved(1, { surface: "dashboard", surface_type: "dashboard", dimension: 6, region_tag: "kpi-row", resolved_round: 4 }); // contrast
      const fy = makeResolved(2, { surface: "subscriptions", surface_type: "list", dimension: 2, region_tag: "data-table", resolved_round: 4 }); // ledger-count
      const fz = makeResolved(3, { surface: "customers", surface_type: "list", dimension: 12, region_tag: "content-body", resolved_round: 4 }); // microcopy, no probe entry
      const fw = makeResolved(4, { surface: "invoices", surface_type: "list", dimension: 6, region_tag: "data-table", resolved_round: 3 }); // different round
      const fm = makeResolved(5, { surface: "invoices", surface_type: "list", dimension: 12, region_tag: "summary-card", resolved_round: 4 }); // microcopy, incomplete probe fields
      writeRows(ledgerPath, [fx, fy, fz, fw, fm]);

      const probeResults = {
        [fx.finding_id]: { present: false, probed: { selector: "[data-ax-foundation-status='danger']", min_ratio: 4.5 } },
        [fy.finding_id]: { present: true, probed: {} },
        [fw.finding_id]: { present: false, probed: { selector: ".ax-data-table", min_ratio: 4.5 } },
        [fm.finding_id]: { present: false, probed: { region_present: false, text: null } },
      };

      const res = finalizeFixes({ round: 4, ledgerPath, repoRoot: fakeRepo, probeResults });
      const folded = fold(readNdjsonRows(ledgerPath));

      assertSelfTest(
        "(d) contrast finding (present:false) promoted to verified-closed",
        folded.get(fx.finding_id).status === "verified-closed"
      );
      assertSelfTest(
        "(d) verified-closed finding carries the minted guard_ref",
        folded.get(fx.finding_id).guard_ref === `${specRel}::@ratchet:${fx.finding_id}`
      );
      assertSelfTest(
        "(d) the minted contrast guard row was written into the fake-repo home spec",
        fs.readFileSync(destAbs, "utf8").includes(`@ratchet:${fx.finding_id}`)
      );
      assertSelfTest(
        "(d) incomplete microcopy probe promotes with ledger-count sentinel",
        folded.get(fm.finding_id).status === "verified-closed" &&
          folded.get(fm.finding_id).guard_ref === "ledger-count"
      );
      assertSelfTest(
        "(d) incomplete microcopy probe does not mutate its guard-home spec",
        fs.readFileSync(microcopyDestAbs, "utf8") === microcopyBefore
      );
      assertSelfTest(
        "(d) present:true finding stays resolved with no guard",
        folded.get(fy.finding_id).status === "resolved" && !folded.get(fy.finding_id).guard_ref
      );
      assertSelfTest(
        "(d) finding with no probe entry stays resolved",
        folded.get(fz.finding_id).status === "resolved"
      );
      assertSelfTest(
        "(d) finding resolved in a DIFFERENT round is untouched",
        folded.get(fw.finding_id).status === "resolved"
      );
      assertSelfTest(
        "(d) two promotions: one concrete mint and one ledger-count sentinel",
        res.promoted === 2 && res.minted === 1 && res.ledgerCount === 1 && res.leftResolved === 2
      );
    }

    console.log("ratchet-fix self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

// -----------------------------------------------------------------------------
// Entry point — `--self-test` is checked FIRST, before any real-path file access.
// -----------------------------------------------------------------------------
if (import.meta.url === `file://${process.argv[1]}`) {
  const argv = process.argv.slice(2);
  try {
    if (argv.includes("--self-test")) {
      runSelfTest();
    } else if (argv.includes("--apply-decisions")) {
      runApplyDecisionsCli(argv);
    } else if (argv.includes("--finalize-fixes")) {
      runFinalizeFixesCli();
    } else {
      console.error(
        "ratchet-fix.mjs: pass --apply-decisions [--round N] [--dry-run], --finalize-fixes, or --self-test"
      );
      process.exitCode = 1;
    }
  } catch (error) {
    console.error(`ratchet-fix.mjs error: ${error.message}`);
    process.exitCode = 1;
  }
}

export { validateDecisionsBatch, buildBanner, applyDecisions, finalizeFixes, resolveRound, scopeForRound };
