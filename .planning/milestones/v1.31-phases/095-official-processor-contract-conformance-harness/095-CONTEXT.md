# Phase 95: Official processor contract + conformance harness - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the current custom-processor extension point into an official first-party processor contract for the supported slice, without broad abstraction churn.

Phase 95 is the contract-hardening phase between Phase 94 strategy lock and Phase 96 real Braintree thin-slice delivery. It should make the support promise executable, honest, and testable across `Fake`, `Stripe`, and the Braintree-targeted path that Phase 96 will complete.

This phase does **not** need to prove every row in the Phase 94 matrix as fully production-complete for Braintree. It does need to make the official promise narrow enough to be true, capability-gated enough to be safe, and testable enough that Phase 96 can land one real provider-backed `Accrue.Billing.subscribe/3` slice without redefining the contract mid-flight.

</domain>

<decisions>
## Implementation Decisions

### Conformance scope

- **D-01:** Phase 95 should use a **staged conformance contract**, not a “prove the full gateway-subscription-core matrix immediately” strategy.
- **D-02:** The Phase 95 contract should prove the minimum first-party subset required to unblock one honest Braintree-backed `Accrue.Billing.subscribe/3` slice in Phase 96.
- **D-03:** The minimum subset for Phase 95 should center on:
  - `customer.create`
  - `customer.retrieve`
  - `payment_method.vault_acquisition`
  - `subscription.direct_create`
  - `subscription.fetch`
  - `webhook.verify`
  - `webhook.parse`
  - `subscription.lifecycle_webhook_projection`
  - `invoice.lifecycle_webhook_projection`
- **D-04:** `customer.update` and `subscription.cancel` should not be treated as Braintree-proven first-party rows in Phase 95 unless the implementation falls out naturally from the same thin slice with no abstraction churn. Otherwise they remain staged/deferred and capability-gated.
- **D-05:** Phase 95 must make any “not yet proven” row explicit in the contract artifacts rather than leaving the matrix to imply broader Braintree support than the branch actually enforces.

### Unsupported-operation behavior

- **D-06:** Public facade truth is strict: if an operation is outside the official first-party slice for the configured processor, it must fail clearly and early.
- **D-07:** The default unsupported response shape should be `{:error, %Accrue.APIError{code: "processor_operation_unsupported"}}` for non-bang public APIs and raise that same error in bang variants.
- **D-08:** Temporary transitional softness is allowed only behind clearly non-public implementation seams used to bring up Phase 95/96 internals. Internal bridge code must not redefine the public support story.
- **D-09:** Existing raise-first capability gates such as `Accrue.Checkout.Session` are precedent for “fail early”, but Phase 95 should prefer tuple-returning non-bang public ergonomics when introducing new processor-slice guards rather than spreading raise-only behavior further.
- **D-10:** The current `Accrue.Processor.Capabilities` legacy defaults are too optimistic for first-party support hardening. Phase 95 planning should treat “broad default true” as a contract-risk to be reduced or isolated.

### Proof lane shape

- **D-11:** `Fake` remains the merge-blocking, deterministic, day-to-day source of truth for processor conformance.
- **D-12:** Provider-backed Stripe/Braintree coverage should use a **hybrid lane model**:
  - Fake conformance tests run in normal local and CI flows.
  - A thin provider-backed smoke lane runs in protected-branch, nightly, or release-oriented automation.
  - Broader provider fidelity tests stay opt-in or advisory.
- **D-13:** Provider-backed smoke coverage should be intentionally narrow and tied to the official thin slice, not used as a second full contract suite that competes with Fake.
- **D-14:** If a provider-backed smoke mismatch appears, Phase 95/96 should first treat it as a signal to refine the conformance contract, capability map, or Fake mirror, not as a reason to let external-provider nondeterminism redefine the mainline proof model.

### Capability labeling and support SSOT

- **D-15:** Phase 95 should ship **public support labeling and executable capability enforcement together**.
- **D-16:** `.planning/processor-support-matrix.md` remains the **public support SSOT**.
- **D-17:** `Accrue.Processor.Capabilities` and first-party adapter declarations become the **executable mirror** of that public support contract.
- **D-18:** Every processor-touched public facade row must carry one explicit label:
  - `all first-party`
  - `Stripe-only`
  - `out of slice`
  - or a clearly staged/deferred equivalent if Phase 95 needs to distinguish “target contract” from “already proven on this branch”
- **D-19:** No new capability row or public API label should land as docs-only or code-only. The matrix, code mirror, guard behavior, and tests must co-evolve in the same PR.

### Elixir / Phoenix / Ecto posture

- **D-20:** Keep the broad processor behaviour as an internal adapter surface, but keep the official first-party support promise **narrow, explicit, and capability-gated**. This is closer to idiomatic Elixir adapter design than universal-gateway abstraction.
- **D-21:** Public APIs should express support truth at the facade boundary rather than forcing users to infer hidden provider caveats from adapter internals.
- **D-22:** Conformance should be anchored in explicit semantic rows and deterministic ExUnit proof, not in hand-wavy “compatible enough” adapter claims.
- **D-23:** Phase 95 should continue the repo’s existing style of codifying truth in both docs artifacts and executable tests rather than trusting comments or convention alone.

### Ecosystem lessons to apply

