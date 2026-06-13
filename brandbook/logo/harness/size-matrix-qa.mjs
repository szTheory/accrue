/**
 * size-matrix-qa.mjs — Playwright size-matrix QA screenshot gallery
 *
 * Renders all SVG variants in brandbook/logo/ at representative sizes
 * on both light and dark backgrounds. Also renders accrue-mark.svg at
 * 32px and 16px to verify favicon-scale legibility.
 *
 * QA screenshots go to .planning/phases/183-logo-system-production/qa-screenshots/
 * (NOT in brandbook/ — exploration artifacts stay in .planning/ per ROADMAP guardrails)
 *
 * Usage:
 *   node brandbook/logo/harness/size-matrix-qa.mjs
 *
 * Prerequisites:
 *   npx playwright install chromium (or playwright install chromium)
 *
 * Blank-render guard: if darkPixelCoverage < 0.5%, prints WARN (does not throw).
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import os from "os";
import { PNG } from "pngjs";
import { chromium } from "playwright";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const LOGO_DIR = path.resolve(__dirname, "..");
const QA_SCREENSHOTS_DIR = path.resolve(
  __dirname,
  "../../../.planning/phases/183-logo-system-production/qa-screenshots"
);

// ---------------------------------------------------------------------------
// Tile definitions
// ---------------------------------------------------------------------------

/**
 * Standard tiles: all SVGs at 320px wide, light + dark.
 * Plus: accrue-mark.svg at 32px and 16px.
 */
const STANDARD_TILES = [
  { id: "light-320", w: 320, h: 80, bg: "#FAFBFC", dpr: 2 },
  { id: "dark-320",  w: 320, h: 80, bg: "#111418", dpr: 2 },
];

const MARK_TILES = [
  { id: "light-32",  w: 32,  h: 32,  bg: "#FAFBFC", dpr: 4 },
  { id: "light-16",  w: 16,  h: 16,  bg: "#FAFBFC", dpr: 8 },
];

// SVGs that are wider aspect (social card)
const SOCIAL_CARD_TILES = [
  { id: "light-600", w: 600, h: 315, bg: "#FAFBFC", dpr: 1 },
];

// ---------------------------------------------------------------------------
// Blank-render guard
// ---------------------------------------------------------------------------

/**
 * Fraction of pixels that differ from the background color by > COLOR_DIST_THRESHOLD.
 * Used to detect blank renders (coordinate-space bug or invisible SVG ink).
 *
 * Checks against the tile background to handle both light and dark themes.
 */
function darkPixelCoverage(pngBuffer, bgHex) {
  const png = PNG.sync.read(pngBuffer);
  const { data, width, height } = png;
  // Parse background hex
  const r = parseInt(bgHex.slice(1, 3), 16);
  const g = parseInt(bgHex.slice(3, 5), 16);
  const b = parseInt(bgHex.slice(5, 7), 16);
  const COLOR_DIST_THRESHOLD = 30;
  let inkCount = 0;
  for (let i = 0; i < data.length; i += 4) {
    const a = data[i + 3];
    if (a < 64) continue; // skip near-transparent pixels
    const dr = data[i] - r;
    const dg = data[i + 1] - g;
    const db = data[i + 2] - b;
    if (Math.sqrt(dr * dr + dg * dg + db * db) > COLOR_DIST_THRESHOLD) inkCount++;
  }
  return inkCount / (width * height);
}

const BLANK_RENDER_MIN_COVERAGE = 0.005; // 0.5%

// ---------------------------------------------------------------------------
// HTML wrapper
// ---------------------------------------------------------------------------

function buildHtmlPage(svgContent, tile) {
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: ${tile.bg};
    width: ${tile.w}px; height: ${tile.h}px;
    overflow: hidden;
    display: flex; align-items: center; justify-content: center;
  }
  svg { max-width: 100%; max-height: 100%; display: block; }
</style>
</head>
<body>${svgContent}</body>
</html>`;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  fs.mkdirSync(QA_SCREENSHOTS_DIR, { recursive: true });

  // List all SVGs in brandbook/logo/
  const allFiles = fs.readdirSync(LOGO_DIR).filter((f) => f.endsWith(".svg"));
  allFiles.sort();

  console.log(`[size-matrix-qa] Found ${allFiles.length} SVGs in ${LOGO_DIR}`);
  console.log(`[size-matrix-qa] Output dir: ${QA_SCREENSHOTS_DIR}`);

  const browser = await chromium.launch({ headless: true });
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-qa-"));

  let screenshotCount = 0;
  let warnCount = 0;

  try {
    for (const svgFile of allFiles) {
      const svgPath = path.join(LOGO_DIR, svgFile);
      const svgContent = fs.readFileSync(svgPath, "utf-8");
      const baseName = svgFile.replace(".svg", "");

      // Determine which tiles to use for this SVG
      const isMark = baseName === "accrue-mark" || baseName === "favicon";
      const isSocialCard = baseName === "accrue-social-card";

      // Build the tile list
      let tiles = [...STANDARD_TILES];
      if (isMark) {
        tiles = [...STANDARD_TILES, ...MARK_TILES];
      } else if (isSocialCard) {
        tiles = SOCIAL_CARD_TILES;
      }

      for (const tile of tiles) {
        const outputName = `${baseName}--${tile.id}.png`;
        const outputPath = path.join(QA_SCREENSHOTS_DIR, outputName);
        const htmlContent = buildHtmlPage(svgContent, tile);

        // Write temp HTML file
        const tmpHtml = path.join(tmpDir, `${baseName}-${tile.id}.html`);
        fs.writeFileSync(tmpHtml, htmlContent);

        // Render with Playwright
        const ctx = await browser.newContext({
          viewport: { width: tile.w, height: tile.h },
          deviceScaleFactor: tile.dpr,
        });
        const page = await ctx.newPage();
        await page.goto(`file://${tmpHtml}`);

        // Screenshot the full page (body is sized to tile)
        const pngBuffer = await page.screenshot({ fullPage: false });
        await ctx.close();

        fs.writeFileSync(outputPath, pngBuffer);
        screenshotCount++;

        // Blank-render guard
        const coverage = darkPixelCoverage(pngBuffer, tile.bg);
        if (coverage < BLANK_RENDER_MIN_COVERAGE) {
          console.warn(
            `[size-matrix-qa] WARN: ${outputName} — dark coverage=${(coverage * 100).toFixed(3)}% (< 0.5% — possible blank render)`
          );
          warnCount++;
        }
      }
    }
  } finally {
    await browser.close();
    // Clean up temp dir
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }

  console.log(
    `[size-matrix-qa] Done. ${screenshotCount} screenshots saved to ${QA_SCREENSHOTS_DIR}`
  );
  if (warnCount > 0) {
    console.warn(
      `[size-matrix-qa] ${warnCount} blank-render warning(s) — review before commit`
    );
  } else {
    console.log(`[size-matrix-qa] All renders passed blank-render guard (coverage >= 0.5%)`);
  }
  console.log(`[size-matrix-qa] QA screenshots saved to ${QA_SCREENSHOTS_DIR} — review before commit`);
}

// isMain guard — prevents side effects when imported as a module
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error("[size-matrix-qa] FATAL:", err);
    process.exit(1);
  });
}
