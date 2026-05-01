# Phase 97: Advanced Subscription Lifecycle - Research

**Researched:** 2026-04-30  
**Domain:** Braintree-backed subscription mutation, lifecycle convergence, and proof coverage  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints

No Phase 97 `CONTEXT.md` exists for this run, so planning must stay inside the already-locked processor-track boundaries from Phases 94-96 instead of inventing new product scope.

### Locked carry-forward constraints

- Keep `Accrue.Billing` as the public product boundary; do not add a Braintree-only alternate mutation API.
- Keep `Fake` as the merge-blocking proof lane and treat real-provider Braintree runs as focused fidelity evidence.
- Keep support truth matrix-led and docs-mirrored; do not imply generic “full Braintree parity”.
- Keep host-owned browser/payment-method acquisition outside core Accrue.
- Prefer explicit capability checks and typed `Accrue.APIError` failures over silent best-effort behavior.

### New planning constraint surfaced by research

- `swap_plan/3`, `update_quantity/3`, `pause/2`, `unpause/2`, and `resume/2` already exist on the public facade, but `Accrue.Processor.Braintree` still returns unsupported errors for every mutation callback beyond direct create/fetch. Phase 97 must close that gap without widening the facade.
- Braintree recurring billing documentation supports subscription update/cancel flows and webhook notifications for lifecycle changes, but it does not expose Stripe-style semantics one-for-one. The phase must implement honest Braintree mappings rather than pretending the providers are identical.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-14 | Implement subscription upgrades, downgrades, quantity changes, and pause/resume logic for Braintree adapters. | The repo already has facade-level lifecycle APIs and local subscription projection/update seams; the missing work is adapter capability, parameter mapping, semantic guards, and proof coverage. |
| PROC-15 | Implement Braintree webhook event parsing to converge subscription mutation changes locally. | Phase 96 already added processor-aware Braintree webhook ingress; Phase 97 needs broader lifecycle normalization, canonical refetch, and projection coverage for mutation-driven state changes. |

</phase_requirements>

## Summary

Phase 97 should be planned as a narrow continuation of Phase 96, not as a new abstraction pass. The public lifecycle APIs already exist, local subscription rows already persist provider projections, and Braintree webhook ingress already exists. The missing work is specific: teach the Braintree adapter and projection layer how to express mutation semantics honestly, then prove those semantics through webhook-backed convergence and focused host/provider evidence.

Three repo facts shape the plan:

1. `Accrue.Billing.SubscriptionActions` is already Stripe-shaped for `swap_plan/3`, `update_quantity/3`, `pause/2`, `unpause/2`, and `resume/2`, so the work should isolate Braintree branching to the request/projection seams instead of touching the public API.
2. `Accrue.Processor.Braintree` currently advertises only `direct_create`, `fetch`, and webhook projection support. Phase 97 must add executable capability truth for mutation paths together with the actual callbacks and tests.
3. Braintree webhook handling already enters through a processor-aware path and normalizes a small set of lifecycle events. Phase 97 needs to expand the normalization/projection story so local `Subscription` rows converge after plan swaps, quantity changes, and status changes.

**Primary recommendation:** split Phase 97 into three plans:

- adapter and facade mutation semantics;
- webhook-driven convergence and projection hardening;
- proof/docs closeout with one focused Braintree provider-backed evidence lane.

## Key Code Observations

### Observation 1: The public mutation surface already exists

`Accrue.Billing` exposes `swap_plan/3`, `update_quantity/3`, `pause/2`, `unpause/2`, and `resume/2`, all backed by `Accrue.Billing.SubscriptionActions`. This phase should not add new public entrypoints unless the existing contract is genuinely impossible to honor.

### Observation 2: The Braintree adapter is intentionally thin today

`accrue/lib/accrue/processor/braintree.ex` implements direct create/fetch and returns `unsupported_operation` for `update_subscription/3`, `cancel_subscription/2..3`, `resume_subscription/2`, and `pause_subscription_collection/4`. That makes adapter expansion the first critical workstream.

### Observation 3: Subscription projection already has a Braintree branch

`Accrue.Billing.SubscriptionProjection` already maps Braintree subscriptions into local rows, but the branch is still thin: no explicit pause/cancel metadata, no mutation-oriented helpers, and no item-level mutation proof.

### Observation 4: Phase 96 already established Braintree webhook ingress

