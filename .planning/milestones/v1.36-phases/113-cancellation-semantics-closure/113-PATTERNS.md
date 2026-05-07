# Phase 113: Cancellation Semantics Closure - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 18
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | request-response | same file | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | support-ssot | canonical contract | same file | exact |
| `.planning/processor-support-matrix.md` | planning mirror | canonical contract | same file | exact |
| `accrue/lib/accrue/processor/braintree.ex` | adapter | request-response | same file | exact |
| `accrue/guides/lifecycle_semantics.md` | docs | canonical contract | same file | exact |
| `accrue/guides/braintree-local-portal.md` | docs | provider guide | same file | exact |
| `accrue/guides/portal_configuration_checklist.md` | docs | provider guide | same file | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | component | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/live/subscription_live.ex` | component | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` | component | request-response | same file | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | host facade | request-response | same file | exact |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | component | request-response | same file | exact |
| `accrue/test/accrue/billing/subscription_cancel_test.exs` | runtime proof | verifier | same file | exact |
| `accrue/test/accrue/processor/capabilities_test.exs` | contract gate | verifier | same file | exact |
| `accrue/test/accrue/processor/braintree_test.exs` | adapter proof | verifier | same file | exact |
| `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` | UI proof | verifier | same file | exact |
| `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs` | UI proof | verifier | same file | exact |
| `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | UI proof | verifier | same file | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing/subscription_actions.ex` (service, request-response)

**Analog:** same file

**Explicit verb split pattern**
```elixir
# cancel/2 — cancel immediately
# cancel_at_period_end/2 — schedule cancellation at the end of the billing period
```

**Typed unsupported-path pattern**
```elixir
{:error,
 %Accrue.APIError{
   code: "processor_operation_unsupported",
   http_status: 422,
   message:
     "Braintree subscriptions cannot be resumed through resume/2 because provider-side cancellations cannot be reactivated."
 }}
```

**Planner implication:** do not redesign the cancellation API in Phase 113. Reuse the existing explicit-verb and typed-error patterns and make the support contract match them.

### `accrue/lib/accrue/processor/capabilities.ex` + `.planning/processor-support-matrix.md` (support SSOT)

**Analogs:** same files

**Runtime label gate**
```elixir
def first_party_supported?(capabilities, path)
    when is_map(capabilities) and is_list(path) do
  support_label(path) == "all first-party" and supports?(capabilities, path)
end
```

**Current cancellation drift seam**
- runtime labels still stage `subscription.cancel` and `subscription.cancel_immediately`
- planning mirror already describes `Accrue.Billing.cancel/2` as first-party

**Planner implication:** treat runtime labels and the support matrix as one co-update unit. Any plan that edits one without the other is incomplete.

### `accrue/lib/accrue/processor/braintree.ex` (adapter, request-response)

**Analog:** same file

**Capability-truth pattern**
```elixir
subscription: %{
  cancel: true,
  cancel_at_period_end: false,
  cancel_immediately: true
}
```

**Unsupported-scheduled-end pattern**
```elixir
truthy?(params[:cancel_at_period_end] || params["cancel_at_period_end"]) ->
  {:error, unsupported_semantic("cancel at period end")}
```

**Planner implication:** Braintree is the boundary-setting file for this phase. Plans should derive wording and tests from this exact truth rather than inventing generic parity language.

### `accrue/guides/lifecycle_semantics.md` (docs, canonical contract)

**Analog:** same file

**Least-surprise posture**
- `cancel_at_period_end` is the default self-serve posture
- `cancel/2` is immediate hard-stop
- wording already distinguishes renewal-stop from immediate access termination

**Planner implication:** use this guide as the vocabulary anchor for any touched portal/admin/example-host copy.

### `accrue/guides/braintree-local-portal.md` and `portal_configuration_checklist.md` (docs, provider guides)

**Analogs:** same files

**Current split-doc pattern**
- Stripe-facing checklist already prefers “at period end”
- Braintree local-portal guide still demonstrates immediate cancel as the primary path

**Planner implication:** this is the highest-value doc co-update seam. Align the Braintree guide to the same vocabulary while still admitting the provider boundary.

### `accrue_portal` LiveViews and tests (component + UI proof)

**Analogs:** same files

**Action/path alignment pattern**
- detail and list views already call `Billing.cancel_at_period_end/2`
- tests already assert “Cancel renewal” wording and `cancel_at_period_end` persistence

**Planner implication:** portal may need only bounded wording or drift-proof updates, not a semantic rewrite. Prefer using the existing pattern as proof of the desired posture.

### `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (component, request-response)

**Analog:** same file

**Dual-action operator pattern**
- exposes both `cancel_now` and `cancel_at_period_end`
- already contains provider-honest copy for end-of-period cancellation
- is the best place to clarify the split between default renewal-stop and exceptional hard-stop behavior

**Planner implication:** if any UI surface needs more explicit provider-aware helper text, admin is the right target because it presents both actions side-by-side.

### `examples/accrue_host/*subscription_live*` (proof/reference surface)

**Analogs:** same files

**Host-owned exceptional hard-stop pattern**
- current copy already frames immediate cancellation as explicit and potentially access-ending
- this is a proof/reference surface, not the primary default self-serve contract

**Planner implication:** avoid over-editing the example host. Preserve its role as a host-owned seam while keeping its wording consistent with the official contract boundary.

### `accrue/test/accrue/billing/subscription_cancel_test.exs`, `capabilities_test.exs`, `braintree_test.exs` (proof bundle)

**Analogs:** same files

**Proof-layer split**
- billing tests prove public facade semantics
- capabilities tests prove label truth
- Braintree tests prove adapter truth and unsupported flags

**Planner implication:** keep this proof layering in the plan. Do not collapse all verification into one file or one package.

## Reusable Phase Pattern

The closest execution analog is Phase 112:

1. close runtime/public truth first
2. mirror that truth into docs and human-facing surfaces
3. finish with targeted proof and drift gates

That pattern fits Phase 113 better than a doc-first pass because the current mismatch is fundamentally a support-contract classification problem.

## Strongest File-Level Opportunities

1. `accrue/lib/accrue/processor/capabilities.ex` + `.planning/processor-support-matrix.md`
   Immediate, high-signal place to close staged-vs-first-party drift.

2. `accrue/guides/braintree-local-portal.md`
   Highest-risk doc seam for overstating scheduled-end parity on Braintree.

3. `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
   Best UI seam for clarifying operator-facing immediate-vs-scheduled action differences.

4. `accrue/test/accrue/processor/capabilities_test.exs`
   Cleanest place to pin the promoted immediate-cancel labels without widening scope.

5. `scripts/ci/*` and existing doc/support verification scripts
   Likely place to codify drift gates once wording is settled.
