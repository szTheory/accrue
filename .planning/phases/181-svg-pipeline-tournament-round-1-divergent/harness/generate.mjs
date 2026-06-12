/**
 * generate.mjs — Main orchestration entry point for the logo tournament pipeline
 *
 * Usage:
 *   node harness/generate.mjs          # full run: ~20–24 raw candidates → 12–16 passing
 *   node harness/generate.mjs --smoke  # smoke run: 1 per direction (4 candidates)
 *
 * Pipeline:
 *   1. Load Geist font (geist-spine.mjs)
 *   2. Create output directories (candidates/, rejected/, screenshots/)
 *   3. Generate raw candidates — all 4 directions (A/B/C/D)
 *   4. Run pre-gate lints (lint.mjs) — cull failures to rejected/
 *   5. Per-direction floor check: >= 3 passing per direction (D-05)
 *   6. Write ALL pre-gate-passing candidates/*.svg and candidates/*.json sidecars
 *   7. Write candidates/index.json metadata index
 *
 * NOTE: The gallery-size cap (12–16, D-04) is enforced by render-matrix.mjs
 * AFTER 16px legibility culling — enforcing the cap here (before legibility)
 * would discard legible candidates while the post-legibility count may still
 * be under the 16-cap ceiling (see defect fixed in post-completion fix 2).
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

import { loadGeistFont, extractGlyphs, getCapHeight } from "./geist-spine.mjs";
import { assembleLockup, computeMarkBbox } from "./assemble-lockup.mjs";
import { lintCandidate } from "./lint.mjs";
import { CONFIGS as A_CONFIGS, generate as generateA } from "./dirs/a-strata.mjs";
import { CONFIGS as B_CONFIGS, generate as generateB } from "./dirs/b-step.mjs";
import { CONFIGS as C_CONFIGS, generate as generateC } from "./dirs/c-arcs.mjs";
import { CONFIGS as D_CONFIGS, generate as generateD } from "./dirs/d-typemark.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Config constants
// ---------------------------------------------------------------------------

const PHASE_DIR = path.resolve(__dirname, "..");
const CANDIDATES_DIR = path.join(PHASE_DIR, "candidates");
const REJECTED_DIR = path.join(PHASE_DIR, "rejected");
const SCREENSHOTS_DIR = path.join(PHASE_DIR, "screenshots");
const LINT_LOG_PATH = path.join(PHASE_DIR, "lint-results.ndjson");

const SMOKE = process.argv.includes("--smoke");

/** Per-direction minimum in final gallery (D-05 floor). */
const MIN_PER_DIRECTION = 3;

/** Target gallery size range (D-04). */
const TARGET_GALLERY_SIZE = { min: 12, max: 16 };

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Write a rejected candidate to rejected/ with reason sidecar.
 *
 * @param {string} candidateId
 * @param {string} svgString
 * @param {string[]} failures — lint failure names
 */
function writeRejected(candidateId, svgString, failures) {
  fs.writeFileSync(path.join(REJECTED_DIR, `${candidateId}.svg`), svgString);
  const reasonText = [
    `Candidate: ${candidateId}`,
    `Lint failures: ${failures.join(", ")}`,
    `Culled: ${new Date().toISOString()}`,
  ].join("\n");
  fs.writeFileSync(
    path.join(REJECTED_DIR, `${candidateId}.reason.txt`),
    reasonText + "\n"
  );
}

/**
 * Build a lockup SVG string from a mark + assembled glyphs.
 * Uses greyscale palette (#181818) to pass monochrome lint.
 *
 * @param {string} markPathD
 * @param {{ advanceWidth: number }[]} glyphs
 * @param {number} markWidth
 * @param {number} capHeight
 * @returns {string} SVG string
 */
function buildLockupSvg(markPathD, glyphs, markWidth, capHeight) {
  const viewboxH = capHeight * 1.4;
  const result = assembleLockup(markPathD, glyphs, {
    markWidth,
    capHeight,
    gapRatio: 0.15,
    fontSize: 1000,
    viewboxH,
    markIsTypemark: false,
    palette: { ink: "#181818", paper: "#FAFBFC" },
  });
  // assembleLockup returns SVG string in standard mode
  return typeof result === "string" ? result : result.svg;
}

