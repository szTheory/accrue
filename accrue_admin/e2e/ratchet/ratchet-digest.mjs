/**
 * ratchet-digest.mjs — the single visual surface Phase 207 produces (ORCH-02). Renders the
 * maintainer's per-round read surface: a self-contained, offline HTML digest of confirmed
 * findings grouped by surface with region overlays, a ranked auto-fixable worklist and a
 * separate IA/product-decision queue, and the sticky summary banner in its 4 locked states.
 * It also assembles the round's `round-NN/` artifact directory (PNGs + `.bbox.json` copied in
 * at render time) and writes the pre-filled `decisions.json` checkpoint (D-42) that 207-06's
 * apply-decisions reader consumes.
 *
 * 207-UI-SPEC.md is the BINDING visual contract for the rendered HTML. This file twins
 * `phase192-gallery.mjs`'s STRUCTURAL idiom (row-builders + a `REQUIRED_FIELDS` validator +
 * `runSelfTest()`/`--self-test`/`import.meta.url` guard) — not its literal Markdown output;
 * this renders HTML.
 *
 * Independence discipline (mirrors `scripts/ci/verify_ratchet_ledger.mjs`): the convergence
 * DISPLAY derived here re-derives round/dry/epoch/status from `rounds.ndjson` for the banner
 * only — it NEVER imports or recomputes 207-01's gate classification. The gate (the ledger
 * reducer + regressions) is authoritative; this digest never re-decides pass/fail.
 *
 * Zero external deps (D-53): only `node:fs`/`node:os`/`node:path`/`node:url` plus `{ fold }`
 * from `./ratchet-ledger.js`. No network, no CDN, no webfont — the emitted HTML opens offline.
 * Deterministic: given identical `findings.ledger.ndjson` + `rounds.ndjson` + `.bbox.json`
 * inputs, the produced HTML is byte-identical (no `Date.now()`/`Math.random()` anywhere).
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { fold } from "./ratchet-ledger.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// -----------------------------------------------------------------------------
// Path constants. `LEDGER_PATH`/`ROUNDS_PATH` match `phase-ratchet-ledger.mjs`'s
// `DEFAULT_PATHS` exactly (same directory). `CAPTURE_DIR` is Phase 205's flat capture root;
// `ROUND_OUTPUT_ROOT` is the gitignored per-round artifact tree this digest assembles into.
// -----------------------------------------------------------------------------
const LEDGER_PATH = path.join(__dirname, "findings.ledger.ndjson");
const ROUNDS_PATH = path.join(__dirname, "rounds.ndjson");
const CAPTURE_DIR = path.join(__dirname, "../../test-results/admin-visuals");
const ROUND_OUTPUT_ROOT = path.join(__dirname, "../../test-results/ui-ratchet");

// -----------------------------------------------------------------------------
// Region-overlay scale (D-55 + RESEARCH Pitfall 2). These are the REAL Playwright capture
// widths, verified against `playwright.config.js`'s explicit `viewport: {width:1280,...}`
// override (desktop) and `devices["Pixel 5"]`'s actual `393` (mobile). This DELIBERATELY
// diverges from `baseline-manifest.js`'s `PROJECTS[...].viewport_width` (1440/390), which is
// stale documentation, not the real capture config — do NOT read `viewport_width` from
// `baseline-manifest.js` for the overlay math.
// -----------------------------------------------------------------------------
const CAPTURE_VIEWPORT_WIDTHS = { "chromium-desktop": 1280, "chromium-mobile": 393 };

// Fixed on-page display width per project so the absolutely-positioned overlay pixels are
// exact against the rendered `<img>` (which is displayed at this width). A uniform scale
// preserves aspect, so bbox y/height map correctly too. Deterministic — no viewport math.
const DISPLAY_WIDTHS = { "chromium-desktop": 960, "chromium-mobile": 393 };

// The theme suffixes/projects a surface may have been captured under (D-09 capture matrix).
const THEME_SUFFIXES = ["", "-dark"];
const CAPTURE_PROJECTS = ["chromium-desktop", "chromium-mobile"];

// Fields every rendered worklist/decisions-needed row must carry non-empty before rendering
// (the UI-SPEC "Data Fields Rendered Per Finding" table). Mirrors phase192-gallery.mjs's
// `validateGalleryRows` failure-collecting pattern.
const REQUIRED_ROW_FIELDS = [
  "finding_id",
  "surface",
  "region_tag",
  "severity",
  "persona_frequency",
  "defect",
  "suggested_fix",
];

// -----------------------------------------------------------------------------
// Small IO helper (absence-safe, twin of the sibling ledger scripts' convention).
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Convergence DISPLAY (banner only — never the gate). Independent re-derivation of
// round/dry/epoch/consecutiveDry/status from `rounds.ndjson`, using the identical K=2 /
// round-6 thresholds as 207-01's `classifyRoundStatus`, WITHOUT importing it.
// -----------------------------------------------------------------------------

/**
 * computeConvergenceDisplay(roundsRows) — pure. Returns the latest round's
 * `{round, dry, epoch, consecutiveDry, status}` for the banner. Latest = max `round`
 * (ties broken by max `seq`). `consecutiveDry` is the trailing run-length of `dry === true`
 * among rows in the latest row's epoch, in `seq` order (a streak never leaks across an epoch
 * boundary, D-49). `status ∈ {"converged","cap-reached","continue"}` via K=2 / 6-cap. An
 * empty log yields the neutral `{round:0, dry:false, epoch:0, consecutiveDry:0, status:"continue"}`.
 */
