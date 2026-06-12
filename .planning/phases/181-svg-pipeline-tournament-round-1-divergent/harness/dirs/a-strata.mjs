/**
 * a-strata.mjs — Direction A: accumulation strata mark generator
 *
 * Motif: horizontal strata (layered records accumulating over time) — 3–6
 * horizontal bars of varying thickness stacked with breathing space between
 * them. The stack reads as "data building up." Fits brand metaphor:
 * accumulation, layered records.
 *
 * Exports:
 *   CONFIGS  — array of 5 candidate knob configurations (A1–A5)
 *   generate(config) → { markPathD, markWidth, markHeight }
 */

// ---------------------------------------------------------------------------
// CONFIGS — 5 candidate parameter sets
// ---------------------------------------------------------------------------

export const CONFIGS = [
  {
    id: 'A1',
    layers: 4,
    amplitude: 0.3,
    strokeWeight: 1.5,
    spacing: 0.25,
    rationale: 'Balanced four-bar stack with moderate taper — readable at all sizes and clearly accumulative without feeling dense',
  },
  {
    id: 'A2',
    layers: 5,
    amplitude: 0.5,
    strokeWeight: 1.2,
    spacing: 0.20,
    rationale: 'Five thin bars with strong taper give a pronounced data-building wedge — emphasises the accumulation metaphor',
  },
  {
    id: 'A3',
    layers: 3,
    amplitude: 0.2,
    strokeWeight: 2.0,
    spacing: 0.30,
    rationale: 'Three chunky bars with gentle taper — bold and clean, maximises legibility at 16px favicon size',
  },
  {
    id: 'A4',
    layers: 6,
    amplitude: 0.4,
    strokeWeight: 1.0,
    spacing: 0.15,
    rationale: 'Six fine bars with compact spacing — layered-record richness, good for social-card context at larger sizes',
  },
  {
    id: 'A5',
    layers: 4,
    amplitude: 0.6,
    strokeWeight: 1.8,
    spacing: 0.35,
    rationale: 'Four wide bars with aggressive taper and generous breathing room — striking wedge shape with strong baseline anchor',
  },
];

// ---------------------------------------------------------------------------
// generate(config) — produce SVG path data for one accumulation-strata mark
// ---------------------------------------------------------------------------

/**
 * Build a single combined SVG path string for the accumulation-strata mark.
 *
 * Coordinate space: 0,0 = top-left. markHeight ≈ 40 units at fontSize=1000.
 * Bars are represented as rounded rectangles using arc path commands.
 * Mark is left-aligned; logotype follows via assemble-lockup.mjs.
 *
 * @param {{ id: string, layers: number, amplitude: number, strokeWeight: number, spacing: number }} config
 * @returns {{ markPathD: string, markWidth: number, markHeight: number }}
 */
export function generate(config) {
  const { layers, amplitude, strokeWeight, spacing } = config;

  // Base dimensions (at fontSize=1000 coordinate space, mark ≈ 40 units tall)
  const BASE_HEIGHT = 40;
  const BASE_WIDTH = 36;

  // Bar height based on strokeWeight and how many bars fit in BASE_HEIGHT
  // Total height = layers * barH + (layers - 1) * gap
  // gap = barH * spacing
  // BASE_HEIGHT = layers * barH * (1 + spacing) - barH * spacing
  // BASE_HEIGHT = barH * (layers + (layers-1) * spacing)
  const barH = BASE_HEIGHT / (layers + (layers - 1) * spacing);
  const gap = barH * spacing;
  const r = Math.min(barH / 2, strokeWeight * 0.6); // corner radius, capped at half barH

  const pathParts = [];

  for (let i = 0; i < layers; i++) {
    // Width tapers: layer 0 (top) is narrowest when amplitude > 0, layer (layers-1) is full width
    // "data building up" — bottom bars are wider (more accumulated)
    const t = layers > 1 ? i / (layers - 1) : 1;
    const w = parseFloat((BASE_WIDTH * (amplitude + (1 - amplitude) * t)).toFixed(3));
    const h = parseFloat(barH.toFixed(3));
    const x = 0; // left-aligned
    const y = parseFloat((i * (barH + gap)).toFixed(3));
    const rr = parseFloat(r.toFixed(3));

    // Rounded rectangle as path (clockwise from top-left corner after initial arc)
    // M top-left corner + rx offset, then: arc top-right, line, arc bottom-right, line, arc bottom-left, line, arc top-left, Z
    if (rr > 0 && w > 2 * rr && h > 2 * rr) {
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
      // Fallback: sharp rectangle if radius is too large or bar is very thin
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
  const markWidth = parseFloat(BASE_WIDTH.toFixed(3));
  const markHeight = parseFloat(BASE_HEIGHT.toFixed(3));

  // T-181-06: validate no NaN in output
  if (markPathD.includes('NaN')) {
    throw new Error(`[a-strata] generate() produced NaN in path for config ${config.id}`);
  }

  return { markPathD, markWidth, markHeight };
}