/**
 * Count passing candidates per direction.
 * @param {{ direction: string }[]} arr
 * @returns {{ A: number, B: number, C: number, D: number }}
 */
function countByDirection(arr) {
  return { A: 0, B: 0, C: 0, D: 0, ...Object.fromEntries(
    ["A", "B", "C", "D"].map((d) => [d, arr.filter((c) => c.direction === d).length])
  ) };
}

/**
 * Run lint on a candidate and return pass/fail with failure list.
 *
 * @param {{ id: string, direction: string, lockupSvg: string, skipGapRatio: boolean,
 *           markBbox?: object, logotypeBbox?: object, capHeight?: number }} candidate
 * @returns {{ pass: boolean, failures: string[] }}
 */
function runLint(candidate) {
  return lintCandidate({
    id: candidate.id,
    direction: candidate.direction,
    svgString: candidate.lockupSvg,
    skipGapRatio: candidate.skipGapRatio,
    markBbox: candidate.markBbox,
    logotypeBbox: candidate.logotypeBbox,
    capHeight: candidate.capHeight,
    // png16Path / png32Path not available at this stage — screenshots in Plan 06
  }, { writeLog: true });
}

// ---------------------------------------------------------------------------
// Generation helpers per direction
// ---------------------------------------------------------------------------

/**
 * Generate one A/B/C candidate object (standard lockup — mark + logotype).
 *
 * @param {string} direction  "A" | "B" | "C"
 * @param {Function} generatorFn  — generate(config) from a-strata/b-step/c-arcs
 * @param {object} config
 * @param {{ advanceWidth: number }[]} accrueGlyphs
 * @param {number} capHeight
 * @returns {object | null} candidate or null on error
 */
function buildStandardCandidate(direction, generatorFn, config, accrueGlyphs, capHeight) {
  try {
    const { markPathD, markWidth, markHeight } = generatorFn(config);

    // Build lockup SVG
    const lockupSvg = buildLockupSvg(markPathD, accrueGlyphs, markWidth, capHeight);

    // Approximate mark bbox from path data
    const markBbox = computeMarkBbox(markPathD);
    // Logotype starts at markWidth + gap
    const gap = capHeight * 0.15;
    const logotypeBbox = { xMin: markWidth + gap };

    return {
      id: config.id,
      direction,
      config,
      markPathD,
      markWidth,
      markHeight,
      lockupSvg,
      markBbox,
      logotypeBbox,
      capHeight,
      skipGapRatio: false,
      rationale: config.rationale,
    };
  } catch (err) {
    console.error(`[generate] Error generating ${config.id}: ${err.message}`);
    return null;
  }
}

/**
 * Generate one Direction D candidate object (integrated typemark — no lockup assembly).
 *
 * @param {object} config
 * @param {import("opentype.js").Font} font
 * @returns {object | null}
 */
function buildTypemarkCandidate(config, font) {
  try {
    const { fullSvg, markIsTypemark, markWidth, markHeight, skipGapRatio } = generateD(config, font);
    return {
      id: config.id,
      direction: "D",
      config,
      lockupSvg: fullSvg,
      markIsTypemark,
      markWidth,
      markHeight,
      skipGapRatio,
      rationale: config.rationale,
    };
  } catch (err) {
    console.error(`[generate] Error generating ${config.id}: ${err.message}`);
    return null;
  }
}

// ---------------------------------------------------------------------------
// main()
// ---------------------------------------------------------------------------

