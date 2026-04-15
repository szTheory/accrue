---
phase: 07-admin-ui-accrue-admin
plan: 11
subsystem: ui
tags: [phoenix, liveview, components, cursor-pagination, polling]
requires:
  - phase: 07-admin-ui-accrue-admin
    provides: Shared admin query modules, shell primitives, and display/navigation component conventions
provides:
  - Shared `AccrueAdmin.Components.DataTable` LiveComponent for query-driven admin lists
  - URL-driven filter rendering, cursor pagination, card mode, bulk selection, and explicit newer-row reload semantics
  - Focused contract-level regression coverage for reusable list behaviors
affects: [07-05, 07-06, 07-07, 07-12]
tech-stack:
  added: []
  patterns: [query-behaviour-driven LiveComponent lists, explicit newer-row polling banners, visible-row bulk selection for shared admin tables]
key-files:
  created:
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/queries/behaviour.ex
    - accrue_admin/test/accrue_admin/queries/query_modules_test.exs
key-decisions:
  - "DataTable consumes only the `AccrueAdmin.Queries.*` behaviour plus caller-provided column/card definitions, so list pages do not embed resource-specific query or rendering assumptions."
  - "Polling only raises a `{N} new rows - click to load` banner and never auto-inserts rows, preserving the bounded DOM and explicit operator control required by the plan."
  - "Bulk selection is scoped to the currently visible rows so pagination and DOM capping do not create hidden selection state."
patterns-established:
  - "Shared list pattern: decode filters from URL params, call the query behaviour, and keep pagination/polling state inside one reusable LiveComponent."
  - "Admin list verification pattern: use an isolated LiveView plus an in-memory fake query module to prove shared table behavior without binding tests to a specific billing resource."
requirements-completed: [ADMIN-02, ADMIN-07, ADMIN-09, ADMIN-11, ADMIN-13, ADMIN-15, ADMIN-16, ADMIN-17, ADMIN-18, ADMIN-19, ADMIN-27]
duration: 8m
completed: 2026-04-15
---

# Phase 7 Plan 11: Shared DataTable Primitive Summary

**Shared query-driven admin DataTable with URL-synced filters, cursor pagination, card mode, bulk selection, and explicit newer-row reloads**

## Performance

- **Duration:** 8m
- **Started:** 2026-04-15T17:53:00Z
- **Completed:** 2026-04-15T18:01:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `AccrueAdmin.Components.DataTable` as the reusable stateful list primitive for later Phase 7 pages instead of leaving list behavior page-local.
- Kept filter state URL-driven while adding local component behavior for cursor pagination, visible-row selection, card rendering, and the explicit poll-banner reload path.
- Added focused contract-level tests that exercise the shared list behaviors through an isolated LiveView and fake query module rather than a resource-specific page suite.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement core DataTable rendering, filter round-tripping, and cursor pagination** - `2adf37a` (feat)
2. **Task 2: Extend DataTable with mobile card mode, bulk selection, and poll-banner updates** - `261e6d3` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/components/data_table.ex` - shared LiveComponent for query-driven admin lists, selection state, card rendering, and explicit newer-row polling.
- `accrue_admin/test/accrue_admin/components/data_table_test.exs` - focused regression suite covering filter round-tripping, pagination, card mode, bulk selection, and newer-row reload behavior.
- `accrue_admin/lib/accrue_admin/queries/behaviour.ex` - corrected shared cursor pagination helper semantics so next-page cursors advance from the last visible row instead of the sentinel row.
- `accrue_admin/test/accrue_admin/queries/query_modules_test.exs` - adjusted query-contract coverage to match the corrected pagination and newer-row counting semantics.

## Decisions Made

- Kept row and card rendering fully caller-shaped through explicit column/card definitions so the shared table never renders entire structs blindly.
- Scoped poll refreshes to a banner plus explicit operator action instead of auto-streaming rows into long-lived sessions.
- Treated visible-row bulk actions as component-owned UI state rather than pushing ad hoc selection logic down into each page LiveView.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected shared cursor pagination semantics in the query helper**
- **Found during:** Task 1 verification
- **Issue:** `AccrueAdmin.Queries.Behaviour.paginate/3` emitted the sentinel row as the next cursor, which skipped the final visible record on the next page.
- **Fix:** Changed the helper to encode the last visible row as the next cursor and updated the query-module regression to assert the corrected newer-row semantics.
- **Files modified:** `accrue_admin/lib/accrue_admin/queries/behaviour.ex`, `accrue_admin/test/accrue_admin/queries/query_modules_test.exs`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/queries/query_modules_test.exs --warnings-as-errors`
- **Committed in:** `2adf37a`

---

**Total deviations:** 1 auto-fixed (1 Rule 1)
**Impact on plan:** The fix was required for correct cursor pagination across all shared admin list pages. No scope creep beyond the shared list contract.

## Issues Encountered

- The shared pagination helper from the earlier query foundation plan produced a skipping cursor once the DataTable tried to page through real result sets; that had to be corrected inline before the list primitive could be considered valid.
- `live_isolated/3` renders the component twice on mount (disconnected and connected), so the focused test suite needed to assert on contract payloads rather than assume a single query call.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later admin page plans can mount one stable list primitive instead of rebuilding filter, pagination, selection, and poll-banner behavior per page.
- The list contract is now verified in isolation, which gives upcoming dashboard, billing, and webhook pages a narrower regression loop when they wire page-specific query modules into the shared table.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-11-SUMMARY.md`
- Found task commit `2adf37a` in git history
- Found task commit `261e6d3` in git history
