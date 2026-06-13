/**
 * generate-r2.mjs — Round 2 orchestration entry point for the logo tournament
 *
 * Usage:
 *   node .planning/phases/182-tournament-convergent-refinement/harness/generate-r2.mjs          # full run: 7 R2 candidates
 *   node .planning/phases/182-tournament-convergent-refinement/harness/generate-r2.mjs --smoke  # smoke: R2-1 only
 *
 * Pipeline:
 *   1. Import primitives from 181 harness (geist-spine, assemble-lockup, lint, generate.buildMonoSvg)
 *   2. Import R2_CONFIGS + generate() from b-step-r2.mjs
 *   3. Create CANDIDATES_DIR, REJECTED_DIR in 182 output dir
 *   4. Load Geist font; extract glyphs for "accrue"
 *   5. For each R2 config: generate mark path → assembleLockup → buildMonoSvg → lint → write SVG
 *   6. Write candidates/index.json
 *
 * Key bindings (from 182-02-PLAN.md interfaces):
 *   - buildMonoSvg imported from generate.mjs (not re-implemented inline)
 *   - accentPathD threading: passed into assembleLockup for two-tone marks
 *   - isMain guard: main() only runs when script is executed directly
 */

import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// 182 phase dir is one level up from harness/
const PHASE_DIR = path.resolve(__dirname, "..");
const HARNESS_DIR = path.resolve(
  __dirname,
  "../../181-svg-pipeline-tournament-round-1-divergent/harness"
);

const CANDIDATES_DIR = path.join(PHASE_DIR, "candidates");
const REJECTED_DIR = path.join(PHASE_DIR, "rejected");
const LINT_LOG_PATH = path.join(PHASE_DIR, "lint-results.ndjson");

const SMOKE = process.argv.includes("--smoke");

// ---------------------------------------------------------------------------
// Dynamic imports from 181 harness primitives
// ---------------------------------------------------------------------------

const { loadGeistFont, extractGlyphs, getCapHeight } = await import(
  path.join(HARNESS_DIR, "geist-spine.mjs")
);
const { assembleLockup } = await import(
  path.join(HARNESS_DIR, "assemble-lockup.mjs")
);
const { lintCandidate } = await import(
  path.join(HARNESS_DIR, "lint.mjs")
);
// buildMonoSvg is the single owner in generate.mjs — import, do NOT re-implement inline
const { buildMonoSvg } = await import(
  path.join(HARNESS_DIR, "generate.mjs")
);
const { R2_CONFIGS, generate } = await import(
  path.join(__dirname, "dirs/b-step-r2.mjs")
);

// ---------------------------------------------------------------------------
// main()
// ---------------------------------------------------------------------------

