---
phase: 19-tax-location-and-rollout-safety
plan: 03
subsystem: payments
tags: [stripe-tax, webhooks, invoices, subscriptions, ecto, exunit]
requires:
  - phase: 19-01
    provides: sanitized processor tax-location failures and Fake invalid-location payload parity
  - phase: 18-03
    provides: narrow automatic-tax projection columns on subscriptions and invoices
provides:
  - Disabled-reason storage for subscription and invoice automatic-tax rollback states
  - Invoice projection of finalization error codes from canonical processor payloads
  - Default webhook reconciliation for invoice.updated and invoice.finalization_failed
affects: [19-04, TAX-03, billing projections, webhook reconciliation]
tech-stack:
  added: []
  patterns: [narrow tax observability columns, canonical invoice webhook reconciliation]
key-files:
  created:
    - .planning/phases/19-tax-location-and-rollout-safety/19-03-SUMMARY.md
    - accrue/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs
    - accrue/test/accrue/webhook/default_handler_test.exs
  modified:
    - accrue/lib/accrue/billing/subscription.ex
    - accrue/lib/accrue/billing/invoice.ex
    - accrue/lib/accrue/billing/subscription_projection.ex
    - accrue/lib/accrue/billing/invoice_projection.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/test/accrue/billing/subscription_projection_tax_test.exs
    - accrue/test/accrue/billing/invoice_projection_test.exs
key-decisions:
  - "Persisted only `automatic_tax_disabled_reason` and `last_finalization_error_code`; full provider payloads still live in `data`."
  - "Reconciled the async failure family by extending the existing canonical invoice reducer instead of adding a separate error-sync path."
patterns-established:
  - "Automatic-tax projection helpers must carry `disabled_reason` for both string-keyed Stripe payloads and atom-keyed Fake payloads."
  - "Invoice rollout-failure visibility stays queryable through additive string columns, not raw finalization messages."
requirements-completed: [TAX-03]
duration: 10 min
completed: 2026-04-17
---

# Phase 19 Plan 03: Tax Rollout Failure Reconciliation Summary

**Recurring tax-location rollback is now projected into local subscription and invoice rows, and invoice failure webhooks reconcile finalization error state through the default handler**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-17T18:03:00Z
- **Completed:** 2026-04-17T18:13:31Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Added additive billing-table columns for automatic-tax disabled reasons and invoice finalization error codes.
- Extended subscription and invoice projections so invalid-location rollback state survives locally in queryable fields while raw provider payloads remain in `data`.
- Taught the default webhook reducer to reconcile `invoice.updated` and `invoice.finalization_failed`, with focused tests covering both invalid-location rollback and finalization failure payloads.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add narrow tax-rollout observability columns** - `f896f3a` (feat)
2. **Task 2: Reconcile disabled-reason and finalization-failure state** - `06a96b6` (feat)

## Files Created/Modified
- `accrue/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs` - Adds additive disabled-reason and finalization-error columns.
- `accrue/lib/accrue/billing/subscription.ex` - Persists subscription automatic-tax disabled reasons.
- `accrue/lib/accrue/billing/invoice.ex` - Persists invoice automatic-tax disabled reasons and finalization error codes.
- `accrue/lib/accrue/billing/subscription_projection.ex` - Projects `automatic_tax.disabled_reason` from Stripe and Fake payloads.
- `accrue/lib/accrue/billing/invoice_projection.ex` - Projects invoice disabled reasons and `last_finalization_error.code`.
- `accrue/lib/accrue/webhook/default_handler.ex` - Reconciles `invoice.updated` and `invoice.finalization_failed`.
- `accrue/test/accrue/billing/subscription_projection_tax_test.exs` - Covers disabled-reason projection for string-keyed and atom-keyed payloads.
- `accrue/test/accrue/billing/invoice_projection_test.exs` - Covers disabled-reason and finalization-error projection from canonical invoice payloads.
- `accrue/test/accrue/webhook/default_handler_test.exs` - Covers invalid-location invoice rollback and finalization-failed webhook reconciliation.

## Decisions Made
- Kept rollout-failure observability string-only and additive so existing non-tax hosts can migrate safely without raw Stripe error storage.
- Used the canonical invoice refetch path for the new webhook family so async invalid-location failures stay consistent with the existing reducer model.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored the planned webhook test path**
- **Found during:** Task 2 (Reconcile disabled-reason and finalization-failure state)
- **Issue:** The plan's verification command targeted `accrue/test/accrue/webhook/default_handler_test.exs`, but the repo only had `default_handler_phase3_test.exs`, so the plan-local test command could not run as written.
- **Fix:** Added `accrue/test/accrue/webhook/default_handler_test.exs` with the rollout-failure coverage the plan expected and kept the rest of the older phase-3 suite untouched.
- **Files modified:** `accrue/test/accrue/webhook/default_handler_test.exs`
- **Verification:** `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/webhook/default_handler_test.exs`
- **Committed in:** `06a96b6`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix only restored the planned verification surface. No behavior outside the task scope changed.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 19 now has local persistence and webhook reconciliation for recurring invalid-location rollback and invoice finalization failures. The remaining TAX-03 work is the operator-facing admin and host visibility planned in 19-04.

## Verification

- `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs`
- `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/webhook/default_handler_test.exs`

## Self-Check: PASSED

- Found `.planning/phases/19-tax-location-and-rollout-safety/19-03-SUMMARY.md`
- Found `accrue/priv/repo/migrations/20260417193000_add_tax_rollout_safety_columns.exs`
- Found commit `f896f3a`
- Found commit `06a96b6`
