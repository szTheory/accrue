---
phase: 191-page-flow-interaction-pass-fixture-stress-microcopy
plan: 04
subsystem: ui
tags: [phoenix-liveview, accrue-admin, page-flow, focus-management, playwright, responsive-css]

requires:
  - phase: 191-03
    provides: [shared overlay focus contracts and hook registration patterns]
provides:
  - LiveView connection-state hook with stale-action disabling
  - Shared data-phase191-focus anchors for patching controls
  - Escape/outside-click focus restore for dropdowns, command palette, and mobile nav
  - Responsive scroll and overflow guards for page-flow surfaces
affects: [phase-191, phase-192, admin-ui-verification, accrue_admin]

tech-stack:
  added: []
  patterns:
    - LiveView lifecycle hook drives visible/programmatic connection status
    - Shared components expose stable focus anchors instead of page-local selectors
    - Generated admin assets are committed after hook/CSS changes

key-files:
  created:
    - accrue_admin/assets/js/hooks/connection_state.js
    - .planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-04-SUMMARY.md
  modified:
    - accrue_admin/assets/js/app.js
    - accrue_admin/assets/js/hooks/accrue_shell_nav.js
    - accrue_admin/assets/js/hooks/command_palette.js
    - accrue_admin/assets/js/hooks/dropdown.js
    - accrue_admin/lib/accrue_admin/components/app_shell.ex
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/components/dropdown_menu.ex
    - accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex
    - accrue_admin/lib/accrue_admin/components/tabs.ex
    - accrue_admin/lib/accrue_admin/components/window_selector.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/e2e/admin-page-flow-phase191.spec.js

key-decisions:
  - "Connection state is sourced from LiveView lifecycle events and expressed through a shared shell hook/status region."
  - "Phase 191 focus verification uses data-phase191-focus anchors on shared components instead of brittle page-specific selectors."
  - "Admin static JS/CSS bundles are committed with source hook and CSS changes so served admin assets match implementation."

patterns-established:
  - "Use data-stale-disable on mutating controls that must be actionability-disabled while the LiveView is disconnected."
  - "Use data-phase191-focus on retained controls, status regions, and route/window navigation anchors touched by LiveView patches."
  - "Constrain floating panels with viewport-relative max dimensions and restore trigger focus on Escape/outside dismissal."

requirements-completed: [IXN-02, IXN-03, IXN-04, IXN-05, PAGE-03, PAGE-04]

duration: 29 min
completed: 2026-06-19
status: complete
---

# Phase 191 Plan 04: Page-Flow Interaction Controls Summary

**LiveView connection state, stale-action disabling, shared patch-focus anchors, and responsive scroll/floating guards for admin page flows**

## Performance

- **Duration:** 29 min
- **Started:** 2026-06-19T15:29:13Z
- **Completed:** 2026-06-19T15:58:19Z
- **Tasks:** 2
- **Files modified:** 19

## Accomplishments

- Added `ConnectionState` and shell markup so disconnected/reconnecting/restored states are visible, announced, and disable stale mutating controls.
- Added shared `data-phase191-focus` anchors to data table, filter chip, dropdown, tab, and window selector controls, with component tests covering those contracts.
- Hardened dropdown, command palette, and mobile nav dismissal so Escape/outside-click closes floating controls and restores focus.
- Added responsive overflow guards for mobile cards, timeline cards, JSON, breadcrumbs, related resources, data tables, and floating panels.
- Extended the Phase 191 browser spec for reconnect, focus, scroll, responsive, floating, and microcopy regressions.

## Task Commits

1. **Task 1 RED: disconnected/reconnecting shell contract** - `a5f61487` (test)
2. **Task 1 GREEN: connection state stale-action guard** - `1d803128` (feat)
3. **Task 2 RED: page-flow focus anchor contracts** - `1ec10543` (test)
4. **Task 2 GREEN: focus anchors and scroll guards** - `47342761` (feat)

## Files Created/Modified

- `accrue_admin/assets/js/hooks/connection_state.js` - LiveView lifecycle hook for status text, stale-disabled controls, and reconnect focus retention.
- `accrue_admin/assets/js/app.js` - Registers `ConnectionState` with admin hooks.
- `accrue_admin/assets/js/hooks/dropdown.js` - Adds Escape/outside dismissal and trigger focus restore.
- `accrue_admin/assets/js/hooks/command_palette.js` - Restores focus to the prior trigger or main content after close/selection.
- `accrue_admin/assets/js/hooks/accrue_shell_nav.js` - Adds mobile-nav Escape/outside dismissal with toggle focus restore.
- `accrue_admin/lib/accrue_admin/components/app_shell.ex` - Adds status region, main-content focus anchor, and stale-disable shell controls.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` - Adds focus anchors, live selection status, and stale-disable action markers.
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` - Adds filter chip focus anchors.
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` - Adds floating-panel metadata and dropdown focus anchors.
- `accrue_admin/lib/accrue_admin/components/tabs.ex` - Adds tab-list/link focus anchors and current marker.
- `accrue_admin/lib/accrue_admin/components/window_selector.ex` - Adds window-list/link focus anchors and current marker.
- `accrue_admin/assets/css/app.css` - Adds responsive overflow and floating-panel constraints.
- `accrue_admin/priv/static/accrue_admin.css` and `accrue_admin/priv/static/accrue_admin.js` - Rebuilt generated admin assets for CSS and hook changes.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` - Adds focused browser assertions for reconnect, responsive scroll, floating controls, and generic-copy checks.
- Component tests under `accrue_admin/test/accrue_admin/components/` - Cover shell status and shared focus anchor contracts.

