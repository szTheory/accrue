# Phase 95: Official processor contract + conformance harness - Research

**Researched:** 2026-04-29
**Domain:** First-party processor contract hardening, capability enforcement, and conformance proof lanes
**Confidence:** HIGH

<user_constraints>
## User Constraints (from 095-CONTEXT.md)

### Locked Decisions

- **D-01/D-02:** Phase 95 uses a staged conformance contract, not immediate broad parity, and proves only the minimum subset needed to unblock one honest Braintree-backed `Accrue.Billing.subscribe/3` slice in Phase 96.
- **D-03:** The minimum subset centers on `customer.create`, `customer.retrieve`, `payment_method.vault_acquisition`, `subscription.direct_create`, `subscription.fetch`, `webhook.verify`, `webhook.parse`, `subscription.lifecycle_webhook_projection`, and `invoice.lifecycle_webhook_projection`.
- **D-04/D-05:** `customer.update` and `subscription.cancel` can stay staged/deferred unless they fall out naturally, and any not-yet-proven row must be explicit in contract artifacts.
- **D-06/D-09:** Public support truth must fail early, but new facade guards should prefer tuple-returning non-bang APIs and `!`-raising variants instead of spreading raise-only behavior.
- **D-10:** The current `Accrue.Processor.Capabilities` legacy defaults are too optimistic and are a direct contract risk for this phase.
- **D-11/D-14:** Fake remains the merge-blocking deterministic SSOT; provider-backed lanes are thin smoke checks that refine the contract rather than replace the mainline proof model.
- **D-15/D-19:** Public support labeling, executable capability enforcement, matrix truth, guard behavior, and tests must ship together in the same change.
- **D-20/D-26:** Keep the broad processor behaviour as an internal adapter seam, but make the official first-party promise narrow, explicit, capability-gated, and shaped by Braintree semantics rather than premature abstraction.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-10 | Define and prove a first-party processor conformance contract for the supported slice. | The repo already has the matrix SSOT, capability map seam, deterministic Fake adapter, and verifier/test culture needed to turn the supported slice into an executable contract. |
| PROC-11 | Remove or isolate slice-blocking Stripe assumptions from processor boundary, config, test harness, and public seams without broad abstraction churn. | The clearest slice-blocking assumptions live in broad capability defaults, Stripe-shaped subscribe params built in `SubscriptionActions`, and unguarded public APIs that still imply wider support than the matrix allows. |

</phase_requirements>

## Project Constraints

- `Fake` remains the deterministic local and CI proof lane; provider-backed runs stay advisory or protected-branch smoke checks, not merge-blocking local defaults. [VERIFIED: `accrue/guides/testing.md`, `guides/testing-live-stripe.md`]
- The public product seam is `Accrue.Billing`, so support truth needs to become visible at the facade boundary rather than remain implicit inside adapter internals. [VERIFIED: `accrue/lib/accrue/billing.ex`]
- Existing unsupported-operation precedent already uses `Accrue.APIError` with code `processor_operation_unsupported`, but current checkout semantics are raise-first and should remain a precedent rather than the new default for non-bang billing APIs. [VERIFIED: `accrue/lib/accrue/checkout/session.ex`]
- The repo already codifies support truth through paired docs artifacts, bash verifiers, and ExUnit shell-outs. Phase 95 should reuse that exact posture instead of inventing a new proof shape. [VERIFIED: `.planning/processor-support-matrix.md`, `scripts/ci/verify_processor_support_matrix.sh`, `accrue/test/accrue/docs/processor_support_matrix_test.exs`]

## Summary

Phase 95 does not need a universal multi-processor architecture. It needs a narrow executable contract that makes the existing support promise honest. The support SSOT from Phase 94 is already in place; the gap is that runtime capability truth, public facade behavior, and proof lanes still lag behind that matrix.

Three repo realities drive the plan:

