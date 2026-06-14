# Phase 182 Winner Freeze

**Locked:** 2026-06-13
**Winner:** R2-7
**Round:** Round 2

## Generator Config (Phase 183 authoritative source)

```js
// b-step-r2.mjs config for the locked winner
{
  id: "R2-7",
  steps: 4,
  stepHeight: 0.25,
  stepWidth: 0.25,
  curvature: 0.05,
  colorTreatment: "two-tone",
  monoMap: { "#5E9E84": "#818181" },
  accentStep: true,
  rationale: "B1 exact with Ink base + Moss accent on top step — B1 robustness at all sizes, with brand-color accent"
}
```

## Computed Geometry (at BASE_UNIT=40)

| Property | Value |
|----------|-------|
| Step width (sw) | 10 units (0.25 × 40) |
| Step height (sh) | 10 units (0.25 × 40) |
| Mark width | 40 units (4 × 10) |
| Mark height | 40 units (4 × 10) |
| Corner radius (rr) | 0.5 units (min(10,10) × 0.05) |
| Scale factor (s) | capHeight / markHeight (computed at render time from Geist) |

Assembled geometry (confirmed from harness output and TOURNAMENT.md):
`markWidth: 40, markHeight: 40, viewBox: "0 0 40 40"`

`accentPathD: M 30.500,0.000 h 9.000 a 0.5,0.5 0 0 1 0.5,0.5 v 39.000 a 0.5,0.5 0 0 1 -0.5,0.5 h -9.000 a 0.5,0.5 0 0 1 -0.5,-0.5 v -39.000 a 0.5,0.5 0 0 1 0.5,-0.5 Z`
(top/rightmost rounded step, filled Moss #5E9E84)

## Color Fills

| Element | Color |
|---------|-------|
| Mark base (ink) | #181818 (steps 1–3) |
| Mark accent (accentFill) | #5E9E84 (Moss — step 4, topmost/rightmost) |
| Logotype | #181818 (greyscale; sat=0; passes lintMonochromeDeriv) |
| Paper background | #FAFBFC |
| monoMap | #5E9E84 → #818181 |

## Lockup Parameters

- gapRatio: 0.15 (mark-to-logotype gap as fraction of cap height)
- viewboxH: capHeight × 1.4
- markIsTypemark: false
- Logotype: "accrue" in Geist (R1-C3 — locked)

## Self-Review Scores (from self-review-r2.ndjson)

| Dimension | Score | Note |
|-----------|-------|------|
| legibility-16px | 3 | Two-tone 4-step rounded (B1 + Moss accent): ink base passes at 16px on paper-light; rounded corners soften at small scale; 4 steps reduce column density; Moss accent on top step adds a color differentiation cue at favicon scale |
| monochrome-survival | 3 | monoSvgString maps Moss accent to grey (#818181); mono tile shows grey accent step vs dark base rounded steps; two-tone character in greyscale confirmed; rounded corners survive to mono without issue |
| avatar-crop-integrity | 3 | 4 rounded steps with Moss accent in circle crop: B1's proven circle-crop strength + brand accent color; rounded corners give the mark a slightly friendlier profile in the circle without losing the stepped character |
| brand-fit | 3 | B1's robustness with Moss brand accent on the topmost step; ascending gesture (R1-C2) preserved; color emphasis on the highest step reinforces the stepping-up metaphor; Accrue brand green as an accent point reads as 'well-made dev tooling' not finance iconography |

## Lint Status

All pre-gate lints passed:
- valid-svg: PASS
- no-rect-background: PASS
- gap-ratio: PASS
- 16px-legibility: PASS (ink base #181818 on paper #FAFBFC, contrast ~17:1; Moss accent on topmost step is supplementary, not the primary legibility path)
- monochrome-derivable: PASS (linted on mono-derived SVG via monoMap; monoSvgString confirmed via R2-7/mono.png)
- no-subtitle: PASS

Note: R2-5 (full-Moss mark) was culled by 16px legibility lint (Moss-on-Paper 3.03:1 — expected per BRAND-DNA; threshold NOT tuned). R2-7's two-tone design avoids this issue: the ink base provides primary contrast, Moss is accent-only.

## Phase 183 Instructions

Phase 183 reads this file to:
1. Import `generate` from `harness/dirs/b-step-r2.mjs` and call `generate({steps: 4, stepHeight: 0.25, stepWidth: 0.25, curvature: 0.05, accentStep: true})` to obtain `{ markPathD, accentPathD, markWidth, markHeight }`
2. Load Geist via `geist-spine.mjs` and extract "accrue" glyphs
3. Call `assembleLockup(markPathD, glyphs, { markWidth, markHeight, capHeight, gapRatio: 0.15, viewboxH: capHeight*1.4, markIsTypemark: false, palette: { ink: "#181818", paper: "#FAFBFC", accentFill: "#5E9E84" }, accentPathD })` to produce the master lockup SVG
4. Apply `svgo` optimization and outline all paths (no text elements)
5. Derive the full logo system (see Phase 183 plan for the complete file set): light-mode lockup, dark-mode lockup, mark-only (color), mark-only (mono, via monoMap), favicon variants (16px, 32px), avatar-circle crop, social card

The `b-step-r2.mjs` generator and the 181 harness `assemble-lockup.mjs` are the SSOT for mark geometry. Phase 183 MUST NOT hand-edit the path data — regenerate from the config above.

---
*Phase 182 closed. Phase 183: Logo System Production.*
