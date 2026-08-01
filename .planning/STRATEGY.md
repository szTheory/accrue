# Accrue Strategy

## Active Strategic Track

### ENT-RAIL-01 — Account-scoped multi-rail and offline entitlement core

**Status:** Active 2026-07-31; v1.58 verified closeout complete
**Why now:** The anonymized B2C Alpha adopter has a concrete web + iOS + offline requirement that the shipped gateway-centric processor abstraction cannot satisfy safely. This is a likely recurring Phoenix-going-mobile shape and clears the stable-core reopen bar.

**North star:** One host account receives coherent access from any verified payment rail, online or offline, while Accrue stays honest about which lifecycle operations it controls and which it only observes.

**Success condition:** Stripe and Apple grants converge into one account snapshot; web and iOS see the same access; an ES256 device-bound lease exposes a 30-day freshness target and a host-owned stale-offline policy that preserves downloaded study and progress while pausing new value expansion; reconnect reconciles automatically; existing single-processor hosts remain additive-compatible.

### PROC-08 — Official dual-provider gateway core

**Status:** Shipped across v1.31–v1.36; retained as a bounded gateway foundation, not the active expansion track.
**Outcome:** Fake, Stripe, and Braintree support the documented Stripe-first capability slice without claiming generic provider parity. The v1.59 rail seam builds beside this processor contract rather than widening it into a lowest-common-denominator lifecycle interface.

## Track Boundaries

- **In scope:** a named first-party capability slice, processor conformance work, capability labeling on processor-touched public APIs, provider selection, explicit non-targets, and the phased delivery needed to reach a real dual-provider core.
- **Still out of scope:** **FIN-03**, merchant-of-record pivots, broad accounting ownership, processor breadth for its own sake, and speculative processor-agnostic abstraction churn.
- **Proof posture:** `Fake` remains the deterministic local and CI proof lane; provider-backed runs are fidelity checks for supported features, not the primary development loop.
- **Public-surface posture:** checkout and billing portal are part of the first-party surface, with provider-honest implementations: Stripe keeps upstream hosted pages, Braintree uses mounted local UI.
- **Custom adapter posture:** custom processors remain an extension point through `Accrue.Processor`, but they stay outside first-party support, parity promises, and release guarantees unless they are explicitly listed in the official processor-support matrix.
- **Target-provider posture:** `Braintree` is the locked second-provider target because it fits Accrue's Stripe-shaped facade, preserves a direct-gateway strategy, and has a tractable Elixir package surface.
- **Non-targets:** merchant-of-record providers, `Adyen`, `PayPal direct subscriptions`, and bank-debit specialists such as `GoCardless` remain explicit non-targets for this track.
- **Rail seam:** the existing processor-support matrix remains the gateway-control truth. A separate rail/entitlement-source matrix owns observation, restore, reconciliation, management, and offline capability truth.
- **Host boundary:** host apps continue to own routes, auth, runtime config, client storage, and app-domain membership policy.
- **Offline policy:** Accrue owns protocol/signing/server reconciliation; Crosswake/host code owns secure storage and client verification.
- **v1 rail scope:** Stripe + Apple only. Google Play is trigger-bound in SEED-007.

## Execution Shape

### Completed foundation — `v1.31` through `v1.36`

**Theme:** Boundary hardening + thin slice  
**Goal:** Lock the repo around a capability-explicit processor-support contract, harden the processor boundary where Stripe assumptions block expansion, and prove one real `Braintree` path through the **gateway subscription core** slice.

### Active expansion — `v1.59`

**Theme:** Account-scoped rail observation + offline access
**Goal:** Deliver Phases 215–220: durable research/contracts, additive foundation, canonical projection, Apple observer, offline lease, and B2C Alpha proof.

## Milestone Rollup

| Milestone | Role in track | Status |
|-----------|---------------|--------|
| v1.31–v1.36 | Bounded Fake/Stripe/Braintree gateway core and support matrix | Shipped |
| v1.58 | lattice_stripe 2.x + Stripe advisory entitlements | Shipped and archived 2026-07-31 |
| v1.59 | Account-scoped Stripe/Apple entitlement union + offline study proof | Active 2026-07-31 |

## Decision Notes

- Accrue is **facade-first and capability-explicit**. First-party support means a named capability slice, not generic processor parity.
- `Braintree` is the locked target because it is the closest Stripe-like direct gateway fit for Accrue's current customer, payment-method, subscription, and webhook-shaped surface.
- The first official multi-provider slice is **gateway subscription core**, centered on customer operations, payment-method vault acquisition, direct subscription creation, webhook verify/parse, and webhook-backed lifecycle projection.
- `Accrue.Billing.subscribe/3` remains the primary second-provider public-facade candidate, and the shipped support contract now also includes provider-honest checkout and billing-portal session APIs.
- Braintree marketplace support via Hyperwallet stays outside the active direct-gateway track. Braintree pay-ins and Hyperwallet payouts are separate truths, marketplace parity is strategically out of bounds unless the project boundary changes, and reopening requires an explicit strategy change plus a new milestone.
- Unsupported capabilities must **fail clearly and early** through capability checks instead of implying parity and surprising adopters later.
- Accrue should learn from **Laravel Cashier** by naming provider tracks honestly instead of pretending every billing system fits one identical contract.
- Accrue should learn from **Pay (Rails)** that bounded multi-provider support works when the shared surface stays narrow and the docs admit where provider behavior diverges.
- Accrue should avoid the **ActiveMerchant** trap: too much gateway breadth creates lowest-common-denominator pressure, leaky abstractions, and DX erosion.
- The **Ecto / Active Storage / Active Job** lesson also applies: adapter compatibility is real, but first-party support only exists where the repo enumerates what is guaranteed.
- Strategy defaults are **reopened only for high-impact changes** such as adding a provider, expanding the supported slice, or changing release-gate philosophy.
- Access aggregation is rail-neutral; lifecycle mutation is resource/rail-aware. This intentional leak is safer than forcing Apple into Stripe-shaped control semantics.
- The Stripe-only `EntitlementSummary` remains observational diagnostics and is never promoted into canonical grant truth.
- The v1.59 canonical projection uses rail/environment-qualified evidence and an account revision; no email-based Apple linking is permitted.
- Offline v1 separates proof freshness from product continuity: a 30-day revalidation target is refreshed opportunistically; stale-offline proof may preserve already-downloaded study and learner progress under host policy while new premium downloads and other value-expanding actions wait for reconnect. A verified deny tombstone supersedes stale positive proof on reconnect.
- Google Play, Family Sharing policy, offer authoring, cross-rail migration/proration, and configurable risk matrices are later work, not v1.59 scope.
