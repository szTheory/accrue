# Phase 95: Official processor contract + conformance harness - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 10 primary files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/processor-support-matrix.md` | config | transform | `.planning/processor-support-matrix.md` | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | utility | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/lib/accrue/processor.ex` | interface | request-response | `accrue/lib/accrue/processor.ex` | exact |
| `accrue/lib/accrue/checkout/session.ex` | interface | request-response | `accrue/lib/accrue/checkout/session.ex` | exact |
| `accrue/lib/accrue/billing.ex` | interface | request-response | `accrue/lib/accrue/billing.ex` | exact |
| `accrue/lib/accrue/billing/subscription_actions.ex` | backend | request-response | `accrue/lib/accrue/billing/subscription_actions.ex` | exact |
| `accrue/test/accrue/processor/capabilities_test.exs` | test | request-response | `accrue/test/accrue/processor/capabilities_test.exs` | exact |
| `guides/testing-live-stripe.md` | docs | batch | `guides/testing-live-stripe.md` | exact |

## Pattern Assignments

### `accrue/lib/accrue/processor/capabilities.ex`

**Analog:** `accrue/lib/accrue/processor/capabilities.ex`

**Current merge pattern:**

```elixir
declared =
  cond do
    function_exported?(adapter, :capabilities, 0) -> adapter.capabilities()
    true -> %{}
  end

deep_merge(@legacy_default, declared)
```

**Use in Phase 95:** keep the adapter-declaration seam, but change the truth source so first-party support is not inherited from broad legacy defaults. If a compatibility layer is needed, keep it explicit and greppable.

---

### `accrue/lib/accrue/processor.ex`

**Analog:** `accrue/lib/accrue/processor.ex`

**Capability helper pattern:**

```elixir
@spec capabilities() :: map()
def capabilities do
  Accrue.Processor.Capabilities.for(__impl__())
end

@spec supports?(atom() | [atom()]) :: boolean()
def supports?(path) when is_list(path),
  do: Accrue.Processor.Capabilities.supports?(capabilities(), path)
```

**Use in Phase 95:** add any new helper accessors for support labels or staged/proven rows here so public callers stay on one facade seam.

---

### `accrue/lib/accrue/checkout/session.ex`

**Analog:** `accrue/lib/accrue/checkout/session.ex`

**Unsupported-operation precedent:**

```elixir
raise Accrue.APIError,
  code: "processor_operation_unsupported",
  message: "#{Processor.name()} does not support checkout creation"
```

**Use in Phase 95:** mirror the exact error code and message style, but prefer non-bang tuple returns in `Accrue.Billing` and reserve raising behavior for `!` variants.

---

### `accrue/lib/accrue/billing.ex`

**Analog:** `accrue/lib/accrue/billing.ex`

**Facade wrapper pattern:**

```elixir
def create_checkout_session(%Customer{} = customer, attrs) do
  ...
  span_billing(:checkout_session, :create, customer, validated, fn ->
    CheckoutSession.create(Map.new([customer: customer] ++ validated))
  end)
end
```

**Use in Phase 95:** insert first-party support guards at the public facade edge, inside the existing `span_billing` shape where practical, so telemetry and ergonomics remain consistent.

---

### `accrue/lib/accrue/billing/subscription_actions.ex`

**Analog:** `accrue/lib/accrue/billing/subscription_actions.ex`

**Current Stripe-shaped subscribe assembly:**

```elixir
stripe_params =
  %{
    customer: customer.processor_id,
    items: [item_params],
    payment_behavior: "default_incomplete",
    expand: ["latest_invoice.payment_intent"]
  }
```

**Use in Phase 95:** isolate only the supported thin-slice assumptions needed for direct subscription creation. Avoid broad abstraction churn or generic provider-neutral builders that try to solve out-of-scope surfaces.

---

### `accrue/test/accrue/processor/capabilities_test.exs`

**Analog:** `accrue/test/accrue/processor/capabilities_test.exs`

**Focused capability assertions:**

```elixir
caps = Capabilities.for(HostedOnlyProcessor)
assert get_in(caps, [:checkout, :hosted]) == true
refute Capabilities.supports?(caps, [:checkout, :embedded])
```

**Use in Phase 95:** extend this file for staged/proven rows, stricter defaults, and first-party slice leaves. Keep tests narrow and leaf-oriented.

---

### `accrue/test/accrue/checkout/session_test.exs`

**Analog:** `accrue/test/accrue/checkout/session_test.exs`

**Small, shape-focused test style:**

```elixir
session = Session.from_processor(%{...})
assert session.ui_mode == "hosted"
assert session.url == "https://checkout.example/txn_123"
```

**Use in Phase 95:** keep unsupported-operation and projection tests similarly focused rather than building large integration fixtures unless lifecycle projection requires them.

---

### `.planning/processor-support-matrix.md` and verifier pair

**Analog:** current matrix + `scripts/ci/verify_processor_support_matrix.sh`

**Docs-contract coupling pattern:**

```bash
require_substring "subscription.lifecycle_webhook_projection" "subscription lifecycle projection row"
require_substring "Stripe-only" "stripe-only support label"
```

**Use in Phase 95:** whenever support labels or staged/proven wording change, update the matrix and verifier in the same task. Do not let runtime capability work move independently of matrix truth.

---

### `guides/testing-live-stripe.md`

**Analog:** `guides/testing-live-stripe.md`

**Advisory provider-lane wording:**

```markdown
This lane uses Stripe test mode and should be treated as `provider-parity checks`,
not as the canonical local demo or the required release lane.
```

**Use in Phase 95:** any provider-smoke additions should preserve this exact posture. The thin provider lane exists to validate real-provider shape, not to replace Fake as the source of truth.

## Recommended Reuse Rules

- Reuse `Accrue.Checkout.Session` error shapes for unsupported operations, but not its raise-first ergonomics for non-bang billing APIs.
- Reuse `Capabilities.for/1` and `supports?/2` as the capability lookup seam; do not invent a second independent runtime support registry unless the plan explicitly makes one the SSOT.
- Reuse docs-verifier coupling whenever matrix rows, support labels, or lane wording change.
- Reuse focused ExUnit files over broad end-to-end suites until the staged supported slice truly needs lifecycle integration proof.