1. `Accrue.Processor.Capabilities` still deep-merges broad legacy defaults, so new adapters inherit optimistic support unless they explicitly opt out. That is the main contract-risk seam. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex`]
2. `Accrue.Billing.SubscriptionActions.subscribe/3` still constructs Stripe-shaped subscription params directly in the billing layer. That is acceptable only if Phase 95 isolates the public contract around the supported slice and makes unsupported processor paths fail clearly instead of implying parity. [VERIFIED: `accrue/lib/accrue/billing/subscription_actions.ex`]
3. The repo already separates deterministic proof from provider fidelity: Fake is the merge-blocking lane; Stripe test mode is advisory. Phase 95 should extend that posture into a processor-conformance harness instead of replacing it. [VERIFIED: `accrue/guides/testing.md`, `guides/testing-live-stripe.md`]

**Primary recommendation:** split Phase 95 into three coupled workstreams:

- establish a stricter executable first-party capability mirror that matches the matrix rather than legacy broad defaults;
- harden `Accrue.Billing` and adjacent seams so public APIs return `{:error, %Accrue.APIError{code: "processor_operation_unsupported"}}` when the configured processor is outside the official slice;
- add a conformance harness that proves the staged slice deterministically against Fake, keeps Stripe non-regression in focused tests, and introduces a thin provider-smoke shape that Phase 96 can reuse for Braintree-backed proof.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Support labels and staged/proven contract wording | Repository docs / planning | API / backend | The matrix remains the public SSOT, but labels must be mirrored into executable checks and facade behavior. |
| First-party capability mirror | API / backend | Test / validation | `Accrue.Processor.Capabilities` is the natural executable seam, but it needs tests and likely a stricter layer than legacy defaults. |
| Unsupported-operation behavior | API / backend | Docs | Users experience support truth through `Accrue.Billing`, not through the raw adapter behaviour. |
| Deterministic conformance lane | Test / validation | API / backend | Fake already gives deterministic proof and should become the conformance harness source of truth. |
| Provider-backed smoke lane | CI / validation | Docs | The lane exists to prove real-provider shape drift, not to redefine the support contract. |

## Standard Stack

### Core

| Library / Artifact | Purpose | Why Standard Here |
|--------------------|---------|-------------------|
| `.planning/processor-support-matrix.md` | Public support SSOT | Phase 94 already made this the canonical truth. |
| `Accrue.Processor.Capabilities` | Executable support mirror | It already resolves adapter capability maps and is the least-disruptive place to tighten contract truth. |
| `Accrue.Billing` and `SubscriptionActions` | Public processor-facing seam | This is where unsupported operations become user-visible and where Stripe-shaped assumptions currently leak through. |
| `Accrue.Checkout.Session` | Existing early-failure precedent | It already raises `processor_operation_unsupported` and provides the literal error contract to mirror for non-bang APIs. |
| `Accrue.Processor.Fake` | Deterministic proof lane | It is already the merge-blocking adapter and should anchor the conformance suite. |

### Supporting

| Artifact | Purpose | When to Use |
|----------|---------|-------------|
| `scripts/ci/verify_processor_support_matrix.sh` | Docs contract verification | Use whenever support labels or capability rows change so code truth and matrix truth stay coupled. |
| `accrue/test/accrue/processor/capabilities_test.exs` | Capability merge semantics precedent | Extend it when changing defaults, staged/proven rows, or adapter capability declarations. |
| `accrue/test/accrue/checkout/session_test.exs` | Unsupported-operation test precedent | Reuse its style when asserting support guards and APIError shapes. |
| `guides/testing-live-stripe.md` | Provider-backed lane posture | Reuse its advisory-lane wording for thin provider smoke without turning it into a blocking contract. |

## Key Code Observations

### Observation 1: Legacy capability defaults are too broad

`Accrue.Processor.Capabilities.for/1` deep-merges adapter declarations onto `@legacy_default`, where checkout, billing portal, customer update, and broad subscription operations all default to `true`. That means the runtime support mirror still overstates parity even after Phase 94 narrowed the public support contract. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex`]

**Planning implication:** Phase 95 should either reduce `@legacy_default` directly or introduce a stricter first-party contract layer above it. The plan should not leave broad-default truth in place while only patching docs.

### Observation 2: Public APIs do not yet expose bounded support truth consistently

Checkout already fails early with `processor_operation_unsupported`, but the broader `Accrue.Billing` surface still assumes the configured adapter can satisfy wide Stripe-shaped operations. `list_payment_methods/2`, `subscribe/3`, and neighboring facade functions currently route directly into implementation seams without a first-party slice gate. [VERIFIED: `accrue/lib/accrue/checkout/session.ex`, `accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/billing/payment_method_actions.ex`, `accrue/lib/accrue/billing/subscription_actions.ex`]

**Planning implication:** add a reusable guard layer near `Accrue.Billing` and preserve bang/non-bang ergonomics: non-bang returns `{:error, %Accrue.APIError{...}}`, bang raises.

### Observation 3: `subscribe/3` is the main Stripe-shaped slice blocker

`SubscriptionActions.do_subscribe/3` assembles Stripe-flavored params such as `payment_behavior`, `expand`, and coupon/default-PM helpers directly before calling the configured adapter. [VERIFIED: `accrue/lib/accrue/billing/subscription_actions.ex`]

**Planning implication:** the phase should isolate the supported thin slice first, then only factor out the minimum abstraction needed to make that slice honest. Broad processor-agnostic rewrites would violate Phase 95's scope boundary.

### Observation 4: The repo already has the right proof-lane philosophy

