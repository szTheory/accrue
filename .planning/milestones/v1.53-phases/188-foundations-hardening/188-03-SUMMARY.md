---
phase: 188-foundations-hardening
plan: "03"
subsystem: ui
tags: [accrue_admin, css, layers, z-index, motion]
requires:
  - phase: 188-foundations-hardening
    provides: "Plan 02 typography and measure foundation CSS"
provides:
  - "Exact semantic layer scale from base through toast"
  - "Overlay and sticky consumers mapped to --ax-z-* role tokens"
  - "Motion-token drift verification against existing v1.51 atoms and bundles"
affects: [phase-188, phase-191, admin-ui-interactions]
tech-stack:
  added: []
  patterns:
    - "Overlay z-index values consume semantic --ax-z-* layer tokens."
    - "Motion remains on the existing --ax-dur, --ax-ease, --ax-rise, --ax-press-scale, and --ax-transition token family."
key-files:
  created:
    - ".planning/phases/188-foundations-hardening/188-03-SUMMARY.md"
  modified:
    - "accrue_admin/assets/css/theme.css"
    - "accrue_admin/assets/css/app.css"
key-decisions:
  - "Retained --ax-z-topbar only as a deprecated compatibility alias to --ax-z-sticky."
  - "Recorded Task 2 as a verification commit because the existing motion CSS already satisfied the token-routing contract."
patterns-established:
  - "Layer roles: base 0, sticky 100, dropdown 200, popover 300, drawer 400, modal 500, toast 600."
  - "Skeleton shimmer remains the only app.css raw timing exception."
requirements-completed: [FND-02, FND-06]
duration: 3 min
completed: 2026-06-16
---

# Phase 188 Plan 03: Layer and Motion Foundation Summary

**Semantic z-index layer scale and verified motion-token routing for AccrueAdmin CSS**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-16T02:35:40Z
- **Completed:** 2026-06-16T02:38:21Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced the partial layer scale with `--ax-z-base`, `--ax-z-sticky`, `--ax-z-dropdown`, `--ax-z-popover`, `--ax-z-drawer`, `--ax-z-modal`, and `--ax-z-toast`.
- Kept `--ax-z-topbar` only as a documented deprecated compatibility alias to `--ax-z-sticky`.
- Migrated topbar, skip link, mobile sidebar, dropdown panel, detail drawer shell, command palette, and flash/toast surfaces to semantic layer tokens.
- Verified motion CSS contains no `transition: all`, no raw local `cubic-bezier(`, and no raw timing literals outside the allowed skeleton shimmer loop.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace partial z-index tokens with semantic layers** - `6ef2ca92` (feat)
2. **Task 2: Route motion gaps through existing tokens** - `44f7d292` (test, empty verification commit)

**Plan metadata:** committed separately with this summary.

## Files Created/Modified

- `accrue_admin/assets/css/theme.css` - Added the exact semantic layer token scale and compatibility alias.
- `accrue_admin/assets/css/app.css` - Replaced overlay/sticky z-index literals with semantic layer token consumers.

## Decisions Made

- Preserved the legacy `--ax-z-topbar` name only as a compatibility alias, with the new `--ax-z-sticky` role as the semantic source.
- Left the existing motion token family unchanged because the source already routed transitions through the approved atoms and bundles.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- Exact D-07 layer token grep loop - passed.
- Overlay z-index literal guard for `10`, `20`, `30`, `40`, `999`, and `1000` in `app.css` - passed.
- Motion guard for `transition: all` and raw `cubic-bezier(` in `app.css` - passed.
- Raw transition/animation timing guard, allowing only `ax-skeleton-shimmer 1.4s` - passed.
- Reduced-motion token checks for `--ax-rise-sm: 0px` and `--ax-press-scale: 1` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 04 can complete semantic state roles and disabled behavior on top of the formalized layer and motion foundation. Any remaining page-flow stacking traps remain Phase 191 interaction-owner work.

---
*Phase: 188-foundations-hardening*
*Completed: 2026-06-16*
