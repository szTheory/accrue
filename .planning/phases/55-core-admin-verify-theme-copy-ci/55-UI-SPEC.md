---
phase: 55
slug: core-admin-verify-theme-copy-ci
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-22
---

# Phase 55 — UI Design Contract

> **ADM-09..ADM-11** add **merge-blocking VERIFY-01** (**Playwright** + **axe**) for the **ADM-08** invoice anchor, keep **`theme-exceptions.md`** honest, and align **`export_copy_strings`** / **`copy_strings.json`** / CI allowlists with **`AccrueAdmin.Copy.Invoice`** growth. **No new UI kits**; **VERIFY-01 policy** (merge-blocking vs advisory) is **unchanged** (**54-CONTEXT D-22**).

---

## Phase scope (surfaces)

| Item | Contract |
|------|-----------|
| VERIFY anchor (**ADM-09**) | **`/invoices`** (`InvoicesLive` `:index`) and **`/invoices/:id`** (`InvoiceLive` `:show`) — locked in **54-CONTEXT D-06** as the **ADM-08** money-primary group Phase 55 extends. |
| Parity guide | Update **`accrue_admin/guides/core-admin-parity.md`** for the invoice rows: assign **named VERIFY flow ids**, flip **`VERIFY-01 lane`** from **`planned — Phase 55 (ADM-09)`** to **`merge-blocking`** only when specs ship in this phase (**D-03**). |
| Theme register (**ADM-10**) | Any **new** token/layout deviation introduced while wiring VERIFY or Copy export must get a **slugged** row in **`accrue_admin/guides/theme-exceptions.md`** with **location**, **deviation**, **rationale**, **future_token**, **status**, **phase_ref** — or the markup is corrected to **`ax-*` / `--ax-*`** (**Phase 50** precedent). |
| Copy export (**ADM-11**) | If **`AccrueAdmin.Copy.Invoice`** (or other Copy modules touched for VERIFY stability) adds or renames public string functions, run **`mix accrue_admin.export_copy_strings`**, commit **`examples/accrue_host/e2e/generated/copy_strings.json`**, and extend CI allowlists / generator contracts per **Phase 53** hygiene — **no drive-by JSON churn** outside the invoice anchor closure. |
| Host VERIFY spine | Extend **`examples/accrue_host/e2e/verify01-admin-a11y.spec.js`** (or successor) following **54-CONTEXT D-08**: prefer **`getByRole` / accessible names** wired to **`AccrueAdmin.Copy`** outputs over brittle currency snapshots; treat **PDF / new tab / download** edges explicitly so flakes do not land on **`main`**. |
| Out of scope | **PROC-08**, **FIN-03**, VERIFY **policy renames**, new third-party registries, **URL-matrix** / crawl-style coverage (**54-CONTEXT D-12**), expanding merge-blocking axe to **non–ADM-08** core rows unless an explicit CONTEXT amendment adopts a new anchor (**54-CONTEXT D-09**). |

---

## Design system

| Property | Value |
|----------|-------|
| Tool | **none** (Phoenix **LiveView** + HEEx) |
| Preset | not applicable |
| Component library | **`AccrueAdmin.Components.*`** (existing admin shell) |
| Icon library | **Heroicons** (existing usage only) |
| Font | **`--ax-font-sans`** — bundled admin CSS / **`theme.css`** |

---

## Spacing scale

Inherited **v1.12 / v1.13** admin contract — **`--ax-space-*`** (multiples of **4px** at default root):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact stacks |
| md | 16px | Default gutters |
| lg | 24px | Section padding |
| xl | 32px | Page rhythm |
| 2xl | 48px | Major section breaks |

**Exceptions:** **44px** minimum hit targets for icon-only controls where WCAG requires; register in **theme-exceptions** if **`ax-*` spacing alone** cannot satisfy layout.

---

## Typography

| Role | Implementation | Weight | Line height |
|------|----------------|--------|---------------|
| Label / table header | `.ax-table-header` / compact **`0.875rem`** rows | **600** | **1.25** |
| Body | `.ax-body` | **400** | **1.5** |
| Eyebrow | `.ax-eyebrow` | **600** | **1.25** |
| Display (page title) | `.ax-display` | **600** | **1.2** |

**Max four visual steps** on invoice surfaces: eyebrow → body → display — no ad-hoc fifth size for VERIFY-visible chrome.

---

## Color (60 / 30 / 10)

| Role | Token / surface | Usage |
|------|-----------------|-------|
| Dominant (**60%**) | `--ax-base` | Page canvas behind invoice tables and KPI grids |
| Secondary (**30%**) | `--ax-elevated`, `--ax-sunken`, `--ax-border` | Cards, table chrome, PDF panel |
| Accent (**10%**) | `--ax-accent` + readable pair | **Primary invoice workflow confirm** (`Copy.invoice_confirm_action_verb()` context), **focus-visible** rings, **single primary drill** into detail from the index when it is the obvious next step |
| Destructive / caution | Readable **warning** / **destructive** text from existing admin patterns | **`Void invoice`**, **`Mark uncollectible`**, and other irreversible workflow actions keep **Copy-backed** labels; do not invent new destructive hues |

