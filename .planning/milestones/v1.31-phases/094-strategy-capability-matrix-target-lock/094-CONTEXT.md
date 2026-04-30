# Phase 94: Strategy + capability matrix + target lock - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the reopened processor-expansion track into explicit repo truth before implementation spreads. Phase 94 must lock:

- the strategic posture for official second-processor support
- a single Stripe-like target provider
- the supported capability slice for the first dual-provider milestone
- the explicit exclusions and non-goals that keep later phases honest

This phase decides **what Accrue officially means by “second processor support”**. It does **not** implement the second adapter, remove all Stripe-shaped assumptions, or promise broad processor parity.

**Out of scope:** merchant-of-record providers, **FIN-03**, accounting/export surfaces, broad processor-agnostic abstraction work, Connect parity, metering parity, coupon/refund parity, embedded checkout parity, and full billing-portal parity across providers.

</domain>

<decisions>
## Implementation Decisions

### Strategic posture

- **D-01:** Accrue adopts **explicit first-party supported slice + custom adapters outside that slice** as the official processor-support posture. The public promise is not “any adapter implementing `Accrue.Processor` is effectively supported”; the public promise is “the documented Accrue billing facade is first-party supported across the named capability slice for `Fake`, `Stripe`, and the chosen second provider.”
- **D-02:** `Fake` remains the **required deterministic proof lane** and merge-blocking default for processor work. Provider-backed runs are fidelity / parity lanes for supported features, not the primary development loop.
- **D-03:** `guides/custom_processors.md` remains an extension-point document, not adoption-front-door guidance. A custom adapter may be compatible with the internal boundary without becoming first-party supported, release-gated, or parity-promised.
- **D-04:** Top-level and strategic docs should avoid “processor-agnostic” wording. Accrue is **facade-first and capability-explicit**, not lowest-common-denominator by marketing claim.

### Target-provider decision

- **D-05:** Lock **Braintree** as the official second-provider target for the Phase 1 dual-provider track.
- **D-06:** Rationale for Braintree:
  - It is the closest plausible **direct gateway** match to Accrue’s current Stripe-first shape: customer records, vaulted payment methods, recurring billing, transactions/refunds, and webhook events.
  - It preserves the principle of least surprise better than Adyen or PayPal direct because Accrue’s current public surface is already Stripe-shaped around customer, subscription, payment method, and webhook-backed state convergence.
  - It offers better maintainer leverage for this repo than enterprise-heavy alternatives because there is a real Elixir package surface and a more tractable gateway mental model than hand-rolling against broader enterprise APIs.
  - It stays inside the already-locked strategy boundary: **Stripe-like gateway**, not merchant-of-record, not finance-system expansion.
- **D-07:** Explicit non-targets for this track:
  - **Merchant-of-record providers** such as Paddle, Lemon Squeezy, and FastSpring. They are the wrong product boundary for Accrue’s locked strategy even if some hosted UX is attractive.
  - **Adyen** for Phase 1. Technically capable, but too enterprise-specific and too far from Accrue’s current facade and ecosystem ergonomics.
  - **PayPal direct subscriptions**. Too wallet-first and approval-flow-specific to serve as the first official “Stripe-like” second provider.
  - **Bank-debit specialists** such as GoCardless. Wrong capability center of gravity for this phase.

### Official capability slice

- **D-08:** The official second-provider slice for this track is **Gateway subscription core**.
- **D-09:** Gateway subscription core means Accrue first-party support is centered on:
  - customer create / retrieve / update
  - payment-method vault acquisition as the provider’s supported hosted or client-tokenized handoff
  - one real subscription acquisition path through the public facade
  - webhook verify / parse
  - webhook-backed convergence of local subscription and invoice truth for the supported lifecycle
  - explicit capability gating for unsupported surfaces
- **D-10:** For the chosen second provider, the first real public-facade story should center on **direct subscription creation and lifecycle truth**, not on Stripe Checkout or Stripe Billing Portal parity.
- **D-11:** The second-provider slice is intentionally **not** “Stripe-near parity” and **not** “hosted billing UX parity everywhere.” Those are different strategic bets and would force abstraction churn before the second provider is even real.
- **D-12:** Phase 94/95/96 should therefore treat the following as **out of slice** for first-party second-provider support:
  - `Accrue.Billing.create_checkout_session/2` parity
  - `Accrue.Billing.create_billing_portal_session/2` parity
  - embedded checkout
  - setup-intent / payment-intent parity
  - payment-method CRUD parity beyond what is minimally needed for the supported gateway subscription path
  - plan swap / quantity mutation / pause / resume / schedules / preview / proration parity
  - refunds, coupons, promotion codes, metering, and Connect

