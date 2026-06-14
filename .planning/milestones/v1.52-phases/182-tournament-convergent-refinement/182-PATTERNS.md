# Phase 182: Tournament Convergent Refinement — Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `182/harness/dirs/b-step-r2.mjs` | generator | transform | `181/harness/dirs/b-step.mjs` | exact |
| `181/harness/assemble-lockup.mjs` (modify) | assembler | transform | self | exact |
| `181/harness/generate.mjs` (modify) | orchestrator | batch | self | exact |
| `181/harness/lint.mjs` (modify) | validator | batch | self | exact |
| `181/harness/render-matrix.mjs` (modify) | renderer | batch | self | exact |
| `181/harness/build-gallery.mjs` (modify) | HTML assembler | batch | self | exact |
| `181/TOURNAMENT.md` (append) | ledger | event-driven | Round 1 verdict block (lines 18–48) | exact |
| `182/round-2-gallery.html` (output artifact) | gallery | file-I/O | `181/round-1-gallery.html` | exact |

---

## Pattern Assignments

### `182/harness/dirs/b-step-r2.mjs` (generator, transform)

**Analog:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/b-step.mjs`

This new file is the Round 2 candidate configuration array plus the extended `generate()` function.
It replaces the 181 CONFIGS array (all B-direction) and adds the `accentPathD` output for two-tone
color variants.

**CONFIGS array pattern** (analog lines 17–58):
```js
export const CONFIGS = [
  {
    id: 'B1',
    steps: 4,
    stepHeight: 0.25,
    stepWidth: 0.25,
    curvature: 0.05,
    rationale: 'Four balanced steps with slight rounding — reads clearly as a staircase / billing-interval progression at all sizes',
  },
  // ... each entry has: id, steps, stepHeight, stepWidth, curvature, rationale
];
```

Round 2 CONFIGS shape extends each entry with optional fields:
```js
export const R2_CONFIGS = [
  {
    id: "R2-1",
    steps: 6, stepHeight: 0.18, stepWidth: 0.18, curvature: 0,
    colorTreatment: "ink",          // "ink" | "moss" | "two-tone"
    monoMap: {},                    // {} for ink variants; {"#5E9E84": "#818181"} for Moss variants
    accentStep: false,              // true = emit accentPathD for top step
    rationale: "B4 exact — ink baseline; user primary pick from Round 1",
  },
  // ...
];
```

**`generate()` return shape** (analog lines 76–141):
```js
export function generate(config) {
  const { steps, stepHeight, stepWidth, curvature } = config;
  const BASE_UNIT = 40;

  const sw = parseFloat((BASE_UNIT * stepWidth).toFixed(3));   // step width
  const sh = parseFloat((BASE_UNIT * stepHeight).toFixed(3));  // step height
  const markWidth  = parseFloat((steps * sw).toFixed(3));
  const markHeight = parseFloat((steps * sh).toFixed(3));
  const rr = parseFloat((Math.min(sw, sh) * curvature).toFixed(3));

  const pathParts = [];

  for (let i = 0; i < steps; i++) {
    const x = parseFloat((i * sw).toFixed(3));
    const y = parseFloat(((steps - 1 - i) * sh).toFixed(3));
    const w = sw;
    const h = parseFloat((markHeight - y).toFixed(3));

    if (rr > 0 && w > 2 * rr && h > 2 * rr) {
      // Full rounded rect (all 4 corners) — IN-04d: comment was stale, fix while editing
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

  if (markPathD.includes('NaN')) {
    throw new Error(`[b-step] generate() produced NaN in path for config ${config.id}`);
  }

  return { markPathD, markWidth, markHeight };
}
```

**New extension for `accentStep` (Option C from RESEARCH.md):**

When `config.accentStep === true`, extract `pathParts[steps - 1]` (the top/shortest/rightmost
step) as a separate `accentPathD` return field. The top step is step index `steps - 1`.

```js
// After pathParts loop — add to return object when accentStep is set:
const accentPathD = config.accentStep ? pathParts[steps - 1] : undefined;
return { markPathD, accentPathD, markWidth, markHeight };
```

The `accentPathD` is the SAME subpath already included in `markPathD` — the base mark and the
accent path overlap. `assembleLockup` renders the base (`markPathD`) in Ink, then overlays the
accent (`accentPathD`) in Moss on top. The overlay paints Moss over the top step's Ink fill.

---

### `assemble-lockup.mjs` (modify: add `accentPathD` + `accentFill` support)

**Analog:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/assemble-lockup.mjs`

**Coordinate-space contract** (lines 1–35, module header — MUST NOT change):
```
- extractGlyphs() bakes ABSOLUTE X positions into each glyph path, baseline at y=0
- assembleLockup places all glyph paths inside ONE <g translate(markScaledW+gap, BASELINE)>
- mark scaled by s = capHeight/markHeight, placed at (0, BASELINE-capHeight)
- BASELINE = capHeight * 1.1 inside viewboxH = capHeight * 1.4
- No per-glyph translate loops — glyph paths carry their own x layout
```

**Current mark `<g>` block** (lines 181–183):
```js
`  <g id="mark" transform="translate(${markTx},${markTy}) scale(${s.toFixed(6)})">`,
`    <path d="${markPathD}" fill="${palette.ink}"/>`,
`  </g>`,
```

**Extended mark `<g>` block for two-tone** (copy this pattern, replacing lines 181–183):
```js
`  <g id="mark" transform="translate(${markTx},${markTy}) scale(${s.toFixed(6)})">`,
`    <path d="${markPathD}" fill="${palette.ink}"/>`,
(config.accentPathD && palette.accentFill)
  ? `    <path d="${config.accentPathD}" fill="${palette.accentFill}"/>`
  : "",
`  </g>`,
```

**`palette` config shape** (lines 119–127):
```js
const {
  markWidth,
  markHeight,
  capHeight,
  gapRatio = 0.15,
  viewboxH,
  markIsTypemark = false,
  palette = { ink: "#111418", paper: "#FAFBFC" },
  // NOTE: WR-05 fix — change default ink to "#181818" (not "#111418")
  // "#111418" has HSV sat=0.29 > 0.15 and would fail lintMonochromeDeriv
} = config;
```

**WR-05 fix** (apply while editing): Change the default palette from `{ ink: "#111418", paper: "#FAFBFC" }` to `{ ink: "#181818", paper: "#FAFBFC" }`. Callers that pass the palette explicitly (like `generate.mjs` line 99) are unaffected.

---

### `generate.mjs` (modify: `--output-dir` parameterization + R2 config import)

**Analog:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/generate.mjs`

**PHASE_DIR hardcoding** (lines 35–45) — the pattern to REPLACE:
```js
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PHASE_DIR = path.resolve(__dirname, "..");    // ← always resolves to 181 dir
const CANDIDATES_DIR = path.join(PHASE_DIR, "candidates");
const REJECTED_DIR   = path.join(PHASE_DIR, "rejected");
const SCREENSHOTS_DIR = path.join(PHASE_DIR, "screenshots");
const LINT_LOG_PATH  = path.join(PHASE_DIR, "lint-results.ndjson");
```

**Parameterized replacement** (per RESEARCH.md Finding 1):
```js
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const argOutputDir = (() => {
  const i = process.argv.indexOf("--output-dir");
  return i !== -1 ? path.resolve(process.argv[i + 1]) : null;
})();
const PHASE_DIR = argOutputDir ?? path.resolve(__dirname, "..");
// All four PHASE_DIR-derived paths remain unchanged below this line
```

**`buildStandardCandidate()` signature** (lines 150–184) — no change to signature; extend to
pass `accentPathD` and `monoSvgString` through when present:
```js
function buildStandardCandidate(direction, generatorFn, config, accrueGlyphs, capHeight) {
  const { markPathD, accentPathD, markWidth, markHeight } = generatorFn(config);

  // Build color lockup SVG (full palette including Moss if configured)
  const lockupSvg = buildLockupSvg(markPathD, accentPathD, glyphs, markWidth, markHeight, capHeight, config);

  // Build mono-derived SVG for color variants (lint + mono tile)
  const monoSvgString = buildMonoSvg(lockupSvg, config.monoMap);

  return {
    id: config.id,
    direction,
    config,
    markPathD,
    accentPathD,
    markWidth,
    markHeight,
    lockupSvg,
    monoSvgString,   // undefined for ink-only variants (monoMap === {})
    markBbox,
    logotypeBbox,
    capHeight,
    skipGapRatio: false,
    rationale: config.rationale,
  };
}
```

**`buildLockupSvg()` extended signature** (lines 90–103):
```js
function buildLockupSvg(markPathD, accentPathD, glyphs, markWidth, markHeight, capHeight, config) {
  const viewboxH = capHeight * 1.4;
  // Determine fill colors from colorTreatment
  const ink = config.colorTreatment === "moss" ? "#5E9E84" : "#181818";
  const accentFill = (config.colorTreatment === "two-tone") ? "#5E9E84" : undefined;

  const result = assembleLockup(markPathD, glyphs, {
    markWidth, markHeight, capHeight,
    gapRatio: 0.15, viewboxH,
    markIsTypemark: false,
    palette: { ink, paper: "#FAFBFC", accentFill },
    accentPathD,  // passed through to assembleLockup for two-tone overlay
  });
  return typeof result === "string" ? result : result.svg;
}
```

**`buildMonoSvg()` helper** (new function, insert after `buildLockupSvg`):
```js
// Build the mono-derived SVG by substituting monoMap colors.
// Returns undefined when monoMap is empty (ink-only candidates need no mono variant).
function buildMonoSvg(svgString, monoMap) {
  if (!monoMap || Object.keys(monoMap).length === 0) return undefined;
  let mono = svgString;
  for (const [from, to] of Object.entries(monoMap)) {
    mono = mono.replaceAll(from, to);
  }
  return mono;
}
```

**IN-01 fix** (apply while editing): Delete the dead assignment `failed = rawCandidates.length - (rawCandidates.length - culled)` at line 466 (summary line). Replace with `const failed = culled;`.

**SMOKE constant** (line 47) — unchanged:
```js
const SMOKE = process.argv.includes("--smoke");
```

**Direction-floor logic** (lines 329–423): For Round 2 there is only one direction (B). The
floor check still runs but will always have enough B candidates. No change needed to the
floor logic; the `MIN_PER_DIRECTION` check is inert when all candidates share a direction.

---

### `lint.mjs` (modify: `lintCandidate` + `lintMonochromeDeriv` jsdoc fix)

**Analog:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/lint.mjs`

**`lintMonochromeDeriv()` current implementation** (lines 129–146) — CORRECT logic, WRONG jsdoc:
```js
/**
 * Fail if any hex color in the SVG has HSV saturation > 0.15.
 * Brand colors (#111418, #24303B, #FAFBFC, #E9EEF2) all have saturation < 0.15.  ← WRONG
 * ...
 */
function lintMonochromeDeriv(svgString) {
  const colorRe = /#([0-9a-fA-F]{3,6})\b/g;
  const matches = [...svgString.matchAll(colorRe)];
  for (const m of matches) {
    const hex = m[1];
    const full = hex.length === 3
      ? hex.split("").map((c) => c + c).join("")
      : hex;
    const r = parseInt(full.slice(0, 2), 16);
    const g = parseInt(full.slice(2, 4), 16);
    const b = parseInt(full.slice(4, 6), 16);
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const saturation = max === 0 ? 0 : (max - min) / max;
    if (saturation > 0.15) return false;
  }
  return true;
}
```

**WR-05 jsdoc fix**: Change the second sentence of the jsdoc to:
```
 * NOTE: #111418 (sat≈0.29) and #24303B (sat≈0.39) exceed this threshold.
 * Generated SVGs use #181818 (sat=0) for the Ink fill, NOT #111418.
 * Color variants use #5E9E84 (sat≈0.40) — lint those via the mono-derived SVG only.
```

**`lintCandidate()` extension** (lines 316–366): Replace the monochrome lint invocation at
lines 344–346 with the `monoSvgString` override pattern:
```js
// 4. Monochrome-derivable — run on mono-derived SVG if provided (color variants)
const svgForMonoLint = candidate.monoSvgString ?? svgString;
const monoPassed = lintMonochromeDeriv(svgForMonoLint);
record("monochrome-derivable", monoPassed,
  "saturated fill — if color variant, check monoMap config produces a low-saturation SVG");
if (!monoPassed) failures.push("monochrome-derivable");
```

**`lintCandidate()` parameter shape** (lines 306–318) — extend `@param` JSDoc:
```js
/**
 * @param {{
 *   id: string,
 *   direction: string,
 *   svgString: string,
 *   monoSvgString?: string,   // NEW: mono-derived SVG for color variants; lint runs on this
 *   skipGapRatio?: boolean,
 *   ...
 * }} candidate
 */
```

**PHASE_DIR hardcoding** (lines 28–37) — apply the same `--output-dir` parameterization as
`generate.mjs` (see above). The paths `CANDIDATES_DIR`, `REJECTED_DIR`, `LINT_LOG` all derive
from `PHASE_DIR`.

---

### `render-matrix.mjs` (modify: `--output-dir` + Moss INK_DARK_COLOR_MAP + avatar-circle clip + WR-01)

**Analog:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/render-matrix.mjs`

**PHASE_DIR hardcoding** (lines 25–34) — apply `--output-dir` parameterization identical to
`generate.mjs` pattern above.

**`INK_DARK_COLOR_MAP`** (lines 97–101) — current:
```js
const INK_DARK_COLOR_MAP = {
  "#181818": "#FAFBFC",   // dark ink → paper
  "#FAFBFC": "#111418",   // paper knockout → dark bg
  "#E9EEF2": "#2A333C",   // fog knockout → dark mid-tone
};
```

**Extended with Moss identity entry** (RESEARCH.md Finding 5):
```js
const INK_DARK_COLOR_MAP = {
  "#181818": "#FAFBFC",   // dark ink → paper (visible on dark bg)
  "#FAFBFC": "#111418",   // paper knockout → dark bg
  "#E9EEF2": "#2A333C",   // fog knockout → dark mid-tone
  "#5E9E84": "#5E9E84",   // Moss → Moss (identity; 5.89:1 on Ink-dark, already passes AA-body)
};
```

For two-tone marks: Ink base `#181818` maps to Paper `#FAFBFC`, Moss accent stays Moss →
Paper+Moss mark on Ink-dark background. Verify visually in spot-check (REQ-2).

**TILES array** (lines 44–53) — unchanged structure; mono tile stays as CSS grayscale filter:
```js
const TILES = [
  { id: "paper-light",   w: 320,  h: 80,  bg: "#FAFBFC", dpr: 1, mono: false },
  { id: "ink-dark",      w: 320,  h: 80,  bg: "#111418", dpr: 1, mono: false },
  { id: "32px-favicon",  w: 32,   h: 32,  bg: "#FAFBFC", dpr: 2, mono: false },
  { id: "16px-favicon",  w: 16,   h: 16,  bg: "#FAFBFC", dpr: 4, mono: false },
  { id: "avatar-circle", w: 96,   h: 96,  bg: "#FAFBFC", dpr: 2, mono: false },
  { id: "readme-header", w: 800,  h: 120, bg: "#FAFBFC", dpr: 1, mono: false },
  { id: "social-card",   w: 600,  h: 315, bg: "#FAFBFC", dpr: 1, mono: false },
  { id: "mono",          w: 320,  h: 80,  bg: "#FAFBFC", dpr: 1, mono: true  },
];
```

Note: the `mono` tile applies `filter: grayscale(1)` via CSS in `buildTileHtml`. For Round 2
the declared `monoMap` approach produces the mono-derived SVG; whether the mono TILE uses the
mono-derived SVG or the CSS filter is a planner decision. The RESEARCH.md recommends using the
pre-computed mono-derived SVG for the mono tile (more precise for design review). If implemented,
add a `monoSvgPath?: string` field to TILES logic in `buildTileHtml`:
```js
// In renderTile() or buildTileHtml() — for mono tile:
const svgForTile = (tile.mono && monoSvgContent) ? monoSvgContent : svgContent;
const effectiveSvg = tile.id === "ink-dark" ? applyInkDarkColors(svgForTile) : svgForTile;
```

**WR-07 avatar-circle fix** (REVIEW lines 107–115) — add circular crop to `buildTileHtml`:
```js
// In buildTileHtml(), add next to the existing mono/ink-dark special cases:
const circleStyle = tile.id === "avatar-circle"
  ? `<style>body { border-radius: 50%; overflow: hidden; }</style>`
  : "";

// And in the returned HTML, include circleStyle alongside monoStyle:
// <head>...\n${monoStyle}\n${circleStyle}\n...</head>
```

Also change the `renderTile` Playwright screenshot target from `page.locator("svg")` to
`page.locator("body")` for the avatar-circle tile so the clip is captured:
```js
const screenshotTarget = tile.id === "avatar-circle"
  ? page.locator("body")
  : page.locator("svg");
await screenshotTarget.screenshot({ path: outputPath });
```

**WR-01 fix** (REVIEW lines 60–68) — smoke-mode must not clobber full index:
```js
// In main(), Step 4 — replace:
let surviving = candidates.filter(c => !culledIds.has(c.id));

// With: read from full on-disk index first
const fullIndex = JSON.parse(fs.readFileSync(indexPath, "utf8"));
let surviving = fullIndex.filter(c => !culledIds.has(c.id));
```

**Blank-render guard** (lines 249–275) — unchanged; keep at `BLANK_RENDER_MIN_DARK_COVERAGE = 0.005`:
```js
const coverage = darkPixelCoverage(paperLightPath);
if (coverage < BLANK_RENDER_MIN_DARK_COVERAGE) {
  console.error(`[render] BLANK-RENDER ${id}: paper-light dark coverage=... — SVG ink is outside viewBox`);
  // ... cull to rejected/
}
```

**IN-04a fix** (apply while editing): Update the blank-render guard comment from "paper-light
or 32px-favicon tile" to "paper-light tile" — the guard only checks paper-light.

**Legibility lint tile for color variants**: Per RESEARCH.md Finding 5, full-Moss variants
may fail 16px legibility on paper-light (contrast 3.03:1 at the threshold). Do NOT change
`CR_THRESHOLD = 3.0`. Let full-Moss variants fail honestly — the pipeline's rejection reason
makes the signal explicit. Two-tone (Ink base + Moss accent) variants pass because the dominant
fill is `#181818` Ink.

---

### `build-gallery.mjs` (modify: `--output-dir` + `--gallery-name` + Round 2 VERDICT_JS)

**Analog:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/build-gallery.mjs`

**PHASE_DIR + GALLERY_PATH hardcoding** (lines 24–33) — apply `--output-dir` parameterization:
```js
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const argOutputDir = (() => {
  const i = process.argv.indexOf("--output-dir");
  return i !== -1 ? path.resolve(process.argv[i + 1]) : null;
})();
const PHASE_DIR = argOutputDir ?? path.resolve(__dirname, "..");

const argGalleryName = (() => {
  const i = process.argv.indexOf("--gallery-name");
  return i !== -1 ? process.argv[i + 1] : null;
})();
const GALLERY_PATH = path.join(PHASE_DIR, argGalleryName ?? "round-1-gallery.html");

const CANDIDATES_DIR  = path.join(PHASE_DIR, "candidates");
const SCREENSHOTS_DIR = path.join(PHASE_DIR, "screenshots");
```

**`renderCandidate()` function** (lines 51–103) — no structural change; update `data-direction`
to show the R2 ID scheme (e.g. "Round 2 — B4 variant") instead of "Direction B":
```js
// The direction badge for R2 candidates shows the color treatment, not a direction letter:
const colorLabel = candidate.colorTreatment
  ? `Color: ${candidate.colorTreatment}`
  : `Direction ${direction}`;
```

**VERDICT_JS** (lines 347–413) — functional copy with Round 2 schema:
```js
// Change lines.push('## Round 1 — ' + today); to:
lines.push('## Round 2 — ' + today);
// Change the constraints placeholder label:
lines.push('(leave blank — agent fills after round; agent extracts R2-C{n} IDs)');
```

The full `buildVerdictBlock()` logic is identical otherwise — winner/killed/notes structure
is the same schema the agent reads to produce the TOURNAMENT.md append.

**`buildGallery()` direction grouping** (lines 420–453) — for Round 2, all candidates are
Direction B. Replace the A/B/C/D direction-section loop with a flat grid (no section headers
by direction, or group by color treatment instead):
```js
// Round 2: group by color treatment instead of direction
const byColor = {};
for (const c of candidates) {
  const key = c.colorTreatment || "ink";
  if (!byColor[key]) byColor[key] = [];
  byColor[key].push(c);
}
const colorNames = {
  ink: "Ink (monochrome baseline)",
  moss: "Full Moss (#5E9E84)",
  "two-tone": "Two-tone: Ink + Moss accent",
};
// render sections by: ink → moss → two-tone
for (const color of ["ink", "moss", "two-tone"]) {
  // ... same section/card rendering as Round 1
}
```

**Gallery `<title>` and header text** (lines 457–471): Change "Round 1" to "Round 2":
```js
<title>Accrue Round 2 Gallery</title>
// header h1:
<h1>Accrue Logo Tournament — Round 2</h1>
// header p (paste instruction):
// ...paste the result into TOURNAMENT.md at the <!-- ROUND-2-APPEND-BELOW --> marker.
```

---

### `TOURNAMENT.md` (append at `<!-- ROUND-2-APPEND-BELOW -->`)

**Analog:** Round 1 verdict block in `181/TOURNAMENT.md` lines 18–48

**Existing Round 1 block structure** (exact schema to mirror for Round 2):
```markdown
## Round 1 — 2026-06-12

<!-- ROUND-1-PASTE-BELOW -->
**Winners:** B4 (primary), B1 (runner-up)
**Killed:** A1 A2 A3 ...

> Verbatim user verdict ...

### B4
- keep: "..."
- change: "..."

### B1
- keep: "..."
- change: "..."

### Constraints (extracted by agent, user-confirmed)
- R1-C1: ...
- R1-C2: ...
```

**Round 2 append schema** (write at `<!-- ROUND-2-APPEND-BELOW -->` marker):
```markdown
## Round 2 — {date}

**Winners:** {R2-N} (primary)[, {R2-M} (runner-up)]
**Killed:** {all other R2 IDs}

> Verbatim user verdict (transcribed)

### {R2-N}
- keep: "{keep note}"
- change: "{change note}"

### Constraints (extracted by agent, user-confirmed)
- R2-C1: ...
- R2-C2: ...

---
```

After the block, if locking a winner:
```markdown
## WINNER LOCKED — {date}

**Final winner:** {R2-N}
**Geometry config:** {full config object}
**Rationale:** {one sentence}

*Phase 183 reads the geometry config above to produce the production logo system in `brandbook/`.*
```

The `<!-- ROUND-2-APPEND-BELOW -->` marker and the `<!-- ROUND-3-APPEND-BELOW -->` marker
(if needed) follow the same invariant: marker stays in place, verdict block is inserted ABOVE
the `---` that follows it, not below.

---

## Shared Patterns

### `--output-dir` CLI Arg (apply to 4 harness scripts)

**Applies to:** `generate.mjs`, `lint.mjs`, `render-matrix.mjs`, `build-gallery.mjs`

**Exact two-line replacement** for each script's `PHASE_DIR = path.resolve(__dirname, "..")`:
```js
const argOutputDir = (() => {
  const i = process.argv.indexOf("--output-dir");
  return i !== -1 ? path.resolve(process.argv[i + 1]) : null;
})();
const PHASE_DIR = argOutputDir ?? path.resolve(__dirname, "..");
```

Insert immediately after the `const __dirname = ...` line. All downstream path joins
(`CANDIDATES_DIR`, `REJECTED_DIR`, `SCREENSHOTS_DIR`, `LINT_LOG`, `GALLERY_PATH`) derive from
`PHASE_DIR` and require no further change.

**Invocation pattern** from repo root:
```bash
HARNESS=.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness
OUTPUT=.planning/phases/182-tournament-convergent-refinement

node $HARNESS/generate.mjs      --output-dir $OUTPUT
node $HARNESS/render-matrix.mjs --output-dir $OUTPUT
node $HARNESS/build-gallery.mjs --output-dir $OUTPUT --gallery-name round-2-gallery.html
```

### Coordinate-Space Contract (MUST NOT change)

**Source:** `assemble-lockup.mjs` lines 1–35 (module header)
**Applies to:** Any new code path that calls `assembleLockup()` — including the two-tone path

The three invariants that caused Fix 3 when violated:
1. Single `<g>` for all glyphs — no per-glyph translate loops
2. Mark scaled by `s = capHeight / markHeight`
3. `BASELINE = capHeight * 1.1` for the glyph group translate

The `accentPathD` overlay sits inside the existing mark `<g>` (inherits the same
`translate + scale` transform) — it correctly scales to cap height with no additional transform.

### Visual Verification Gate (mandatory before checkpoint, per D-182-10)

**Applies to:** Round 2 plan's final pre-checkpoint tasks

After pipeline run, executor MUST Read these PNGs and confirm:
```
REQ-1: Read screenshots/R2-5/paper-light.png  → mark visible, Moss color confirmed
REQ-2: Read screenshots/R2-6/ink-dark.png     → Paper+Moss mark on dark background
REQ-3: Read screenshots/R2-2/16px-favicon.png → 5 steps individually distinguishable
REQ-4: Read screenshots/R2-5/mono.png         → grey (not green) mark
REQ-5: grep -c "class=\"candidate\"" round-2-gallery.html → ≥ 6
```

### Blank-Render Guard (unchanged — MUST stay)

**Source:** `render-matrix.mjs` lines 249–275
**Signal:** paper-light dark pixel coverage < 0.5%
**Action:** reject as "blank-render" (not legibility cull)
**What it detects:** coordinate-space bug (SVG ink outside viewBox)
**Do not tune:** threshold stays at `BLANK_RENDER_MIN_DARK_COVERAGE = 0.005`

### Smoke-Mode Invocation

```bash
node $HARNESS/generate.mjs --output-dir $OUTPUT --smoke
# Expect: R2_CONFIGS[0] only (one candidate), no blank-render, lint-results.ndjson created
```

Smoke runs MUST NOT clobber the full index (WR-01 fix applied first). If smoke passes, run full.

---

## No Analog Found

All files in Phase 182 have direct analogs in the Phase 181 harness. No file requires patterns
from RESEARCH.md alone.

---

## REVIEW.md Triage Applied

Per D-182-13, only pipeline-exercised findings are addressed in Phase 182:

| Finding | Status | Where Applied |
|---------|--------|---------------|
| WR-01 (smoke clobbers index.json) | MUST FIX | `render-matrix.mjs` — fullIndex pattern above |
| WR-05 (mono lint jsdoc wrong; default palette) | MUST FIX | `lint.mjs` jsdoc + `assemble-lockup.mjs` default palette |
| WR-07 (avatar-circle not cropped) | MUST FIX | `render-matrix.mjs` — circleStyle + body screenshot |
| IN-04d (b-step comment "top corners only" vs "full rounded rect") | FIX WHILE EDITING | `b-step-r2.mjs` generate() comment |
| IN-01 (dead `failed = ...` computation) | FIX WHILE EDITING | `generate.mjs` summary line |
| IN-04a (blank-render doc says "paper-light or 32px-favicon") | FIX WHILE EDITING | `render-matrix.mjs` blank-render comment |

Findings left for Phase 183: CR-01, WR-02, WR-03, WR-04, WR-06, WR-08, WR-09, IN-02, IN-03, IN-04b/c, IN-05, IN-06, IN-07, IN-08

---

## Metadata

**Analog search scope:** `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/`
**Files scanned:** 7 harness modules + TOURNAMENT.md + 181-REVIEW.md + 181-06-SUMMARY.md
**Pattern extraction date:** 2026-06-13
