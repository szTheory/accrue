/**
 * geist-spine.mjs — Geist font loading + per-glyph path extraction
 *
 * Pure ESM module. Exports:
 *   loadGeistFont()     — async, returns an opentype Font object
 *   extractGlyphs()     — sync, returns per-character path data
 *   getCapHeight()      — sync, returns os2.sCapHeight (reference for gap-ratio lint)
 *
 * Usage (smoke test):
 *   node harness/geist-spine.mjs --test
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import opentype from "opentype.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Font loading helpers
// ---------------------------------------------------------------------------

async function loadFromWoff2() {
  // Dynamic import — wawoff2 uses a WASM module internally and requires async init
  const wawoff2Module = (await import("wawoff2")).default;
  const woff2Path = path.resolve(
    __dirname,
    "../../../../accrue_admin/priv/static/fonts/geist-sans-vf.woff2"
  );
  if (!fs.existsSync(woff2Path)) {
    throw new Error(
      `[geist-spine] Fallback woff2 not found at: ${woff2Path}\n` +
        "Ensure accrue_admin/priv/static/fonts/geist-sans-vf.woff2 exists."
    );
  }
  const woff2Buf = fs.readFileSync(woff2Path);
  const decompressed = await wawoff2Module.decompress(woff2Buf);
  // wawoff2 returns a Uint8Array whose .buffer may be a shared WASM memory region.
  // opentype.parse() requires a plain ArrayBuffer — copy to avoid signature errors.
  const ab = new ArrayBuffer(decompressed.length);
  new Uint8Array(ab).set(decompressed);
  return opentype.parse(ab);
}

/**
 * Load the Geist Sans Regular font.
 *
 * Primary: geist npm package TTF (static, non-variable — reliable glyph outlines).
 *   The package ships "Geist-Regular.ttf" under dist/fonts/geist-sans/.
 *   Note: require.resolve() cannot reach this path because the geist package.json
 *   exports map restricts resolution to declared exports only. We use path.join
 *   from __dirname to node_modules/geist instead.
 *
 * Fallback: wawoff2 decompress of the in-repo variable WOFF2.
 *
 * @returns {Promise<import("opentype.js").Font>}
 */
export async function loadGeistFont() {
  // Primary: direct path construction — avoids the geist exports map restriction
  const ttfPath = path.join(
    __dirname,
    "node_modules/geist/dist/fonts/geist-sans/Geist-Regular.ttf"
  );
  try {
    if (!fs.existsSync(ttfPath)) {
      throw new Error(`TTF not found at: ${ttfPath}`);
    }
    const buf = fs.readFileSync(ttfPath);
    return opentype.parse(buf.buffer);
  } catch {
    console.warn("[geist-spine] geist npm TTF not found — falling back to wawoff2");
    return loadFromWoff2();
  }
}

// ---------------------------------------------------------------------------
// Glyph extraction
// ---------------------------------------------------------------------------

/**
 * Extract per-character glyph path data for each character in text.
 *
 * CRITICAL: flipY: false is mandatory. font.getPath() / glyph.getPath()
 * already performs the Cartesian→SVG y-axis flip internally (opentype.js Issue #724).
 * Passing flipY: true (the default for toPathData) would double-flip the coordinates,
 * rendering all letterforms upside-down in SVG viewBox space.
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

    // flipY: false — do NOT pass true (default), as getPath already flips y
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
// Cap height helper (reference for gap-ratio lint)
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
// Smoke test (--test flag)
// ---------------------------------------------------------------------------

if (process.argv.includes("--test")) {
  const font = await loadGeistFont();
  const glyphs = extractGlyphs(font, "accrue");

  if (glyphs.length !== 6) {
    console.error(
      `[geist-spine] smoke: FAIL — expected 6 glyphs for "accrue", got ${glyphs.length}` +
        "\n  Possible ligature substitution — check font's GSUB table."
    );
    process.exit(1);
  }

  console.log("[geist-spine] smoke: OK");
  process.exit(0);
}