### Public-facade interpretation

- **D-13:** The public facade remains the product boundary, but processor support must be **capability-labeled**. Every processor-touched public API should be treated as one of:
  - supported on all first-party processors
  - Stripe-only
  - out of the official second-provider slice
- **D-14:** For this milestone, `Accrue.Billing.subscribe/3` is the primary candidate public facade for the second-provider thin slice. It already matches the direct-gateway shape more naturally than `create_checkout_session/2` or `create_billing_portal_session/2`.
- **D-15:** `create_checkout_session/2` and `create_billing_portal_session/2` remain valuable public APIs, but they should be documented as **Stripe-first** until another first-party processor proves them honestly.
- **D-16:** Capability rows should describe **semantic behaviors**, not provider jargon. Example: “webhook-backed subscription lifecycle convergence” is the contract; provider event names are implementation details.

### Capability-matrix shape

- **D-17:** The capability matrix should be the first-class truth artifact for processor support. New processor work starts by naming capability rows before implementation work spreads.
- **D-18:** The matrix should evolve beyond the current broad legacy defaults in `Accrue.Processor.Capabilities` and add explicit rows needed for honest multi-provider support, including semantics similar to:
  - `customer.create/retrieve/update`
  - `payment_method.vault_acquisition`
  - `subscription.direct_create`
  - `subscription.fetch`
  - `subscription.cancel`
  - `subscription.lifecycle_webhook_projection`
  - `invoice.lifecycle_webhook_projection`
  - `webhook.verify`
  - `webhook.parse`
  - `checkout.hosted_handoff` only where truly supported
  - `billing_portal.hosted_self_serve` only where truly supported
- **D-19:** Unsupported capabilities must fail **clearly and early** via capability checks, not by implying Stripe parity and surprising integrators later.

### Architecture and DX lessons applied

- **D-20:** Accrue should learn from **Laravel Cashier** by naming provider tracks honestly instead of pretending all billing systems fit one uniform contract.
- **D-21:** Accrue should learn from **Pay (Rails)** that multi-provider support can work if the shared surface stays bounded and the docs warn that complex provider behaviors diverge.
- **D-22:** Accrue should explicitly avoid the **ActiveMerchant** trap: too much gateway breadth creates lowest-common-denominator pressure, leaky abstractions, and DX erosion.
- **D-23:** The Ecto / Active Storage / Active Job lesson applies: adapters are real, but first-party support must enumerate exactly what is guaranteed. Internal adapter compatibility is not the same thing as public support.

### Recommended wording for strategy and docs

- **D-24:** Strategy/docs should use wording in this shape:
  - Accrue officially supports the documented billing facade across `Fake`, `Stripe`, and `Braintree` for the capability slice listed in the processor matrix.
  - `Fake` is the deterministic local and CI proof lane.
  - Provider-backed runs are fidelity checks for supported features, not the primary development loop.
  - Custom processors remain an extension point through `Accrue.Processor`, but they are outside first-party parity and release guarantees unless explicitly listed in the support matrix.

### GSD shift-left defaults

- **D-25:** Shift these defaults left for future billing-facade / processor discuss-plan work:
  - assume first-party support means **named capability slice**, not generic processor parity
  - assume `Fake` remains merge-blocking deterministic SSOT
  - assume provider-backed lanes are fidelity checks, not mainline proof
  - assume new processor work needs a capability-matrix row before API expansion
  - assume every processor-facing public API must be labeled “all first-party,” “Stripe-only,” or “out of slice”
- **D-26:** These defaults should be reopened only for high-impact choices such as adding a provider, expanding the first-party slice, changing release-gate philosophy, or promoting a Stripe-only API into the official multi-provider contract.

### the agent's Discretion

- Exact names for the new capability-matrix leaves introduced in Phase 95.
- Whether the second-provider thin slice in Phase 96 uses an installer-generated host example, the canonical demo host, or both.
- Whether Braintree’s hosted/client-tokenized payment-method acquisition should surface as a new facade helper or stay internal to the host example in the first implementation pass.

</decisions>

<specifics>
## Specific Ideas

- Strategic synthesis:
  - **Braintree** is the best second target because it matches the locked direct-gateway strategy better than MoR providers and bends Accrue’s Stripe-first facade less than Adyen or PayPal direct.
  - The tempting **hosted subscription core** story fits Paddle/Lemon reality better than it fits a direct gateway. Accrue should not let that attractive hosted-UX story pull the repo into the wrong provider class.
  - The coherent path is therefore: **direct gateway target + bounded gateway subscription slice + explicit exclusions for Stripe-only UX surfaces**.
