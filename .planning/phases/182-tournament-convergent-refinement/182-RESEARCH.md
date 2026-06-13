---
phase: 182-tournament-convergent-refinement
researched: 2026-06-12
domain: SVG pipeline parameterization, color treatment, tournament loop mechanics
confidence: HIGH
---

# Phase 182: Tournament Convergent Refinement — Research

**Researched:** 2026-06-12
**Domain:** SVG logo pipeline reuse, color fills, monochrome lint, 16px legibility, tournament loop structure
**Confidence:** HIGH (all findings from repo archaeology — no external web research needed)

---

## Summary

Phase 182 reuses the Phase 181 harness (generate → lint → render-matrix → build-gallery) against a
new candidate set: 6–9 variants of B4 (primary) and B1 (runner-up), now also exploring brand-color
fills (full Moss, two-tone Ink+Moss). Four surgical changes to the harness enable this:

1. **Parameterize phase-dir** in generate/lint/render-matrix/build-gallery so they can target the
   182 output directory while the 181 harness directory (and its `node_modules`) stays in place.
2. **Extend `assembleLockup` palette** to accept a per-element fill map for two-tone marks.
3. **Fix `lintMonochromeDeriv` semantics** so color variants are not auto-culled but are still
   required to prove they are mono-derivable by declaring a mono mapping that the pipeline
   lints and renders.
4. **Extend `INK_DARK_COLOR_MAP`** in `render-matrix.mjs` to handle Moss fills on dark backgrounds.

The round loop is one-round-per-plan. Each plan's final task is a user checkpoint; the planner
authors exactly the number of round-plans that exist (Round 2 = 182-02, Round 3 = 182-03 if
needed) and the user decides after each gallery whether to lock or extend.

**Primary recommendation:** Reuse the 181 harness directory in-place with an `--output-dir` CLI
argument. Do not copy the harness into 182 — it doubles the node_modules footprint for no benefit
and creates two sources of truth for the harness code.

---

## Architectural Responsibility Map

| Capability | Primary Location | Secondary | Rationale |
|------------|-----------------|-----------|-----------|
| Candidate geometry (new configs) | `182/harness/dirs/b-step.mjs` (a copy/fork) | — | New CONFIGS array for R2 IDs; the 181 CONFIGS are dead per R1-C1 |
| Color fill variants | `assembleLockup` palette extension | `generate.mjs` | The assembler owns fill injection; generator passes per-element fill map |
| Mono derivation proof | `lint.mjs` + `render-matrix.mjs` | — | Lint checks the mono-mapped render, not the color SVG's raw hex values |
| Ink-dark color swapping | `render-matrix.mjs INK_DARK_COLOR_MAP` | — | Existing mechanism, needs Moss entry added |
| Gallery output | `build-gallery.mjs` | — | Writes `round-2-gallery.html`; reads from 182 output dir |
| Ledger append | Manual task (agent writes) | — | Appends at `<!-- ROUND-2-APPEND-BELOW -->` in 181 TOURNAMENT.md |

---

## Research Finding 1: Harness Parameterization

### The Hardcoding Problem

Every harness module resolves its phase directory with the same pattern:

```js
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PHASE_DIR = path.resolve(__dirname, "..");
```

This is `__dirname` of `harness/` resolved one level up — always the 181 phase dir regardless
of where the scripts are invoked from. The four scripts affected: `generate.mjs`, `lint.mjs`,
`render-matrix.mjs`, `build-gallery.mjs`. `geist-spine.mjs` and `assemble-lockup.mjs` have no
path dependencies and are unaffected. `b-step.mjs` has no path dependencies.

### Recommendation: `--output-dir` CLI argument (one env var pattern)

The smallest diff is a single resolution function added to each affected script:

```js
// Replace the hardcoded PHASE_DIR line with:
const argOutputDir = (() => {
  const i = process.argv.indexOf("--output-dir");
  return i !== -1 ? path.resolve(process.argv[i + 1]) : null;
})();
const PHASE_DIR = argOutputDir ?? path.resolve(__dirname, "..");
```

**Why CLI arg over env var:**
- Env vars leak across concurrent runs; CLI args are per-invocation
- `node harness/generate.mjs --output-dir ../../182-tournament-convergent-refinement` is
  self-documenting in shell history and SUMMARY commits
- No new config module needed; four two-line edits total

**Why reuse 181 harness in-place vs. copy:**
- `node_modules` is ~120 MB (playwright, opentype.js, pngjs, wawoff2). Copying doubles this.
- Harness code is already verified correct post-fix. Copying creates a divergence risk.
- The 182 phase dir only needs: `candidates/`, `rejected/`, `screenshots/`,
  `round-2-gallery.html`, `lint-results.ndjson` — all produced by the scripts as output.
- The 181 harness `dirs/b-step.mjs` file gets a 182-specific CONFIGS array. One approach: a
  separate `dirs/b-step-r2.mjs` file in the 182 phase dir, referenced by a 182-specific
  `generate-r2.mjs` wrapper that also sets `PHASE_DIR` to the 182 dir. But this is more
  complexity than needed. Simpler: a thin `generate-r2.mjs` in the 182 harness dir that
  imports from the 181 harness but overrides CONFIGS. See Pattern 1 below.

### Simplest Execution Pattern

Add `--output-dir` to the four affected scripts (4 lines total). Invoke from the repo root:

```bash
# From repo root
HARNESS=.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness
OUTPUT=.planning/phases/182-tournament-convergent-refinement

node $HARNESS/generate.mjs  --output-dir $OUTPUT
node $HARNESS/render-matrix.mjs --output-dir $OUTPUT
node $HARNESS/build-gallery.mjs --output-dir $OUTPUT
```

