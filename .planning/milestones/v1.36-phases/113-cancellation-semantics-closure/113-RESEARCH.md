# Phase 113: Cancellation Semantics Closure - Research

**Researched:** 2026-05-06
**Domain:** Cancellation semantics closure across facade verbs, capability labels, provider-honest docs, touched UI, and proof lanes for Stripe, Fake, and Braintree.
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Keep the official Braintree first-party cancellation contract immediate-only.
- **D-02:** `Accrue.Billing.cancel/2` remains the immediate hard-stop verb.
- **D-03:** `Accrue.Billing.cancel_at_period_end/2` remains the explicit scheduled-end verb where provider truth supports it.
- **D-04:** Unsupported providers must fail clearly for `cancel_at_period_end/2`; do not silently degrade into immediate cancellation.
- **D-05:** `cancel_immediately` may remain capability/docs vocabulary that maps to `cancel/2`, but this phase should not add a third public facade verb just for naming symmetry.
- **D-06:** Capability booleans, support labels, `.planning/processor-support-matrix.md`, docs, and touched UX must move together in one truth pass.
- **D-07:** `subscription.cancel` and `subscription.cancel_immediately` should align to the same immediate-cancel truth across Stripe, Fake, and Braintree.
- **D-08:** `subscription.cancel_at_period_end` remains supported on Stripe and Fake and explicitly unsupported on Braintree.
- **D-09:** Unsupported lifecycle branches should fail with typed, machine-readable errors plus one concrete next-step hint.
- **D-10:** Touched host/admin/customer surfaces should gate unsupported Braintree scheduled-end flows instead of implying parity.

### the agent's Discretion
- Exact label wording for mixed lifecycle support, as long as immediate-vs-scheduled truth is explicit.
- Exact typed error/message shape for unsupported Braintree scheduled-end flows, as long as the error is machine-readable and actionable.
- Exact host seam wording for Braintree non-renewal policy above Accrue, as long as it is clearly outside the official first-party contract.

### Deferred Ideas (OUT OF SCOPE)
- Any public API rename or new alias such as `cancel_now/2` or `cancel_immediately/2`.
- Library-owned local scheduled-cancellation orchestration for Braintree.
- Broader lifecycle parity such as pause/resume/reopen symmetry.
- New processor breadth or support-contract expansion outside Phase 113.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-22 | Host code can use the supported subscription cancellation path on Stripe, Fake, and Braintree through the generic billing facade without staged-label drift or ambiguous processor semantics. | The shipped immediate path already exists at `Billing.cancel/2`, Braintree already exposes `cancel: true` and `cancel_immediately: true`, and the missing closure work is at labels, docs, unsupported-path messaging, and proof rather than basic adapter support. [VERIFIED: `accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/billing/subscription_actions.ex`, `accrue/lib/accrue/processor/braintree.ex`, `accrue/test/accrue/billing/subscription_cancel_test.exs`] |
| PROC-23 | Maintainers and adopters can inspect capability labels for customer update and cancellation semantics and see runtime truth that matches actual supported behavior, with unsupported lifecycle branches still failing clearly. | Runtime capabilities still describe cancellation rows as staged, while the shipped docs/UI/test surfaces already distinguish immediate and end-of-period flows unevenly; Phase 113 needs one aligned truth pass across capability labels, the support matrix, touched docs, and tests. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex`, `.planning/processor-support-matrix.md`, `accrue/guides/lifecycle_semantics.md`, `accrue/guides/braintree-local-portal.md`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`, `accrue_portal/lib/accrue_portal/live/subscription_live.ex`] |
</phase_requirements>

## Summary

The runtime semantics are already mostly correct; the support contract is what still drifts. `Accrue.Billing.cancel/2` already means immediate cancellation, `Accrue.Billing.cancel_at_period_end/2` already means scheduled-end cancellation, and `resume/2` already encodes the provider-specific unsupported branch for Braintree. The remaining mismatch is that runtime capability labels still call the cancellation family `staged first-party target` even though the immediate path is already real and merge-blocked. [VERIFIED: `accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/billing/subscription_actions.ex`, `accrue/lib/accrue/processor/capabilities.ex`, `accrue/test/accrue/billing/subscription_cancel_test.exs`]

Braintree already exposes the desired boundary in code. Its capability map declares `cancel: true`, `cancel_immediately: true`, and `cancel_at_period_end: false`, and its adapter rejects `cancel_at_period_end` and `cancel_at` with explicit unsupported semantics instead of faking parity. That is the contract Phase 113 should promote publicly rather than smooth over. [VERIFIED: `accrue/lib/accrue/processor/braintree.ex`, `accrue/test/accrue/processor/braintree_test.exs`]