- **D-24:** Learn from **Laravel Cashier** and **Pay (Rails)**: keep provider stories honest, support a bounded shared surface, and admit where processor semantics diverge.
- **D-25:** Avoid the **ActiveMerchant** trap: broad gateway sameness invites long-tail feature-matrix drag, leaky abstractions, and worse DX.
- **D-26:** Braintree-specific semantics should shape the Phase 95 contract instead of being abstracted away prematurely. The key Phase 95 assumptions are:
  - recurring subscriptions are plan-based
  - payment-method vault acquisition is a prerequisite seam, not an incidental detail
  - webhook ordering is not guaranteed
  - the first honest subscription path is narrower than Stripe’s broader surface

### Shift-left defaults for future GSD passes

- **D-27:** Future processor-track discuss phases should auto-resolve these defaults unless the phase explicitly widens the support promise:
  - staged contract first, broad parity later
  - public facade hard-fails unsupported processor operations
  - Fake is merge-blocking SSOT
  - provider-backed smoke is narrow and non-PR-blocking by default
  - matrix is public SSOT, code is executable mirror, both ship together
- **D-28:** Reopen these defaults only for materially strategic changes such as:
  - expanding the official first-party capability slice
  - promoting a Stripe-only public API into all-first-party support
  - changing provider-lane gating policy
  - changing the public support labeling model

### the agent's Discretion

- Exact naming of staged-vs-proven contract markers in the matrix and verifier output.
- Whether Phase 95 reduces `@legacy_default` directly or introduces a stricter first-party capability layer above it as an intermediate step.
- Whether provider-backed smoke lives in existing `live-stripe` style test structure, a new processor-contract suite, or both.

</decisions>

<specifics>
## Specific Ideas

- The most coherent Phase 95 posture is:
  - **narrow official contract**
  - **hard public support boundaries**
  - **Fake-first deterministic proof**
  - **one thin real-provider smoke path**
  - **public matrix + code mirror shipped together**
- The support story should read more like “Accrue officially supports a named first-party subset and proves it explicitly” and less like “any processor implementing the broad behaviour is effectively first-party.”
- DX principle: users should never have to guess whether `Braintree` support for a public API is real, partial, or accidental.
- Long-term ergonomics preference:
  - non-bang APIs return `{:error, %Accrue.APIError{}}`
  - bang APIs raise
  - runtime support truth is visible from both docs and tests
- External ecosystem lessons were reviewed during this discussion and are captured in the decisions above, so downstream agents should treat the decisions here as the canonical synthesis instead of re-deriving them.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Strategy and milestone truth

- `.planning/STRATEGY.md` — active PROC-08 strategy, support posture, and track boundaries
- `.planning/ROADMAP.md` — Phase 95 goal and success criteria
- `.planning/REQUIREMENTS.md` — `PROC-10` and `PROC-11`
- `.planning/STATE.md` — active milestone position
- `.planning/PROJECT.md` — project-level product posture and v1.31 framing

### Phase 94 locked context

- `.planning/phases/94-strategy-capability-matrix-target-lock/094-CONTEXT.md` — locked provider, slice, and support-posture decisions
- `.planning/processor-support-matrix.md` — current public processor-support SSOT from Phase 94

### Processor boundary and capability code

- `accrue/lib/accrue/processor.ex` — broad behaviour and runtime dispatch surface
- `accrue/lib/accrue/processor/capabilities.ex` — current capability declaration/merge behavior
- `accrue/lib/accrue/processor/stripe.ex` — first-party Stripe capability declaration
- `accrue/lib/accrue/processor/fake.ex` — Fake proof lane and deterministic adapter surface

### Public facade and current guard precedent

- `accrue/lib/accrue/billing.ex` — public facade entrypoints
- `accrue/lib/accrue/billing/subscription_actions.ex` — `subscribe/3` and subscription lifecycle seam
- `accrue/lib/accrue/checkout/session.ex` — current early capability-gate precedent

### Proof posture and current test shape

- `accrue/test/accrue/processor/capabilities_test.exs` — current capability semantics tests
- `accrue/test/accrue/checkout/session_test.exs` — current checkout-shape test precedent
- `accrue/guides/testing.md` — Fake-first testing posture
- `guides/testing-live-stripe.md` — current provider-backed fidelity posture

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Processor.Capabilities` already gives Phase 95 a natural executable seam for narrowing first-party support, but its legacy-true defaults currently overstate parity.
- `Accrue.Checkout.Session` already demonstrates capability gating at the facade boundary with a clear unsupported-operation error shape.
- `Accrue.Processor.Fake` already provides the right deterministic harness model for merge-blocking conformance tests.

### Established Patterns

- Accrue already treats `Fake` as the practical local/CI proof lane and real providers as separate fidelity surfaces.
- The repo already likes docs-plus-verifier SSOT pairs for public contract work; Phase 95 should reuse that style rather than invent a new truth system.
- The public facade is intentionally wider than the official second-provider slice, so explicit support labeling is required for least surprise.

### Integration Points

- Phase 95 should harden the support contract around `Accrue.Billing.subscribe/3` and adjacent lifecycle seams before Phase 96 adds the real Braintree-backed path.
- The capability map, support matrix, facade guards, and proof lanes should all be planned as one coupled surface rather than separate cleanups.

</code_context>

<deferred>
## Deferred Ideas

- Broad proof of every gateway-subscription-core row in Phase 95 regardless of Phase 96 slice needs
- Full Braintree parity for checkout or billing portal
- Using provider-backed tests as the normal merge-blocking source of truth
- Docs-only support labeling without executable guards
- Broad cleanup of every existing raise-vs-tuple ergonomic inconsistency outside the Phase 95 touched surface

</deferred>

---

*Phase: 95-official-processor-contract-conformance-harness*
*Context gathered: 2026-04-29*
