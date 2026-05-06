---
phase: 103-metering-engine
plan: 03
subsystem: payments
tags: [braintree, metering, settlement, oban, ecto]
requires:
  - phase: 103-metering-engine
    provides: "Plan 01 renewal-window anchors and Plan 02 local invoice authoring"
provides:
  - "Replay-safe settlement state for one metered renewal window"
  - "Braintree off-session sale support for authored metered invoices"
  - "Durable recovery states for retryable, payment-method, and terminal failures"
affects: [phase-103-plan-04, metered-billing, operator-recovery]
tech-stack:
  added: []
  patterns: [renewal-owned-settlement-ledger, replay-safe-braintree-sale, typed-settlement-recovery]
key-files:
  created:
    - accrue/lib/accrue/billing/metered_charge_attempt.ex
    - accrue/lib/accrue/billing/metered_charge_attempts.ex
    - accrue/priv/repo/migrations/20260503102000_create_accrue_metered_charge_attempts.exs
  modified:
    - accrue/lib/accrue/billing/metered_renewal.ex
    - accrue/lib/accrue/billing/metered_renewal_actions.ex
    - accrue/lib/accrue/errors.ex
    - accrue/lib/accrue/jobs/process_metered_renewal.ex
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/test/accrue/billing/metered_charge_attempts_test.exs
    - accrue/test/accrue/jobs/process_metered_renewal_test.exs
    - accrue/test/accrue/processor/braintree_test.exs
key-decisions:
  - "One metered renewal owns exactly one durable charge-attempt row, and recovery mutates that row instead of creating a second settlement unit."
  - "Renewal settlement resolves the customer's current default payment method at replay time so payment-method repair reuses the same period-owned idempotency subject."
  - "Braintree sale failures are translated into typed retryable or hard-decline errors before renewal state transitions are persisted."
patterns-established:
  - "Settle authored metered invoices through a renewal-owned idempotency subject derived from the renewal id, not from transient worker attempts."
  - "Persist recovery state on both the renewal row and the charge-attempt row so operator replay keeps the original failure audit intact."
requirements-completed: [BT-06, BT-07]
duration: 5 min
completed: 2026-05-03
---

# Phase 103 Plan 03 Summary

**Metered renewal windows now settle through one replay-safe Braintree sale with durable recovery state for retries, missing payment methods, and hard declines.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-03T01:21:30Z
- **Completed:** 2026-05-03T01:26:25Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added a renewal-owned `MeteredChargeAttempt` ledger plus a migration so one closed period can persist settlement state, retry timing, and original failure audit without duplicating external sales.
- Extended `MeteredRenewalActions` and `ProcessMeteredRenewal` from local invoice authoring into full settlement, including replay-safe idempotency, current default-payment-method resolution, and renewal state transitions to `retry_scheduled`, `awaiting_payment_method`, `paid`, or `failed_exhausted`.
- Replaced the Braintree `create_charge/2` stub with an off-session `Transaction.sale` path and added focused tests that pin payload shape plus typed failure translation.

## Task Commits

1. **Task 1: Add tests for renewal settlement, replay safety, and typed recovery states** - `264fa16` (`test`)
2. **Task 2: Implement charge-attempt persistence, renewal settlement worker, and Braintree sale support** - `6c668b1` (`feat`)

## Files Created/Modified

- `accrue/lib/accrue/billing/metered_charge_attempt.ex` - schema for one canonical renewal-owned settlement row.
- `accrue/lib/accrue/billing/metered_charge_attempts.ex` - attempt upsert and recovery-state transitions.
- `accrue/lib/accrue/billing/metered_renewal.ex` - paid timestamp support for settled renewal windows.
- `accrue/lib/accrue/billing/metered_renewal_actions.ex` - authored-invoice-to-settlement pipeline, payment-method replay, and renewal state updates.
- `accrue/lib/accrue/errors.ex` - typed metered-settlement prerequisite and conflict errors.
- `accrue/lib/accrue/jobs/process_metered_renewal.ex` - worker now continues from invoice authoring into settlement.
- `accrue/lib/accrue/processor/braintree.ex` - off-session sale request/response translation for metered renewal settlement.
- `accrue/priv/repo/migrations/20260503102000_create_accrue_metered_charge_attempts.exs` - settlement ledger table plus `paid_at` on renewals.
- `accrue/test/accrue/billing/metered_charge_attempts_test.exs` - recovery-state and repair replay coverage.
- `accrue/test/accrue/jobs/process_metered_renewal_test.exs` - worker replay and same-charge-unit coverage.
- `accrue/test/accrue/processor/braintree_test.exs` - sale payload and typed failure translation coverage.

## Decisions Made

- Kept the settlement ledger renewal-scoped instead of attempt-scoped so retry and repair replay mutate one canonical row per billing period.
- Derived the Braintree idempotency key from a deterministic renewal-owned subject UUID, preventing worker-attempt churn from producing a second sale.
- Preserved original failure metadata on the attempt row while allowing later successful repair to overwrite only the current attempted payment method and processor charge id.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Shared planning files in `.planning/` already had unrelated local edits before this run. To avoid touching dirty files outside Plan 03 ownership, shared `STATE.md` / `ROADMAP.md` / requirements updates and the metadata-only docs commit were not performed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 04 can build webhook convergence, operator recovery surfaces, or downstream billing explanations on top of stable settlement state and one canonical renewal-owned charge unit.
- Renewal rows now carry paid-state timestamps and the attempt ledger preserves the recovery chain needed for operator tooling.

## Self-Check

PASSED

- Summary file exists at `.planning/phases/103-metering-engine/103-03-SUMMARY.md`.
- Commit `264fa16` exists for the RED test gate.
- Commit `6c668b1` exists for the GREEN implementation gate.
