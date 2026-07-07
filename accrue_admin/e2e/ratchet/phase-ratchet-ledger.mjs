/**
 * phase-ratchet-ledger.mjs — the deterministic sibling gate for the UI ratchet's forward-only
 * finding ledger (Phase 206, v1.56). Twins `phase200-scorecard.mjs`'s asymmetric
 * forward-only-compare + `--self-test`-on-fixtures discipline (D-37), adapted from per-cell
 * score/coverage to per-lens open-finding counts.
 *
 * This is the DETERMINISTIC PLANE. Zero network calls, zero LLM, zero live-model credential
 * dependency — it only folds the committed `findings.ledger.ndjson` (via `ratchet-ledger.js`'s
 * `fold()`, never reimplemented here), computes per-lens `confirmed_open` counts (D-24 — the
 * closed 7-value lens enum), asymmetrically compares them against `ledger.baseline.json`
 * (fires only on increase, D-26), checks `guard_ref` presence via a static substring read of a
 * committed guard-home spec file (D-39/D-40), checks `reopen-markers.ndjson` legitimacy
 * (D-41), and writes `finding-regressions.ndjson`. The `--freeze` gate (D-37) refuses to
 * overwrite a frozen baseline unless explicitly invoked with `--freeze` (reserved for Phase 208).
 *
 * Usage:
 *   node e2e/ratchet/phase-ratchet-ledger.mjs              # run against the real committed files
 *   node e2e/ratchet/phase-ratchet-ledger.mjs --self-test   # pure fixture proof, no real writes
 *   node e2e/ratchet/phase-ratchet-ledger.mjs --freeze      # Phase 208 only — permits writing a
 *                                                            # frozen baseline
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import * as ratchetLedger from "./ratchet-ledger.js";
// Plain static data import — `baseline-manifest.js` is a pure CommonJS data module (zero
// side effects, zero credential/key gating), unlike the dynamic key-gated SDK import in
// `ratchet-propose.mjs`. `SURFACES` is the closed set of admin surfaces the coverage-floor
// clause (D-48) resolves "scope=all" against.
import baselineManifest from "../baseline-manifest.js";

const { fold, LENS_KEYS } = ratchetLedger;
const { SLICES, SURFACES } = baselineManifest;

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// __dirname === accrue_admin/e2e/ratchet/ — go up 3 levels to the repo root.
const REPO_ROOT = path.resolve(__dirname, "../../..");

// -----------------------------------------------------------------------------
// Path constants (D-38/D-27/D-41) — every computation below accepts these as an OPTIONAL
// overridable `{ledgerPath, baselinePath, reopenMarkersPath, regressionsPath}` parameter
// object, defaulting to the real committed paths here. This is what lets `--self-test`
// redirect every read/write to an `fs.mkdtempSync` scratch root without ever touching the
// real committed files (LEDGER-05).
// -----------------------------------------------------------------------------
const DEFAULT_PATHS = {
  ledgerPath: path.join(__dirname, "findings.ledger.ndjson"),
  baselinePath: path.join(__dirname, "ledger.baseline.json"),
  reopenMarkersPath: path.join(__dirname, "reopen-markers.ndjson"),
  regressionsPath: path.join(__dirname, "finding-regressions.ndjson"),
  roundsPath: path.join(__dirname, "rounds.ndjson"),
};

// -----------------------------------------------------------------------------
// Round-state paths (207-01, D-47/D-48/D-49). `NEXT_ROUND_MARKER_PATH` and
// `ROUND_STATUS_MARKER_PATH` are EPHEMERAL scalar handoff files to the (later) Elixir
// orchestrator — NOT gate-relevant committed artifacts, so they live under the already-
// gitignored repo-root `test-results/` tree and are deliberately absent from DEFAULT_PATHS.
// -----------------------------------------------------------------------------
const NEXT_ROUND_MARKER_PATH = path.join(__dirname, "../../test-results/ui-ratchet/.round-next");
const ROUND_STATUS_MARKER_PATH = path.join(REPO_ROOT, "accrue_admin/test-results/ui-ratchet/.round-status");

// Standing forward-only scorecard artifacts from Phase 200 (repo-root-relative). An ABSENT file
// is treated as empty/pass, matching `readNdjsonRows`'s absence-safe convention.
const STANDING_REGRESSIONS_PATH = path.join(
  REPO_ROOT,
  ".planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/regressions.ndjson"
);
const CELLS_CENSUS_PATH = path.join(
  REPO_ROOT,
  ".planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/final.cells.json"
);
const BUNDLE_PATH = path.join(REPO_ROOT, "accrue_admin/priv/static/accrue_admin.css");

/**
 * GUARD_HOME_SPECS — the closed D-39 allowlist. `guard_ref` path components must be a literal
 * member of this array (path-safety, T-206-03-01) — no dedicated 5th ratchet guard-home spec is
 * minted this phase (Phase 207's guard-minting work decides case-by-case whether one is
 * warranted).
 */
const GUARD_HOME_SPECS = [
  "accrue_admin/e2e/foundation-tokens.spec.js",
  "accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js",
  "accrue_admin/e2e/reduced-motion.spec.js",
  "accrue_admin/e2e/admin-page-flow-phase200.spec.js",
];

// -----------------------------------------------------------------------------
// Small IO helpers (twin `phase200-scorecard.mjs`'s conventions verbatim).
// -----------------------------------------------------------------------------

/** sha256(absPath) — copied verbatim from `phase200-scorecard.mjs:238-240`. */
function sha256(absPath) {
  return createHash("sha256").update(fs.readFileSync(absPath)).digest("hex");
}

/** ledgerSha256(ledgerPath) — sha256 of the ledger file, or of an empty buffer if absent. */
function ledgerSha256(ledgerPath) {
  if (fs.existsSync(ledgerPath)) return sha256(ledgerPath);
  return createHash("sha256").update("").digest("hex");
}

