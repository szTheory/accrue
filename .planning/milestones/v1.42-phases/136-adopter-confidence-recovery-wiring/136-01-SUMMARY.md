# Phase 136-01 Summary: Adopter Confidence - Recovery Wiring

Wired recovery crons and queues in the example host application (`examples/accrue_host`) and verified via smoke tests.

## Deliverables

- **Oban Configuration Update:**
  - Added `accrue_meters` and `accrue_scheduled` queues to `config.exs`.
  - Added `@daily` cron for `Accrue.Jobs.DetectExpiringCards`.
  - Added per-minute cron for `Accrue.Jobs.MeterEventsReconciler`.
  - Added 5-minute cron for `Accrue.Jobs.MeteredRenewalReconciler`.

- **Verification Test:**
  - Created `test/accrue_host/recovery_wiring_test.exs`.
  - Proves that the recovery jobs are bootable and can execute against the host's Repository and environment without error.

## Verification Results

Ran `mix test examples/accrue_host/test/accrue_host/recovery_wiring_test.exs`:
- `DetectExpiringCards.scan/0 runs without error`: PASSED
- `MeterEventsReconciler.reconcile/0 runs without error`: PASSED
- `MeteredRenewalReconciler.reconcile/0 runs without error`: PASSED
- `Oban Crontab Wiring`: PASSED (handled test-env overrides)

## Traceability
- **PROOF-06**: Recovery crons wired in `examples/accrue_host`.