## Decisions Made

- Connection status is bound to LiveView lifecycle events rather than a manually clickable UI state, satisfying T-191-08.
- Focus targets are shared component contracts (`data-phase191-focus`) so Phase 192 can verify retained controls without coupling to page-specific DOM shape.
- The generated admin JS/CSS bundles are part of the implementation surface whenever hook registration or admin CSS changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Scoped Phase 191 grep tags so focused browser checks only run targeted tests**
- **Found during:** Task 1 browser verification
- **Issue:** Describe-level tags caused `--grep "@reconnect"` to run unrelated Phase 191 tests while reconnect work was being verified.
- **Fix:** Kept tags on individual tests so reconnect/focus/scroll/responsive/floating greps are scoped correctly.
- **Files modified:** `accrue_admin/e2e/admin-page-flow-phase191.spec.js`
- **Verification:** `npm run e2e:phase191 -- --grep "@reconnect" --project=chromium-desktop`
- **Committed in:** `1d803128`

**2. [Rule 1 - Compatibility Bug] Preserved existing selected-count markup contract while adding live status semantics**
- **Found during:** Task 2 component verification
- **Issue:** Existing tests matched the selected-count attribute order exactly.
- **Fix:** Added `role="status"` and `aria-live="polite"` without breaking the previous `data-role="selected-count"` assertion shape.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/data_table.ex`
- **Verification:** Component suite passed with 54 tests.
- **Committed in:** `47342761`

**3. [Rule 2 - Missing Critical] Added shared overflow guards found by responsive page-flow scan**
- **Found during:** Task 2 browser verification
- **Issue:** Real route scans exposed reachable-action risks in timeline cards, data table cards, KPI deltas, JSON viewer, breadcrumbs, and related links.
- **Fix:** Added min-width, wrapping, max-width, and scroll containment guards in shared CSS.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
- **Verification:** Responsive/floating Phase 191 grep and group contracts passed.
- **Committed in:** `47342761`

**4. [Rule 1 - Test Bug] Narrowed generic microcopy copy pattern**
- **Found during:** Task 2 browser verification
- **Issue:** The broad `invalid` regex falsely flagged the legitimate Coupons status/filter label "Invalid".
- **Fix:** Narrowed the generic error pattern to "oops", "forbidden", and specific generic invalid phrases.
- **Files modified:** `accrue_admin/e2e/admin-page-flow-phase191.spec.js`
- **Verification:** Responsive/floating Phase 191 grep passed.
- **Committed in:** `47342761`

**5. [Rule 3 - Blocking] Recompiled embedded admin assets after CSS/JS rebuild**
- **Found during:** Task 2 browser verification
- **Issue:** `mix accrue_admin.assets.build` rewrote static assets, but the E2E server served embedded admin assets that needed a forced compile to pick up rebuilt CSS/JS.
- **Fix:** Ran `mix compile --force` after asset rebuild before final browser verification.
- **Files modified:** `accrue_admin/priv/static/accrue_admin.css`, `accrue_admin/priv/static/accrue_admin.js`
- **Verification:** Focus/scroll/responsive/floating and reconnect browser checks passed.
- **Committed in:** `1d803128`, `47342761`

---

**Total deviations:** 5 auto-fixed (2 blocking, 2 bugs, 1 missing critical)
**Impact on plan:** All fixes were required to verify the planned interaction, responsive, and stale-state contracts. No dependencies, production routes, auth paths, or schema changes were added.

## Issues Encountered

- Existing unrelated dirty files were present throughout execution. Only plan-owned files and generated admin assets were staged.
- `accrue_admin/assets/css/app.css` and `accrue_admin/priv/static/accrue_admin.css` had pre-existing `.ax-dev-group-specimen` width/max-width/box-sizing changes. They were preserved in the working tree but excluded from Task 2 staging with custom index blobs.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/components/app_shell_test.exs` - passed.
- `cd accrue_admin && mix test test/accrue_admin/components/app_shell_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/navigation_components_test.exs` - passed, 54 tests, 0 failures.
- `cd accrue_admin && npm run e2e:group-contracts` - passed, 16 tests.
- `cd accrue_admin && npm run e2e:phase191 -- --grep "@reconnect" --project=chromium-desktop` - passed, 1 test.
- `cd accrue_admin && npm run e2e:phase191 -- --grep "@focus|@scroll|@responsive|@floating" --project=chromium-desktop` - passed, 2 tests.

## TDD Gate Compliance

- RED gate commits present: `a5f61487`, `1ec10543`.
- GREEN gate commits present after RED: `1d803128`, `47342761`.
- No refactor-only commit was needed.

## Known Stubs

None. Stub scan found only legitimate CSS/form placeholder selectors and empty form values.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None. The new client hooks and CSS are the planned Phase 191 interaction surface; no network endpoints, auth paths, file access, or schema trust boundaries were added.

## Next Phase Readiness

Phase 192 can now verify page-flow interaction behavior against stable shared focus anchors, connection-state status/stale markers, and generated admin assets. Remaining Phase 191 plans can build on the same Phase 191 browser harness tags.

## Self-Check: PASSED

- Found summary path: `.planning/phases/191-page-flow-interaction-pass-fixture-stress-microcopy/191-04-SUMMARY.md`
- Found created hook: `accrue_admin/assets/js/hooks/connection_state.js`
- Found task commits: `a5f61487`, `1d803128`, `1ec10543`, `47342761`

---
*Phase: 191-page-flow-interaction-pass-fixture-stress-microcopy*
*Completed: 2026-06-19*
