---
phase: 50
slug: copy-tokens-verify-gates
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-22
---

# Phase 50 — UI Design Contract

> **ADM-04 / ADM-05 / ADM-06** are **discipline and verification** gates, not a new visual system. This contract locks **what may change** on screen and **how** tests reference it.

---

## Phase scope (surfaces)

| Item | Contract |
|------|-----------|
| In-scope packages | `accrue_admin` LiveViews under **`live/**/*.ex`**, shared **`components/**/*.ex`**, and **`AccrueAdmin.Copy`** (+ optional **`lib/accrue_admin/copy/*.ex`** delegates). |
| Out of scope | New third-party UI kits; **PROC-08** / **FIN-03**; changing VERIFY-01 **merge-blocking vs advisory** semantics (**D-17**). |
| Host integration | **`examples/accrue_host`** — extend **VERIFY-01** Playwright specs only; no fork of host chrome beyond documented axe scope (**D-21**). |

---

## Copy (ADM-04)

| Rule | Detail |
|------|--------|
| SSOT | **All new/changed v1.12 operator-visible literals** in the enforcement glob use **`AccrueAdmin.Copy.*`** or **`AccrueAdmin.Copy.Locked.*`** — not raw HEEx string blobs (**50-CONTEXT D-01**). |
| Growth | Prefer **`lib/accrue_admin/copy/<domain>.ex`** + **`defdelegate`** from **`AccrueAdmin.Copy`** (**D-07**). |
| Locked | **`Copy.Locked`** only for verbatim / cross-surface-sensitive text (**D-06**). |
| Playwright | Selectors default to **`getByRole` / `getByLabel`** using strings **sourced from Copy** — **no hand-duplicated English** once **D-23** anti-drift ships (**50-CONTEXT**). |
| Scalpel | **`data-test-id`** only when roles/names are ambiguous; prefix policy carries forward from **Phase 48** (**D-22**). |

---

## Tokens & layout (ADM-05)

| Rule | Detail |
|------|--------|
| Defaults | **`ax-*` primitives** and **semantic CSS variables** (`--ax-*`) for touched summary/KPI/card rows. |
| Exceptions | Every intentional deviation has **one row** in **`accrue_admin/guides/theme-exceptions.md`** + **one inline pointer** comment at site (**D-10–D-12**). |
| ADRs | Policy-only — not per-row narratives (**D-14**). |

---

## VERIFY-01 / Playwright (ADM-06)

| Rule | Detail |
|------|--------|
| Inventory | Merge-blocking completeness is judged against a **checked-in path inventory** (union of v1.12 touched mounted flows), **not** git-diff-only (**D-15**). |
| Spec shape | **Per-flow**: setup → navigate → LiveView readiness → critical affordances → **one** `@axe-core/playwright` pass (**D-19–D-20**). |
| Readiness | **No `networkidle`** as primary LV wait — locator-driven / **`waitForLiveView`** + visible landmarks (**D-20**). |
| Split threshold | New spec file only if primary spec exceeds **~400–500** lines or `describe` ownership breaks down (**D-18**). |

---

## Design system

Unchanged from **Phase 48/49**: existing **`AccrueAdmin.Components.*`**, HEEx, **`theme.css` / `app.css`** tokens — **no new preset or font stack**.

---

## Interaction & motion

No new motion; respect existing **`prefers-reduced-motion`** usage.

---

## Accessibility

- **axe**: **serious** + **critical** violations fail merge-blocking jobs (existing VERIFY-01 posture).
- Full-page axe while host layout stays clean; document any future **scoped root** or **disableRules** with rationale (**D-21**).

---

## Success (UI-facing)

- Operators see **no regression** in hierarchy/readability; only **copy centralization**, **token compliance**, and **test harness** changes visible where explicitly migrated.
- **ADM-06** inventory paths each have **Playwright + axe** coverage per **`50-VERIFICATION.md`**.
