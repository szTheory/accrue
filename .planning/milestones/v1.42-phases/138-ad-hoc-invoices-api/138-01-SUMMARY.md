# 138-01 Summary: Processor Invoice Item Operations

Extended the processor layer to support ad-hoc invoice item creation and deletion.

## Delivered

- Added `invoice_item_create/2` and `invoice_item_delete/3` to `Accrue.Processor`.
- Implemented Stripe invoice item delegation through `LatticeStripe.InvoiceItem`.
- Added explicit unsupported responses in the Braintree adapter.
- Extended the Fake processor state and handlers so invoice items mutate stored invoice lines and totals coherently.

## Verification

- `mix compile`
- `mix test test/accrue/billing/invoice_item_actions_test.exs`

## Traceability

- BIL-08
