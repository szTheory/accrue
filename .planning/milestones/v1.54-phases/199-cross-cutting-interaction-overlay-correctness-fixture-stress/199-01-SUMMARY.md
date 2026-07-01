---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: "01"
subsystem: testing
tags: [playwright, e2e, overlay, interaction, fixtures, copy, phase199]

requires:
  - phase: 191
    provides: Shared Playwright helpers for focus, hit-testing, scroll reachability, clipping, and theme setup.
  - phase: 195
    provides: Canonical overlay, drawer, step-up, and subscription overlay contract patterns.
  - phase: 197
    provides: LIST route and empty-state browser contract patterns.
  - phase: 198
    provides: DETAIL/analytics target matrices and drawer or step-up route-flow patterns.
provides:
  - Phase 199 Playwright browser contract for overlay, motion, theme, affordance, fixture, and copy behavior.
  - Focused `npm run e2e:phase199` script for the cross-cutting interaction contract.
  - Red-gate evidence for later Phase 199 plans: step-up inert, dropdown viewport bounds, and Recovery back-focus behavior.
affects: [phase199, phase200, admin-ui, overlay, e2e, copy]

tech-stack:
  added: []
  patterns:
    - Explicit Phase 199 Playwright target arrays rather than page or fixture abstractions.
    - Local browser assertion helpers for overlay root, ghost cleanup, drawer geometry, floating bounds, production theme persistence, route focus/scroll, and action context labels.
    - Dedicated one-spec, one-worker npm script for focused cross-cutting browser gates.

key-files:
  created:
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-01-SUMMARY.md
  modified:
    - accrue_admin/package.json

key-decisions:
  - "The Phase 199 browser contract uses explicit target arrays for overlay, motion, theme, affordance, fixture, and copy checks instead of a generic page or fixture abstraction."
  - "The focused browser gate is allowed to stay red when failures are real Phase 199 behavior gaps, but syntax, script, auth, route, import, and seed setup must be green."
  - "Customer payment-method overlay coverage is declared in the target array and left for the later fixture-extension plan because existing E2E seeds do not yet create payment methods."

patterns-established:
  - "Phase 199 browser coverage should keep setup deterministic through existing `/__e2e__/seed/*` endpoints and fail at the behavior assertion layer."
  - "Production theme persistence tests should use `accrue_theme`, not the older visual-helper key."

requirements-completed: [IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01]

duration: 10m 31s
completed: 2026-06-29
status: complete
---

# Phase 199 Plan 01: Browser Contract Summary

**Focused Phase 199 Playwright contract for overlay behavior, motion geometry, theme persistence, floating affordances, fixture flows, and copy context**

## Performance

- **Duration:** 10m 31s
- **Started:** 2026-06-29T21:15:54Z
- **Completed:** 2026-06-29T21:26:25Z
- **Tasks:** 1
- **Files modified:** 2 implementation files plus planning closeout metadata

## Accomplishments

- Created `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` with tagged browser coverage for `@overlay`, `@motion`, `@theme`, `@affordance`, `@fixture`, and `@copy`.
- Added explicit target arrays: `PHASE199_ROUTE_FLOWS`, `OVERLAY_FLOW_TARGETS`, `FLOATING_TARGETS`, `THEME_CASES`, and `COPY_TARGETS`.
- Added local assertion helpers for overlay root placement, ghost cleanup, drawer geometry, floating bounds, production `accrue_theme` persistence, route focus/scroll, and action-context labels.
- Added `npm run e2e:phase199` as a one-worker focused Playwright command.
- Ran the browser red gate and confirmed failures are real Phase 199 behavior gaps rather than syntax, script, import, auth, route, or seed setup failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the tagged Phase 199 browser contract and script** - `b322fea1` (test)

**Plan metadata:** committed after summary and state closeout.

## Files Created/Modified

- `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` - Phase 199 cross-cutting Playwright contract and local assertion helpers.
- `accrue_admin/package.json` - Added the exact `e2e:phase199` script.
- `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-01-SUMMARY.md` - Execution summary and verification record.

## Decisions Made

- Used explicit target arrays and route builders to keep failures tied to concrete admin surfaces.
- Kept helpers test-local because this plan only creates the browser contract; shared helper extraction belongs only if later plans prove repeated logic.
- Declared the Customer payment-method overlay representative in `OVERLAY_FLOW_TARGETS`, but did not make it a runnable assertion yet because the existing seed endpoints do not create payment-method rows. That fixture activation belongs to the later Phase 199 fixture plan.
- Tested production theme persistence through `accrue_theme` cookie/localStorage behavior, not the older `accrue_admin_theme` visual helper path.

## Verification Results

- `cd accrue_admin && node --check e2e/admin-interaction-overlay-phase199.spec.js` - passed.
- Exact `e2e:phase199` script check - passed; exactly one script points at `e2e/admin-interaction-overlay-phase199.spec.js`.
- Required tag scan - passed for `@overlay`, `@motion`, `@theme`, `@affordance`, `@fixture`, and `@copy`.
- Required symbol scan - passed for `PHASE199_ROUTE_FLOWS`, `OVERLAY_FLOW_TARGETS`, `FLOATING_TARGETS`, `THEME_CASES`, `COPY_TARGETS`, `seedPhase199`, `assertOverlayRoot`, `assertNoGhostOverlay`, `assertDrawerGeometry`, `assertFloatingBounds`, `assertThemePersistence`, `assertRouteFocusAndScroll`, and `assertActionContextLabels`.
- Forbidden scope scan - passed with no page-object abstraction, fixture DSL, `InteractionPage`, Floating UI, Popper, or positioning/runtime dependency import.
- Stub scan - passed with no TODO, FIXME, placeholder, coming soon, not available, empty hardcoded UI collections, null, or empty string stubs in modified implementation files.
- `cd accrue_admin && npm run e2e:phase199` - intentionally red after setup reached all runnable contracts: 12 passed, 11 skipped, 3 failed.

Current red browser failures:

1. `@overlay` StepUp representative opens through `#ax-overlay-root`, but `#accrue-admin-shell` is not inert while the step-up modal is active.
2. `@affordance` action-menu dropdown overflows the viewport bottom (`bottom` about 1255 on a 900px viewport).
3. `@fixture` Recovery to Campaign back navigation leaves focus on `document.body`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The first local browser dry run exposed harness issues in cookie setup, step-up selector targeting, and Recovery drill-link scoping. These were fixed before the task commit. The remaining browser failures are expected RED contract failures for later Phase 199 implementation plans.

## Auth Gates

None.

## Known Stubs

None.

## Threat Flags

None. This plan added a test-only Playwright spec and npm script; it did not add network endpoints, auth paths, file access patterns, schema changes, package installs, or runtime trust-boundary surface.

## TDD Gate Compliance

Task-level TDD red-gate coverage is present via `b322fea1`. This plan intentionally ships the failing browser contract only; later Phase 199 implementation plans are responsible for driving the focused gate green.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The Phase 199 browser contract is ready for implementation plans to address the red overlay, affordance, and fixture-focus failures while preserving the passing setup, route, seed, theme, motion, and copy scaffolding.

## Self-Check: PASSED

- Found `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`.
- Found `accrue_admin/package.json`.
- Found `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-01-SUMMARY.md`.
- Found task commit `b322fea1`.

---
*Phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress*
*Completed: 2026-06-29*
