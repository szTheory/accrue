# Accrue Strategy

## Active Strategic Track

### PROC-08 — Official dual-provider core

**Status:** Active as of 2026-04-29  
**Why now:** Accrue reached `1.0.0` with no open P0/P1 maintainer-friction rows and an explicit post-1.0 intake gate. Continuing with maintenance-only milestones would likely produce diminishing returns. The next substantial bet is reopening **PROC-08** with written boundaries and a locked second-provider contract.

**North star:** Move Accrue from a credible Stripe-first billing library to a credible production billing platform with **Stripe plus one first-party Stripe-like processor** on the documented billing facade.

**Success condition:** Accrue officially supports the documented billing facade across `Fake`, `Stripe`, and `Braintree` for the capability slice listed in the processor-support matrix, without degrading the Stripe-first first-user path or broadening into a merchant-of-record or finance-system strategy.

## Track Boundaries

- **In scope:** a named first-party capability slice, processor conformance work, capability labeling on processor-touched public APIs, provider selection, explicit non-targets, and the phased delivery needed to reach a real dual-provider core.
- **Still out of scope:** **FIN-03**, merchant-of-record pivots, broad accounting ownership, processor breadth for its own sake, and speculative processor-agnostic abstraction churn.
- **Proof posture:** `Fake` remains the deterministic local and CI proof lane; provider-backed runs are fidelity checks for supported features, not the primary development loop.
- **Public-surface posture:** checkout and billing portal remain **Stripe-first** until another first-party processor proves them honestly.
- **Custom adapter posture:** custom processors remain an extension point through `Accrue.Processor`, but they stay outside first-party support, parity promises, and release guarantees unless they are explicitly listed in the official processor-support matrix.
- **Target-provider posture:** `Braintree` is the locked second-provider target because it fits Accrue's Stripe-shaped facade, preserves a direct-gateway strategy, and has a tractable Elixir package surface.
- **Non-targets:** merchant-of-record providers, `Adyen`, `PayPal direct subscriptions`, and bank-debit specialists such as `GoCardless` remain explicit non-targets for this track.

## Execution Shape

### Phase 1 — `v1.31`

**Theme:** Boundary hardening + thin slice  
**Goal:** Lock the repo around a capability-explicit processor-support contract, harden the processor boundary where Stripe assumptions block expansion, and prove one real `Braintree` path through the **gateway subscription core** slice.

### Phase 2 — follow-on milestone(s)

**Theme:** Official dual-provider core  
**Goal:** Extend the thin slice into a complete first-party adapter story for the supported capability slice, with explicit docs, support labels, and proof lanes.

## Milestone Rollup

| Milestone | Role in track | Status |
|-----------|---------------|--------|
| v1.31 | Reopen PROC-08 with a locked provider, capability matrix, bounded processor contract, and one real vertical slice | Active |

## Decision Notes

- Accrue is **facade-first and capability-explicit**. First-party support means a named capability slice, not generic processor parity.
- `Braintree` is the locked target because it is the closest Stripe-like direct gateway fit for Accrue's current customer, payment-method, subscription, and webhook-shaped surface.
- The first official multi-provider slice is **gateway subscription core**, centered on customer operations, payment-method vault acquisition, direct subscription creation, webhook verify/parse, and webhook-backed lifecycle projection.
- `Accrue.Billing.subscribe/3` is the primary second-provider public-facade candidate. Checkout and billing portal remain **Stripe-first** until proven otherwise.
- Unsupported capabilities must **fail clearly and early** through capability checks instead of implying parity and surprising adopters later.
- Accrue should learn from **Laravel Cashier** by naming provider tracks honestly instead of pretending every billing system fits one identical contract.
- Accrue should learn from **Pay (Rails)** that bounded multi-provider support works when the shared surface stays narrow and the docs admit where provider behavior diverges.
- Accrue should avoid the **ActiveMerchant** trap: too much gateway breadth creates lowest-common-denominator pressure, leaky abstractions, and DX erosion.
- The **Ecto / Active Storage / Active Job** lesson also applies: adapter compatibility is real, but first-party support only exists where the repo enumerates what is guaranteed.
- Strategy defaults are **reopened only for high-impact changes** such as adding a provider, expanding the supported slice, changing release-gate philosophy, or promoting a Stripe-only API into the official multi-provider contract.
