---
phase: 48
slug: admin-metering-billing-signals
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-22
---

# Phase 48 — UI Design Contract

> Visual and interaction contract for **ADM-01**: at least one **credible metering- or usage-adjacent** operator signal on the **admin entry path** (`AccrueAdmin.Live.DashboardLive`), with **honest deep links** into existing operator indexes (webhooks, event ledger, or other surfaces already in tree — no new accounting semantics).

---

## Phase scope (routes & components)

| Item | Contract |
|------|-----------|
| Primary surface | `AccrueAdmin.Live.DashboardLive` **index** only (mounted admin **home** / `live "/"`). |
| Shell | Reuse `AccrueAdmin.Components.AppShell` — no layout fork. |
| New UI | **Exactly one** additional operator-visible signal block implemented as **`AccrueAdmin.Components.KpiCard`** (linked when a sensible target URL exists). |
| Placement | **First position** inside the existing `section.ax-kpi-grid` (before the current “Customers” card) so metering/usage health is visible **without scroll** on common laptop viewports. Remaining four KPI cards keep **relative order** after the new card. |
| Grid | Reuse `section.ax-kpi-grid` and existing responsive rules; do **not** introduce a parallel grid system or third-party layout. If five tiles stress the column template, adjust **only** the `ax-kpi-grid` `grid-template-columns` breakpoints in `accrue_admin/assets/css/app.css` — no new layout primitive. |
| Deep links | Card **must** use `href` + `aria_label` on `KpiCard` when linking out. Target must be an **existing** LiveView route (e.g. webhooks index, events index) and must match **what the KPI actually counts** (no misleading “meter” label on unrelated aggregates). Prefer webhooks and/or event ledger when the counted rows are webhook- or ledger-backed per plan. |

---

## Design System

| Property | Value |
|----------|-------|
| Tool | **none** (no shadcn / no new UI kit) |
| Preset | not applicable |
| Component library | **Existing** `AccrueAdmin.Components.*` + HEEx only |
| Icon library | **none** added in this phase (text + existing card chrome only) |
| Font | `var(--ax-font-sans)` (system stack per `theme.css` / `app.css`) |

---

## Spacing Scale

Declared values align with **`--ax-space-*`** (multiples of **4px** at default root font size):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px (`0.25rem`) | Eyebrow / tight inline gaps |
| sm | 8px (`0.5rem`) | KPI footer gaps, chip padding |
| md | 16px (`1rem`) | Card padding, section gaps |
| lg | 24px (`1.5rem`) | Page header block spacing |
| xl | 32px (`2rem`) | Sidebar / major section padding |
| 2xl | 48px (`3rem`) | Rare page-level breaks |

**Exceptions:** none beyond existing `AppShell` / `ax-page` patterns.

---

## Typography

Use **only** existing utility roles (no new font-size tokens for this phase):

| Role | Size | Weight | Line height | Class / context |
|------|------|--------|--------------|-----------------|
| Display + KPI value | 1.75rem | 600 | 1.2 | `.ax-display` (page title) and `.ax-kpi-value` (numeric KPI) — **one scale step**, two roles |
| Heading (card titles) | 1.25rem | 600 | 1.2 | `.ax-heading` — activity sections |
| Body | 1rem | 400 / 600 per existing | 1.5 | `.ax-body`, `.ax-page-copy` |
| Label (KPI title) | 0.875rem | 600 | 1.4 | `.ax-label` inside `KpiCard` |

**Constraint:** No additional font-size declarations for Phase 48; **four** distinct sizes max (label 14px, body 16px, heading 20px, display/KPI 28px at default 16px root).

---

## Color

Contract uses **semantic CSS variables** only (`html.accrue-admin` in `accrue_admin/assets/css/theme.css` + `app.css`). No raw hex in LiveView for this phase.

| Role | Token | Usage |
|------|-------|-------|
| Dominant (~60%) | `--ax-base` | Page background |
| Secondary (~30%) | `--ax-elevated`, `--ax-sunken` | Cards, KPI surfaces |
| Accent (~10%) | `--ax-accent` (host `--accrue-*` bridge) | **Only**: focus ring mixes, active nav, linked-card hover border, **KPI delta** “cobalt” tone when used for informational (not success) emphasis |
| Muted copy | `--ax-muted` | Meta lines, deltas explained |
| Attention | `--ax-warning` / readable variants | `delta_tone="amber"` when count > 0 for “needs attention” semantics |
| Healthy | `--ax-success` | `delta_tone="moss"` when backlog is zero / healthy |

**Accent reserved for:** linked KPI hover/focus border treatment, optional cobalt delta for secondary numeric, focus-visible ring — **not** for all links site-wide (inherits existing admin behavior).

**Destructive:** No destructive actions on Dashboard for this phase — **n/a** for new UI. Existing flows unchanged.

---

## Interaction & motion

| Topic | Rule |
|-------|------|
| Linked KPI | Full-card `<a class="ax-kpi-card--linked">` — same as existing cards; keyboard focus uses existing `:focus-visible` styles. |
| Motion | Respect `prefers-reduced-motion` via existing `--ax-theme-transition` — no new animations. |

---

## Copywriting Contract

All **new or changed** operator-visible strings for this phase go through **`AccrueAdmin.Copy`** (functions named under a `dashboard_meter_*` or `dashboard_usage_*` prefix — exact names chosen in plan). **Do not** embed new literals in `dashboard_live.ex`.

| Element | Copy contract |
|---------|----------------|
| New KPI **label** | Must name the **actual** aggregate (e.g. if counting stuck meter-event rows: **“Meter events pending sync”**; if surfacing recent failures: **“Meter reporting failures (24h)”**). Forbidden: vague **“Usage”** or **“Meters”** without tying to stored projections. |
| New KPI **meta** (`:meta` slot) | One sentence stating **data source** (e.g. local `accrue_meter_events` / webhook pipeline) — same honesty bar as `Copy.dashboard_page_copy_primary()`. |
| New KPI **aria_label** | Action + destination, e.g. **“Open webhooks list filtered to meter errors”** (must match real `href` behavior). |
| Primary CTA (card) | N/A — the **card** is the affordance; no **“Submit”** / **“OK”** buttons added on Dashboard. |
| Empty state | If count is zero **and** a delta line would be empty: show **numeric zero** plus meta; do not use “No data found”. If a **secondary** query returns no rows for a footnote, omit the footnote rather than placeholder copy. |
| Error / load failure | If the dashboard query fails: reuse existing **“billing projections unavailable”** pattern if present; otherwise add **one** `Copy.dashboard_*` string that states **problem + next step** (e.g. check DB / logs) — never bare **“Something went wrong”** without a path. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | **none** | not required |
| Third-party UI | **none** | n/a |

---

## Verification hooks (for later ADM-06)

| Gate | Expectation |
|------|-------------|
| ExUnit | Assertions reference **`AccrueAdmin.Copy`** helpers for any new dashboard metering strings. |
| Playwright | If VERIFY-01 covers mounted admin home, extend **only** selectors that remain stable (prefer `data-test-id` added in execution phase if required — not mandated in UI-SPEC). |
| axe | New card is **keyboard-focusable** (linked card) and exposes **`aria-label`** when `href` is set — same bar as existing KPI cards. |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending — fill after `/gsd-plan-phase` execution verification if desired