- External lessons worth carrying into planning:
  - **Laravel Cashier** split provider stories instead of forcing fake sameness.
  - **Pay (Rails)** supports multiple processors but warns that complex flows diverge.
  - **ActiveMerchant** shows the downside of over-broad gateway abstraction.
- User preference captured:
  - low-impact processor-support posture, proof-lane, and capability-labeling choices should be auto-resolved by project defaults in future GSD workflow passes
  - only materially strategic choices should be reopened interactively

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Strategic truth

- `.planning/STRATEGY.md` — active PROC-08 track, north star, and non-goals
- `.planning/REQUIREMENTS.md` — PROC-09..13, especially PROC-09 wording
- `.planning/ROADMAP.md` — Phase 94 / 95 / 96 goals and success criteria
- `.planning/PROJECT.md` — v1.31 strategy framing and project-level non-goals
- `.planning/STATE.md` — current milestone and execution position

### Current processor boundary

- `accrue/lib/accrue/processor.ex` — broad Stripe-shaped behaviour and dispatch contract
- `accrue/lib/accrue/processor/capabilities.ex` — current capability helper and legacy-default shape
- `accrue/lib/accrue/processor/stripe.ex` — first-party Stripe capability declaration and adapter conventions
- `accrue/lib/accrue/processor/fake.ex` — deterministic Fake proof lane and scripted-response patterns
- `accrue/guides/custom_processors.md` — extension-point posture to preserve but re-scope honestly

### Public-facade and proof surfaces

- `accrue/lib/accrue/billing.ex` — current public billing facade breadth
- `accrue/lib/accrue/checkout/session.ex` — checkout capability gating precedent
- `accrue/lib/accrue/webhook/default_handler.ex` — webhook-driven convergence boundary
- `accrue/lib/accrue/webhook/plug.ex` — webhook verification / parsing boundary
- `accrue/guides/testing.md` — Fake-first testing posture
- `guides/testing-live-stripe.md` — provider-parity lane posture
- `examples/accrue_host/README.md` — currently documented public facade emphasis
- `examples/accrue_host/docs/adoption-proof-matrix.md` — public proof posture across subscribe / checkout / portal

### Relevant prior phase context

- `.planning/milestones/v1.25-phases/080-checkout-session-on-accrue-billing/080-CONTEXT.md` — recent checkout facade decision style and shift-left precedent
- `.planning/milestones/v1.26-phases/082-first-hour-portal-spine/082-CONTEXT.md` — portal facade integrator emphasis
- `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md` — current project pattern for deep, cohesive discuss defaults

### External ecosystem references that informed these decisions

- Braintree recurring billing and webhooks
- Braintree hosted fields / vault / checkout-with-vault guidance
- Laravel Cashier Stripe + Cashier Paddle docs
- Pay (Rails) processor support and warning language
- ActiveMerchant as the “too broad abstraction” cautionary example

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Processor.Capabilities` already gives Accrue a place to encode a smaller official support slice rather than pretending the full behaviour is always available.
- `Accrue.Checkout.Session` already proves the repo can capability-gate a facade instead of assuming every provider supports the same UI contract.
- `Accrue.Processor.Fake` already provides the right deterministic testing model: scripted failures, stable IDs, controllable time, and webhook synthesis.

### Established Patterns

- The repo is already **webhook-first** for state truth and reconciliation.
- The repo is already **Fake-first** for deterministic CI and local development.
- The repo’s public facade is broader than the honest multi-provider slice; the next phase must therefore add **capability labeling**, not just another adapter.

### Integration Points

- **Phase 95** should translate these decisions into the first-party conformance contract, new capability rows, and the removal or isolation of slice-blocking Stripe assumptions.
- **Phase 96** should prove one real Braintree-backed billing path through the documented public facade, most likely centered on `Accrue.Billing.subscribe/3` plus the minimal payment-method acquisition and webhook-backed lifecycle needed to make that path truthful.

</code_context>

<deferred>
## Deferred Ideas

- Full parity for `create_checkout_session/2` outside Stripe
- Full parity for `create_billing_portal_session/2` outside Stripe
- Processor-agnostic support for advanced subscription mutations, schedules, preview/proration, refunds, coupons, promotion codes, metering, and Connect
- Merchant-of-record provider support
- Any finance / accounting / **FIN-03** expansion
- Community plugin ecosystem posture for processors

</deferred>

---

*Phase: 094-strategy-capability-matrix-target-lock*
*Context gathered: 2026-04-29*
