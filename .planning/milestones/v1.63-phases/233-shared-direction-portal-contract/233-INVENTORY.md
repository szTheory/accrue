# Phase 233 current Admin and Portal inventory

**Evidence captured:** 2026-10-07 (UTC)  
**source SHA:** `1cc8322e7b1528d2a14e2a592b1e89999de7828b`  
**Scope:** source inspection only. Served-render observations are recorded separately in `233-BASELINE.md` after this inventory.

This is a current-source map, not a claim that every route or state was rendered in this task. Route paths are relative to their configurable mount unless stated otherwise. The later-phase column identifies the planned refinement owner, not an assertion that work has already shipped.

## Package and route entry points

| Consumer | Current source | Routes and responsibilities | State/flow owner | Asset owner | Later scope |
|---|---|---|---|---|---|
| Admin | `accrue_admin/lib/accrue_admin/router.ex` | 21 production LiveView routes: home; customers list/detail; subscriptions list/detail; invoices list/detail; payments list/detail; coupons list/detail; promotion codes list/detail; Connect list/detail; events list/detail; webhooks list/detail; recovery list/campaign detail. Legacy `/charges` routes redirect to payments. Dev-only routes are separate. | `AccrueAdmin.Live.*` route modules own query and interaction state; shared components/hooks own embedded search, filters, drawers, confirmations, selection, and theme behavior. | `accrue_admin/assets/css/theme.css`, `app.css`, JS and fonts, served via `AccrueAdmin.Assets`; package-scoped `--ax-*` tokens. | 234 customers/subscriptions; 237 invoices/payments/recovery; 238 events/webhooks/coupons/promotion codes/Connect. |
| Portal | `accrue_portal/lib/accrue_portal/router.ex` | Seven customer LiveViews: `/`, `/subscriptions`, `/subscriptions/:id`, `/payment-methods`, `/payment-methods/new`, `/invoices`, `/checkout/:token`. | Corresponding `AccruePortal.Live.*` modules own loaded/empty/denied and interactive pending/failed/result state; `AuthHook` supplies the authenticated customer context. | Portal-owned `accrue_portal/priv/static/accrue_portal.css` and `accrue_portal.js`, with public core `accrue/priv/static/brand.css` token/brand bridge, served from `AccruePortal.Assets`. Portal is buildless; the canonical host compiles embedded asset bodies. | 235 checkout and payment hooks/handoffs; 236 Portal self-service routes; 239 integrated coverage/handoff. |
| Portal POST boundary | `accrue_portal/lib/accrue_portal/router.ex` | Four protected POSTs: `POST /payment-methods` (create), `POST /payment-methods/:id/default`, `POST /payment-methods/:id/delete`, and `POST /checkout/:token/complete`. | `PaymentMethodController` owns create/default/delete outcomes; `CheckoutController` owns completion and redirect/flash result. | Same Portal/core assets as the associated forms. | 235 checkout POST and handoff; 236 payment method actions; 239 cross-transport coverage. |
| Canonical example host | `examples/accrue_host/lib/accrue_host_web/router.ex` | `/pricing`; authenticated `/app/billing`; `/app/organization-scope` POST; `/app/entitlements/diagnostics`; user login/register/settings routes used for continuity. Portal is mounted at `/billing` in the host router. | Host-owned auth, active organization selection, membership policy, plan selection, and return/navigation state. | Host layouts and theme plus package-served Admin/Portal assets; Portal's host brand bridge is presentation data. | 235 pricing/checkout continuity; 233-01/02/03/07 and 233-05 contract/application slices; 239 integrated handoff. |

## Current Portal route and flow matrix

| Route/flow | Component or endpoint | Current owned states and evidence seam | Asset owner | Later scope |
|---|---|---|---|---|
| `/billing` overview | `AccruePortal.Live.HomeLive` | Customer-scoped subscription/payment/invoice summary; render-level empty/unavailable handling belongs to the LiveView/read model. | Portal CSS/JS + core brand tokens | 236 |
| `/billing/subscriptions` list/cancel | `SubscriptionsLive`; cancel event | Loaded list, no subscriptions, eligibility and cancellation pending/result feedback are LiveView-owned. | Portal CSS | 236 |
| `/billing/subscriptions/:id` inspect/change/cancel | `SubscriptionLive` | Target lookup/denial, details, plan preview/change confirmation, cancellation confirmation and result events. | Portal CSS | 236 |
| `/billing/payment-methods` list/default/delete | `PaymentMethodsLive`; POST `/:id/default` and `/:id/delete` | Loaded/empty list; protected/in-use/default behavior and POST flash/redirect results. Controller reloads target within the assigned Customer. | Portal CSS | 236 |
| `/billing/payment-methods/new` card acquisition | `AddPaymentMethodLive`; POST `/payment-methods`; `Hooks.BraintreeHostedFields` | Client-token/form readiness, secure-field/tokenization failure, pending submit and POST success/failure. | Portal CSS/JS; official Braintree Hosted Fields owns card entry/tokenization | 236, with secure hook integration in 235 |
| `/billing/invoices` recent invoices | `InvoicesLive` | Loaded recent records, empty list, missing hosted document/link, and denied context. The read model currently limits the view to 20. | Portal CSS | 236 |
| `/billing/checkout/:token` checkout | `CheckoutLive`; tokenized event; POST `/checkout/:token/complete` | Token/session missing, expired/completed, loaded checkout, promo preview/error, payment pending/failure/result, and target Customer comparison. Both event and POST completion paths are separate seams. | Portal CSS/JS; official Braintree Hosted Fields | 235, 236, 239 |