/** readNdjsonRows(absPath) — an absent or empty file parses to `[]`; never throws on absence. */
function readNdjsonRows(absPath) {
  let raw;
  try {
    raw = fs.readFileSync(absPath, "utf8");
  } catch (err) {
    if (err && err.code === "ENOENT") return [];
    throw err;
  }
  const text = raw.trim();
  if (!text) return [];
  return text.split("\n").map((line) => JSON.parse(line));
}

/** writeJson(absPath, value) — 2-space indent + trailing newline, matching phase200's convention. */
function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

/** writeNdjson(absPath, rows) — 0-byte-on-empty contract (twin of phase200's regressions.ndjson). */
function writeNdjson(absPath, rows) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  const text = rows.map((row) => JSON.stringify(row)).join("\n") + (rows.length ? "\n" : "");
  fs.writeFileSync(absPath, text);
}

/**
 * readBaseline(baselinePath) — an absent or empty file is treated as the empty starting
 * baseline `{frozen: false, epoch: 0, confirmed_open: {}, resolved_locked: []}`.
 */
function readBaseline(baselinePath) {
  const empty = { frozen: false, epoch: 0, confirmed_open: {}, resolved_locked: [] };
  if (!fs.existsSync(baselinePath)) return empty;
  const raw = fs.readFileSync(baselinePath, "utf8").trim();
  if (!raw) return empty;
  return JSON.parse(raw);
}

/**
 * regressionRow(kind, lens, baselineValue, currentValue, message) — adapts
 * `phase200-scorecard.mjs`'s `regressionRow()` (line 386) to this file's per-lens/per-finding
 * domain. `lens` carries whichever identifier is meaningful for `kind`: the lens key for
 * `count-increase`, the `finding_id` for `guard-missing`, the `claim_key` for `illegal-reopen`.
 */
function regressionRow(kind, lens, baselineValue, currentValue, message) {
  return {
    kind,
    lens,
    baseline_value: baselineValue,
    current_value: currentValue,
    message,
  };
}

// -----------------------------------------------------------------------------
// Round-state helpers (207-01, D-47) — pure, fs-free; the self-test drives them with
// in-memory arrays.
// -----------------------------------------------------------------------------

/**
 * computeNextRound(roundsRows) — the next round integer for the append-only `rounds.ndjson`
 * event log: `max(0, ...round values) + 1`, order-independent. An empty log yields `1`; a log
 * whose rows carry `round ∈ {1,2,3}` (in any order) yields `4`.
 */
function computeNextRound(roundsRows) {
  return Math.max(0, ...roundsRows.map((row) => row.round || 0)) + 1;
}

// -----------------------------------------------------------------------------
// D-48 dry-round 4-clause conjunction + D-49 K=2/6-cap convergence — all pure, parameterized,
// fs-free EXCEPT the two file-reading clauses (which accept explicit paths, mirroring the
// existing `computeRegressions(paths)` vs `runReducer(paths)` split). The self-test flips each
// input independently on `fs.mkdtempSync` fixtures.
// -----------------------------------------------------------------------------

/**
 * computeClauseNewOpens(foldedFindings, currentRound) — Clause 1: passes iff NO folded finding's
 * latest row is a `confirm` raised THIS round. A finding whose latest event is `confirm` with
 * `round === currentRound` is a brand-new open this round and fails the clause.
 */
function computeClauseNewOpens(foldedFindings, currentRound) {
  return !foldedFindings.some((f) => f.event === "confirm" && f.round === currentRound);
}

/**
 * computeClauseZeroOpen(foldedFindings) — Clause 2: passes iff NO folded finding remains
 * `status === "open"` (any round). A single still-open finding fails the clause.
 */
function computeClauseZeroOpen(foldedFindings) {
  return !foldedFindings.some((f) => f.status === "open");
}

/**
 * computeClauseRegressionsEmpty(findingRegressionsPath, standingRegressionsPath) — Clause 3:
 * passes iff BOTH the just-written `finding-regressions.ndjson` and the standing Phase-200
 * scorecard `regressions.ndjson` are empty (absent / 0-byte / whitespace-only all read as `[]`
 * via the absence-safe `readNdjsonRows`).
 */
function computeClauseRegressionsEmpty(findingRegressionsPath, standingRegressionsPath) {
  return (
    readNdjsonRows(findingRegressionsPath).length === 0 &&
    readNdjsonRows(standingRegressionsPath).length === 0
  );
}

/**
 * scoreFloorRowsForScopeMember(cellsCensusRows, scopeMember) — resolve one capture-scope member
 * to the Phase 200 score-floor rows that prove it. Exact surface matches are used for ordinary
 * page captures. The `component-kitchen` capture is not itself a census surface; it renders the
 * component-family and component-group design-system rows, so it expands to those row families.
 * If explicit scored Phase 200 rows exist for a member, ignore older fallback rows with null score.
 */
function scoreFloorRowsForScopeMember(cellsCensusRows, scopeMember) {
  const matches =
    scopeMember === "component-kitchen"
      ? cellsCensusRows.filter((cell) => cell.surface_type === "component" || cell.surface_type === "component-group")
      : cellsCensusRows.filter((cell) => cell.surface === scopeMember);
  const scoredMatches = matches.filter((cell) => scoreValue(cell) !== null);
  return scoredMatches.length > 0 ? scoredMatches : matches;
}

function scoreValue(cell) {
  if (typeof cell.score === "number") return Number.isFinite(cell.score) ? cell.score : null;
  if (typeof cell.score === "string" && cell.score.trim() !== "") {
    const value = Number(cell.score);
    return Number.isFinite(value) ? value : null;
  }
  return null;
}

function cellMeetsCoverageFloor(cell) {
  const score = scoreValue(cell);
  return cell.coverage_status === "covered" && score !== null && score >= 2;
}

function normalizeScopeMembers(scopeSurfaces) {
  if (scopeSurfaces == null || scopeSurfaces === "all") return null;
  return Array.from(scopeSurfaces).flatMap((surface) =>
    surface === "foundation" ? SLICES.foundation : [surface]
  );
}

/**
 * computeClauseCoverageFloor(cellsCensusRows, scopeSurfaces) — Clause 4: passes iff at least one
 * row is examined and every in-scope score-floor row has `coverage_status === "covered"` and
 * numeric `score >= 2`. `scopeSurfaces` is either the `null`/`"all"` sentinel (no filter — the
 * entire census must satisfy the floor) or a `Set<string>` of capture/slice surface names.
 */
