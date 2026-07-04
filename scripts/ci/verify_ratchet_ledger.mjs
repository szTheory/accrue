/**
 * verify_ratchet_ledger.mjs — the independent CI re-verifier for the UI ratchet's committed
 * forward-only finding ledger (Phase 206, v1.56). Twins `verify_phase200_scorecard.mjs`'s
 * relationship to its own generator script: this file deliberately does NOT import the
 * deterministic reducer module it cross-checks, nor the shared lifecycle/fold helper module
 * (206-01) that reducer itself imports (both committed alongside this script's target data
 * files under `accrue_admin/e2e/ratchet/`) — genuine code independence, so a bug shared
 * between the two would not silently pass both.
 *
 * This is the LAST plane the LLM is permanently kept off of: this CI-facing script never
 * imports the Anthropic SDK package and makes zero network calls (grep-verifiable).
 *
 * Independence discipline:
 *  - This file re-implements its OWN fold-and-recompute over the raw `findings.ledger.ndjson`
 *    rows: parse every line as JSON, assert `seq` is strictly increasing across the whole file
 *    (an independent re-implementation of the same tamper-evidence check the shared lifecycle
 *    helper's `fold()` already performs — deliberately duplicated, not shared), keep only the
 *    latest row per `finding_id` (latest-event-wins), and recompute `confirmed_open` per lens
 *    directly from that independently-folded state.
 *  - It NEVER reads `ledger.baseline.json`'s own stored `confirmed_open` numbers as an input to
 *    the recompute — only as the thing being cross-checked against. Any mismatch (in either
 *    direction, for any of the 7 lens keys) is a hard failure (LEDGER-04's literal contract: "a
 *    hand-edited baseline that disagrees with the raw-row recompute must fail").
 *  - `GUARD_HOME_SPECS` (the closed 4-path allowlist) and the `guard_ref` static-substring
 *    presence check are duplicated here verbatim from the deterministic reducer's own
 *    D-39/D-40 logic — again intentional duplication for independence, not an import.
 *  - `finding-regressions.ndjson` is independently re-read as raw bytes off disk
 *    (`fs.statSync(...).size === 0`) rather than trusting any prior process's reported exit
 *    code — this single check transitively re-confirms every regression kind the deterministic
 *    reducer already detects (count-increase, guard-missing, illegal-reopen), since any of
 *    those would have left that file non-empty.
 *  - The ONE deliberate exception to the independence rule: `region-tags.js`'s
 *    `isAdmissibleToken()` is imported and reused rather than re-derived a second time, since
 *    re-implementing that token grammar risks silent divergence (Don't Hand-Roll). The 7-value
 *    lens-key enum is, like `GUARD_HOME_SPECS`, duplicated locally as its own closed constant
 *    (`region-tags.js` does not itself define the lens-key vocabulary).
 *
 * Usage:
 *   node scripts/ci/verify_ratchet_ledger.mjs              # run against the real committed files
 *   node scripts/ci/verify_ratchet_ledger.mjs --self-test   # pure fixture proof, no real reads
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as regionTags from "../../accrue_admin/e2e/ratchet/region-tags.js";

const { isAdmissibleToken } = regionTags;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// __dirname === <repo>/scripts/ci — go up 2 levels to the repo root (mirrors
// verify_phase200_scorecard.mjs's own REPO_ROOT computation).
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const RATCHET_DIR = path.join(REPO_ROOT, "accrue_admin", "e2e", "ratchet");

const DEFAULT_PATHS = {
  ledgerPath: path.join(RATCHET_DIR, "findings.ledger.ndjson"),
  baselinePath: path.join(RATCHET_DIR, "ledger.baseline.json"),
  reopenMarkersPath: path.join(RATCHET_DIR, "reopen-markers.ndjson"),
  regressionsPath: path.join(RATCHET_DIR, "finding-regressions.ndjson"),
};

/**
 * LENS_KEYS — the closed 7-value per-lens gate key (D-24/D-25). Duplicated here as its own
 * independent constant (NOT imported from any sibling module) — mirrors the intentional
 * `GUARD_HOME_SPECS` duplication below: re-deriving the SAME literal 7-value set a second time
 * is what makes this file's recompute a genuine cross-check rather than a shared blind spot.
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

/**
 * GUARD_HOME_SPECS — the closed D-39 allowlist, duplicated verbatim from the deterministic
 * reducer's own copy. `guard_ref` path components must be a literal member of this array
 * (path-safety, T-206-04-04) — this repetition is intentional duplication for independence.
 */
