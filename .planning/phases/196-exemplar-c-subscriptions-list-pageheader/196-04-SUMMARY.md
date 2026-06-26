---
phase: 196-exemplar-c-subscriptions-list-pageheader
plan: "04"
status: complete
completed_at: "2026-06-26T21:33:00Z"
subsystem: accrue_admin
requirements:
  - EXE-03
  - PGH-01
tags:
  - pageheader
  - subscriptions
  - list
  - liveview
dependency_graph:
  requires:
    - 196-02
    - 196-03
  provides:
    - Subscriptions PageHeader adoption
    - Subscriptions LIST exemplar states
    - owner-safe default queue clear-all
  affects:
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
tech_stack:
  added: []
  patterns:
    - Phoenix LiveView PageHeader slot composition
    - DataTable list_status slot and explicit LIST markers
    - DataTableNav URL-backed filter mutation
key_files:
  created:
    - .planning/phases/196-exemplar-c-subscriptions-list-pageheader/196-04-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
decisions:
  - PageHeader hosts Subscriptions slots only; SubscriptionsLive and DataTableNav continue owning filter/list state.
  - Bare Subscriptions first paint assigns the At risk queue before disconnected render and canonicalizes connected navigation through DataTableNav.merge_query/2.
  - The status column renders StatusBadge output through Phoenix.HTML.Safe before returning safe HTML from the DataTable cell callback.
metrics:
  duration: 12m
  tasks_completed: 3
  files_changed: 4
  commits:
    - ca5b51de
    - b9ad420a
    - f2a4a099
    - e4ba40ee
---

# Phase 196 Plan 04: Subscriptions PageHeader and LIST Exemplar Summary

PageHeader-hosted Subscriptions list with default At risk queue, exact state copy, explicit LIST markers, owner-safe clear-all, and prioritized identity/state/plan/time/signal columns.

## What Changed

- Replaced the inline Subscriptions header with `PageHeader.page_header/1`, moving breadcrumbs, description, summary stats, and the filter toolbar into PageHeader slots.
- Disabled the duplicate DataTable-owned filter toolbar while preserving `handle_event("data_table_filter", ...)` and `DataTableNav.patch_with_filters/3`.
- Made bare `/subscriptions` render the default At risk queue before disconnected first paint and canonicalize connected navigation with `DataTableNav.merge_query/2`.
- Added exact Subscriptions list copy for first-run empty, queue empty, filtered empty, and unavailable plan/amount text.
- Added persistent FilterChipBar list status with visible count, active constraint chips, All chip behavior, and clear-all links that preserve organization scope and land on `view=all`.
- Wired explicit LIST attrs for Subscriptions: `data-ax-list="subscriptions"`, empty reasons, list states, and the test-runtime-only `phase196_state=loading-skeleton` hook.
- Reordered columns to customer/subscription identity, state, plan/amount, renewal/end timing, and signals; raw subscription IDs now appear as secondary text.

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Replace inline Subscriptions header with PageHeader slots | ca5b51de | `subscriptions_live.ex`, `subscriptions_live_test.exs` |
| 2 | Implement default queue, All chip, clear-all, and state copy | b9ad420a | `subscriptions_live.ex`, `copy/subscription.ex`, `copy.ex`, `subscriptions_live_test.exs` |
| 3 | Prioritize columns and wire explicit LIST states | f2a4a099 | `subscriptions_live.ex`, `copy/subscription.ex`, `copy.ex`, `subscriptions_live_test.exs` |
| Fix | Render subscription states with StatusBadge | e4ba40ee | `subscriptions_live.ex` |

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs:82` - passed, 1 test.
- `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs:57 test/accrue_admin/live/subscriptions_live_test.exs:96 test/accrue_admin/live/subscriptions_live_test.exs:110 test/accrue_admin/live/subscriptions_live_test.exs:131` - passed, 4 tests.
- `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs` - passed, 12 tests.
- `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs` - passed, 35 tests.
- `cd accrue_admin && mix compile --warnings-as-errors` - passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical plan conformance] Status column initially mirrored StatusBadge markup directly**
- **Found during:** Task 3 final review
- **Issue:** The first implementation preserved the visual status badge contract but did not call `AccrueAdmin.Components.StatusBadge.status_badge/1` as requested.
- **Fix:** Routed state cells through `StatusBadge.status_badge/1`, converted the rendered component through `Phoenix.HTML.Safe`, and returned safe HTML for the existing DataTable cell callback.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`
- **Commit:** e4ba40ee

## Auth Gates

None.

## Known Stubs

None. `Plan and amount unavailable` is intentional D-07 copy for rows without projected plan/amount fields, not an unwired placeholder.

## Threat Flags

None. The changed trust surfaces were already covered by T-196-15 through T-196-20 in the plan threat register.

## Self-Check: PASSED

- Found expected files: `subscriptions_live.ex`, `copy/subscription.ex`, `copy.ex`, and `subscriptions_live_test.exs`.
- Found commits: `ca5b51de`, `b9ad420a`, `f2a4a099`, and `e4ba40ee`.
- No unexpected tracked file deletions.
- No Customers, Payouts, Webhooks, or other Phase 196 list pages were changed.