The main drift is in human-facing mirrors. The lifecycle guide already teaches `cancel_at_period_end` as the default least-surprise self-serve action, the portal surfaces already use `Billing.cancel_at_period_end/2`, and the example host already frames immediate cancellation as exceptional. But the support labels and support matrix still understate the shipped immediate contract, and the Braintree local-portal guide plus admin/operator surfaces still need one provider-honest pass so the same cancellation vocabulary appears everywhere. [VERIFIED: `accrue/guides/lifecycle_semantics.md`, `accrue/guides/braintree-local-portal.md`, `accrue/guides/portal_configuration_checklist.md`, `accrue_portal/lib/accrue_portal/live/subscription_live.ex`, `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`, `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`]

**Primary recommendation:** split Phase 113 into three plans:

1. promote the runtime/public cancellation support truth so immediate-cancel rows are first-party while scheduled-end truth stays explicitly split by provider
2. align docs and touched UI around the same immediate-vs-scheduled vocabulary and provider-honest unsupported guidance
3. close the phase with deterministic core/UI proof plus drift-gate updates so the contract cannot slip back to staged or ambiguous wording

That sequencing follows the same pattern Phase 112 used successfully: runtime/public truth first, then human-facing mirrors, then proof. [VERIFIED: `.planning/phases/112-customer-update-contract-closure/112-01-PLAN.md`, `.planning/phases/112-customer-update-contract-closure/112-02-PLAN.md`, `.planning/phases/112-customer-update-contract-closure/112-03-PLAN.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Immediate and scheduled cancellation runtime semantics | `accrue/lib/accrue/billing/subscription_actions.ex` | `accrue/lib/accrue/processor/*.ex` | The billing action layer defines the public meaning of `cancel/2`, `cancel_at_period_end/2`, and `resume/2`, while adapters supply provider truth and unsupported-path behavior. |
| Public support labels and first-party classification | `accrue/lib/accrue/processor/capabilities.ex` | `.planning/processor-support-matrix.md` | Runtime labels and the human-readable support matrix are the canonical contract mirrors that must move together. |
| Customer-facing scheduled-end wording | `accrue_portal/lib/accrue_portal/copy.ex` and LiveViews | `accrue/guides/lifecycle_semantics.md` | Portal surfaces already use the scheduled-end action path; they should mirror the lifecycle guide’s vocabulary rather than invent their own. |
| Operator/provider-divergence guidance | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | `accrue/guides/braintree-local-portal.md` | Admin surfaces already expose both actions and are the natural place for provider-aware helper text and confirmation wording. |
| Host-owned exceptional hard-stop example | `examples/accrue_host/lib/accrue_host/billing.ex` and LiveView | lifecycle docs | The example host already owns the product-policy seam and should keep immediate cancellation explicit rather than implying generic parity. |

## Current-State Findings

### The public facade already has the right verb split

- `Accrue.Billing.cancel/2` delegates to `SubscriptionActions.cancel/2`.
- `Accrue.Billing.cancel_at_period_end/2` delegates to `SubscriptionActions.cancel_at_period_end/2`.
- `subscription_cancel_test.exs` already proves immediate cancel returns `:canceled`, while `cancel_at_period_end/2` preserves `:active` and flips `cancel_at_period_end`. [VERIFIED: `accrue/lib/accrue/billing.ex`, `accrue/lib/accrue/billing/subscription_actions.ex`, `accrue/test/accrue/billing/subscription_cancel_test.exs`]

### Braintree already encodes the bounded provider truth

- Braintree capabilities expose `cancel: true`, `cancel_immediately: true`, `cancel_at_period_end: false`.
- `validate_cancel_params/1` rejects `cancel_at_period_end` and `cancel_at` as unsupported semantics and rejects unsupported immediate-cancel flags like `invoice_now: true` and `prorate: true`.
- Existing tests already pin both the capability booleans and the unsupported flag behavior. [VERIFIED: `accrue/lib/accrue/processor/braintree.ex`, `accrue/test/accrue/processor/braintree_test.exs`]

### Runtime/public labels are still staged and need closure

- `Capabilities.support_label([:subscription, :cancel])` is still `staged first-party target`.
- `Capabilities.support_label([:subscription, :cancel_immediately])` is still `staged first-party target`.
- `.planning/processor-support-matrix.md` already describes `Accrue.Billing.cancel/2` as `all first-party`, which means runtime labels and planning SSOT have drifted apart in opposite directions.
- `subscription.cancel_at_period_end` should remain split rather than promoted globally because Braintree truth is explicitly `false`. [VERIFIED: `accrue/lib/accrue/processor/capabilities.ex`, `.planning/processor-support-matrix.md`, `accrue/test/accrue/processor/capabilities_test.exs`]

### Docs and UX already contain most of the desired vocabulary, but not consistently

- `accrue/guides/lifecycle_semantics.md` already frames `cancel_at_period_end` as the default self-serve posture and `cancel/2` as the exceptional immediate path.
- `accrue_portal` detail and list views already call `Billing.cancel_at_period_end/2`, and existing tests already assert customer-facing “Cancel renewal” wording.
- The example host already uses explicit hard-stop wording for its immediate cancel proof surface.
- The Braintree local-portal guide still teaches immediate cancellation as the primary self-serve example and is the strongest remaining doc seam that can overstate parity. [VERIFIED: `accrue/guides/lifecycle_semantics.md`, `accrue/guides/braintree-local-portal.md`, `accrue_portal/lib/accrue_portal/live/subscription_live.ex`, `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`, `accrue_portal/test/accrue_portal/live/subscription_live_test.exs`, `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`]

### The proof lanes are already close to what Phase 113 needs

- Core billing tests already cover the immediate-vs-scheduled runtime behavior.
- Braintree adapter tests already cover capability truth and unsupported parameters.
- Portal/admin/example-host tests already pin key cancellation wording in several touched surfaces.
- The largest missing proof gap is contract-level support-label alignment for `subscription.cancel` and `subscription.cancel_immediately`, plus doc-level drift checks for the Braintree scheduled-end teaching surface. [VERIFIED: `accrue/test/accrue/billing/subscription_cancel_test.exs`, `accrue/test/accrue/processor/braintree_test.exs`, `accrue/test/accrue/processor/capabilities_test.exs`, `accrue_portal/test/accrue_portal/live/subscription_live_test.exs`, `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`, `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`]

## Risks

### Risk 1: promoting all cancellation labels uniformly would lie about Braintree

If Phase 113 simply flips every cancellation-related support label to first-party, the runtime contract would imply Braintree supports scheduled-end cancellation when it explicitly does not. Keep `cancel` and `cancel_immediately` aligned to the shipped immediate path, but keep `cancel_at_period_end` provider-split. [VERIFIED: `accrue/lib/accrue/processor/braintree.ex`, `accrue/lib/accrue/processor/capabilities.ex`]

### Risk 2: changing public API names in the same phase would widen scope and destabilize proof

The current verb split is already consistent enough for closure. Adding aliases or renames would multiply docs/proof churn without solving the actual support-truth problem. [VERIFIED: `.planning/phases/113-cancellation-semantics-closure/113-CONTEXT.md`, `accrue/lib/accrue/billing.ex`]

### Risk 3: docs/UI might accidentally imply that Accrue owns a host-side Braintree non-renewal policy

It is fine to point adopters toward a host-owned seam for softer Braintree behavior, but the wording must keep that outside the official first-party runtime contract. [VERIFIED: `.planning/phases/113-cancellation-semantics-closure/113-CONTEXT.md`, `examples/accrue_host/lib/accrue_host/billing.ex`]

## Recommended Plan Shape

### Plan 01: Runtime and support-truth closure

Scope:
- promote `subscription.cancel` and `subscription.cancel_immediately` runtime labels from staged to first-party
- keep `subscription.cancel_at_period_end` explicitly split
- align `.planning/processor-support-matrix.md` wording to the promoted immediate path and unsupported Braintree scheduled-end branch
- extend contract tests for the promoted labels and the split row

Why first:
- everything else depends on a settled support-contract story
- this mirrors the successful “runtime/public truth before docs” sequencing from Phase 112

### Plan 02: Docs and touched UX alignment

Scope:
- update `accrue/guides/braintree-local-portal.md` and adjacent lifecycle-facing docs so they teach the provider-honest split
- tighten admin/operator helper text and confirmations around “Cancel now” vs “Cancel at period end”
- keep portal and example-host surfaces aligned to the same vocabulary; only change them where needed to avoid drift or implied parity

Why second:
- once the support labels are settled, docs and UX can mirror them without guessing

### Plan 03: Proof and drift gates

Scope:
- extend targeted core, admin, portal, and host tests where the new contract needs durable assertions
- add or tighten script/doc drift gates so staged-vs-first-party mismatch and stale Braintree guide wording fail fast

Why last:
- the proof should pin the final contract wording, not an intermediate draft

## Verification Guidance

- `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/processor/capabilities_test.exs test/accrue/processor/braintree_test.exs`
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs`
- `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs`
- `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs`
- run any existing support-matrix/doc verification scripts touched by the plan so runtime labels and planning mirrors cannot drift independently

## RESEARCH COMPLETE