const GUARD_HOME_SPECS = [
  "accrue_admin/e2e/foundation-tokens.spec.js",
  "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js",
  "accrue_admin/e2e/reduced-motion.spec.js",
  "accrue_admin/e2e/admin-page-flow-phase200.spec.js",
];

// -----------------------------------------------------------------------------
// Small IO helpers.
// -----------------------------------------------------------------------------

/** readRawLedgerLines(ledgerPath) — an absent or empty file parses to `[]`, never throws. */
function readRawLedgerLines(ledgerPath) {
  let raw;
  try {
    raw = fs.readFileSync(ledgerPath, "utf8");
  } catch (error) {
    if (error && error.code === "ENOENT") return [];
    throw error;
  }
  const text = raw.trim();
  if (!text) return [];
  return text.split("\n").map((line) => JSON.parse(line));
}

/** readBaseline(baselinePath, failures) — absent/empty/malformed all degrade to `{confirmed_open: {}}`. */
function readBaseline(baselinePath, failures) {
  if (!fs.existsSync(baselinePath)) return { confirmed_open: {} };
  const raw = fs.readFileSync(baselinePath, "utf8").trim();
  if (!raw) return { confirmed_open: {} };
  try {
    return JSON.parse(raw);
  } catch (error) {
    failures.malformedJson.push(`ledger.baseline.json malformed JSON: ${error.message}`);
    return { confirmed_open: {} };
  }
}

function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function writeNdjson(absPath, rows) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  const text = rows.map((row) => JSON.stringify(row)).join("\n") + (rows.length ? "\n" : "");
  fs.writeFileSync(absPath, text);
}

// -----------------------------------------------------------------------------
// Independent fold + per-lens recompute (T-206-04-01).
// -----------------------------------------------------------------------------

/**
 * independentFold(rawRows) — this file's OWN latest-event-wins fold, re-implemented from
 * scratch rather than imported. Asserts `seq` is strictly increasing across the whole file
 * (pushing to `seqFailures` rather than throwing, so a tampered ledger surfaces as a normal
 * `ok:false` result instead of crashing the CLI). Returns `{folded: Map<finding_id, latestRow>,
 * seqFailures: string[]}`.
 */
function independentFold(rawRows) {
  const folded = new Map();
  const seqFailures = [];
  let maxSeq = -Infinity;
  for (const row of rawRows) {
    if (typeof row.seq !== "number" || !(row.seq > maxSeq)) {
      seqFailures.push(
        `seq not monotonic (independent recompute): finding_id=${JSON.stringify(
          row.finding_id
        )} seq=${JSON.stringify(row.seq)}`
      );
      continue;
    }
    maxSeq = row.seq;
    folded.set(row.finding_id, row);
  }
  return { folded, seqFailures };
}

/**
 * computeIndependentOpenCounts(foldedRowsMap) — recompute per-lens `{total, minor, real}` open
 * counts directly from the independently-folded state. Never reads `ledger.baseline.json`.
 */
function computeIndependentOpenCounts(foldedRowsMap) {
  const counts = {};
  for (const lens of LENS_KEYS) counts[lens] = { total: 0, minor: 0, real: 0 };

  for (const row of foldedRowsMap.values()) {
    if (row.status !== "open") continue;
    const lenses = Array.isArray(row.raised_by_lenses) ? row.raised_by_lenses : [];
    for (const lens of lenses) {
      if (!counts[lens]) continue; // defensive — never a gate key outside the closed 7-value enum
      counts[lens].total += 1;
      if (row.severity === "minor") counts[lens].minor += 1;
      else if (row.severity === "real") counts[lens].real += 1;
    }
  }
  return counts;
}

