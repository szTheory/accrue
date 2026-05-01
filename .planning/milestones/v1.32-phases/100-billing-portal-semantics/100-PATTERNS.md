# Phase 100: Billing Portal Semantics - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/processor/braintree.ex` | adapter | API integration | `accrue/lib/accrue/processor/braintree.ex` | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | config | config/metadata | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/lib/accrue/billing.ex` | service/facade | request-response | `accrue/lib/accrue/billing.ex` | exact |
| `accrue/guides/braintree-local-portal.md` | documentation | N/A | `accrue/guides/portal_configuration_checklist.md` | role-match |

## Pattern Assignments

### `accrue/lib/accrue/processor/braintree.ex` (adapter, API integration)

**Analog:** `accrue/lib/accrue/processor/braintree.ex`

**Capability rejection pattern** (lines 13-33):
The capability map explicitly lists `false` for intentionally unsupported slices.
```elixir
      subscription: %{
        direct_create: true,
        cancel: true,
        fetch: true,
        lifecycle_webhook_projection: true,
        update: true,
        cancel_at_period_end: false,
        cancel_immediately: true,
        pause: false,
        resume: false
      },
```
*Pattern:* Add `billing_portal: %{create: false}` to the `capabilities/0` map.

**Explicit API Error pattern** (lines 485-499):
Unsupported operations return `{:error, %APIError{...}}` with a clear message and code.
```elixir
  defp unsupported_semantic(semantic) do
    %APIError{
      code: "processor_operation_unsupported",
      http_status: 422,
      message: "Braintree does not support Accrue's #{semantic} semantic."
    }
  end
```
*Pattern:* Modify `portal_session_create/2` to return `{:error, %Accrue.APIError{code: :unsupported_by_gateway, http_status: 400, message: "..."}}` directly, bypassing the generic `unsupported()` helper to comply with D-03.

---

### `accrue/lib/accrue/processor/capabilities.ex` (config, config/metadata)

**Analog:** `accrue/lib/accrue/processor/capabilities.ex`

**Capability map structure pattern** (lines 11-47):
The source of truth for support labels. Note that `billing_portal` is already defined here.
```elixir
    billing_portal: %{
      create: "Stripe-only"
    },
```
*Pattern:* Ensure Braintree's own module (`braintree.ex`) correctly mirrors this structure with `create: false`. No structural changes are strictly needed in `capabilities.ex` itself unless documentation updates are desired to explicitly mention Braintree's headless nature.

---

### `accrue/lib/accrue/billing.ex` (service/facade, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Documentation & ExDoc pattern** (lines 351-383):
Existing docstrings use Markdown sections for special considerations and processor behaviors (e.g. metered billing doc at line 527).
```elixir
  ## Error tuples vs persisted rows

  `{:error, _}` means this **call** could not advance durable meter state as
  requested (for example the processor rejected the usage report).
```
*Pattern:* Expand `@doc` for `create_billing_portal_session/2` and `create_billing_portal_session!/2` to include a section detailing processor capabilities, explicitly documenting the Braintree `{:error, %Accrue.APIError{code: :unsupported_by_gateway}}` limitation, and cross-linking to `guides/braintree-local-portal.md`.

---

### `accrue/guides/braintree-local-portal.md` (documentation, N/A)

**Analog:** `accrue/guides/portal_configuration_checklist.md` (and other LiveView/integration guides)

**Documentation pattern:**
Guides typically provide context, "why", and explicit code snippets.
*Pattern:* Write a guide that explains why Accrue doesn't ship an opinionated UI for Braintree, then provide Phoenix/LiveView code snippets showing how to assemble `Accrue.Billing.add_payment_method/3` and `Accrue.Billing.swap_plan/3` into a cohesive local portal.

## Shared Patterns

### Standard Accrue APIError
**Source:** `accrue/lib/accrue/errors.ex`
**Apply to:** `accrue/lib/accrue/processor/braintree.ex`
The `Accrue.APIError` struct is centrally used for processor rejections.
```elixir
defmodule Accrue.APIError do
  @type t :: %__MODULE__{}
  defexception [:message, :code, :http_status, :request_id, :processor_error]
end
```
*Application:* Ensure the `code` is strictly `:unsupported_by_gateway` (as requested by D-03) rather than a string.

## No Analog Found

None.

## Metadata

**Analog search scope:** `accrue/lib/accrue/**/*.ex`, `accrue/guides/*.md`
**Files scanned:** ~10
**Pattern extraction date:** 2026-05-01