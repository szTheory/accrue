# Phase 95: Official processor contract + conformance harness - Research

**Researched:** 2026-04-29
**Domain:** Processor contract hardening, conformance testing, and Stripe-assumption isolation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

All items in this block are copied verbatim from `095-CONTEXT.md`. [VERIFIED: 095-CONTEXT.md]

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- Broad proof of every gateway-subscription-core row in Phase 95 regardless of Phase 96 slice needs
- Full Braintree parity for checkout or billing portal
- Using provider-backed tests as the normal merge-blocking source of truth
- Docs-only support labeling without executable guards
- Broad cleanup of every existing raise-vs-tuple ergonomic inconsistency outside the Phase 95 touched surface
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-10 | Accrue defines and proves a first-party processor conformance contract for the supported slice so Stripe, Fake, and the chosen second processor can be validated against the same expectations. [VERIFIED: REQUIREMENTS.md] | This research recommends one executable capability mirror, one deterministic Fake conformance suite, and one thin provider-smoke lane keyed to the staged slice in `095-CONTEXT.md`. [VERIFIED: REQUIREMENTS.md][VERIFIED: 095-CONTEXT.md][VERIFIED: codebase grep][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/] |
| PROC-11 | Slice-blocking Stripe assumptions are removed or isolated from the processor boundary, config, test harness, and public integration seams without broad abstraction churn outside the chosen slice. [VERIFIED: REQUIREMENTS.md] | This research identifies the current optimistic capability defaults, the Stripe-shaped `subscribe/3` request payload, and the raise-first checkout guard pattern as the main surfaces to isolate or narrow. [VERIFIED: REQUIREMENTS.md][VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Phase 95 must stay within the locked runtime floor of Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+, and it should not recommend backward-compatibility work for older platform versions. [VERIFIED: CLAUDE.md]
- Existing required dependencies remain `lattice_stripe`, `oban`, `swoosh`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, and `chromic_pdf`; this phase should harden the processor contract, not introduce a competing universal payment abstraction. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory and non-bypassable, raw-body capture must happen before `Plug.Parsers`, sensitive processor payloads must not be logged verbatim, and stored payment-method detail must remain references rather than PII. [VERIFIED: CLAUDE.md][VERIFIED: accrue/lib/accrue/errors.ex]
- Public entry points are expected to emit `:telemetry`, so new unsupported-operation guards belong at the public facade boundary and must preserve the existing telemetry discipline. [VERIFIED: CLAUDE.md][VERIFIED: codebase grep]
- The monorepo structure is fixed, with repo-level CI and shared guides; processor contract truth should therefore continue to live in repo-level planning/docs artifacts plus `accrue/` tests instead of splitting into a separate package or support silo. [VERIFIED: CLAUDE.md][VERIFIED: .github/workflows/ci.yml]

## Summary

Phase 95 should not widen the processor abstraction. It should make the already-locked Phase 94 support matrix executable for the staged slice, then narrow or isolate the code paths that still imply broader Stripe parity than the official contract allows. The critical repo facts are already visible: `.planning/processor-support-matrix.md` is the public SSOT, `scripts/ci/verify_processor_support_matrix.sh` is the existing drift gate, and `Accrue.Processor.Capabilities` still deep-merges optimistic `true` defaults for checkout, billing portal, customer update, and multiple subscription leaves. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: accrue/lib/accrue/processor/capabilities.ex]

The biggest slice-blocking runtime assumption is in `Accrue.Billing.SubscriptionActions.do_subscribe/3`, which still builds `stripe_params` with Stripe-specific fields like `payment_behavior: "default_incomplete"` and `expand: ["latest_invoice.payment_intent"]` before dispatching to the configured processor. That is acceptable for the current Stripe adapter and Fake mirror, but it is the main contract breach to isolate before a real Braintree-backed Phase 96 path can fit without lying about the API shape. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

The planner should treat Phase 95 as three coupled outcomes shipped together: one stricter executable capability mirror, one deterministic conformance harness for the staged rows, and one facade-level unsupported-operation policy for out-of-slice or not-yet-proven operations. Provider-backed proof should stay thin and advisory, matching the existing `live-stripe` lane posture rather than replacing Fake as merge-blocking truth. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md][VERIFIED: .github/workflows/ci.yml]