/**
 * compareAgainstBaseline(independentCounts, baselineConfirmedOpen, failures) — the literal
 * LEDGER-04 contract: ANY disagreement (in either direction) between this file's own
 * independently-recomputed per-lens totals and the committed baseline's STORED numbers is a
 * hard failure pushed to `failures.baselineMismatch`.
 */
function compareAgainstBaseline(independentCounts, baselineConfirmedOpen, failures) {
  const baselineOpen = baselineConfirmedOpen || {};
  for (const lens of LENS_KEYS) {
    const independent = independentCounts[lens];
    const stored = baselineOpen[lens] || { total: 0, minor: 0, real: 0 };
    const storedTotal = stored.total ?? 0;
    const storedMinor = stored.minor ?? 0;
    const storedReal = stored.real ?? 0;
    if (
      independent.total !== storedTotal ||
      independent.minor !== storedMinor ||
      independent.real !== storedReal
    ) {
      failures.baselineMismatch.push(
        `Lens ${lens}: ledger.baseline.json stores confirmed_open ${JSON.stringify({
          total: storedTotal,
          minor: storedMinor,
          real: storedReal,
        })} but the independent recompute from raw findings.ledger.ndjson rows is ${JSON.stringify(
          independent
        )}.`
      );
    }
  }
}

// -----------------------------------------------------------------------------
// guard_ref path-safety + static-substring presence check (T-206-04-04) — a SECOND,
// independently-duplicated confirmation of the same D-39/D-40 contract.
// -----------------------------------------------------------------------------

/**
 * validGuardHomePath(specPath) — path-safety check (no absolute path, no backslash, no `..`
 * component) plus closed-allowlist membership, adapted from `verify_phase200_scorecard.mjs`'s
 * `validArtifactRef`-style shape (lines 220-234) into this file's `GUARD_HOME_SPECS` domain.
 */
function validGuardHomePath(specPath) {
  if (typeof specPath !== "string" || specPath.length === 0) return false;
  if (path.isAbsolute(specPath)) return false;
  if (specPath.includes("\\")) return false;
  if (specPath.split("/").includes("..")) return false;
  return GUARD_HOME_SPECS.includes(specPath);
}

/**
 * extractArrayLiteral(sourceText, constName) — WR-03: read a sibling file's array-literal
 * constant declaration AS TEXT (never `require`/`import` it — this file's whole independence
 * design is to never depend at RUNTIME on the modules/constants it cross-checks) and
 * regex-extract + `JSON.parse` its literal value. Used ONLY by `runSelfTest()` below, as a
 * cheap self-test-time-only consistency assertion that a hand-duplicated closed-enum array
 * (`GUARD_HOME_SPECS`, `LENS_KEYS`) has not silently drifted from its sibling copy — closing
 * the gap where a future phase adds/removes an entry in one file and forgets the other, which
 * would otherwise go undetected until an unexplained CI pass/fail mismatch.
 */
function extractArrayLiteral(sourceText, constName) {
  const re = new RegExp(`const ${constName}\\s*=\\s*(\\[[\\s\\S]*?\\]);`);
  const match = re.exec(sourceText);
  if (!match) {
    throw new Error(`extractArrayLiteral: could not find ${constName} declaration in source`);
  }
  // Strip trailing commas before a closing `]` — valid JS array-literal syntax (as used by both
  // sibling files' formatting), but not valid JSON.
  const jsonish = match[1].replace(/,(\s*\])/g, "$1");
  return JSON.parse(jsonish);
}

/**
 * checkGuardRefIndependent(guardRef, findingId, repoRoot) — re-implements the D-39/D-40
 * static-substring guard-presence contract from scratch. `guard_ref === "ledger-count"` is the
 * D-40 explicit no-real-guard sentinel and always passes. Otherwise splits on the literal `"::"`
 * separator, validates the spec path against `validGuardHomePath`, validates the
 * `@ratchet:f-[0-9a-f]{16}` token grammar with a `finding_id` cross-wire check, and reads the
 * spec file for a literal substring match of the token.
 */
