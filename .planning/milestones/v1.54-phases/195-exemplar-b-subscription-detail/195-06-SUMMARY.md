---
phase: 195-exemplar-b-subscription-detail
plan: "06"
subsystem: accrue_admin-ui
tags: [detail, summary-list, action-menu, dropdown, css, liveview]

requires:
  - phase: 195-exemplar-b-subscription-detail/195-03
    provides: Canonical overlay component API and body-level overlay root
  - phase: 195-exemplar-b-subscription-detail/195-04
    provides: Dropdown and overlay JS behavior foundation
  - phase: 195-exemplar-b-subscription-detail/195-05
    provides: Token-compliant overlay CSS and rebuilt served CSS bundle
provides:
  - Reusable `AccrueAdmin.Components.Detail.summary_list/1` component for detail-page header rows
  - Reusable `AccrueAdmin.Components.DropdownMenu.action_menu/1` component for grouped LiveView action overflow menus
  - Node coverage for `dropdown.js` Escape/outside-click dismissal, idempotent close, and focus restoration
  - Token-compliant source CSS and rebuilt served CSS for summary-list and action-menu primitives
affects: [195-07, 195-08, 198, 199]

tech-stack:
  added: []
  patterns:
    - "Detail.summary_list/1 stays separate from detail_field_list/1: row-level actions in headers, read-only fields in drill groups."
    - "DropdownMenu.action_menu/1 is a lightweight details/menu disclosure; drawer and StepUp surfaces it opens remain the overlay/modal boundary."
    - "Generated admin CSS is rebuilt and committed after source CSS changes."

key-files:
  created:
    - accrue_admin/test/js/dropdown_test.mjs
  modified:
    - accrue_admin/lib/accrue_admin/components/detail.ex
    - accrue_admin/lib/accrue_admin/components/dropdown_menu.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/test/accrue_admin/components/overlay_components_test.exs

key-decisions:
  - "Use row maps for Detail.summary_list/1 so later detail propagation can pass strings, rendered HTML values, and optional Change/View actions without changing detail_field_list/1."
  - "Keep DropdownMenu.action_menu/1 non-modal: it renders native details/menu semantics and does not set scroll-lock, inert, scrim, focus-trap, or aria-modal attributes."
  - "Do not mark EXE-02 or IXN-01 complete from this prerequisite plan; 195-07 owns the Subscription detail conversion and Phase 199 owns the cross-page overlay sweep."

patterns-established:
  - "Row actions append visible Change/View labels with visually hidden subscription context."
  - "Action-menu groups render in caller-provided order, with danger items styled via ax-dropdown-item-danger and separated by a group divider."
  - "Dropdown dismissal behavior is covered by fake-DOM Node tests around the existing dropdown.js grammar."

requirements-completed: []
requirements-addressed: [EXE-02, IXN-01]

duration: 7m 52s
completed: 2026-06-26
status: complete
---

# Phase 195 Plan 06: Reusable DETAIL Primitives Summary

**Reusable summary-list and non-modal LiveView action-menu primitives with token-compliant source CSS and a rebuilt served admin bundle.**

## Performance

- **Duration:** 7m 52s
- **Started:** 2026-06-26T09:11:25Z
- **Completed:** 2026-06-26T09:19:17Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `Detail.summary_list/1` for semantic `<dl data-ax-summary-list>` rows with strings, rendered values, and optional row actions.
- Added `DropdownMenu.action_menu/1` for grouped `<details>` overflow actions using `<button role="menuitem" phx-click>` controls.
- Added component coverage for read-only rows, Change/View actions, hidden action context, menu semantics, danger grouping, and non-modal output.
- Added Node coverage for dropdown Escape close, outside-click close, idempotent repeated close, and focus restoration to the `<summary>` trigger.
- Added source CSS for summary-list rows/actions and action-menu grouping/dividers/top-right origin, then rebuilt `priv/static/accrue_admin.css`.

## Task Commits

