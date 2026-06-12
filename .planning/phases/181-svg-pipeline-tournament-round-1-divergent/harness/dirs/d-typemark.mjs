/**
 * d-typemark.mjs — Direction D: path surgery integrated typemark generator
 *
 * Motif: "accrue" as a fully-integrated custom typemark where the logo IS the
 * letterform — no separate geometric mark to the left. Bespoke Geist glyph-
 * outline surgery is applied to one or more letterforms:
 *
 *   D1 — cc echoed layers: duplicate the first c path shifted/offset to create
 *        a layered shadow/echo effect behind the cc pair.
 *   D2 — stepped e crossbar: overlay a stepped mask on the e's crossbar,
 *        creating a staircase notch profile via SVG masking.
 *   D3 — u filling interval: the u counter reads as a vessel; add an interior
 *        fill element creating a liquid/gauge metaphor at partial fill height.
 *   D4 — all three motifs combined: cc echo + stepped-e crossbar +
 *        u filling interval applied simultaneously.
 *
 * All configs have skipGapRatio: true — Direction D typemarks are fully
 * integrated (no spatial gap between mark and type; they are one element).
 *
 * Exports:
 *   CONFIGS  — array of 4 candidate configurations (D1–D4)
 *   generate(config, font) → { fullSvg, markIsTypemark: true, markWidth,
 *                               markHeight, skipGapRatio: true }
 *
 * Color constraint (Wave 2 finding):
 *   #111418 (Ink) has HSV saturation ~0.29 — exceeds the 0.15 monochrome lint
 *   threshold. Use #181818 (sat=0, pure grey) for all fill geometry. Overlays
 *   may use opacity on #181818 (greyscale-mappable). Fog #E9EEF2 (sat≈0.06)
 *   is permitted for interior fill accents.
 */

import { extractGlyphs, getCapHeight } from "../geist-spine.mjs";

// ---------------------------------------------------------------------------
// CONFIGS — 4 candidate configurations
// ---------------------------------------------------------------------------

export const CONFIGS = [
  {
    id: "D1",
    motif: "cc-echo",
    markIsTypemark: true,
    echoOffset: { dx: 4, dy: 4 },
    echoOpacity: 0.35,
    skipGapRatio: true,
    rationale:
      "cc echoed layers: the double-c pair gains a shifted shadow echo — depth-through-layering signals the ledger/audit metaphor",
  },
  {
    id: "D2",
    motif: "stepped-e-crossbar",
    markIsTypemark: true,
    stepDepth: 28,
    stepWidth: 60,
    stepOffset: 0.45,
    skipGapRatio: true,
    rationale:
      "stepped e crossbar: the e's horizontal crossbar carries a staircase notch — interval and state-transition imagery built into the letterform",
  },
  {
    id: "D3",
    motif: "u-filling-interval",
    markIsTypemark: true,
    fillLevel: 0.55,
    fillColor: "#E9EEF2",
    skipGapRatio: true,
    rationale:
      "u filling interval: the u counter reads as a vessel at 55% fill — accumulation/capacity metaphor without adding any separate mark element",
  },
  {
    id: "D4",
    motif: "all-three",
    markIsTypemark: true,
    echoOffset: { dx: 3, dy: 3 },
    echoOpacity: 0.30,
    stepDepth: 24,
    stepWidth: 56,
    stepOffset: 0.45,
    fillLevel: 0.50,
    fillColor: "#E9EEF2",
    skipGapRatio: true,
    rationale:
      "all three motifs combined: cc echo + stepped e crossbar + u filling interval — maximum brand-motif density in a single typemark",
  },
];

// ---------------------------------------------------------------------------
// SVG dimension constants (at fontSize=1000)
// ---------------------------------------------------------------------------

const FONT_SIZE = 1000;
// Full viewBox height: cap height (≈730) + descender depth below baseline (≈270)
// At fontSize=1000, baseline sits at y=730 (since glyph paths use y-down SVG coords
// and getPath() was called with y=0 which maps the baseline to y=capHeight).
// We use 1100 as a safe total height covering ascenders + descenders.
const VIEW_H = 1100;