function checkGuardRefIndependent(guardRef, findingId, repoRoot) {
  if (guardRef === "ledger-count") return { ok: true };
  if (typeof guardRef !== "string") return { ok: false };

  const parts = guardRef.split("::");
  if (parts.length !== 2 || !parts[0] || !parts[1]) return { ok: false };
  const [specPath, token] = parts;

  if (!validGuardHomePath(specPath)) return { ok: false };

  const tokenMatch = /^@ratchet:(f-[0-9a-f]{16})$/.exec(token);
  if (!tokenMatch || tokenMatch[1] !== findingId) return { ok: false };

  const absSpecPath = path.join(repoRoot, specPath);
  if (!fs.existsSync(absSpecPath)) return { ok: false };

  const contents = fs.readFileSync(absSpecPath, "utf8");
  if (!contents.includes(token)) return { ok: false };

  return { ok: true };
}

/**
 * checkGuardRefsIndependent(foldedRowsMap, repoRoot, failures) — runs
 * `checkGuardRefIndependent()` against every folded row whose `status` is `"resolved"` or
 * `"verified-closed"`; a failing result pushes a `failures.guardMissing` entry. This is a
 * SECOND, independent confirmation of whatever the deterministic reducer already checked —
 * genuine cross-validation, not shared code.
 */
function checkGuardRefsIndependent(foldedRowsMap, repoRoot, failures) {
  for (const row of foldedRowsMap.values()) {
    if (row.status !== "resolved" && row.status !== "verified-closed") continue;
    const result = checkGuardRefIndependent(row.guard_ref, row.finding_id, repoRoot);
    if (!result.ok) {
      failures.guardMissing.push(
        `Finding ${row.finding_id} (status=${row.status}) has a missing or invalid guard_ref ` +
          `(independent re-check): ${JSON.stringify(row.guard_ref)}.`
      );
    }
  }
}

// -----------------------------------------------------------------------------
// justification_token re-admissibility check — the one deliberate reuse of region-tags.js
// (Don't Hand-Roll: re-implementing the token grammar a second time risks silent divergence).
// -----------------------------------------------------------------------------

/**
 * checkJustificationTokensIndependent(foldedRowsMap, failures) — for every folded row that
 * still carries a `justification_token`, independently re-validates it via `region-tags.js`'s
 * `isAdmissibleToken()`. This is a defense-in-depth re-check against a row whose token was
 * hand-inserted or corrupted directly in the committed ledger, bypassing the append-time gate
 * upstream — a genuine second confirmation, using the SAME shared grammar rather than a
 * re-derived (and possibly divergent) copy of it.
 */
function checkJustificationTokensIndependent(foldedRowsMap, failures) {
  for (const row of foldedRowsMap.values()) {
    if (row.justification_token == null) continue;
    if (!isAdmissibleToken(row.justification_token)) {
      failures.inadmissibleToken.push(
        `Finding ${row.finding_id} carries an inadmissible justification_token: ${JSON.stringify(
          row.justification_token
        )}.`
      );
    }
  }
}

// -----------------------------------------------------------------------------
// finding-regressions.ndjson zero-byte check (T-206-04-02) — raw bytes off disk, never a
// trusted prior exit code.
// -----------------------------------------------------------------------------

/**
 * checkRegressionsZeroBytes(regressionsPath, failures) — reads the raw byte size directly off
 * disk via `fs.statSync`. An absent file degrades to size `0` (trivially clean — matches the
 * committed-file convention elsewhere in this codebase); any non-zero size is a hard failure.
 */
function checkRegressionsZeroBytes(regressionsPath, failures) {
  let size = 0;
  try {
    size = fs.statSync(regressionsPath).size;
  } catch (error) {
    if (error && error.code === "ENOENT") {
      size = 0;
    } else {
      throw error;
    }
  }
  if (size !== 0) {
    failures.regressionsNotEmpty.push(
      `finding-regressions.ndjson is ${size} bytes (expected exactly 0) — real regressions may exist.`
    );
  }
}

// -----------------------------------------------------------------------------
// Top-level verifier.
// -----------------------------------------------------------------------------

function failureTemplate() {
  return {
    seqNotMonotonic: [],
    malformedJson: [],
    baselineMismatch: [],
    guardMissing: [],
    inadmissibleToken: [],
    regressionsNotEmpty: [],
  };
}

