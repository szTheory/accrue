/**
 * score-visuals.mjs — LLM vision-scoring CLI for admin UI PNGs
 *
 * Reads PNG screenshots captured by `npm run e2e:visuals:png-only` from
 * test-results/admin-visuals/{chromium-desktop,chromium-mobile}/, sends each
 * to the Anthropic messages API with the Phase 187 rubric, and emits
 * structured NDJSON findings.
 *
 * REMEDIATION LOOP (cap 3 rounds):
 *   1. Run `npm run e2e:visuals:png-only` (with live Phoenix server) to capture PNGs.
 *   2. Run `ANTHROPIC_API_KEY=... npm run score-visuals` to score.
 *   3. Review test-results/admin-visuals/findings.ndjson for any score < 2.
 *   4. For each failing dimension: fix the CSS/component, rebuild assets
 *      (`mix accrue_admin.assets.build`), commit priv/static, reshoot, rescore.
 *   5. Repeat up to 3 rounds. Phase 176 confirmed all 21 screens ≥ 2 at code
 *      level, so minimal remediation is expected.
 *
 * Usage:
 *   node e2e/score-visuals.mjs               # score to findings.ndjson in RESULTS_DIR
 *   node e2e/score-visuals.mjs --stdout      # emit findings to stdout instead
 *   SCORE_MODEL=claude-opus-4-5 node ...     # override model
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ----------------------------------------------------------------------------
// API key guard — FIRST executable statement.
// If the key is absent, skip cleanly. This must run before any SDK import so
// that ERR_MODULE_NOT_FOUND (SDK not installed) cannot occur in the no-key path.
// ----------------------------------------------------------------------------
if (!process.env.ANTHROPIC_API_KEY) {
  console.log("[score-visuals] ANTHROPIC_API_KEY not set — skipping (human/CI gate only)");
  process.exit(0);
}

const { default: manifest } = await import("./baseline-manifest.js");

// Dynamic import of the Anthropic SDK — only executed when key IS present.
const { default: Anthropic } = await import("@anthropic-ai/sdk");
const client = new Anthropic(); // reads ANTHROPIC_API_KEY from env

// ----------------------------------------------------------------------------
// Configuration
// ----------------------------------------------------------------------------
const model = process.env.SCORE_MODEL || "claude-sonnet-4-5";
const RESULTS_DIR = path.join(__dirname, "../test-results/admin-visuals");
const MAX_B64_BYTES = 5 * 1024 * 1024; // 5 MB — skip oversized images with a warning
const TO_STDOUT = process.argv.includes("--stdout");

// ----------------------------------------------------------------------------
// 12-dimension rubric (Phase 187 manifest contract)
// Dimensions: 1-12. Score 0-3; pass threshold ≥ 2.
// ----------------------------------------------------------------------------
const { DIMENSIONS, SURFACES, PROJECTS, cellId } = manifest;
const EXPECTED_DIMENSION_IDS = DIMENSIONS.map((dimension) => dimension.id);
const DIMENSION_PROMPT = DIMENSIONS
  .map((dimension) => `${dimension.id}. ${dimension.name}`)
  .join("\n");

const RUBRIC_PROMPT = `You are a senior UI/UX reviewer for a Phoenix/LiveView admin billing dashboard called Accrue Admin. You will evaluate a screenshot against a 12-dimension rubric and return a JSON array of findings.

DIMENSIONS AND SCORING (0–3, pass ≥ 2):

${DIMENSION_PROMPT}

Use the Phase 187 rubric meanings: tokenized implementation, hierarchy, spacing rhythm, state coverage, responsive behavior, contrast, focus semantics, brand expression, motion safety, reuse, interaction-integrity, and microcopy.

OUTPUT INSTRUCTIONS:
Return a JSON array only — no markdown, no explanation, no code fences. Each element must be an object with exactly these fields:
{
  "screen": "<screen name derived from filename>",
  "viewport": "<chromium-desktop or chromium-mobile>",
  "theme": "<light or dark>",
  "dimension": <integer 1-12>,
  "dimension_name": "<dimension name from the list above>",
  "score": <integer 0-3>,
  "defect": <string describing the issue, or null if score >= 2>,
  "suggested_fix": <string with actionable fix, or null if score >= 2>
}

Include one object per dimension per screenshot. Return exactly 12 objects for each image evaluated.`;

function metadataForImage(screen, viewport, theme, dimensionId) {
  const surface = SURFACES.find((entry) => entry.surface === screen);
  const project = PROJECTS.find((entry) => entry.name === viewport || entry.mode === viewport);
  const dimension = DIMENSIONS.find((entry) => entry.id === dimensionId);
  if (!surface || !project || !dimension || !surface.themes.includes(theme)) return null;

  return {
    cell_id: cellId(surface.surface, project.name, theme, "default-populated", dimension.id),
    surface: surface.surface,
    surface_type: surface.surface_type,
    state: "default-populated",
    persona_job: surface.persona_job,
    coverage_status: "covered",
    dimension: dimension.id,
    dimension_name: dimension.name,
  };
}

function hasExpectedDimensions(findings) {
  if (!Array.isArray(findings) || findings.length !== EXPECTED_DIMENSION_IDS.length) return false;
  const ids = findings.map((finding) => Number(finding.dimension)).sort((a, b) => a - b);
  return EXPECTED_DIMENSION_IDS.every((id, index) => ids[index] === id);
}

// ----------------------------------------------------------------------------
// PNG discovery helpers
// ----------------------------------------------------------------------------
function discoverPngs() {
  if (!fs.existsSync(RESULTS_DIR)) {
    console.log(`[score-visuals] RESULTS_DIR not found: ${RESULTS_DIR}`);
    console.log("[score-visuals] Run 'npm run e2e:visuals:png-only' first to capture screenshots.");
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
// Scoring loop
// ----------------------------------------------------------------------------
async function main() {
  const pngs = discoverPngs();
  if (pngs.length === 0) {
    console.log("[score-visuals] No PNGs found — nothing to score.");
    process.exit(0);
  }

  console.log(`[score-visuals] Found ${pngs.length} PNG(s) to score using model: ${model}`);

  let findingsOutput;
  let findingsPath;

  if (TO_STDOUT) {
    findingsOutput = process.stdout;
  } else {
    findingsPath = path.join(RESULTS_DIR, "findings.ndjson");
    // Truncate/create the output file so reruns don't concatenate stale findings
    fs.writeFileSync(findingsPath, "");
  }

  let totalFindings = 0;
  let belowBar = 0;
  let skipped = 0;

  try {
    for (const { pngPath, screen, viewport, theme } of pngs) {
      // Large-image guard — skip PNGs whose base64 encoding exceeds 5 MB
      const b64 = fs.readFileSync(pngPath, "base64");
      if (b64.length > MAX_B64_BYTES) {
        console.warn(
          `[score-visuals] Skipping ${pngPath} — base64 size ${b64.length} exceeds 5 MB limit`
        );
        skipped++;
        continue;
      }

      console.log(`[score-visuals] Scoring ${viewport}/${screen} (${theme})…`);

      const response = await client.messages.create({
        model,
        max_tokens: 2048,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: "image/png",
                  data: b64,
                },
              },
              {
                type: "text",
                text: RUBRIC_PROMPT,
              },
            ],
          },
        ],
      });

      const rawText = response.content[0]?.text ?? "[]";

      let findings;
      try {
        const parsed = JSON.parse(rawText);
        findings = Array.isArray(parsed) ? parsed : null;
      } catch (parseErr) {
        console.error(
          `[score-visuals] Failed to parse model response for ${screen} (${viewport}/${theme}): ${parseErr.message}`
        );
        console.error("[score-visuals] Raw response:", rawText.slice(0, 500));
        continue;
      }

      if (!findings) {
        console.error(
          `[score-visuals] Model returned non-array for ${screen} (${viewport}/${theme}): ${rawText.slice(0, 200)}`
        );
        continue; // skip this image, don't abort the run
      }

      if (!hasExpectedDimensions(findings)) {
        console.warn(
          `[score-visuals] Skipping ${screen} (${viewport}/${theme}) — model response did not contain dimension ids 1-12 exactly once`
        );
        skipped++;
        continue;
      }

      // Enrich findings with authoritative metadata (override model-supplied values)
      for (const finding of findings) {
        const dimensionId = Number(finding.dimension);
        const metadata = metadataForImage(screen, viewport, theme, dimensionId);
        const enriched = {
          screen,
          viewport,
          theme,
          dimension: dimensionId,
          dimension_name:
            DIMENSIONS.find((dimension) => dimension.id === dimensionId)?.name || finding.dimension_name,
          score: finding.score,
          defect: finding.defect ?? null,
          suggested_fix: finding.suggested_fix ?? null,
          ...(metadata || {}),
        };

        const line = JSON.stringify(enriched) + "\n";
        if (TO_STDOUT) {
          findingsOutput.write(line);
        } else {
          fs.appendFileSync(findingsPath, line);
        }

        totalFindings++;
        if (typeof enriched.score === "number" && enriched.score < 2) {
          belowBar++;
        }
      }
    }
  } catch (err) {
    console.error(`[score-visuals] API error: ${err.message}`);
    process.exit(1);
  }

  if (!TO_STDOUT && findingsPath) {
    console.log(`[score-visuals] Findings written to: ${findingsPath}`);
  }

  const skippedNote = skipped > 0 ? ` (${skipped} skipped — oversized)` : "";
  console.log(
    `[score-visuals] Scored ${pngs.length - skipped} PNGs → ${totalFindings} findings (${belowBar} below bar)${skippedNote}`
  );

  if (belowBar > 0) {
    console.log(
      `[score-visuals] ${belowBar} finding(s) scored < 2 — review findings.ndjson and follow the remediation loop (≤3 rounds).`
    );
  }
}

await main();
