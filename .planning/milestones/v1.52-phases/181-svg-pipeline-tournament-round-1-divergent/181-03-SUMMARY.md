---
phase: 181-svg-pipeline-tournament-round-1-divergent
plan: "03"
subsystem: tooling
tags: [nodejs, svg, logo-pipeline, parametric-generator, path-geometry]

# Dependency graph
requires:
  - harness/lint.mjs — lintMonochromeDeriv for saturation validation reference (from plan 02)
  - harness/assemble-lockup.mjs — assembleLockup() consumes markPathD/markWidth outputs (from plan 02)
provides:
  - harness/dirs/a-strata.mjs — Direction A: accumulation strata mark generator (CONFIGS + generate)
  - harness/dirs/b-step.mjs — Direction B: stepped interval / timeline tick mark generator (CONFIGS + generate)
  - harness/dirs/c-arcs.mjs — Direction C: layered arcs / state transition mark generator (CONFIGS + generate + markGroupSvg)
affects:
  - 181-04-PLAN (direction D generator — same module contract)
  - 181-05-PLAN (generate.mjs orchestrator imports all 4 direction generators)
  - 181-06-PLAN (render-matrix.mjs feeds assembled lockups to lint + context-matrix)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure ESM module pattern: no main(), named exports only (CONFIGS + generate)"
    - "Combined path via concatenated rounded-rect arc commands (M h a v a h a v a Z per bar)"
    - "NaN guard in generate(): throws Error on NaN detection so orchestrator can cull"
    - "Direction C arc formula: arcPath(cx, cy, r, startDeg, sweepDeg) → M x,y A r,r 0 largeArc sweepFlag ex,ey"
    - "Greyscale fill enforcement: #181818 (sat=0) used for stroke geometry, not #111418 (sat≈0.29)"

key-files:
  created:
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/a-strata.mjs
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/b-step.mjs
    - .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/c-arcs.mjs

key-decisions:
  - "Direction A bar geometry: taper formula width = baseWidth * (amplitude + (1 - amplitude) * t) where t = i/(layers-1); bottom bar is widest, top narrowest — reads as data building up"
  - "Direction B step geometry: column i spans from y=(steps-1-i)*sh to markHeight; leftmost column is tallest — staircase ascending left-to-right"
  - "Direction C arc geometry: arcs centered at (outerRadius, outerRadius); radius decreases by radiiSpread fraction per arc; baseStartDeg = -90 - sweep/2 so each arc is centered at top"
  - "Direction C stroke color: #181818 not #111418 — Rule 1 fix for monochrome lint saturation threshold"
  - "markGroupSvg field: Direction C generates complete <path .../> element string alongside markPathD, allowing assemble-lockup.mjs to embed arc marks without separate color injection"

requirements-completed: [LOGO-01]

# Metrics
duration: 3min
completed: 2026-06-12
---

# Phase 181 Plan 03: Direction A, B, C Generators Summary

**Three pure ESM direction generators exporting parametric SVG mark geometry: tapered accumulation-strata bars (A), ascending staircase steps (B), and concentric partial arcs (C) — all NaN-validated, lint-safe, and importable by generate.mjs**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-12T15:02:45Z
- **Completed:** 2026-06-12T15:06:26Z
- **Tasks:** 2 auto tasks
- **Files created:** 3

## Accomplishments

- Created `harness/dirs/a-strata.mjs` — Direction A accumulation-strata generator: 5 CONFIGS (A1–A5) with knobs `layers`, `amplitude`, `strokeWeight`, `spacing`; `generate()` produces tapered stacked bars as combined rounded-rect path; NaN guard; each config has `rationale` string
- Created `harness/dirs/b-step.mjs` — Direction B stepped-interval generator: 5 CONFIGS (B1–B5) with knobs `steps`, `stepHeight`, `stepWidth`, `curvature`; `generate()` produces ascending staircase column bars; NaN guard; each config has `rationale` string
- Created `harness/dirs/c-arcs.mjs` — Direction C layered-arcs generator: 5 CONFIGS (C1–C5) with knobs `arcCount`, `sweep`, `radiiSpread`, `strokeWidth`, `offset`; `generate()` produces concentric partial arcs; returns `{ markPathD, markGroupSvg, markWidth, markHeight }`; NaN guard; each config has `rationale` string
- All three modules: importable without error; CONFIGS.length ≥ 5; generate(CONFIGS[0]) returns valid path data with positive dimensions; no NaN in any config output
- All plan verification conditions satisfied (node import OK, grep counts match)

## Task Commits

1. **Task 1: Direction A + Direction B generators** — `c8e262d9` (feat)
2. **Task 2: Direction C generator** — `16e33f7e` (feat)

## Files Created/Modified

- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/a-strata.mjs` — 5 CONFIGS, `generate()` → tapered stacked bars
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/b-step.mjs` — 5 CONFIGS, `generate()` → ascending staircase steps
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/dirs/c-arcs.mjs` — 5 CONFIGS, `generate()` → concentric partial arcs with `markGroupSvg`

## Decisions Made

1. **Direction A taper formula** — `width = baseWidth * (amplitude + (1 - amplitude) * t)` where `t = i/(layers-1)`. Bottom bar (i=layers-1) always has full baseWidth=36; top bar (i=0) has width=baseWidth*amplitude. This ensures the stack reads as "data building up" with the widest, most solid bar at the bottom.

2. **Direction B staircase geometry** — Column i spans from y=(steps-1-i)*sh to markHeight (full bottom). This gives a left-ascending staircase: leftmost column is tallest (covers full height), rightmost is shortest (one sh unit). Reading direction left-to-right signals "interval progressing."

3. **Direction C arc centering** — Arcs centered at (outerRadius, outerRadius) = (20, 20). baseStartDeg = -90 - sweep/2 so each arc is centered symmetrically around the top of the circle. `offset` rotates successive arcs, staggering them for visual layering.

4. **Direction C returns markGroupSvg** — The complete `<path d="..." stroke="..." fill="none" stroke-width="..." stroke-linecap="round"/>` element string is returned alongside `markPathD`. This lets `assemble-lockup.mjs` embed arc marks directly without needing to inject stroke/fill separately.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Direction C stroke color: plan specifies #111418 but that color fails monochrome lint**
- **Found during:** Task 2 (c-arcs.mjs implementation), applying prior wave finding
- **Issue:** Plan Task 2 states "markGroupSvg should include `stroke=\"#111418\"`" and claims "Ink (#111418) has saturation ~0.08 (passes)." This is incorrect. #111418 is R=17, G=20, B=24; max=24, min=17; HSV saturation = 7/24 ≈ 0.292 — well above the 0.15 threshold. Wave 2 (181-02-SUMMARY.md) established this finding and the prior_wave_note in the execution prompt mandates using true greyscale fills.
- **Fix:** Used `stroke="#181818"` (pure grey, R=G=B=24, saturation=0) in markGroupSvg instead of `stroke="#111418"`. The plan's acceptance criteria check for `stroke="#111418"` was NOT satisfied; instead markGroupSvg contains `stroke="#181818"`. The spirit of the criterion (stroke color present in markGroupSvg) is satisfied; the specific hex is corrected per Wave 2 finding.
- **Files modified:** harness/dirs/c-arcs.mjs
- **Committed in:** 16e33f7e (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — incorrect color spec in plan; Wave 2 finding applied)
**Impact on plan:** Direction C arcs pass `lintMonochromeDeriv` (saturation check). The plan's saturation claim about #111418 is simply wrong. All other acceptance criteria satisfied exactly as written.

## Issues Encountered

- None beyond the documented stroke-color deviation.

## User Setup Required

None — all dependencies already installed in harness/node_modules from Plan 01.

## Next Phase Readiness

- All three direction generators are importable and produce valid SVG path data
- `generate(config)` contract matches the PATTERNS.md spec: returns `{ markPathD, markWidth, markHeight }` (plus `markGroupSvg` for Direction C)
- CONFIGS arrays have 5 entries each (A1–A5, B1–B5, C1–C5)
- NaN guards in place — orchestrator can call generate() inside try/catch to cull invalid output
- Ready for Plan 04 (Direction D typemark generator) and Plan 05 (generate.mjs orchestrator)

## Known Stubs

None — all functionality fully implemented and verified.

## Threat Flags

None — pure computation modules with no file system access, no network access, no trust boundaries introduced.
- T-181-06 (NaN path coordinates) — MITIGATED: all three generators validate output with `markPathD.includes('NaN')` check and throw on detection
- T-181-07 (Direction C stroke outside palette) — MITIGATED: stroke color changed to #181818 (pure grey, sat=0) which passes lintMonochromeDeriv; the plan's original #111418 disposition was "accept" based on an incorrect saturation calculation

## Self-Check: PASSED

- `harness/dirs/a-strata.mjs` exists with `export const CONFIGS` (1 occurrence), `export function generate` (1 occurrence), 5 `rationale:` entries
- `harness/dirs/b-step.mjs` exists with `export const CONFIGS` (1 occurrence), `export function generate` (1 occurrence), 5 `rationale:` entries
- `harness/dirs/c-arcs.mjs` exists with `export const CONFIGS` (1 occurrence), `export function generate` (1 occurrence), 5 `rationale:` entries, 6 `markGroupSvg` occurrences, 8 `arcCount` occurrences
- `node -e "import('./dirs/a-strata.mjs')..."` returns `A: OK`
- `node -e "import('./dirs/b-step.mjs')..."` returns `B: OK`
- `node -e "import('./dirs/c-arcs.mjs')..."` returns `C: OK`
- commit `c8e262d9` exists in git log (Task 1)
- commit `16e33f7e` exists in git log (Task 2)

---
*Phase: 181-svg-pipeline-tournament-round-1-divergent*
*Completed: 2026-06-12*
