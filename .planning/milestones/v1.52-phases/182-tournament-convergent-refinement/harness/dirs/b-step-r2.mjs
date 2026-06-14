/**
 * b-step-r2.mjs — Round 2 candidate configs for Direction B (stepped intervals)
 *
 * Round 2 builds on the Round 1 verdict: B4 (primary) + B1 (runner-up) locked as
 * winners. This module defines 7 refinement candidates:
 *   R2-1 / R2-2 / R2-3 / R2-4  — Ink monochrome baselines (exploration variants)
 *   R2-5                         — Full Moss (#5E9E84) mark
 *   R2-6 / R2-7                  — Two-tone: Ink base + Moss accent on top step
 *
 * Exports:
 *   R2_CONFIGS  — array of 7 candidate knob configurations (R2-1..R2-7)
 *   generate(config) → { markPathD, accentPathD?, markWidth, markHeight }
 *
 * Self-contained — does NOT import from b-step.mjs.
 */

// ---------------------------------------------------------------------------
// R2_CONFIGS — 7 candidate parameter sets
// ---------------------------------------------------------------------------

export const R2_CONFIGS = [
  {
    id: "R2-1",
    steps: 6,
    stepHeight: 0.18,
    stepWidth: 0.18,
    curvature: 0,
    colorTreatment: "ink",
    monoMap: {},
    accentStep: false,
    rationale: "B4 exact — ink baseline; user primary pick from Round 1",
  },
  {
    id: "R2-2",
    steps: 5,
    stepHeight: 0.22,
    stepWidth: 0.22,
    curvature: 0,
    colorTreatment: "ink",
    monoMap: {},
    accentStep: false,
    rationale: "B4 chunkier 5-step — 16px weakness fix; wider bars reduce column-merge at favicon scale",
  },
  {
    id: "R2-3",
    steps: 4,
    stepHeight: 0.22,
    stepWidth: 0.26,
    curvature: 0,
    colorTreatment: "ink",
    monoMap: {},
    accentStep: false,
    rationale: "4-wide steps — B1 step-count with B4 crispness; no rounding",
  },
  {
    id: "R2-4",
    steps: 4,
    stepHeight: 0.25,
    stepWidth: 0.25,
    curvature: 0.05,
    colorTreatment: "ink",
    monoMap: {},
    accentStep: false,
    rationale: "B1 exact — runner-up baseline; strongest 16px favicon in Round 1 self-review",
  },
  {
    id: "R2-5",
    steps: 5,
    stepHeight: 0.22,
    stepWidth: 0.22,
    curvature: 0,
    colorTreatment: "moss",
    monoMap: { "#5E9E84": "#818181" },
    accentStep: false,
    rationale: "B4 chunkier 5-step with full Moss mark — primary color test; may fail 16px on paper-light (BRAND-DNA: Moss large-text only on light surfaces)",
  },
  {
    id: "R2-6",
    steps: 5,
    stepHeight: 0.22,
    stepWidth: 0.22,
    curvature: 0,
    colorTreatment: "two-tone",
    monoMap: { "#5E9E84": "#818181" },
    accentStep: true,
    rationale: "B4 chunkier 5-step with Ink base + Moss accent on top step — subtler color; passes 16px on paper-light (base fill is #181818)",
  },
  {
    id: "R2-7",
    steps: 4,
    stepHeight: 0.25,
    stepWidth: 0.25,
    curvature: 0.05,
    colorTreatment: "two-tone",
    monoMap: { "#5E9E84": "#818181" },
    accentStep: true,
    rationale: "B1 exact with Ink base + Moss accent on top step — B1 robustness at all sizes, with brand-color accent",
  },
];

// ---------------------------------------------------------------------------
// generate(config) — produce SVG path data for one stepped-interval mark
// ---------------------------------------------------------------------------

/**
 * Build a single combined SVG path string for the stepped-interval mark.
 *
 * Steps ascend left-to-right. Each step is a rectangle positioned so its
 * base aligns with the top of the previous step, forming a staircase silhouette.
 * The mark fills a bounding box of approx markWidth × markHeight.
 *
 * Coordinate space: 0,0 = top-left. markHeight ≈ 40 units at fontSize=1000.
 *
 * When config.accentStep === true, the topmost step (rightmost, index steps-1)
 * is returned separately as accentPathD — for Moss two-tone overlays.
 *
 * @param {{
 *   id: string,
 *   steps: number,
 *   stepHeight: number,
 *   stepWidth: number,
 *   curvature: number,
 *   accentStep?: boolean
 * }} config
 * @returns {{ markPathD: string, accentPathD?: string, markWidth: number, markHeight: number }}
 */
export function generate(config) {
  const { steps, stepHeight, stepWidth, curvature } = config;

  // Base unit: total mark height ≈ 40
  const BASE_UNIT = 40;

  // Each step's pixel dimensions
  const sw = parseFloat((BASE_UNIT * stepWidth).toFixed(3));  // step width
  const sh = parseFloat((BASE_UNIT * stepHeight).toFixed(3)); // step height

  // Total mark dimensions
  const markWidth = parseFloat((steps * sw).toFixed(3));
  const markHeight = parseFloat((steps * sh).toFixed(3));

  // Corner radius as fraction of the smaller step dimension
  const rr = parseFloat((Math.min(sw, sh) * curvature).toFixed(3));

  const pathParts = [];

  for (let i = 0; i < steps; i++) {
    // Step i: x starts at i * sw, y from (steps - 1 - i) * sh down to markHeight
    // This gives a staircase ascending left-to-right:
    //   - leftmost (i=0): tallest column (full height)
    //   - rightmost (i=steps-1): shortest column (one sh unit tall)
    const x = parseFloat((i * sw).toFixed(3));
    const y = parseFloat(((steps - 1 - i) * sh).toFixed(3));
    const w = sw;
    const h = parseFloat((markHeight - y).toFixed(3));

    if (rr > 0 && w > 2 * rr && h > 2 * rr) {
      // Full rounded rect (all 4 corners)
      pathParts.push(
        `M ${(x + rr).toFixed(3)},${y.toFixed(3)}` +
        ` h ${(w - 2 * rr).toFixed(3)}` +
        ` a ${rr},${rr} 0 0 1 ${rr},${rr}` +
        ` v ${(h - 2 * rr).toFixed(3)}` +
        ` a ${rr},${rr} 0 0 1 ${-rr},${rr}` +
        ` h ${(-(w - 2 * rr)).toFixed(3)}` +
        ` a ${rr},${rr} 0 0 1 ${-rr},${-rr}` +
        ` v ${(-(h - 2 * rr)).toFixed(3)}` +
        ` a ${rr},${rr} 0 0 1 ${rr},${-rr}` +
        ` Z`
      );
    } else {
      // Sharp rectangle
      pathParts.push(
        `M ${x.toFixed(3)},${y.toFixed(3)}` +
        ` h ${w.toFixed(3)}` +
        ` v ${h.toFixed(3)}` +
        ` h ${(-w).toFixed(3)}` +
        ` Z`
      );
    }
  }

  const markPathD = pathParts.join(" ");

  // NaN guard: validate no NaN in output
  if (markPathD.includes("NaN")) {
    throw new Error(`[b-step-r2] generate() produced NaN in path for config ${config.id}`);
  }

  // accentStep extension: separate top/rightmost step as accentPathD for two-tone mark
  if (config.accentStep) {
    const accentPathD = pathParts[steps - 1];
    return { markPathD, accentPathD, markWidth, markHeight };
  }

  return { markPathD, markWidth, markHeight };
}
