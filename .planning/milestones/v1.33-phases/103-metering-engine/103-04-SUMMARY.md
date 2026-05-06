---
phase: 103-metering-engine
plan: 04
subsystem: payments
tags: [braintree, metering, telemetry, oban, docs]
requires:
  - phase: 103-metering-engine
    provides: "Plan 01-03 local metering, invoice authoring, and settlement state"
provides:
  - "Stale-window metered renewal backstop that reuses webhook-opened renewal truth"
  - "Durable Braintree metered-billing ops tuples and default counters"
  - "Public and operator docs for local aggregation plus one-sale settlement"
affects: [phase-103-closeout, metered-billing, operator-recovery]
tech-stack:
  added: []
  patterns: [scheduled-backstop-not-primary-clock, durable-metric-ops-catalog, honest-braintree-metering-docs]
key-files:
  created:
    - accrue/lib/accrue/jobs/metered_renewal_reconciler.ex
    - accrue/guides/braintree-metered-billing.md
    - accrue/test/accrue/jobs/metered_renewal_reconciler_test.exs
    - accrue/test/accrue/telemetry/metered_billing_ops_test.exs
  modified:
    - accrue/lib/accrue/billing/metered_renewal_actions.ex
    - accrue/lib/accrue/billing/metered_renewal_invoice.ex
    - accrue/lib/accrue/telemetry/ops.ex
    - accrue/lib/accrue/telemetry/metrics.ex
    - accrue/test/support/telemetry_ops_inventory.ex
    - accrue/guides/metering.md
    - accrue/guides/telemetry.md
    - accrue/guides/operator-runbooks.md
key-decisions:
  - "The scheduled reconciler only repairs stale renewal windows after a grace period and reuses the same Braintree renewal-opening contract as the webhook path."
  - "Metered-billing ops tuples fire on durable renewal or settlement transitions, not on raw retry attempts."
  - "Public docs keep the processor distinction explicit: Stripe has native meters; Braintree uses local aggregation plus one settlement sale."
patterns-established:
  - "Use a reconciler as a narrow repair backstop instead of a scheduler-owned billing clock."
  - "Keep metered recovery observable through low-cardinality counters and PII-free ops metadata."
requirements-completed: [BT-06, BT-07]
duration: 6 min
completed: 2026-05-03
---

# Phase 103 Plan 04 Summary

**Phase 103 now closes with a webhook-primary stale-window repair path, durable Braintree metered-billing ops telemetry, and docs that explain the local-ledger-first settlement model honestly.**

## Performance

- **Duration:** 6 min
- **Completed:** 2026-05-03T01:38:00Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Added `Accrue.Jobs.MeteredRenewalReconciler` to detect stale Braintree renewal windows after a grace period and reopen them through the existing renewal-opening seam instead of inventing a second billing path.
- Added explicit metered-billing ops tuples and default counters for stale renewal repair, missing local meter definitions, awaiting-payment-method recovery, and failed-exhausted settlement.
- Updated the public metering, telemetry, and operator guides and added `accrue/guides/braintree-metered-billing.md` as the canonical explanation of local aggregation, renewal windows, local invoice decomposition, and one `Transaction.sale` settlement per closed period.
- Revalidated the phase verification lane with the scoped metering/telemetry suites plus telemetry inventory and docs grep checks.

## Task Commits

1. **Task 1: Add tests for stale-window recovery and metered-billing ops telemetry** - `3cf0bee` (`test`)
2. **Task 2: Implement stale-window reconciler and metered-billing telemetry catalog** - `aabda22` (`feat`)
3. **Task 3: Document Braintree metering, telemetry, and operator recovery** - `3aca7fa` (`docs`)

## Files Created/Modified

- `accrue/lib/accrue/jobs/metered_renewal_reconciler.ex` - scheduled stale-window repair worker for Braintree metered renewals.
- `accrue/lib/accrue/billing/metered_renewal_actions.ex` - durable settlement-state telemetry emission on metered recovery transitions.
- `accrue/lib/accrue/billing/metered_renewal_invoice.ex` - missing-definition ops emission from local renewal invoice authoring.
- `accrue/lib/accrue/telemetry/ops.ex` - canonical metered-billing ops tuple catalog additions.
- `accrue/lib/accrue/telemetry/metrics.ex` - low-cardinality metered-billing counters.
- `accrue/test/accrue/jobs/metered_renewal_reconciler_test.exs` - stale-window backstop and one-shot repair telemetry coverage.
- `accrue/test/accrue/telemetry/metered_billing_ops_test.exs` - durable metered-billing ops event and counter coverage.
- `accrue/test/support/telemetry_ops_inventory.ex` - telemetry inventory parity for the new ops tuples.
- `accrue/guides/braintree-metered-billing.md` - canonical public Braintree metered-billing guide.
- `accrue/guides/metering.md` - shared ingress guide updated with the Stripe vs Braintree processor distinction.
- `accrue/guides/telemetry.md` - exact metered-billing tuples, semantics, and metric names.
- `accrue/guides/operator-runbooks.md` - ordered stale renewal, missing-definition, awaiting-payment-method, and failed-exhausted recovery steps.

## Verification

- `cd accrue && mix test test/accrue/jobs/metered_renewal_reconciler_test.exs test/accrue/telemetry/metered_billing_ops_test.exs --warnings-as-errors`
- `cd accrue && mix test test/accrue/jobs/metered_renewal_reconciler_test.exs test/accrue/telemetry/metered_billing_ops_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs test/accrue/telemetry/metrics_test.exs --warnings-as-errors && test -f guides/braintree-metered-billing.md && test -f ../.planning/phases/103-metering-engine/103-VALIDATION.md && rg -n "local aggregation|renewal window|Transaction\\.sale|awaiting-payment-method|failed-exhausted" guides/braintree-metered-billing.md guides/operator-runbooks.md && rg -n "metered_|accrue\\.ops\\.|wave_0_complete: true|nyquist_compliant: true" guides/telemetry.md ../.planning/phases/103-metering-engine/103-VALIDATION.md`

## Decisions Made

- The stale renewal backstop counts repaired windows, not every stale subscription scanned, so the worker stays aligned with the actual repair action.
- Metered settlement telemetry is emitted only after the durable renewal state write succeeds, preserving the one-transition-one-event contract.
- The new guide keeps Braintree metering separate from the shared `report_usage/3` surface so adopters do not infer Stripe-native parity where none exists.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed metered recovery telemetry to use the post-transition charge attempt**
- **Found during:** Task 2 verification
- **Issue:** `failure_class` metadata for `failed_exhausted` and `awaiting_payment_method` was emitted from the pre-update attempt row, which left the docs-stable metadata incomplete.
- **Fix:** Bound the updated charge-attempt rows returned from `MeteredChargeAttempts.*` and passed those durable values into the renewal-state telemetry path.
- **Files modified:** `accrue/lib/accrue/billing/metered_renewal_actions.ex`
- **Commit:** `aabda22`

## Issues Encountered

- `gsd-sdk` is unavailable in this workspace, and `.planning/STATE.md` already has unrelated local edits. Shared planning-state updates and the metadata-only final docs commit were not performed to avoid touching dirty global planning files outside Plan 04 ownership.

## Known Stubs

None.

## Self-Check

PASSED

- Summary file exists at `.planning/phases/103-metering-engine/103-04-SUMMARY.md`.
- Commit `3cf0bee` exists for the RED test gate.
- Commit `aabda22` exists for the GREEN implementation gate.
- Commit `3aca7fa` exists for the documentation task.
