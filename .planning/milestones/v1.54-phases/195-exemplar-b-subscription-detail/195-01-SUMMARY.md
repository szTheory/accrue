---
phase: 195-exemplar-b-subscription-detail
plan: "01"
subsystem: accrue_admin-testing
tags: [tdd-red, overlay, scroll-lock, playwright, subscription-detail]

requires:
  - phase: 193-research-re-baseline-pattern-lock
    provides: SPEC-DETAIL contract, portal-primary decision, page-flow helper patterns
  - phase: 194-exemplar-a-dashboard
    provides: one-spec Playwright script pattern and Phase 191 helper reuse
provides:
  - Component RED coverage for the canonical Overlay API and drawer/modal wrapper migration
  - Node RED coverage for ref-counted scroll lock, inert shell, scroll restore, and scrollbar compensation
  - Playwright RED coverage for Subscription detail SPEC-DETAIL and IXN-01 rendered behavior
  - e2e:phase195 package script
affects: [195-03, 195-04, 195-05, 195-07, 195-08, 199]

tech-stack:
  added: []
  patterns:
    - "RED-only Wave 0 harness: tests fail on missing planned implementation, not syntax or setup"
    - "Phase 191 helper reuse for detail-page Playwright assertions"
    - "Node fake-DOM hook test shape for browser-side scroll-lock modules"

key-files:
  created:
    - accrue_admin/test/js/scroll_lock_test.mjs
    - accrue_admin/e2e/admin-spec-detail-phase195.spec.js
  modified:
    - accrue_admin/test/accrue_admin/components/overlay_components_test.exs
    - accrue_admin/package.json

key-decisions:
  - "Plan 195-01 intentionally remains RED-only; implementation is owned by later Phase 195 plans."
  - "EXE-02 and IXN-01 are addressed by validation coverage here, but not marked complete in REQUIREMENTS.md."

patterns-established:
  - "Overlay component tests assert portal/template source and wrapper migration; browser tests own real teleported DOM behavior."
  - "ScrollLock tests require an explicit reset helper so module-level lock counters cannot leak between cases."
  - "Phase 195 Playwright spec opens seeded Subscription detail before failing on missing DETAIL selectors or overlay behavior."

requirements-completed: []
requirements-addressed: [IXN-01, EXE-02]

duration: 9m 15s
completed: 2026-06-26
status: complete
---

# Phase 195 Plan 01: Overlay Action-Hosting RED Harness Summary

**RED validation harness for canonical overlay, scroll-lock, drawer-hosted actions, and Subscription detail SPEC-DETAIL invariants.**

## Performance

- **Duration:** 9m 15s
- **Started:** 2026-06-26T08:05:53Z
- **Completed:** 2026-06-26T08:15:08Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added component RED coverage for `AccrueAdmin.Components.Overlay.overlay/1` and required `DetailDrawer` / `StepUpAuthModal` migration to the overlay portal contract.
- Added Node RED coverage for `ScrollLock.lock/0` / `unlock/0` behavior: ref-counting, exact scroll restore, inert background, and `--ax-scrollbar-comp`.
- Added `admin-spec-detail-phase195.spec.js` plus `e2e:phase195`, proving the browser harness reaches seeded Subscription detail before failing on missing Phase 195 selectors.

## Task Commits

1. **Task 1: Add overlay component RED tests** - `d1faa5f4` (test)
2. **Task 2: Add scroll-lock RED tests** - `cd61a96d` (test)
3. **Task 3: Add Phase 195 Playwright RED spec and script** - `11c93048` (test)

## Files Created/Modified

- `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` - Adds RED assertions for the canonical overlay API, body-level portal target, overlay hook, drawer/modal presentation attrs, and wrapper migration.
- `accrue_admin/test/js/scroll_lock_test.mjs` - Adds Node fake-DOM RED tests for the planned scroll-lock module.
- `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` - Adds browser RED assertions for SPEC-DETAIL initial render, action drawer behavior, focus/top-pointer checks, inert background, Escape, backdrop click, and mobile/desktop geometry.
- `accrue_admin/package.json` - Adds exactly one `e2e:phase195` script targeting the Phase 195 spec with one worker and 60s timeout.

## Verification Results

- `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs` - RED as expected: 6 tests, 4 failures on missing `AccrueAdmin.Components.Overlay.overlay/1` and missing portal/overlay attrs on current wrappers.
- `cd accrue_admin && node --test test/js/scroll_lock_test.mjs` - RED as expected: `ERR_MODULE_NOT_FOUND` for `assets/js/hooks/scroll_lock.js`.
- `cd accrue_admin && node --check e2e/admin-spec-detail-phase195.spec.js` - PASS.
- `cd accrue_admin && npm run e2e:phase195` - RED as expected: 6 failures after seeded Subscription detail page load, missing `[data-ax-action-band]` and `[data-ax-action-overflow-menu]` selectors.

## Decisions Made

- No implementation was added in this plan because its objective is Wave 0 RED validation.
- `REQUIREMENTS.md` remains pending for `EXE-02` and `IXN-01`; this plan addresses them with validation artifacts but does not complete the underlying implementation requirements.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The component test run continues to print a pre-existing PhoenixStorybook `RegistryStory.variations_for/1` warning from `storybook/components/button.story.exs`; it does not block the intended RED assertions.

## Known Stubs

None. The failing references are intentional RED contracts for later implementation plans, not shipped stubs.

## Threat Flags

None. This plan added tests and an npm script only; it introduced no production routes, endpoints, auth paths, file-access paths, schema changes, or runtime network surface.

## TDD Gate Compliance

Advisory: this plan has `type: tdd` but is explicitly a Wave 0 RED validation plan. RED `test(195-01)` commits exist; a GREEN `feat(195-01)` commit is intentionally absent because implementation is split into later Phase 195 plans.

## User Setup Required

None - no external service configuration required.

## Self-Check

- [x] `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` exists.
- [x] `accrue_admin/test/js/scroll_lock_test.mjs` exists.
- [x] `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` exists.
- [x] `accrue_admin/package.json` contains exactly one `e2e:phase195` script.
- [x] Task commit `d1faa5f4` exists.
- [x] Task commit `cd61a96d` exists.
- [x] Task commit `11c93048` exists.
- [x] No generated runtime artifacts were left untracked by the test runs.

## Self-Check: PASSED

## Next Phase Readiness

Plan 195-03 can implement `AccrueAdmin.Components.Overlay`, `#ax-overlay-root`, and wrapper migration against locked component tests. Plan 195-04 can implement `ScrollLock`. Plan 195-07 can green the Subscription detail action-band and drawer-hosting browser assertions.

---
*Phase: 195-exemplar-b-subscription-detail*
*Completed: 2026-06-26*
