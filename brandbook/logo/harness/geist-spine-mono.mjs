/**
 * geist-spine-mono.mjs — Geist Mono font loading + per-glyph path extraction
 *
 * Parallel to geist-spine.mjs (from Phase 181) but targets Geist Mono Regular (weight 400)
 * instead of Geist Sans Regular. Used for the subtitle variant (D-07).
 *
 * Pure ESM module. Exports:
 *   loadGeistMonoFont()  — async, returns an opentype Font object
 *   extractGlyphs()      — sync, returns per-character path data
 *   getCapHeight()       — sync, returns os2.sCapHeight (reference for subtitle sizing)
 *
 * Usage (smoke test):
 *   node brandbook/logo/harness/geist-spine-mono.mjs --test
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import opentype from "opentype.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Font loading helpers
// ---------------------------------------------------------------------------

/**
 * Load the Geist Mono Regular font (weight 400).
 *
 * Primary: geist npm package TTF (static, non-variable — reliable glyph outlines).
 *   The package ships "GeistMono-Regular.ttf" under dist/fonts/geist-mono/.
 *   Note: require.resolve() cannot reach this path because the geist package.json
 *   exports map restricts resolution to declared exports only. We use path.join
 *   from __dirname to node_modules/geist instead.
 *
 * @returns {Promise<import("opentype.js").Font>}
 */
export async function loadGeistMonoFont() {
  // Primary: direct path construction — avoids the geist exports map restriction
  // Geist Mono Regular is at: node_modules/geist/dist/fonts/geist-mono/GeistMono-Regular.ttf
  const ttfPath = path.join(
    __dirname,
    "node_modules/geist/dist/fonts/geist-mono/GeistMono-Regular.ttf"
  );
  try {
    if (!fs.existsSync(ttfPath)) {
      throw new Error(`TTF not found at: ${ttfPath}`);
    }
    const buf = fs.readFileSync(ttfPath);
    return opentype.parse(buf.buffer);
  } catch (err) {
    throw new Error(
      `[geist-spine-mono] Failed to load Geist Mono Regular font: ${err.message}`
    );
  }
}

// ---------------------------------------------------------------------------
// Glyph extraction
// ---------------------------------------------------------------------------

/**
 * Extract per-character glyph path data for each character in text.
 *
 * CRITICAL: flipY: false is MANDATORY.
 *
 * font.getPath() / glyph.getPath() already performs the Cartesian→SVG y-axis flip
 * internally (opentype.js Issue #724). Passing flipY: true (the default for toPathData)
 * would double-flip the coordinates, rendering all letterforms upside-down in SVG
 * viewBox space. This was the root cause of the Phase 181 coordinate-space bug that
 * shipped a broken gallery — do not reintroduce it.
 *
 * @param {import("opentype.js").Font} font
 * @param {string} text
 * @param {number} [fontSize=1000]
 * @returns {Array<{char: string, d: string, advanceWidth: number, xMin: number, yMin: number, xMax: number, yMax: number}>}
 */
export function extractGlyphs(font, text, fontSize = 1000) {
  const glyphs = [];
  let x = 0;

  for (const char of text) {
    const glyph = font.charToGlyph(char);
    const glyphPath = glyph.getPath(x, 0, fontSize);
    const bb = glyphPath.getBoundingBox();

    // flipY: false — MANDATORY, do NOT change to true. getPath already flips y.
    const d = glyphPath.toPathData({ decimalPlaces: 3, flipY: false });
    const advanceWidth =
      (glyph.advanceWidth / font.unitsPerEm) * fontSize;

    glyphs.push({
      char,
      d,
      advanceWidth,
      xMin: bb.x1,
      yMin: bb.y1,
      xMax: bb.x2,
      yMax: bb.y2,
    });

    x += advanceWidth;
  }

  return glyphs;
}

// ---------------------------------------------------------------------------
// Cap height helper
// ---------------------------------------------------------------------------

/**
 * Return the cap height in font units (at unitsPerEm=1000 this is the absolute value).
 * Falls back to 700 if os2 table is absent.
 *
 * @param {import("opentype.js").Font} font
 * @returns {number}
 */
export function getCapHeight(font) {
  return font.tables.os2?.sCapHeight ?? 700;
}

// ---------------------------------------------------------------------------
// Smoke test (--test flag) + isMain guard
// ---------------------------------------------------------------------------

async function main() {
  const font = await loadGeistMonoFont();
  const testText = "Billing for Elixir apps";
  const glyphs = extractGlyphs(font, testText);

  if (glyphs.length === 0) {
    console.error(
      `[geist-spine-mono] smoke: FAIL — expected > 0 glyphs for "${testText}", got 0`
    );
    process.exit(1);
  }

  // Sanity check: each character in testText produces exactly one glyph entry
  // (including space characters which return the space glyph)
  if (glyphs.length !== testText.length) {
    console.error(
      `[geist-spine-mono] smoke: FAIL — expected ${testText.length} glyphs for "${testText}", got ${glyphs.length}`
    );
    process.exit(1);
  }

  // Verify cap height is reasonable (Geist Mono Regular sCapHeight ≈ 700–750)
  const capHeight = getCapHeight(font);
  if (capHeight <= 0) {
    console.error(
      `[geist-spine-mono] smoke: FAIL — getCapHeight returned ${capHeight} (expected > 0)`
    );
    process.exit(1);
  }

  console.log("[geist-spine-mono] smoke: OK");
  process.exit(0);
}

// isMain guard — prevents pipeline execution when imported as a module
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--test")) {
    main().catch((err) => {
      console.error("[geist-spine-mono] FATAL:", err);
      process.exit(1);
    });
  }
}
