/**
 * c-arcs.mjs — Direction C: layered arcs / state transition mark generator
 *
 * Motif: concentric or offset partial arcs — 2–4 arcs layered at different
 * radii or angular offsets, reading as state-machine transitions, progress
 * rings, or lifecycle stages. Fits brand metaphor: state transitions, layered
 * records, accumulation.
 *
 * Note on color: arcs use stroke-based geometry. The stroke color is #181818
 * (pure grey, HSV sat=0) rather than Ink #111418 (HSV sat≈0.29) to pass the
 * monochrome lint check (threshold: saturation ≤ 0.15). This is a Rule 1 fix
 * per 181-02-SUMMARY deviation finding: brand dark #111418 exceeds threshold.
 *
 * Exports:
 *   CONFIGS  — array of 5 candidate knob configurations (C1–C5)
 *   generate(config) → { markPathD, markGroupSvg, markWidth, markHeight }
 */

// ---------------------------------------------------------------------------
// CONFIGS — 5 candidate parameter sets
// ---------------------------------------------------------------------------

export const CONFIGS = [
  {
    id: 'C1',
    arcCount: 3,
    sweep: 200,
    radiiSpread: 0.25,
    strokeWidth: 2.0,
    offset: 30,
    rationale: 'Three arcs with staggered rotation — layered state-transition rings with balanced spread; legible at both favicon and social-card sizes',
  },
  {
    id: 'C2',
    arcCount: 2,
    sweep: 270,
    radiiSpread: 0.30,
    strokeWidth: 3.0,
    offset: 0,
    rationale: 'Two concentric wide arcs with no offset — minimal and bold, strong favicon silhouette; sweep communicates progress/completion',
  },
  {
    id: 'C3',
    arcCount: 4,
    sweep: 150,
    radiiSpread: 0.20,
    strokeWidth: 1.5,
    offset: 45,
    rationale: 'Four short arcs with maximum rotational spread — layered records with distinct lifecycle stages visible as separate arcs',
  },
  {
    id: 'C4',
    arcCount: 3,
    sweep: 240,
    radiiSpread: 0.35,
    strokeWidth: 2.5,
    offset: 20,
    rationale: 'Three wide arcs with generous radii spread and slight rotation — open, confident mark expressing sustained state transitions',
  },
  {
    id: 'C5',
    arcCount: 2,
    sweep: 300,
    radiiSpread: 0.40,
    strokeWidth: 2.0,
    offset: 15,
    rationale: 'Two sweeping arcs with wide radii gap — nearly-complete rings with subtle rotation; reads clearly as a continuous cycle at all sizes',
  },
];

// ---------------------------------------------------------------------------
// Arc path helpers
// ---------------------------------------------------------------------------

/**
 * Convert degrees to radians.
 * @param {number} deg
 * @returns {number}
 */
function toRad(deg) {
  return deg * Math.PI / 180;
}

/**
 * Build an SVG arc path string for a partial circle arc.
 * @param {number} cx  Center x
 * @param {number} cy  Center y
 * @param {number} r   Radius
 * @param {number} startDeg  Start angle in degrees (0 = right, clockwise)
 * @param {number} sweepDeg  Sweep angle in degrees (positive = clockwise)
 * @returns {string}  SVG path data fragment: "M x,y A rx,ry xrot large-arc sweep ex,ey"
 */
function arcPath(cx, cy, r, startDeg, sweepDeg) {
  const x1 = parseFloat((cx + r * Math.cos(toRad(startDeg))).toFixed(3));
  const y1 = parseFloat((cy + r * Math.sin(toRad(startDeg))).toFixed(3));
  const endDeg = startDeg + sweepDeg;
  const x2 = parseFloat((cx + r * Math.cos(toRad(endDeg))).toFixed(3));
  const y2 = parseFloat((cy + r * Math.sin(toRad(endDeg))).toFixed(3));

  // Large arc flag: 1 if sweep > 180
  const largeArc = Math.abs(sweepDeg) > 180 ? 1 : 0;
  // Sweep direction: 1 for clockwise (positive sweep), 0 for counter-clockwise
  const sweepFlag = sweepDeg >= 0 ? 1 : 0;

  return `M ${x1},${y1} A ${r},${r} 0 ${largeArc} ${sweepFlag} ${x2},${y2}`;
}

// ---------------------------------------------------------------------------
// generate(config) — produce arc-based SVG path data for one state-transition mark
// ---------------------------------------------------------------------------

/**
 * Build arc-based mark geometry for Direction C.
 *
 * Returns { markPathD, markGroupSvg, markWidth, markHeight }.
 *
 * markPathD: space-joined arc path segments (d attribute value for a single <path>)
 * markGroupSvg: complete <path ... /> element string including stroke/fill attrs,
 *   ready to embed in an SVG <g> group by assemble-lockup.mjs.
 *
 * Color note: uses #181818 (pure grey, HSV sat=0) — NOT #111418 (HSV sat≈0.29
 * which exceeds the monochrome lint threshold of 0.15). See module header.
 *
 * @param {{ id: string, arcCount: number, sweep: number, radiiSpread: number, strokeWidth: number, offset: number }} config
 * @returns {{ markPathD: string, markGroupSvg: string, markWidth: number, markHeight: number }}
 */
export function generate(config) {
  const { arcCount, sweep, radiiSpread, strokeWidth, offset } = config;

  // Outer arc radius ≈ 20 units; mark bounding box = 2*outerRadius × 2*outerRadius
  const outerRadius = 20;
  const cx = outerRadius;
  const cy = outerRadius;

  // Starting angle for the outermost arc: -90 deg (top of circle) minus half sweep,
  // so each arc is centered around the top.
  const baseStartDeg = -90 - sweep / 2;

  const arcParts = [];

  for (let i = 0; i < arcCount; i++) {
    // Successive arcs are smaller by radiiSpread each
    const r = parseFloat((outerRadius * (1 - i * radiiSpread)).toFixed(3));
    if (r <= 0) continue; // guard against degenerate radius

    // Each arc is rotated by `offset` degrees relative to the previous
    const startDeg = parseFloat((baseStartDeg + i * offset).toFixed(3));

    arcParts.push(arcPath(cx, cy, r, startDeg, sweep));
  }

  const markPathD = arcParts.join(' ');
  const markWidth = parseFloat((2 * outerRadius).toFixed(3));
  const markHeight = parseFloat((2 * outerRadius).toFixed(3));

  // T-181-06: validate no NaN in output
  if (markPathD.includes('NaN')) {
    throw new Error(`[c-arcs] generate() produced NaN in path for config ${config.id}`);
  }

  // Build complete <path> element string with stroke/fill attributes.
  // Uses pure grey #181818 (not #111418) to pass lintMonochromeDeriv.
  const sw = parseFloat(strokeWidth.toFixed(3));
  const markGroupSvg = `<path d="${markPathD}" stroke="#181818" fill="none" stroke-width="${sw}" stroke-linecap="round"/>`;

  return { markPathD, markGroupSvg, markWidth, markHeight };
}
