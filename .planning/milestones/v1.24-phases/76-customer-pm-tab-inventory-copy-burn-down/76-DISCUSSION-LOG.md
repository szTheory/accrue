# Phase 76: Customer PM tab — inventory + Copy burn-down - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`76-CONTEXT.md`** — this log preserves alternatives considered.

**Date:** 2026-04-24  
**Phase:** 76 — Customer PM tab — inventory + Copy burn-down  
**Areas discussed:** ADM-13 inventory shape; Copy module layout; ADM-14 LiveView scope; ExUnit vs Playwright vs axe (Phase 77 coherence)  
**Mode:** User requested **all areas** + parallel **research subagents** + single cohesive recommendation set (synthesized here).

---

## 1. ADM-13 — Inventory shape (verification vs guides vs both)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Inventory only in phase **`76-VERIFICATION.md`** | |
| B | Primary inventory in **`accrue_admin/guides/`** | |
| C | Verification holds full table; **guide stub** points only (no duplicate matrix) | ✓ |

**User's choice:** **C (verification-first, guide as pointer-only)** — aligned with GSD verify artifacts, low staleness, Hex-idiomatic separation of volatile enumerations from durable guides.  
**Notes:** Merge-blocking CI remains on **VERIFY / code**, not parsed markdown tables. Research cited Rails/Laravel/Stripe-style split between internal verification and public docs.

---

## 2. Copy API layout (submodule vs flat vs gettext)

| Option | Description | Selected |
|--------|-------------|----------|
| A | **`AccrueAdmin.Copy.CustomerPaymentMethods`** + **`defdelegate`** from **`AccrueAdmin.Copy`** | ✓ |
| B | Flat additions only in **`copy.ex`** | |
| C | Host gettext / overridable Tier B | |

**User's choice:** **A** — matches **`Copy.Invoice`**, **`Copy.Subscription`**, etc.; better merge ownership, naming, and contributor grep than a growing flat file; gettext deferred as out of scope for Tier A.  
**Notes:** Naming discretion **`CustomerPaymentMethods`** vs **`Customer.PaymentMethods`** left to implementer (see CONTEXT).

---

## 3. ADM-14 — File / tab scope in `customer_live.ex`

| Option | Description | Selected |
|--------|-------------|----------|
| A | **Strict:** **`payment_methods`** branch (+ PM-specific chrome only) | ✓ |
| B | Opportunistic: any literal touched in the file | |
| C | Document-only (not sufficient alone for ADM-14) | |

**User's choice:** **A** — matches roadmap phase split and ADM-14 wording; stragglers listed in inventory with **Phase 77** deferral sentence.  
**Notes:** Accepts temporary uneven polish across tabs; improves PR atomicity and VERIFY blast radius.

---

## 4. Tests — Phase 76 vs Phase 77 (Playwright / axe)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Touch-only updates to existing Playwright when broken | ✓ (partial) |
| B | Proactive new Playwright / axe in Phase 76 | |
| C | **ExUnit-first** (`LiveViewTest` / `render_component`); assert via **Copy** SSOT | ✓ |

**User's choice:** **C + touch-only Playwright (A)** — Phase **77** owns new **Playwright + axe** per **ADM-15**; avoids duplicate string sources and CI flake before VERIFY scope lands.  
**Notes:** Reject **B** for coherence with ADM-15; mitigates Jest-style snapshot / triple-string footguns.

---

## Claude's Discretion

- Submodule naming variant (**`Customer.PaymentMethods`**) if multiple customer sub-surfaces appear.
- Guide stub location: **new file** vs **`admin_ui.md`** subsection.

## Deferred Ideas

- Non-PM customer LiveView literals and **gettext** Tier B — captured in **`76-CONTEXT.md`** `<deferred>`.
