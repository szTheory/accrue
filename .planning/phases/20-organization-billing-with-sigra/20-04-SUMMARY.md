---
phase: 20-organization-billing-with-sigra
plan: 04
subsystem: auth
tags: [sigra, liveview, organization-billing, admin-scope, webhook-replay]
requires:
  - phase: 20-organization-billing-with-sigra
    provides: Admin owner-scope session threading and `current_owner_scope` resolution from plan 20-03
provides:
  - Owner-aware customer, subscription, and invoice query loaders keyed by active organization
  - Webhook detail and bulk replay proof that fails closed on out-of-scope or ambiguous ownership
  - Focused ORG-03 regression coverage for cross-org denial and webhook ambiguity
affects: [phase-20-plan-05, phase-20-plan-06, org-billing, accrue-admin]
tech-stack:
  added: []
  patterns: [query-layer owner proof via customer joins, webhook replay proof via local billing causality]
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/queries/customers.ex
    - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
    - accrue_admin/lib/accrue_admin/queries/invoices.ex
    - accrue_admin/lib/accrue_admin/queries/webhooks.ex
    - accrue_admin/lib/accrue_admin/queries/events.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
key-decisions:
  - "Owner proof now lives in the query modules themselves, so admin detail loaders return `:not_found` before any LiveView assigns a row."
  - "Webhook ownership proof accepts only a single in-scope billing lineage; rows with no proof or mixed proof return `{:ambiguous, proof_context}` and are not replayable."
patterns-established:
  - "Pass `owner_scope` into admin query modules and join back to `Accrue.Billing.Customer.owner_type` and `owner_id` for organization detail/list access."
  - "Treat webhook payload ids and event causality as advisory proof inputs that must converge on one in-scope organization before the row is returned."
requirements-completed: [ORG-03]
duration: 16 min
completed: 2026-04-17
---

# Phase 20 Plan 04: Admin Query Loader Scope Summary

**`accrue_admin` query loaders now prove organization ownership before returning customer, subscription, invoice, or replayable webhook rows.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-04-17T20:01:00Z
- **Completed:** 2026-04-17T20:17:28Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added RED regression coverage for ORG-03 loader denial across customer, subscription, invoice, webhook, and bulk replay paths.
- Scoped customer, subscription, and invoice queries by organization owner proof through the persisted customer ownership columns.
- Replaced global webhook detail behavior with owner-aware proofing that returns `{:ok, row}`, `:not_found`, or `{:ambiguous, proof_context}`.
- Added event-query owner scoping so org-scoped admin activity views no longer bypass customer ownership checks.

## Task Commits

1. **Task 1: Add ORG-03 regression coverage for owner-aware query loaders** - `8347e27` (test)
2. **Task 2: Gate ORG-03 admin query modules on owner proof and webhook ambiguity** - `2568995` (feat)

## Files Created/Modified

- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - adds cross-org customer loader denial coverage.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - adds cross-org subscription loader denial coverage.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - adds cross-org invoice loader denial coverage.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - adds in-scope, out-of-scope, and ambiguous webhook proof coverage.
- `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` - adds scoped bulk replay count coverage.
- `accrue_admin/lib/accrue_admin/queries/customers.ex` - adds organization owner-scope filtering and detail lookup.
- `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` - adds organization owner-scope filtering and detail lookup.
- `accrue_admin/lib/accrue_admin/queries/invoices.ex` - adds organization owner-scope filtering and detail lookup.
- `accrue_admin/lib/accrue_admin/queries/webhooks.ex` - adds webhook ownership proof, ambiguity handling, and scoped replay counts.
- `accrue_admin/lib/accrue_admin/queries/events.ex` - adds owner-aware event filtering for organization scope.

## Decisions Made

- Query modules now accept owner scope directly instead of leaving org filtering to downstream LiveViews.
- Webhook proofing prefers local invoice, subscription, customer, and event-subject causality, and it fails closed when proof is missing or mixed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The initial RED run exposed a few malformed test patterns before it reached the intended missing loader APIs; those assertions were corrected and the RED gate then failed on the absent owner-aware query contracts.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan `20-05` can now switch the customer, subscription, and event LiveViews over to these owner-aware loaders and preserve the denial copy contract without leaking row data first.
- Plan `20-06` can reuse the webhook ambiguity result and scoped replay counts instead of inventing another replay authorization path in the UI layer.

## Self-Check: PASSED

---
*Phase: 20-organization-billing-with-sigra*
*Completed: 2026-04-17*
