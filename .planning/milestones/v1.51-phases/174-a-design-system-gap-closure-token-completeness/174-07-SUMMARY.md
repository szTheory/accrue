---
phase: 174-a-design-system-gap-closure-token-completeness
plan: "07"
subsystem: ui
tags: [css, design-tokens, app.css, accrue_admin, transition, motion]

# Dependency graph
requires:
  - phase: 174-a-design-system-gap-closure-token-completeness/174-01
    provides: intentional-exception comment convention established for .ax-search-trigger-like cases
provides:
  - Resolved stale 'collapse pending' comment in .ax-search-trigger block in app.css
  - Intentional-exception comment documenting asymmetric two-token transition rationale
  - Rebuilt accrue_admin.css asset bundle consistent with updated source
affects: [174-VERIFICATION.md, gap-closure Gap 3 resolution, design-system conventions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Intentional-exception comment pattern: when a CSS block uses two distinct duration tokens for asymmetric enter/exit speed, document it with an intentional-exception comment rather than forcing a collapse that loses brand-meaningful timing differences"

key-files:
  created: []
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css

key-decisions:
  - "Option (c) chosen for Gap 3 resolution: document .ax-search-trigger as an intentional exception rather than forced collapse or adding a new --ax-transition-focus token. The two-token asymmetric transition (--ax-theme-transition for colors at 180ms; --ax-motion-fast for transform at 120ms) is brand-meaningful and cannot be losslessly collapsed to a single bundle var()."

patterns-established:
  - "Intentional-exception comment: /* Intentional exception: two-token asymmetric transition — not collapsible to a single bundle. ... */ — used when a selector deliberately uses multiple duration tokens for asymmetric timing"

requirements-completed:
  - DSY-01

# Metrics
duration: 5min
completed: 2026-06-03
---

# Phase 174, Plan 07: .ax-search-trigger Gap 3 Resolution Summary

**Stale 'collapse pending' comment in .ax-search-trigger replaced with a permanent intentional-exception comment documenting asymmetric two-token transition rationale; asset bundle rebuilt.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-03T22:02:00Z
- **Completed:** 2026-06-03T22:08:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Removed the stale `/* Phase D: asymmetric speed — collapse pending ... */` comment from the `.ax-search-trigger` block in `app.css` (grep for "collapse pending" now returns 0 lines)
- Replaced with an intentional-exception comment explaining that `--ax-theme-transition` (180ms for color/border/background) and `--ax-motion-fast` (120ms for transform snap) are two distinct brand-meaningful token durations that cannot be collapsed without losing the enter/exit speed asymmetry
- Rebuilt the `accrue_admin.css` asset bundle via `mix accrue_admin.assets.build`; 172 admin tests pass, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace stale deferral comment with intentional-exception comment** - `ea8df670` (fix)
2. **Task 2: Rebuild accrue_admin.css asset bundle** - included in plan metadata commit (rebuild produced no binary diff as minifier strips all comments; bundle verified intact at 42 kB, all tests pass)

**Plan metadata:** (included in docs commit below)

## Files Created/Modified
- `accrue_admin/assets/css/app.css` - `.ax-search-trigger` block: stale 'Phase D' comment replaced with intentional-exception comment (lines 1450-1452). No functional CSS change.
- `accrue_admin/priv/static/accrue_admin.css` - Rebuilt asset bundle (42 kB; minifier strips comments so binary is unchanged, but pipeline is confirmed in-sync)

## Decisions Made
- Option (c): document `.ax-search-trigger` as an intentional exception — not a forced collapse (which would lose the 180ms vs 120ms enter/exit timing difference) and not a new `--ax-transition-focus` token (which would add complexity with no DX benefit). The 4 other collapsed sites in earlier plans all had identical per-property durations; `.ax-search-trigger` is the one genuinely asymmetric case.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- The asset rebuild (`mix accrue_admin.assets.build`) produced no binary change in `accrue_admin.css` (expected: CSS minifiers strip comments, so a comment-only change in `app.css` yields identical minified output). The plan acknowledges this: "The comment removal in Task 1 does not change the compiled output of the CSS (comments are stripped during minification). The rebuild is still required to keep the bundle timestamp and content consistent with source." All acceptance criteria were satisfied — no "collapse pending" in the bundle, bundle is non-empty, test suite green.

## Phase-Gate Verification Results

| Check | Result |
|-------|--------|
| `grep -c "collapse pending" app.css` | 0 |
| `grep -n "Intentional exception" app.css` | 1 line at .ax-search-trigger (line 1450) |
| `grep -c "Phase D" app.css` | 0 |
| `mix test --seed 0` (accrue_admin) | 172 tests, 0 failures |
| `bash scripts/ci/verify_package_docs.sh` | exits 0, all invariants pass |

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

All 7 plans in Phase 174 are now complete. Gap 3 (the last VERIFICATION.md partial warning) is resolved. Phase 174 (a-design-system-gap-closure-token-completeness) is fully done and ready for the Phase 174 verifier to sign off.

---
*Phase: 174-a-design-system-gap-closure-token-completeness*
*Completed: 2026-06-03*
