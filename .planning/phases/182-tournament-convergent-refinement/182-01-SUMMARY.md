---
phase: 182-tournament-convergent-refinement
plan: "01"
subsystem: brand/logo-harness
tags: [harness, svg-pipeline, round-2, two-tone, output-dir, review-fixes]
dependency_graph:
  requires:
    - 181-svg-pipeline-tournament-round-1-divergent/181-07-SUMMARY.md
  provides:
    - 182-tournament-convergent-refinement/harness/dirs/b-step-r2.mjs (R2_CONFIGS + generate)
    - 181-harness --output-dir parameterization (all four scripts)
    - assembleLockup two-tone mark support (accentPathD + palette.accentFill)
    - generate.mjs buildMonoSvg export (consumed by 182-02 generate-r2.mjs)
  affects:
    - 181-svg-pipeline-tournament-round-1-divergent/harness/ (five files modified)
tech_stack:
  added: []
  patterns:
    - argOutputDir pattern: CLI --output-dir parsed with process.argv.indexOf → path.resolve
    - monoSvgString override: lintCandidate uses monoSvgString ?? svgString for mono-derivability check
    - accentPathD overlay: inside existing mark <g> (inherits transform, no new translate)
    - isMain guard: process.argv[1] === fileURLToPath(import.meta.url) before await main()
    - colorTreatment grouping: build-gallery groups by ink/moss/two-tone when any candidate has colorTreatment
key_files:
  created:
    - .planning/phases/182-tournament-convergent-refinement/harness/dirs/b-step-r2.mjs
  modified:
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/assemble-lockup.mjs
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/generate.mjs
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/lint.mjs
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/render-matrix.mjs
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/build-gallery.mjs
decisions:
  - "accentPathD overlay is inside the existing mark <g> block (inherits translate+scale), not a new transform — coordinate-space contract preserved"
  - "buildMonoSvg() is exported from generate.mjs (not b-step-r2.mjs) because 182-02 generate-r2.mjs imports it alongside other generate.mjs utilities"
  - "Smoke-run artifacts (181-direction candidates in 182 dir) cleaned up; 182-02 will generate the real R2_CONFIGS candidates"
  - "ROUND_LABEL derived from --gallery-name at Node.js level; injected into VERDICT_JS via string replacement before HTML embedding"
metrics:
  duration: 6m
  completed_date: "2026-06-13"
  tasks_completed: 3
  files_modified: 6
requirements: [LOGO-03]
---

# Phase 182 Plan 01: Round 2 Harness Infrastructure Summary

Round 2 pipeline prerequisite infrastructure: --output-dir parameterization across all four harness scripts, two-tone mark support in assembleLockup, b-step-r2.mjs config module with 7 Round 2 candidates, and four REVIEW findings fixed.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create b-step-r2.mjs + extend assemble-lockup for two-tone marks | f366658d | b-step-r2.mjs (new), assemble-lockup.mjs |
| 2 | Parameterize generate.mjs + lint.mjs (--output-dir, mono-lint override, REVIEW fixes) | 08e40bb5 | generate.mjs, lint.mjs |
| 3 | Parameterize render-matrix.mjs + build-gallery.mjs (--output-dir, WR-01, WR-07, Moss color map, Round 2 gallery format) | 050c8e61 | render-matrix.mjs, build-gallery.mjs |

## What Was Built

### b-step-r2.mjs
New self-contained module at `.planning/phases/182-tournament-convergent-refinement/harness/dirs/b-step-r2.mjs`. Exports `R2_CONFIGS` (7 entries: R2-1..R2-7) and `generate(config)`. R2-1..R2-4 are Ink baselines, R2-5 is full Moss, R2-6 and R2-7 are two-tone (Ink base + Moss accent on top step). The `generate()` function copies the b-step.mjs pathParts loop verbatim and adds `accentStep` support: when `config.accentStep === true`, the rightmost step (index `steps-1`) is returned separately as `accentPathD`.

### assembleLockup.mjs (two surgical edits)
1. Default palette `#111418` changed to `#181818` (sat=0, passes lintMonochromeDeriv — WR-05).
2. Conditional accent path overlay added inside the existing mark `<g>` block — inherits the same `translate(markTx,markTy) scale(s)` transform. No new transform added (T-182-02 mitigated).