// ---------------------------------------------------------------------------
// generate(config, font) — produce a full integrated typemark SVG
// ---------------------------------------------------------------------------

/**
 * Produce a complete <svg> string with all 6 "accrue" Geist glyphs and the
 * requested motif modifications applied.
 *
 * @param {object} config   — one of CONFIGS
 * @param {import("opentype.js").Font} font — pre-loaded font from loadGeistFont()
 * @returns {{ fullSvg: string, markIsTypemark: true, markWidth: number,
 *             markHeight: number, skipGapRatio: true }}
 */
export function generate(config, font) {
  const glyphs = extractGlyphs(font, "accrue", FONT_SIZE);
  const capHeight = getCapHeight(font);

  // Total width = sum of all advance widths
  const totalWidth = glyphs.reduce((sum, g) => sum + g.advanceWidth, 0);
  const totalHeight = VIEW_H;

  // Build the SVG inner elements based on the motif config
  const innerElements = buildMotifElements(config, glyphs, capHeight);

  const fullSvg =
    `<svg xmlns="http://www.w3.org/2000/svg" ` +
    `viewBox="0 0 ${totalWidth.toFixed(3)} ${totalHeight}">\n` +
    innerElements +
    `\n</svg>`;

  // T-181-08: assert no NaN in generated SVG
  if (fullSvg.includes("NaN")) {
    throw new Error(
      `[d-typemark] generate() produced NaN in SVG for config ${config.id}`
    );
  }

  return {
    fullSvg,
    markIsTypemark: true,
    markWidth: parseFloat(totalWidth.toFixed(3)),
    markHeight: totalHeight,
    skipGapRatio: true,
  };
}

// ---------------------------------------------------------------------------
// Motif builders
// ---------------------------------------------------------------------------

/**
 * Dispatch to the appropriate motif builder based on config.motif.
 *
 * @param {object} config
 * @param {Array} glyphs — from extractGlyphs('accrue', 1000)
 * @param {number} capHeight
 * @returns {string} — SVG element string (inner content of <svg>)
 */
function buildMotifElements(config, glyphs, capHeight) {
  switch (config.motif) {
    case "cc-echo":
      return buildCcEcho(config, glyphs);
    case "stepped-e-crossbar":
      return buildSteppedECrossbar(config, glyphs, capHeight);
    case "u-filling-interval":
      return buildUFillingInterval(config, glyphs, capHeight);
    case "all-three":
      return buildAllThree(config, glyphs, capHeight);
    default:
      throw new Error(`[d-typemark] Unknown motif: ${config.motif}`);
  }
}

// ---------------------------------------------------------------------------
// D1: cc echoed layers
// ---------------------------------------------------------------------------

/**
 * "accrue" with the first c (index 1) echoed behind as a shifted, semi-opaque
 * duplicate. The echo is drawn first (lower z-order), then all 6 base glyphs
 * on top. Echo uses opacity on #181818 — greyscale-mappable, passes lint.
 *
 * Glyph indices in "accrue":
 *   0 = a, 1 = c (first), 2 = c (second), 3 = r, 4 = u, 5 = e
 */
function buildCcEcho(config, glyphs) {
  const { echoOffset, echoOpacity } = config;
  const { dx, dy } = echoOffset;

  // Echo: the first c (index 1) shifted by (dx, dy), rendered at reduced opacity
  // The echo is placed in a <g> with opacity applied to the group
  const firstC = glyphs[1];
  const secondC = glyphs[2];

  // We echo both c glyphs (the cc pair) for a more pronounced layering effect.
  // Each echo path already has absolute coordinates baked in (from extractGlyphs).
  // We use a <g transform="translate(dx, dy)"> wrapping the cc pair echo paths.
  const echoGroup =
    `  <g opacity="${echoOpacity}" transform="translate(${dx},${dy})">\n` +
    `    <path d="${firstC.d}" fill="#181818"/>\n` +
    `    <path d="${secondC.d}" fill="#181818"/>\n` +
    `  </g>`;

  // Base glyphs: all 6 "accrue" letterforms on top at full opacity
  const baseGlyphs = glyphs
    .map((g) => `  <path d="${g.d}" fill="#181818"/>`)
    .join("\n");

  return echoGroup + "\n" + baseGlyphs;
}

