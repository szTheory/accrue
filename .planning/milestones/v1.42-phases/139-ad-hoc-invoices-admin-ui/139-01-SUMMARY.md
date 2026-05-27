# 139-01 Summary: Ad-hoc Invoices - Admin UI

Implemented the Admin UI for managing ad-hoc line items on draft invoices.

## Delivered

- Added UI components to `invoice_live.ex` for adding and removing manual line items.
- Added all required copywriting from `139-UI-SPEC.md` to `AccrueAdmin.Copy` and `AccrueAdmin.Copy.Invoice`.
- Wired up state management for the ad-hoc line item form and pending deletion confirmation.
- Gated the manual adjustment form strictly behind the `invoice.status == :draft` constraint.
- Connected the `add_manual_item` and `confirm_remove_item` LiveView events to the `Accrue.Billing` API.
- Added corresponding unit tests in `invoice_live_test.exs` and verified success.