function computeConvergenceDisplay(roundsRows) {
  if (!Array.isArray(roundsRows) || roundsRows.length === 0) {
    return { round: 0, dry: false, epoch: 0, consecutiveDry: 0, status: "continue" };
  }
  const latest = roundsRows.reduce((best, row) => {
    if (best === null) return row;
    const r = row.round || 0;
    const br = best.round || 0;
    if (r > br) return row;
    if (r === br && (row.seq || 0) > (best.seq || 0)) return row;
    return best;
  }, null);

  const epoch = latest.epoch;
  const scoped = roundsRows
    .filter((row) => row.epoch === epoch)
    .slice()
    .sort((a, b) => (a.seq || 0) - (b.seq || 0));
  let consecutiveDry = 0;
  for (let i = scoped.length - 1; i >= 0; i--) {
    if (scoped[i].dry === true) consecutiveDry += 1;
    else break;
  }

  const round = latest.round || 0;
  let status;
  if (consecutiveDry >= 2) status = "converged";
  else if (round >= 6) status = "cap-reached";
  else status = "continue";

  return { round, dry: latest.dry === true, epoch, consecutiveDry, status };
}

// -----------------------------------------------------------------------------
// Summary banner copy (the 4 locked UI-SPEC states). Pure — returns a structured object whose
// `headline` is the EXACT copy string; the renderer maps it to markup.
// -----------------------------------------------------------------------------

/**
 * buildSummaryBanner({round, confirmed, rootCause, iaDecisions, status, consecutiveDry}) —
 * returns `{state, headline, badge, emptyHeading, emptyBody}` matching exactly one of the 4
 * UI-SPEC banner states. Precedence: converged > cap-reached > empty > normal (a converged
 * round has 0 open findings, so it must win over the empty state and still show the
 * `CONVERGED` badge over the standard headline).
 */
function buildSummaryBanner({ round, confirmed, rootCause, iaDecisions, status, consecutiveDry }) {
  const normalHeadline =
    `Round ${round} — ${confirmed} confirmed, ${rootCause} root-cause, ${iaDecisions} IA decisions`;

  if (status === "converged") {
    return {
      state: "converged",
      headline: normalHeadline,
      badge: { glyph: "✓", text: `CONVERGED (${consecutiveDry} dry rounds)`, tone: "accent" },
      emptyHeading: null,
      emptyBody: null,
    };
  }
  if (status === "cap-reached") {
    return {
      state: "cap-reached",
      headline: `CAP REACHED — 6 rounds, ${confirmed} open, not converged`,
      badge: { glyph: "⚠", text: "CAP REACHED", tone: "danger" },
      emptyHeading: null,
      emptyBody: null,
    };
  }
  if (confirmed === 0) {
    return {
      state: "empty",
      headline: `Round ${round} — 0 confirmed findings`,
      badge: null,
      emptyHeading: "No confirmed findings this round",
      emptyBody:
        `Round ${round} re-verified every surface in scope and found nothing new to fix. ` +
        `If this continues for one more round, the loop reports CONVERGED.`,
    };
  }
  return {
    state: "normal",
    headline: normalHeadline,
    badge: null,
    emptyHeading: null,
    emptyBody: null,
  };
}

// -----------------------------------------------------------------------------
// Ranking / partition (D-54 predicate + D-56 sort keys, zero non-determinism).
// -----------------------------------------------------------------------------