/**
 * verifyRatchetLedger(overridePaths) — the independent CI re-verifier. Accepts the same
 * overridable `{ledgerPath, baselinePath, reopenMarkersPath, regressionsPath}` shape the
 * deterministic reducer accepts, defaulting to the real committed repo paths. `reopenMarkersPath`
 * is accepted for shape parity but unused — this file's own duty is the baseline-mismatch
 * recompute (LEDGER-04) plus the guard_ref and regressions-byte-count second checks; the
 * illegal-reopen/count-increase regression kinds are transitively re-confirmed by the
 * `finding-regressions.ndjson` zero-byte check (LEDGER-05), never re-derived here. Returns
 * `{ok: boolean, failures: {...}}` and NEVER throws on ordinary tampered/malformed input.
 */
export function verifyRatchetLedger(overridePaths = {}) {
  const paths = { ...DEFAULT_PATHS, ...overridePaths };
  const failures = failureTemplate();

  const rawRows = readRawLedgerLines(paths.ledgerPath);
  const { folded, seqFailures } = independentFold(rawRows);
  failures.seqNotMonotonic.push(...seqFailures);

  const independentCounts = computeIndependentOpenCounts(folded);
  const baseline = readBaseline(paths.baselinePath, failures);
  compareAgainstBaseline(independentCounts, baseline.confirmed_open, failures);

  checkGuardRefsIndependent(folded, REPO_ROOT, failures);
  checkJustificationTokensIndependent(folded, failures);

  checkRegressionsZeroBytes(paths.regressionsPath, failures);

  const ok = Object.values(failures).every((items) => items.length === 0);
  return { ok, failures };
}

// -----------------------------------------------------------------------------
// --self-test (mkdtemp fixtures — never touches the real committed accrue_admin/e2e/ratchet/
// files).
// -----------------------------------------------------------------------------

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function emptyBaseline() {
  const confirmed_open = {};
  for (const lens of LENS_KEYS) confirmed_open[lens] = { total: 0, minor: 0, real: 0 };
  return {
    schema_version: "ratchet-ledger-baseline/1",
    frozen: false,
    epoch: 1,
    ledger_sha256: "0".repeat(64),
    confirmed_open,
    resolved_locked: [],
  };
}

/**
 * writeFixtureFiles(dir, {...}) — writes one fixture scenario's own synthetic
 * `findings.ledger.ndjson`/`ledger.baseline.json`/`reopen-markers.ndjson`/
 * `finding-regressions.ndjson` quadruple under `dir` and returns the override-paths object.
 */
function writeFixtureFiles(dir, { ledgerRows = [], baseline = null, regressionsText = "" } = {}) {
  fs.mkdirSync(dir, { recursive: true });
  const paths = {
    ledgerPath: path.join(dir, "findings.ledger.ndjson"),
    baselinePath: path.join(dir, "ledger.baseline.json"),
    reopenMarkersPath: path.join(dir, "reopen-markers.ndjson"),
    regressionsPath: path.join(dir, "finding-regressions.ndjson"),
  };
  writeNdjson(paths.ledgerPath, ledgerRows);
  if (baseline) writeJson(paths.baselinePath, baseline);
  fs.writeFileSync(paths.reopenMarkersPath, "");
  fs.mkdirSync(path.dirname(paths.regressionsPath), { recursive: true });
  fs.writeFileSync(paths.regressionsPath, regressionsText);
  return paths;
}

/**
 * runSelfTest() — proves, on independent `fs.mkdtempSync` fixtures, never touching the real
 * committed ledger/baseline/regressions files, the plan's 5 required scenarios: (1) an absent
 * baseline file (default-all-zero) against an empty ledger exits `ok:true`; (2) a
 * `ledger.baseline.json` hand-edited so its `confirmed_open` numbers disagree with what the raw
 * ledger rows actually fold to exits `ok:false` with a non-empty `failures.baselineMismatch`
 * (the core LEDGER-04 assertion); (3) a non-empty `finding-regressions.ndjson` exits `ok:false`;
 * (4) a `resolved` row whose `guard_ref` token is absent from its named (real, on-disk)
 * `GUARD_HOME_SPECS` file exits `ok:false` with a `failures.guardMissing` entry; (5) a
 * genuinely-matching NON-ZERO ledger/baseline pair (proving the recompute is a real cross-check,
 * not a trivial both-zero pass) exits `ok:true`. Plus one additional fixture (6) proving the
 * deliberate `region-tags.js` reuse actually gates: an open finding carrying an inadmissible
 * `justification_token` exits `ok:false` with a `failures.inadmissibleToken` entry.
 */
