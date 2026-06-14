/**
 * b-step.mjs — Direction B: stepped interval / timeline tick mark generator
 *
 * Motif: a staircase or stepped progression — a series of rising steps with
 * uniform or varying intervals, reading as timeline ticks or billing intervals
 * accumulating. Fits brand metaphor: timelines, aligned intervals.
 *
 * Exports:
 *   CONFIGS  — array of 5 candidate knob configurations (B1–B5)
 *   generate(config) → { markPathD, markWidth, markHeight }
 */

// ---------------------------------------------------------------------------
// CONFIGS — 5 candidate parameter sets
// ---------------------------------------------------------------------------

export const CONFIGS = [
  {
    id: 'B1',
    steps: 4,
    stepHeight: 0.25,
    stepWidth: 0.25,
    curvature: 0.05,
    rationale: 'Four balanced steps with slight rounding — reads clearly as a staircase / billing-interval progression at all sizes',
  },
  {
    id: 'B2',
    steps: 5,
    stepHeight: 0.20,
    stepWidth: 0.20,
    curvature: 0,
    rationale: 'Five sharp-cornered steps — crisp timeline-tick geometry, strong technical character with no softening',
  },
  {
    id: 'B3',
    steps: 3,
    stepHeight: 0.30,
    stepWidth: 0.35,
    curvature: 0.10,
    rationale: 'Three wide rounded steps — bold and approachable, maximises legibility at 16px favicon with chunky proportions',
  },
  {
    id: 'B4',
    steps: 6,
    stepHeight: 0.18,
    stepWidth: 0.18,
    curvature: 0,
    rationale: 'Six fine steps — dense interval grid, signals precision billing cadence; best at medium/large sizes',
  },
  {
    id: 'B5',
    steps: 4,
    stepHeight: 0.28,
    stepWidth: 0.30,
    curvature: 0.08,
    rationale: 'Four steps with generous height and soft corners — balanced between clarity and approachability, good for avatar crop',
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
 * @param {{ id: string, steps: number, stepHeight: number, stepWidth: number, curvature: number }} config
 * @returns {{ markPathD: string, markWidth: number, markHeight: number }}
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
    // Step sits at column i, starting from y=(steps-1-i)*sh, height from there to markHeight
    // This gives a staircase ascending left-to-right:
    //   - leftmost (i=0): tallest column (full height)
    //   - rightmost (i=steps-1): shortest column (one sh unit tall)
    const x = parseFloat((i * sw).toFixed(3));
    const y = parseFloat(((steps - 1 - i) * sh).toFixed(3));
    const w = sw;
    const h = parseFloat((markHeight - y).toFixed(3));

    if (rr > 0 && w > 2 * rr && h > 2 * rr) {
      // Top corners only: rounded top-left and top-right to give a stepped-bar look
      // Full rounded rect for simplicity (all 4 corners)
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

  const markPathD = pathParts.join(' ');

  // T-181-06: validate no NaN in output
  if (markPathD.includes('NaN')) {
    throw new Error(`[b-step] generate() produced NaN in path for config ${config.id}`);
  }

  return { markPathD, markWidth, markHeight };
}