The testing guides clearly separate Fake-backed correctness from live Stripe fidelity. That is exactly the lane shape the context wants for Phase 95/96. [VERIFIED: `accrue/guides/testing.md`, `guides/testing-live-stripe.md`]

**Planning implication:** conformance tests should be Fake-first and merge-blocking; provider-backed smoke should be narrow, explicitly advisory or protected-branch only, and scoped to the official thin slice.

## Recommended Project Structure

```text
accrue/lib/accrue/
├── processor/capabilities.ex            # stricter first-party mirror or staged contract layer
├── processor.ex                         # helper accessors for support labels / capability checks
├── billing.ex                           # public guard layer for first-party slice truth
├── billing/subscription_actions.ex      # minimal isolation of Stripe-shaped subscribe assumptions
└── billing/payment_method_actions.ex    # out-of-slice / vault-acquisition boundary

accrue/test/accrue/
├── processor/capabilities_test.exs      # capability and staged-support tests
├── checkout/session_test.exs            # unsupported-operation precedent
├── billing/                             # facade guard and subscription conformance tests
└── webhook/                             # lifecycle projection contract tests where needed

.planning/
├── processor-support-matrix.md          # staged/proven labels stay aligned with runtime contract
└── phases/95-.../095-*.md               # planning, validation, and proof artifacts
```

## Architecture Patterns

### Pattern 1: Matrix SSOT plus executable mirror

**What:** one public matrix declares support truth, and one code seam mirrors that truth in executable capability data.

**Use here:** keep `.planning/processor-support-matrix.md` as the public contract and make `Accrue.Processor.Capabilities` or a sibling layer the runtime mirror.

### Pattern 2: Facade guard with non-bang / bang symmetry

**What:** guard the public non-bang API with `{:error, %Accrue.APIError{code: "processor_operation_unsupported"}}` and let bang variants raise that same error.

**Use here:** extend the checkout precedent into the Phase 95 billing slice without spreading raise-only behavior.

### Pattern 3: Deterministic conformance plus advisory provider smoke

**What:** merge-blocking Fake conformance proves semantics; provider-backed smoke only checks the narrow real-provider path and contract drift.

**Use here:** add a thin provider-smoke harness that Phase 96 can plug Braintree into, while Phase 95 keeps the deterministic contract credible on every PR.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Broad legacy defaults remain authoritative | Docs and runtime support truth drift immediately | Make capability hardening a first-wave plan, not a cleanup note. |
| Public APIs still imply unsupported parity | Integrators hit surprising runtime failures or hidden Stripe-only paths | Add explicit facade guards and matrix-linked tests in the same PR. |
| Conformance harness tries to prove too much | Phase scope expands into broad parity work | Limit the contract to the staged thin slice from D-03 and mark other rows explicitly deferred/staged. |
| Provider smoke becomes merge-blocking | Nondeterministic external failures redefine the proof model | Keep provider smoke advisory/protected-branch only and document the lane contract. |

## Validation Architecture

The validation stack should mirror the existing repo pattern:

- **Quick path:** focused ExUnit files covering capability semantics, facade unsupported-operation behavior, and the new conformance helpers.
- **Full path:** all focused phase test files plus docs verifiers so matrix/support labels and executable behavior are sampled together.
- **Wave 0 requirement:** if Phase 95 introduces shared conformance helpers or a provider-smoke tag, create those scaffolds before implementation tasks depend on them.

Recommended test families:

- `accrue/test/accrue/processor/capabilities_test.exs`
- new facade guard tests near `billing.ex` / `subscription_actions.ex`
- lifecycle projection tests that prove the staged supported rows
- docs verifiers (`verify_package_docs.sh`, `verify_processor_support_matrix.sh`) whenever labels or matrix rows change

## Plan Shape Recommendation

Use three plans:

1. **Capability mirror and support labeling** — make runtime support truth match the matrix and add staged/proven labeling where needed.
2. **Public facade hardening** — add explicit unsupported-operation behavior and isolate only the slice-blocking Stripe assumptions needed for `subscribe/3` and adjacent supported rows.
3. **Conformance harness and lane docs** — prove the staged slice in Fake-first tests, add thin provider-smoke structure, and update matrix/testing docs together.

## Open Questions Resolved for Planning

- **Should Phase 95 prove the whole matrix?** No. Only the staged minimum subset needed for Phase 96.
- **Should provider-backed smoke become merge-blocking?** No. Keep it thin and advisory/protected-branch only.
- **Should broad processor behaviour be replaced?** No. Keep it internal and narrow the official first-party promise instead.
- **Should unsupported billing APIs raise or return tuples?** Non-bang should return `{:error, %Accrue.APIError{...}}`; bang variants raise.
