/**
 * render-matrix.mjs — Playwright context-matrix screenshot runner
 *
 * For each candidate in candidates/index.json, renders 8 context tiles
 * (paper-light, ink-dark, 32px-favicon, 16px-favicon, avatar-circle,
 * readme-header, social-card, mono) via headless Chromium and saves them
 * to screenshots/{candidateId}/{tileId}.png.
 *
 * After rendering, the 16px legibility pixel-heuristic lint runs on the
 * 16px-favicon and 32px-favicon PNGs. Any candidate that fails is culled
 * to rejected/ with a reason sidecar, and removed from candidates/index.json.
 *
 * Usage:
 *   node harness/render-matrix.mjs           # full run — all candidates
 *   node harness/render-matrix.mjs --smoke   # first candidate per direction only
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { chromium } from "playwright";
import { lint16pxLegibility } from "./lint.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const PHASE_DIR = path.resolve(__dirname, "..");
const CANDIDATES_DIR = path.join(PHASE_DIR, "candidates");
const SCREENSHOTS_DIR = path.join(PHASE_DIR, "screenshots");
const REJECTED_DIR = path.join(PHASE_DIR, "rejected");
const SMOKE = process.argv.includes("--smoke");

/** 8 context tiles per candidate */
const TILES = [
  { id: "paper-light",   w: 320,  h: 80,  bg: "#FAFBFC", dpr: 1, mono: false },
  { id: "ink-dark",      w: 320,  h: 80,  bg: "#111418", dpr: 1, mono: false },
  { id: "32px-favicon",  w: 32,   h: 32,  bg: "#FAFBFC", dpr: 2, mono: false },
  { id: "16px-favicon",  w: 16,   h: 16,  bg: "#FAFBFC", dpr: 4, mono: false },
  { id: "avatar-circle", w: 96,   h: 96,  bg: "#FAFBFC", dpr: 2, mono: false },
  { id: "readme-header", w: 800,  h: 120, bg: "#FAFBFC", dpr: 1, mono: false },
  { id: "social-card",   w: 600,  h: 315, bg: "#FAFBFC", dpr: 1, mono: false },
  { id: "mono",          w: 320,  h: 80,  bg: "#FAFBFC", dpr: 1, mono: true  },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Build a minimal HTML wrapper for an SVG in a tile context.
 * For the mono tile, adds a CSS grayscale filter.
 */
function buildTileHtml(svgContent, tile) {
  const monoStyle = tile.mono
    ? `<style>svg { filter: grayscale(1); }</style>`
    : "";
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
${monoStyle}
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: ${tile.bg};
    width: ${tile.w}px;
    height: ${tile.h}px;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  svg {
    max-width: 100%;
    max-height: 100%;
  }
</style>
</head>
<body>
${svgContent}
</body>
</html>`;
}

/**
 * Render one tile for one candidate using Playwright.
 * Reuses the already-open browser (one browser per candidate).
 * @returns {string} outputPath
 */
async function renderTile(browser, svgContent, tile, candidateId) {
  const candidateDir = path.join(SCREENSHOTS_DIR, candidateId);
  const outputPath = path.join(candidateDir, `${tile.id}.png`);
  const tmpPath = path.join(candidateDir, `_tmp_${tile.id}.html`);

  const html = buildTileHtml(svgContent, tile);
  fs.writeFileSync(tmpPath, html);

  try {
    const ctx = await browser.newContext({
      viewport: { width: tile.w, height: tile.h },
      deviceScaleFactor: tile.dpr,
    });
    const page = await ctx.newPage();
    await page.goto("file://" + tmpPath);
    await page.locator("svg").screenshot({ path: outputPath });
    await ctx.close();
  } finally {
    // Always remove the temp HTML after screenshot (T-181-15 mitigation)
    try { fs.unlinkSync(tmpPath); } catch (_) { /* ignore */ }
  }

  return outputPath;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // Step 1 — Load candidates index
  const indexPath = path.join(CANDIDATES_DIR, "index.json");
  if (!fs.existsSync(indexPath)) {
    console.error("[render] candidates/index.json not found — run generate.mjs first");
    process.exit(1);
  }
  let candidates = JSON.parse(fs.readFileSync(indexPath, "utf8"));
  if (!Array.isArray(candidates) || candidates.length === 0) {
    console.error("[render] candidates/index.json is empty — run generate.mjs first");
    process.exit(1);
  }

  // Smoke mode: first candidate per direction only
  if (SMOKE) {
    const seen = new Set();
    candidates = candidates.filter(c => {
      if (seen.has(c.direction)) return false;
      seen.add(c.direction);
      return true;
    });
    console.log(`[render] Smoke mode — rendering ${candidates.length} candidates (1 per direction)`);
  }

  // Create screenshots root dir
  fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });
  fs.mkdirSync(REJECTED_DIR, { recursive: true });

  console.log(`[render] Rendering ${candidates.length} candidates × ${TILES.length} tiles…`);

  let rendered = 0;
  let culled16px = 0;
  let errors = 0;
  const culledIds = new Set();

  const browser = await chromium.launch({ headless: true });
  try {
    // Step 2 — For each candidate, render all 8 tiles
    for (const candidate of candidates) {
      const { id } = candidate;
      const svgPath = path.join(CANDIDATES_DIR, `${id}.svg`);

      if (!fs.existsSync(svgPath)) {
        console.warn(`[render] WARN: SVG not found for ${id} at ${svgPath} — skipping`);
        errors++;
        continue;
      }

      const svgContent = fs.readFileSync(svgPath, "utf8");
      const candidateDir = path.join(SCREENSHOTS_DIR, id);
      fs.mkdirSync(candidateDir, { recursive: true });

      try {
        // Render all 8 tiles
        for (const tile of TILES) {
          await renderTile(browser, svgContent, tile, id);
        }

        // Step 3 — 16px legibility lint (unless smoke mode)
        if (!SMOKE) {
          const path16 = path.join(SCREENSHOTS_DIR, id, "16px-favicon.png");
          const path32 = path.join(SCREENSHOTS_DIR, id, "32px-favicon.png");

          if (fs.existsSync(path16) && fs.existsSync(path32)) {
            const result = lint16pxLegibility(path16, path32);
            if (result.pass === false) {
              console.log(`[render] Culled ${id}: 16px legibility — ${result.reason}`);

              // Move SVG to rejected/
              const rejectedSvgPath = path.join(REJECTED_DIR, `${id}.svg`);
              fs.copyFileSync(svgPath, rejectedSvgPath);

              // Write reason sidecar
              const reasonText = [
                `Lint: 16px-legibility`,
                `Reason: ${result.reason}`,
                `Measured: ${JSON.stringify({ contrastRatio: result.contrastRatio, edgeDensityRatio: result.edgeDensityRatio })}`,
                `Culled: ${new Date().toISOString()}`,
              ].join("\n");
              fs.writeFileSync(path.join(REJECTED_DIR, `${id}.reason.txt`), reasonText + "\n");

              culledIds.add(id);
              culled16px++;
              continue; // don't count as rendered
            }
          }
        }

        rendered++;
        console.log(`[render] ${id} — ${TILES.length} tiles written`);
      } catch (err) {
        console.warn(`[render] WARN: Failed to render ${id} — ${err.message}`);
        errors++;
      }
    }
  } finally {
    await browser.close();
  }

  // Step 4 — Update candidates/index.json (remove culled candidates)
  if (culledIds.size > 0) {
    const surviving = candidates.filter(c => !culledIds.has(c.id));
    fs.writeFileSync(indexPath, JSON.stringify(surviving, null, 2));
    console.log(`[render] Updated index.json — removed ${culledIds.size} culled candidate(s)`);
  }

  console.log(
    `[render] Done: ${rendered} rendered / ${culled16px} culled by 16px lint / ${errors} errors → ${SCREENSHOTS_DIR}`
  );
}

await main();
