/**
 * assemble-lockup.mjs — Mark + logotype lockup assembly with gap enforcement
 *
 * Pure ESM module — no CLI entry point. Exports:
 *   assembleLockup(markPathD, glyphs, config) → SVG string
 *   computeMarkBbox(markPathD) → { xMin, xMax, yMin, yMax }
 *
 * Gap enforcement:
 *   Standard mode: gap = capHeight * gapRatio (default 0.15)
 *   Direction D (markIsTypemark: true): no gap, single unified typemark SVG
 *
 * Config shape:
 *   {
 *     markWidth: number,        — width of the mark element in SVG units
 *     capHeight: number,        — cap height in font units (from getCapHeight())
 *     gapRatio?: number,        — gap as fraction of capHeight (default 0.15)
 *     fontSize?: number,        — font size used for glyph extraction (default 1000)
 *     viewboxH: number,         — viewBox height for the assembled SVG
 *     markIsTypemark?: boolean, — Direction D: mark IS the letterform, no separate logotype
 *     palette?: {               — color palette (default: Ink/Paper brand colors)
 *       ink: string,
 *       paper: string,
 *     }
 *   }
 */

// ---------------------------------------------------------------------------
// computeMarkBbox — approximate bounding box from path data
// ---------------------------------------------------------------------------

/**
 * Extract an approximate bounding box from SVG path data by scanning M/L/C/Q
 * coordinate pairs. This is a rough scan (accuracy within 5px is sufficient
 * for gap-ratio lint purposes — not a full SVG path parser).
 *
 * @param {string} pathD — SVG path data string (the `d` attribute value)
 * @returns {{ xMin: number, xMax: number, yMin: number, yMax: number }}
 */
function computeMarkBbox(pathD) {
  // Match coordinate pairs after M, L, C, Q, S, T commands
  // Handles both space-separated and comma-separated pairs
  const coordRe = /[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?/g;
  const nums = (pathD.match(coordRe) ?? []).map(Number);

  if (nums.length === 0) {
    return { xMin: 0, xMax: 0, yMin: 0, yMax: 0 };
  }

  // Treat numbers as alternating x/y pairs (approximation)
  let xMin = Infinity, xMax = -Infinity, yMin = Infinity, yMax = -Infinity;
  for (let i = 0; i < nums.length - 1; i += 2) {
    const x = nums[i];
    const y = nums[i + 1];
    if (x < xMin) xMin = x;
    if (x > xMax) xMax = x;
    if (y < yMin) yMin = y;
    if (y > yMax) yMax = y;
  }
  // Handle odd-length array: last number is unpaired, treat as x only
  if (nums.length % 2 !== 0) {
    const x = nums[nums.length - 1];
    if (x < xMin) xMin = x;
    if (x > xMax) xMax = x;
  }

  return { xMin, xMax, yMin, yMax };
}

// ---------------------------------------------------------------------------
// assembleLockup — assemble mark + logotype glyphs into a single SVG
// ---------------------------------------------------------------------------

/**
 * Assemble a mark path and extracted glyph paths into a single lockup SVG.
 *
 * @param {string} markPathD — SVG path `d` attribute value for the mark
 * @param {Array<{ char: string, d: string, advanceWidth: number }>} glyphs
 *   — from geist-spine.mjs extractGlyphs()
 * @param {{
 *   markWidth: number,
 *   capHeight: number,
 *   gapRatio?: number,
 *   fontSize?: number,
 *   viewboxH: number,
 *   markIsTypemark?: boolean,
 *   palette?: { ink: string, paper: string }
 * }} config
 * @returns {string | { svg: string, markIsTypemark: true }}
 *   In standard mode: returns the SVG string directly.
 *   In markIsTypemark mode: returns { svg, markIsTypemark: true }.
 */
function assembleLockup(markPathD, glyphs, config) {
  const {
    markWidth,
    capHeight,
    gapRatio = 0.15,
    fontSize = 1000,
    viewboxH,
    markIsTypemark = false,
    palette = { ink: "#111418", paper: "#FAFBFC" },
  } = config;

  // Direction D: mark IS the integrated typemark — no separate logotype, no gap
  if (markIsTypemark) {
    const svg =
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${markWidth} ${viewboxH}">` +
      `<path d="${markPathD}" fill="${palette.ink}"/>` +
      `</svg>`;
    return { svg, markIsTypemark: true };
  }

  // Standard mode: discrete mark + logotype with gap enforcement
  const gap = capHeight * gapRatio;
  const scale = fontSize / 1000; // glyph advanceWidths are at fontSize units

  // Build per-glyph path elements using translate() transform
  // This avoids raw path coordinate parsing; each glyph is wrapped in a <g>
  // with a translate transform, which is correct for already-extracted glyph paths.
  let xOffset = markWidth + gap;
  const glyphElements = [];

  for (let i = 0; i < glyphs.length; i++) {
    const { char, d, advanceWidth } = glyphs[i];
    const safeChar = char.replace(/[^a-zA-Z0-9]/g, "_");
    const id = `glyph-${safeChar}-${i}`;
    glyphElements.push(
      `<g transform="translate(${xOffset.toFixed(3)},0)">` +
        `<path id="${id}" d="${d}" fill="${palette.ink}"/>` +
      `</g>`
    );
    xOffset += advanceWidth * scale;
  }

  const totalW = xOffset;

  const svg = [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${totalW.toFixed(3)} ${viewboxH}">`,
    `  <path id="mark" d="${markPathD}" fill="${palette.ink}"/>`,
    ...glyphElements.map((el) => `  ${el}`),
    `</svg>`,
  ].join("\n");

  return svg;
}

// Named exports
export { assembleLockup, computeMarkBbox };
