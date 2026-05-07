# Phase 112 Plan 02 Summary

## Outcome

Promoted `customer.update` to an all-first-party support row and locked the shared `Accrue.Billing.update_customer/2` contract behind deterministic capability, facade, Fake, Stripe, and Braintree proof.

## Changes Made

- Promoted `customer.update` from `staged first-party target` to `all first-party` in the runtime capability labels.
- Updated `.planning/processor-support-matrix.md` so the public capability row and `Accrue.Billing.update_customer/2` mapping now describe the closed shared subset: `name`, `email`, and flat `metadata`.
- Tightened the capability test to pin the promoted `customer.update` row while keeping subscription cancellation staged for Phase 113.
- Strengthened the billing-event proof to reject provider-specific drift (`default_source`) alongside unsupported local attrs before any processor mutation.
- Expanded Fake and Braintree customer-update tests to prove the promoted shared subset directly.
- Added a Stripe proof guard that keeps the billing facade narrow while preserving the specialized `update_customer_tax_location/2` lane.

## Verification

- `cd accrue && mix test test/accrue/processor/capabilities_test.exs`
  - PASS
  - `3 tests, 0 failures`
- `rg -n "customer.update|Accrue.Billing.update_customer/2|all first-party|staged first-party target" accrue/lib/accrue/processor/capabilities.ex .planning/processor-support-matrix.md accrue/test/accrue/processor/capabilities_test.exs`
  - PASS
  - Confirmed `customer.update` is `all first-party` in runtime + matrix, while subscription cancellation rows remain staged.
- `cd accrue && mix test test/accrue/billing/events_transaction_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/braintree_test.exs test/accrue/processor/stripe_test.exs`
  - PASS
  - `73 tests, 0 failures`
- `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/billing/events_transaction_test.exs test/accrue/processor/fake_test.exs test/accrue/processor/braintree_test.exs test/accrue/processor/stripe_test.exs`
  - PASS
  - `76 tests, 0 failures`

## Deviations from Plan

### [Rule 1 - Bug] Translate Braintree metadata into `custom_fields` for the promoted shared subset

- Found during: Task 112-02-02
- Issue: `Accrue.Processor.Braintree.update_customer/3` moved `name` into `company` but dropped shared `metadata`, so the promoted first-party row was not actually true for Braintree.
- Fix: Added `metadata -> custom_fields` translation in the Braintree customer translator and proved the request/response shape in `braintree_test.exs`.
- Files modified: `accrue/lib/accrue/processor/braintree.ex`, `accrue/test/accrue/processor/braintree_test.exs`
- Verification: included in the task proof bundle and final plan verification suite above
- Commit: `29528fa`

## Exact Files Changed

- `.planning/processor-support-matrix.md`
- `.planning/phases/112-customer-update-contract-closure/112-02-SUMMARY.md`
- `accrue/lib/accrue/processor/braintree.ex`
- `accrue/lib/accrue/processor/capabilities.ex`
- `accrue/test/accrue/billing/events_transaction_test.exs`
- `accrue/test/accrue/processor/braintree_test.exs`
- `accrue/test/accrue/processor/capabilities_test.exs`
- `accrue/test/accrue/processor/fake_test.exs`
- `accrue/test/accrue/processor/stripe_test.exs`
