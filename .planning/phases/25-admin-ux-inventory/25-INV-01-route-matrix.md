# INV-01 — Route matrix

**Snapshot:** 2026-04-20 @ 98fb8f3  
**Production method:** `cd examples/accrue_host && mix phx.routes` — filter rows whose path starts with `/billing` (admin mount). Re-run after dependency bumps that change `AccrueAdmin.Assets` hashes.  
**Scope statement:** **Include** all `live/4` routes registered inside `live_session :accrue_admin` in `accrue_admin/lib/accrue_admin/router.ex` **outside** the `if dev_routes?` block (shipping product surface), with **host-absolute** paths under mount `/billing`. **Include** non-LiveView `GET /billing/assets/*` rows (`AccrueAdmin.Assets`, actions `:brand`, `:css`, `:js`) in **Non-LiveView (Plug → Assets)**. **Exclude** Phoenix LiveView transport endpoints (`WS /live/websocket`, `GET|POST /live/longpoll`) from this matrix — they are framework plumbing, not admin pages (they do not appear under `/billing` in normal host output).

## Shipping `live_session` routes

Host-absolute paths assume the reference mount in `examples/accrue_host` (`accrue_admin "/billing", …`).

| Admin-relative path | Host-absolute path | LiveView module | Notes |
|---------------------|--------------------|------------------|-------|
| `/` | `/billing` | `AccrueAdmin.Live.DashboardLive` | `:index` |
| `/customers` | `/billing/customers` | `AccrueAdmin.Live.CustomersLive` | `:index` |
| `/customers/:id` | `/billing/customers/:id` | `AccrueAdmin.Live.CustomerLive` | `:show` |
| `/subscriptions` | `/billing/subscriptions` | `AccrueAdmin.Live.SubscriptionsLive` | `:index` |
| `/subscriptions/:id` | `/billing/subscriptions/:id` | `AccrueAdmin.Live.SubscriptionLive` | `:show` |
| `/invoices` | `/billing/invoices` | `AccrueAdmin.Live.InvoicesLive` | `:index` |
| `/invoices/:id` | `/billing/invoices/:id` | `AccrueAdmin.Live.InvoiceLive` | `:show` |
| `/charges` | `/billing/charges` | `AccrueAdmin.Live.ChargesLive` | `:index` |
| `/charges/:id` | `/billing/charges/:id` | `AccrueAdmin.Live.ChargeLive` | `:show` |
| `/coupons` | `/billing/coupons` | `AccrueAdmin.Live.CouponsLive` | `:index` |
| `/coupons/:id` | `/billing/coupons/:id` | `AccrueAdmin.Live.CouponLive` | `:show` |
| `/promotion-codes` | `/billing/promotion-codes` | `AccrueAdmin.Live.PromotionCodesLive` | `:index` |
| `/promotion-codes/:id` | `/billing/promotion-codes/:id` | `AccrueAdmin.Live.PromotionCodeLive` | `:show` |
| `/connect` | `/billing/connect` | `AccrueAdmin.Live.ConnectAccountsLive` | `:index` |
| `/connect/:id` | `/billing/connect/:id` | `AccrueAdmin.Live.ConnectAccountLive` | `:show` |
| `/events` | `/billing/events` | `AccrueAdmin.Live.EventsLive` | `:index` |
| `/webhooks` | `/billing/webhooks` | `AccrueAdmin.Live.WebhooksLive` | `:index` |
| `/webhooks/:id` | `/billing/webhooks/:id` | `AccrueAdmin.Live.WebhookLive` | `:show` |

## Non-LiveView (Plug → Assets)

Hashed paths below match `mix phx.routes` at snapshot SHA; hashes change when asset bytes change.

| Host-absolute path (example) | Module | Action | Notes |
|------------------------------|--------|--------|-------|
| `GET /billing/assets/brand-f9ea58f4f6eaf459e5612cd64bbe564f` | `AccrueAdmin.Assets` | `:brand` | Brand asset |
| `GET /billing/assets/css-ca3f5a157351c821572b68393cbd6fe8` | `AccrueAdmin.Assets` | `:css` | Bundled admin CSS |
| `GET /billing/assets/js-7024235a0e3fc9a7d2a6809780214f24` | `AccrueAdmin.Assets` | `:js` | Bundled admin JS |

## Dev-only routes (`allow_live_reload: true`)

These `live/4` routes are emitted **only** when the host passes `allow_live_reload: true` into `accrue_admin/2` (see `accrue_admin/lib/accrue_admin/router.ex` `if dev_routes?` block). The reference host uses `allow_live_reload: false`, so **they do not appear** in `mix phx.routes` for `examples/accrue_host`; source is authoritative for this subsection.

| Admin-relative path | Host-absolute (if mount `/billing`) | LiveView module | Notes |
|---------------------|-------------------------------------|-----------------|-------|
| `/dev/clock` | `/billing/dev/clock` | `AccrueAdmin.Dev.ClockLive` | `:index` |
| `/dev/email-preview` | `/billing/dev/email-preview` | `AccrueAdmin.Dev.EmailPreviewLive` | `:index` |
| `/dev/webhook-fixtures` | `/billing/dev/webhook-fixtures` | `AccrueAdmin.Dev.WebhookFixtureLive` | `:index` |
| `/dev/components` | `/billing/dev/components` | `AccrueAdmin.Dev.ComponentKitchenLive` | `:index` |
| `/dev/fake-inspect` | `/billing/dev/fake-inspect` | `AccrueAdmin.Dev.FakeInspectLive` | `:index` |

## Host mount reference

| Property | Value |
|----------|-------|
| Example host mount | `/billing` (`examples/accrue_host/lib/accrue_host_web/router.ex`, `accrue_admin "/billing", …` ca. line 90) |
| `allow_live_reload` in reference config | `false` — dev-only admin routes above are **not** registered in the reference app. |

## `mix phx.routes` cross-check

At snapshot time, every shipping host-absolute `/billing/...` LiveView path in the table above appears in `cd examples/accrue_host && mix phx.routes` output (plus the three `AccrueAdmin.Assets` rows). Non-admin path `/app/billing` (`AccrueHostWeb.SubscriptionLive`) is **out of scope** for INV-01.
