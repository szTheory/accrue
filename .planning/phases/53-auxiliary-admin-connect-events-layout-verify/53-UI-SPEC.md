---
phase: 53
slug: auxiliary-admin-connect-events-layout-verify
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-22
reviewed_at: 2026-04-22
---

# Phase 53 — UI Design Contract

> **AUX-03..AUX-06** extend **Phase 52** copy discipline to **Connect** + **events**, lock **`ax-*` / token** usage, and expand **VERIFY-01** (**Playwright** + **axe**) across materially touched **auxiliary** mounted paths. **No new UI kits**; inherits **Phase 50** verification posture.

---

## Phase scope (surfaces)

| Item | Contract |
|------|-----------|
| In-scope LiveViews | **`ConnectAccountsLive`**, **`ConnectAccountLive`**, **`EventsLive`** — operator-visible English via **`AccrueAdmin.Copy`** (new **`Copy.Connect`** / **`Copy.BillingEvent`** modules + **`defdelegate`** from **`AccrueAdmin.Copy`**, mirroring coupon/promo split). |
| Layout / tokens | **`ax-*`** classes and **`--ax-*`** semantic variables on all **v1.13**-touched auxiliary rows per **AUX-05** / **UX-04**; register unavoidable deviations in **`accrue_admin/guides/theme-exceptions.md`**. |
| VERIFY | **AUX-06**: every materially touched mounted-admin path for **AUX-01..AUX-04** gets or extends **VERIFY-01** coverage — **serious** + **critical** **axe** failures remain merge-blocking; reuse **`e2e/generated/copy_strings.json`** + **`export_copy_strings`** where it reduces drift (**Phase 50 D-18–D-23**). |
| Out of scope | **PROC-08**, **FIN-03**, new third-party component registries, VERIFY-01 **policy** renames. |

---

## Design system

| Property | Value |
|----------|-------|
| Tool | **none** (Phoenix **LiveView** + HEEx; not React/shadcn) |
| Preset | not applicable |
| Component library | **`AccrueAdmin.Components.*`** (`AppShell`, `Breadcrumbs`, `DataTable`, `KpiCard`, `FlashGroup`, …) |
| Icon library | **Heroicons** (existing `heroicons` usage only; no new pack) |
| Font | **`--ax-font-sans`** — system UI stack (`app.css` / bundled admin CSS) |

---

## Spacing scale

Declared **`--ax-space-*`** tokens (multiples of **4px** at default root font size):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px (`0.25rem`) | Inline gaps, tight meta |
| sm | 8px (`0.5rem`) | Compact stacks |
| md | 16px (`1rem`) | Default padding / gutters |
| lg | 24px (`1.5rem`) | Section padding |
| xl | 32px (`2rem`) | Page rhythm |
| 2xl | 48px (`3rem`) | Major section breaks |

**Exceptions:** **44px** minimum hit target for icon-only controls (WCAG touch); document in **theme-exceptions** if layout cannot use **`ax-*`** spacing alone.

---

## Typography

| Role | Implementation | Weight | Line height |
|------|------------------|--------|-------------|
| Label / table header | `.ax-table-header` / compact **`0.875rem`** utility rows | **600** | **1.25** |
| Body | `.ax-body` | **400** | **1.5** |
| Eyebrow | `.ax-eyebrow` | **600** | **1.25** |
| Display (page title) | `.ax-display` | **600** | **1.2** |

**Max four visual steps** on these surfaces: eyebrow → body → single heading step via **`.ax-display`** (no ad-hoc fifth size).

---

## Color (60 / 30 / 10)

| Role | Token / surface | Usage |
|------|-----------------|-------|
| Dominant (**60%**) | `--ax-base` | **`AppShell`** canvas, page background |
| Secondary (**30%**) | `--ax-elevated`, `--ax-sunken`, `--ax-border` | Cards, KPI tiles, table chrome, side regions |
| Accent (**10%**) | `--ax-accent` + readable pair | **Primary row action** (“Save platform fee override”), **focus ring** (`--ax-focus-ring`), **in-table link** to detail when it is the single primary drill |
| Destructive | `--ax-warning` / readable text for cautionary deltas; use **`--ax-accent`** only where existing admin patterns already mark irreversible delete (none required on Connect/events in this phase unless a destructive control already exists — then **readable destructive** text from theme) | Reserved for **deauthorize** / **irreversible** affordances only |

**Accent reserved for:** primary **save** on **Connect** fee override, **focus-visible** outlines, **primary text links** that navigate into the **one** obvious next step (e.g. open account from list). **Not** for every sort chip, filter label, or breadcrumb.

---

## Copywriting contract

All strings below are **targets** for **`AccrueAdmin.Copy`** (or delegated modules); HEEx must call functions — **no** new raw English on touched paths.

| Element | Copy |
|---------|------|
| Primary CTA (Connect detail — save override) | **Save platform fee override** |
| Secondary CTA (filters / table) | **Apply filters** (table toolbar submit) |
| Connect index empty heading | **No connected accounts yet** |
| Connect index empty body | **Stripe projections will appear here after your integration creates Connect accounts. Check webhooks and owner scope if you expect rows.** |
| Events index empty heading | **No billing events matched** |
| Events index empty body | **Loosen filters or trigger a subscription or invoice change, then refresh this index.** |
| Error state (generic LiveView failure) | **This Connect view failed to load. Retry from the Connect list; if it persists, inspect logs for the owner scope you selected.** |
| Destructive confirmation (only if exposing deauthorize / hard delete) | **Deauthorize Connect account:** confirm modal title **Remove this connected account**; body **This stops payouts and platform fee overrides for this Stripe account until reconnected.** |

---

## Registry safety

| Registry | Blocks used | Safety gate |
|----------|-------------|-------------|
| *(none)* | — | **not applicable** — no shadcn / third-party UI registry in **`accrue_admin`** |

---

## Visual hierarchy (focal point)

1. **`ax-page-header`** (breadcrumbs + eyebrow + **`.ax-display`** title + page copy).  
2. **`ax-kpi-grid`** summary strip.  
3. **`DataTable`** as the primary scan surface (Connect index / Events index).  
4. **Connect detail**: override editor block is **secondary** focal — visually subordinate to KPI summary.

Icon-only controls (if any) keep **`aria-label`** sourced from **Copy** alongside the icon.

---

## VERIFY-01 / Playwright

| Rule | Detail |
|------|--------|
| Inventory | Extend the **checked-in** mounted-path list to include **`/connect`**, **`/connect/:id`**, **`/events`** (and any coupon/promo paths touched while satisfying **AUX-06**). |
| Spec shape | **Per path**: auth/setup → navigate → **locator-driven** LiveView readiness (**no `networkidle`**) → assert **one** critical affordance → **`@axe-core/playwright`** serious+critical clean. |
| Strings in tests | **Playwright** assertions use **`e2e/generated/copy_strings.json`** (after export pipeline) or **`AccrueAdmin.Copy`** helpers — **no** hand-duplicated English for SSOT-owned strings. |

---

## Checker sign-off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-04-22

---

## Success (UI-facing)

- **Connect** + **events** pages read with the same **copy SSOT** discipline as coupons/promos; grep for new operator phrases resolves to **`AccrueAdmin.Copy`** (or **`Copy.Connect`** / **`Copy.BillingEvent`** delegates).
- **axe** posture matches **v1.12** on all materially touched auxiliary routes in scope.
- **Theme exceptions** file updated for any token bypass, each with rationale + pointer comment in code.
