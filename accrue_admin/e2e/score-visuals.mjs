/**
 * score-visuals.mjs — LLM vision-scoring CLI for admin UI PNGs
 *
 * Reads PNG screenshots captured by `npm run e2e:visuals:png-only` from
 * test-results/admin-visuals/{chromium-desktop,chromium-mobile}/, sends each
 * to the Anthropic messages API with the 10-dimension rubric, and emits
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
// 10-dimension rubric (locked schema from CONTEXT.md D-01/QA-02)
// Dimensions: 1-10. Score 0-3; pass threshold ≥ 2.
// ----------------------------------------------------------------------------
const DIMENSIONS = [
  { id: 1, name: "token-compliance" },
  { id: 2, name: "visual-hierarchy" },
  { id: 3, name: "spacing-rhythm" },
  { id: 4, name: "state-coverage" },
  { id: 5, name: "responsive-mobile-first" },
  { id: 6, name: "contrast" },
  { id: 7, name: "focus-semantics" },
  { id: 8, name: "brand-expression" },
  { id: 9, name: "motion" },
  { id: 10, name: "reuse-dry" },
];

const RUBRIC_PROMPT = `You are a senior UI/UX reviewer for a Phoenix/LiveView admin billing dashboard called Accrue Admin. You will evaluate a screenshot against a 10-dimension rubric and return a JSON array of findings.

DIMENSIONS AND SCORING (0–3, pass ≥ 2):

1. token-compliance — All colors, spacing, radii, shadows, and typography use design-system tokens (no hardcoded hex/px overrides). 0=many violations, 1=some, 2=mostly compliant, 3=fully compliant.

2. visual-hierarchy — Primary actions, headings, and data are visually prioritized; secondary content recedes appropriately. 0=no clear hierarchy, 1=weak, 2=clear, 3=excellent.

3. spacing-rhythm — Consistent vertical and horizontal rhythm; gutters, padding, and section spacing feel intentional. 0=chaotic, 1=inconsistent, 2=mostly consistent, 3=polished rhythm.

4. state-coverage — Empty, loading, error, and populated states are handled gracefully with appropriate feedback. 0=only happy path visible, 1=partial, 2=good coverage, 3=all states well-handled.

5. responsive-mobile-first — On mobile viewport, content is readable and actionable without horizontal scroll; touch targets ≥ 44px. 0=broken on mobile, 1=barely usable, 2=functional, 3=polished.

6. contrast — Text and interactive element contrast ratios meet WCAG AA (4.5:1 for body text, 3:1 for large/UI). 0=multiple failures, 1=one failure, 2=all passing, 3=exceeds AA.

7. focus-semantics — Focus indicators are clearly visible; interactive elements have appropriate ARIA roles/labels visible in the screenshot. 0=no visible focus indicators, 1=partial, 2=present, 3=exemplary.

8. brand-expression — The screen feels like polished developer tooling (well-made, not fintech-flashy); quiet confidence through typography and whitespace. 0=generic/off-brand, 1=neutral, 2=on-brand, 3=exemplary.

9. motion — Animations and transitions (if visible in screenshot context) are purposeful and not distracting. For static screenshots, evaluate whether motion affordances (hover states, transition indicators) are appropriate. 0=jarring/absent, 1=mediocre, 2=good, 3=excellent.

10. reuse-dry — Common patterns (tables, badges, cards, drawers) use the same component shapes across screens; no one-off inline styles. 0=significant duplication visible, 1=some, 2=mostly DRY, 3=fully consistent.

OUTPUT INSTRUCTIONS:
Return a JSON array only — no markdown, no explanation, no code fences. Each element must be an object with exactly these fields:
{
  "screen": "<screen name derived from filename>",
  "viewport": "<chromium-desktop or chromium-mobile>",
  "theme": "<light or dark>",
  "dimension": <integer 1-10>,
  "dimension_name": "<dimension name from the list above>",
  "score": <integer 0-3>,
  "defect": <string describing the issue, or null if score >= 2>,
  "suggested_fix": <string with actionable fix, or null if score >= 2>
}

Include one object per dimension per screenshot. Return exactly 10 objects for each image evaluated.`;

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
    // Truncate/create the output file
    fs.writeFileSync(findingsPath, "");
    findingsOutput = fs.createWriteStream(findingsPath, { flags: "a" });
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
        findings = JSON.parse(rawText);
      } catch (parseErr) {
        console.error(
          `[score-visuals] Failed to parse model response for ${screen} (${viewport}/${theme}): ${parseErr.message}`
        );
        console.error("[score-visuals] Raw response:", rawText.slice(0, 500));
        continue;
      }

      // Enrich findings with authoritative metadata (override model-supplied values)
      for (const finding of findings) {
        const enriched = {
          screen,
          viewport,
          theme,
          dimension: finding.dimension,
          dimension_name: finding.dimension_name,
          score: finding.score,
          defect: finding.defect ?? null,
          suggested_fix: finding.suggested_fix ?? null,
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