function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-ledger-verifier-"));
  try {
    // (1) absent baseline file (default-all-zero) against an empty ledger.
    {
      const paths = writeFixtureFiles(path.join(root, "fixture-absent-baseline"), {});
      const result = verifyRatchetLedger(paths);
      assertSelfTest(
        "(1) empty ledger against absent (default-all-zero) baseline exits ok:true",
        result.ok,
        JSON.stringify(result.failures)
      );
    }

    // (2) hand-edited baseline disagreeing with the raw ledger rows (LEDGER-04 core assertion).
    {
      const baseline = emptyBaseline();
      baseline.confirmed_open["persona:operator-founder"] = { total: 1, minor: 0, real: 1 };
      const paths = writeFixtureFiles(path.join(root, "fixture-baseline-mismatch"), { baseline });
      const result = verifyRatchetLedger(paths);
      assertSelfTest("(2) hand-edited baseline disagreement exits ok:false", !result.ok);
      assertSelfTest(
        "(2) failures.baselineMismatch is non-empty",
        result.failures.baselineMismatch.length > 0,
        JSON.stringify(result.failures)
      );
    }

    // (3) non-empty finding-regressions.ndjson.
    {
      const paths = writeFixtureFiles(path.join(root, "fixture-nonempty-regressions"), {
        baseline: emptyBaseline(),
        regressionsText: `${JSON.stringify({ kind: "count-increase", lens: "design" })}\n`,
      });
      const result = verifyRatchetLedger(paths);
      assertSelfTest("(3) non-empty finding-regressions.ndjson exits ok:false", !result.ok);
      assertSelfTest(
        "(3) failures.regressionsNotEmpty is non-empty",
        result.failures.regressionsNotEmpty.length > 0
      );
    }

    // (4) resolved row whose guard_ref token is absent from its named REAL on-disk
    // GUARD_HOME_SPECS file.
    {
      const findingId = "f-abc0000000000099";
      const paths = writeFixtureFiles(path.join(root, "fixture-guard-missing"), {
        ledgerRows: [
          {
            finding_id: findingId,
            seq: 1,
            event: "resolve",
            status: "resolved",
            raised_by_lenses: [],
            severity: "real",
            guard_ref: `accrue_admin/e2e/foundation-tokens.spec.js::@ratchet:${findingId}`,
          },
        ],
        baseline: emptyBaseline(),
      });
      const result = verifyRatchetLedger(paths);
      assertSelfTest("(4) guard_ref token absent from real spec file exits ok:false", !result.ok);
      assertSelfTest("(4) failures.guardMissing is non-empty", result.failures.guardMissing.length > 0);
    }

    // (5) genuinely-matching NON-ZERO ledger/baseline pair — proves the recompute is a real
    // cross-check, not a trivial both-zero pass.
    {
      const findingId = "f-2222222222222299";
      const baseline = emptyBaseline();
      baseline.confirmed_open.design = { total: 1, minor: 0, real: 1 };
      const paths = writeFixtureFiles(path.join(root, "fixture-matching-nonzero"), {
        ledgerRows: [
          {
            finding_id: findingId,
            seq: 1,
            event: "confirm",
            status: "open",
            raised_by_lenses: ["design"],
            severity: "real",
          },
        ],
        baseline,
      });
      const result = verifyRatchetLedger(paths);
      assertSelfTest(
        "(5) genuinely-matching non-zero recompute exits ok:true",
        result.ok,
        JSON.stringify(result.failures)
      );
    }

    // (6) an open finding carrying an inadmissible justification_token — proves the deliberate
    // region-tags.js reuse (isAdmissibleToken) actually gates rather than sitting unused.
    {
      const findingId = "f-3333333333333399";
      const baseline = emptyBaseline();
      baseline.confirmed_open.design = { total: 1, minor: 0, real: 1 };
      const paths = writeFixtureFiles(path.join(root, "fixture-inadmissible-token"), {
        ledgerRows: [
          {
            finding_id: findingId,
            seq: 1,
            event: "confirm",
            status: "open",
            raised_by_lenses: ["design"],
            severity: "real",
            justification_token: "not-an-admissible-token",
          },
        ],
        baseline,
      });
      const result = verifyRatchetLedger(paths);
      assertSelfTest("(6) inadmissible justification_token exits ok:false", !result.ok);
      assertSelfTest(
        "(6) failures.inadmissibleToken is non-empty",
        result.failures.inadmissibleToken.length > 0
      );
    }

    // (7) WR-03: cross-file consistency check — the two hand-duplicated closed-enum arrays
    // (`GUARD_HOME_SPECS`, `LENS_KEYS`) must stay byte-identical to their sibling copies.
    // `phase-ratchet-ledger.mjs` defines its OWN `GUARD_HOME_SPECS` but imports its
    // `LENS_KEYS` from `ratchet-ledger.js` (`const { fold, LENS_KEYS } = ratchetLedger`) —
    // so the canonical `LENS_KEYS` to compare this file's own independent copy against lives
    // in `ratchet-ledger.js`, not `phase-ratchet-ledger.mjs`. Read as raw source text, never
    // imported — this is a self-test-time-only assertion, not a runtime dependency.
    {
      const phaseReducerSource = fs.readFileSync(
        path.join(RATCHET_DIR, "phase-ratchet-ledger.mjs"),
        "utf8"
      );
      const ledgerSource = fs.readFileSync(path.join(RATCHET_DIR, "ratchet-ledger.js"), "utf8");

      const reducerGuardHomeSpecs = extractArrayLiteral(phaseReducerSource, "GUARD_HOME_SPECS");
      assertSelfTest(
        "(7) GUARD_HOME_SPECS stays byte-identical between this file and phase-ratchet-ledger.mjs",
        JSON.stringify(reducerGuardHomeSpecs) === JSON.stringify(GUARD_HOME_SPECS),
        JSON.stringify({ reducerGuardHomeSpecs, thisFile: GUARD_HOME_SPECS })
      );

      const canonicalLensKeys = extractArrayLiteral(ledgerSource, "LENS_KEYS");
      assertSelfTest(
        "(7) LENS_KEYS stays byte-identical between this file's own copy and ratchet-ledger.js's " +
          "canonical array (the one phase-ratchet-ledger.mjs actually imports)",
        JSON.stringify(canonicalLensKeys) === JSON.stringify(LENS_KEYS),
        JSON.stringify({ canonicalLensKeys, thisFile: LENS_KEYS })
      );
    }

    console.log("verify_ratchet_ledger self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

// -----------------------------------------------------------------------------
// CLI entry point.
// -----------------------------------------------------------------------------

function reportFailures(failures) {
  console.error("verify_ratchet_ledger.mjs: independent recompute failed.");
  for (const [section, items] of Object.entries(failures)) {
    if (items.length === 0) continue;
    console.error(`\n${section}:`);
    for (const item of items) console.error(`- ${item}`);
  }
}

function main() {
  // `--self-test` is checked FIRST, before any file-system read against the real committed
  // paths — running it never touches DEFAULT_PATHS.
  if (process.argv.includes("--self-test")) {
    runSelfTest();
    return;
  }

  const result = verifyRatchetLedger(DEFAULT_PATHS);
  console.log(`[verify-ratchet-ledger] ok=${result.ok}`);
  if (!result.ok) {
    reportFailures(result.failures);
    process.exitCode = 1;
  } else {
    console.log(
      "[verify-ratchet-ledger] independent recompute matches the committed baseline; finding-regressions.ndjson is 0 bytes."
    );
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`verify_ratchet_ledger.mjs crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
