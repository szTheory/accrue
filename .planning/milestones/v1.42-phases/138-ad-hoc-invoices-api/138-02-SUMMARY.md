# 138-02 Summary: Billing Ad-hoc Invoice Item API

Implemented the public billing API for manual draft-invoice adjustments.

## Delivered

- Added `Accrue.Billing.add_invoice_item/3`, `add_invoice_item!/3`, `remove_invoice_item/3`, and `remove_invoice_item!/3`.
- Added draft-only invoice item workflows in `InvoiceActions`.
- Reprojected the canonical processor invoice after each item mutation and synchronized local `InvoiceItem` rows, including stale-row removal.
- Recorded `invoice.item_added` and `invoice.item_removed` ledger events.
- Added targeted tests for success paths, ledger events, totals updates, and non-draft rejection.

## Verification

- `mix test test/accrue/billing/invoice_item_actions_test.exs test/accrue/billing/invoice_workflow_test.exs test/accrue/billing/invoice_items_test.exs`

## Traceability

- BIL-08