// ---------------------------------------------------------------------------
// D2: stepped e crossbar
// ---------------------------------------------------------------------------

/**
 * "accrue" with the e (index 5) crossbar notched into a stepped staircase
 * profile. Implemented via SVG clipPath: the e glyph is rendered normally,
 * then an overlay stepped shape in Paper (#FAFBFC) cuts a staircase notch
 * into the crossbar region.
 *
 * The Geist 'e' crossbar sits at roughly the midpoint of the cap height.
 * At fontSize=1000 with cap height ≈730, the baseline is at y=730 in SVG
 * space (y-down). The e's crossbar is roughly at y ≈ 400–460 (mid-x-height).
 *
 * Motif knobs:
 *   stepDepth  — vertical height of the notch (units in SVG coordinate space)
 *   stepWidth  — horizontal width of the notch (units in SVG coordinate space)
 *   stepOffset — fraction (0–1) of the glyph's advance width where notch sits
 */
function buildSteppedECrossbar(config, glyphs, capHeight) {
  const { stepDepth, stepWidth, stepOffset } = config;

  // e glyph is at index 5 in "accrue"
  const eGlyph = glyphs[5];

  // Estimate crossbar Y position: e's crossbar is roughly at 55% of cap height
  // from the bottom of the glyph, i.e. at y ≈ (capHeight - capHeight * 0.55)
  // in SVG y-down space. Since getPath() was called with y=0 (baseline at 0),
  // and font.getPath() flips coords so that y increases downward with baseline
  // at 0 → ascenders at negative y... wait — actually with extractGlyphs using
  // glyph.getPath(x, 0, fontSize), the glyph is placed with the baseline at y=0.
  // In SVG y-down, ascenders have NEGATIVE y (above baseline) and descenders
  // have POSITIVE y. So the e's x-height ≈ 0.72 × capHeight ≈ 526 units, and
  // the crossbar sits near y ≈ -(xHeight / 2) ≈ -263 in glyph space.
  //
  // For the overlay mask, we need to position the stepped shape over the
  // crossbar. We estimate:
  //   crossbarY ≈ -(capHeight * 0.35)   (slightly above x-height midpoint)
  //   crossbarH ≈ capHeight * 0.05      (crossbar is thin — ~35–50 units)
  //
  // The step notch is a small rectangle cut into the crossbar, shaped as a
  // staircase: two horizontal segments connected by a vertical drop.
  const xHeight = capHeight * 0.72; // approximate x-height in font units
  const crossbarY = -(xHeight * 0.48); // crossbar centre in glyph-local y
  const crossbarH = capHeight * 0.05; // crossbar height (thin bar)

  // Notch horizontal position: stepOffset × e advance width from the glyph's
  // leftmost edge. The e glyph's x start comes from its bounding box xMin.
  const eXMin = eGlyph.xMin;
  const eWidth = eGlyph.xMax - eGlyph.xMin;
  const notchX = eXMin + eWidth * stepOffset - stepWidth / 2;
  const notchY = crossbarY - crossbarH / 2;

  // Stepped mask shape: a filled Paper (#FAFBFC) staircase overlay.
  // Shape: top-left at (notchX, notchY), steps down by (stepDepth/2),
  // then continues right for another (stepWidth/2).
  //
  //   ┌────────┐
  //   │ step 1 │
  //            └────────┐
  //                     │ step 2
  //                     └────────
  //
  const halfW = (stepWidth / 2).toFixed(3);
  const halfD = (stepDepth / 2).toFixed(3);
  const nx = notchX.toFixed(3);
  const ny = notchY.toFixed(3);
  const totalStepH = (stepDepth + crossbarH).toFixed(3);

  // Staircase path that covers the crossbar with a stepped notch:
  // Two rectangles side by side, vertically offset by stepDepth/2
  const stepPath =
    `M ${nx},${ny}` +
    ` h ${halfW}` +
    ` v ${halfD}` +
    ` h ${halfW}` +
    ` v ${totalStepH}` +
    ` h ${(-stepWidth).toFixed(3)}` +
    ` v ${(-totalStepH).toFixed(3)}` +
    ` Z`;

  // Base glyphs
  const baseGlyphs = glyphs
    .map((g) => `  <path d="${g.d}" fill="#181818"/>`)
    .join("\n");

  // Overlay the stepped mask in Paper colour over the e's crossbar
  const stepOverlay = `  <path d="${stepPath}" fill="#FAFBFC"/>`;

  return baseGlyphs + "\n" + stepOverlay;
}

