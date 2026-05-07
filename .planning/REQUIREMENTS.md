# Requirements: v1.37 Subscription Change Management

**Status:** Complete 2026-05-07
**Opened:** 2026-05-07

## Overview

Make Accrue feel complete for the most common post-checkout SaaS billing work
by promoting active subscription-change management into an explicit first-party
contract across the public billing facade, admin/operator surfaces, and
customer self-serve portal.

## Active Requirements

- [x] **SCM-01** — Host code can treat `Accrue.Billing.swap_plan/3` as an official first-party active-subscription-change API with one documented support contract across Fake, Stripe, and bounded Braintree.
- [x] **SCM-02** — Host code and first-party UI surfaces can preview supported subscription changes through `Accrue.Billing.preview_upcoming_invoice/2` before commit, with proration and preview semantics documented as the canonical path.
- [x] **SCM-03** — Stripe and Fake adopters can manage quantity and subscription-item changes through the official billing facade, while unsupported Braintree quantity/item semantics fail clearly and never imply parity.
- [x] **SCM-04** — Admin/operator surfaces expose the supported subscription-change actions, preview states, and setup gates that match the official provider contract.
- [x] **SCM-05** — Customer self-serve portal surfaces expose supported plan-change and preview flows with wording that stays provider-honest and avoids unsupported lifecycle implications.
- [x] **SCM-06** — The processor support matrix, lifecycle/First Hour/production-readiness docs, example-host guidance, and merge-blocking verifiers repeat one coherent subscription-change contract and catch future drift automatically.

## Future Requirements

- **LIF-03** — Broader pause/unpause, resume, and recovery semantics beyond the active-subscription-change bundle.
- **SCH-01** — Official subscription schedule management on the shared first-party support contract.
- **BIL-08** — Cross-provider preview/proration parity beyond the bounded support promised in this milestone.

## Out of Scope

- Linked Hex release-readiness and publish operations.
- Pause/unpause promotion, resume semantics expansion, and scheduled subscription management.
- Hyperwallet or marketplace reopening.
- `FIN-03` app-owned finance exports.
- New billing primitives unrelated to changing an already-active subscription.

## Traceability

| Requirement | Planned Phase | Status |
|-------------|---------------|--------|
| SCM-01 | Phase 117 | complete |
| SCM-02 | Phase 117 | complete |
| SCM-03 | Phase 118 | complete |
| SCM-04 | Phase 118 | complete |
| SCM-05 | Phase 118 | complete |
| SCM-06 | Phase 119 | complete |