**Primary recommendation:** Plan Phase 95 around a staged conformance table keyed to the exact D-03 rows, add tuple-returning facade guards for unsupported processor operations, and refactor `subscribe/3` so processor-generic semantics are prepared at the facade layer while Stripe-only request shaping moves behind the adapter seam. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: accrue/lib/accrue/checkout/session.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public support truth and staged row labels | Repository docs / planning [VERIFIED: .planning/processor-support-matrix.md] | CI / validation [VERIFIED: scripts/ci/verify_processor_support_matrix.sh] | Phase 94 already made the support matrix the public SSOT and wired it into CI, so Phase 95 must extend that truth rather than create a second contract source. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: .github/workflows/ci.yml] |
| Executable capability mirror | API / backend [VERIFIED: accrue/lib/accrue/processor/capabilities.ex] | Repository docs / planning [VERIFIED: .planning/processor-support-matrix.md] | The code mirror belongs at the processor boundary because `Processor.supports?/1` is the runtime gate, but it must match the planning matrix in the same PR. [VERIFIED: accrue/lib/accrue/processor.ex][VERIFIED: 095-CONTEXT.md] |
| Unsupported-operation enforcement on public APIs | API / backend [VERIFIED: accrue/lib/accrue/checkout/session.ex] | Telemetry / validation [VERIFIED: codebase grep] | `Accrue.Checkout.Session` already gates unsupported operations at the facade boundary with `Accrue.APIError`, which is the right ownership model for the new staged contract as well. [VERIFIED: accrue/lib/accrue/checkout/session.ex][VERIFIED: accrue/lib/accrue/errors.ex] |
| Deterministic conformance proof | API / backend tests [VERIFIED: accrue/test/accrue/processor/capabilities_test.exs] | CI / validation [VERIFIED: .github/workflows/ci.yml] | Fake-backed ExUnit remains the merge-blocking truth lane, so the staged contract should be proved in normal `mix test` and PR CI. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/guides/testing.md] |
| Provider-backed smoke for the staged slice | Provider-parity tests [VERIFIED: guides/testing-live-stripe.md] | Protected-branch / scheduled CI [VERIFIED: .github/workflows/ci.yml] | The existing `live-stripe` lane already establishes the advisory provider-smoke pattern that Phase 95 should mirror rather than replace. [VERIFIED: guides/testing-live-stripe.md][VERIFIED: .github/workflows/ci.yml] |
| Vault acquisition semantics for Braintree path | Browser / client [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/] | API / backend [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] | Braintree’s staged slice still depends on a client-side tokenized handoff plus a server-side subscription create against vaulted payment details. [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Accrue.Processor.Capabilities` | current repo module [VERIFIED: accrue/lib/accrue/processor/capabilities.ex] | Executable support contract mirror | It is already the runtime seam behind `Processor.supports?/1`, so Phase 95 should harden it instead of inventing another capability registry. [VERIFIED: accrue/lib/accrue/processor.ex][VERIFIED: accrue/lib/accrue/processor/capabilities.ex] |
| `Accrue.Checkout.Session` guard pattern | current repo module [VERIFIED: accrue/lib/accrue/checkout/session.ex] | Existing unsupported-operation precedent | It already raises `Accrue.APIError` with code `processor_operation_unsupported`, which Phase 95 can reuse as the support-boundary shape while adapting non-bang ergonomics per D-07 and D-09. [VERIFIED: accrue/lib/accrue/checkout/session.ex][VERIFIED: 095-CONTEXT.md] |
| `.planning/processor-support-matrix.md` | current repo artifact [VERIFIED: .planning/processor-support-matrix.md] | Public processor-support SSOT | Phase 94 explicitly established this file as the matrix contract and CI already enforces its presence and key literals. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/verify_processor_support_matrix.sh] |
| `scripts/ci/verify_processor_support_matrix.sh` | current repo script [VERIFIED: scripts/ci/verify_processor_support_matrix.sh] | Matrix drift gate | This is the existing shift-left contract harness for support prose and should stay the outermost docs check while Phase 95 adds deeper runtime conformance tests. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: .github/workflows/ci.yml] |
| ExUnit + Fake-backed processor tests | current repo test stack [VERIFIED: accrue/test/accrue/processor/capabilities_test.exs] | Deterministic conformance proof | The repo’s testing doctrine is already Fake-first and merge-blocking, which matches the locked phase decisions. [VERIFIED: accrue/guides/testing.md][VERIFIED: 095-CONTEXT.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `braintree` | `0.16.0`, published 2025-03-27 [VERIFIED: https://hex.pm/packages/braintree/dependencies] | Candidate Elixir server SDK for the later real adapter path | Use in Phase 96 adapter implementation, not as a prerequisite for Phase 95 contract hardening unless a smoke seam truly needs it. [VERIFIED: https://hex.pm/packages/braintree/dependencies] |
| `test/live_stripe/*` pattern | current repo test lane [VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs] | Provider-smoke template | Reuse this shape for thin provider-backed contract smoke so the staged processor slice stays advisory outside the main PR gate. [VERIFIED: guides/testing-live-stripe.md][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs] |
| Braintree Hosted Fields + Vault docs | current official docs [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/] | Vault acquisition semantics for the future second-provider path | Use when defining the semantic `payment_method.vault_acquisition` row and when deciding what Phase 96 host wiring must prove. [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Tight staged conformance rows in code and tests [VERIFIED: 095-CONTEXT.md] | Keep only the Phase 94 docs matrix and rely on adapter claims | That would leave PROC-10 unproved at runtime and would not catch optimistic capability drift from `@legacy_default`. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/processor/capabilities.ex] |
| Strict first-party capability layer above legacy defaults [VERIFIED: 095-CONTEXT.md] | Edit `@legacy_default` in place immediately | In-place reduction is viable, but an intermediate strict layer reduces blast radius while public support labels and tests are still being aligned. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/processor/capabilities.ex] |
| Thin provider-smoke lane parallel to Fake conformance [VERIFIED: 095-CONTEXT.md] | Make provider-backed tests merge-blocking | That would conflict with the repo’s existing `live-stripe` philosophy and reintroduce network nondeterminism into the main proof lane. [VERIFIED: guides/testing-live-stripe.md][VERIFIED: 095-CONTEXT.md] |

**Installation:**
```bash
# No new dependency is required to complete Phase 95 itself.
# Phase 95 can use the existing repo stack:
cd accrue && mix test

# Candidate later-phase dependency verification:
# https://hex.pm/packages/braintree
```

**Version verification:** The current candidate Elixir Braintree package is `braintree` `0.16.0` on Hex, and the repo’s live-provider pattern already exists under `accrue/test/live_stripe/`. [VERIFIED: https://hex.pm/packages/braintree/dependencies][VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs]

## Architecture Patterns

### System Architecture Diagram

```text
.planning/processor-support-matrix.md
        +
095-CONTEXT.md locked staged rows
        |
        v
Executable capability mirror
- Accrue.Processor.Capabilities
- adapter declarations
        |
        +-----------------------------+
        |                             |
        v                             v
Facade guard layer             Conformance harness
- Billing / Checkout APIs      - Fake deterministic suite
- tuple-returning non-bang     - provider-smoke slice
- bang variants raise          - CI lane split
        |                             |
        +-------------+---------------+
                      |
                      v
Phase 96-ready processor seam
- generic semantic input
- adapter-specific request shaping
- honest out-of-slice failures
```

The key sequencing is: matrix truth first, executable mirror second, facade guards third, provider-smoke last. That order matches the current repo’s docs-contract-first discipline and minimizes abstraction churn. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: .github/workflows/ci.yml]

### Recommended Project Structure

```text
accrue/lib/accrue/
├── processor/
│   ├── capabilities.ex           # strict first-party mirror
│   ├── stripe.ex                 # first-party reference adapter
│   └── fake.ex                   # deterministic conformance mirror
├── billing.ex                    # public facade guard points
├── billing/subscription_actions.ex  # subscribe slice; isolate Stripe params
└── checkout/session.ex           # existing unsupported-operation precedent

accrue/test/accrue/
├── processor/
│   ├── capabilities_test.exs     # existing leaf-override semantics
│   └── contract_test.exs         # new staged conformance suite [ASSUMED]
├── billing/
│   └── processor_support_test.exs  # new facade guard coverage [ASSUMED]
└── docs/
    └── processor_support_matrix_test.exs

accrue/test/live_stripe/
└── processor_contract_live_test.exs # new thin provider-smoke lane [ASSUMED]
```

### Pattern 1: Matrix SSOT + Executable Mirror
**What:** Keep `.planning/processor-support-matrix.md` as the public SSOT, then encode the same staged rows in `Accrue.Processor.Capabilities` and adapter declarations. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
**When to use:** Any processor-touched public API whose support story must stay honest across Fake, Stripe, and the future second provider. [VERIFIED: 095-CONTEXT.md]
**Example:**
```elixir
# Source: accrue/lib/accrue/processor/capabilities.ex
@spec supports?(map(), [atom()]) :: boolean()
def supports?(capabilities, path) when is_map(capabilities) and is_list(path) do
  case get_in(capabilities, path) do
    true -> true
    _ -> false
  end
end
```

### Pattern 2: Tuple-first Public Guard, Bang Variant Raises
**What:** New public support guards should return `{:error, %Accrue.APIError{code: "processor_operation_unsupported"}}` in non-bang APIs and raise in bang variants. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/errors.ex]
**When to use:** Any `Accrue.Billing` or adjacent facade API whose support depends on the staged processor slice. [VERIFIED: 095-CONTEXT.md]
**Example:**
```elixir
# Source: accrue/lib/accrue/checkout/session.ex
unless Processor.supports?([:checkout, :create]) do
  raise Accrue.APIError,
    code: "processor_operation_unsupported",
    message: "#{Processor.name()} does not support checkout creation"
end
```

This existing pattern should be adapted so non-bang APIs return the error tuple instead of always raising first. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/checkout/session.ex]

### Pattern 3: Processor-generic Semantics Above Adapter-specific Request Shaping
**What:** Build semantic subscription intent in the billing layer, then let the adapter translate that intent into provider-native request payloads. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]
**When to use:** `subscribe/3` and any adjacent Phase 95 seam where Stripe-specific request keys currently leak into the generic processor boundary. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
**Example:**
```elixir
# Source: accrue/lib/accrue/billing/subscription_actions.ex
stripe_params =
  %{
    customer: customer.processor_id,
    items: [item_params],
    payment_behavior: "default_incomplete",
    expand: ["latest_invoice.payment_intent"]
  }
```

This is the exact shape Phase 95 should isolate behind the Stripe adapter seam. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]

### Anti-Patterns to Avoid

- **Broad legacy-default truth:** `@legacy_default` currently marks many leaves `true`, which makes undeclared support look real. Phase 95 should not keep treating that map as the first-party contract. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
- **Conformance by docs only:** The matrix script checks prose drift, not runtime behavior, so PROC-10 still needs a dedicated conformance test suite. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs]
- **Provider-backed lane as primary proof:** The repo explicitly positions `live-stripe` as advisory. Phase 95 should not make external-provider tests the normal merge gate. [VERIFIED: guides/testing-live-stripe.md][VERIFIED: .github/workflows/ci.yml]
- **Public API silence on unsupported rows:** Out-of-slice operations must fail early at the facade boundary rather than relying on adapter internals to fail later and less clearly. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/checkout/session.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support truth registry | A second custom support DSL separate from the matrix and capability map | `.planning/processor-support-matrix.md` + `Accrue.Processor.Capabilities` [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: accrue/lib/accrue/processor/capabilities.ex] | The repo already has both the public SSOT and the runtime seam; duplicating them would create drift faster, not less. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: scripts/ci/verify_processor_support_matrix.sh] |
| External-provider proof policy | A brand-new CI philosophy for processor lanes | Existing Fake-first + advisory `live-stripe` model [VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md] | The project already has a stable deterministic/advisory split, and Phase 95 decisions explicitly reaffirm it. [VERIFIED: 095-CONTEXT.md] |
| Braintree card-field handling | Direct PAN storage or custom hosted-card iframe work | Braintree Hosted Fields / tokenized vault acquisition [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/] | Hosted Fields provides the PCI-safe framed-input path that matches the staged `payment_method.vault_acquisition` row. [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/] |
| Webhook signature parsing | A homegrown signature format or bypass path | Provider-native verify/parse path with `Accrue.SignatureError` semantics [VERIFIED: accrue/lib/accrue/errors.ex][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/] | Signature verification is a locked security boundary in this project and official Braintree docs explicitly describe invalid-signature parse failures. [VERIFIED: CLAUDE.md][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/] |

**Key insight:** Phase 95 should hand-roll less abstraction, not more. The honest move is to codify the narrow supported slice and isolate Stripe-only request semantics, not to pretend the full behaviour surface is now universally portable. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/processor.ex]

## Common Pitfalls

### Pitfall 1: Treating `@legacy_default` as the first-party contract
**What goes wrong:** Adapters inherit broad `true` leaves for checkout, billing portal, and multiple subscription operations unless they explicitly override them. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
**Why it happens:** `Capabilities.for/1` deep-merges adapter declarations onto `@legacy_default`, so undeclared rows still read as supported. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
**How to avoid:** Introduce a strict first-party capability map or reduce the defaults before using the map as executable support truth for the staged slice. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
**Warning signs:** Capability tests still assert “known adapters report broad current capabilities,” and new adapters pass support checks for rows they never explicitly implemented. [VERIFIED: accrue/test/accrue/processor/capabilities_test.exs]

### Pitfall 2: Leaving Stripe request keys in the generic subscription seam
**What goes wrong:** A new second-provider adapter must either ignore Stripe-only fields or fake support for them, which distorts the contract before the adapter is real. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
**Why it happens:** `do_subscribe/3` builds `stripe_params` directly in the billing layer with `payment_behavior` and `expand` keys. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
**How to avoid:** Split semantic subscription intent from provider-native payload translation so Stripe-only fields move behind `Accrue.Processor.Stripe`. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
**Warning signs:** New tests for Braintree-targeted conformance need to special-case or ignore request fields that only Stripe understands. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]

### Pitfall 3: Adding docs labels without runtime guard behavior
**What goes wrong:** The matrix says a row is Stripe-only or out of slice, but calling the public API still falls through to adapter code and fails late or inconsistently. [VERIFIED: .planning/processor-support-matrix.md][VERIFIED: accrue/lib/accrue/checkout/session.ex]
**Why it happens:** The current matrix verifier only checks literals, not facade behavior. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh]
**How to avoid:** Ship public labels, capability checks, unsupported error tuples, and guard tests in the same PR. [VERIFIED: 095-CONTEXT.md]
**Warning signs:** A support label changes in `.planning/processor-support-matrix.md` without new or updated ExUnit coverage for the touched public API. [VERIFIED: 095-CONTEXT.md]

### Pitfall 4: Letting provider smoke compete with Fake conformance
**What goes wrong:** CI becomes slower and less deterministic, and provider drift starts driving contract decisions more than the intended staged semantics. [VERIFIED: guides/testing-live-stripe.md][VERIFIED: 095-CONTEXT.md]
**Why it happens:** External-provider tests feel “more real,” so teams over-weight them relative to deterministic adapter mirrors. [VERIFIED: guides/testing-live-stripe.md]
**How to avoid:** Keep the full contract suite Fake-backed and merge-blocking, then add only one or two provider-backed smoke assertions for the staged slice. [VERIFIED: 095-CONTEXT.md][VERIFIED: .github/workflows/ci.yml]
**Warning signs:** A PR needs network credentials to validate ordinary contract changes, or the provider lane starts duplicating the entire conformance suite. [VERIFIED: 095-CONTEXT.md][VERIFIED: guides/testing-live-stripe.md]

## Code Examples

Verified patterns from official sources and the current codebase:

### Capability guard lookup
```elixir
# Source: accrue/lib/accrue/processor.ex
def supports?(path) when is_atom(path), do: supports?([path])

def supports?(path) when is_list(path),
  do: Accrue.Processor.Capabilities.supports?(capabilities(), path)
```
[VERIFIED: accrue/lib/accrue/processor.ex]

### Existing unsupported-operation error shape
```elixir
# Source: accrue/lib/accrue/checkout/session.ex
raise Accrue.APIError,
  code: "processor_operation_unsupported",
  message: "#{Processor.name()} does not support checkout creation"
```
[VERIFIED: accrue/lib/accrue/checkout/session.ex]

### Braintree recurring-billing constraint
```text
# Source: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/
Create a plan, store customers in the Vault, then create a subscription
that associates the customer's payment method with the plan.
```
[CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]

### Braintree hosted vault acquisition constraint
```text
# Source: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/
Hosted Fields renders payment fields in iframes so card input stays on
the gateway side of the boundary.
```
[CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad custom-adapter extension point implied by the full behaviour surface [VERIFIED: accrue/lib/accrue/processor.ex] | Explicit first-party capability slice with Phase 94 matrix SSOT [VERIFIED: .planning/processor-support-matrix.md] | Phase 94, 2026-04-29 [VERIFIED: .planning/STATE.md] | Phase 95 should harden the staged slice rather than broaden the behaviour. [VERIFIED: .planning/STATE.md][VERIFIED: 095-CONTEXT.md] |
| Docs-only processor-support posture before the Phase 94 gate [VERIFIED: .planning/STATE.md] | Docs verifier plus CI gate for processor-support matrix [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: .github/workflows/ci.yml] | Phase 94, 2026-04-29 [VERIFIED: .planning/STATE.md] | Phase 95 starts with a real docs contract harness already in place. [VERIFIED: .planning/STATE.md] |
| Live Stripe as a narrower parity lane | Formal advisory provider lane in `guides/testing-live-stripe.md` and CI schedule [VERIFIED: guides/testing-live-stripe.md][VERIFIED: .github/workflows/ci.yml] | Current repo state by 2026-04-29 [VERIFIED: guides/testing-live-stripe.md] | Phase 95 can mirror this pattern for thin provider smoke. [VERIFIED: 095-CONTEXT.md] |

**Deprecated/outdated:**

- Treating undeclared capability leaves as safe first-party truth is outdated for this track because D-10 explicitly calls the broad legacy defaults a contract risk. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
- Treating checkout and billing portal as implicit multi-processor candidates is outdated for this milestone because the matrix now labels them `Stripe-only`. [VERIFIED: .planning/processor-support-matrix.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `accrue/test/accrue/processor/contract_test.exs` is the best new home for the staged conformance suite. [ASSUMED] | Architecture Patterns / Validation Architecture | Low — planner may choose a different test filename, but the requirement for a dedicated Fake-backed contract suite remains. |
| A2 | `accrue/test/live_stripe/processor_contract_live_test.exs` is the best new home for thin provider smoke. [ASSUMED] | Architecture Patterns / Validation Architecture | Low — planner may reuse another live suite file, but the advisory lane requirement remains. |

## Open Questions

1. **Should Phase 95 reduce `@legacy_default` directly or add a stricter first-party overlay?**
   - What we know: D-10 says the current broad defaults are too optimistic, and `Capabilities.for/1` currently deep-merges onto them. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
   - What's unclear: Whether the lowest-risk change is to shrink the defaults immediately or to preserve legacy behavior behind a strict first-party wrapper used only by public support guards. [VERIFIED: 095-CONTEXT.md]
   - Recommendation: Prefer a strict overlay if it keeps Stripe/Fake internals stable while the public contract is hardened; only mutate `@legacy_default` directly if the touched tests and adapters stay small. [VERIFIED: 095-CONTEXT.md][ASSUMED]

2. **How much of `customer.update` and `subscription.cancel` should Phase 95 mark as staged versus proven?**
   - What we know: D-04 says not to treat those rows as Braintree-proven unless they fall out naturally from the thin slice. [VERIFIED: 095-CONTEXT.md]
   - What's unclear: Whether the branch will naturally gain enough second-provider truth for those rows while hardening `subscribe/3` and webhook projection. [VERIFIED: 095-CONTEXT.md]
   - Recommendation: Keep the matrix explicit with staged/deferred markers and only promote the rows if both executable guards and conformance tests land in the same PR. [VERIFIED: 095-CONTEXT.md]

3. **Should provider smoke reuse `live_stripe` directly or add a processor-contract-specific live suite?**
   - What we know: The repo already has a working advisory provider-lane pattern under `test/live_stripe/`, and D-12 through D-14 want the new lane thin and non-competing. [VERIFIED: guides/testing-live-stripe.md][VERIFIED: 095-CONTEXT.md]
   - What's unclear: Whether phase-local clarity is better served by a new live file or by extending the existing Stripe live modules with processor-contract cases. [VERIFIED: accrue/test/live_stripe/proration_fidelity_live_test.exs]
   - Recommendation: Reuse the existing `live_stripe` lane mechanics and add one focused file or module for contract smoke rather than mixing staged processor semantics into unrelated parity tests. [VERIFIED: guides/testing-live-stripe.md][ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix test`, facade/conformance work | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Mix | test and verification commands | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| PostgreSQL server | DB-backed ExUnit suite | ✓ [VERIFIED: local command] | `pg_isready` accepting on `/tmp:5432` [VERIFIED: local command] | — |
| `psql` client | DB diagnostics | ✓ [VERIFIED: local command] | `14.17` [VERIFIED: local command] | — |
| Node.js | Host/browser-adjacent or provider JS harness work if expanded later | ✓ [VERIFIED: local command] | `v22.14.0` [VERIFIED: local command] | — |
| npm | JS package operations if expanded later | ✓ [VERIFIED: local command] | `11.1.0` [VERIFIED: local command] | — |
| Docker | Local CI replay or service-backed smoke lanes | ✓ [VERIFIED: local command] | `29.4.0` [VERIFIED: local command] | — |
| Braintree credentials / sandbox | Real provider smoke for the second-provider path | ✗ [VERIFIED: codebase grep] | — | Fake conformance only in Phase 95; real Braintree smoke is Phase 96-adjacent. [VERIFIED: 095-CONTEXT.md] |

**Missing dependencies with no fallback:**

- None for Phase 95 planning and Fake-backed implementation work. [VERIFIED: local command]

**Missing dependencies with fallback:**

- Braintree sandbox credentials are not present in the repo and are not needed to plan or implement the Fake-first contract harness; use the deterministic Fake suite and keep provider-smoke advisory. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/guides/testing.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5` [VERIFIED: accrue/mix.exs][VERIFIED: local command] |
| Config file | `accrue/test/test_helper.exs` [VERIFIED: accrue/test/test_helper.exs] |
| Quick run command | `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/checkout/session_test.exs test/accrue/docs/processor_support_matrix_test.exs` [VERIFIED: local command] |
| Full suite command | `cd accrue && mix test --warnings-as-errors` [VERIFIED: .github/workflows/ci.yml][VERIFIED: accrue/guides/testing.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-10 | Staged capability rows are executable across Fake, Stripe, and declared first-party adapters for the supported slice. [VERIFIED: 095-CONTEXT.md] | unit/integration | `cd accrue && mix test test/accrue/processor/contract_test.exs` [ASSUMED] | ❌ Wave 0 |
| PROC-10 | Public matrix and executable mirror stay aligned. [VERIFIED: 095-CONTEXT.md] | docs/unit | `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs` [VERIFIED: local command] | ✅ |
| PROC-10 | Thin provider-backed smoke confirms the staged contract still matches the reference provider lane. [VERIFIED: 095-CONTEXT.md] | provider-smoke | `cd accrue && mix test --only live_stripe test/live_stripe/processor_contract_live_test.exs` [ASSUMED] | ❌ Wave 0 |
| PROC-11 | Unsupported out-of-slice operations return `{:error, %Accrue.APIError{code: "processor_operation_unsupported"}}` and bang variants raise. [VERIFIED: 095-CONTEXT.md] | unit/integration | `cd accrue && mix test test/accrue/billing/processor_support_test.exs` [ASSUMED] | ❌ Wave 0 |
| PROC-11 | `subscribe/3` no longer leaks Stripe-only request semantics through the generic processor boundary. [VERIFIED: REQUIREMENTS.md][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex] | integration | `cd accrue && mix test test/accrue/billing/subscription_test.exs test/accrue/processor/contract_test.exs` [ASSUMED] | Partial |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/checkout/session_test.exs test/accrue/docs/processor_support_matrix_test.exs`
- **Per wave merge:** `cd accrue && mix test test/accrue/processor test/accrue/billing test/accrue/docs`
- **Phase gate:** `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test --warnings-as-errors`

### Wave 0 Gaps

- [ ] `accrue/test/accrue/processor/contract_test.exs` — deterministic staged conformance suite for the D-03 rows. [ASSUMED]
- [ ] `accrue/test/accrue/billing/processor_support_test.exs` — tuple-vs-bang unsupported-operation guard coverage on touched public APIs. [ASSUMED]
- [ ] `accrue/test/live_stripe/processor_contract_live_test.exs` — thin advisory provider-smoke contract lane. [ASSUMED]
- [ ] Potential helper fixture for staged capability expectations shared across Fake and Stripe reference adapters. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: 095-CONTEXT.md] | Host app auth remains outside this phase’s processor-contract scope. [VERIFIED: CLAUDE.md][VERIFIED: 095-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: 095-CONTEXT.md] | No session-layer changes are required for the processor contract itself. [VERIFIED: 095-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: 095-CONTEXT.md] | Public facade support truth must fail early for unsupported operations so callers cannot accidentally cross into unproven processor paths. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/checkout/session.ex] |
| V5 Input Validation | yes [VERIFIED: codebase grep] | Existing `NimbleOptions` validation at public facades should remain in place when adding processor-slice guards. [VERIFIED: accrue/lib/accrue/checkout/session.ex][VERIFIED: accrue/lib/accrue/billing.ex] |
| V6 Cryptography | yes [VERIFIED: CLAUDE.md] | Webhook signature verification remains mandatory and provider-native; invalid signatures must stay hard failures. [VERIFIED: CLAUDE.md][VERIFIED: accrue/lib/accrue/errors.ex][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported operation appears supported because of optimistic capability defaults | Tampering | Reduce or isolate `@legacy_default`, then enforce staged support at the facade boundary with explicit `processor_operation_unsupported` errors. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex][VERIFIED: 095-CONTEXT.md] |
| Raw processor payloads leak through logs or telemetry on new guard paths | Information Disclosure | Reuse existing `Accrue.APIError` sensitivity discipline and avoid attaching raw payloads to telemetry metadata. [VERIFIED: accrue/lib/accrue/errors.ex][VERIFIED: CLAUDE.md] |
| Invalid webhook signatures are parsed as valid lifecycle events | Spoofing | Keep verify/parse as explicit capability rows and preserve hard-failure signature behavior. [VERIFIED: 095-CONTEXT.md][VERIFIED: accrue/lib/accrue/errors.ex][CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/] |
| Provider-smoke secrets or customer data leak into docs/test output | Information Disclosure | Keep provider lanes opt-in/advisory, use environment variables, and preserve the no-PII logging rules already stated in the testing guides. [VERIFIED: guides/testing-live-stripe.md][VERIFIED: accrue/guides/testing.md] |

## Sources

### Primary (HIGH confidence)

- `095-CONTEXT.md` — locked Phase 95 decisions, staged slice, proof-lane model, and unsupported-operation policy. [VERIFIED: 095-CONTEXT.md]
- `.planning/processor-support-matrix.md` — current public processor-support SSOT. [VERIFIED: .planning/processor-support-matrix.md]
- `accrue/lib/accrue/processor/capabilities.ex` — current optimistic legacy defaults and runtime leaf lookup. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex]
- `accrue/lib/accrue/billing/subscription_actions.ex` — current Stripe-shaped `subscribe/3` request preparation. [VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex]
- `accrue/lib/accrue/checkout/session.ex` — existing unsupported-operation guard precedent. [VERIFIED: accrue/lib/accrue/checkout/session.ex]
- `scripts/ci/verify_processor_support_matrix.sh` and `accrue/test/accrue/docs/processor_support_matrix_test.exs` — current docs-level support-contract harness. [VERIFIED: scripts/ci/verify_processor_support_matrix.sh][VERIFIED: accrue/test/accrue/docs/processor_support_matrix_test.exs]
- `.github/workflows/ci.yml` — current merge-blocking vs advisory CI lane split. [VERIFIED: .github/workflows/ci.yml]
- `accrue/guides/testing.md` and `guides/testing-live-stripe.md` — current Fake-first and provider-parity testing doctrine. [VERIFIED: accrue/guides/testing.md][VERIFIED: guides/testing-live-stripe.md]
- Braintree recurring billing overview — plan-based recurring billing plus vault prerequisite. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/overview/]
- Braintree webhooks overview — webhook kinds, parse guidance, and invalid-signature behavior. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/overview/]
- Braintree Hosted Fields overview — iframe-based PCI-safe payment field collection. [CITED: https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/]

### Secondary (MEDIUM confidence)

- Hex package page for `braintree` `0.16.0` — current candidate Elixir SDK existence and release version. [VERIFIED: https://hex.pm/packages/braintree/dependencies]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - The recommended stack is mostly existing repo modules, scripts, and CI lanes already verified in the codebase, with only one supporting Hex package version check. [VERIFIED: codebase grep][VERIFIED: https://hex.pm/packages/braintree/dependencies]
- Architecture: HIGH - The main contract boundaries, current Stripe assumptions, and proof-lane model are explicit in `095-CONTEXT.md`, the current code, and the CI/testing guides. [VERIFIED: 095-CONTEXT.md][VERIFIED: codebase grep]
- Pitfalls: HIGH - The main pitfalls are directly observable in `@legacy_default`, the Stripe-shaped `subscribe/3` payload, and the current docs-only verifier scope. [VERIFIED: accrue/lib/accrue/processor/capabilities.ex][VERIFIED: accrue/lib/accrue/billing/subscription_actions.ex][VERIFIED: scripts/ci/verify_processor_support_matrix.sh]

**Research date:** 2026-04-29
**Valid until:** 2026-05-29
