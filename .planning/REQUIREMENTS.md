# Requirements: Accrue v1.35

**Defined:** 2026-05-06
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.35 Requirements

**Goal:** Close the supportability gap between Accrue's shipped Stripe + Braintree capabilities and the repo's public/operator-facing truth.

### Support Contract

- [x] **SUP-01**: Public package docs, support matrix, and planning mirrors MUST state one provider-honest contract for checkout, billing portal, and the official Stripe + Braintree facade surface.
- [x] **SUP-02**: First-hour and host-facing guidance MUST document the mounted Braintree portal/checkout setup contract, including `portal_base_url`, `portal_mount_path`, auth/CSP expectations, and the sharp failure modes adopters need to diagnose.

### Lifecycle Semantics

- [ ] **LIF-01**: Accrue MUST publish one canonical lifecycle semantics guide that explains cancel, cancel-at-period-end, resume, pause/unpause, lifecycle status labels, and post-action convergence across Stripe, Fake, and Braintree with explicit native/host-owned/unsupported labeling.
- [ ] **LIF-02**: Any Accrue-owned lifecycle copy or UI touched in this milestone MUST prefer least-surprise subscription behavior, clearly distinguish states like `active`, `canceling`, `paused`, `past_due`, and `ended`, and avoid implying Stripe-only semantics on Braintree.

### Webhook & Operator Truth

- [ ] **OPS-01**: Webhook docs, operator runbooks, and telemetry reference material MUST become processor-aware for the shipped Braintree slice, including replay/recovery, drift diagnosis, checkout completion ambiguity, and metered renewal recovery.
- [ ] **OPS-02**: Deterministic proof and verifier coverage MUST prevent support-contract drift and exercise the Braintree recovery/documentation paths that this milestone formalizes.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New processors or broader processor breadth | v1.35 is a consolidation milestone inside the existing Stripe + Braintree boundary |
| Hyperwallet / marketplace reopening | Explicitly rejected in v1.33 unless strategy changes in writing |
| FIN-03 app-owned finance exports | Still outside Accrue's billing-library scope |
| Broad new billing primitives | The current need is supportability closure, not another capability sweep |
| Heavy `accrue_portal` theming or cosmetic redesign | UI work should only support clarity and lifecycle truth, not become a design project |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SUP-01 | Phase 109 | Complete |
| SUP-02 | Phase 109 | Complete |
| LIF-01 | Phase 110 | Pending |
| LIF-02 | Phase 110 | Pending |
| OPS-01 | Phase 111 | Pending |
| OPS-02 | Phase 111 | Pending |

**Coverage:**
- v1.35 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0

---
*Requirements defined: 2026-05-06*
*Last updated: 2026-05-06 after Phase 109 Plan 03 execution*
