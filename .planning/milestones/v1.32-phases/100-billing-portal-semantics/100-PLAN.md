---
phase: 100-billing-portal-semantics
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue/lib/accrue/processor/braintree.ex
  - accrue/lib/accrue/billing.ex
  - accrue/guides/braintree-local-portal.md
  - accrue/test/accrue/processor/braintree_test.exs
  - accrue/test/accrue/billing/billing_portal_session_facade_test.exs
autonomous: true
requirements:
  - PROC-20
must_haves:
  truths:
    - Braintree explicitly rejects billing portal creation capabilities.
    - Calling `create_billing_portal_session/2` returns a typed `APIError` when Braintree is the gateway.
    - Integrators have clear documentation explaining why Accrue does not ship a UI and how to build a local portal.
  artifacts:
    - path: accrue/lib/accrue/processor/braintree.ex
      provides: Capability map explicitly rejecting portal creation
    - path: accrue/lib/accrue/billing.ex
      provides: Capability gating and error routing for portal sessions
    - path: accrue/guides/braintree-local-portal.md
      provides: Copy-pasteable LiveView snippets for custom portals
  key_links:
    - from: accrue/lib/accrue/billing.ex
      to: accrue/guides/braintree-local-portal.md
      via: Error message documentation reference
---

<objective>
Implement the explicit rejection of billing portal creation for Braintree, ensuring Accrue remains a headless backend facade while providing developers with a comprehensive guide to building a local portal.

Purpose: To avoid shipping opinionated UI components for missing gateway features while clearly guiding integrators on achieving feature parity using Accrue's primitives.
Output: Capability checks in the facade, explicit APIError response, and a local portal implementation guide.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/milestones/v1.32-ROADMAP.md
@.planning/PROJECT.md
@.planning/milestones/v1.32-phases/100-billing-portal-semantics/100-CONTEXT.md
@.planning/milestones/v1.32-phases/100-billing-portal-semantics/100-RESEARCH.md
@.planning/milestones/v1.32-phases/100-billing-portal-semantics/100-PATTERNS.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Explicitly disable Braintree portal capability</name>
  <files>accrue/lib/accrue/processor/braintree.ex, accrue/test/accrue/processor/braintree_test.exs</files>
  <behavior>
    - Test 1: `capabilities/0` returns a map that includes `billing_portal: %{create: false}`.
  </behavior>
  <action>
    Modify `Accrue.Processor.Braintree.capabilities/0` to explicitly map `billing_portal: %{create: false}`. This reflects the reality that Braintree lacks a hosted billing portal.
    Do not use generic `unsupported/1` helper here; simply update the capability map structure.
  </action>
  <verify>
    <automated>cd accrue && mix test test/accrue/processor/braintree_test.exs</automated>
  </verify>
  <done>Braintree explicit capability map returns false for billing_portal create.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Fail cleanly in Billing facade on unsupported gateways</name>
  <files>accrue/lib/accrue/billing.ex, accrue/test/accrue/billing/billing_portal_session_facade_test.exs</files>
  <behavior>
    - Test 1: `create_billing_portal_session/2` returns `{:error, %Accrue.APIError{code: :unsupported_by_gateway}}` when `Accrue.Processor.supports?([:billing_portal, :create])` is false.
  </behavior>
  <action>
    Modify `Accrue.Billing.create_billing_portal_session/2` and `create_billing_portal_session!/2` to check for capability support before delegating to the processor.
    Wrap the delegation:
    `if Accrue.Processor.supports?([:billing_portal, :create]) do ... else ... end`.
    If false, return `{:error, %Accrue.APIError{code: :unsupported_by_gateway, http_status: 400, message: "The configured processor (Braintree) does not support a hosted billing portal. See guides/braintree-local-portal.md for building a local portal."}}`.
    Ensure Telemetry `span_billing` continues to wrap the logic so the error payload is emitted properly.
    Update the `@doc` strings for these functions to document this explicit processor limitation, cross-linking to `guides/braintree-local-portal.md`.
  </action>
  <verify>
    <automated>cd accrue && mix test test/accrue/billing/billing_portal_session_facade_test.exs</automated>
  </verify>
  <done>Facade cleanly intercepts and errors on unsupported billing portal creation, with clear documentation.</done>
</task>

<task type="auto">
  <name>Task 3: Author local portal documentation guide</name>
  <files>accrue/guides/braintree-local-portal.md</files>
  <action>
    Create a comprehensive developer guide explaining how to build a custom local billing portal.
    Explain why Accrue does not ship this UI (avoiding CSS framework lock-in, routing complexities, security surface expansion).
    Provide Phoenix/LiveView code snippets showing how to assemble `Accrue.Billing.add_payment_method/3`, `Accrue.Billing.swap_plan/3`, etc., into a cohesive self-serve local portal that achieves parity with Stripe's portal.
    Ensure formatting aligns with other guides in the directory.
  </action>
  <verify>
    <automated>test -f accrue/guides/braintree-local-portal.md</automated>
  </verify>
  <done>Comprehensive DX guide exists with code snippets and architectural rationale.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Developer → Accrue API | Calling billing facade functions crosses the library boundary. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-100-01 | Denial of Service | `Accrue.Billing.create_billing_portal_session` | mitigate | Reject at facade level via `capabilities` check rather than failing deep in processor adapter. |
| T-100-02 | Information Disclosure | `Accrue.APIError` response | mitigate | Ensure error message provides DX value without leaking underlying adapter configuration secrets. |
</threat_model>

<verification>
- `mix test` passes across the suite, specifically `braintree_test.exs` and `billing_portal_session_facade_test.exs`.
- Documentation generation (`mix docs` if available) successfully parses the new guide.
- Braintree is strictly prevented from attempting to create billing portals.
</verification>

<success_criteria>
- The Accrue application cleanly rejects `billing_portal` requests for Braintree with a custom HTTP 400 APIError.
- The `braintree-local-portal.md` guide is available in the `guides` directory.
- `Accrue.Billing.create_billing_portal_session/2` has updated `@doc` references pointing to the guide.
</success_criteria>

<output>
After completion, create `.planning/phases/100-billing-portal-semantics/100-01-SUMMARY.md`
</output>