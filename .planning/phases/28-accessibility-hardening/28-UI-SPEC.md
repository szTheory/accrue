---
phase: 28
slug: accessibility-hardening
status: approved
shadcn_initialized: false
preset: none
created: 2026-04-20
reviewed_at: 2026-04-20T00:00:00Z
---

# Phase 28 — UI Design Contract

> **Accessibility hardening** for mounted `accrue_admin`: focus and modals, credible table semantics, WCAG AA contrast in light and dark themes, and at least one automated gate on a real admin path. Inherits **Phase 20**, **Phase 21**, and **Phase 26** tokens, hierarchy, and locked copy; does **not** introduce new visual branding or third-party UI kits.

**Sources:** `.planning/REQUIREMENTS.md` (A11Y-01..04), `21-UI-SPEC.md`, `26-UI-SPEC.md`, `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`, `AccrueAdmin.Components.DataTable`, `AccrueAdmin.Components.StepUpAuthModal`.

---

## Scope and requirements

| Req ID | Contract emphasis |
|--------|---------------------|
| **A11Y-01** | Step-up and any other `role="dialog"` surfaces: predictable **focus** (initial focus, return focus to trigger, Escape where supported), **no focus loss** on patch/update, and **visible `:focus-visible` rings** on all interactive `ax-*` controls in light and dark themes (extends existing `--ax-focus-ring` usage). |
| **A11Y-02** | **Grid tables** (`DataTable` desktop layout): `<thead>` / `scope="col"` baseline is already present; add a **machine-readable table name** (prefer `<caption class="…">` with optional visually-hidden utility, or `aria-labelledby` pointing to existing page heading) on **one representative index per family** — **customers** and **webhooks** — so header↔cell association is credible in screen readers. Card/mobile layout: preserve **`<dl>` / `<dt>` / `<dd>`** pairings already used; do not regress label/value coupling. |
| **A11Y-03** | **WCAG 2.2 AA** contrast for body text, labels, `ax-button` variants, links, and chips on **representative routes** (at least: customers index, one money detail, webhooks index) in **light and dark** themes — documented **spot-check procedure** (token list + viewport) **or** coverage via the same automated axe run as A11Y-04 where rules apply. |
| **A11Y-04** | At least one **CI** job runs **`@axe-core/playwright`** (or equivalent) against a **mounted admin** URL in `examples/accrue_host` (or documented test host), failing the build on serious violations; if temporarily infeasible, a short **ADR in-repo** explains the gap and the follow-up milestone (per REQUIREMENTS). |

**Out of scope:** Full-site WCAG audit of every LiveView; host demo app styling outside admin mount; new registries or non-semantic color literals (still governed by Phase 26 UX-04).

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | Phoenix LiveView + `AccrueAdmin.Components.*` + `ax-*` CSS (`theme.css` / `app.css`) |
| Icon library | Heroicons only where already used |
| Font | `--ax-font-sans` / system stack (`theme.css`) |

---

## Spacing scale

Identical to Phase 26 — multiples of **4px** via `--ax-space-*`.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact gaps |
| md | 16px | Default stacks |
| lg | 24px | Card padding |
| xl | 32px | Section separation |
| 2xl | 48px | Major breaks |
| 3xl | 64px | Page-level spacing |

**Exceptions:** **44px** minimum hit targets for icon-only or compact controls (Phase 20). No additional exceptions without ADR.

---

## Typography

| Role | Size | Weight | Line height | Usage |
|------|------|--------|--------------|-------|
| Body | 16px | 400 | 1.5 | Table body, dialog body, errors |
| Label | 14px | 600 | 1.4 | Column headers, form labels |
| Heading | 20px | 600 | 1.2 | Section titles |
| Display | 28px | 600 | 1.2 | Page title in `ax-page-header` |

No additional font sizes or weights in Phase 28-only markup.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `var(--ax-base)` / paper tokens | Page background |
| Secondary (30%) | `var(--ax-elevated)`, `var(--ax-sunken)` | Cards, stripes |
| Accent (10%) | `var(--ax-accent)` + readable pair | Primary actions, selected nav, **focus ring mix** (`--ax-focus-ring`) |
| Destructive / risk | warning / error semantic tokens | Risk states, destructive confirmations |

**Accent reserved for:** primary confirm control, selected nav/tab, scoped-owner emphasis, **focus-visible ring** — not generic fill on every control (Phase 20 / 26).

**A11Y-03:** Any new text/background pair introduced in Phase 28 must meet **4.5:1** for normal text and **3:1** for large text / UI components per WCAG AA; prefer existing semantic variables over literals.

