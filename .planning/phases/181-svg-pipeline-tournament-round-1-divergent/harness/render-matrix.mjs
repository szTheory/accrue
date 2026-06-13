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
import { PNG } from "pngjs";
import { lint16pxLegibility } from "./lint.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const argOutputDir = (() => {
  const i = process.argv.indexOf("--output-dir");
  return i !== -1 ? path.resolve(process.argv[i + 1]) : null;
})();
const PHASE_DIR = argOutputDir ?? path.resolve(__dirname, "..");
const CANDIDATES_DIR = path.join(PHASE_DIR, "candidates");
const SCREENSHOTS_DIR = path.join(PHASE_DIR, "screenshots");
const REJECTED_DIR = path.join(PHASE_DIR, "rejected");
const SMOKE = process.argv.includes("--smoke");

/** Target gallery size range (D-04). Gallery cap is enforced HERE, after legibility culling. */
const TARGET_GALLERY_SIZE = { min: 12, max: 16 };

/** Per-direction minimum in final gallery (D-05 floor). */
const MIN_PER_DIRECTION = 3;

/** 8 context tiles per candidate.
 * source: "lockup" — renders the full mark+logotype lockup SVG (default for wide tiles).
 * source: "mark"   — renders the mark-only SVG (for square favicon / avatar tiles so the
 *                     wordmark is not squeezed into a square viewport and the icon can be
 *                     judged on its own merits). Uses candidate.markSvgString when available;
 *                     falls back to full lockupSvg only if markSvgString is absent.
 */
const TILES = [
  { id: "paper-light",   w: 320,  h: 80,  bg: "#FAFBFC", dpr: 1, mono: false, source: "lockup" },
  { id: "ink-dark",      w: 320,  h: 80,  bg: "#111418", dpr: 1, mono: false, source: "lockup" },
  { id: "32px-favicon",  w: 32,   h: 32,  bg: "#FAFBFC", dpr: 2, mono: false, source: "mark"   },
  { id: "16px-favicon",  w: 16,   h: 16,  bg: "#FAFBFC", dpr: 4, mono: false, source: "mark"   },
  { id: "avatar-circle", w: 96,   h: 96,  bg: "#FAFBFC", dpr: 2, mono: false, source: "mark"   },
  { id: "readme-header", w: 800,  h: 120, bg: "#FAFBFC", dpr: 1, mono: false, source: "lockup" },
  { id: "social-card",   w: 600,  h: 315, bg: "#FAFBFC", dpr: 1, mono: false, source: "lockup" },
  { id: "mono",          w: 320,  h: 80,  bg: "#FAFBFC", dpr: 1, mono: true,  source: "lockup" },
];

/**
 * Minimum fraction of "dark" pixels in the paper-light tile.
 * A render with < 0.5% dark coverage is considered blank (coordinate-space bug
 * or invisible mark). Distinct from the 16px legibility cull — reported as
 * "blank-render" rejection reason so it is unambiguous in diagnostics.
 */