const SEVERITY_ORDER = { real: 0, minor: 1 };
const EFFORT_ORDER = { css: 0, null: 1 };

/** severityRank(sev) — real→0, minor→1, anything else→2 (sorts last, deterministically). */
function severityRank(sev) {
  return sev in SEVERITY_ORDER ? SEVERITY_ORDER[sev] : 2;
}

/** effortRank(effortClass) — `"css"`→0, `null`→1 (cheap auto-fixable wins first). */
function effortRank(effortClass) {
  if (effortClass === "css") return 0;
  return 1; // null (or any non-css worklist value)
}

/**
 * partitionFindings(foldedOpenFindings) — splits `open` findings into `{worklist,
 * decisionsNeeded}` by the D-54 predicate (`effort_class === "ia-product-decision"` →
 * decisionsNeeded; else → worklist) and sorts each per the exact D-56 keys. Defensively
 * filters to `status === "open"` so a caller may pass the full folded set. Fully deterministic:
 * every comparator ends on `finding_id` ascending, so ordering never depends on sort stability.
 */
function partitionFindings(foldedOpenFindings) {
  const open = (foldedOpenFindings || []).filter((f) => f.status === "open");
  const worklist = [];
  const decisionsNeeded = [];
  for (const f of open) {
    if (f.effort_class === "ia-product-decision") decisionsNeeded.push(f);
    else worklist.push(f);
  }

  const byFindingId = (a, b) => String(a.finding_id).localeCompare(String(b.finding_id));
  const bySeverityThenFreq = (a, b) => {
    const sev = severityRank(a.severity) - severityRank(b.severity);
    if (sev !== 0) return sev;
    return (b.persona_frequency || 0) - (a.persona_frequency || 0); // desc
  };

  worklist.sort((a, b) => {
    const base = bySeverityThenFreq(a, b);
    if (base !== 0) return base;
    const eff = effortRank(a.effort_class) - effortRank(b.effort_class);
    if (eff !== 0) return eff;
    return byFindingId(a, b);
  });
  decisionsNeeded.sort((a, b) => {
    const base = bySeverityThenFreq(a, b);
    if (base !== 0) return base;
    return byFindingId(a, b);
  });

  return { worklist, decisionsNeeded };
}

// -----------------------------------------------------------------------------
// decisions.json row-builder (D-42) — the CONTRACT 207-06's apply-decisions reader depends on.
// -----------------------------------------------------------------------------

/**
 * buildDecisionsJsonRows(worklist) — one pre-filled `approve` row per worklist finding:
 * `{finding_id, decision, surface, summary, region_tag}`. `summary` is the finding's `defect`
 * prose (the human-readable one-liner the maintainer edits before running `ui.fix`).
 */
function buildDecisionsJsonRows(worklist) {
  return (worklist || []).map((f) => ({
    finding_id: f.finding_id,
    decision: "approve",
    surface: f.surface,
    summary: f.defect,
    region_tag: f.region_tag,
  }));
}

// -----------------------------------------------------------------------------
// Row validator (twins phase192-gallery.mjs's `validateGalleryRows`: collect failures, throw a
// joined message). Run before rendering so a malformed ledger row fails loud, not silently.
// -----------------------------------------------------------------------------

/**
 * validateDigestRows(rows, sectionLabel) — asserts every `REQUIRED_ROW_FIELDS` value is present
 * and non-empty on each row. Throws a single joined message listing every failure, or returns
 * the rows unchanged on success.
 */
function validateDigestRows(rows, sectionLabel = "row") {
  const failures = [];
  (rows || []).forEach((row, index) => {
    for (const field of REQUIRED_ROW_FIELDS) {
      const value = row[field];
      if (value === null || value === undefined || String(value).trim() === "") {
        failures.push(`${sectionLabel} ${index + 1} missing ${field}`);
      }
    }
  });
  if (failures.length > 0) throw new Error(failures.join("; "));
  return rows;
}

export {
  LEDGER_PATH,
  ROUNDS_PATH,
  CAPTURE_DIR,
  ROUND_OUTPUT_ROOT,
  CAPTURE_VIEWPORT_WIDTHS,
  DISPLAY_WIDTHS,
  readNdjsonRows,
  computeConvergenceDisplay,
  buildSummaryBanner,
  partitionFindings,
  buildDecisionsJsonRows,
  validateDigestRows,
};
