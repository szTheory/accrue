# Phase 112 Plan 01 Summary

## Outcome

Promoted `Accrue.Billing.update_customer/2` from a local row edit to the bounded first-party remote write-through contract for `name`, `email`, and flat `metadata`, while preserving an explicit `update_customer_local/2` path for host-owned local maintenance.

## Changes Made

- Replaced the old local-only `update_customer/2` implementation with processor-first dispatch, shared attr validation, sanitized projection sync, and bounded `customer.updated` event payloads.
- Added `update_customer_local/2` for explicit local-only customer-row maintenance and a distinct `customer.local_updated` event.
- Added projection-sync failure handling for remote-success/local-write-failure, including typed error return and `[:accrue, :ops, :customer_projection_sync_failed]` telemetry with correlation metadata.
- Expanded `events_transaction_test.exs` to prove:
  - processor-backed update semantics
  - unsupported attr rejection before remote drift
  - sanitized local projection from processor responses
  - explicit local-only maintenance behavior
  - typed projection-sync failure plus telemetry evidence

## Verification

- `cd accrue && mix test test/accrue/billing/events_transaction_test.exs`
  - PASS
  - `12 tests, 0 failures`

## Deviations from Plan

### [Rule 1 - Bug] Converted stale local projection writes into typed errors

- Found during: Task 112-01-02 verification
- Issue: optimistic-lock conflicts raised `Ecto.StaleEntryError`, which bypassed the required typed projection-sync failure contract.
- Fix: used `stale_error_field: :lock_version` on the local projection update so stale writes surface as an error tuple, then wrapped that branch in the new typed projection-sync failure response and telemetry.
- Files modified: `accrue/lib/accrue/billing.ex`

None otherwise.