---

## Copywriting contract

Phase 28 **inherits** locked host/admin strings from **Phase 20 / 21 / 27** where unchanged. Only **accessibility-facing** additions or clarifications below.

| Element | Copy |
|---------|------|
| Step-up primary action (submit control) | **Verify identity** (replaces bare “Verify” on the submit control — verb + object, screen-reader friendly) |
| Step-up dialog title | **Step-up required** (keep `id="step-up-title"` as `aria-labelledby` target) |
| Step-up error (structure) | Keep `data-role="step-up-error"`; body text remains implementation-defined but must describe **what failed** and **what to try next** (no standalone “Something went wrong”). |
| Data table filter submit | **Apply filters** (existing — keep) |
| Data table clear | **Clear** acceptable as secondary control next to Apply; if reduced to icon-only, add **`aria-label="Clear filters"`**. |
| Row selection toggle | **Select** / **Selected** (existing toggle labels — acceptable for binary row state) |
| Destructive confirmations | Use exact strings from **21-UI-SPEC.md** / `AccrueAdmin.Copy` (e.g. replay confirmations) — no generic “OK” / “Submit”. |
| Empty states | Continue **Phase 27** / `Copy` module strings — do not introduce “No data found” / “Nothing here” placeholders. |

---

## Interaction and focus contract (A11Y-01)

| Surface | Requirement |
|---------|-------------|
| **Step-up modal** (`StepUpAuthModal`) | On open: move **initial focus** to the first focusable control inside the dialog (challenge field, or **Verify identity** if no field). On successful dismiss or cancel: **return focus** to the element that opened the step-up. Document chosen mechanism (`phx-hook`, `JS.exec`, or LiveView **focus wrap** API) in phase verification notes. |
| **Keyboard** | **Escape** closes or cancels the dialog when product semantics allow; if not dismissible, document **why** in the same verification doc. |
| **Focus rings** | All new or touched interactive elements use existing **`:focus-visible`** patterns (`border-color: var(--ax-focus-ring)`, `outline: none`) — verify in **light and dark** themes. |
| **Skip link** | Preserve existing **skip to main** behavior; do not remove or hide without replacement. |

---

## Tables and structure (A11Y-02)

| Layout | Contract |
|--------|----------|
| **Desktop grid** | Keep `<table>` / `<thead>` / `scope="col"`; ensure header text matches visible column labels. |
| **Caption / name** | Representative **customers** and **webhooks** indexes expose a **concise table name** (caption or `aria-labelledby`) aligned with the page purpose (e.g. includes resource type; may reference active org context where already shown in page chrome). |
| **Selection column** | Header text **Select** remains valid; toggle buttons keep `aria-pressed`. |
| **Card layout** | Maintain `dt`/`dd` association for field rows. |

---

## Contrast and verification (A11Y-03 / A11Y-04)

| Theme | Minimum verification |
|-------|----------------------|
| Light | Representative pages: body on base, label on elevated, primary button text on accent, link on base. |
| Dark | Same routes with dark theme active — no regressions against AA for the same tokens. |

**Automation:** Playwright + `@axe-core/playwright` (or equivalent) runs on **at least one** mounted admin path that renders `DataTable` and navigational chrome (exact spec path recorded in plan / verification doc). Serious axe violations fail CI.

---

## Visual hierarchy (focal points)

| Context | Primary anchor | Notes |
|---------|----------------|-------|
| Step-up dialog | `#step-up-title` + first field | User must immediately understand auth gate. |
| Customers / webhooks index | Page header + named table | Screen reader users hear page purpose then table scope. |

Icon-only controls must retain **`aria-label`** (or visible text) per Phase 26; Phase 28 audits for gaps.

---

## Registry safety

| Registry | Blocks used | Safety gate |
|----------|-------------|-------------|
| shadcn official | none | not required |
| Third-party UI kits | none | not required |

---

## Checker sign-off

- [x] Dimension 1 — Copywriting: PASS (specific step-up CTA; inherits locked strings elsewhere)
- [x] Dimension 2 — Visuals: PASS (focal points for dialog + indexes declared)
- [x] Dimension 3 — Color: PASS (60/30/10 + accent reserved list + contrast obligation)
- [x] Dimension 4 — Typography: PASS (four roles, two weights)
- [x] Dimension 5 — Spacing: PASS (4px grid + 44px exception)
- [x] Dimension 6 — Registry safety: PASS (no third-party registries)

**Approval:** approved 2026-04-20