// ---------------------------------------------------------------------------
// D3: u filling interval
// ---------------------------------------------------------------------------

/**
 * "accrue" with the u (index 4) counter showing a partial fill — a liquid/
 * gauge metaphor. Rendered as: base u glyph in #181818, then a Fog (#E9EEF2)
 * filled rectangle clipped to the u's counter interior via clipPath.
 *
 * The fill level (0–1) controls how much of the counter height is "filled"
 * from the bottom up.
 *
 * Fog #E9EEF2: R=233, G=238, B=242 → max=242, min=233, sat=9/242≈0.037 < 0.15
 * — passes monochrome lint (T-181-09 accepted: deliberate design choice).
 */
function buildUFillingInterval(config, glyphs, capHeight) {
  const { fillLevel, fillColor } = config;

  // u glyph is at index 4 in "accrue"
  const uGlyph = glyphs[4];

  // u counter bounds (approx from glyph metrics):
  // The u is an open bowl — the counter (interior white space) sits between
  // the two vertical strokes. In SVG y-down with baseline at y=0:
  //   counter top ≈ y = -(capHeight * 0.72)  (top of x-height)
  //   counter bottom ≈ y = 0                  (baseline)
  //   counter left/right: inset from glyph xMin/xMax by stroke width ≈ 8% each side
  //
  // We approximate: fill rect from (uXMin + inset, fillTop) to (uXMax - inset, 0)
  const inset = (uGlyph.xMax - uGlyph.xMin) * 0.18; // stroke-width inset
  const xHeight = capHeight * 0.72;
  const counterTop = -xHeight; // top of the counter in SVG coords (y-down, baseline=0)
  const counterBottom = 0; // baseline
  const counterHeight = counterBottom - counterTop; // positive

  // Fill: from the bottom up by fillLevel fraction
  const fillHeight = counterHeight * fillLevel;
  const fillRectY = counterBottom - fillHeight; // top of the fill rectangle

  const clipId = `d3-u-clip-${uGlyph.char}`;
  const fillX = (uGlyph.xMin + inset).toFixed(3);
  const fillW = (uGlyph.xMax - uGlyph.xMin - 2 * inset).toFixed(3);
  const fillY = fillRectY.toFixed(3);
  const fillH = fillHeight.toFixed(3);

  // Use clipPath to constrain the fill to the u's counter area
  const defs =
    `  <defs>\n` +
    `    <clipPath id="${clipId}">\n` +
    `      <rect x="${fillX}" y="${fillY}" width="${fillW}" height="${fillH}"/>\n` +
    `    </clipPath>\n` +
    `  </defs>`;

  // Base glyphs
  const baseGlyphs = glyphs
    .map((g) => `  <path d="${g.d}" fill="#181818"/>`)
    .join("\n");

  // Fill overlay: the fill rect clipped by the same rect (simple overlay)
  // We overlay the fill as a plain rect without clipPath because the u path
  // itself (fill=#181818) will overdraw the counter edges. The fill rect
  // sits behind all glyphs except the u — but since the u is filled #181818
  // which overwrites the fill, we render the fill AFTER the base glyphs but
  // use a separate <path> with a pointer-events:none group.
  //
  // Better approach: render all glyphs EXCEPT u, then the fill rect, then u on top.
  // The u glyph uses a compound path (outer bowl + inner counter hole via even-odd rule).
  // We rely on the SVG fill-rule="evenodd" so the counter is transparent, letting
  // the fill rect show through.
  const glyphsExceptU = glyphs
    .filter((_, i) => i !== 4)
    .map((g) => `  <path d="${g.d}" fill="#181818"/>`)
    .join("\n");

  const uGlyphEvenOdd = `  <path d="${uGlyph.d}" fill="#181818" fill-rule="evenodd"/>`;
  const fillRect =
    `  <rect x="${fillX}" y="${fillY}" width="${fillW}" height="${fillH}" fill="${fillColor}"/>`;

  return defs + "\n" + glyphsExceptU + "\n" + fillRect + "\n" + uGlyphEvenOdd;
}

