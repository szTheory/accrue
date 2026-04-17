# Phase 21 plan 04 — summary

- Extended admin query selects for subscriptions, invoices, and charges to carry tax/ownership fields used by list UIs.
- Money indexes (`customers_live`, `subscriptions_live`, `invoices_live`, `charges_live`) show **Billing signals** via `billing_signals_cell/1` and `BillingPresentation`.
- LiveView tests assert column presence and signal text (e.g. `Off`) where applicable.

Verification: `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/charges_live_test.exs`.