`generate.mjs` also needs to import the Round 2 B configs instead of the full A/B/C/D configs.
The cleanest approach without a full harness fork: pass a `--config-module` path or simply
edit a 182-specific `generate-r2.mjs` that imports from the 181 harness and overrides the
direction config. See "Pattern 1" in Code Examples below.

**Also needed in `build-gallery.mjs`:** The gallery output file name is hardcoded as
`round-1-gallery.html`. Add `--gallery-name <filename>` or make it derive from `--output-dir`
basename. Recommend `--gallery-name round-2-gallery.html` as a CLI arg.

[VERIFIED: repo source, assemble-lockup.mjs + generate.mjs + lint.mjs + render-matrix.mjs + build-gallery.mjs]

---

## Research Finding 2: Color in the Lockup Pipeline

### Current State

`assembleLockup` accepts `palette: { ink: string, paper: string }` and applies `palette.ink`
as a single fill to the mark path:

```js
// assemble-lockup.mjs:182
`    <path d="${markPathD}" fill="${palette.ink}"/>`,
```

### (a) Full-Moss Mark

A full-Moss mark uses `#5E9E84` for the entire `markPathD`. The only change needed is passing
`palette: { ink: "#5E9E84", paper: "#FAFBFC" }` to `assembleLockup`. The existing single-fill
path element handles this correctly.

**BUT:** `lintMonochromeDeriv` will cull it immediately — `#5E9E84` has HSV saturation ≈ 0.405,
far above the 0.15 threshold. See Research Finding 3 for the correct approach.

### (b) Two-Tone Mark (e.g., top step in Moss, rest in Ink)

`b-step.mjs generate()` returns a single `markPathD` string — one SVG path `d` value
containing all N step rectangles as subpaths separated by `M` commands:

```
M 0,21.6 h 7.2 v 18.4 h -7.2 Z  M 7.2,18.0 h 7.2 v 22.0 h -7.2 Z  ...
```

There is no per-step color information in this string; it is one atomic fill region.

**Options for two-tone:**

**Option A — Split `generate()` output into per-step subpaths:**
Modify `b-step.mjs` to return `{ steps: [{ pathD, stepIndex }] }` in addition to the combined
`markPathD`. `assembleLockup` receives a `fills: string[]` array and emits one `<path>` per
step with the correct fill. This is the cleanest approach but requires a protocol change in
`generate()`, `buildStandardCandidate()`, and `assembleLockup()`.

**Option B — Pass a `markElements` array to `assembleLockup` (pre-built path elements):**
`generate-r2.mjs` calls `generate(config)` then splits the returned `markPathD` into
per-subpath strings (split on `M ` with a careful parser), pairs them with a fills array, and
builds `<path d="..." fill="..."/>` strings. `assembleLockup` accepts an optional
`markElements: string[]` override in place of `markPathD` + a single fill.

**Option C — Minimal: treat the top N steps as a separate overlaid path:**
Since steps are stacked ascending, the topmost step is step index `steps-1` in `b-step.mjs`
(the shortest bar, rightmost column). `generate()` could return a separate `accentPathD` for
just the top step alongside the full `markPathD` (all steps in Ink). `assembleLockup` renders
the base mark in Ink and overlays the accent path in Moss. This is the minimal change.

**Recommendation: Option C.** Add a single optional output field `accentPathD` to
`b-step.mjs generate()` when a config sets `accentStep: true`. `assembleLockup` gets an
optional `accentFill` palette key. This is a two-function edit that introduces zero protocol
changes for callers not using color:

```js
// b-step.mjs — add to generate() return when config.accentStep is set:
return {
  markPathD,      // all steps combined — used as base, filled with palette.ink
  accentPathD,    // top step only — filled with palette.accentFill (Moss)
  markWidth,
  markHeight,
};

// assemble-lockup.mjs — in the mark <g>:
`    <path d="${markPathD}" fill="${palette.ink}"/>`,
accentPathD ? `    <path d="${accentPathD}" fill="${palette.accentFill ?? palette.ink}"/>` : "",
```

The top step's rectangle is simply `pathParts[steps - 1]` from the existing loop — trivially
extractable.

[VERIFIED: repo source, b-step.mjs generate() + assemble-lockup.mjs assembleLockup()]

---

## Research Finding 3: Monochrome-Derivability for Color Variants

### The Problem

`lintMonochromeDeriv` checks raw hex values in the SVG source and fails any color with HSV
saturation > 0.15. Moss #5E9E84: R=94, G=158, B=132; max=158, min=94; sat=(158-94)/158 = 0.405.
This means ANY Moss-colored candidate is unconditionally culled pre-gallery.

The **intent** of the lint (from the jsdoc and the CONTEXT.md code insight) is:
"mark survives mono conversion" — i.e., the mark's structure (steps) is not hue-dependent and
would still read as distinct shapes when desaturated. A Moss-filled staircase desaturates to a
mid-grey staircase — perfectly legible. The intent is NOT "the SVG must already be greyscale."

### Recommended Solution: Two-variant approach per color candidate

Each color candidate generates **two SVG files**:
1. The **color variant** SVG — fills use brand palette colors (Moss, etc.)
2. A **mono-derived variant** SVG — produced by mapping the color palette to greyscale
   equivalents per a declared `monoMap`, then linted and rendered as the 8th tile replacement

**Concrete implementation:**

