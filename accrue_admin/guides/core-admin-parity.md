# Core admin operator surface parity (ADM-07)

This guide is the **authoritative ADM-07** inventory for **core** `accrue_admin` LiveView routes mounted via `AccrueAdmin.Router.accrue_admin/2`. Each row ties a **mounted surface** to **`AccrueAdmin.Copy`** posture, **`ax-*` / theme token** discipline, and **VERIFY-01** expectations. Planning decisions **D-01–D-05** and **D-16–D-18** live in **Phase 54** `54-CONTEXT.md`—maintain **one** matrix here; do not fork a competing table under `.planning/`.

**Copy posture (Tier A reminder):** Operator-visible strings on mounted routes belong in `AccrueAdmin.Copy` (or `Copy.Locked` where legally sensitive). **`clean`** means the primary `~H"""` shell for that action is audited and literals are routed through Copy for the scope of this row. **`gaps`** means raw English remains in headings, KPI labels, breadcrumbs, filters, or primary buttons. **`needs audit`** is an explicit **P2** posture when only a partial pass was recorded—prefer **`needs audit`** over guessing **`clean`**.

**`ax-*` / token posture:** **`clean`** when layout and cards use `ax-*` utilities consistently on audited chrome; **`gaps`** when mixed Tailwind-only layout or inline literals suggest drift; register honest exceptions in [`theme-exceptions.md`](theme-exceptions.md).

**VERIFY-01 lane:** Per **D-03**, use **`planned — Phase 55 (ADM-09)`** when merge-blocking Playwright + axe flows are not yet assigned for that surface. **`merge-blocking`** applies only where the existing VERIFY-01 spine already enforces the row today.

## Core surface matrix

Routes are **relative to the admin mount**. LiveView modules and actions match `accrue_admin/lib/accrue_admin/router.ex` inside the `live_session :accrue_admin` block.

| Route (relative to mount) | LiveView module + action | `AccrueAdmin.Copy` posture | `ax-*` / token posture | Named VERIFY flow id | VERIFY-01 lane | Severity |
| --- | --- | --- | --- | --- | --- | --- |
| `/` | `AccrueAdmin.Live.DashboardLive` `:index` | **clean** — breadcrumbs, KPIs, timelines, and page chrome use `Copy.*` | **clean** — `ax-page`, `ax-kpi-grid`, `ax-*` typography | — | planned — Phase 55 (ADM-09) | P2 |
| `/customers` | `AccrueAdmin.Live.CustomersLive` `:index` | **gaps** — page header, KPI labels, breadcrumbs, and `DataTable` column/filter labels are raw English; empty/table chrome uses `Copy` | **clean** on audited shell (`ax-page`, `ax-kpi-grid`) | — | planned — Phase 55 (ADM-09) | P1 |
| `/customers/:id` | `AccrueAdmin.Live.CustomerLive` `:show` | **gaps** — shell headings, KPI labels, tab titles, and several empty states remain raw English; flashes and selected empty rows use `Copy` / `Copy.Locked` | **clean** on `ax-*` cards and lists | — | planned — Phase 55 (ADM-09) | P1 |
| `/subscriptions` | `AccrueAdmin.Live.SubscriptionsLive` `:index` | **gaps** — index header, KPIs, breadcrumbs, and table chrome are raw English; empty state uses `Copy` | **clean** on shell | — | planned — Phase 55 (ADM-09) | P1 |
| `/subscriptions/:id` | `AccrueAdmin.Live.SubscriptionLive` `:show` | **clean** — drill-down chrome, breadcrumbs, KPIs, and actions route through `Copy.*` | **clean** — `ax-*` shell | — | planned — Phase 55 (ADM-09) | P2 |
| `/invoices` | `AccrueAdmin.Live.InvoicesLive` `:index` | **clean — ADM-08** — list chrome, KPI labels, breadcrumbs, filters, and column labels route through `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Invoice` (empty states remain `Copy.invoices_index_empty_*`) | **clean** on `ax-*` shell | `core-admin-invoices-index` | merge-blocking | P2 |
| `/invoices/:id` | `AccrueAdmin.Live.InvoiceLive` `:show` | **clean — ADM-08** — invoice shell, KPIs, workflow controls, tax-risk panel, PDF block, line items, timeline labels, and source-event chrome route through `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Invoice`; flashes and processor warnings remain on `Copy` facade | **clean** on `ax-*` shell | `core-admin-invoices-detail` | merge-blocking | P2 |
| `/charges` | `AccrueAdmin.Live.ChargesLive` `:index` | **gaps** — index header, KPIs, breadcrumbs, and table chrome are raw English; empty state uses `Copy` | **clean** on shell | — | planned — Phase 55 (ADM-09) | P1 |
| `/charges/:id` | `AccrueAdmin.Live.ChargeLive` `:show` | **gaps** — detail shell, fee breakdown labels, refund form copy, and breadcrumbs are raw English; flashes use `Copy` | **clean** on `ax-*` cards | — | planned — Phase 55 (ADM-09) | P1 |
| `/webhooks` | `AccrueAdmin.Live.WebhooksLive` `:index` | **gaps** — header, KPIs, DLQ bulk-replay controls, and table chrome are raw English; empty/table caption paths use `Copy`; bulk replay confirmations use `Copy` helpers | **clean** on shell | — | planned — Phase 55 (ADM-09) | P1 |
| `/webhooks/:id` | `AccrueAdmin.Live.WebhookLive` `:show` | **gaps** — inspector headings, KPI labels, replay buttons, and timeline chrome are raw English; replay guardrails use `Copy` / `Copy.Locked` | **clean** on `ax-*` shell | — | planned — Phase 55 (ADM-09) | P1 |

## Excluded (v1.13 auxiliary)

Per **D-18**, the following **`live/3` routes are intentionally out of the core 11-row matrix**: `/coupons`, `/coupons/:id`, `/promotion-codes`, `/promotion-codes/:id`, `/connect`, `/connect/:id`, `/events`. They ship as auxiliary operator tools and are tracked separately from ADM-07 core parity.

**Static assets** under `get("/assets/…")` are not LiveView rows. **`/dev/*` routes** (behind `:allow_live_reload`) are compile-gated developer utilities—not part of supported OSS operator UX; omit from this matrix.

## VERIFY-01 lane column

The **VERIFY-01 lane** column records how the **existing** host VERIFY spine relates to each row today. **`merge-blocking`** is used only where `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` already enforces the row (see **Phase 55** `55-CONTEXT.md` **D-03**/**D-04** for invoice anchors). Other core rows may remain **`planned — Phase 55 (ADM-09)`** until named flows land—this preserves an honest inventory without silently expanding VERIFY policy (**D-20**, **D-14**).

## Maintenance notes

When router `live/3` entries change, update this matrix in the same change-set. Optional hygiene (**D-19**): diff router entries vs `lib/accrue_admin/live/**/*.ex` for orphan modules—non-normative.

## References

- `accrue_admin/lib/accrue_admin/router.ex` — authoritative route list (**D-16**).
- [`admin_ui.md`](admin_ui.md) — host mount and UI stack overview.
- [`theme-exceptions.md`](theme-exceptions.md) — intentional token deviations.