async function main() {
  console.log(`[generate-r2] Starting Round 2 pipeline — ${SMOKE ? "SMOKE" : "FULL"} run…`);

  // Step 1 — Create output directories
  fs.mkdirSync(CANDIDATES_DIR, { recursive: true });
  fs.mkdirSync(REJECTED_DIR, { recursive: true });

  // Truncate lint log for fresh run
  fs.writeFileSync(LINT_LOG_PATH, "");

  // Step 2 — Load Geist font
  console.log("[generate-r2] Loading Geist font…");
  let font;
  try {
    font = await loadGeistFont();
  } catch (err) {
    console.error(`[generate-r2] FATAL: Could not load Geist font — ${err.message}`);
    process.exit(1);
  }

  const capHeight = getCapHeight(font);
  const glyphs = extractGlyphs(font, "accrue", 1000);

  if (glyphs.length !== 6) {
    console.error(
      `[generate-r2] FATAL: extractGlyphs('accrue') returned ${glyphs.length} glyphs — expected 6.` +
        "\n  Possible ligature substitution in font GSUB table."
    );
    process.exit(1);
  }
  console.log(`[generate-r2] Font loaded. capHeight=${capHeight}, glyphs=${glyphs.length}`);

  // Step 3 — Generate candidates
  const configs = SMOKE ? [R2_CONFIGS[0]] : R2_CONFIGS;
  const passing = [];
  let culled = 0;

  for (const config of configs) {
    console.log(`[generate-r2] Processing ${config.id} (${config.colorTreatment})…`);

    let result;
    try {
      result = generate(config);
    } catch (err) {
      console.error(`[generate-r2] Error generating ${config.id}: ${err.message}`);
      culled++;
      continue;
    }

    const { markPathD, accentPathD, markWidth, markHeight } = result;

    // Derive ink fill from colorTreatment
    const ink = config.colorTreatment === "moss" ? "#5E9E84" : "#181818";
    // Derive accentFill for two-tone marks
    const accentFill = config.colorTreatment === "two-tone" ? "#5E9E84" : undefined;

    // Assemble lockup SVG
    let lockupSvg;
    try {
      const assembleResult = assembleLockup(markPathD, glyphs, {
        markWidth,
        markHeight,
        capHeight,
        gapRatio: 0.15,
        viewboxH: capHeight * 1.4,
        markIsTypemark: false,
        accentPathD,
        palette: { ink, paper: "#FAFBFC", accentFill },
      });
      // assembleLockup returns SVG string in standard mode
      lockupSvg = typeof assembleResult === "string" ? assembleResult : assembleResult.svg;
    } catch (err) {
      console.error(`[generate-r2] Error assembling lockup for ${config.id}: ${err.message}`);
      culled++;
      continue;
    }

    // Build mono-derived SVG using the imported buildMonoSvg (do NOT re-implement)
    const monoSvgString = buildMonoSvg(lockupSvg, config.monoMap);

    // Build mark-only SVG for square/small tiles (16px-favicon, 32px-favicon, avatar-circle).
    // A favicon is the MARK alone — rendering the full lockup into a square viewport
    // stretches the wordmark and makes the icon impossible to judge.
    // viewBox is mark-local coordinate space: 0 0 markWidth markHeight.
    const markSvgLines = [
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${markWidth} ${markHeight}">`,
      `  <path d="${markPathD}" fill="${ink}"/>`,
    ];
    if (accentPathD && accentFill) {
      // Two-tone: overlay the accent step in Moss (#5E9E84)
      markSvgLines.push(`  <path d="${accentPathD}" fill="${accentFill}"/>`);
    }
    markSvgLines.push(`</svg>`);
    const markSvgString = markSvgLines.join("\n");

    // Build candidate object
    const candidate = {
      id: config.id,
      direction: "B",
      colorTreatment: config.colorTreatment,
      config,
      markPathD,
      accentPathD,
      markWidth,
      markHeight,
      lockupSvg,
      markSvgString,
      monoSvgString,
      capHeight,
      skipGapRatio: false,
      rationale: config.rationale,
    };

    // Write SVG for lint (lintCandidate reads from PHASE_DIR, needs CANDIDATES_DIR)
    const svgPath = path.join(CANDIDATES_DIR, `${config.id}.svg`);
    fs.writeFileSync(svgPath, lockupSvg);
    // Write mark-only SVG (used by render-matrix for square tiles)
    fs.writeFileSync(path.join(CANDIDATES_DIR, `${config.id}-mark.svg`), markSvgString);
    if (monoSvgString) {
      fs.writeFileSync(path.join(CANDIDATES_DIR, `${config.id}-mono.svg`), monoSvgString);
    }

    // Run lint
    let lintResult;
    try {
      lintResult = lintCandidate(
        {
          id: config.id,
          direction: "B",
          svgString: lockupSvg,
          monoSvgString,
          skipGapRatio: false,
        },
        { writeLog: false }
      );
    } catch (err) {
      console.error(`[generate-r2] Error running lint for ${config.id}: ${err.message}`);
      lintResult = { pass: false, failures: [`lint-error: ${err.message}`] };
    }

    // Append to lint log
    const logEntry = {
      id: config.id,
      pass: lintResult.pass,
      failures: lintResult.failures ?? [],
      timestamp: new Date().toISOString(),
    };
    fs.appendFileSync(LINT_LOG_PATH, JSON.stringify(logEntry) + "\n");

    if (!lintResult.pass) {
      // Move SVG to rejected/
      const failureList = lintResult.failures?.join(", ") ?? "unknown";
      console.log(`[generate-r2] Culled ${config.id}: ${failureList}`);

      const rejectedSvgPath = path.join(REJECTED_DIR, `${config.id}.svg`);
      try { fs.renameSync(svgPath, rejectedSvgPath); } catch (_) { /* ignore */ }
      if (monoSvgString) {
        const monoPath = path.join(CANDIDATES_DIR, `${config.id}-mono.svg`);
        const rejectedMonoPath = path.join(REJECTED_DIR, `${config.id}-mono.svg`);
        try { fs.renameSync(monoPath, rejectedMonoPath); } catch (_) { /* ignore */ }
      }

      // Write reason file
      const reasonText = [
        `Candidate: ${config.id}`,
        `Lint failures: ${failureList}`,
        `Culled: ${new Date().toISOString()}`,
      ].join("\n");
      fs.writeFileSync(path.join(REJECTED_DIR, `${config.id}-reason.txt`), reasonText + "\n");

      culled++;
    } else {
      passing.push(candidate);
      console.log(`[generate-r2] Passed ${config.id} (${config.colorTreatment})`);
    }
  }

  // Step 4 — Write index.json with surviving candidates
  const index = passing.map((c) => ({
    id: c.id,
    direction: c.direction,
    colorTreatment: c.colorTreatment,
    rationale: c.rationale,
    skipGapRatio: c.skipGapRatio,
    markSvgString: c.markSvgString,
    monoSvgString: c.monoSvgString,
  }));
  fs.writeFileSync(path.join(CANDIDATES_DIR, "index.json"), JSON.stringify(index, null, 2));

  // Step 5 — Summary
  console.log(
    `[generate-r2] Done: ${passing.length} passed / ${culled} culled → ${passing.length} gallery candidates in ${CANDIDATES_DIR}`
  );
}

// isMain guard — per D-181-05 lesson; importing this module does NOT trigger the pipeline
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[generate-r2] FATAL:", err);
    process.exit(1);
  });
}
