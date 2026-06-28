---
phase: 197-propagate-list
plan: "04"
subsystem: ui
tags: [phoenix-liveview, accrue-admin, list-pages, page-header, data-table, filter-chip-bar]

requires:
  - phase: 196-exemplar-c-subscriptions-list-pageheader
    provides: Shared PageHeader, DataTable list-state, FilterChipBar, and DataTableNav LIST contracts
  - phase: 197-propagate-list
    provides: Phase 197 list contracts, copy helpers, and query seams from plans 01-03
provides:
  - Customers LIST propagation with PageHeader filters, FilterChipBar chips, owner-safe clear-all, and four states
  - Coupons LIST propagation with valid/default and all inventory lenses
  - Promotion codes LIST propagation with active/default and all inventory lenses
affects: [phase-197-list-propagation, phase-200-verification, accrue-admin-list-pages]

tech-stack:
  added: []
  patterns:
    - PageHeader owns list orientation, stat strip, and filter toolbar
    - DataTable owns rows/cards/states with render_filter_toolbar disabled by callers
    - FilterChipBar renders URL-backed lenses and visible result counts from DataTable list_status
    - DataTableNav.merge_query preserves org scope for filter and clear links

key-files:
  created:
    - .planning/phases/197-propagate-list/197-04-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/test/accrue_admin/live/customers_live_test.exs
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex

key-decisions:
  - "Customers remains all-default and exposes Missing payment method as a quick lens instead of manufacturing a queue."
  - "Coupons canonicalizes bare list visits to valid=true and uses view=all as the all-inventory escape hatch."
  - "Promotion codes canonicalizes bare list visits to active=true and uses view=all to keep inactive codes accessible."
  - "Clear-all links are built through DataTableNav.merge_query so organization scope is preserved while filter params are removed."

patterns-established:
  - "Reference list migration pattern: PageHeader slots plus DataTable list_status replace page-local headers and inline filter bars."
  - "Inventory-default lists distinguish first-run-empty from default-lens-empty through explicit empty_reason helpers."
  - "Raw processor IDs are secondary identity text behind operator nouns and object names."

requirements-completed: [PRP-01]

duration: 14m
completed: 2026-06-28
status: complete
---

# Phase 197 Plan 04: Propagate LIST Reference Pages Summary

**Customers, Coupons, and Promotion codes now share the locked LIST composition with PageHeader filters, URL-backed lenses, honest counts, scoped clear-all links, and state-specific copy.**

## Performance

- **Duration:** 14m
- **Started:** 2026-06-28T16:59:28Z
- **Completed:** 2026-06-28T17:13:12Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Migrated Customers to the PageHeader/DataTable/FilterChipBar LIST composition while keeping all customers visible by default and exposing Missing payment method as a quick lens.
- Migrated Coupons to a valid-coupons default with an All coupons escape hatch, owner-scope-safe clear-all, state-specific empty copy, and prioritized identity/state/value/time columns.
- Migrated Promotion codes to an active-codes default with inactive codes accessible through All, state-specific copy, owner-scope-safe clear-all, and primary code/coupon identity before raw IDs.
- Verified the migrated LiveViews plus shared PageHeader, DataTable, and FilterChipBar components together.

## Task Commits

1. **Task 1: Migrate Customers to the LIST exemplar** - `fae5e138` (feat)
2. **Task 2: Migrate Coupons to the LIST exemplar** - `7148d45f` (feat)
3. **Task 3: Migrate Promotion codes to the LIST exemplar** - `035333e3` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/customers_live.ex` - Adopted PageHeader, FilterChipBar list status, list-state helpers, owner-safe scoped paths, and distinct customer empty/loading behavior.
- `accrue_admin/test/accrue_admin/live/customers_live_test.exs` - Updated stale assertions to the Phase 197 customer LIST copy contract.
- `accrue_admin/lib/accrue_admin/live/coupons_live.ex` - Adopted PageHeader, valid/all URL lenses, owner-safe clear-all, state-specific copy, and LIST column priority.
- `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex` - Adopted PageHeader, active/all URL lenses, owner-safe clear-all, state-specific copy, and LIST column priority.

## Decisions Made

- Reused the Phase 196 Subscriptions pattern for all three pages: PageHeader owns page orientation and the filter toolbar, while DataTable renders rows/cards and exposes list status to FilterChipBar.
- Kept Customers all-default because the page is a lookup inventory, not an exception queue.
- Used `valid=true` and `active=true` as canonical inventory defaults for Coupons and Promotion codes, with `view=all` as the explicit all-records mode.
- Preserved `org` on default, filter, detail, and clear links by deriving paths from the current owner scope and routing merges through `DataTableNav.merge_query/2`.

## Deviations from Plan

None - plan executed within the planned task scope.

## Issues Encountered

- Existing Customers tests still asserted pre-197 empty/index copy. They were updated to the copy helpers introduced in Plan 03.
- Promotion-code all-view ordering made an inactive row's raw processor id appear before the active code in a broad substring assertion. The inactive secondary raw id was hidden so primary code identity remains ahead of raw ids without changing query behavior or All visibility.

## Known Stubs

None. Stub scan only found real input placeholder attributes in filter field definitions.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs` - passed
- `cd accrue_admin && mix test test/accrue_admin/live/coupons_live_test.exs` - passed
- `cd accrue_admin && mix test test/accrue_admin/live/promotion_codes_live_test.exs` - passed
- `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs` - 56 tests, 0 failures

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 197-05 through 197-07 can apply the same LIST propagation pattern to the remaining list pages. The shared PageHeader/DataTable/FilterChipBar path is now proven across an all-default lookup page and two narrowed inventory-default pages.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/197-propagate-list/197-04-SUMMARY.md`.
- Task commits found: `fae5e138`, `7148d45f`, `035333e3`.
- No accidental tracked file deletions were detected after task commits.
- The only unrelated untracked path remains `.planning/research/.cache/`.

---
*Phase: 197-propagate-list*
*Completed: 2026-06-28*
