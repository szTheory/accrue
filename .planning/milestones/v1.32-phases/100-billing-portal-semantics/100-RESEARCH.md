<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Accrue must remain a headless backend facade. It will not ship opinionated UI components (like LiveView) to polyfill missing gateway features like Braintree's lack of a hosted portal.
- **D-02:** `Accrue.Processor.Braintree` must explicitly reject `billing_portal: %{create: true}` in its capability map to reflect reality.
- **D-03:** `Accrue.Billing.create_billing_portal_session/2` must return an explicit, typed error when the underlying processor is Braintree: `{:error, %Accrue.APIError{code: :unsupported_by_gateway, message: "..."}}`.
- **D-04:** The error message should be helpful and point developers to the official Accrue documentation for building a local portal.
- **D-05:** To bridge the DX gap without taking on UI maintenance, Accrue must provide a comprehensive, first-class guide (`guides/braintree-local-portal.md`).
- **D-06:** The guide must demonstrate exactly how to build a custom local portal in Phoenix/LiveView using Accrue's existing `Accrue.Billing` CRUD primitives (developed in Phases 97-99 for subscription mutations and payment method management).
- **D-07:** The documentation should be structured to mirror the capabilities of Stripe's portal, showing developers how to achieve parity in their host application.
- **D-08:** Maintain the precedent that Accrue is an API wrapper and domain modeler, not a UI framework. Future gateway integrations missing hosted UIs should follow this exact "explicit error + documentation recipe" pattern.

### the agent's Discretion
- The exact wording of the error message to fit within the `Accrue.APIError` struct.
- The structure and formatting of `guides/braintree-local-portal.md`.

### Deferred Ideas (OUT OF SCOPE)
- A drop-in unified LiveView portal shipped as part of `accrue_admin` (rejected to maintain separation of concerns and avoid UI lock-in).
- Any attempt to render Braintree Drop-in UI directly from Accrue.
</user_constraints>

# Phase 100: Billing Portal Semantics - Research

**Researched:** 2026-05-01 (Current Date)
**Domain:** Elixir, Accrue Billing Facade, Braintree Processor capabilities, Documentation
**Confidence:** HIGH

## Summary

This phase enforces the architectural boundary of Accrue as a headless billing facade by officially recognizing that Braintree lacks a hosted billing portal. Rather than attempting to polyfill this gap with a framework-specific (e.g., Phoenix LiveView) UI implementation within Accrue, the library will explicitly reject billing portal requests when backed by Braintree.

**Primary recommendation:** Update `Accrue.Processor.Braintree.capabilities/0` to disable `:billing_portal`, intercept portal session creation in `Accrue.Billing.create_billing_portal_session/2`, return a targeted `:unsupported_by_gateway` error pointing to a new canonical guide, and author `guides/braintree-local-portal.md` documenting how hosts should construct their own localized portal using Accrue's lower-level CRUD primitives.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Braintree Hosted Portal | N/A | — | Gateway lacks this feature; Accrue cannot supply it headlessly. |
| Local Portal UI | Host App (Frontend) | — | Explicit boundary decision: Accrue provides headless APIs, the host application provides UI. |
| Billing Portal Routing | API / Backend (Accrue) | — | Accrue inspects gateway capabilities and routes or safely errors with actionable guidance. |

## Standard Stack

N/A - This phase introduces no new dependencies. It alters internal conditional routing and adds documentation.

## Architecture Patterns