function computeClauseCoverageFloor(cellsCensusRows, scopeSurfaces) {
  const scopeMembers = normalizeScopeMembers(scopeSurfaces);
  const filtered =
    scopeMembers == null
      ? cellsCensusRows
      : scopeMembers.flatMap((surface) => scoreFloorRowsForScopeMember(cellsCensusRows, surface));
  return filtered.length > 0 && filtered.every(cellMeetsCoverageFloor);
}

/** computeDryRound(clauses) — the D-48 conjunction over the 4 clause booleans (as an array). */
function computeDryRound(clauses) {
  return clauses.every(Boolean);
}

/**
 * computeConsecutiveDry(roundsRows, currentEpoch) — the trailing run-length of `dry === true`
 * among rows in `currentEpoch`, in file order. Rows from any OTHER epoch are excluded FIRST so a
 * dry streak never leaks across an epoch boundary (D-49). Counting stops at the first
 * `dry === false` from the tail.
 */
function computeConsecutiveDry(roundsRows, currentEpoch) {
  const scoped = roundsRows.filter((row) => row.epoch === currentEpoch);
  let count = 0;
  for (let i = scoped.length - 1; i >= 0; i--) {
    if (scoped[i].dry === true) count += 1;
    else break;
  }
  return count;
}

/**
 * classifyRoundStatus(consecutiveDry, currentRoundNumber) — D-49: `"converged"` at K=2 consecutive
 * dry rounds; else `"cap-reached"` at the 6-round hard cap; else `"continue"`.
 */
function classifyRoundStatus(consecutiveDry, currentRoundNumber) {
  if (consecutiveDry >= 2) return "converged";
  if (currentRoundNumber >= 6) return "cap-reached";
  return "continue";
}

/**
 * readCellsCensus(absPath) — parse the Phase-200 `final.cells.json` census array; an absent or
 * malformed file (or a non-array top level) reads as `[]`, so Clause 4 fails closed rather than
 * crashing the seal.
 */