const BLANK_RENDER_MIN_DARK_COVERAGE = 0.005; // 0.5%

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Fraction of pixels that are "ink-colored" (differ from the paper-light bg) in a PNG file.
 * Used as blank-render guard: a near-empty render indicates the SVG ink is
 * outside the viewBox (coordinate-space bug) rather than a legibility issue.
 *
 * Uses color-distance from the paper-light background (#FAFBFC = 250, 251, 252)
 * rather than a luminance threshold — this correctly handles Moss (#5E9E84) ink,
 * which has luminance ~0.56 (above the old 0.5 threshold) but is clearly visible.
 *
 * @param {string} pngPath — path to the PNG file
 * @returns {number} fraction of ink-colored pixels (0.0–1.0)
 */
function darkPixelCoverage(pngPath) {
  const png = PNG.sync.read(fs.readFileSync(pngPath));
  const { data, width, height } = png;
  // Paper-light background: #FAFBFC = rgb(250, 251, 252)
  const BG_R = 250, BG_G = 251, BG_B = 252;
  // Pixel is "ink" if its color distance from the bg exceeds this threshold
  // (Euclidean RGB distance; threshold ~30 excludes JPEG/anti-alias noise)
  const COLOR_DIST_THRESHOLD = 30;
  let inkCount = 0;
  for (let i = 0; i < data.length; i += 4) {
    const a = data[i + 3];
    if (a < 64) continue; // skip near-transparent pixels
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];
    const dr = r - BG_R;
    const dg = g - BG_G;
    const db = b - BG_B;
    const dist = Math.sqrt(dr * dr + dg * dg + db * db);
    if (dist > COLOR_DIST_THRESHOLD) inkCount++;
  }
  return inkCount / (width * height);
}

/**
 * Color map for the ink-dark tile: swap dark ink to paper, and paper/fog knockouts
 * to the dark bg and a dark mid-tone respectively — so the logo reads light-on-dark.
 * Keys are exact hex values as they appear in generated SVGs (case-sensitive).
 */
const INK_DARK_COLOR_MAP = {
  "#181818": "#FAFBFC", // dark ink → paper (visible on dark bg)
  "#FAFBFC": "#111418", // paper knockout → dark bg (knockout still knocks out)
  "#E9EEF2": "#2A333C", // fog knockout → dark mid-tone (Direction D stepped/fill motifs)
  "#5E9E84": "#5E9E84", // Moss → Moss (identity; 5.89:1 on Ink-dark per contrast-table.txt; no swap needed)
};

/**
 * Apply INK_DARK_COLOR_MAP to an SVG string by simple string replacement.
 * Uses a two-pass approach to avoid A→B, B→A flip conflicts.
 */
function applyInkDarkColors(svgContent) {
  // Replace using a placeholder pass to avoid collision between swapped pairs.
  // All three keys are distinct hex values so a single-pass regex replace is safe
  // as long as we replace all at once (no key is a substring of another key here).
  const replacements = Object.entries(INK_DARK_COLOR_MAP);
  const pattern = new RegExp(
    replacements.map(([k]) => k.replace(/#/g, "\\#")).join("|"),
    "g"
  );
  return svgContent.replace(pattern, (match) => INK_DARK_COLOR_MAP[match] ?? match);
}

/**
 * Build a minimal HTML wrapper for an SVG in a tile context.
 * For the mono tile: uses monoSvgString if available (monoMap-derived grey), else CSS grayscale.
 * For the ink-dark tile: inverts ink/paper colors so the logo is light-on-dark.
 * For the social-card tile: adds a "real context" text overlay (D-182-08) with prominent sizing.
 * For mark-source tiles (32px-favicon, 16px-favicon, avatar-circle): renders the mark-only SVG
 * so the wordmark is not squeezed into a square viewport and the icon can be judged alone.
 *
 * @param {string} svgContent — the candidate's lockup SVG string
 * @param {object} tile — tile config from TILES array
 * @param {string | undefined} monoSvgString — monoMap-derived SVG for Moss/two-tone candidates
 * @param {string | undefined} markSvgString — mark-only SVG (for square/favicon tiles)
 */
function buildTileHtml(svgContent, tile, monoSvgString, markSvgString) {
  // Resolve the base SVG source.
  // Mark-source tiles (32px-favicon, 16px-favicon, avatar-circle): use the mark-only SVG so
  // the favicon/avatar shows the icon alone. Falls back to full lockup only if markSvgString
  // is absent (e.g. old index.json without the markSvgString field).
  const isMarkTile = tile.source === "mark";
  const baseSvg = (isMarkTile && markSvgString) ? markSvgString : svgContent;

  // Mono tile (source: "lockup"): prefer monoSvgString (exact grey-swap) over CSS grayscale.
  // Ink-dark tile (source: "lockup"): apply INK_DARK_COLOR_MAP to the lockup SVG.
  // Mark-source tiles: just use the mark SVG as-is (all mark tiles have paper-light bg).
  let effectiveSvg;
  if (tile.mono && monoSvgString) {
    effectiveSvg = monoSvgString; // grey paths from monoMap; lockup tile only
  } else if (tile.id === "ink-dark") {
    // Ink-dark is always a lockup tile; apply color swap to the full lockup SVG
    effectiveSvg = applyInkDarkColors(baseSvg);
  } else {
    effectiveSvg = baseSvg;
  }

  // CSS grayscale filter only when mono tile but no monoSvgString available
  const monoStyle = (tile.mono && !monoSvgString)
    ? `<style>svg { filter: grayscale(1); }</style>`
    : "";

  // WR-07: avatar-circle tile renders with border-radius:50% on body so the
  // circular clip is visible in the screenshot (screenshotted via page.locator("body")).
  const circleStyle = tile.id === "avatar-circle"
    ? `<style>body { border-radius: 50%; overflow: hidden; }</style>`
    : "";

  // D-182-08: social-card "real context" text overlay — exercises actual social-card use case.
  // The logo lockup is rendered at a prominent scale (200px height out of 315px card height)
  // so both the mark and the accompanying copy are clearly readable at 600×315.
  // Layout: logo centered top-half, copy text below — a real Open Graph card pattern.
  const socialCardOverlay = tile.id === "social-card"
    ? `<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;width:100%;height:100%;gap:20px;font-family:system-ui,sans-serif;padding:32px;">
        <div style="height:80px;max-width:520px;width:100%;display:flex;align-items:center;justify-content:center;overflow:hidden;">
          ${effectiveSvg}
        </div>
        <div style="display:flex;flex-direction:column;align-items:center;gap:6px;text-align:center;">
          <div style="font-size:22px;font-weight:700;color:#181818;letter-spacing:-0.01em;">accrue</div>
          <div style="font-size:15px;font-weight:400;color:#5E9E84;">Elixir billing library for Phoenix</div>
          <div style="font-size:12px;font-weight:400;color:#6B7280;">hex.pm/packages/accrue</div>
        </div>
      </div>`
    : "";

  const bodyContent = tile.id === "social-card"
    ? socialCardOverlay
    : effectiveSvg;

  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
${monoStyle}
${circleStyle}
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
    display: block;
  }
</style>
</head>
<body>
${bodyContent}
</body>
</html>`;
}

/**
 * Render one tile for one candidate using Playwright.
 * Reuses the already-open browser (one browser per candidate).
 * @param {string} svgContent — the candidate's lockup SVG string
 * @param {object} tile — tile config from TILES array
 * @param {string} candidateId
 * @param {string | undefined} monoSvgString — monoMap-derived SVG for mono tile (Moss/two-tone)
 * @param {string | undefined} markSvgString — mark-only SVG for square/favicon tiles
 * @returns {string} outputPath
 */
async function renderTile(browser, svgContent, tile, candidateId, monoSvgString, markSvgString) {
  const candidateDir = path.join(SCREENSHOTS_DIR, candidateId);
  const outputPath = path.join(candidateDir, `${tile.id}.png`);
  const tmpPath = path.join(candidateDir, `_tmp_${tile.id}.html`);

  const html = buildTileHtml(svgContent, tile, monoSvgString, markSvgString);
  fs.writeFileSync(tmpPath, html);

  try {
    const ctx = await browser.newContext({
      viewport: { width: tile.w, height: tile.h },
      deviceScaleFactor: tile.dpr,
    });
    const page = await ctx.newPage();
    await page.goto("file://" + tmpPath);
    // WR-07: avatar-circle uses body locator to capture the circular clip.
    // D-182-08: social-card tile uses body locator too — the SVG is nested inside the
    // text-overlay div and isn't the direct body child, so page.locator("svg") would
    // fail to screenshot the full tile context (the copy overlay).
    const screenshotTarget =
      tile.id === "avatar-circle" || tile.id === "social-card"
        ? page.locator("body")
        : page.locator("svg");
    await screenshotTarget.screenshot({ path: outputPath });
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
      // monoSvgString from index.json — for Moss/two-tone candidates, renders true grey (not CSS filter)
      const monoSvgString = candidate.monoSvgString ?? undefined;
      // markSvgString from index.json — mark-only SVG for square/favicon tiles so the wordmark
      // is not squeezed into a square viewport and the icon can be judged alone.
      // Falls back to reading the -mark.svg file from disk if not embedded in index.json.
      let markSvgString = candidate.markSvgString ?? undefined;
      if (!markSvgString) {
        const markSvgPath = path.join(CANDIDATES_DIR, `${id}-mark.svg`);
        if (fs.existsSync(markSvgPath)) {
          markSvgString = fs.readFileSync(markSvgPath, "utf8");
        }
      }
      const candidateDir = path.join(SCREENSHOTS_DIR, id);
      fs.mkdirSync(candidateDir, { recursive: true });

      try {
        // Render all 8 tiles
        for (const tile of TILES) {
          await renderTile(browser, svgContent, tile, id, monoSvgString, markSvgString);
        }

        // Step 3a — Blank-render guard (always, even in smoke mode)
        // If the paper-light tile has < 0.5% dark pixels, the SVG ink is almost
        // certainly outside the viewBox (coordinate-space bug). Reject as
        // "blank-render" — distinct from the legibility cull — before further checks.
        {
          const paperLightPath = path.join(SCREENSHOTS_DIR, id, "paper-light.png");
          if (fs.existsSync(paperLightPath)) {
            const coverage = darkPixelCoverage(paperLightPath);
            if (coverage < BLANK_RENDER_MIN_DARK_COVERAGE) {
              console.error(
                `[render] BLANK-RENDER ${id}: paper-light dark coverage=${(coverage * 100).toFixed(3)}% ` +
                  `< ${(BLANK_RENDER_MIN_DARK_COVERAGE * 100).toFixed(1)}% threshold — SVG ink is outside viewBox`
              );
              const rejectedSvgPath = path.join(REJECTED_DIR, `${id}.svg`);
              fs.copyFileSync(svgPath, rejectedSvgPath);
              const reasonText = [
                `Lint: blank-render`,
                `Reason: paper-light dark coverage=${(coverage * 100).toFixed(3)}% < ${(BLANK_RENDER_MIN_DARK_COVERAGE * 100).toFixed(1)}% (SVG ink outside viewBox)`,
                `Culled: ${new Date().toISOString()}`,
              ].join("\n");
              fs.writeFileSync(path.join(REJECTED_DIR, `${id}.reason.txt`), reasonText + "\n");
              culledIds.add(id);
              culled16px++; // reuse counter for tracking; also logged as blank-render
              continue;
            }
          }
        }

        // Step 3b — 16px legibility lint (unless smoke mode)
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

  // Step 4 — Update candidates/index.json (remove legibility-culled candidates)
  // WR-01: read the FULL index from disk (smoke mode may have only rendered a subset;
  // surviving must start from the full set to avoid clobbering unrendered candidates).
  const fullIndex = JSON.parse(fs.readFileSync(indexPath, "utf8"));
  let surviving = fullIndex.filter(c => !culledIds.has(c.id));
  if (culledIds.size > 0) {
    fs.writeFileSync(indexPath, JSON.stringify(surviving, null, 2));
    console.log(`[render] Updated index.json — removed ${culledIds.size} legibility-culled candidate(s)`);
  }

  // Step 5 — Gallery-size cap: direction-balanced cull if survivors exceed max (D-04 / D-05)
  //
  // This runs AFTER legibility culling so no legible candidate is discarded while
  // the post-legibility count is already within (or below) the 16-cap ceiling.
  if (!SMOKE && surviving.length > TARGET_GALLERY_SIZE.max) {
    const excess = surviving.length - TARGET_GALLERY_SIZE.max;
    console.log(
      `[render] Gallery size ${surviving.length} exceeds max ${TARGET_GALLERY_SIZE.max} — ` +
        `culling ${excess} direction-balanced (D-05 floor preserved)`
    );

    for (let i = 0; i < excess; i++) {
      // Build per-direction buckets (preserve insertion order within each direction)
      const buckets = {};
      for (const c of surviving) {
        (buckets[c.direction] = buckets[c.direction] ?? []).push(c);
      }

      // Find the direction with the most candidates that is still above the floor
      const eligible = Object.entries(buckets)
        .filter(([, arr]) => arr.length > MIN_PER_DIRECTION)
        .sort(([, a], [, b]) => b.length - a.length);

      if (eligible.length === 0) {
        console.warn(
          `[render] WARN: Cannot cull further — all directions are at or below ` +
            `MIN_PER_DIRECTION (${MIN_PER_DIRECTION}).  Gallery will have ${surviving.length} candidates.`
        );
        break;
      }

      // Cull the last candidate from the largest eligible direction
      const [, targetBucket] = eligible[0];
      const toCull = targetBucket[targetBucket.length - 1];

      // Write to rejected/ with gallery-size-cull reason
      const svgSrc = path.join(CANDIDATES_DIR, `${toCull.id}.svg`);
      const rejectedSvgPath = path.join(REJECTED_DIR, `${toCull.id}.svg`);
      if (fs.existsSync(svgSrc)) fs.copyFileSync(svgSrc, rejectedSvgPath);
      const reasonText = [
        `Candidate: ${toCull.id}`,
        `Lint failures: gallery-size-cull`,
        `Culled: ${new Date().toISOString()}`,
      ].join("\n");
      fs.writeFileSync(path.join(REJECTED_DIR, `${toCull.id}.reason.txt`), reasonText + "\n");

      surviving = surviving.filter(c => c.id !== toCull.id);
      console.log(
        `[render] Gallery-size cull: ${toCull.id} (Direction ${toCull.direction}, ` +
          `bucket size was ${targetBucket.length})`
      );
    }

    // Write updated index after gallery-size cull
    fs.writeFileSync(indexPath, JSON.stringify(surviving, null, 2));
    console.log(`[render] Updated index.json — ${surviving.length} candidates after gallery-size cull`);
  }

  // Step 6 — Per-direction floor warning (D-05) — informational only, does not block
  if (!SMOKE) {
    const dirCounts = {};
    for (const c of surviving) {
      dirCounts[c.direction] = (dirCounts[c.direction] ?? 0) + 1;
    }
    for (const dir of ["A", "B", "C", "D"]) {
      const count = dirCounts[dir] ?? 0;
      if (count < MIN_PER_DIRECTION) {
        console.warn(
          `[render] WARN: Direction ${dir} has ${count} candidate(s) in final gallery ` +
            `(D-05 floor is ${MIN_PER_DIRECTION}) — ` +
            `too few legible configs at 16px; add heavier-stroke variants to fix in Phase 182`
        );
      }
    }
    const total = surviving.length;
    if (total < TARGET_GALLERY_SIZE.min) {
      console.warn(
        `[render] WARN: Final gallery has ${total} candidates — below D-04 minimum ${TARGET_GALLERY_SIZE.min}`
      );
    }
  }

  console.log(
    `[render] Done: ${rendered} rendered / ${culled16px} culled by 16px lint / ${errors} errors → ${SCREENSHOTS_DIR}`
  );
}

await main();
