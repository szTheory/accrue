---
phase: 183-logo-system-production
plan: "02"
subsystem: brandbook/logo
tags: [logo, svg, svgo, geist-mono, social-card, subtitle, resvg]

dependency_graph:
  requires:
    - phase: 183-01
      provides: "harness bootstrap — package.json, svgo.config.mjs, geist-spine-mono.mjs"
    - phase: 181-svg-pipeline-tournament-round-1-divergent
      provides: "geist-spine.mjs, assemble-lockup.mjs coordinate contract"
    - phase: 182-tournament-convergent-refinement
      provides: "b-step-r2.mjs frozen R2-7 generator (4-step mark, Moss accent)"
  provides:
    - "generate-logo-suite.mjs — 13-SVG production orchestrator (fixed)"
    - "All 13 SVG brand artifacts in brandbook/logo/ (regenerated, verified)"
    - "accrue-social-card.svg — social card with all glyphs preserved under SVGO"
    - "accrue-logo-subtitle.svg — subtitle variant with full viewBox width for unclipled subtitle"
  affects:
    - "183-03 (raster export — reads all 13 SVGs)"
    - "183-04 (size-matrix QA — verifies all 13 SVGs)"
    - "186 (HTML brand book — embeds all brand SVG artifacts)"

tech-stack:
  added: []
  patterns:
    - "SVGO glyph-size safety: render text paths at large font size (>=200 units) + scale() group down to target visual size — prevents mergePaths/convertPathData from collapsing small-coordinate 'i' dot+stem contours"
    - "Subtitle viewBox width expansion: max(lockupW, wordmarkLeftX + subtitleRunWidth + padding) — subtitle run may exceed wordmark width"

key-files:
  created:
    - brandbook/logo/harness/generate-logo-suite.mjs (fix commit 1ec7edd9)
    - brandbook/logo/accrue-logo.svg
    - brandbook/logo/accrue-logo-on-dark.svg
    - brandbook/logo/accrue-logo-subtitle.svg (Defect 2 fixed)
    - brandbook/logo/accrue-wordmark.svg
    - brandbook/logo/accrue-mark.svg
    - brandbook/logo/accrue-mark-on-dark.svg
    - brandbook/logo/accrue-logo-mono.svg
    - brandbook/logo/accrue-logo-mono-inverse.svg
    - brandbook/logo/accrue-mark-mono.svg
    - brandbook/logo/accrue-mark-mono-inverse.svg
    - brandbook/logo/accrue-clearspace.svg
    - brandbook/logo/accrue-social-card.svg (Defect 1 fixed)
    - brandbook/logo/favicon.svg
  modified: []

key-decisions:
  - "2026-06-13 (183-02): SVGO glyph-size rule — subtitle paths must be rendered at large font size (>=capHeight*0.42) and scale()-d down; rendering at small visual size (28px) lets mergePaths collapse 'i' contours with near-degenerate coordinates"
  - "2026-06-13 (183-02): Subtitle viewBox width must be expanded to max(lockupW, wordmarkLeftX + subtitleRunWidth + padding); width-only fix was insufficient — Geist Mono advance widths for 'Billing for Elixir apps' exceed the lockup width"

patterns-established:
  - "SVGO-safe subtitle rendering: always render at >= the large font size (subtitleFontSize = capHeight * 0.42) and use scale() transform for visual sizing"
  - "viewBox expansion: when adding content below OR to the right of a base lockup, expand BOTH height AND width as needed"

requirements-completed:
  - LOGO-04

duration: 35min
completed: "2026-06-13"
---

# Phase 183 Plan 02: SVG Production Suite Summary

**13-SVG Accrue brand artifact suite committed from frozen R2-7 config, with two post-checkpoint defects fixed — social-card subtitle glyph loss under SVGO and standalone subtitle clipping at viewBox right edge.**

## Performance

- **Duration:** 35 min (including continuation fix + visual verification)
- **Started:** 2026-06-13T15:40:00Z
- **Completed:** 2026-06-13T16:15:00Z
- **Tasks:** 2 (Task 1 committed in prior wave; Task 2 checkpoint reached; continuation fixed two defects)
- **Files modified:** 3 (generator + 2 SVG artifacts)

## Accomplishments

- `generate-logo-suite.mjs` written and run — 13 SVG brand artifacts generated from frozen R2-7 config (4-step Ink/Moss mark, Geist wordmark, accessible metadata)
- Defect 1 fixed: social-card subtitle now renders "Billing for Elixir apps" with all glyphs present — second `i` in "Elixir" preserved by rendering at large font size + scale() group
- Defect 2 fixed: standalone subtitle viewBox width expanded to accommodate the full Geist Mono run width, which exceeds the lockup width

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | Write generate-logo-suite.mjs + generate 13 SVGs | 451c02d1 | feat |
| 2 (fix) | Expand subtitle viewBox width + preserve social-card glyphs under SVGO | 1ec7edd9 | fix |

## Files Created/Modified