`Accrue.Webhook.Signature`, `Accrue.Webhook.Plug`, and `Accrue.Webhook.DefaultHandler` already accept Braintree webhooks. Phase 97 should reuse that ingress and extend lifecycle normalization instead of building a second webhook path.

## Implementation Risks

### Risk 1: Quantity semantics are not obviously Stripe-equivalent

`update_quantity/3` assumes a single-item subscription with an item id and quantity mutation path. The current Braintree adapter does not yet expose a direct quantity equivalent in the repo. The plan must make this explicit and prove one honest mapping instead of hiding the risk inside a generic “adapter parity” task.

### Risk 2: Pause/resume semantics may be provider-divergent

The repo currently models two different concepts:

- `resume/2` for “undo cancel at period end”
- `unpause/2` for “resume a paused subscription”

Phase 97 must define which Braintree operation or emulation path backs each concept and keep the distinction explicit in tests and support wording.

### Risk 3: Webhook convergence can regress Stripe/Fake paths

The shared reducer pipeline in `Accrue.Webhook.DefaultHandler` is already used across providers. Mutation-oriented Braintree changes must be accompanied by focused shared regression runs.

## Recommended Project Structure

```text
accrue/lib/accrue/
├── processor/braintree.ex
├── processor/capabilities.ex
├── billing/subscription_actions.ex
├── billing/subscription_projection.ex
├── webhook/default_handler.ex
└── billing/invoice_projection.ex

accrue/test/accrue/
├── processor/braintree_test.exs
├── processor/capabilities_test.exs
├── billing/subscription_actions_test.exs
├── billing/subscription_projection_provider_test.exs
├── webhook/default_handler_test.exs
└── webhook/default_handler_phase3_test.exs

examples/accrue_host/test/accrue_host/
└── braintree_*.exs
```

## Architecture Patterns

### Pattern 1: Keep mutation branching at the adapter/request seam

Reuse the existing `SubscriptionActions` transaction and projection flow. Add Braintree-specific request assembly and callback support there instead of introducing a provider-specific public mutation module.

### Pattern 2: Canonical refetch on every lifecycle webhook

Keep using `Processor.fetch/2` after webhook normalization. Do not trust payload snapshots as the final source of subscription truth.

### Pattern 3: Support truth ships with executable capability changes

Any new Braintree mutation support must update `capabilities/0`, support-label tests, and docs/matrix wording together.

## Validation Architecture

The repo already has the right validation stack for this phase:

- focused ExUnit suites for adapter, billing actions, and projections;
- shared webhook regression files for the reducer path;
- docs/support verifiers for wording drift;
- one focused credentialed Braintree proof lane in `examples/accrue_host`.

Recommended quick command:

```bash
cd accrue && mix test \
  test/accrue/processor/braintree_test.exs \
  test/accrue/processor/capabilities_test.exs \
  test/accrue/billing/subscription_actions_test.exs \
  test/accrue/billing/subscription_projection_provider_test.exs
```

Recommended full command:

```bash
bash scripts/ci/verify_processor_support_matrix.sh && \
cd accrue && mix test \
  test/accrue/processor/braintree_test.exs \
  test/accrue/processor/capabilities_test.exs \
  test/accrue/billing/subscription_actions_test.exs \
  test/accrue/billing/subscription_projection_provider_test.exs \
  test/accrue/webhook/default_handler_test.exs \
  test/accrue/webhook/default_handler_phase3_test.exs
```

## Plan Shape Recommendation

Use three plans:

1. **Mutation contract + adapter semantics** — add Braintree mutation callbacks, capability truth, and billing-action branching with focused regressions.
2. **Webhook convergence + projection hardening** — normalize mutation-related lifecycle events and persist converged subscription state locally.
3. **Proof + docs closeout** — extend the host/provider evidence lane and update support wording/matrix truth to reflect the real Phase 97 slice.

## Resolved Planning Answers

- **Should Phase 97 widen the public API?** No. Keep using the existing billing facade methods.
- **Should webhook work be a separate subsystem?** No. Extend the existing Braintree ingress and shared reducer path.
- **Should provider-backed Braintree runs become merge-blocking?** No. Keep them focused, explicit, and advisory, while Fake stays the routine proof lane.
- **Should quantity/pause semantics be hidden under generic wording?** No. Treat both as explicit contract work items with dedicated tests and docs.
