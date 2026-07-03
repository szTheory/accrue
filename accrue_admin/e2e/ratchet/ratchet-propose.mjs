/**
 * ratchet-propose.mjs — defect-only, claim-keyed candidate proposer for the UI ratchet
 * (Phase 205, v1.56). Forked from `accrue_admin/e2e/score-visuals.mjs`.
 *
 * This is the PROPOSER half of the ratchet's noisy off-gate plane. It fans a set of
 * job-anchored operator-persona lenses over the committed admin PNGs and emits a
 * VARIABLE 0..N defect rows per image to `candidates.ndjson`. An empty `[]` is valid
 * and expected ("nothing blocks — do not invent findings"). It LAYERS ON (never
 * replaces) the 30,348-cell census scorecard (`phase200-scorecard.mjs`); each candidate
 * carries `cell_refs[]` as a foreign key INTO the census lattice (D-12), never a merge.
 *
 * DETERMINISM (DEDUP-01/DEDUP-02): the LLM output is ADVISORY input only — it NEVER gates
 * CI. Every identity field (`surface`/`dimension`/`region_tag`/`overlay_tags`/`claim_key`/
 * `finding_id`) is re-derived by the harness from the SDK-free SSOT `region-tags.js`; any
 * model-supplied `claim_key`/`finding_id` is ignored (D-04/D-16). The pure `--self-test`
 * proves DEDUP-01/02 with no key and no live model (twins `phase200-scorecard.mjs`).
 *
 * Guard ordering (RESEARCH Pattern 1 / Pitfall 4) — the three guards run in THIS order at
 * the top of the file, all BEFORE any SDK import:
 *   1. `--self-test` branch  → `regionTags.runSelfTest()` → exit 0  (no key, no SDK)
 *   2. no-key `exit 0` guard → skip cleanly if `ANTHROPIC_API_KEY` is absent (EVAL-03)
 *   3. dynamic import of `baseline-manifest.js` + `@anthropic-ai/sdk` (only with a key)
 *
 * Usage:
 *   node e2e/ratchet/ratchet-propose.mjs --self-test   # pure DEDUP-01/02 proof (no key)
 *   ANTHROPIC_API_KEY=… node e2e/ratchet/ratchet-propose.mjs   # live proposer run
 *   SCORE_MODEL=… node e2e/ratchet/ratchet-propose.mjs         # override the model
 *
 * NOTE: the comparative graphic-design lens (EVAL-02/EVAL-04) is added in Plan 04; this
 * plan (03) ships the 6 operator-persona lenses.
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { createHash } from "node:crypto";
import * as regionTags from "./region-tags.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ----------------------------------------------------------------------------
// GUARD 1 — `--self-test` FIRST. Pure DEDUP-01/DEDUP-02 proof: no key, no SDK
// import. This must precede the no-key guard AND the SDK import so CI can run it
// key-free (EVAL-03/DEDUP-02). `runSelfTest()` throws on failure → nonzero exit.
// ----------------------------------------------------------------------------
if (process.argv.includes("--self-test")) {
  regionTags.runSelfTest();
  process.exit(0);
}

// ----------------------------------------------------------------------------
// GUARD 2 — API-key guard. If the key is absent, skip cleanly. Kept verbatim
// (retitled) from `score-visuals.mjs:35-38`. MUST run before any SDK import so
// that ERR_MODULE_NOT_FOUND (SDK not installed) cannot occur on the no-key path.
// ----------------------------------------------------------------------------
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[ratchet-propose] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}

// ----------------------------------------------------------------------------
// GUARD 3 — only NOW import the manifest + SDK (key is present).
// ----------------------------------------------------------------------------
const { default: manifest } = await import("./baseline-manifest.js");
const { default: Anthropic } = await import("@anthropic-ai/sdk");
const client = new Anthropic(); // reads ANTHROPIC_API_KEY from env

// ----------------------------------------------------------------------------
// Configuration (from `score-visuals.mjs:49-52`)
// ----------------------------------------------------------------------------
const model = process.env.SCORE_MODEL || "claude-sonnet-4-5";
const round = Number(process.env.RATCHET_ROUND || "1");
const RESULTS_DIR = path.join(__dirname, "../../test-results/admin-visuals");
const BUNDLE_PATH = path.join(__dirname, "../../priv/static/accrue_admin.css");
const CANDIDATES_PATH = path.join(RESULTS_DIR, "candidates.ndjson");
const MAX_B64_BYTES = 5 * 1024 * 1024; // 5 MB — skip oversized images with a warning
const MAX_FINDINGS_PER_IMAGE = 12; // D-16 cap: keep top-N by (job_blocking, severity)

const { DIMENSIONS, SURFACES, cellId } = manifest;

// bundle_sha256 (D-17) — content fingerprint of the built CSS bundle the PNGs reflect.
// Computed once; `null` if the bundle is absent (non-fatal — provenance only).
function bundleSha256() {
  try {
    return createHash("sha256").update(fs.readFileSync(BUNDLE_PATH)).digest("hex");
  } catch {
    return null;
  }
}

// run_id (D-17) — a per-run, non-identity provenance token. Never enters claim_key.
function makeRunId() {
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const rand = createHash("sha256").update(String(Math.random())).digest("hex").slice(0, 8);
  return `run-${stamp}-${rand}`;
}

// ----------------------------------------------------------------------------
// PNG discovery — KEEP verbatim from `score-visuals.mjs:114-148`. Surface identity
// is derived from the filename (harness-injected, never model-chosen — D-04).
// ----------------------------------------------------------------------------
function discoverPngs() {
  if (!fs.existsSync(RESULTS_DIR)) {
    console.log(`[ratchet-propose] RESULTS_DIR not found: ${RESULTS_DIR}`);
    console.log("[ratchet-propose] Run 'npm run e2e:visuals:png-only' first to capture screenshots.");
    return [];
  }

  const projects = ["chromium-desktop", "chromium-mobile"];
  const pngs = [];

  for (const projectName of projects) {
    const projectDir = path.join(RESULTS_DIR, projectName);
    if (!fs.existsSync(projectDir)) {
      continue;
    }

    const files = fs.readdirSync(projectDir).filter((f) => f.endsWith(".png"));
    for (const file of files) {
      const isDark = file.endsWith("-dark.png");
      const theme = isDark ? "dark" : "light";
      const screen = isDark
        ? file.slice(0, -"-dark.png".length)
        : file.slice(0, -".png".length);

      pngs.push({
        pngPath: path.join(projectDir, file),
        screen,
        viewport: projectName,
        theme,
      });
    }
  }

  return pngs;
}

// ----------------------------------------------------------------------------
// Proposer loop
// ----------------------------------------------------------------------------
async function main() {
  const pngs = discoverPngs();
  if (pngs.length === 0) {
    console.log("[ratchet-propose] No PNGs found — nothing to propose.");
    process.exit(0);
  }

  console.log(`[ratchet-propose] Found ${pngs.length} PNG(s) to evaluate using model: ${model}`);

  // Truncate/create the output so reruns do not concatenate stale rows.
  fs.writeFileSync(CANDIDATES_PATH, "");

  const run_id = makeRunId();
  const bundle_sha256 = bundleSha256();

  let totalRows = 0;
  let skipped = 0;
  let failedImages = 0;

  try {
    for (const png of pngs) {
      // Large-image guard — skip PNGs whose base64 encoding exceeds 5 MB (EVAL-03).
      const b64 = fs.readFileSync(png.pngPath, "base64");
      if (b64.length > MAX_B64_BYTES) {
        console.warn(
          `[ratchet-propose] Skipping ${png.pngPath} — base64 size ${b64.length} exceeds 5 MB limit`
        );
        skipped++;
        continue;
      }

      console.log(`[ratchet-propose] Evaluating ${png.viewport}/${png.screen} (${png.theme})…`);

      let rows;
      try {
        rows = await proposeForImage(png, b64, { run_id, bundle_sha256 });
      } catch (imgErr) {
        console.error(
          `[ratchet-propose] Failed on ${png.screen} (${png.viewport}/${png.theme}): ${imgErr.message}`
        );
        failedImages++;
        continue;
      }

      for (const row of rows) {
        fs.appendFileSync(CANDIDATES_PATH, JSON.stringify(row) + "\n");
        totalRows++;
      }
    }
  } catch (err) {
    console.error(`[ratchet-propose] API error: ${err.message}`);
    process.exit(1);
  }

  const skippedNote = skipped > 0 ? ` (${skipped} skipped — oversized)` : "";
  console.log(
    `[ratchet-propose] Evaluated ${pngs.length - skipped} PNG(s) → ${totalRows} candidate(s) → ${CANDIDATES_PATH}${skippedNote}`
  );

  if (failedImages > 0) {
    console.error(`[ratchet-propose] ${failedImages} image(s) could not be evaluated`);
    process.exit(1);
  }
}

// proposeForImage — Task 2/3 fill the persona fan-out + validation gate. Stage 1
// establishes the discovery + IO scaffolding; the model call is added next.
async function proposeForImage(_png, _b64, _provenance) {
  return [];
}

await main();
