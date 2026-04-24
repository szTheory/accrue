---
phase: 76-customer-pm-tab-inventory-copy-burn-down
inventory_status: established
verified: ""
---

# Phase 76 — Customer payment methods tab verification

This file is the **ADM-13** merge-facing inventory for operator-visible strings and coverage on the customer detail **`payment_methods`** tab (`AccrueAdmin.Live.CustomerLive`). **ADM-14** (routing those strings through `AccrueAdmin.Copy` for this tab only) is in scope for the same phase; **ADM-15** / **ADM-16** (cross-tab KPI, charges, subscriptions copy, axe/VERIFY extensions) stay **out of scope** here and are deferred per **76-CONTEXT.md**.

## Inventory — operator strings

| Location | Literal / helper | Copy-backed? | Notes |
| --- | --- | --- | --- |
| `customer_live.ex` — `payment_methods` branch, card `<h3>` | `Copy.customer_payment_methods_section_heading/0` | yes | Section title for listed payment methods |
| `customer_live.ex` — `payment_methods` branch, row label fallback | `Copy.customer_payment_methods_row_fallback_label/0` | yes | Shown when `card_brand` and `type` are both absent on a row |
| `customer_live.ex` — `payment_methods` branch, last4 mask | `Copy.customer_payment_methods_card_last4_mask/0` | yes | Visual separator before `card_last4` |
| `customer_live.ex` — `payment_methods` branch, empty state `<p>` | `Copy.customer_payment_methods_empty_copy/0` | yes | When the customer has zero `PaymentMethod` rows |

## ax-* and layout tokens

On the **`payment_methods`** tab, the audited chrome uses:

- `ax-card` — card wrapper for the tab panel
- `ax-heading` — section title
- `ax-list-row` — each payment method row
- `ax-body` — row body text and empty-state paragraph

## Tests — ExUnit and Playwright

- **ExUnit:** `accrue_admin/test/accrue_admin/live/customer_live_test.exs` exercises default tab, events, metadata, invoices, and out-of-scope / loader cases; it does **not** mount **`?tab=payment_methods`** today.
- **Playwright:** `accrue_admin/e2e/phase7-uat.spec.js` has no dedicated **`payment_methods`** tab flow. **Phase 77** owns extending VERIFY / axe coverage for deferred cross-tab items.

## Cross-tab stragglers (deferred — D-09)

- **Subscriptions KPI delta** on the customer shell: substring **`" payment methods"`** inside `Integer.to_string(@tab_counts.payment_methods) <> " payment methods"` — **Deferred to Phase 77 (ADM-15/16) — no code change in Phase 76.**
- **Charges tab empty state** on the same LiveView: **`"No charges projected yet."`** — **Deferred to Phase 77 (ADM-15/16) — no code change in Phase 76.**