function readCellsCensus(absPath) {
  try {
    const raw = fs.readFileSync(absPath, "utf8").trim();
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

/** bundleSha256() — sha256 of the built CSS bundle (D-17 provenance); `null` if absent. */
function bundleSha256() {
  try {
    return sha256(BUNDLE_PATH);
  } catch {
    return null;
  }
}

// -----------------------------------------------------------------------------
// Per-lens open-finding count (D-24/D-25/D-26).
// -----------------------------------------------------------------------------

/**
 * computeCurrentOpenCounts(foldedFindings) — initialize an accumulator keyed by all 7
 * `LENS_KEYS` to `{total, minor, real}`; for every folded finding whose `status === "open"`,
 * and for every lens string in its (sticky, never-mutated) `raised_by_lenses` array, increment
 * that lens's `total` and its `minor`/`real` sub-count matching the finding's `severity` (a
 * finding collapsed across N lenses contributes +1 to EACH of those N lens totals). `theme` is
 * never a lens key.
 */
function computeCurrentOpenCounts(foldedFindings) {
  const counts = {};
  for (const lens of LENS_KEYS) counts[lens] = { total: 0, minor: 0, real: 0 };

  for (const finding of foldedFindings) {
    if (finding.status !== "open") continue;
    const lenses = Array.isArray(finding.raised_by_lenses) ? finding.raised_by_lenses : [];
    for (const lens of lenses) {
      if (!counts[lens]) continue; // defensive — never a gate key outside the closed 7-value enum
      counts[lens].total += 1;
      if (finding.severity === "minor") counts[lens].minor += 1;
      else if (finding.severity === "real") counts[lens].real += 1;
    }
  }
  return counts;
}

/**
 * compareOpenCounts(currentOpenCounts, baseline) — the asymmetric forward-only compare (ported
 * from `compareCells()`, `phase200-scorecard.mjs:488-537`), adapted per-lens: fires a
 * `count-increase` regression ONLY when a lens's current total exceeds its baseline total. A
 * count that decreases or stays equal is silent forward progress, never a regression.
 */
function compareOpenCounts(currentOpenCounts, baseline) {
  const baselineOpen = baseline.confirmed_open || {};
  const regressions = [];
  for (const lens of LENS_KEYS) {
    const currentTotal = currentOpenCounts[lens].total;
    const baselineTotal = baselineOpen[lens]?.total ?? 0;
    if (currentTotal > baselineTotal) {
      regressions.push(
        regressionRow(
          "count-increase",
          lens,
          baselineTotal,
          currentTotal,
          `Lens ${lens} open-finding count increased from ${baselineTotal} to ${currentTotal}.`
        )
      );
    }
  }
  return regressions;
}

// -----------------------------------------------------------------------------
// guard_ref presence check (D-39/D-40, T-206-03-01).
// -----------------------------------------------------------------------------

/** isSafeSpecPath(specPath) — path-safety + closed-allowlist membership (T-206-03-01). */
function isSafeSpecPath(specPath) {
  if (typeof specPath !== "string" || specPath.length === 0) return false;
  if (path.isAbsolute(specPath)) return false;
  if (specPath.includes("\\")) return false;
  if (specPath.split("/").includes("..")) return false;
  return GUARD_HOME_SPECS.includes(specPath);
}

/**
 * checkGuardRef(guard_ref, finding_id, repoRoot) — D-39's inline greppable guard-presence
 * contract, proven by a STATIC SUBSTRING READ of a committed guard-home spec file — no
 * Playwright, no test execution.
 *
 * `guard_ref === "ledger-count"` is the D-40 explicit no-real-guard sentinel: returns
 * `{ok: true}` immediately, no file check at all.
 *
 * Otherwise: splits on the literal `"::"` separator into exactly 2 non-empty parts
 * `[specPath, token]`; rejects an unsafe/non-allowlisted `specPath`; rejects a `token` not
 * matching `/^@ratchet:f-[0-9a-f]{16}$/`; rejects if the embedded `f-[0-9a-f]{16}` id does not
 * equal `finding_id` (prevents cross-wiring a guard onto the wrong finding, T-206-03-01);
 * rejects if the spec file does not exist on disk; rejects if the file's contents do not
 * `.includes(token)`.
 */
function checkGuardRef(guard_ref, finding_id, repoRoot) {
  if (guard_ref === "ledger-count") {
    return { ok: true };
  }
  if (typeof guard_ref !== "string") {
    return { ok: false, kind: "guard-missing" };
  }

  const parts = guard_ref.split("::");
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    return { ok: false, kind: "guard-missing" };
  }
  const [specPath, token] = parts;

  if (!isSafeSpecPath(specPath)) {
    return { ok: false, kind: "guard-missing" };
  }

  const tokenMatch = /^@ratchet:(f-[0-9a-f]{16})$/.exec(token);
  if (!tokenMatch || tokenMatch[1] !== finding_id) {
    return { ok: false, kind: "guard-missing" };
  }

  const absSpecPath = path.join(repoRoot, specPath);
  if (!fs.existsSync(absSpecPath)) {
    return { ok: false, kind: "guard-missing" };
  }

  const contents = fs.readFileSync(absSpecPath, "utf8");
  if (!contents.includes(token)) {
    return { ok: false, kind: "guard-missing" };
  }

  return { ok: true };
}

/**
 * checkGuardRefs(foldedFindings, repoRoot) — runs `checkGuardRef()` against every folded
 * finding whose `status` is `"resolved"` or `"verified-closed"`; a failing result pushes a
 * `guard-missing` regression.
 */
function checkGuardRefs(foldedFindings, repoRoot) {
  const regressions = [];
  for (const finding of foldedFindings) {
    if (finding.status !== "resolved" && finding.status !== "verified-closed") continue;
    const result = checkGuardRef(finding.guard_ref, finding.finding_id, repoRoot);
    if (!result.ok) {
      regressions.push(
        regressionRow(
          "guard-missing",
          finding.finding_id,
          null,
          null,
          `Finding ${finding.finding_id} (status=${finding.status}) has a missing or invalid guard_ref: ${JSON.stringify(
            finding.guard_ref
          )}.`
        )
      );
    }
  }
  return regressions;
}

// -----------------------------------------------------------------------------
// reopen-marker legitimacy check (D-41, T-206-03-03).
// -----------------------------------------------------------------------------

/**
 * checkReopenMarkers(foldedFindings, baseline, reopenMarkersPath) — reads+parses
 * `reopen-markers.ndjson` into a Set of `finding_id`s whose own `epoch` field equals the
 * CURRENT `baseline.epoch`; for every folded finding whose `status === "open"` AND whose
 * `claim_key` is present in `baseline.resolved_locked`, pushes an `illegal-reopen` regression
 * if no entry in that epoch-scoped Set matches its `finding_id`.
 */
function checkReopenMarkers(foldedFindings, baseline, reopenMarkersPath) {
  const reopenRows = readNdjsonRows(reopenMarkersPath);
  const currentEpoch = baseline.epoch;
  const legitReopenIds = new Set(
    reopenRows.filter((row) => row.epoch === currentEpoch).map((row) => row.finding_id)
  );
  const resolvedLockedSet = new Set(baseline.resolved_locked || []);

  const regressions = [];
  for (const finding of foldedFindings) {
    if (finding.status !== "open") continue;
    if (!resolvedLockedSet.has(finding.claim_key)) continue;
    if (legitReopenIds.has(finding.finding_id)) continue;
    regressions.push(
      regressionRow(
        "illegal-reopen",
        finding.claim_key,
        null,
        null,
        `Finding ${finding.finding_id} (claim_key=${finding.claim_key}) reappeared open without a matching current-epoch reopen marker.`
      )
    );
  }
  return regressions;
}

// -----------------------------------------------------------------------------
// --freeze gate (D-37, T-206-03-02).
// -----------------------------------------------------------------------------

/**
 * regenerateBaseline({baselinePath, ledgerPath}, currentOpenCounts, resolvedLocked) —
 * regenerates `ledger.baseline.json` from the CURRENT fold+count computation (D-27 shape).
 * Before writing, reads the EXISTING on-disk baseline fresh: if it has `frozen === true` and
 * `--freeze` is absent from `process.argv`, throws rather than silently overwriting it
 * (Phase 208 only exercises `--freeze`).
 */
function regenerateBaseline({ baselinePath, ledgerPath }, currentOpenCounts, resolvedLocked) {
  const existing = readBaseline(baselinePath);
  const freezeFlagPresent = process.argv.includes("--freeze");

  if (existing.frozen === true && !freezeFlagPresent) {
    throw new Error("Refusing to modify a frozen baseline without --freeze (Phase 208 only).");
  }

  const epoch = existing.epoch && existing.epoch > 0 ? existing.epoch : 1;
  const newBaseline = {
    schema_version: "ratchet-ledger-baseline/1",
    frozen: freezeFlagPresent,
    epoch,
    ledger_sha256: ledgerSha256(ledgerPath),
    confirmed_open: currentOpenCounts,
    resolved_locked: resolvedLocked,
  };

  writeJson(baselinePath, newBaseline);
  return newBaseline;
}

// -----------------------------------------------------------------------------
// Top-level reducer — ties fold + count + compare + guard + reopen together.
// -----------------------------------------------------------------------------

/**
 * computeRegressions(paths) — the pure (no-write) computation: fold the ledger, compute
 * per-lens open counts, read the baseline, and run all 3 regression checks. Never writes
 * anything to disk (only reads).
 */
function computeRegressions(paths) {
  const { ledgerPath, baselinePath, reopenMarkersPath } = paths;

  const ledgerRows = readNdjsonRows(ledgerPath);
  const foldedMap = fold(ledgerRows); // seq-monotonicity violations propagate as a hard failure
  const foldedFindings = Array.from(foldedMap.values());

  const currentOpenCounts = computeCurrentOpenCounts(foldedFindings);
  const baseline = readBaseline(baselinePath);

  const regressions = [
    ...compareOpenCounts(currentOpenCounts, baseline),
    ...checkGuardRefs(foldedFindings, REPO_ROOT),
    ...checkReopenMarkers(foldedFindings, baseline, reopenMarkersPath),
  ];

  const resolvedLocked = foldedFindings
    .filter((finding) => finding.status === "resolved" || finding.status === "verified-closed")
    .map((finding) => finding.claim_key);

  return { foldedFindings, currentOpenCounts, baseline, regressions, resolvedLocked };
}

/**
 * runReducer(paths) — the full write path used by the real (non-self-test) CLI run: computes
 * regressions, writes `finding-regressions.ndjson` (0 bytes on pass), then regenerates
 * `ledger.baseline.json` (subject to the `--freeze` gate above).
 */
function runReducer(paths = DEFAULT_PATHS) {
  const { regressionsPath, baselinePath, ledgerPath } = paths;
  const { currentOpenCounts, regressions, resolvedLocked } = computeRegressions(paths);

  writeNdjson(regressionsPath, regressions);
  const baseline = regenerateBaseline({ baselinePath, ledgerPath }, currentOpenCounts, resolvedLocked);

  return { regressions, baseline };
}

// -----------------------------------------------------------------------------
// --seal-round orchestrator (207-01, D-48/D-49). Reuses `runReducer`/`fold` verbatim — never
// reimplements ledger folding or regression computation.
// -----------------------------------------------------------------------------

/**
 * sealRound(paths) — the D-48/D-49 round-seal pipeline. Validates `RATCHET_ROUND` (missing or
 * non-finite → clear stderr message, `process.exitCode = 1`, append NOTHING); resolves scope from
 * `RATCHET_SURFACES` (default `"all"`); runs the EXISTING `runReducer` (which writes
 * `finding-regressions.ndjson` and regenerates the unfrozen baseline exactly as the plain no-flag
 * run does); folds the ledger; computes the 4 dry clauses + `dry`; appends one
 * `ratchet-round-seal/1` row to `rounds.ndjson`; classifies convergence over the just-updated
 * rows scoped to the current epoch; writes the status marker; ALWAYS exits 0 on the success path
 * (the non-zero escalation contract belongs to the later Elixir `ui.round` task, which reads this
 * marker AFTER the digest renders — `--seal-round` must never abort mid-pipeline).
 */
function sealRound(paths = DEFAULT_PATHS) {
  const rawRound = process.env.RATCHET_ROUND;
  const currentRound = Number(rawRound);
  if (
    rawRound === undefined ||
    rawRound === null ||
    String(rawRound).trim() === "" ||
    !Number.isFinite(currentRound)
  ) {
    console.error(
      "[phase-ratchet-ledger] --seal-round: RATCHET_ROUND is missing or non-numeric; appending nothing to rounds.ndjson."
    );
    process.exitCode = 1;
    return;
  }

  const rawScope = process.env.RATCHET_SURFACES || "all";
  const scopeSurfaces =
    rawScope === "all"
      ? null
      : new Set(
          rawScope
            .split(",")
            .map((s) => s.trim())
            .filter(Boolean)
        );

  // Reuse the existing reducer unchanged — writes finding-regressions.ndjson + regenerates the
  // (unfrozen) baseline, identical to the plain no-flag invocation.
  const { baseline } = runReducer(paths);

  const foldedFindings = Array.from(fold(readNdjsonRows(paths.ledgerPath)).values());

  const clause1 = computeClauseNewOpens(foldedFindings, currentRound);
  const clause2 = computeClauseZeroOpen(foldedFindings);
  const clause3 = computeClauseRegressionsEmpty(paths.regressionsPath, STANDING_REGRESSIONS_PATH);
  const clause4 = computeClauseCoverageFloor(readCellsCensus(CELLS_CENSUS_PATH), scopeSurfaces);
  const dry = computeDryRound([clause1, clause2, clause3, clause4]);

  const epoch = baseline.epoch;
  const existingRoundsRows = readNdjsonRows(paths.roundsPath);
  const newRow = {
    schema_version: "ratchet-round-seal/1",
    round: currentRound,
    dry,
    epoch,
    scope: rawScope,
    bundle_sha256: bundleSha256(),
    seq: existingRoundsRows.length + 1,
  };
  const updatedRows = [...existingRoundsRows, newRow];
  writeNdjson(paths.roundsPath, updatedRows);

  const consecutiveDry = computeConsecutiveDry(updatedRows, epoch);
  const status = classifyRoundStatus(consecutiveDry, currentRound);

  fs.mkdirSync(path.dirname(ROUND_STATUS_MARKER_PATH), { recursive: true });
  fs.writeFileSync(ROUND_STATUS_MARKER_PATH, status);

  console.log(`[phase-ratchet-ledger] round=${currentRound} dry=${dry} status=${status}`);
}

// -----------------------------------------------------------------------------
// Self-test (D-37 — proves LEDGER-03/LEDGER-05 entirely on fixtures; zero network calls, no
// live-model credential dependency). Twins `phase200-scorecard.mjs`'s `assertSelfTest()`/
// `runSelfTest()` shape verbatim.
// -----------------------------------------------------------------------------

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

/**
 * writeFixtureFiles(dir, {ledgerRows, baseline, reopenRows}) — writes one fixture scenario's
 * own synthetic `findings.ledger.ndjson`/`ledger.baseline.json`/`reopen-markers.ndjson` trio
 * under `dir` and returns the `{ledgerPath, baselinePath, reopenMarkersPath, regressionsPath}`
 * override object for that fixture. `baseline` may be omitted — an absent baseline file behaves
 * identically to the all-zero default via `readBaseline()`.
 */
function writeFixtureFiles(dir, { ledgerRows = [], baseline = null, reopenRows = [] } = {}) {
  fs.mkdirSync(dir, { recursive: true });
  const paths = {
    ledgerPath: path.join(dir, "findings.ledger.ndjson"),
    baselinePath: path.join(dir, "ledger.baseline.json"),
    reopenMarkersPath: path.join(dir, "reopen-markers.ndjson"),
    regressionsPath: path.join(dir, "finding-regressions.ndjson"),
  };
  writeNdjson(paths.ledgerPath, ledgerRows);
  writeNdjson(paths.reopenMarkersPath, reopenRows);
  if (baseline) writeJson(paths.baselinePath, baseline);
  return paths;
}

/**
 * runSelfTest() — proves, on 5 independent mkdtemp fixtures: (1) a clean ledger produces 0
 * regressions; (2) count-increase fires exactly once, naming the regressed lens; (3)
 * guard-missing fires when a resolved finding's `guard_ref` token is absent from its named
 * guard-home spec file; (4) illegal-reopen fires when a `resolved_locked` claim reappears open
 * without a matching current-epoch reopen marker; (5) the `--freeze` refusal gate throws and
 * leaves the on-disk frozen baseline byte-identical. Never mutates the real committed ledger/
 * baseline/reopen-marker files — every fixture targets its own subdirectory of one
 * `fs.mkdtempSync` scratch root, wrapped in try/finally so cleanup never skips.
 */
function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ratchet-ledger-"));
  try {
    // (0) computeNextRound — pure, fs-free (D-47): empty log -> 1; rows carrying round {1,3,2}
    // (deliberately out of order) -> 4 (max+1, order-independent).
    {
      assertSelfTest("(0) computeNextRound: empty -> 1", computeNextRound([]) === 1);
      assertSelfTest(
        "(0) computeNextRound: {1,3,2} -> 4 (order-independent)",
        computeNextRound([{ round: 1 }, { round: 3 }, { round: 2 }]) === 4
      );
    }

    // (1) clean fixture — an empty ledger against the (absent -> all-zero) baseline.
    {
      const paths = writeFixtureFiles(path.join(root, "fixture-clean"), {});
      const { regressions } = computeRegressions(paths);
      assertSelfTest("(1) clean fixture: 0 regressions", regressions.length === 0, JSON.stringify(regressions));
    }

    // (2) count-increase fixture — 2 confirmed open findings for persona:operator-founder
    // against a baseline recording only 1 for that lens.
    {
      const paths = writeFixtureFiles(path.join(root, "fixture-count-increase"), {
        ledgerRows: [
          {
            finding_id: "f-2222222222222221",
            seq: 1,
            event: "confirm",
            status: "open",
            raised_by_lenses: ["persona:operator-founder"],
            severity: "real",
            claim_key: "dashboard__d02__kpi-row__ov-none",
          },
          {
            finding_id: "f-2222222222222222",
            seq: 2,
            event: "confirm",
            status: "open",
            raised_by_lenses: ["persona:operator-founder"],
            severity: "minor",
            claim_key: "subscriptions-list__d04__data-table__ov-none",
          },
        ],
        baseline: {
          schema_version: "ratchet-ledger-baseline/1",
          frozen: false,
          epoch: 1,
          ledger_sha256: "0".repeat(64),
          confirmed_open: { "persona:operator-founder": { total: 1, minor: 0, real: 1 } },
          resolved_locked: [],
        },
      });
      const { regressions } = computeRegressions(paths);
      assertSelfTest(
        "(2) count-increase: exactly 1 regression",
        regressions.length === 1,
        JSON.stringify(regressions)
      );
      assertSelfTest(
        "(2) count-increase: regression names persona:operator-founder",
        regressions[0]?.kind === "count-increase" && regressions[0]?.lens === "persona:operator-founder"
      );
    }

    // (3) guard-missing fixture — a resolved finding whose guard_ref embeds a token that is NOT
    // present as a substring in its named (real, on-disk) guard-home spec file.
    {
      const paths = writeFixtureFiles(path.join(root, "fixture-guard-missing"), {
        ledgerRows: [
          {
            finding_id: "f-abc0000000000001",
            seq: 1,
            event: "resolve",
            status: "resolved",
            raised_by_lenses: [],
            severity: "real",
            claim_key: "dashboard__d02__kpi-row__ov-none",
            guard_ref: "accrue_admin/e2e/foundation-tokens.spec.js::@ratchet:f-abc0000000000001",
          },
        ],
      });
      const { regressions } = computeRegressions(paths);
      assertSelfTest(
        "(3) guard-missing: exactly 1 regression",
        regressions.length === 1,
        JSON.stringify(regressions)
      );
      assertSelfTest("(3) guard-missing: regression kind is guard-missing", regressions[0]?.kind === "guard-missing");
    }

    // (4) illegal-reopen fixture — baseline.resolved_locked contains a claim_key; the SAME
    // finding reappears open with an EMPTY reopen-markers.ndjson (no legitimate marker).
    {
      const paths = writeFixtureFiles(path.join(root, "fixture-illegal-reopen"), {
        ledgerRows: [
          {
            finding_id: "f-4444444444444444",
            seq: 1,
            event: "reopen",
            status: "open",
            raised_by_lenses: [],
            severity: "minor",
            claim_key: "dashboard__d02__kpi-row__ov-none",
          },
        ],
        baseline: {
          schema_version: "ratchet-ledger-baseline/1",
          frozen: false,
          epoch: 1,
          ledger_sha256: "0".repeat(64),
          confirmed_open: {},
          resolved_locked: ["dashboard__d02__kpi-row__ov-none"],
        },
        reopenRows: [],
      });
      const { regressions } = computeRegressions(paths);
      assertSelfTest(
        "(4) illegal-reopen: exactly 1 regression",
        regressions.length === 1,
        JSON.stringify(regressions)
      );
      assertSelfTest(
        "(4) illegal-reopen: regression names the claim_key",
        regressions[0]?.kind === "illegal-reopen" && regressions[0]?.lens === "dashboard__d02__kpi-row__ov-none"
      );
    }

    // (5) --freeze refusal fixture — an existing frozen:true baseline, called WITHOUT
    // "--freeze" in process.argv (guaranteed true under --self-test), throws the exact
    // refusal error and leaves the on-disk baseline byte-identical.
    {
      const dir = path.join(root, "fixture-freeze-refusal");
      fs.mkdirSync(dir, { recursive: true });
      const baselinePath = path.join(dir, "ledger.baseline.json");
      const ledgerPath = path.join(dir, "findings.ledger.ndjson");
      fs.writeFileSync(ledgerPath, "");
      writeJson(baselinePath, {
        schema_version: "ratchet-ledger-baseline/1",
        frozen: true,
        epoch: 1,
        ledger_sha256: "0".repeat(64),
        confirmed_open: {},
        resolved_locked: [],
      });

      const beforeBytes = fs.readFileSync(baselinePath);
      let threw = false;
      let thrownMessage = "";
      try {
        regenerateBaseline({ baselinePath, ledgerPath }, computeCurrentOpenCounts([]), []);
      } catch (err) {
        threw = true;
        thrownMessage = err.message;
      }
      const afterBytes = fs.readFileSync(baselinePath);

      assertSelfTest(
        "(5) --freeze refusal: throws the exact refusal error",
        threw && thrownMessage === "Refusing to modify a frozen baseline without --freeze (Phase 208 only).",
        thrownMessage
      );
      assertSelfTest(
        "(5) --freeze refusal: on-disk baseline byte-identical before and after",
        Buffer.compare(beforeBytes, afterBytes) === 0
      );
    }

    // (6) seal-round clauses — all 4 clauses true -> dry:true (D-48). Each clause is computed from
    // crafted inputs so the conjunction is exercised end-to-end, not just asserted as a literal.
    {
      const dir = path.join(root, "fixture-seal-clauses-true");
      fs.mkdirSync(dir, { recursive: true });
      const emptyReg = path.join(dir, "finding-regressions.ndjson");
      const emptyStanding = path.join(dir, "standing-regressions.ndjson");
      fs.writeFileSync(emptyReg, "");
      fs.writeFileSync(emptyStanding, "");
      const c1 = computeClauseNewOpens([], 3);
      const c2 = computeClauseZeroOpen([]);
      const c3 = computeClauseRegressionsEmpty(emptyReg, emptyStanding);
      const c4 = computeClauseCoverageFloor(
        [{ surface: "dashboard", coverage_status: "covered", score: 2 }],
        null
      );
      assertSelfTest(
        "(6) all 4 clauses true -> dry:true",
        computeDryRound([c1, c2, c3, c4]) === true,
        JSON.stringify([c1, c2, c3, c4])
      );
    }

    // (7) each clause individually false -> dry:false, one clause flipped at a time.
    {
      // 7a — clause1 false: a finding whose latest event is a confirm raised THIS round.
      assertSelfTest(
        "(7a) clause1 (new-opens) false -> dry:false",
        computeDryRound([
          computeClauseNewOpens([{ event: "confirm", round: 3, status: "open" }], 3),
          true,
          true,
          true,
        ]) === false
      );
      // 7b — clause2 false: a still-open finding remains.
      assertSelfTest(
        "(7b) clause2 (zero-open) false -> dry:false",
        computeDryRound([true, computeClauseZeroOpen([{ status: "open" }]), true, true]) === false
      );
      // 7c — clause3 false: a non-empty regressions fixture.
      {
        const dir = path.join(root, "fixture-clause3-false");
        fs.mkdirSync(dir, { recursive: true });
        const reg = path.join(dir, "finding-regressions.ndjson");
        const standing = path.join(dir, "standing.ndjson");
        writeNdjson(reg, [{ kind: "count-increase", lens: "x" }]);
        fs.writeFileSync(standing, "");
        assertSelfTest(
          "(7c) clause3 (regressions-empty) false -> dry:false",
          computeDryRound([true, true, computeClauseRegressionsEmpty(reg, standing), true]) === false
        );
      }
      // 7d — clause4 false: an in-scope cell whose coverage_status is not "covered".
      assertSelfTest(
        "(7d) clause4 (coverage-floor) false -> dry:false",
        computeDryRound([
          true,
          true,
          true,
          computeClauseCoverageFloor([{ surface: "dashboard", coverage_status: "gap", score: 2 }], null),
        ]) === false
      );
      // 7e — clause4 false: covered but below the Phase 208 score floor.
      assertSelfTest(
        "(7e) clause4 score 1 fails the score floor",
        computeClauseCoverageFloor([{ surface: "dashboard", coverage_status: "covered", score: 1 }], null) === false
      );
      // 7f — clause4 false: covered but missing a numeric score.
      assertSelfTest(
        "(7f) clause4 missing score fails the score floor",
        computeClauseCoverageFloor([{ surface: "dashboard", coverage_status: "covered" }], null) === false
      );
      // 7g — clause4 false: scoped lookup examines zero rows.
      assertSelfTest(
        "(7g) clause4 zero scoped rows fails closed",
        computeClauseCoverageFloor([{ surface: "dashboard", coverage_status: "covered", score: 2 }], new Set(["missing-surface"])) === false
      );
      // 7h — the named Phase 208 foundation slice expands every member. The component-kitchen
      // member maps to component/component-group rows, not an exact `surface=component-kitchen`
      // lookup, because it is a capture containing the design-system census.
      {
        const foundationRows = [
          { surface: "dashboard", surface_type: "page-flow", coverage_status: "covered", score: 2 },
          { surface: "subscription-detail", surface_type: "page-flow", coverage_status: "covered", score: 2 },
          { surface: "subscriptions", surface_type: "page-flow", coverage_status: "covered", score: 2 },
          { surface: "button", surface_type: "component", coverage_status: "covered", score: 2 },
          {
            surface: "page-header/actions/breadcrumbs",
            surface_type: "component-group",
            coverage_status: "covered",
            score: 2,
          },
        ];
        const memberCounts = Object.fromEntries(
          SLICES.foundation.map((member) => [member, scoreFloorRowsForScopeMember(foundationRows, member).length])
        );
        assertSelfTest(
          "(7h) SLICES.foundation expands every member to at least one score-floor row",
          Object.values(memberCounts).every((count) => count > 0),
          JSON.stringify(memberCounts)
        );
        assertSelfTest(
          "(7h) component-kitchen maps to component-family/design-system rows",
          memberCounts["component-kitchen"] === 2,
          JSON.stringify(memberCounts)
        );
        assertSelfTest(
          "(7h) SLICES.foundation score-floor rows pass at score 2",
          computeClauseCoverageFloor(foundationRows, new Set(["foundation"])) === true
        );
      }
    }

    // (8) 2 consecutive dry rows in the SAME epoch -> converged (D-49 K=2).
    {
      const rows = [
        { round: 1, dry: true, epoch: 1 },
        { round: 2, dry: true, epoch: 1 },
      ];
      const cd = computeConsecutiveDry(rows, 1);
      assertSelfTest(
        "(8) 2 consecutive dry (same epoch) -> converged",
        cd === 2 && classifyRoundStatus(cd, 2) === "converged",
        `consecutiveDry=${cd}`
      );
    }

    // (9) a dry row from an OLDER epoch must NOT count toward the current epoch's streak.
    {
      const rows = [
        { round: 1, dry: true, epoch: 0 },
        { round: 2, dry: true, epoch: 1 },
      ];
      const cd = computeConsecutiveDry(rows, 1);
      assertSelfTest(
        "(9) older-epoch dry excluded from current streak",
        cd === 1 && classifyRoundStatus(cd, 2) === "continue",
        `consecutiveDry=${cd}`
      );
    }

    // (10) round 6 with fewer than 2 consecutive dry rounds -> cap-reached (D-49 6-cap).
    {
      const rows = [
        { round: 5, dry: false, epoch: 1 },
        { round: 6, dry: true, epoch: 1 },
      ];
      const cd = computeConsecutiveDry(rows, 1);
      assertSelfTest(
        "(10) round 6, <2 consecutive dry -> cap-reached",
        cd === 1 && classifyRoundStatus(cd, 6) === "cap-reached",
        `consecutiveDry=${cd}`
      );
    }

    // (11) missing RATCHET_ROUND -> non-zero process.exitCode, NO row appended (T-207-07).
    {
      const dir = path.join(root, "fixture-seal-no-round");
      const paths = writeFixtureFiles(dir, {});
      paths.roundsPath = path.join(dir, "rounds.ndjson");
      writeNdjson(paths.roundsPath, []);

      const prevRound = process.env.RATCHET_ROUND;
      const prevExit = process.exitCode;
      delete process.env.RATCHET_ROUND;
      sealRound(paths);
      const exitWas = process.exitCode;
      const appended = readNdjsonRows(paths.roundsPath);
      // Restore process/env state so the outer self-test exits clean.
      process.exitCode = prevExit;
      if (prevRound !== undefined) process.env.RATCHET_ROUND = prevRound;

      assertSelfTest("(11) missing RATCHET_ROUND: non-zero exitCode", exitWas === 1, String(exitWas));
      assertSelfTest(
        "(11) missing RATCHET_ROUND: no row appended",
        appended.length === 0,
        JSON.stringify(appended)
      );
    }

    console.log("phase-ratchet-ledger self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

// -----------------------------------------------------------------------------
// CLI entry point.
// -----------------------------------------------------------------------------

function main() {
  // `--self-test` is checked FIRST, before any file-system side effect against the real
  // committed paths — running it never touches DEFAULT_PATHS.
  if (process.argv.includes("--self-test")) {
    runSelfTest();
    return;
  }

  // `--next-round` (207-01, D-47) — a side-effect-scoped scalar handoff: compute the next round
  // integer from the committed `rounds.ndjson` and write it to the ephemeral marker for the
  // Elixir orchestrator. Checked immediately after `--self-test` and before any reducer run so it
  // NEVER touches the ledger/baseline/regressions gate artifacts.
  if (process.argv.includes("--next-round")) {
    const rows = readNdjsonRows(DEFAULT_PATHS.roundsPath);
    const next = computeNextRound(rows);
    fs.mkdirSync(path.dirname(NEXT_ROUND_MARKER_PATH), { recursive: true });
    fs.writeFileSync(NEXT_ROUND_MARKER_PATH, String(next));
    console.log(`[phase-ratchet-ledger] next-round=${next}`);
    return;
  }

  // `--seal-round` (207-01, D-48/D-49) — the 4-clause dry conjunction + convergence classification.
  // Reuses `runReducer`/`fold`; never aborts mid-pipeline (always exits 0 on the success path).
  if (process.argv.includes("--seal-round")) {
    sealRound(DEFAULT_PATHS);
    return;
  }

  const { regressions } = runReducer(DEFAULT_PATHS);
  console.log(`[phase-ratchet-ledger] regressions=${regressions.length}`);
  if (regressions.length > 0) {
    console.error("[phase-ratchet-ledger] blocking regressions found; see finding-regressions.ndjson.");
    process.exitCode = 1;
  }
}

// WR-05: wrap the CLI entry point in the SAME clean-crash-message try/catch as the sibling
// independent CI re-verifier (`scripts/ci/verify_ratchet_ledger.mjs`) — an unexpected throw here
// (e.g. `fold()`'s tamper-evidence exception on a corrupted ledger, or `regenerateBaseline()`'s
// frozen-baseline refusal error surfacing from an unexpected caller path) previously surfaced in
// CI as a raw Node stack trace instead of the same actionable one-liner the sibling script
// produces, despite the two being explicitly twinned by design elsewhere in this phase.
if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`phase-ratchet-ledger.mjs crashed: ${error.message}`);
    process.exitCode = 1;
  }
}

// -----------------------------------------------------------------------------
// Exports (207-01). This file was CLI-only before Phase 207. `GUARD_HOME_SPECS`/`checkGuardRef`/
// `isSafeSpecPath` are exported so 207-03's `ratchet-guard-mint.mjs` reuses the SAME guard-token
// grammar instead of re-deriving a second, possibly-diverging regex (Don't Hand-Roll — exactly
// the failure mode Phase 206 flagged). `computeNextRound` is exported so the self-test (and any
// later consumer) can call it directly on in-memory arrays.
// -----------------------------------------------------------------------------
export { GUARD_HOME_SPECS, checkGuardRef, isSafeSpecPath, computeNextRound };