### generate.mjs
- `argOutputDir` pattern: `--output-dir` parsed after `__dirname`; `PHASE_DIR` defaults to `__dirname/..` if absent.
- `buildLockupSvg()` extended: derives `ink` from `colorTreatment` (moss → `#5E9E84`, else `#181818`), derives `accentFill` for two-tone, passes `accentPathD` to `assembleLockup`.
- `buildMonoSvg(svgString, monoMap)` added as an **exported** function (consumed by 182-02 `generate-r2.mjs` import).
- `buildStandardCandidate()` threads `accentPathD` and `monoSvgString` through to the returned candidate object.
- IN-01 dead assignment fixed: `const failed = culled` (was `rawCandidates.length - (rawCandidates.length - culled)`).
- `isMain` guard added: `await main()` replaced with `if (process.argv[1] === fileURLToPath(import.meta.url)) { await main(); }` — importing generate.mjs no longer triggers the 181 pipeline as a side effect.

### lint.mjs
- `argOutputDir` pattern added.
- `lintMonochromeDeriv()` jsdoc corrected (WR-05): removed false claim that `#111418` has sat < 0.15; documented that color variants must pass via `monoSvgString` override.
- `lintCandidate()`: added `monoSvgString` to jsdoc and destructuring; mono-derivability lint now uses `svgForMonoLint = monoSvgString ?? svgString` so Moss-colored SVGs lint against their greyscale mono mapping.

### render-matrix.mjs
- `argOutputDir` pattern added.
- `INK_DARK_COLOR_MAP`: added `"#5E9E84": "#5E9E84"` identity entry (Moss visible on Ink-dark background per contrast-table.txt 5.89:1 ratio).
- WR-07: `buildTileHtml()` adds `border-radius: 50%; overflow: hidden` on body for `avatar-circle` tile; `renderTile()` screenshots via `page.locator("body")` for that tile.
- WR-01: Step 4 reads `fullIndex` from `index.json` before filtering out `culledIds`, so smoke-mode culls don't clobber unrendered candidates.
- IN-04a: blank-render guard comment corrected ("paper-light tile" only).

### build-gallery.mjs
- `argOutputDir` + `argGalleryName` patterns added; `GALLERY_PATH` uses `argGalleryName ?? "round-1-gallery.html"`.
- `ROUND_LABEL` derived from `--gallery-name` at Node.js level (e.g. `round-2-gallery.html` → `"Round 2"`).
- `buildGallery()`: when any candidate has `colorTreatment`, groups by `ink` / `moss` / `two-tone` with section headers; falls back to direction-letter grouping for Round 1 galleries (backward compatible).
- `renderCandidate()`: displays `"Color: {colorTreatment}"` badge when `colorTreatment` is set.
- Gallery `<title>`, `<h1>`, and VERDICT_JS round heading use `ROUND_LABEL`.

## Deviations from Plan

None — plan executed exactly as written. The IN-04d comment fix in b-step-r2.mjs was applied as specified: the new file uses "Full rounded rect (all 4 corners)" rather than copying the stale "top corners only" comment from b-step.mjs.

## Verification Results

All automated checks passed:

- `b-step-r2.mjs`: 7 configs, R2-6/R2-7 emit `accentPathD`, R2-1..R2-5 do not, no NaN
- `assemble-lockup.mjs`: `#111418` removed, `#181818` present, `accentPathD` appears 3 times (jsdoc × 2 + conditional overlay × 1)
- `generate.mjs`: `--output-dir`, `export function buildMonoSvg`, `monoSvgString`, `isMain` guard, dead assignment removed
- `lint.mjs`: `--output-dir`, `monoSvgString ?? svgString`, WR-05 jsdoc corrected
- `render-matrix.mjs`: `--output-dir`, `#5E9E84` in color map, `border-radius: 50%`, `fullIndex`
- `build-gallery.mjs`: `--output-dir`, `--gallery-name`, `colorTreatment` grouping
- Smoke run: `generate.mjs --output-dir .../182 --smoke` produced `candidates/index.json` in the 182 dir; Round 1 index intact at 16 candidates (unchanged)
- Import side-effect test: `await import('/path/to/generate.mjs')` completes without running the pipeline

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. All file writes are confined to `PHASE_DIR` subdirs (candidates/, rejected/, screenshots/). The `--output-dir` CLI arg is resolved via `path.resolve()` with no symlink-following logic added (T-182-05: accepted).

## Self-Check: PASSED

- [x] b-step-r2.mjs exists: `.planning/phases/182-tournament-convergent-refinement/harness/dirs/b-step-r2.mjs`
- [x] assemble-lockup.mjs modified: contains `#181818` and `accentPathD`
- [x] generate.mjs modified: contains `--output-dir`, `buildMonoSvg`, `isMain` guard
- [x] lint.mjs modified: contains `--output-dir`, `monoSvgString ?? svgString`
- [x] render-matrix.mjs modified: contains `--output-dir`, `#5E9E84`, `border-radius: 50%`, `fullIndex`
- [x] build-gallery.mjs modified: contains `--output-dir`, `--gallery-name`, `colorTreatment`
- [x] Commits: f366658d, 08e40bb5, 050c8e61 (all verified via git log)