## Current Admin route families

The production route definitions are in `accrue_admin/lib/accrue_admin/router.ex`. The complete mount-relative family map is:

| Route family | Current component(s) | Primary flow and state owner | Asset owner | Later scope |
|---|---|---|---|---|
| `/` | `DashboardLive` | Operator overview, search and task entry; LiveView owns result/empty/error state. | Admin assets and `--ax-*` | 234, 237 |
| `/customers`, `/customers/:id` | `CustomersLive`, `CustomerLive` | Find customer and inspect related billing records/tabs. | Admin assets | 234 |
| `/subscriptions`, `/subscriptions/:id` | `SubscriptionsLive`, `SubscriptionLive` | Lifecycle investigation and supported subscription actions/confirmations. | Admin assets | 234 |
| `/invoices`, `/invoices/:id` | `InvoicesLive`, `InvoiceLive` | Invoice amounts, collection state and supported actions. | Admin assets | 237 |
| `/payments`, `/payments/:id` | `ChargesLive`, `ChargeLive` | Payment/charge evidence, fees and supported refunds. | Admin assets | 237 |
| `/analytics/recovery`, `/analytics/recovery/subscriptions/:id` | `RecoveryLive`, `CampaignLive` | Recovery window, campaign history and return context. | Admin assets | 237 |
| `/events`, `/events/:id` | `EventsLive`, `EventLive` | Local billing/audit event investigation and linked records. | Admin assets | 238 |
| `/webhooks`, `/webhooks/:id` | `WebhooksLive`, `WebhookLive` | Delivery investigation and eligible retry/replay result. | Admin assets | 238 |
| `/coupons`, `/coupons/:id` | `CouponsLive`, `CouponLive` | Inspect coupon terms and redemptions; no create/edit route implied. | Admin assets | 238 |
| `/promotion-codes`, `/promotion-codes/:id` | `PromotionCodesLive`, `PromotionCodeLive` | Inspect code restrictions, use and coupon relationship. | Admin assets | 238 |
| `/connect`, `/connect/:id` | `ConnectAccountsLive`, `ConnectAccountLive` | Provider account readiness and local fee override. | Admin assets | 238 |

Embedded Admin flows are owned by the route LiveViews plus their components/hooks: search, filter/sort/pagination, selection, action drawers, confirmation/step-up, payment-method details, entitlements, refund history, PDFs, timelines/payloads, notices, reconnect, and theme selection. Dev-only `/dev/*` routes and `/charges` compatibility redirects are not additional production UI surfaces.

## Host billing entry, handoff, and return seams

| Seam | Source | Current responsibility | Later scope |
|---|---|---|---|
| Offer selection | `/pricing`, `AccrueHostWeb.PageController` and plan components | Select an existing host plan and carry chosen-plan continuity toward auth/checkout. | 235 |
| Host billing overview | `/app/billing`, `AccrueHostWeb.SubscriptionLive` | Show host's current billing entity, plan lifecycle and available existing actions. | 235 |
| Organization context | `/app/organization-scope`, `OrganizationScopeController`, `AccrueHost.Accounts.Scope` | Host-owned account selection/membership; generic unavailable response for stale or unauthorized selection. | Phase 233 contract and 235/236 consumers |
| Portal mount | `Accrue.Portal.Router.accrue_portal` from host router | Mount Portal beneath `/billing`; host owns authentication and explicit session keys. | 233-01/05 |
| Provider handoff and return | Host billing/Portal checkout and provider facade paths | Stripe-hosted versus Braintree-mounted boundaries; return destination is navigation only and must not establish payment authorization/result. | 235, 239 |
| Login/registration continuity | User session LiveViews/controllers | Preserve requested plan/billing destination across sign-in and return. | 235 |

## Provenance and historical evidence boundary

The source inventory was taken from the repository at SHA `1cc8322e7b1528d2a14e2a592b1e89999de7828b` on 2026-10-07. Source paths and ownership above are source-based facts. Current served behavior, rendered appearance, asset response hashes, themes and viewport observations are deliberately deferred to `233-BASELINE.md` and its fresh captures.

Saved July screenshots and earlier browser pass counts are **historical** only. They describe older source trees and are not proof of today's served Admin or Portal output. No current-render claim is made by this inventory.