- `brandbook/logo/harness/generate-logo-suite.mjs` — Main orchestrator; two defect fixes applied
- `brandbook/logo/accrue-social-card.svg` — 1200×630 social card; subtitle now glyph-complete
- `brandbook/logo/accrue-logo-subtitle.svg` — Subtitle lockup; viewBox width no longer clips subtitle
- `brandbook/logo/accrue-logo.svg` — PRIMARY lockup (light bg, full color)
- `brandbook/logo/accrue-logo-on-dark.svg` — On-dark lockup
- `brandbook/logo/accrue-wordmark.svg` — Logotype only
- `brandbook/logo/accrue-mark.svg` — Mark-only (4-step, Moss accent)
- `brandbook/logo/accrue-mark-on-dark.svg` — Mark-only, dark background
- `brandbook/logo/accrue-logo-mono.svg` — Monochrome (#818181 accent)
- `brandbook/logo/accrue-logo-mono-inverse.svg` — Monochrome inverse
- `brandbook/logo/accrue-mark-mono.svg` — Mark-only monochrome
- `brandbook/logo/accrue-mark-mono-inverse.svg` — Mark-only monochrome inverse
- `brandbook/logo/accrue-clearspace.svg` — Clearspace diagram
- `brandbook/logo/favicon.svg` — Favicon (mark passthrough)

## Decisions Made

- SVGO-safe glyph rendering pattern locked: subtitle paths must be rendered at a large font size (capHeight * 0.42 ≈ 298 units at Geist's capHeight=710) and then scale()-d down using a CSS transform group. Rendering at 28px directly produces path coordinates small enough for `mergePaths` + `convertPathData` to drop subpaths — specifically the dot and stem of lowercase `i` (two M-subcontours per `i`).
- viewBox width expansion pattern locked: when a subtitle run is laid out with `translate(wordmarkLeftX, ...)`, the viewBox width must be `max(lockupW, wordmarkLeftX + subtitleRunWidth + small_padding)`. Geist Mono is monospaced and wider per-character than Geist Sans, so the subtitle consistently overflows the lockup width.

## Deviations from Plan

### Checkpoint Defects Found and Fixed (continuation from Task 2 visual review)

Two defects were identified during the Task 2 visual-fidelity checkpoint (user reviewed PNGs) and fixed in the continuation wave:

**1. [Rule 1 - Bug] Social card subtitle drops second 'i' in "Elixir" under SVGO**
- **Found during:** Task 2 checkpoint — both resvg and macOS WebKit confirmed "Elix r" rendering
- **Issue:** Social card subtitle was rendered at font size 28 (small). SVGO's `mergePaths` + `convertPathData` collapsed the near-degenerate dot+stem contours of `i` at those coordinates. Confirmed by comparing M-command count: large-font "Elixir" has more subcontours than the 28px version.
- **Fix:** Render subtitle at `subtitleFontSize` (capHeight * 0.42 ≈ 298 units), then wrap the group in `scale(28/subtitleFontSize)`. The centering X is computed in large-font units, then scaled to card units by the same factor so horizontal centering remains correct.
- **Files modified:** `brandbook/logo/harness/generate-logo-suite.mjs`, `brandbook/logo/accrue-social-card.svg`
- **Verification:** Read `/tmp/verify-social-card.png` — "Billing for Elixir apps" visible with both `i` glyphs intact
- **Committed in:** 1ec7edd9

**2. [Rule 1 - Bug] Standalone subtitle clips at viewBox right edge**
- **Found during:** Task 2 checkpoint — "Billing for Elixir apps" subtitle was visually cut off at "...Elixi"
- **Issue:** The subtitle SVG viewBox width was set to `lockupW` (the lockup width), but the Geist Mono subtitle run (`wordmarkLeftX + subtitleRunWidth`) exceeded this width. The viewport clipped the rightmost glyphs.
- **Fix:** Track `subtitleX` accumulator after all glyph advances, then set `expandedViewboxW = max(lockupW, wordmarkLeftX + subtitleRunWidth + trackingExtra * 0.5)`.
- **Files modified:** `brandbook/logo/harness/generate-logo-suite.mjs`, `brandbook/logo/accrue-logo-subtitle.svg`
- **Verification:** Read `/tmp/verify-subtitle.png` — full "Billing for Elixir apps" visible without clipping
- **Committed in:** 1ec7edd9

---

**Total deviations:** 2 auto-fixed (Rule 1 bugs, both from checkpoint review)
**Impact on plan:** Both fixes required for correctness per the visual-fidelity gate. No scope creep.

## Issues Encountered

None beyond the two checkpoint defects (documented above). Generator ran cleanly; all 13 SVGs produced in a single pass.

## Known Stubs

None. All 13 SVG artifacts are fully complete path-based brand files with accessible metadata.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes.

## Next Phase Readiness

- All 13 SVG brand artifacts committed at `brandbook/logo/` — ready for Plan 03 (raster export: PNG sizes + ICO favicon)
- `generate-logo-suite.mjs` is the stable generator; any future brand parameter changes must update the R2-7 frozen config section
- SVGO-safe glyph rendering pattern is now established and documented for Plan 04 (size-matrix QA) to test against

## Self-Check: PASSED

- [x] brandbook/logo/accrue-logo.svg exists
- [x] brandbook/logo/accrue-social-card.svg exists (Defect 1 fixed)
- [x] brandbook/logo/accrue-logo-subtitle.svg exists (Defect 2 fixed)
- [x] brandbook/logo/favicon.svg exists
- [x] All 13 SVGs present (`ls brandbook/logo/*.svg | wc -l` = 13)
- [x] No `<text>` or `@font-face` in any committed SVG
- [x] Every SVG has `<title>` (grep -c confirmed = 1)
- [x] Mono variants use #818181 not #5E9E84
- [x] Primary logo PNG confirmed: 4-step mark (Ink base, Moss top) + "accrue" wordmark — not blank
- [x] Social card PNG confirmed: "Billing for Elixir apps" with both `i` characters intact
- [x] Subtitle PNG confirmed: full subtitle visible, nothing clipped at right edge
- [x] Commits 451c02d1, 1ec7edd9 exist in git log
