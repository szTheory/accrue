---
phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
plan: 08
subsystem: ui
tags: [dropdowns, floating-panels, viewport-bounds, playwright, css]

requires:
  - phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress
    provides: [Phase 199 interaction overlay fixtures and prior drawer geometry coverage through plan 199-07]
provides:
  - viewport-bound native dropdown placement for action menus
  - trigger-aware dropdown flip, clamp, and transform-origin behavior
  - bottom-right viewport stress coverage for Phase 199 affordance checks
affects: [admin-ui, dropdown-menu, action-menu, theme-picker, phase199-e2e]

tech-stack:
  added: []
  patterns:
    - Native details dropdowns remain non-modal and use requestAnimationFrame positioning.
    - Floating panel X/Y placement is driven by CSS custom properties consumed by the shared transform.

key-files:
  created:
    - .planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-08-SUMMARY.md
  modified:
    - accrue_admin/assets/js/hooks/dropdown.js
    - accrue_admin/assets/css/app.css
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - accrue_admin/e2e/phase191-page-flow-helpers.js
    - accrue_admin/test/js/dropdown_test.mjs
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js

key-decisions:
  - "Kept dropdowns as native non-modal details disclosures and added viewport clamping in the shared dropdown hook instead of introducing overlay portals or modal behavior."
  - "Applied horizontal clamping through the existing transform pipeline so mobile action menus can animate and stay bounded with one computed geometry path."

patterns-established:
  - "Dropdown panels set data-floating-placement plus CSS custom properties for max-height, X shift, and trigger-relative transform origin."
  - "Phase 199 affordance tests pin action menus near locked viewport edges and wait for final floating geometry before asserting bounds."

requirements-completed: [IXN-02, IXN-03]

duration: 40m
completed: 2026-06-30
status: complete
---

# Phase 199 Plan 08: Keep Floating Panels Viewport-Bound and Trigger-Aware Summary

**Native dropdown panels now flip and clamp within the viewport through shared transform-based placement, with stress coverage for bottom-right action menus.**

## Performance

- **Duration:** 40m
- **Started:** 2026-06-30T02:35:13Z
- **Completed:** 2026-06-30T03:15:00Z
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments

- Added viewport-aware positioning for `details.ax-dropdown` panels, including vertical flip, constrained max height, horizontal clamp, and trigger-relative transform origin.
- Preserved dropdowns as non-modal disclosure surfaces: no body scroll lock, backdrop, `aria-modal`, or shell inert behavior was added.
- Extended Phase 199 affordance E2E coverage with bottom-right viewport stress cases across phone, tablet, and desktop sizes.
- Rebuilt the checked-in admin CSS and JS assets after source CSS/hook changes.

## Task Commits

This TDD task was committed atomically:

1. **Task 1 RED: Keep floating panels viewport-bound and trigger-aware** - `0e55a0ba` (test)
2. **Task 1 GREEN: Keep dropdown panels viewport-bound** - `3d77b376` (fix)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `accrue_admin/assets/js/hooks/dropdown.js` - Adds shared dropdown placement, viewport clamp, reset, resize, and toggle scheduling behavior.
- `accrue_admin/assets/css/app.css` - Wires dropdown placement variables into max-height, top placement, transform origin, and transform-based X/Y movement.
- `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` - Adds geometry-settling bounds assertions and bottom-right action-menu viewport stress coverage.
- `accrue_admin/e2e/phase191-page-flow-helpers.js` - Adds shared floating adjacency assertion coverage from the RED test commit.
- `accrue_admin/test/js/dropdown_test.mjs` - Adds unit coverage for bottom-edge flip, viewport clamp, and transform origin.
- `accrue_admin/priv/static/accrue_admin.css` - Rebuilt admin stylesheet.
- `accrue_admin/priv/static/accrue_admin.js` - Rebuilt admin script bundle.
- `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-08-SUMMARY.md` - Plan execution summary.

## Decisions Made

- Kept action menus and dropdowns as native `details` disclosure controls, matching the Phase 199 contract that non-modal controls must not behave like overlays.
- Used transform-based horizontal clamping because dropdown motion already owns `transform`; this avoids depending on individual `translate` behavior and keeps animation and final geometry in sync.
- Made the Phase 199 affordance helper poll for settled floating geometry before asserting hard bounds, so assertions match the final interactive state rather than an in-flight transition frame.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first browser implementation used horizontal offset paths that did not reliably affect the mobile action-menu panel while the existing dropdown transform owned motion. This was resolved by moving X clamping into the shared `transform` value and verified with the Phase 199 affordance matrix.
- Existing Storybook asset warnings appeared during `mix` compile/build commands. They did not block the plan and match the existing project behavior for optional Storybook assets.

## Verification

- `cd accrue_admin && node --test test/js/dropdown_test.mjs` - passed, 6 tests.
- `cd accrue_admin && mix test test/accrue_admin/components/theme_picker_test.exs --max-failures 5` - passed, 6 tests.
- `cd accrue_admin && npm run e2e:phase199 -- --grep @affordance` - passed, 2 desktop tests; 2 mobile project variants intentionally skipped by the spec.
- `cd accrue_admin && mix accrue_admin.assets.build && git diff --check priv/static/accrue_admin.css` - passed.
- Dependency diff check for package and lock files - no changes.

## Known Stubs

None. Stub scan found only normal test helper default values and existing placeholder CSS class names; no new incomplete UI or mock data source was introduced.

## Threat Flags

None. The plan changed local UI positioning, CSS, generated static assets, and tests only; it introduced no new network endpoint, auth path, file access pattern, schema change, or trust boundary.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED commit present: `0e55a0ba`
- GREEN commit present after RED: `3d77b376`
- Refactor commit: not needed

## Self-Check: PASSED

- Confirmed SUMMARY exists at `.planning/phases/199-cross-cutting-interaction-overlay-correctness-fixture-stress/199-08-SUMMARY.md`.
- Confirmed key modified files exist.
- Confirmed RED commit `0e55a0ba` and GREEN commit `3d77b376` exist in git history.

## Next Phase Readiness

Plan 199-08 is complete. Phase 199 can continue with the remaining unexecuted plans using the updated dropdown bounds contract and tests.

---
*Phase: 199-cross-cutting-interaction-overlay-correctness-fixture-stress*
*Completed: 2026-06-30*