A. Each Round 2 config declares a `monoMap: { [hex]: string }` that maps its color fills to
   greyscale equivalents:
   ```js
   // Example for full-Moss config:
   monoMap: { "#5E9E84": "#818181" }
   // Example for two-tone Ink+Moss:
   monoMap: { "#5E9E84": "#818181", "#181818": "#181818" }
   ```
   The greyscale equivalent for Moss (#5E9E84) is computed as perceived luminance:
   L = 0.2126×94 + 0.7152×158 + 0.0722×132 ≈ 131.5 → #848484 (use #818181 as rounded).

B. `generate-r2.mjs` builds both the color SVG and the mono-derived SVG (by substituting
   `monoMap` colors before calling `assembleLockup` a second time with the grey fills).

C. The **lint runs on the mono-derived SVG**, not the color SVG:
   - `lintMonochromeDeriv` passes because the mono-derived SVG uses only grey fills (sat = 0)
   - `lint16pxLegibility` runs on the mono-derived PNG at 16px
   - `lintNoRectBackground` and `lintNoSubtitle` are color-agnostic, run on either

D. `render-matrix.mjs` renders the color SVG for all tiles except the `mono` tile.
   The `mono` tile uses the pre-computed mono-derived SVG (not a CSS grayscale filter, which
   is imprecise for design review — the declared mapping shows exactly what Moss maps to).

E. `lintMonochromeDeriv` gets an updated call in `lintCandidate` that accepts an optional
   `monoSvgString` override:
   ```js
   // lintCandidate — change:
   const svgForMonoLint = candidate.monoSvgString ?? svgString;
   const monoPassed = lintMonochromeDeriv(svgForMonoLint);
   ```
   When `monoSvgString` is provided, the lint checks the mono-mapped variant (which will pass
   because its fills are grey). When absent, it falls through to the original behavior,
   preserving backward compatibility for Ink-only candidates.

**Why not just skip the mono lint for color candidates?** The lint's value is precisely that it
forces color candidates to prove their structure survives mono conversion. Skipping it would
weaken the brand constraint. Linting the declared mono mapping preserves the intent.

**What the jsdoc currently says (WR-05, false):** "Brand colors (#111418, #24303B, #FAFBFC,
#E9EEF2) all have saturation < 0.15." This is incorrect — #111418 has sat ≈ 0.29, #24303B
has sat ≈ 0.39. The generated SVGs use `#181818` (sat = 0), not `#111418`. The jsdoc must be
corrected as part of this work (D-182-13: fix what the pipeline exercises). The lint's
CONTRACT (sat > 0.15 fails) is correct for its purpose; only the jsdoc description of brand
colors is wrong.

[VERIFIED: repo source, lint.mjs lintMonochromeDeriv() + 181-REVIEW.md WR-05]

---

## Research Finding 4: 16px Legibility for B4-Family

### B4's Weakness

B4 config: `{ steps: 6, stepHeight: 0.18, stepWidth: 0.18, curvature: 0 }`.

At `BASE_UNIT = 40`:
- `sw = 40 × 0.18 = 7.2 units`
- `sh = 40 × 0.18 = 7.2 units`
- Total mark: `43.2 × 43.2` in mark-local space

After scaling to cap height (≈ 720 units at fontSize=1000):
- `s = 720 / 43.2 ≈ 16.67`
- Each step width in viewBox space: `7.2 × 16.67 ≈ 120 units`

At 16px render, the full mark width (≈ `43.2 × 16.67 = 720 units`) maps to roughly `16 × (markScaledW / totalW)` pixels. Total lockup width ≈ 3900 units; mark portion ≈ 720 / 3900 ≈ 18.5% of 16px = ~3 pixels for the entire mark. At 3 pixels wide, 6 columns of 0.5px each are indistinguishable. This produces the "merging into a boxy shape" effect.

### Structural Variants for Round 2

Round 2 must include at least one variant addressing the 16px weakness WITHOUT branching to
a size-specific mark (that is Phase 183's concern). The goal is ONE geometry that works at
all sizes.

**Variant family R2-B4a — Chunkier proportions (5 steps, wider bars):**
`{ steps: 5, stepHeight: 0.22, stepWidth: 0.22, curvature: 0 }`
- Mark: `5 × 8.8 = 44 units` wide (similar total mark width)
- Each step: `8.8 × 16.67 = 147 units` → at 16px renders to ~0.7px per step
- With 5 steps, each column gets more horizontal space → less merging
- Trades B4's "dense interval grid" aesthetic for B1's robustness
- This is the "chunkier 5-step compromise between B1 and B4" suggested in CONTEXT.md D-182-02

**Variant family R2-B4b — Reduced steps, increased step height/width ratio:**
`{ steps: 4, stepHeight: 0.22, stepWidth: 0.26, curvature: 0 }` (closer to B1 but sharper)
- 4 wider steps but without B1's curvature (stays B4's hard-edge aesthetic)
- More B1-like at 16px but retains the crisp no-curvature character

**Variant family R2-B4c — Same 6 steps, increased contrast between steps:**
The 16px problem is partly merging (adjacent columns blend). A gap between steps (even 0.5
units) might create visual separation. `b-step.mjs` does not currently support inter-step
gaps — adding `gapFraction: 0.08` (8% of step width left as space) is a new knob.
- Risk: "gaps" between steps might read as noise at 16px; needs empirical verification
- Could break the "staircase silhouette" reading at larger sizes

**Recommendation for the variant matrix:** Prioritize R2-B4a (5-step chunkier) as the primary
B4 weakness fix. R2-B4b is the cleaner "B1 without rounding" test. R2-B4c (gap knob) is the
most speculative and can be omitted if combinatorics exceed 9 slots.

[VERIFIED: repo source, b-step.mjs + 181-REVIEW.md IN-04]

---

## Research Finding 5: Moss Contrast on Light and Dark Backgrounds

### Contrast Table Evidence

From `artifacts/contrast-table.txt` (Phase 180, HIGH confidence):

| Pair | Contrast Ratio | WCAG Level |
|------|---------------|-----------|
| Paper (#FAFBFC) vs Moss (#5E9E84) | 3.03:1 | AA-large |
| Ink (#111418) vs Moss (#5E9E84) | 5.89:1 | AA-body |

Note: the contrast table gives Ink vs Moss = 5.89:1, meaning **Moss-on-Ink-dark = 5.89:1**
(since contrast is symmetric). This is above AA-body (4.5:1).

**For the ink-dark tile:** A full-Moss mark on Ink (#111418) background achieves 5.89:1 — well
above the legibility threshold. No problem there.

**For the paper-light tile:** A full-Moss mark on Paper (#FAFBFC) achieves 3.03:1. The 16px
favicon legibility lint uses `CR_THRESHOLD = 3.0`. The Moss-on-Paper pair is at the threshold
boundary (3.03:1 measured at full saturation on a solid pixel; anti-aliased edge pixels at
16px will produce mixed-colour pixels with lower contrast than the true value). At 16px,
the measured corner-sample CR from the PNG will be lower than 3.03:1.

**Implication:** Full-Moss variants may fail the 16px legibility lint on paper-light. This is
NOT a threshold-tuning problem (D-182-12: do not tune thresholds to explain away). It is a
genuine contrast problem: Moss is a mid-range green that does not have high contrast against
Paper. The BRAND-DNA usage rule already says "Moss: UI states, icons, large text only on light
surfaces (≥ 24px or ≥ 18.67px bold)."

**Consequence for pipeline design:** The 16px favicon tile for full-Moss should be rendered
against the **Ink-dark background** (where contrast is 5.89:1), or the pipeline must accept
that full-Moss variants will be 16px-culled on paper-light. The most principled approach:

- Run the 16px favicon legibility lint on the **ink-dark** 16px tile for color variants, since
  Moss is designed for use on dark surfaces at small sizes
- The paper-light 16px tile is still rendered and shown in the gallery for the user to judge
  visually, but the lint gate uses ink-dark for color variants

OR: Keep the paper-light lint gate as-is and let full-Moss 16px variants fail. This sends an
honest signal: a full-Moss mark does not pass 16px legibility on a light background. Two-tone
variants (Ink+Moss) pass on paper-light because the base is still `#181818` ink on paper.

**Recommendation:** Use the existing lint gate (paper-light 16px). Full-Moss candidates that
fail the 16px lint are culled with an explicit reason. The gallery still shows them in all
other tiles. Add a note in the generate log: "full-Moss marks may fail 16px-legibility on
paper-light — this is correct per BRAND-DNA (Moss is large-text only on light surfaces)."
Two-tone (Ink base + Moss accent) variants will pass because the majority fill is Ink.

### INK_DARK_COLOR_MAP Extension for Moss

The current map in `render-matrix.mjs`:
```js
const INK_DARK_COLOR_MAP = {
  "#181818": "#FAFBFC",   // dark ink → paper
  "#FAFBFC": "#111418",   // paper knockout → dark bg
  "#E9EEF2": "#2A333C",   // fog knockout → dark mid-tone
};
```

For Moss-colored SVGs in the ink-dark tile, Moss (#5E9E84) should remain Moss or be brightened
slightly. Options:
- **Keep Moss as-is:** Moss on Ink-dark is 5.89:1 — passes AA-body. No swap needed; Moss is
  already the "correct" ink-dark color for a Moss mark.
- **Swap to lighter Moss:** #7BC4A8 (brighter) — not in brand palette; avoid.

**Recommendation:** Add `"#5E9E84": "#5E9E84"` (no-op identity mapping) to `INK_DARK_COLOR_MAP`
to make the Moss-on-dark handling explicit. No color transformation needed — Moss reads fine
on Ink-dark already.

For the ink-dark tile when the base mark is `#181818` (Ink) on dark bg, the existing map
already handles the swap (#181818 → #FAFBFC). For two-tone marks with both `#181818` and
`#5E9E84` fills: the Ink portions flip to Paper (white), the Moss portions stay Moss. This
produces a two-tone Paper+Moss mark on an Ink-dark background — visually coherent.

[VERIFIED: repo source artifacts/contrast-table.txt, render-matrix.mjs INK_DARK_COLOR_MAP]

---

## Research Finding 6: Round Loop Mechanics

### GSD Plans Are Static — Rounds Are Dynamic

GSD plans are authored once and executed linearly. They cannot branch based on user verdicts
at runtime. The convergent round loop (user judges → append ledger → next round or done) is
fundamentally a sequential human decision loop, not a static plan.

### How 181 Structured Its Checkpoint (181-07-PLAN.md pattern)

181's plan 07 was the checkpoint plan: "user opens gallery, picks winners, pastes verdict."
It was a single short plan with one user-facing task and no code changes. The verdict was
delivered conversationally (not via the gallery button), transcribed by the agent, and became
R1-C1..C4.

### Recommended Round Loop Structure for 182

**One plan per round.** Structure:

- **182-02-PLAN.md** — "Round 2 pipeline run": generates 6–9 variants, renders gallery,
  final task is `checkpoint:human-verify` — user views `round-2-gallery.html` and delivers verdict.
  Agent appends verdict at `<!-- ROUND-2-APPEND-BELOW -->` in 181 TOURNAMENT.md.
  End of plan: agent poses the explicit "extend or lock?" question:
  - If user locks → skip to 182-FINAL plan (freeze winner, record geometry)
  - If user extends → 182-03-PLAN.md authored

- **182-03-PLAN.md** (authored only if Round 2 ends without lock) — "Round 3 pipeline run":
  same structure, 6–9 variants derived from Round 2 verdict. After 3 rounds (Round 2 = first
  convergent, Round 3 = second), the explicit "settle-or-extend" question fires regardless of
  user desire: "3 rounds complete — lock [leading candidate] or authorize one more round?"

- **182-FINAL-PLAN.md** (authored when user locks) — "Lock winner": writes final TOURNAMENT.md
  entry with winner ID + frozen geometry for Phase 183 consumption.

**Why not a looping plan?** GSD executor follows a static plan; the planner cannot know in
advance which round will produce a lock. A one-round-per-plan structure means:
- The planner authors 182-02 now (all research is known)
- 182-03 is authored only if/when 182-02 returns without a lock (the 182-03 planner reads the
  Round 2 TOURNAMENT.md entry as its context)
- Max 3 convergent rounds = max 3 plans (02, 03, 04) + 1 final plan = 4 plans total; typically 2-3

**Settle-or-extend question format (D-182-04 schema):**
```
Round N complete. Candidates: [R2-5 (B4 5-step Moss), R2-7 (B4 two-tone)]
Leading: R2-5 (no change notes, marked winner)

OPTIONS:
  LOCK   — R2-5 is the final winner; Phase 182 closes
  EXTEND — one more round of variants from R2-5
  SETTLE — lock R2-5 now without another round (same as LOCK, explicit acknowledgement)
```

[ASSUMED: this loop structure matches the D-11 verdict schema from 181; adapt if user prefers a different format]

---

## Research Finding 7: REVIEW.md Triage for Round 2 Pipeline

Per D-182-13: fix what the Round 2 pipeline exercises. The 18 findings map to:

### MUST FIX (Round 2 exercises these directly)

| Finding | Severity | Why Round 2 Exercises It |
|---------|----------|-------------------------|
| **WR-01** (smoke-mode cull clobbers index.json) | Warning | Round 2 smoke runs should not corrupt the index |
| **WR-05** (jsdoc wrong; default palette ink would fail lint) | Warning | Color variants will use non-#181818 fills; jsdoc must be corrected to prevent confusion; `assembleLockup` default palette must be fixed |
| **WR-07** (avatar-circle not circle-cropped) | Warning | Round 2 explicitly shows "avatar crop integrity" context — fix adds ~3 lines and surfaces real clipping |
| **IN-04d** (b-step.mjs comment: "top corners only" vs "full rounded rect") | Info | b-step.mjs is being modified for accentStep; fix the stale comment while editing |

### SHOULD FIX (cheap, prevents confusion during Round 2 debugging)

| Finding | Severity | Rationale |
|---------|----------|-----------|
| **WR-02** (gap-ratio lint tautological) | Warning | Not wrong, just always-pass; low noise risk; defer unless it masks a real gap issue |
| **IN-01** (dead computation `failed = ...`) | Info | Delete the 1-liner while editing generate.mjs for --output-dir |
| **IN-04a** (blank-render doc says "paper-light or 32px-favicon") | Info | Fix while reading render-matrix.mjs for INK_DARK_COLOR_MAP extension |

### DO NOT FIX IN 182 (out of scope per D-182-13)

| Finding | Reason |
|---------|--------|
| **CR-01** (Direction C arcs render as filled domes) | Direction C is dead (R1-C1). The `markGroupSvg` contract removal (not introduction of new Direction C rendering) is fine to ignore — Round 2 never generates C candidates. |
| **WR-03** (Direction D floor-regen dead code) | Direction D is dead. |
| **WR-04** (Direction D echo offset wrong coord space) | Direction D is dead. |
| **WR-06** (Direction A amplitude semantics inverted) | Direction A is dead. |
| **WR-08** (SVG active content guard) | Round 2 generates its own SVGs; no hand-edited files. Low risk. |
| **WR-09** (gallery pre onclick TypeError) | CSS user-select:all fallback works. Minor; defer. |
| **IN-02** (dead exports/imports; svgo in package.json) | Cleanup; does not affect Round 2. |
| **IN-03** (Direction D unreferenced clipPath) | Direction D is dead. |
| **IN-04b/c** (render-matrix stale comments) | Low noise risk. |
| **IN-05** (blank-render counted in 16px-lint counter) | Cosmetic reporting issue; does not affect culling logic. |
| **IN-06** (geist-spine no isMain guard) | Low risk; only fires with `--test` arg. |
| **IN-07** (viewBox float artifact, duplicate ids) | Cosmetic; harmless in the gallery. |
| **IN-08** (lint CLI mode skips 2 of 6 checks) | Round 2 invokes lint via generate.mjs pipeline, not standalone CLI. |

[VERIFIED: repo source, 181-REVIEW.md all 18 findings cross-referenced with R1-C1..C4 locked decisions]

---

## Recommended Variant Matrix (6–9 candidates for Round 2)

Combinatorics: 3–4 structures × 3 color treatments = 9–12 raw. Prune to 6–9.

### Structures (4)

| ID | Config | Purpose |
|----|--------|---------|
| R2-S1 | B4 exact: `{steps:6, sh:0.18, sw:0.18, curv:0}` | Baseline; user's primary pick |
| R2-S2 | B4 chunkier: `{steps:5, sh:0.22, sw:0.22, curv:0}` | Fix 16px weakness; compromise B1/B4 |
| R2-S3 | B4 wider: `{steps:4, sh:0.22, sw:0.26, curv:0}` | B1 step-count, B4 crispness |
| R2-S4 | B1 exact: `{steps:4, sh:0.25, sw:0.25, curv:0.05}` | Runner-up baseline; 16px benchmark |

### Color Treatments (3)

| ID | Treatment | Assembler Palette |
|----|-----------|------------------|
| R2-C-ink | Full Ink (#181818) | `{ink:"#181818"}` — baseline, no color |
| R2-C-moss | Full Moss (#5E9E84) | `{ink:"#5E9E84"}` — may fail 16px on paper-light |
| R2-C-2t | Two-tone: Ink base + Moss accent (top step) | `{ink:"#181818", accentFill:"#5E9E84"}` |

### Matrix (pruned to 7 candidates)

| Candidate | Structure | Color | Rationale |
|-----------|-----------|-------|-----------|
| R2-1 | R2-S1 (B4 exact) | Ink | Baseline reference for B4 at correct scale |
| R2-2 | R2-S2 (B4 chunkier 5-step) | Ink | Tests 16px fix without color distraction |
| R2-3 | R2-S3 (B4 4-wide) | Ink | Sharp B1 alternative |
| R2-4 | R2-S4 (B1 exact) | Ink | Runner-up baseline |
| R2-5 | R2-S2 (B4 chunkier) | Full Moss | Primary color test on the stronger structure |
| R2-6 | R2-S2 (B4 chunkier) | Two-tone | Subtler color; likely 16px winner |
| R2-7 | R2-S4 (B1 exact) | Two-tone | B1 with color accent; backup |

7 candidates: 4 structural baselines (Ink) + 3 color variants on the most promising structure.
Omit R2-S1 Moss/two-tone (known 16px weakness not fixed) and R2-S3 Moss (three color×structure
combos exceed the 9 cap and S3 is speculative).

[ASSUMED: final variant selection is Claude's Discretion per CONTEXT.md; this matrix is a
recommendation, not a locked commitment]

---

## "Increasingly Real Contexts" Copy (D-182-08)

Round 2 adds actual copy to the readme-header and social-card tiles (ROADMAP SC-1). Recommended
copy per BRAND-DNA voice:

**readme-header tile** (800×120, logo at ~24px height):
Background should be the actual GitHub README header context: a white/light page. Use the
standard lockup. The tile already renders the lockup; no copy overlay needed unless the tile is
extended to show "accrue" with a sub-badge. Keep tile as-is for Round 2 — the "real context"
is provided by the actual dimensions, not added text.

**social-card tile** (600×315): Add a background that suggests the social card layout:
```
[logo]  accrue — Elixir billing library for Phoenix
        hex.pm/packages/accrue
```
The tile HTML wrapper should include these text strings in Geist. This exercises the actual
social-card use case and surfaces spacing/weight issues the abstract tile doesn't reveal.

[ASSUMED: exact copy is Claude's Discretion; should match BRAND-DNA voice: "Elixir billing library for Phoenix"]

---

## Common Pitfalls (from 181 Fix History)

### Pitfall 1: Coordinate-Space Bug (Fix 3 — the most dangerous)

**What goes wrong:** Mark renders as a few dots; blank-render guard fires.
**Root cause:** Three specific bugs in assemble-lockup.mjs:
  (a) Per-glyph translate loop doubles the already-baked glyph X offsets
  (b) Glyphs at y=0 baseline render above viewBox (all ascender ink at negative y)
  (c) Mark not scaled from ~40-unit space to cap-height space
**How to avoid:** The coordinate-space contract in `assemble-lockup.mjs` header is now
authoritative. Any new `assembleLockup` call variant (e.g., for multi-fill marks) must
preserve: (1) single `<g>` for all glyphs, (2) mark scaled by `s = capHeight/markHeight`,
(3) `BASELINE = capHeight * 1.1` for the glyph group translate. Do NOT add per-element
translate loops.
**Warning sign:** blank-render guard fires on paper-light tile (< 0.5% dark pixel coverage).
Investigate SVG source before tuning any threshold.

### Pitfall 2: Unused Rendering Contract (CR-01 pattern)

**What goes wrong:** A generator emits a field (e.g. `accentPathD`) that `assembleLockup`
never consumes. The SVG renders as if the accent does not exist. The gallery looks like an
Ink-only mark while the config claims two-tone.
**How to avoid:** Per D-182-11: every new generator output field must be wired end-to-end and
verified in a rendered PNG before the checkpoint. After adding `accentPathD`, visually inspect
the rendered paper-light PNG and confirm the top step is Moss-colored.

### Pitfall 3: Threshold Tuning to Explain Away Bad Renders

**What goes wrong:** 16px legibility lint culls candidates that look visually acceptable.
Agent lowers `CR_THRESHOLD` from 3.0 to a smaller value to "fix" the pipeline.
**Root cause documented:** This exact error occurred in 181 (threshold lowered to 1.75 based
on broken renders). The 1.75 was based on near-blank images from the coordinate-space bug.
**How to avoid:** Per D-182-12: if many candidates fail the 16px lint, READ the PNGs first.
If the renders look visually correct at 16px but measure low CR, the threshold may need one
evidenced adjustment — but do it with a justification written in the SUMMARY, not silently.
For Moss-on-Paper candidates, a low CR at 16px is EXPECTED (contrast is only 3.03:1) and
should not trigger threshold tuning.

### Pitfall 4: Smoke-Mode Index Clobber (WR-01)

**What goes wrong:** A smoke run with one blank-render candidate (or any cull) rewrites
`candidates/index.json` with only the smoke subset, destroying the full candidate list.
**How to avoid:** Fix WR-01 before running any smoke test. The fix is to read from the full
on-disk index before computing surviving candidates in smoke mode.

### Pitfall 5: Visual Verification Before Checkpoint (D-182-10)

**What goes wrong:** The 181 coordinate-space bug shipped a broken gallery because nobody
verified the rendered PNGs. The user judged B4 and B1 based on (eventually corrected) renders,
but the intermediate gallery was broken.
**How to avoid:** After the pipeline run and before the user checkpoint, the executor MUST Read
at least 2–3 PNGs from `screenshots/` to confirm (a) mark is visible, (b) color fills are
correct, (c) ink-dark tile is light-on-dark. This is a mandatory step in the Round 2 plan.

### Pitfall 6: lintMonochromeDeriv Culls Color Variants Pre-Gallery

**What goes wrong:** All Moss-colored SVGs are culled in generate.mjs Step 4 (pre-gate lint)
before `render-matrix.mjs` ever runs. Gallery has 0 color candidates.
**How to avoid:** Implement the mono-derived variant approach (Research Finding 3) BEFORE
running generate.mjs. The lint must be applied to the mono-derived SVG, not the color SVG.

### Pitfall 7: INK_DARK_COLOR_MAP Misses Moss — Moss Disappears on Dark Tile

**What goes wrong:** The ink-dark tile swaps `#181818 → #FAFBFC` but Moss `#5E9E84` has no
mapping. On Ink-dark (#111418) background: Moss-on-Ink is 5.89:1 (fine). However for
TWO-TONE marks where the base is `#181818`: the base flips to `#FAFBFC` (paper/white), and
the Moss accent stays Moss. This gives a Paper+Moss mark on dark bg — legible, but needs
explicit review. Add Moss to INK_DARK_COLOR_MAP as an explicit identity entry; verify visually.

---

## Code Examples

### Pattern 1: generate-r2.mjs — 182-specific generator wrapper

```js
// .planning/phases/182-tournament-convergent-refinement/harness/generate-r2.mjs
// Thin wrapper: imports from 181 harness, overrides direction configs
// Run: node .../182/harness/generate-r2.mjs --output-dir .../182

import path from "path";
import { fileURLToPath } from "url";

// Override path resolution BEFORE importing generate.mjs functions
// (generate.mjs PHASE_DIR is determined by __dirname; we use --output-dir arg instead)

// Import only the harness primitives, not generate.mjs main()
import { loadGeistFont, extractGlyphs, getCapHeight } from
  "../../181-svg-pipeline-tournament-round-1-divergent/harness/geist-spine.mjs";
import { assembleLockup } from
  "../../181-svg-pipeline-tournament-round-1-divergent/harness/assemble-lockup.mjs";
import { lintCandidate } from
  "../../181-svg-pipeline-tournament-round-1-divergent/harness/lint.mjs";
import { generate as generateB } from
  "../../181-svg-pipeline-tournament-round-1-divergent/harness/dirs/b-step.mjs";

// Round 2 configs — all B direction
export const R2_CONFIGS = [
  { id: "R2-1", steps: 6, stepHeight: 0.18, stepWidth: 0.18, curvature: 0,
    colorTreatment: "ink",  monoMap: {}, rationale: "B4 exact — ink baseline" },
  { id: "R2-2", steps: 5, stepHeight: 0.22, stepWidth: 0.22, curvature: 0,
    colorTreatment: "ink",  monoMap: {}, rationale: "B4 chunkier 5-step — 16px fix candidate" },
  // ... etc
];
```

Note: the wrapper pattern avoids copy-pasting the full generate.mjs main loop. Whether to
inline the main loop or use the `--output-dir` patch on the original is a planner decision.
The `--output-dir` patch is simpler for the executor.

### Pattern 2: assembleLockup with accentFill (two-tone)

```js
// In assemble-lockup.mjs — extend the mark <g> block:
const markFillEl = `<path d="${markPathD}" fill="${palette.ink}"/>`;
const accentEl = (config.accentPathD && palette.accentFill)
  ? `\n    <path d="${config.accentPathD}" fill="${palette.accentFill}"/>`
  : "";

// In the SVG output:
`  <g id="mark" transform="translate(${markTx},${markTy}) scale(${s.toFixed(6)})">`,
`    ${markFillEl}${accentEl}`,
`  </g>`,
```

### Pattern 3: lintCandidate with monoSvgString override

```js
// In lint.mjs lintCandidate():
const svgForMonoLint = candidate.monoSvgString ?? candidate.svgString;
const monoPassed = lintMonochromeDeriv(svgForMonoLint);
record("monochrome-derivable", monoPassed,
  "saturated fill — mono-derived variant also fails (check monoMap config)");
```

### Pattern 4: INK_DARK_COLOR_MAP extension for Moss

```js
// In render-matrix.mjs:
const INK_DARK_COLOR_MAP = {
  "#181818": "#FAFBFC",   // dark ink → paper
  "#FAFBFC": "#111418",   // paper knockout → dark bg
  "#E9EEF2": "#2A333C",   // fog knockout → dark mid-tone
  "#5E9E84": "#5E9E84",   // Moss → Moss (identity; 5.89:1 on Ink-dark, already passes)
};
```

---

## Validation Architecture

### Pre-Checkpoint Verification Requirements

Per D-182-10, visual verification is mandatory before the user checkpoint. The Round 2 plan
MUST include a visual spot-check task:

| Req | Behavior | Check |
|-----|----------|-------|
| REQ-1 | Color fills render correctly | Read paper-light PNG: mark visible, Moss fill confirmed for Moss candidates |
| REQ-2 | Ink-dark tile is light-on-dark | Read ink-dark PNG: mark should be Paper/white on dark background |
| REQ-3 | 16px favicon is readable | Read 16px-favicon PNG: steps individually distinguishable for 5-step candidates |
| REQ-4 | Mono tile reflects declared monoMap | Read mono PNG: Moss candidates show grey (not green) mark |
| REQ-5 | Gallery HTML opens and shows all candidates | `grep -c "class=\"candidate\"" round-2-gallery.html` ≥ 6 |

### Pipeline Smoke Test

```bash
# Before full run, smoke test the Round 2 generate step:
node .../181/harness/generate.mjs --output-dir .../182 --smoke
# Expect: 1-2 candidates, no blank-render errors, lint-results.ndjson created
```

---

## Environment Availability

The 181 harness `node_modules` is already installed and verified working. No new npm installs
needed if the 181 harness is reused in-place (recommended).

| Dependency | Available | Version | Notes |
|------------|-----------|---------|-------|
| Node.js | ✓ | (from 181 run) | ESM modules, no version change |
| Playwright Chromium | ✓ | (installed in 181 harness/node_modules) | Already downloaded and cached |
| opentype.js | ✓ | (installed in 181 harness/node_modules) | Font loading for Geist |
| pngjs | ✓ | (installed in 181 harness/node_modules) | PNG pixel analysis |
| Geist font | ✓ | (installed in 181 harness/node_modules/geist) | Typography |

If harness is copied to 182 dir: `npm ci` in the new dir is required. Avoid.

---

## Open Questions

1. **accentStep: single top step vs. configurable step index**
   - What we know: the user said "is monochrome our style?" suggesting color accent, not full Moss
   - What's unclear: should the accent be always the topmost step, or configurable per config?
   - Recommendation: hardcode to topmost step (last in pathParts array, rightmost column) for
     Round 2. If the user wants a different accent position in Round 3, add the knob then.

2. **Social-card tile copy — should it render text via SVG `<text>` or HTML overlay?**
   - What we know: the current tile renders only the lockup SVG in a 600×315 box
   - What's unclear: adding HTML text requires a more complex tile HTML template
   - Recommendation: add a CSS overlay in the tile HTML (`position: absolute` text over the
     centered SVG). Keep it simple for Round 2; the point is to see the mark at realistic scale.

3. **Should R2 ID scheme be R2-1..R2-7 or a semantic scheme like B4-ink, B4a-moss?**
   - What we know: the CONTEXT.md leaves this as Claude's Discretion
   - What's unclear: semantic names are more readable in TOURNAMENT.md; numeric are simpler to code
   - Recommendation: use `R2-{N}` for pipeline IDs (CONFIGS id field), include the semantic name
     in the rationale string. `data-id` in the gallery HTML becomes `R2-1` etc.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Playwright Chromium binary is still cached and functional in 181 node_modules | Environment Availability | Pipeline fails at render step; fix: re-install Playwright browser |
| A2 | The `--output-dir` CLI arg approach does not conflict with any existing `process.argv` parsing in the four harness scripts | Research Finding 1 | Generate/render/gallery scripts malfunction; diagnose via stderr |
| A3 | Moss at #818181 greyscale is the correct perceptual mapping for the mono tile | Research Finding 3 | Mono tile looks lighter/darker than expected; adjust monoMap value |
| A4 | Round 2 will not need more than 9 candidates (combinatorics fit in 7) | Variant Matrix | If user wants more combinations, adjust matrix to add 2 more within cap |
| A5 | The settle-or-extend question format satisfies the user's loop preference | Research Finding 6 | User wants a different checkpoint format; adapt the gallery verdict block |

---

## Sources

### Primary (HIGH confidence — verified from repo source)
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/b-step.mjs` — path construction, CONFIGS, generate() return shape
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/assemble-lockup.mjs` — coordinate contract, palette shape, assembleLockup() implementation
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/lint.mjs` — lintMonochromeDeriv(), lintCandidate(), CR_THRESHOLD = 3.0
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/generate.mjs` — PHASE_DIR hardcoding, buildStandardCandidate(), buildLockupSvg()
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/render-matrix.mjs` — PHASE_DIR hardcoding, INK_DARK_COLOR_MAP, buildTileHtml(), smoke-mode index clobber (WR-01)
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/build-gallery.mjs` — PHASE_DIR hardcoding, GALLERY_PATH hardcoded filename
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/181-REVIEW.md` — all 18 findings with fix snippets
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/181-06-SUMMARY.md` — 4 post-completion fixes, coordinate-space contract
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/TOURNAMENT.md` — Round 1 verdict, R1-C1..C4, ROUND-2-APPEND-BELOW marker
- `.planning/phases/180-brand-audit-dna-lock/artifacts/contrast-table.txt` — Moss vs Paper 3.03:1, Ink vs Moss 5.89:1
- `.planning/phases/180-brand-audit-dna-lock/BRAND-DNA.md` — Moss usage rule (large text/icons on light surfaces only), palette
- `.planning/phases/182-tournament-convergent-refinement/182-CONTEXT.md` — all locked decisions D-182-01..D-182-13

### Tertiary (LOW confidence — derived from math, not verified against a rendering)
- Moss greyscale mapping: #818181 derived from luminance formula L≈131.5/255; exact perceptual
  mapping should be verified against the rendered mono tile before the checkpoint

---

## Metadata

**Confidence breakdown:**
- Harness parameterization: HIGH — all scripts read and the hardcoding pattern is unambiguous
- Color pipeline design: HIGH — assemble-lockup.mjs and b-step.mjs fully read
- Mono lint semantics: HIGH — lint.mjs source read; WR-05 confirms the jsdoc is wrong
- Contrast math: HIGH — contrast-table.txt is authoritative
- Round loop mechanics: MEDIUM — structure is recommended, not derived from a fixed GSD constraint
- Variant matrix: MEDIUM (Claude's Discretion) — combinatorics are sound; user judgment final

**Research date:** 2026-06-12
**Valid until:** Phase 182 completion (no external dependencies; all findings are from stable committed code)