// ---------------------------------------------------------------------------
// D4: all three motifs combined
// ---------------------------------------------------------------------------

/**
 * Apply cc echo + stepped e crossbar + u filling interval simultaneously.
 * Renders in layers: echo → fill → all base glyphs (u with evenodd) → step overlay.
 */
function buildAllThree(config, glyphs, capHeight) {
  const {
    echoOffset,
    echoOpacity,
    stepDepth,
    stepWidth,
    stepOffset,
    fillLevel,
    fillColor,
  } = config;

  // cc echo (same as D1)
  const { dx, dy } = echoOffset;
  const firstC = glyphs[1];
  const secondC = glyphs[2];
  const echoGroup =
    `  <g opacity="${echoOpacity}" transform="translate(${dx},${dy})">\n` +
    `    <path d="${firstC.d}" fill="#181818"/>\n` +
    `    <path d="${secondC.d}" fill="#181818"/>\n` +
    `  </g>`;

  // u fill (similar to D3 but inline — reuse same geometry)
  const uGlyph = glyphs[4];
  const inset = (uGlyph.xMax - uGlyph.xMin) * 0.18;
  const xHeight = capHeight * 0.72;
  const counterTop = -xHeight;
  const counterBottom = 0;
  const counterHeight = counterBottom - counterTop;
  const fillHeight = counterHeight * fillLevel;
  const fillRectY = counterBottom - fillHeight;
  const fillX = (uGlyph.xMin + inset).toFixed(3);
  const fillW = (uGlyph.xMax - uGlyph.xMin - 2 * inset).toFixed(3);
  const fillY = fillRectY.toFixed(3);
  const fillH = fillHeight.toFixed(3);
  const fillRect =
    `  <rect x="${fillX}" y="${fillY}" width="${fillW}" height="${fillH}" fill="${fillColor}"/>`;

  // Base glyphs (u with evenodd so its counter is transparent to show fill)
  const glyphsExceptU = glyphs
    .filter((_, i) => i !== 4)
    .map((g) => `  <path d="${g.d}" fill="#181818"/>`)
    .join("\n");
  const uGlyphEvenOdd = `  <path d="${uGlyph.d}" fill="#181818" fill-rule="evenodd"/>`;

  // stepped e crossbar overlay (same as D2)
  const eGlyph = glyphs[5];
  const crossbarY = -(xHeight * 0.48);
  const crossbarH = capHeight * 0.05;
  const eXMin = eGlyph.xMin;
  const eWidth = eGlyph.xMax - eGlyph.xMin;
  const notchX = eXMin + eWidth * stepOffset - stepWidth / 2;
  const notchY = crossbarY - crossbarH / 2;
  const halfW = (stepWidth / 2).toFixed(3);
  const halfD = (stepDepth / 2).toFixed(3);
  const nx = notchX.toFixed(3);
  const ny = notchY.toFixed(3);
  const totalStepH = (stepDepth + crossbarH).toFixed(3);
  const stepPath =
    `M ${nx},${ny}` +
    ` h ${halfW}` +
    ` v ${halfD}` +
    ` h ${halfW}` +
    ` v ${totalStepH}` +
    ` h ${(-stepWidth).toFixed(3)}` +
    ` v ${(-totalStepH).toFixed(3)}` +
    ` Z`;
  const stepOverlay = `  <path d="${stepPath}" fill="#FAFBFC"/>`;

  return (
    echoGroup +
    "\n" +
    fillRect +
    "\n" +
    glyphsExceptU +
    "\n" +
    uGlyphEvenOdd +
    "\n" +
    stepOverlay
  );
}
