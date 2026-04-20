# INV-02 — Component coverage

**Snapshot:** 2026-04-20 @ dce7334  
**Production method:** `rg -n 'AccrueAdmin\.Components\.' accrue_admin/lib/accrue_admin/live` plus manual read of `alias AccrueAdmin.Components.{...}` blocks in normative LiveViews listed in `25-CONTEXT.md` D-03.

## Kitchen coverage set (`ComponentKitchenLive`)

From `alias AccrueAdmin.Components.{...}` in `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (dev-only route `/dev/components` when `allow_live_reload: true`):

`AppShell`, `Breadcrumbs`, `Button`, `FlashGroup`, `KpiCard`, `StatusBadge`, `Tabs`

## Normative surfaces (D-03)

Primitives on these routes require **either** a kitchen section **or** documented real-route automated tests (LiveView `accrue_admin/test/...` or host `examples/accrue_host/e2e`):

- Money indexes: `CustomersLive`, `SubscriptionsLive`, `InvoicesLive`, `ChargesLive`
- Webhooks: `WebhooksLive`, `WebhookLive`
- Step-up / sensitive actions: destructive flows on `InvoiceLive`, `ChargeLive`, `SubscriptionLive`
- Dashboard: `DashboardLive` (only where downstream UI-SPEC rows apply — see INV-03)

## Production `AccrueAdmin.Components.*` by LiveView (normative focus)

| LiveView | `AccrueAdmin.Components.*` (aliases) |
|----------|----------------------------------------|
| `CustomersLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `FlashGroup`, `KpiCard` |
| `SubscriptionsLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `FlashGroup`, `KpiCard` |
| `InvoicesLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `KpiCard` |
| `ChargesLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `KpiCard` |
| `WebhooksLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `FlashGroup`, `KpiCard` |
| `WebhookLive` | `AppShell`, `Breadcrumbs`, `FlashGroup`, `JsonViewer`, `KpiCard`, `Timeline` |
| `DashboardLive` | `AppShell`, `Breadcrumbs`, `KpiCard`, `Timeline` |
| `InvoiceLive` | `AppShell`, `Breadcrumbs`, `FlashGroup`, `KpiCard`, `MoneyFormatter`, `StatusBadge`, `StepUpAuthModal`, `TaxOwnershipCard`, `Timeline` |
| `ChargeLive` | `AppShell`, `Breadcrumbs`, `FlashGroup`, `JsonViewer`, `KpiCard`, `MoneyFormatter`, `StatusBadge`, `StepUpAuthModal`, `TaxOwnershipCard`, `Timeline` |
| `SubscriptionLive` | `AppShell`, `Breadcrumbs`, `FlashGroup`, `JsonViewer`, `KpiCard`, `StatusBadge`, `StepUpAuthModal`, `TaxOwnershipCard`, `Timeline` |
| `CustomerLive` | `AppShell`, `Breadcrumbs`, `JsonViewer`, `KpiCard`, `MoneyFormatter`, `Tabs`, `TaxOwnershipCard`, `Timeline` |

## Gap list (normative surfaces vs kitchen)

| Component / pattern | Production usage | Kitchen / evidence | Blocking? | Notes |
|---------------------|-------------------|--------------------|-----------|-------|
| `AppShell` | All normative LiveViews above | `ComponentKitchenLive` (`AppShell.app_shell`) | no | Shell parity exercised in dev kitchen. |
| `Breadcrumbs` | All normative LiveViews | `ComponentKitchenLive` | no | |
| `FlashGroup` | `CustomersLive`, `SubscriptionsLive`, `WebhooksLive`, `WebhookLive`, detail lives | `ComponentKitchenLive` | no | `ChargesLive` / `InvoicesLive` omit `FlashGroup` at alias layer (by design); not a D-03 “missing primitive” gap. |
| `KpiCard` | All money indexes, webhooks, dashboard | `ComponentKitchenLive` (`KpiCard` demo grid) | no | |
| `DataTable` | Money indexes + `WebhooksLive` | *Not rendered in* `ComponentKitchenLive` | no | D-03 (b): LiveView tests (`customers_live_test.exs`, `subscriptions_live_test.exs`, `invoices_live_test.exs`, `charges_live_test.exs`, `webhooks_live_test.exs`) plus host e2e customers index (`examples/accrue_host/e2e/verify01-admin-mounted.spec.js`) cover real routes. |
| `JsonViewer` | `WebhookLive` (+ non-normative detail pages) | *Not in kitchen* | no | `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`; e2e webhook detail (`examples/accrue_host/e2e/phase13-canonical-demo.spec.js`). |
| `Timeline` | `DashboardLive`, `WebhookLive`, detail lives | *Not in kitchen* | no | `dashboard_live_test.exs`, `webhook_live_test.exs`, detail LiveView tests. |
| `StepUpAuthModal` | `InvoiceLive`, `ChargeLive`, `SubscriptionLive` | *Not in kitchen* | no | Step-up flows asserted in `invoice_live_test.exs`, `charge_live_test.exs`, `subscription_live_test.exs`. |
| `MoneyFormatter` | Detail lives (money + line items) | *Not in kitchen* | no | Real-route tests on detail modules assert rendered currency strings / totals. |
| `StatusBadge` | Detail lives | `ComponentKitchenLive` | no | |
| `Tabs` | `CustomerLive` | `ComponentKitchenLive` | no | |
| `TaxOwnershipCard` | Detail lives | *Not in kitchen* | no | Non-blocking per D-03 default scope (tax truth promoted via INV-03 / Phase 20 obligations, not Phase 25 exit). No dedicated component-level test module; tracked if INV-03 marks normative. |

## Non-blocking backlog (other production LiveViews)

Per D-03, surfaces outside money indexes / webhooks / step-up / conditional dashboard are **inventory-only** for Phase 25:

| LiveView | `AccrueAdmin.Components.*` | Notes |
|----------|----------------------------|-------|
| `CouponsLive`, `CouponLive` | `AppShell`, `Breadcrumbs`, `DataTable` (+ `JsonViewer` on detail) | Coupons — non-blocking per D-03. |
| `PromotionCodesLive`, `PromotionCodeLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `JsonViewer` on detail | Promotion codes — non-blocking per D-03. |
| `ConnectAccountsLive`, `ConnectAccountLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `FlashGroup` (detail) | Connect — non-blocking per D-03. |
| `EventsLive` | `AppShell`, `Breadcrumbs`, `DataTable`, `KpiCard` | Events index — non-blocking per D-03. |
| `Button` | *(no `AccrueAdmin.Live.*` usage)* | Used only in `ComponentKitchenLive` for dev demos — no production gap. |

## Follow-ups

- Phase **26** may add `DataTable` / `Timeline` / `JsonViewer` slices to `ComponentKitchenLive` for faster visual diffing (optional — D-03 already satisfied by tests today).
- Phase **29** may extend Playwright beyond customers + webhook detail to every money index if VERIFY-01 scope expands.
