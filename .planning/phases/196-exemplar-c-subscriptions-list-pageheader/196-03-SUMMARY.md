---
phase: 196-exemplar-c-subscriptions-list-pageheader
plan: "03"
subsystem: ui-components
tags: [phoenix-liveview, data-table, filter-chip-bar, spec-list, css]

requires:
  - phase: 196-exemplar-c-subscriptions-list-pageheader
    provides: RED LIST primitive contracts from 196-01 and the frozen PageHeader slot contract from 196-02
provides:
  - DataTable LIST state markers for populated, first-run-empty, filtered-empty, and loading-skeleton states
  - Accessible DataTable table/card skeleton fixture gated by explicit loading assigns
  - DataTable-owned filter toolbar helper that stays parent-targeted for `data_table_filter`
  - FilterChipBar chip row, visible result count, and caller-supplied clear-all markers
  - Focused LIST/skeleton source CSS and rebuilt committed admin CSS bundle
affects: [phase-196, phase-197, subscriptions-list, data-table, filter-chip-bar, pageheader]

tech-stack:
  added: []
  patterns:
    - DataTable derives explicit LIST markers while honoring caller-provided `list_state` and `empty_reason`
    - Loading skeletons are fixture-gated and accessible without production fake delays
    - Filter toolbar markup remains DataTable-owned but caller-positionable through PageHeader slots
    - FilterChipBar renders caller-owned URLs for chip removal and clear-all navigation

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css

key-decisions:
  - "DataTable keeps backward-compatible derived state defaults while allowing callers to pass explicit `list_state` and `empty_reason`."
  - "The loading skeleton is a truthful fixture path only: no `Process.sleep`, `:timer.sleep`, fake delay, or broad async rewrite was introduced."
  - "The filter toolbar remains DataTable-owned and parent-targeted; PageHeader can host it later without owning filter state."
  - "FilterChipBar treats result counts and clear-all hrefs as caller-supplied presentation data, preserving owner-scope responsibility outside the component."

patterns-established:
  - "LIST state markers live on the DataTable root: `data-ax-list`, `data-ax-state`, and empty-state `data-ax-empty-reason`."
  - "Skeleton accessibility uses root `aria-busy`, exactly one `role=status`, and decorative `aria-hidden` skeleton shapes."
  - "Chip/count/clear-all contracts use stable markers: `data-ax-filter-chips`, `data-ax-result-count`, and `data-ax-clear-all`."

requirements-completed: [EXE-03]

duration: 9min
completed: 2026-06-26
status: complete
---

# Phase 196 Plan 03: LIST Primitive Contract Summary

**Shared LIST primitives now expose explicit state markers, truthful skeleton fixtures, caller-positionable filter toolbar markup, and chip/count/clear-all contracts.**

## Performance

- **Duration:** 9min
- **Started:** 2026-06-26T21:01:07Z
- **Completed:** 2026-06-26T21:09:55Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added DataTable root `data-ax-list`, `data-ax-state`, and empty-reason markers with derived fallback states for existing callers.
- Added an accessible loading-skeleton fixture path with table-shaped desktop skeleton rows and card-shaped mobile skeletons.
- Extracted `DataTable.filter_toolbar/1`, added `render_filter_toolbar`, and added a `:list_status` slot with visible row count and list state slot args.
- Extended FilterChipBar with active chip row, result count, and clear-all markers while keeping all URLs caller-supplied.
- Added focused source CSS for chip/count/clear-all layout, DataTable list status, and table/card skeletons; rebuilt `priv/static/accrue_admin.css`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add DataTable LIST state markers and loading skeleton fixture** - `4f244c33` (feat)
2. **Task 2: Extract caller-owned filter toolbar and chip/count/clear row support** - `4eafeac6` (feat)
3. **Task 3: Add LIST state and skeleton styles, then rebuild admin assets** - `36bbdac5` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/components/data_table.ex` - Adds explicit LIST state markers, skeleton fixture rendering, filter toolbar helper, render toggle, and list-status slot.
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` - Adds result count, clear-all href/label, chip row markers, and count/clear markers.
- `accrue_admin/assets/css/app.css` - Adds focused styles for chip/count/clear layout, DataTable list status, and table/card skeleton fixtures.
- `accrue_admin/priv/static/accrue_admin.css` - Rebuilt generated admin CSS bundle.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs` - PASS, 32 tests.
- `cd accrue_admin && mix accrue_admin.assets.build` - PASS, regenerated `priv/static/accrue_admin.css` with no generated JS change.
- `bash scripts/ci/verify_package_docs.sh` - PASS.
- `grep -R "Process.sleep\\|:timer.sleep" accrue_admin/lib/accrue_admin/components/data_table.ex && exit 1 || exit 0` - PASS.

## Decisions Made

- Derived DataTable state remains backward-compatible for existing tables, but explicit caller state wins for Phase 196 queue/filter distinctions.
- Loading skeletons are test/fixture-driven UI states only; production synchronous reads are unchanged.
- FilterChipBar does not construct or mutate URLs; it renders caller-supplied `remove_href` and `clear_all_href` values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] DataTable toolbar helper landed with Task 1**
- **Found during:** Task 1 (DataTable LIST state markers and loading skeleton fixture)
- **Issue:** The required Task 1 verification command runs the full `data_table_test.exs` file, which already contained the Phase 196 `DataTable.filter_toolbar/1` contract from Plan 01.
- **Fix:** Added the DataTable-owned toolbar helper in the Task 1 commit, then completed built-in toolbar extraction and slot support in Task 2.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/data_table.ex`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs` passed.
- **Committed in:** `4f244c33`

**2. [Rule 3 - Blocking] Replaced raw CSS type declaration after package-doc guard failure**
- **Found during:** Task 3 (LIST state and skeleton styles)
- **Issue:** `verify_package_docs.sh` rejected a new raw `font-weight: 600` declaration in the clear-all link style.
- **Fix:** Switched the rule to `font: var(--ax-type-label-font)` and rebuilt the committed CSS bundle.
- **Files modified:** `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`
- **Verification:** `bash scripts/ci/verify_package_docs.sh` passed.
- **Committed in:** `36bbdac5`

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** Both fixes preserved the planned component boundaries and strengthened verification compliance; no scope expanded into SubscriptionsLive or PageHeader adoption.

## Issues Encountered

- PhoenixStorybook emitted existing source/asset-resolution warnings during compilation in test/dev builds. The required tests and asset build exited successfully, so no plan change was needed.

## Known Stubs

None. Stub scan false positives were limited to existing generic placeholder/input support in DataTable and generated minified CSS content; no production stub blocks the plan goal.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 196-04 can adopt these primitives in SubscriptionsLive: render the extracted filter toolbar in PageHeader, pass explicit LIST state/empty reasons, and wire FilterChipBar result count plus clear-all hrefs while preserving owner scope.

## Self-Check: PASSED

- Found all four modified files.
- Found task commits `4f244c33`, `4eafeac6`, and `36bbdac5`.
- No accidental tracked deletions were detected after task commits.

---
*Phase: 196-exemplar-c-subscriptions-list-pageheader*
*Completed: 2026-06-26*
