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
 *     markWidth: number,        — width of the mark element in mark-local units
 *     markHeight: number,       — height of the mark element in mark-local units
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
 *
 * Coordinate-space contract (post-fix):
 *   - extractGlyphs(font, text, fontSize) bakes ABSOLUTE X positions into each glyph
 *     path, with the baseline at y=0 (ascenders at negative y, descenders at positive y).
 *   - assembleLockup places all glyph paths inside a SINGLE <g> translated to
 *     (markScaledWidth + gap, BASELINE) so ascenders/descenders land in the viewBox.
 *   - The mark is scaled from its local unit space (markHeight ≈ 40) to cap height
 *     (capHeight ≈ 714–730) and placed at the top-left of the lockup sitting on BASELINE.
 *   - No per-glyph translate loops — the glyph paths already carry their x layout.
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
 * Coordinate-space design:
 *   extractGlyphs() bakes absolute X positions into each path (x accumulates over
 *   advance widths). Baseline is at y=0; ascenders are at negative Y.
 *
 *   To render correctly inside a viewBox="0 0 W H":
 *   1. The mark is scaled: s = capHeight / markHeight, so it occupies one cap-height.
 *      It is translated to (0, BASELINE - capHeight) so it sits atop the baseline.
 *   2. All glyph paths are placed inside ONE <g transform="translate(markScaledWidth+gap, BASELINE)">.
 *      The single translate moves the baseline from y=0 to y=BASELINE, pushing
 *      ascenders (negative-y ink) into positive viewBox space.
 *   3. BASELINE = capHeight * 1.1 inside viewboxH = capHeight * 1.4
 *      → 0.1×capHeight headroom above cap top, 0.3×capHeight below baseline for
 *        descenders and breathing room (Geist "accrue" has no descenders).
 *   No per-glyph translate loops — each path already carries its x layout from extractGlyphs.
 *
 * @param {string} markPathD — SVG path `d` attribute value for the mark
 * @param {Array<{ char: string, d: string, advanceWidth: number }>} glyphs
 *   — from geist-spine.mjs extractGlyphs()
 * @param {{
 *   markWidth: number,
 *   markHeight: number,
 *   capHeight: number,
 *   gapRatio?: number,
 *   fontSize?: number,
 *   viewboxH: number,
 *   markIsTypemark?: boolean,
 *   accentPathD?: string,
 *   palette?: { ink: string, paper: string, accentFill?: string }
 * }} config
 * @returns {string | { svg: string, markIsTypemark: true }}
 *   In standard mode: returns the SVG string directly.
 *   In markIsTypemark mode: returns { svg, markIsTypemark: true }.
 */
function assembleLockup(markPathD, glyphs, config) {
  const {
    markWidth,
    markHeight,
    capHeight,
    gapRatio = 0.15,
    viewboxH,
    markIsTypemark = false,
    accentPathD,
    palette = { ink: "#181818", paper: "#FAFBFC" },
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
  //
  // BASELINE: where the text baseline sits in viewBox coords (y-down).
  // We use 1.1× cap height as baseline → 0.1×capH headroom above caps,
  // 0.3×capH below (descenders + breathing room).
  const BASELINE = capHeight * 1.1;

  // Mark scale: fit mark to exactly one cap-height (top sits at BASELINE - capHeight).
  // markHeight is the mark's local coordinate height (e.g. ~40 for Direction A).
  const effectiveMarkHeight = (markHeight != null && markHeight > 0) ? markHeight : capHeight;
  const s = capHeight / effectiveMarkHeight;

  // Scaled mark dimensions in viewBox coordinate space
  const markScaledW = markWidth * s;

  // Gap in font units between mark right edge and logotype left edge
  const gap = capHeight * gapRatio;

  // Total width = scaled-mark width + gap + glyph run width (glyphs already at fontSize units)
  const glyphRunWidth = glyphs.reduce((sum, g) => sum + g.advanceWidth, 0);
  const totalW = markScaledW + gap + glyphRunWidth;

  // Mark: translate so it sits on the baseline (top at BASELINE - capHeight)
  // mark-local y=0 is the mark's top edge, so translate(0, BASELINE - capHeight)
  // then scale(s) to expand to cap height
  const markTx = (0).toFixed(3);
  const markTy = (BASELINE - capHeight).toFixed(3);

  // Single group for all glyphs: translate baseline from y=0 to y=BASELINE,
  // and shift horizontally past the scaled mark + gap.
  const glyphTx = (markScaledW + gap).toFixed(3);
  const glyphTy = BASELINE.toFixed(3);

  // Glyph paths concatenated (no per-glyph wrapping needed — x is already baked in)
  const glyphPaths = glyphs
    .map((g, i) => {
      const safeChar = g.char.replace(/[^a-zA-Z0-9]/g, "_");
      return `    <path id="glyph-${safeChar}-${i}" d="${g.d}" fill="${palette.ink}"/>`;
    })
    .join("\n");

  const svg = [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${totalW.toFixed(3)} ${viewboxH}">`,
    `  <g id="mark" transform="translate(${markTx},${markTy}) scale(${s.toFixed(6)})">`,
    `    <path d="${markPathD}" fill="${palette.ink}"/>`,
    (accentPathD && palette.accentFill) ? `    <path d="${accentPathD}" fill="${palette.accentFill}"/>` : "",
    `  </g>`,
    `  <g id="logotype" transform="translate(${glyphTx},${glyphTy})">`,
    glyphPaths,
    `  </g>`,
    `</svg>`,
  ].join("\n");

  return svg;
}

// Named exports
export { assembleLockup, computeMarkBbox };