**Accent reserved for:** primary **confirm** on the invoice action panel, **focus-visible** outlines, **one** primary navigation accent consistent with **`ax-sidebar-link-active`** tests. **Not** for every filter chip, sort control, or secondary metadata link.

---

## Copywriting contract

All operator-visible strings on VERIFY-visible paths remain **`AccrueAdmin.Copy`** / **`AccrueAdmin.Copy.Invoice`** — Playwright selectors should target **roles and accessible names** derived from these functions (not duplicated English in specs).

| Element | Copy (SSOT = `AccrueAdmin.Copy.Invoice` unless noted) |
|---------|---------------------------------------------------------|
| Primary workflow actions (toolbar / panel) | **`Finalize invoice`**, **`Manual pay`**, **`Void invoice`**, **`Mark uncollectible`** — respective `invoice_action_*` functions; each must keep a **verb + object** shape (no bare **Save** / **Submit**). |
| Confirm panel | **`Confirm action`** (`invoice_confirm_panel_label/0`) scopes the panel; the confirm control stays **`invoice_confirm_action_verb/0`** but MUST remain **programmatically tied** to `invoice_confirm_workflow_message/2` (e.g. `aria-describedby`) so assistive tech never hears a lone generic verb. |
| Dismiss confirm panel | **`invoice_confirm_cancel/0`** — if the literal is a single generic word, **ADM-08/55** UI work replaces it with **Dismiss invoice change** or equivalent **verb + noun** while keeping **one** Copy function as SSOT. |
| Invoice index empty heading | **`No invoices for this organization yet`** — `invoices_index_empty_title/0` |
| Invoice index empty body | **`invoices_index_empty_copy/0`** (multi-sentence guidance stays in Copy) |
| Invoice index page title / headline | **`Invoices`** + **`Collections and invoice review`** — `invoices_page_title_index/0`, `invoices_index_headline/0` |
| Error / guard (action without selection) | **`Select an invoice action before confirming.`** — `invoice_select_action_warning/0` |
| Destructive-adjacent confirmation (void / uncollectible flows) | Confirmations must name the **invoice workflow** being applied via existing **action-specific** `Copy` strings — not generic “Are you sure?” |
| PDF / download controls | **`Open PDF`**, **`Download rendered PDF`**, **`Open rendered PDF`** — `invoice_open_pdf_button/0`, `invoice_download_rendered_pdf_link/0`, `invoice_open_rendered_pdf_link/0` |

---

## VERIFY-01 interaction contract (**ADM-09**)

| Rule | Detail |
|------|--------|
| **Named flows** | Add stable **`Named VERIFY flow id`** values in **`core-admin-parity.md`** for **`/invoices`** and **`/invoices/:id`** (e.g. `core-admin-invoices-index`, `core-admin-invoices-detail`) — **no URL crawls** (**Phase 50 D-19**). |
| **axe gate** | **Serious** + **critical** violations are merge-blocking, matching **Phase 53** / existing **`verify01-admin-a11y.spec.js`** posture. |
| **Themes** | Run **light** and **dark** theme scans on **desktop** projects; **skip mobile** projects where the theme toggle is hidden — mirror **existing** customers/subscriptions axe tests. |
| **Stable selectors** | Prefer **`getByRole('link' \| 'button', { name: … })`** with names from **`copy_strings.json`** / **`AccrueAdmin.Copy`**; avoid snapshotting **formatted money** unless a dedicated stable **`aria-label`** or test id is introduced and documented here. |
| **PDF / download** | Use **expectations** that match how **`InvoiceLive`** exposes **Open PDF** / **Download rendered PDF** — if a new tab or download event is flaky, gate with **`test.step`** + explicit **`waitForLoadState`** or mark **documented advisory** only if VERIFY policy already allows (default: **fix the UX or test**, do not silently downgrade merge-blocking). |

---

## Registry safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | **none** | not applicable |
| Third-party UI kits | **none** | not applicable |

---

## Checker sign-off

- [x] Dimension 1 Copywriting: PASS — operator copy locked to **`AccrueAdmin.Copy.Invoice`**; CTAs are **action-specific** (no generic **Submit** / **OK** for primary workflow).
- [x] Dimension 2 Visuals: PASS — **focal hierarchy**: index **`ax-kpi-grid` + primary table** first; detail **invoice summary KPIs + workflow panel** first; side chrome secondary.
- [x] Dimension 3 Color: PASS — **60/30/10** with **accent reserved** list explicit; destructive/caution paths tied to existing **Copy** labels.
- [x] Dimension 4 Typography: PASS — **≤4** scale steps on VERIFY-visible invoice chrome.
- [x] Dimension 5 Spacing: PASS — **`--ax-space-*`** multiples of **4px**; documented **44px** touch exception path.
- [x] Dimension 6 Registry Safety: PASS — **no third-party component registries** in scope.

**Approval:** approved 2026-04-22

---

## UI-SPEC COMPLETE

Phase **55** design contract is ready for **`/gsd-plan-phase 55`** (or **`/gsd-discuss-phase 55`** if maintainers want additional CI policy decisions before planning).
