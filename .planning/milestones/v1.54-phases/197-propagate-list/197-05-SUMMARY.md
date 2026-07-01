---
phase: 197-propagate-list
plan: "05"
subsystem: accrue_admin
status: complete
completed: 2026-06-28T17:29:01Z
duration: 9m 38s
tags:
  - phase-197
  - list-contracts
  - liveview
  - admin-ui
  - invoices
  - payments
dependency_graph:
  requires:
    - 197-01
    - 197-02
    - 197-03
    - 197-04
  provides:
    - invoices-list-contract
    - payments-list-contract
  affects:
    - phase-200-visual-uat
    - accrue-admin-list-surfaces
tech_stack:
  added: []
  patterns:
    - PageHeader stat_strip and filter_toolbar slots
    - DataTable list_id list_state empty_reason contract
    - FilterChipBar list_status result-count contract
    - owner-scope query propagation
key_files:
  created:
    - .planning/phases/197-propagate-list/197-05-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
decisions:
  - Kept payments backed by AccrueAdmin.Queries.Charges while presenting payment terminology in the LIST UI.
  - Reused the Phase 197 PageHeader/DataTable/FilterChipBar contract from prior migrated list pages.
  - Preserved organization scope through default queue redirects, clear-all links, row links, and summary counts.
metrics:
  tasks_completed: 2
  tests: 75 plan-level tests passed
requirements:
  - PRP-01
commits:
  - be64172e
  - 10260c0a
---

# Phase 197 Plan 05: Invoices and Payments LIST Summary

Invoices and payments now use the Phase 197 LIST exemplar pattern with PageHeader-hosted filters, visible queue chips, scoped clear-all links, list state metadata, and copy-backed empty/loading states.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Migrate Invoices list to LIST exemplar | be64172e | `invoices_live.ex`, `invoices_live_test.exs` |
| 2 | Migrate Payments list through ChargesLive | 10260c0a | `charges_live.ex`, `charges_live_test.exs` |

## Implementation Notes

- Invoices now render through `PageHeader.page_header`, suppress the DataTable inline filter toolbar, and render queue/filter chips in the DataTable `:list_status` slot with visible result counts.
- Invoices preserve organization scope in default queue redirects, row links, and clear-all links, and use owner-scoped summary counts for first-run empty detection.
- Payments now render through the same contract while keeping `query_module={Charges}` as the existing data boundary.
- Payments expose the default Failed payments queue, All payments lens, scoped clear-all links, loading fixture support, and payment-focused columns in the expected order.
- Payments summary counts now respect organization owner scope, including refunded charge counts.

## Verification

RED checks:
- `mix test test/accrue_admin/live/invoices_live_test.exs` failed before the invoice implementation on the pre-existing Phase 197 contract assertions.
- `mix test test/accrue_admin/live/charges_live_test.exs` failed before the payments implementation on the pre-existing Phase 197 contract assertions.

GREEN checks:
- `mix test test/accrue_admin/live/invoices_live_test.exs` passed with 9 tests, 0 failures.
- `mix test test/accrue_admin/live/charges_live_test.exs` passed with 8 tests, 0 failures.
- `mix test test/accrue_admin/queries/query_modules_test.exs --max-failures 3` passed with 21 tests, 0 failures.
- Plan-level matrix passed with 75 tests, 0 failures:
  `mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/queries/query_modules_test.exs test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs --max-failures 3`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated stale legacy empty-copy assertions**
- **Found during:** Tasks 1 and 2
- **Issue:** Existing LiveView tests still asserted pre-Phase 197 empty-state copy after the migrated LIST contract supplied specific first-run, queue, filtered, and loading copy.
- **Fix:** Updated those assertions to the Phase 197 copy helpers used by the new list contracts.
- **Files modified:** `accrue_admin/test/accrue_admin/live/invoices_live_test.exs`, `accrue_admin/test/accrue_admin/live/charges_live_test.exs`
- **Commit:** be64172e, 10260c0a

## Auth Gates

None.

## Known Stubs

None. The stub scan found only intentional form placeholders, literal `%{}` comparisons for scope checks, and test assertions.

## Deferred Issues

None.

## Self-Check: PASSED

- Found created summary file: `.planning/phases/197-propagate-list/197-05-SUMMARY.md`
- Found modified implementation files: `invoices_live.ex`, `charges_live.ex`
- Found modified contract tests: `invoices_live_test.exs`, `charges_live_test.exs`
- Found task commit `be64172e`
- Found task commit `10260c0a`
- No tracked file deletions were introduced.
- Untracked `.planning/research/.cache/` was left untouched.
