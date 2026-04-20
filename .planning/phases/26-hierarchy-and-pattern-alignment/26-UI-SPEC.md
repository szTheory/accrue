---
phase: 26
slug: hierarchy-and-pattern-alignment
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-20
reviewed_at: 2026-04-20
---

# Phase 26 — UI Design Contract

> **Normative hierarchy and pattern alignment** on operator surfaces (money indexes, money detail, webhooks, token discipline). Inherits **Phase 20** and **Phase 21** visual tokens and locked copy; Phase 26 does **not** own microcopy polish (Phase 27) or new registries.

**Sources:** `26-CONTEXT.md` D-01..D-04, `REQUIREMENTS.md` UX-01..UX-04, `20-UI-SPEC.md`, `21-UI-SPEC.md`, `26-theme-exceptions.md`.

---

## Scope and surfaces

| UX ID | Surfaces | Contract emphasis |
|-------|----------|---------------------|
| UX-01 | `customers`, `subscriptions`, `invoices`, `charges` index LiveViews | One list-row shell: column order, signal placement (`md` from row edge between edge and chips), **exactly two** row signals per Phase 21 |
| UX-02 | Money detail LiveViews + shared detail primitives | Single outer `ax-page`; KPI region uses `ax-kpi-grid` / `KpiCard`; **no** inner `ax-page` as card chrome; **no** card nested inside confirmation/warning card |
| UX-03 | `webhooks` index + `webhook` detail | Same type scale and density rhythm as money lists (body/label/heading/display only); table cell padding uses same `--ax-space-*` steps as other admin tables |
| UX-04 | All templates/CSS touched by Phase 26 | Semantic tokens from `theme.css` default; literals only with **registry row** in `26-theme-exceptions.md` |

**Out of scope for this contract:** coupons/connect/events unless INV-03 explicitly marks them for this milestone; new `<.ax_*>` public API renames; Percy/visual CI inside `accrue_admin`.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | Phoenix LiveView + `AccrueAdmin.Components.*` + existing `ax-*` CSS from `accrue_admin` |
| Icon library | Heroicons only where already used on touched surfaces |
| Font | `--ax-font-sans` / system stack (`theme.css`) |

**Stability (semver-relevant):** `ax-*` class strings, `data-role` hooks, and documented public assigns on shared components remain compatible for v1.x; internal DOM depth may refactor **behind** function components only where duplication or spec violations cluster, without renaming those public contracts in a minor release. (`26-CONTEXT.md` D-02.)

---

## Layout and DOM hierarchy

**Single main landmark:** Each LiveView render tree exposes **one** primary `main` (via existing shell / `ax-page` contract); nested mains are forbidden.

**Nesting rules (align Phase 20):**

1. **Page shell:** exactly one top-level `ax-page` (or equivalent documented shell root) per screen.
2. **Cards:** content sections use `ax-card`; do not wrap an `ax-page` inside a card.
3. **KPI blocks:** numeric summaries live in `ax-kpi-grid` with `KpiCard`; KPI block sits **above** primary detail tables/cards unless an existing screen already documents a different order — then normalize to that documented order across money details only.
4. **Tax & ownership:** one `ax-card` at `lg` padding; internal sections separated by `md`; **no** nested card (`26-CONTEXT.md` / Phase 21).

**List rows (UX-01):** Primary row hit target is the row title link; signals sit in a **dedicated trailing cluster** with `sm` gap between the two chips and `md` inset from the row container edge (Phase 21).

**Webhooks (UX-03):** Reuse the same table typography classes / font-size tokens as money index tables; do not introduce a one-off smaller body size for webhook tables.

---

## Spacing scale

Same numeric scale as Phase 20 (multiples of **4px** via `--ax-space-*` rem tokens in `theme.css`).

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px (`--ax-space-xs`) | Icon gaps, chip internal padding |
| sm | 8px | Gap between the two list signals |
| md | 16px | Default stack gaps; row edge → signals |
| lg | 24px | Card padding |
| xl | 32px | Section separation |
| 2xl | 48px | Major breaks |
| 3xl | 64px | Page-level breathing room |

**Exceptions:** **44px** minimum hit targets for icon-only or compact controls (Phase 20). No other exceptions without ADR note.

---

