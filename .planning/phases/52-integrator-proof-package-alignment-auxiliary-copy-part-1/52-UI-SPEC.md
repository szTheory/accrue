---
phase: 52
slug: integrator-proof-package-alignment-auxiliary-copy-part-1
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-22
---

# Phase 52 — UI Design Contract

> **INT-04 / INT-05** are **proof and package-doc honesty** gates. **AUX-01 / AUX-02** are **copy SSOT** for **coupon** and **promotion code** LiveViews — **not** a new visual system. Inherits **Phase 50** posture (**`ax-*`**, **`AccrueAdmin.Copy`**, **no new UI kits**).

---

## Phase scope (surfaces)

| Item | Contract |
|------|-----------|
| In-scope | **`CouponsLive`**, **`CouponLive`**, **`PromotionCodesLive`**, **`PromotionCodeLive`** — operator-visible strings via **`AccrueAdmin.Copy`** + **`lib/accrue_admin/copy/coupon.ex`** / **`promotion_code.ex`** + **`defdelegate`** on **`AccrueAdmin.Copy`** (**52-CONTEXT D-01–D-04**). |
| Doc / proof | **`examples/accrue_host/docs/adoption-proof-matrix.md`**, **`evaluator-walkthrough-script.md`** (only on **D-06** triggers), **`examples/accrue_host/README.md`** contract alignment — no new VERIFY-01 **policy** semantics (**D-08**). |
| Out of scope | **Connect** / **events** copy (**AUX-03..AUX-05** → Phase **53**); **full** VERIFY-01 Playwright + axe matrix for coupon/promo (**AUX-06** → **53**) unless **D-15** minimal exception fires. |

---

## Copy (AUX-01 / AUX-02)

| Rule | Detail |
|------|--------|
| SSOT | New/changed operator literals on touched paths use **`AccrueAdmin.Copy.*`** only — **no** raw HEEx English for migrated strings. |
| Growth | **`coupon_*`** / **`promotion_code_*`** function names; modules **`Copy.Coupon`** / **`Copy.PromotionCode`** (or equivalent) behind **`defdelegate`** — **do not** bulk-append bodies into **`copy.ex`** (**D-01**). |
| Locked | **No** coupon/promo strings through **`Copy.Locked`** (**D-03**). |
| Tests | **`LiveViewTest` / ExUnit`** assert via **`AccrueAdmin.Copy`** (or shared test helpers calling Copy) — **no** duplicated English literals for SSOT-owned strings on touched paths (**D-04**, **D-13**). |

---

## Tokens & layout

Unchanged from **Phase 50**: **`ax-*`** primitives; **no** new theme rows for Phase 52 unless fixing an obvious regression (then **theme-exceptions** row if required by **UX-04**).

---

## VERIFY-01 / Playwright

| Rule | Detail |
|------|--------|
| Default | **No** new broad Playwright coverage in **52** — deferred to **53** (**D-14**). |
| Exception (**D-15**) | If executor **must** touch **`e2e/*.spec.js`**, **`export_copy_strings`**, or **`accrue_host_verify_browser.sh`**, add **at most** one **narrow** smoke; every asserted string from **`e2e/generated/copy_strings.json`** after allowlist extension — **no `networkidle`**, locator-driven readiness (**Phase 50 D-18–D-23**). |

---

## Accessibility

No relaxation of existing **axe** posture on paths **already** covered by VERIFY-01; Phase **52** does **not** expand the mounted-path axe matrix (**53**).

---

## Success (UI-facing)

- Coupon and promotion code screens show **centralized copy** only; grep for operator phrases hits **`AccrueAdmin.Copy`** (or delegated modules).
- **No** hand-duplicated Copy literals in **ExUnit** on touched coupon/promo paths.
