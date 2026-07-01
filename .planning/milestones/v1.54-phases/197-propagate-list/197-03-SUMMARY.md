---
phase: 197-propagate-list
plan: "03"
subsystem: payments
tags: [elixir, phoenix, ecto, admin-ui, copy, queries, owner-scope]

requires:
  - phase: 197-propagate-list
    provides: RED contracts and LiveView list migration handoff from plans 197-01 and 197-02
provides:
  - Phase 197 list copy helper surface for Customers, Invoices, Payments, Coupons, Promotion Codes, Webhooks, Events, and Connect Accounts
  - Allowlisted Webhooks multi-status decode for replay queue defaults
  - Connect Accounts needs_attention OR query lens
  - Charges owner-scope filtering through joined customer ownership
affects: [phase-197-liveview-migrations, admin-list-copy, query-default-lenses, tenant-scope]

tech-stack:
  added: []
  patterns:
    - Central AccrueAdmin.Copy delegates expose page copy while resource copy modules own resource-specific text
    - Query modules decode URL lens params into allowlisted filters before applying Ecto predicates
    - Charges mirrors Invoices owner-scope behavior through the joined customer binding

key-files:
  created: []
  modified:
    - accrue_admin/test/accrue_admin/copy_test.exs
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/copy/billing_event.ex
    - accrue_admin/lib/accrue_admin/copy/connect.ex
    - accrue_admin/lib/accrue_admin/copy/coupon.ex
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
    - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
    - accrue_admin/lib/accrue_admin/queries/webhooks.ex
    - accrue_admin/lib/accrue_admin/queries/connect_accounts.ex
    - accrue_admin/lib/accrue_admin/queries/charges.ex

key-decisions:
  - "Webhooks replay defaults decode through an allowlisted multi-status status param instead of atom conversion from raw URL text."
  - "Connect Needs attention is a query-owned OR lens; individual readiness filters remain explicit AND filters."
  - "Payments owner scope is enforced in Charges.list/1 and count_newer_than/1 through the joined customer owner relation."

patterns-established:
  - "List copy helpers use deterministic resource-prefixed names and are reachable from AccrueAdmin.Copy."
  - "Default queue lenses must be represented by query semantics, not UI-only text."
  - "Payments tenant boundaries are applied before filters, cursors, counts, and projections."

requirements-completed: [PRP-01]

duration: 9min
completed: 2026-06-28
status: complete
---

# Phase 197 Plan 03: Shared Copy and Query Seams Summary

**Phase 197 list copy helpers plus Webhooks, Connect, and Payments query semantics for upcoming LiveView migrations**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-28T16:47:01Z
- **Completed:** 2026-06-28T16:55:38Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Added RED copy contracts and GREEN implementation for all eight Phase 197 target list pages.
- Added allowlisted Webhooks `status=failed,dead` decoding and filtering without unbounded atom creation.
- Added Connect Accounts `needs_attention=true` as a named OR predicate across readiness blockers.
- Added Charges owner-scope support through customer ownership for both list and newer-count queries.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add RED copy helper contracts** - `2b35c358` (test)
2. **Task 1 GREEN: Add Phase 197 list copy helpers** - `8203c618` (feat)
3. **Task 2: Implement Webhooks multi-status and Connect attention query semantics** - `85aaaf84` (feat)
4. **Task 3: Implement Payments owner-scope query support** - `0e9c3a63` (feat)

_Task 2 and Task 3 GREEN commits satisfied RED contracts inherited from Plan 197-01._

## Files Created/Modified

- `accrue_admin/test/accrue_admin/copy_test.exs` - Added Phase 197 copy helper contracts for page headings, state copy, labels, and result labels.
- `accrue_admin/lib/accrue_admin/copy.ex` - Added central delegates and direct copy helpers for Customers, Payments, and Webhooks.
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex` - Added Events list copy helpers.
- `accrue_admin/lib/accrue_admin/copy/connect.ex` - Added Connect Accounts list copy helpers.
- `accrue_admin/lib/accrue_admin/copy/coupon.ex` - Added Coupons list copy helpers.
- `accrue_admin/lib/accrue_admin/copy/invoice.ex` - Added Invoices list copy helpers.
- `accrue_admin/lib/accrue_admin/copy/promotion_code.ex` - Added Promotion Codes list copy helpers.
- `accrue_admin/lib/accrue_admin/queries/webhooks.ex` - Added allowlisted multi-status status decode and encoding support.
- `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex` - Added `needs_attention` decode and OR filtering.
- `accrue_admin/lib/accrue_admin/queries/charges.ex` - Added owner-scope support for payment list and count queries.

## Decisions Made

- Webhook status strings are filtered against `WebhookEvent.statuses/0` before conversion, preserving existing atom storage while avoiding arbitrary atom creation from URL params.
- Connect attention is independent from existing boolean filters so the default lens can mean "any readiness blocker" while explicit filters continue to compose normally.
- Charges reused the Invoices owner-scope pattern instead of introducing a new ownership abstraction because Charges already joins Customers for list projection.

## Deviations from Plan

None - planned code scope was executed as written.

## Issues Encountered

- Full query-module verification initially picked up stale persisted E2E rows in the local `accrue_admin_test` database. The test database was reset with `MIX_ENV=test mix ecto.drop --quiet`, then the required verification commands passed.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 3` - passed, 5 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/queries/query_modules_test.exs --max-failures 3` - passed, 21 tests, 0 failures.
- `cd accrue_admin && mix compile --warnings-as-errors` - passed.

## Known Stubs

None. Stub scan found only non-stub equality checks in query/test logic.

## Threat Flags

None. New security-relevant surfaces were the Webhooks status decoder, Connect attention predicate, and Charges owner-scope predicate already covered by the plan threat model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 197-04 through 197-06 can migrate individual LiveViews against stable copy helpers and real default-lens query behavior. Payments list migration can preserve owner-scope URLs knowing Charges filters and counts now enforce the scope.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/197-propagate-list/197-03-SUMMARY.md`.
- All 10 modified source/test files exist.
- Task commits exist: `2b35c358`, `8203c618`, `85aaaf84`, `0e9c3a63`.

---
*Phase: 197-propagate-list*
*Completed: 2026-06-28*
