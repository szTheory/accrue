---
phase: 49
slug: drill-flows-navigation
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-22
---

# Phase 49 — UI Design Contract

> Visual and interaction contract for **ADM-02** / **ADM-03** in the **customer → subscription → invoice** drill: **`SubscriptionLive`** gains **InvoiceLive-parity** breadcrumb context and a **bounded “Related billing”** region — without **primary nav** structural changes (**049-CONTEXT.md D-08**).

---

## Phase scope (routes & components)

| Item | Contract |
|------|-----------|
| Primary surface | **`AccrueAdmin.Live.SubscriptionLive`** (`live "/subscriptions/:id"`) — **breadcrumb trail** + **one** new **`ax-card`** block for related navigation. |
| Reference surface | **`AccrueAdmin.Live.InvoiceLive`** — **canonical** breadcrumb shape (**Dashboard → index → Customer → current record**). |
| Shell | Reuse **`AppShell`** — no layout fork. |
| Nav / sidebar | **`AccrueAdmin.Nav`** — **no** add/remove/reorder of top-level items (**D-08**). |
| New UI | **Exactly one** new **`article.ax-card`** (or nested section with **`ax-card`** chrome) titled via **`AccrueAdmin.Copy`** — **≤5** links total. |
| Breadcrumbs | **Four** segments before current page: **Dashboard** (linked) → **Subscriptions** (linked) → **Customer** (linked, label matches invoice-detail honesty: name → email → id) → **Subscription** (current, **no** `href` on terminal crumb). All list/detail `href` values use **`ScopedPath.build(@admin_mount_path, suffix, @current_owner_scope)`** (same org-preservation semantics as **`InvoiceLive`**). |
| Related billing links | **Minimum:** **Customer** (detail). **Invoices:** use **`ScopedPath.build(..., "/invoices", scope, %{"customer_id" => customer.id})`** only if **`Invoices.decode_filter/1`** documents **`customer_id`** (it does) — this is an **honest** row filter. **Charges:** same pattern with **`?customer_id=`** via **`Charges.decode_filter/1`**. **Do not** ship **`subscription_id=`** deep links on invoices/charges — **not** implemented in query modules (would violate **D-07**). **Events:** **index only** **`/events`** (no query implying subscription-scoped ledger unless a future phase adds **`subject_id`** filter to **`Events.decode_filter`**). |
| Copy | Any **new** operator-visible strings for this phase → **`AccrueAdmin.Copy`** with prefix **`subscription_drill_*`** (exact prefix locked in **`049-01-PLAN.md`** tasks). |

---

## Design System

| Property | Value |
|----------|-------|
| Tool | **none** |
| Component library | Existing **`AccrueAdmin.Components.*`** + **`Breadcrumbs`**, **`ax-*`** tokens only |

---

## Spacing & typography

Follow existing **`ax-page-header`**, **`ax-card`**, **`ax-eyebrow`**, **`ax-heading`**, **`ax-body`** usage in **`SubscriptionLive`** — **no** new font-size or spacing tokens for this phase.

---

## Color

Semantic **`--ax-*`** variables only — same bar as Phase **48**.

---

## Interaction & motion

| Topic | Rule |
|-------|------|
| Related links | Plain **`<.link>`** or **`<a href=…>`** with **`ScopedPath`** — no `push_patch` for list filters beyond what **InvoicesLive** / **ChargesLive** already parse from **`handle_params`**. |
| Motion | No new animations. |

---

## Accessibility

- Related card wrapper: **`aria-label`** via **`Copy.subscription_drill_related_region_aria_label/0`** (or name chosen in plan) — must describe **“related billing navigation”** not data metrics.
- Breadcrumb nav inherits **`Breadcrumbs`** component (**`aria-label="Breadcrumb"`**).

---

## Copywriting Contract

| Element | Contract |
|---------|----------|
| Related card title | Names the **region** (e.g. **“Related billing”**) — not a KPI. |
| Link labels | Concrete destinations (**“Customer”**, **“Invoices for this customer”**, **“Charges for this customer”**, **“All events”**) — **no** “filtered subscription” claims unless query parity exists. |

---

## Registry Safety

No new component registries.

---

## VERIFY / Playwright (**D-13**)

**No** new Playwright scenarios. Touch VERIFY-01 only if an **existing** spec fails after markup changes; prefer **`data-role`** / accessible names already present.
