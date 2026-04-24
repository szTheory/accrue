# Project Research Summary

**Project:** Accrue  
**Domain:** v1.25 — friction SSOT + integrator contracts + **`Accrue.Billing`** checkout facade  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Executive Summary

**v1.25** is a **brownfield** milestone: no new Hex stack. The product move is to expose **Stripe Checkout Session** creation through **`Accrue.Billing`**, mirroring the **v1.24** billing-portal facade (**BIL-04**): **NimbleOptions**-validated attrs, **`Accrue.Telemetry.span/3`** via **`span_billing(:checkout_session, :create, …)`**, and **Fake-backed** ExUnit. **`Accrue.Checkout.Session`** remains the delegate — **do not** bypass it for raw processor calls.

In parallel, **FRG-01** discipline requires a **real maintainer pass** on **`v1.17-FRICTION-INVENTORY.md`** (new sourced rows **or** explicit dated certification). **INT-12** keeps **First Hour**, host README, adoption matrix, and **VERIFY-01** honest when checkout becomes a documented golden-path API — same-PR co-update rules apply.

Top risks: **credential leakage** (checkout **URL** / **`client_secret`**) via logs or span metadata, and **proof drift** if docs change without verifiers. Mitigate with **BIL-04**-style documentation, sanitized **`billing_metadata`**, and phase **81** as the integrator contract gate.

## Key Findings

### Recommended Stack

No additions — see **`STACK.md`**. Continue **Elixir 1.17+**, **`lattice_stripe ~> 1.1`**, **`nimble_options`**, **Fake** processor in tests.

### Expected Features

**Must have (table stakes):**

- **`Accrue.Billing.create_checkout_session/2`** (+ **`!`**) — **Fake** proofs + span.  
- **Friction inventory** maintainer outcome with evidence.  
- **Telemetry catalog** + span coverage alignment for new entry point.

**Should have:**

- **First Hour** / matrix / **VERIFY-01** updates when public narrative mentions the new API (**INT-12**).

**Defer:**

- **PROC-08**, **FIN-03** — explicit non-goals.

### Architecture Approach

Thin **`Billing`** wrapper over **`Accrue.Checkout.Session.create/1`**, preserving **`Inspect`** masking and processor indirection. Span resource **`:checkout_session`**, action **`:create`**, OTel-style name **`accrue.billing.checkout_session.create`**.

### Critical Pitfalls

1. **Credential leakage** — never log **URL** / **`client_secret`**; see **PITFALLS §1**.  
2. **Unspanned public `Billing` function** — breaks **`billing_span_coverage_test.exs`**.  
3. **Integrator doc / verifier drift** — fix with same-PR matrix + script updates.

## Implications for Roadmap

### Phase 79: Friction inventory maintainer pass

**Rationale:** Establishes evidence before doc churn from **81**.  
**Delivers:** **`79-VERIFICATION.md`** + inventory diff or certification.  
**Addresses:** **INV-03**  
**Avoids:** Silent “no work” close (**Pitfall 4**).

### Phase 80: Checkout session on **`Accrue.Billing`**

**Rationale:** Core API + tests + span — independent of doc polish.  
**Delivers:** **BIL-06** implementation + ExUnit.  
**Avoids:** Secret/url leak (**Pitfall 1**).

### Phase 81: Telemetry truth + integrator contracts

**Rationale:** Depends on final span name + whether docs change.  
**Delivers:** **BIL-07**, **INT-12** — **`telemetry.md`**, **`CHANGELOG`**, optional First Hour / matrix / VERIFY.  
**Avoids:** Proof drift (**Pitfall 3**).

### Phase Ordering Rationale

**79 → 80 → 81** minimizes thrash: inventory first; shipping API second; contracts last when text paths are stable.

### Research Flags

- **Phase 81:** Watch **`docs-contracts-shift-left`** — multiple bash verifiers may need coordinated edits.  
- **Phase 80:** Standard pattern — low research risk during **`/gsd-plan-phase`**.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new deps. |
| Features | HIGH | Mirrors shipped **BIL-04**. |
| Architecture | HIGH | **`Checkout.Session`** already models attrs. |
| Pitfalls | HIGH | Known Stripe + telemetry patterns. |

### Gaps to Address During Planning

- Exact **NimbleOptions** schema for **`attrs`** (subset or full parity with **`@create_schema`** minus **`customer`**) — lock in **Phase 80** plan.  
- Whether **installer** / **`mix accrue.install`** should emit **`create_checkout_session`** delegate — decide in **81** if timeboxed.

## Sources

### Primary

- **`.planning/PROJECT.md`**, **`.planning/milestones/v1.24-REQUIREMENTS.md`**  
- **`accrue/lib/accrue/billing.ex`**, **`accrue/lib/accrue/checkout/session.ex`**

### Secondary

- **`.planning/research/v1.17-FRICTION-INVENTORY.md`**, **`v1.17-north-star.md`**

---
*Research completed: 2026-04-24*  
*Ready for roadmap: yes*
