---
phase: 54
slug: core-admin-inventory-first-burn-down
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-22
---

# Phase 54 — UI Design Contract

> **ADM-07 / ADM-08** are **parity inventory + copy/token conformance** on existing LiveViews — **no new visual system**, charts, or third-party kits. This contract locks **what may change** on the **invoice anchor** and what stays **documentation-only**.

---

## Phase scope (surfaces)

| Item | Contract |
|------|-----------|
| In-scope packages | `accrue_admin` — **`InvoicesLive`** + **`InvoiceLive`** for **ADM-08**; **guides** only for **ADM-07** matrix. Shared **`components/**`** only when **rendered in the invoice list/detail route closure** per **54-CONTEXT D-13**. |
| Out of scope | New merge-blocking **Playwright + axe** flows (**ADM-09**, Phase 55); systematic **`export_copy_strings` / `copy_strings.json` / CI allowlist** expansion (**ADM-11**, Phase 55) unless an **existing** generated JSON consumer would **break** without a minimal sync (**54-CONTEXT D-15**). **PROC-08** / **FIN-03**; new UI kits. |
| Host integration | **`examples/accrue_host`** — **no new** VERIFY-01 specs in Phase 54; edit **existing** specs only if ADM-08 would otherwise make assertions false (**54-CONTEXT D-14**). |

---

## Copy (ADM-08)

| Rule | Detail |
|------|--------|
| SSOT | Operator-visible English on the **invoice index + detail** paths routes through **`AccrueAdmin.Copy`** (or **`lib/accrue_admin/copy/*.ex`** + **`defdelegate`**) — not raw HEEx literals for migrated strings (**54-CONTEXT D-10**). |
| Growth | Prefer **`AccrueAdmin.Copy.Invoice`** (or similarly named submodule) when volume exceeds comfortable `copy.ex` size (**Phase 50 D-07** precedent). |
| Tests | **`invoices_live_test.exs`** / **`invoice_live_test.exs`** (and any **materially touched** tests) assert **Copy-backed** strings via **`Copy.function_name()`** — no duplicated English for migrated copy (**54-CONTEXT D-10**). |

---

## Tokens & layout

| Rule | Detail |
|------|--------|
| Defaults | **`ax-*`** classes and **`--ax-*`** variables on **touched** markup; align to **v1.6 UX-04** intent. |
| Exceptions | Register **honest** rows in **`accrue_admin/guides/theme-exceptions.md`** when a deviation remains after burn-down; prefer **fix** on touched rows (**54-CONTEXT D-10**). |

---

## VERIFY-01 boundary (Phase 54)

| Rule | Detail |
|------|--------|
| Policy | **Unchanged** merge-blocking vs advisory semantics (**54-CONTEXT D-22**). |
| Inventory column | **`core-admin-parity.md`** uses **`planned — Phase 55 (ADM-09)`** for core rows until specs exist (**54-CONTEXT D-03**). |
| Assertions | Prefer **stable roles/labels** sourced from Copy when future Playwright work lands; Phase 54 does not expand axe coverage (**54-CONTEXT D-14**). |

---

## Design system

Unchanged from **Phase 48–50**: **`AccrueAdmin.Components.*`**, HEEx, **`theme.css`** — **no new preset or font stack**.

---

## Accessibility

- **No regression** in semantic structure (landmarks, headings, button names) while migrating literals to Copy.
- **axe** posture unchanged for Phase 54 — **no new** merge-blocking scans on invoice routes here.

---

## Success (UI-facing)

- **`core-admin-parity.md`** is the **canonical ADM-07** matrix (**54-CONTEXT D-01**).
- **Invoice list + detail** operator chrome is **Copy-backed** and **token-correct** on **git-touched** files in the anchor closure (**ADM-08**).
