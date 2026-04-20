# Admin UI / UX — baseline audit (read-only)

**Date:** 2026-04-20  
**Scope:** `accrue_admin` LiveViews + components + CSS; **host** `examples/accrue_host` only where it affects mounted admin or existing VERIFY-01 / trust Playwright.  
**References:** `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md`, `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md`

---

## 1. Route matrix (`AccrueAdmin.Router`)

Shipping `live_session` routes (relative to host mount path):

| Path | LiveView |
|------|----------|
| `/` | `AccrueAdmin.Live.DashboardLive` |
| `/customers` | `AccrueAdmin.Live.CustomersLive` |
| `/customers/:id` | `AccrueAdmin.Live.CustomerLive` |
| `/subscriptions` | `AccrueAdmin.Live.SubscriptionsLive` |
| `/subscriptions/:id` | `AccrueAdmin.Live.SubscriptionLive` |
| `/invoices` | `AccrueAdmin.Live.InvoicesLive` |
| `/invoices/:id` | `AccrueAdmin.Live.InvoiceLive` |
| `/charges` | `AccrueAdmin.Live.ChargesLive` |
| `/charges/:id` | `AccrueAdmin.Live.ChargeLive` |
| `/coupons` | `AccrueAdmin.Live.CouponsLive` |
| `/coupons/:id` | `AccrueAdmin.Live.CouponLive` |
| `/promotion-codes` | `AccrueAdmin.Live.PromotionCodesLive` |
| `/promotion-codes/:id` | `AccrueAdmin.Live.PromotionCodeLive` |
| `/connect` | `AccrueAdmin.Live.ConnectAccountsLive` |
| `/connect/:id` | `AccrueAdmin.Live.ConnectAccountLive` |
| `/events` | `AccrueAdmin.Live.EventsLive` |
| `/webhooks` | `AccrueAdmin.Live.WebhooksLive` |
| `/webhooks/:id` | `AccrueAdmin.Live.WebhookLive` |

Dev-only (when `allow_live_reload: true`): `/dev/clock`, `/dev/email-preview`, `/dev/webhook-fixtures`, `/dev/components` (**Component kitchen**), `/dev/fake-inspect`.

---

## 2. `ax-*` usage in LiveViews (grep snapshot)

All **16** production LiveViews under `accrue_admin/lib/accrue_admin/live/` reference `class="ax-` (count per file ranges ~6–55). **EventsLive** shows the smallest footprint (~6); **webhook** and **invoice** detail pages show the largest. This indicates broad adoption of the packaged class system, not ad hoc HTML-only pages.

**Implication (INV-02):** `ComponentKitchenLive` previews only **AppShell, Breadcrumbs, Button, FlashGroup, KpiCard, StatusBadge, Tabs** — a **subset** of production primitives (`DataTable`, `TaxOwnershipCard`, `StepUpAuthModal`, `JsonViewer`, `Timeline`, etc. are **not** in the kitchen).

---

## 3. Alignment with Phase 20 / 21 UI-SPEC

| Spec theme | Baseline observation |
|------------|----------------------|
| **No new UI kits** | Still LiveView + `ax-*` + `theme.css` / `app.css`; no `components.json` path. |
| **Spacing / type roles** | `DashboardLive` uses `ax-page`, `ax-page-header`, `ax-eyebrow`, `ax-display`, `ax-body`, `ax-kpi-grid` with `aria-label` on KPI section — matches documented hierarchy intent. |
| **Money indexes + signals** | Phase **21** list-signal and **Tax & ownership** rules apply to **customers/subscriptions/invoices/charges** per spec; other indexes (coupons, promotion codes, connect, events) use shared `DataTable` but were **not** the focus of Phase 21 locked copy. |
| **Locked microcopy** | Org/tax/replay strings are spec-locked in 20/21; **`DataTable` defaults** (`empty_title` / `empty_copy`: “No rows found” / “Adjust the filters…”) are **generic** and may not match Phase 20 “plain language / no jargon” bar on every surface (COPY gap). |
| **Tenant chrome** | `Active organization` / `?org=` preservation — validated in Phase 20–21; out of scope for pure component polish unless regressions found. |

---

## 4. Playwright and `@mobile` (host)

| Artifact | Role |
|----------|------|
| `examples/accrue_host/playwright.config.js` | Projects: `chromium-desktop`, `chromium-mobile` (Pixel 5), `chromium-mobile-tagged` (`grep: /@mobile/`). |
| `e2e/phase13-canonical-demo.spec.js` | Release-blocking **@phase15-trust** flow; uses **role** locators, `assertResponsiveState`, `expectNoHorizontalOverflow`; switches admin nav between **Menu** button (mobile project) and **Webhooks** link (desktop). **Does not** import `@axe-core/playwright` (no `axe` in repo e2e tree as of this audit). |
| `e2e/mobile-tag-holder.spec.js` | **@mobile** placeholder only — stable target for `chromium-mobile-tagged`. |

**Gap (MOB-03 / A11Y-04):** Admin-heavy flows beyond the trust walkthrough are **not** systematically covered on mobile; **automated axe** is **not** wired in e2e despite Phase 21 CONTEXT citing an “a11y axe pattern” (implementation is **responsive + visibility** checks today).

**Config quirk:** `chromium-mobile-tagged` uses **Desktop Chrome** viewport in config while filtering `@mobile` tests — maintainers should treat **true** mobile geometry as **`chromium-mobile`** project, not the tagged project name alone.

---

## 5. Recommended first execution focus (Phase 25+)

1. **Close INV-03** with a short table: each **money index** + **webhook** list vs 21-UI-SPEC rows (signals, chips, card).
2. **DataTable** empty copy audit (COPY-01): differentiate generic “No rows found” vs domain-specific empty states where it improves operator clarity.
3. **Pick one** mounted-admin Playwright path for **MOB-01** and prototype **A11Y-04** (axe or strict role/label contract).

---

*This document is planning-only; it does not change product behavior.*