async function main() {
  console.log(`[generate] Starting logo pipeline — ${SMOKE ? "SMOKE" : "FULL"} run…`);

  // -------------------------------------------------------------------------
  // Step 1 — Load font
  // -------------------------------------------------------------------------
  console.log("[generate] Loading Geist font…");
  let font;
  try {
    font = await loadGeistFont();
  } catch (err) {
    console.error(`[generate] FATAL: Could not load Geist font — ${err.message}`);
    process.exit(1);
  }

  const capHeight = getCapHeight(font);
  const accrueGlyphs = extractGlyphs(font, "accrue", 1000);

  // Assert 6 distinct glyphs (guard against ligature substitution — RESEARCH.md ligature edge case)
  if (accrueGlyphs.length !== 6) {
    console.error(
      `[generate] FATAL: extractGlyphs('accrue') returned ${accrueGlyphs.length} glyphs — expected 6.` +
        "\n  Possible ligature substitution in font GSUB table."
    );
    process.exit(1);
  }

  console.log(`[generate] Font loaded. capHeight=${capHeight}, glyphs=${accrueGlyphs.length}`);

  // -------------------------------------------------------------------------
  // Step 2 — Create output directories
  // -------------------------------------------------------------------------
  fs.mkdirSync(CANDIDATES_DIR, { recursive: true });
  fs.mkdirSync(REJECTED_DIR, { recursive: true });
  fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });

  // Truncate lint log at the start of a fresh run
  fs.writeFileSync(LINT_LOG_PATH, "");

  // -------------------------------------------------------------------------
  // Step 3 — Generate all raw candidates
  // -------------------------------------------------------------------------
  console.log("[generate] Generating raw candidates…");

  const rawCandidates = [];

  // Direction A
  const aConfigs = SMOKE ? [A_CONFIGS[0]] : A_CONFIGS;
  for (const config of aConfigs) {
    const candidate = buildStandardCandidate("A", generateA, config, accrueGlyphs, capHeight);
    if (candidate) {
      rawCandidates.push(candidate);
      console.log(`[generate] Generated ${candidate.id} (Direction A)`);
    }
  }

  // Direction B
  const bConfigs = SMOKE ? [B_CONFIGS[0]] : B_CONFIGS;
  for (const config of bConfigs) {
    const candidate = buildStandardCandidate("B", generateB, config, accrueGlyphs, capHeight);
    if (candidate) {
      rawCandidates.push(candidate);
      console.log(`[generate] Generated ${candidate.id} (Direction B)`);
    }
  }

  // Direction C
  const cConfigs = SMOKE ? [C_CONFIGS[0]] : C_CONFIGS;
  for (const config of cConfigs) {
    const candidate = buildStandardCandidate("C", generateC, config, accrueGlyphs, capHeight);
    if (candidate) {
      rawCandidates.push(candidate);
      console.log(`[generate] Generated ${candidate.id} (Direction C)`);
    }
  }

  // Direction D — generate(config, font), returns fullSvg directly
  const dConfigs = SMOKE ? [D_CONFIGS[0]] : D_CONFIGS;
  for (const config of dConfigs) {
    const candidate = buildTypemarkCandidate(config, font);
    if (candidate) {
      rawCandidates.push(candidate);
      console.log(`[generate] Generated ${candidate.id} (Direction D)`);
    }
  }

  console.log(`[generate] Raw candidates: ${rawCandidates.length}`);

  // -------------------------------------------------------------------------
  // Step 4 — Run lints; cull failures
  // -------------------------------------------------------------------------
  console.log("[generate] Running pre-gate lints…");

  const passing = [];
  let culled = 0;

  for (const candidate of rawCandidates) {
    const result = runLint(candidate);
    if (result.pass) {
      passing.push(candidate);
    } else {
      culled++;
      console.log(`[generate] Culled ${candidate.id}: ${result.failures.join(", ")}`);
      writeRejected(candidate.id, candidate.lockupSvg, result.failures);
    }
  }

  console.log(`[generate] After lint pass: ${passing.length} passing, ${culled} culled`);

  // -------------------------------------------------------------------------
  // Step 5 — Per-direction floor check (D-05)
  // -------------------------------------------------------------------------
  if (!SMOKE) {
    const dirCounts = countByDirection(passing);
    for (const dir of ["A", "B", "C", "D"]) {
      if (dirCounts[dir] < MIN_PER_DIRECTION) {
        console.log(
          `[generate] Direction ${dir} below floor — running targeted regeneration ` +
            `(have ${dirCounts[dir]}, need ${MIN_PER_DIRECTION})`
        );

        // Determine which configs are already passing
        const passingIds = new Set(passing.filter((c) => c.direction === dir).map((c) => c.id));

        // Try mutated variants of CONFIGS for this direction (up to 2 retry passes per D-05)
        let retryAttempts = 0;
        const MAX_RETRIES = 2;

        const allDirConfigs =
          dir === "A" ? A_CONFIGS :
          dir === "B" ? B_CONFIGS :
          dir === "C" ? C_CONFIGS : D_CONFIGS;

        while (dirCounts[dir] < MIN_PER_DIRECTION && retryAttempts < MAX_RETRIES) {
          retryAttempts++;
          let added = 0;

          for (const baseConfig of allDirConfigs) {
            if (dirCounts[dir] >= MIN_PER_DIRECTION) break;

            // Create a mutated variant ID (e.g., A1v2, A1v3)
            const variantId = `${baseConfig.id}v${retryAttempts + 1}`;
            if (passingIds.has(variantId)) continue;

            // Mutate knobs slightly: multiply amplitude-like knob by 1.2
            let variantConfig;
            if (dir === "A") {
              variantConfig = {
                ...baseConfig,
                id: variantId,
                amplitude: Math.min(0.9, (baseConfig.amplitude ?? 0.4) * 1.2),
                rationale: `${baseConfig.rationale} [variant amplitude+20%]`,
              };
            } else if (dir === "B") {
              variantConfig = {
                ...baseConfig,
                id: variantId,
                stepHeight: Math.min(0.5, (baseConfig.stepHeight ?? 0.25) * 1.2),
                rationale: `${baseConfig.rationale} [variant stepHeight+20%]`,
              };
            } else if (dir === "C") {
              variantConfig = {
                ...baseConfig,
                id: variantId,
                sweep: Math.min(330, (baseConfig.sweep ?? 200) * 1.1),
                rationale: `${baseConfig.rationale} [variant sweep+10%]`,
              };
            } else {
              // Direction D — try a different CONFIGS entry
              continue;
            }

            let candidate;
            if (dir === "D") {
              candidate = buildTypemarkCandidate(variantConfig, font);
            } else {
              const genFn = dir === "A" ? generateA : dir === "B" ? generateB : generateC;
              candidate = buildStandardCandidate(dir, genFn, variantConfig, accrueGlyphs, capHeight);
            }

            if (!candidate) continue;

            const result = runLint(candidate);
            if (result.pass) {
              passing.push(candidate);
              passingIds.add(variantId);
              dirCounts[dir]++;
              added++;
              console.log(`[generate] Targeted regen: added ${variantId} to Direction ${dir}`);
            } else {
              culled++;
              writeRejected(candidate.id, candidate.lockupSvg, result.failures);
            }
          }

          if (added === 0) break; // no progress — stop retrying
        }

        if (dirCounts[dir] < MIN_PER_DIRECTION) {
          console.warn(
            `[generate] WARN: Direction ${dir} has only ${dirCounts[dir]} candidates after regeneration ` +
              `(floor is ${MIN_PER_DIRECTION})`
          );
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Step 6 — Write candidates
  //
  // NOTE: Gallery-size cap enforcement (D-04, 12–16) is intentionally deferred
  // to render-matrix.mjs, which runs AFTER 16px legibility culling.  Enforcing
  // the cap here (before legibility) risks discarding legible candidates when
  // the post-legibility count would already be under the 16-cap ceiling.
  // -------------------------------------------------------------------------
  console.log(`[generate] Writing ${passing.length} candidates to ${CANDIDATES_DIR}…`);
  for (const candidate of passing) {
    // Write SVG
    fs.writeFileSync(path.join(CANDIDATES_DIR, `${candidate.id}.svg`), candidate.lockupSvg);

    // Write JSON sidecar
    const sidecar = {
      id: candidate.id,
      direction: candidate.direction,
      config: candidate.config,
      rationale: candidate.rationale,
      skipGapRatio: candidate.skipGapRatio ?? false,
    };
    fs.writeFileSync(
      path.join(CANDIDATES_DIR, `${candidate.id}.json`),
      JSON.stringify(sidecar, null, 2)
    );
  }

  // -------------------------------------------------------------------------
  // Step 7 — Write metadata index
  // -------------------------------------------------------------------------
  const index = passing.map((c) => ({
    id: c.id,
    direction: c.direction,
    rationale: c.rationale,
  }));
  fs.writeFileSync(path.join(CANDIDATES_DIR, "index.json"), JSON.stringify(index, null, 2));

  // -------------------------------------------------------------------------
  // Summary line
  // -------------------------------------------------------------------------
  const passed = passing.length;
  const failed = rawCandidates.length - (rawCandidates.length - culled);
  console.log(
    `[generate] Done: ${passed} passed / ${culled} culled → ${passing.length} gallery candidates in ${CANDIDATES_DIR}`
  );
}

await main();
