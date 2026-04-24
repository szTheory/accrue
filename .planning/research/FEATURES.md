# Feature Research

**Domain:** Accrue v1.25 — friction SSOT + integrator proof + **`Accrue.Billing`** checkout entry  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Hosts / Integrators Expect)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **`Accrue.Billing`** owns subscription + payment-method + portal entry | Single host **`MyApp.Billing`** teaching surface | LOW | **v1.24** added portal; checkout is the natural sibling for “start payment on Stripe.” |
| **Fake-backed** tests for new billing API | CI determinism; library positioning | MEDIUM | Same bar as **BIL-04**. |
| **`:telemetry` / span** on new public **`Billing`** functions | Ops catalog + **`billing_span_coverage_test`** gate | LOW | Extend **`guides/telemetry.md`** + span coverage test expectations. |
| Friction inventory stays honest after ship | **FRG-01** / **v1.21** maintenance posture | LOW | Either **new sourced rows** or **explicit maintainer certification** — not silent drift. |

### Differentiators (Competitive / Trust)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Typed **`Accrue.Checkout.Session`** projection | Fewer foot-guns than raw Stripe maps | Already shipped — **Billing** facade exposes it consistently. |
| **VERIFY-01** + adoption matrix co-move with docs | Evaluator trust | MEDIUM | **INT-12** — same-PR discipline from **`scripts/ci/README.md`**. |

### Anti-Features (Defer / Avoid)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full embedded Checkout UI in **`accrue_admin`** | “Ship UI” | Scope explosion; host owns web UI | Document **`ui_mode: :embedded`** in guides only. |
| **PROC-08** second processor | Multi-gateway | False parity; milestone non-goal | Explicit future milestone. |

## Feature Dependencies

```
INV-03 (friction pass)
    └── informs ──> INT-12 (which doc rows / verifiers need touch)

BIL-06 (Billing checkout API)
    └── requires ──> Accrue.Checkout.Session (existing)
    └── enables ──> BIL-07 + INT-12 (docs + proof alignment)
```

### Dependency Notes

- **BIL-06 before BIL-07:** Catalog and **CHANGELOG** should describe **observed** span names, not speculative ones.  
- **INV-03** can complete in parallel with **BIL-06** at roadmap level, but **79** before **81** reduces thrash on **`verify_v1_17_friction_research_contract.sh`**.

## MVP Definition (this milestone)

### Launch With (v1.25)

- [ ] **INV-03** — Inventory pass with evidence row or certification.  
- [ ] **BIL-06** — **`create_checkout_session`** + **`!`**, Fake tests, span.  
- [ ] **BIL-07** + **INT-12** — Telemetry doc + optional First Hour / matrix / VERIFY alignment when checkout is documented.

### Add After Validation

- [ ] Installer template adds **`create_checkout_session`** delegate on **`MyApp.Billing`** — only if **First Hour** / installer story references it (**stretch** inside **81**).

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| BIL-06 checkout facade | HIGH | MEDIUM | P1 |
| INV-03 friction pass | MEDIUM | LOW | P1 |
| BIL-07 telemetry/docs | HIGH | LOW | P1 |
| INT-12 integrator alignment | HIGH | MEDIUM | P1 |

## Competitor Feature Analysis

| Feature | Pay / Cashier (pattern) | Accrue v1.25 |
|---------|-------------------------|--------------|
| Checkout from “Billable” context | Single entry on user/account model | **`Accrue.Billing`** + **`%Customer{}`** first arg, same as portal. |

## Sources

- **`.planning/milestones/v1.24-REQUIREMENTS.md`**  
- **`accrue/guides/testing.md`** — host **`MyApp.Billing.create_checkout_session`** mention (already suggests host facade naming).  
- **`.planning/research/v1.17-north-star.md`**

---
*Feature research for: Accrue v1.25*  
*Researched: 2026-04-24*
