---
phase: 181-svg-pipeline-tournament-round-1-divergent
plan: "02"
subsystem: tooling
tags: [nodejs, svg, lint, logo-pipeline, pngjs, xmldom]

# Dependency graph
requires:
  - harness/geist-spine.mjs — loadGeistFont(), extractGlyphs(), getCapHeight() (from plan 01)
provides:
  - harness/lint.mjs — pre-gate lint suite: 6 deterministic checks, self-test mode
  - harness/assemble-lockup.mjs — lockup assembler: standard + Direction D integrated-typemark modes
affects:
  - 181-03-PLAN (generate.mjs imports lintCandidate + assembleLockup)
  - 181-04-PLAN (direction generators use assembleLockup)
  - 181-05-PLAN (render-matrix feeds PNG paths to lint16pxLegibility)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Individual export function → function + single export {} block (satisfies grep -c "export {" == 1)
    - HSV saturation check: (max-min)/max; brand darks (#111418, #24303B) have sat ~0.29-0.39 — generators must use pure greys or pass through gap-ratio validation, not monochrome lint
    - lintCandidate skips gap-ratio for Direction D via skipGapRatio: true flag
    - assembleLockup uses translate() transform groups for glyph placement (avoids raw path coordinate parsing)
    - computeMarkBbox uses flat numeric scan (approximation; accuracy within 5px is sufficient)

key-files:
  created:
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/lint.mjs
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/assemble-lockup.mjs

key-decisions:
  - "Brand color #111418 has HSV saturation ~0.29 (blue-tinted dark) — exceeds the 0.15 monochrome threshold; smoke test valid SVG uses pure grey #181818 instead"
  - "assembleLockup returns SVG string directly in standard mode; returns { svg, markIsTypemark: true } object in Direction D mode — consumers must handle both shapes"
  - "Glyph paths wrapped in <g transform='translate(...)'>  rather than coordinate-shifting the raw path data — simpler and equally correct for all use cases"

patterns-established:
  - "Pattern: lint.mjs exports — individual function declarations + single export {} block at bottom"
  - "Pattern: Direction D skipGapRatio flag — lintCandidate logs note and skips gap check when true"
  - "Pattern: assembleLockup Direction D mode — returns { svg, markIsTypemark: true } not raw string"

requirements-completed: [LOGO-01]

# Metrics
duration: 5min
completed: 2026-06-12
---

# Phase 181 Plan 02: Pre-Gate Lint Suite and Lockup Assembler Summary

**6-check deterministic SVG lint suite with NDJSON output, rejected/ sidecar evidence, and smoke-test mode; plus a gap-enforced lockup assembler with Direction D integrated-typemark support**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-12T14:53:57Z
- **Completed:** 2026-06-12T14:59:09Z
- **Tasks:** 2 auto tasks
- **Files created:** 2

## Accomplishments

- Created `harness/lint.mjs` — 6 pre-gate lint functions: `lintValidParse`, `lintNoRectBackground`, `lintNoSubtitle`, `lintMonochromeDeriv`, `lintLockupGapRatio`, `lint16pxLegibility`, plus `lintCandidate` orchestrator
- `--test` smoke mode: 8 inline fixture assertions covering all hard logo constraints; exits 0 with `[lint] smoke: OK`
- NDJSON output to `lint-results.ndjson`; rejected candidates copied to `rejected/` with reason sidecar
- Created `harness/assemble-lockup.mjs` — `assembleLockup()` in two modes: standard (mark + glyph paths with gap = capHeight × gapRatio) and Direction D integrated-typemark (wraps full typemark, no gap)
- `computeMarkBbox()` for gap-ratio lint input from raw path data
- Both modules node-importable without error; all plan acceptance criteria verified

## Task Commits

1. **Task 1: Pre-gate lint suite (lint.mjs)** — `28a59e4a` (feat)
2. **Task 2: Lockup assembler (assemble-lockup.mjs)** — `54594867` (feat)

## Files Created/Modified

- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/lint.mjs` — pre-gate lint suite, 539 lines
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/assemble-lockup.mjs` — lockup assembler, 147 lines

## Decisions Made

1. **Brand colors exceed monochrome threshold** — `#111418` (Ink) and `#24303B` (Cobalt) have HSV saturation ~0.29 and ~0.39 respectively (blue-tinted darks), both above the 0.15 threshold. The plan comment saying "Brand colors all have saturation < 0.15" is incorrect. Fix: smoke test valid SVG uses pure grey `#181818` (sat=0). Generators using brand palette colors for the mark will need to verify their SVG fills pass the lint — pure greyscale variants do; cool-tinted darks do not.

2. **assembleLockup Direction D return shape** — Standard mode returns a raw SVG string. Direction D mode (`markIsTypemark: true`) returns `{ svg: string, markIsTypemark: true }` to allow callers to distinguish and avoid applying logotype-specific processing.

3. **Glyph positioning via translate() transform** — Rather than parsing and rewriting raw SVG path coordinate data (complex and error-prone), glyph `<path>` elements are wrapped in `<g transform="translate(xOffset,0)">` groups. This is correct because the glyph paths from `extractGlyphs()` are already in glyph-local coordinates (starting near x=0); the translate shifts them into lockup position.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Brand color #111418 has HSV saturation > 0.15**
- **Found during:** Task 1 smoke test development
- **Issue:** The plan spec stated "Brand colors (#111418, #24303B, #FAFBFC, #E9EEF2) all have saturation < 0.15 — they pass correctly." This is incorrect. #111418 is a blue-tinted dark (R=17, G=20, B=24): max=24, min=17, sat=7/24=0.292. #24303B is even more saturated (sat=0.39).
- **Fix:** Smoke test Fixture 5 (valid SVG) changed from `fill="#111418"` to `fill="#181818"` (pure grey, sat=0). The lint function itself is correct — it correctly identifies #111418 as having saturation > 0.15. The plan's rationale comment was wrong.
- **Implication for generators:** Direction generators that use `#111418` for mark fills will fail the monochrome lint. Generators should use true greyscale fills (e.g., `#1a1a1a`, `#000000`, `#181818`) OR the plan must document that `#111418` is allowlisted. This is flagged as a known issue for Plan 03 generator authors.
- **Files modified:** harness/lint.mjs (fixture only, not lint logic)
- **Committed in:** 28a59e4a

---

**Total deviations:** 1 auto-fixed (Rule 1 — incorrect assumption in plan spec)
**Impact on plan:** Lint logic is correct. Smoke test passes. Generator authors (Plan 03-06) must use greyscale fills or expect monochrome lint failures for brand-dark-colored marks.

## Issues Encountered

- None beyond the documented brand-color saturation deviation.

## User Setup Required

None — all dependencies already installed in harness/node_modules from Plan 01.

## Next Phase Readiness

- `lint.mjs` is ready for import by `generate.mjs` (Plan 03)
- `assemble-lockup.mjs` is ready for use by all 4 direction generators (Plans 03-06)
- Both modules are importable without error
- `lint.mjs --test` exits 0

## Known Stubs

None — all functionality fully implemented and verified.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundaries introduced.
- T-181-03 (DOMParser malformed SVG) — MITIGATED: every DOMParser call is wrapped in try/catch; parseerror → lint failure (not crash)
- T-181-04 (path traversal in rejected/ output) — ACCEPTED: output paths constructed from PHASE_DIR constant anchored to __dirname; no user input in path
- T-181-05 (hex regex matching non-color strings) — ACCEPTED: false matches would cause lint failure, not security issue

## Self-Check: PASSED

- `harness/lint.mjs` exists with 539 lines, `export {` present (1 occurrence), `skipGapRatio` present (6 occurrences), `appendFileSync` present (1 occurrence), `rejected` present (6 occurrences)
- `harness/assemble-lockup.mjs` exists with `assembleLockup` and `computeMarkBbox` exports
- `node lint.mjs --test` exits 0, prints `[lint] smoke: OK`
- `node -e "import('./assemble-lockup.mjs')..."` inline check returns `OK`
- commit `28a59e4a` exists in git log (Task 1)
- commit `54594867` exists in git log (Task 2)

---
*Phase: 181-svg-pipeline-tournament-round-1-divergent*
*Completed: 2026-06-12*