1. **Task 1 RED: Add failing summary-list coverage** - `e3b63ad2` (test)
2. **Task 1 GREEN: Add Detail.summary_list/1** - `82042713` (feat)
3. **Task 2 RED: Add failing action-menu coverage** - `01ed4fbb` (test)
4. **Task 2 GREEN: Add DropdownMenu.action_menu/1** - `cea9e0c3` (feat)
5. **Task 3: Add primitive CSS and rebuild bundle** - `89e81451` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/components/detail.ex` - Adds `summary_list/1` with row-map values and optional href/LiveView event actions.
- `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` - Adds `action_menu/1` beside the existing link-shaped `dropdown_menu/1`.
- `accrue_admin/assets/css/app.css` - Adds summary-list and action-menu source styles using existing tokens.
- `accrue_admin/priv/static/accrue_admin.css` - Rebuilt minified served CSS bundle containing the new primitive styles.
- `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` - Adds component coverage for summary-list and action-menu contracts.
- `accrue_admin/test/js/dropdown_test.mjs` - Adds fake-DOM Node tests for dropdown dismissal and focus restoration.

## Verification Results

- `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs` - PASS: 16 tests, 0 failures. The run still prints the existing PhoenixStorybook `RegistryStory.variations_for/1` warning from `storybook/components/button.story.exs`.
- `cd accrue_admin && node --test test/js/dropdown_test.mjs` - PASS: 4 tests, 0 failures. Node still prints the existing module-type warning for ESM parsing of `dropdown.js`.
- `bash scripts/ci/verify_package_docs.sh` - PASS. Foundation contrast passed and the Phase 193 CSS source guards remained green.
- `cd accrue_admin && mix accrue_admin.assets.build` - PASS. The build rebuilt the committed admin CSS/JS assets and exited 0; it still prints existing Storybook dev-asset warnings.
- `git diff --check accrue_admin/assets/css/app.css accrue_admin/priv/static/accrue_admin.css` - PASS.
- Bundle probe - PASS: `accrue_admin/priv/static/accrue_admin.css` contains `ax-summary-list`, `ax-action-menu`, and `transform-origin`.

## Decisions Made

- `Detail.summary_list/1` uses row maps and supports both atom and string keys for later LiveView call-site convenience.
- `summary_list/1` intentionally does not replace `detail_field_list/1`; the latter remains the read-only drill-section field-list primitive.
- `DropdownMenu.action_menu/1` reuses native dropdown disclosure and `dropdown.js` dismissal semantics, but renders button menuitems instead of links.
- Requirements remain addressed, not completed: `EXE-02` needs the actual Subscription detail conversion and `IXN-01` remains owned by Phase 199's cross-page overlay sweep.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The focused component test continues to print a pre-existing PhoenixStorybook registry warning. It did not block compilation or tests.
- `node --test test/js/dropdown_test.mjs` prints Node's existing module-type warning because `accrue_admin/package.json` does not declare `"type": "module"`. The test exits 0.
- `mix accrue_admin.assets.build` prints existing Storybook dev-asset warnings and exits 0.

## Known Stubs

None. Stub scan found no TODO/FIXME or placeholder UI data introduced by this plan. The scan matched the pre-existing `.ax-input-placeholder` CSS class name and existing `slot != []` component guards; neither is a shipped data stub.

## Threat Flags

None. The summary row action and action-menu trust boundaries are the planned T-195-21 through T-195-24 surfaces. Mitigations shipped: row actions include hidden context, the action menu emits item values only, danger items are styled/grouped last, and the menu remains non-modal with no overlay attributes.

## User Setup Required

None - no external service configuration required.

## Self-Check

- [x] `accrue_admin/lib/accrue_admin/components/detail.ex` contains `def summary_list`.
- [x] `accrue_admin/lib/accrue_admin/components/dropdown_menu.ex` contains both `def dropdown_menu` and `def action_menu`.
- [x] `accrue_admin/test/js/dropdown_test.mjs` exists.
- [x] `accrue_admin/priv/static/accrue_admin.css` contains the summary-list and action-menu classes.
- [x] Task commit `e3b63ad2` exists.
- [x] Task commit `82042713` exists.
- [x] Task commit `01ed4fbb` exists.
- [x] Task commit `cea9e0c3` exists.
- [x] Task commit `89e81451` exists.
- [x] Final verification commands pass.
- [x] No generated runtime artifacts were left untracked, except the pre-existing `.planning/research/.cache/` directory.

## Self-Check: PASSED

## Next Phase Readiness

Plan 195-07 can now consume `Detail.summary_list/1` and `DropdownMenu.action_menu/1` to convert Subscription detail into the six-band SPEC-DETAIL page, host forms in the existing canonical drawer path, and keep destructive actions routed through StepUp.

---
*Phase: 195-exemplar-b-subscription-detail*
*Completed: 2026-06-26*