### Recommended Project Structure (Guide)
The new guide `guides/braintree-local-portal.md` should live alongside existing integration guides like `guides/testing-live-stripe.md` and `guides/first_hour.md` in the `accrue/guides/` directory. (Note: Elixir's `mix.exs` automatically packages everything under `guides/*.md`).

### Pattern 1: Capability-Gated Facade Operations
**What:** Leveraging `Accrue.Processor.Capabilities` to branch logic before attempting an underlying gateway call.
**When to use:** When standardizing unified interfaces (like `create_billing_portal_session/2`) over underlying adapters (Stripe vs. Braintree) with differing feature surfaces.
**Example:**
```elixir
if Accrue.Processor.supports?([:billing_portal, :create]) do
  # delegate to underlying creation
else
  # return fast, structured APIError
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Missing gateway portal | Accrue-shipped LiveView portal | `guides/braintree-local-portal.md` | Avoids CSS framework lock-in, complex routing injection, and security footprint in the headless API boundary. |

## Common Pitfalls

### Pitfall 1: Silent Failures on Unsupported Gateways
**What goes wrong:** If `create_billing_portal_session/2` delegates blindly to Braintree, it will fail deep within adapter specifics or return generic 400 bad requests that provide no actionable DX (developer experience).
**How to avoid:** Hard-code the rejection in the `Accrue.Billing` facade using the capability map. Provide an explicit error pointing to the guide.

### Pitfall 2: Accidental Telemetry Leakage
**What goes wrong:** If the error is not caught cleanly, it might skew `[:accrue, :billing, :billing_portal, :create]` OpenTelemetry metrics with generic failures rather than explicit unsupported operation markers.
**How to avoid:** Ensure the error path still emits the standard telemetry with the expected `:error` payload structure.

## Code Examples

### 1. Updating Braintree Capabilities (`accrue/lib/accrue/processor/braintree.ex`)
```elixir
  def capabilities do
    %{
      # ... existing ...
      billing_portal: %{create: false},
      # ... existing ...
    }
  end
```

### 2. Gating the Facade (`accrue/lib/accrue/billing.ex`)
Modify `create_billing_portal_session/2`:
```elixir
    span_billing(:billing_portal, :create, customer, validated, fn ->
      if Accrue.Processor.supports?([:billing_portal, :create]) do
        Session.create(Map.new([customer: customer] ++ validated))
      else
        {:error,
         %Accrue.APIError{
           code: :unsupported_by_gateway,
           message:
             "The configured processor (#{Accrue.Processor.processor_name()}) does not support a hosted billing portal. See guides/braintree-local-portal.md for building a local portal.",
           http_status: 400
         }}
      end
    end)
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix.exs` automatically includes all `.md` files in `guides/` in the Hex package. | Standard Stack | Documentation guide would be missing from ExDoc Hex package if wildcard isn't configured. (Verified via grep `extras: ["README.md" | Path.wildcard("guides/*.md")]` in `mix.exs`) |

## Open Questions (RESOLVED)

1. **Test Coverage Structure** (RESOLVED)
   - What we know: `create_billing_portal_session/2` has tests for Stripe.
   - What's unclear: Should we mock `Accrue.Processor.Braintree` in `billing_portal_session_facade_test.exs` to ensure the specific `APIError` is returned?
   - Recommendation: Yes, add an explicit test block mimicking a Braintree configuration to assert the `{:error, %APIError{code: :unsupported_by_gateway}}` branch is triggered properly.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/accrue/billing/billing_portal_session_facade_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-20 | Braintree capabilities correctly map `billing_portal: %{create: false}` | unit | `mix test test/accrue/processor/braintree_test.exs` | ✅ Wave 0 |
| PROC-20 | `create_billing_portal_session/2` returns targeted `APIError` if unsupported | unit | `mix test test/accrue/billing/billing_portal_session_facade_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements. We only need to add specific test cases within existing files.

## Sources

### Primary (HIGH confidence)
- Codebase grep matching: `Accrue.Billing.create_billing_portal_session/2` (`accrue/lib/accrue/billing.ex`)
- Codebase grep matching: `Accrue.Processor.Braintree.capabilities/0` (`accrue/lib/accrue/processor/braintree.ex`)
- Codebase grep matching: `guides/` wildcard in `mix.exs`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - First-party Accrue API changes only.
- Architecture: HIGH - Follows strict constraints laid out in D-01 through D-08.
- Pitfalls: HIGH - Grounded in current telemetry and capability design.