---
phase: 197-propagate-list
plan: "02"
subsystem: accrue_admin LiveView LIST contracts
status: complete
tags:
  - red-tests
  - liveview
  - list-contracts
  - propagation
dependency_graph:
  requires:
    - 197-01 validation scaffold
  provides:
    - RED LiveView contracts for eight Phase 197 target lists
  affects:
    - accrue_admin/test/accrue_admin/live/customers_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
tech_stack:
  added: []
  patterns:
    - Phoenix LiveViewTest RED contract assertions
    - AccrueAdmin.ListContracts shared test manifest
key_files:
  created: []
  modified:
    - accrue_admin/test/accrue_admin/live/customers_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/charges_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
decisions:
  - Reused AccrueAdmin.ListContracts from 197-01 as the single source for route, list id, lens, state, and copy assertions.
  - Kept this plan test-only so runtime Phase 197 propagation remains RED for the implementation plans.
  - Used LiveViewTest on_error warning only in the new Customers contract tests to keep assertions reachable despite the pre-existing duplicate IdBadge runtime warning.
metrics:
  completed_at: 2026-06-28T16:41:27Z
  duration: approximately 45 minutes
  tasks_completed: 3
  files_modified: 8
requirements:
  - PRP-01
---

# Phase 197 Plan 02: RED LiveView LIST Contracts Summary

Added RED LiveView contract coverage for all eight target LIST surfaces using the shared Phase 197 validation manifest.

## What Changed

Task 1 added contract tests for Customers, Coupons, and Promotion Codes. These assert PageHeader chrome, list identifiers, default and all lenses, result-count language, owner-safe clear-all behavior, list states, loading fixtures, and primary table column order.

Task 2 added contract tests for Invoices and Payments. These cover the Needs collection and Failed payments queues, payments route language, owner-safe clear-all links, first-run/filtered/queue/loading states, and billing table column priorities.

Task 3 added contract tests for Webhooks, Events, and Connect accounts. These cover Needs replay, All ledger, Admin changes, and Needs attention lenses; clear-all scoping; loading and empty states; and preservation of webhooks selection-driven replay controls.

## Commits

| Task | Commit | Description |
| --- | --- | --- |
| 1 | 317e3d2b | Added reference-list RED contracts for customers, coupons, and promotion codes. |
| 2 | 523a2c01 | Added status-queue RED contracts for invoices and payments. |
| 3 | c1815522 | Added operational RED contracts for webhooks, events, and connect accounts. |

## Verification

All required verification commands were run and exited RED as expected because runtime Phase 197 behavior is not implemented yet:

```bash
cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs --max-failures 5
cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs --max-failures 5
cd accrue_admin && mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs --max-failures 6
```

Observed failures were contract assertion failures for missing runtime propagation, including PageHeader markers, filter chips, clear-all links, list states, default queue lenses, route language, and column ordering. Setup, compile, and fixture failures were resolved before task commits.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Kept Customers RED tests reachable despite duplicate runtime IDs**
- **Found during:** Task 1
- **Issue:** Customers LiveView emitted duplicate `IdBadge` IDs in desktop and mobile render paths, causing LiveViewTest to stop before new RED contract assertions could run.
- **Fix:** Added a local `live_list/2` helper for new Customers contract tests using `on_error: :warn`, preserving RED contract signal without changing runtime code.
- **Files modified:** `accrue_admin/test/accrue_admin/live/customers_live_test.exs`
- **Commit:** 317e3d2b

**2. [Rule 3 - Blocking issue] Replaced invalid filter fixture IDs**
- **Found during:** Task 2
- **Issue:** New invoice/payment clear-all tests originally used non-UUID `customer_id` query fixtures, which triggered Ecto cast errors before UI assertions.
- **Fix:** Generated UUID customer filter values inside the tests.
- **Files modified:** `accrue_admin/test/accrue_admin/live/invoices_live_test.exs`, `accrue_admin/test/accrue_admin/live/charges_live_test.exs`
- **Commit:** 523a2c01

## Auth Gates

None.

## Known Stubs

None. Stub scan found only helper assertions such as `assert missing == []`, not placeholder UI data or mock-only wiring.

## Threat Flags

None. This plan added test-only assertions and did not introduce runtime endpoints, authentication paths, file access, schema changes, or other trust-boundary surface.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/197-propagate-list/197-02-SUMMARY.md`.
- Task commits found: `317e3d2b`, `523a2c01`, `c1815522`.
- All eight modified LiveView test files exist.
- No unrelated files were staged; `.planning/research/.cache/` remains untracked and untouched.