## Typography

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|--------------|-------|
| Body | 16px | 400 | 1.5 | Table body, description text |
| Label | 14px | 600 | 1.4 | Headers, form labels, **list signal chips** (Phase 26 normalizes chips to this row — no 12px chip scale on touched surfaces) |
| Heading | 20px | 600 | 1.2 | Page section titles |
| Display | 28px | 600 | 1.2 | Page title in `ax-page-header` |

**Rules:** Long IDs and names wrap with `overflow-wrap: anywhere` or equivalent. No viewport-based fluid type. Uppercase eyebrows stay **14px semibold** only where already used in admin; do not add new 12px uppercase patterns on touched files in Phase 26.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `var(--ax-base)` / `var(--accrue-paper)` | Page background |
| Secondary (30%) | `var(--ax-elevated)`, `var(--ax-sunken)` | Cards, table stripes, side regions |
| Accent (10%) | `var(--ax-accent)` + readable pair | Primary row emphasis affordances only |
| Destructive / risk | `var(--ax-warning)` / success tokens per Phase 21 tri-state | Risk states, blocked replay, confirmations |

**Accent reserved for:** active org/scoped-owner emphasis, selected nav/tab, primary confirm button, focus-visible ring — **not** generic fills on every control (Phase 20).

**UX-04:** New color in HEEx/CSS must go through **semantic variable in `theme.css`** first. If a literal is unavoidable, add a row to `26-theme-exceptions.md` **before merge** (`26-CONTEXT.md` D-04).

---

## Copywriting contract

Phase 26 **does not rewrite** operator strings except where a string is moved with markup (text unchanged). Locked strings remain authoritative (`20-UI-SPEC.md`, `21-UI-SPEC.md`).

| Element | Copy |
|---------|------|
| Primary CTA (host org billing, unchanged) | Start organization subscription |
| Empty states (indexes) | No new marketing empty states; keep existing table-empty behavior for Phase 26 |
| Error state (billing action failure) | We couldn't complete that billing action for the active organization. Check organization access, billing setup, or webhook processing, then try again. |
| Cross-org denial (admin) | You don't have access to billing for this organization. |
| Ambiguous webhook replay | Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved. |
| Single replay confirmation | Replay webhook for the active organization? |
| Bulk replay confirmation | Replay {count} failed or dead webhook rows for the active organization? |

**Row navigation:** Use existing resource titles for row links; do not introduce parallel shortened titles in Phase 26.

---

## Visual hierarchy (focal points)

| Screen family | Primary anchor | Secondary |
|---------------|------------------|-----------|
| Money index | First column resource title + chevron/row affordance | Ownership + tax signal cluster (trailing) |
| Money detail | `ax-page-header` title + KPI grid | Tax & ownership card, then primary tables |
| Webhook index | Status + event type column | Timestamp, then detail link |
| Webhook detail | Page header + delivery / payload summary | Timeline or secondary panels |

Icon-only actions **must** keep `aria-label` (or visible label) consistent with existing components; no new icon-only actions without label contract in the same PR as the markup change.

---

## Verification hooks (implementation)

- **Default:** `Phoenix.LiveViewTest` + stable needles (`data-role`, `href` shapes).
- **Hierarchy:** `Floki` asserts **wrapper depth**, single `main`, and expected **counts** of `ax-card` / `ax-page` under fixture assigns where risk is nesting regressions (`26-CONTEXT.md` D-03).
- **Mounted realism:** extend `examples/accrue_host` Playwright only when the risk is not expressible in LiveViewTest (unchanged pyramid).

---

## Registry safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| Third-party UI kits / blocks | none | not required |

`REQUIREMENTS.md` out-of-scope: no new shadcn, MUI, or other registries in v1.6 admin polish.

---

## Checker sign-off

- [x] Dimension 1 Copywriting: PASS (inherits locked Phase 20/21 strings; Phase 26 is non-copy scope)
- [x] Dimension 2 Visuals: PASS (focal points + hierarchy declared)
- [x] Dimension 3 Color: PASS (60/30/10 + accent list + UX-04 exception path)
- [x] Dimension 4 Typography: PASS (four roles; chips normalized to 14px label on touched surfaces)
- [x] Dimension 5 Spacing: PASS (4px grid + documented exceptions)
- [x] Dimension 6 Registry Safety: PASS (no third-party registries)

**Approval:** approved 2026-04-20
