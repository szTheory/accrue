# Phase 52: Integrator proof + package alignment + auxiliary copy (part 1) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`52-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 52 — Integrator proof + package alignment + auxiliary copy (part 1)  
**Areas discussed:** Copy SSOT shape (AUX-01/02), INT-04 proof alignment, INT-05 Hex/`verify_package_docs`, Verification split 52 vs 53  
**Mode:** User requested **all areas** + parallel **subagent research** + one-shot synthesis (no interactive per-question turns).

---

## 1 — Copy SSOT shape (coupons / promotion codes)

| Option | Description | Selected |
|--------|-------------|----------|
| **A** | New **`AccrueAdmin.Copy.Coupon`** + **`AccrueAdmin.Copy.PromotionCode`** behind **`defdelegate`** on **`AccrueAdmin.Copy`** | ✓ |
| **B** | Single combined module (e.g. `Copy.Promotions`) |  |
| **C** | Flat `def` bodies only in `copy.ex` |  |

**User's choice:** **A** (research + alignment with **Phase 50 D-07** / existing **`Copy.Subscription`** pattern).  
**Notes:** Subagent memo — lowest merge conflict vs `copy.ex` hotspot; preserves **Stripe-shaped** separation (coupon ≠ promotion code); grep-friendly **`coupon_*`** / **`promotion_code_*`**; avoids **`Locked`** dilution.

---

## 2 — INT-04 adoption matrix & walkthrough

| Option | Description | Selected |
|--------|-------------|----------|
| **Matrix-only** | Update matrix; walkthrough optional |  |
| **Mandatory paired** | Any matrix edit rewrites walkthrough |  |
| **Hybrid (triggered)** | Walkthrough only when commands / CI claims / blocking semantics / artifacts change | ✓ |

**User's choice:** **Hybrid** + **semantic “touched lanes”** + **layered SSOT** (README = executable commands; matrix = semantic map; walkthrough = narrative on **D-06** triggers).  
**Notes:** Preserves **Phase 51** Layer A/B/C honesty; avoids four-file command duplication footgun.

---

## 3 — INT-05 `@version` / `verify_package_docs`

| Option | Description | Selected |
|--------|-------------|----------|
| **Literal `0.3.0` everywhere** | Marketing-simple; fights `@version` bumps |  |
| **“See mix.exs” only** | Low drift; poor copy-paste DX for Hex consumers |  |
| **CI-generated markdown everywhere** | Powerful; heavy tooling |  |
| **Extend existing bash parse + gates** | `@version` SSOT; CI lists stale fences; optional **main vs Hex** banner | ✓ |

**User's choice:** **Extend `verify_package_docs.sh`** pattern across all install-adjacent surfaces touched in Phase 52; **Oban-style** README clarity for **main vs Hex**.  
**Notes:** Matches existing Release Please workflow; **Ecto-style** concrete fences remain in files but are **machine-checked** against `mix.exs`.

---

## 4 — Verification depth (Phase 52 vs 53)

| Option | Description | Selected |
|--------|-------------|----------|
| **A — ExUnit / LiveViewTest-first** | Copy routing + no literal drift in Elixir tests | ✓ (floor) |
| **B — Minimal Playwright** | Only if VERIFY / export pipeline files already edited | ✓ (conditional) |
| **C — Full axe + browser matrix in 52** | Duplicate **AUX-06** |  |

**User's choice:** **A** as **primary**; **B** only under **D-15** exception; **C** explicitly **rejected** (deferred to **Phase 53 AUX-06**).  
**Notes:** Subagent — **Pay/Cashier**-style OSS emphasizes **money-path integration** + **small E2E** set, not Dashboard-wide UI matrices.

---

## Claude's discretion

- Exact **`coupon_*`** / **`promotion_code_*`** function naming (within prefix rules).  
- Whether **any** Playwright file is touched in Phase 52 (**D-15**).

## Deferred ideas

- **AUX-03..AUX-06** auxiliary VERIFY breadth → **Phase 53** (see **`52-CONTEXT.md`** `<deferred>`).
