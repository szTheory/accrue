# Phase 155: StripeFixtures Polish + Telemetry Counters - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/test/support/stripe_fixtures.ex` | utility | transform | `accrue/test/support/webhook_fixtures.ex` | role-match |
| `accrue/lib/accrue/telemetry/metrics.ex` | config | request-response | `accrue/lib/accrue/webhook/default_handler.ex` | flow-match |
| `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | test | request-response | `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | exact |
| `accrue/test/accrue/telemetry/metrics_test.exs` | test | request-response | `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs` | role-match |

## Pattern Assignments

### `accrue/test/support/stripe_fixtures.ex` (utility, transform)

**Analog:** `accrue/test/support/webhook_fixtures.ex`

**Module doc + option list pattern** (`accrue/test/support/webhook_fixtures.ex:2-14`, `:21-31`):
```elixir
@moduledoc """
Test fixtures for webhook payloads. Generates valid Stripe-signed
webhook events using lattice_stripe's test signature helper.
...
## Options

  * `:secret` — signing secret (default: `default_secret/0`)
  * `:timestamp` — Unix timestamp for the signature (default: now)
"""
```

**Optional field assembly pattern** (`accrue/test/support/stripe_fixtures.ex:453-457`, `:470-471`):
```elixir
envelope_overrides =
  %{}
  |> maybe_put("id", Map.get(opts, :id))
  |> maybe_put("created", Map.get(opts, :created))
  |> deep_merge(overrides)

defp maybe_put(map, _key, nil), do: map
defp maybe_put(map, key, value), do: Map.put(map, key, value)
```

**Core fixture composition pattern** (`accrue/test/support/stripe_fixtures.ex:441-451`, `:459-463`):
```elixir
summary_object = %{
  "object" => "entitlements.active_entitlement_summary",
  "customer" => customer,
  "livemode" => livemode,
  "entitlements" => %{"object" => "list", "data" => Enum.map(entitlements, &normalize_entitlement/1), "has_more" => has_more, "url" => url}
}

webhook_event("entitlements.active_entitlement_summary.updated", summary_object, envelope_overrides)
```

---

### `accrue/lib/accrue/telemetry/metrics.ex` (config, request-response)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Telemetry metric declaration pattern** (`accrue/lib/accrue/telemetry/metrics.ex:61-63`, `:68-89`):
```elixir
counter("accrue.webhooks.received.count", tags: [:type]),
counter("accrue.webhooks.dispatched.count", tags: [:status]),
last_value("accrue.webhooks.queue_depth"),
...
counter("accrue.ops.entitlement_summary_truncated.count"),
counter("accrue.entitlements.summary_synced.count", tags: [:result]),
```

**Emit/metric tuple alignment pattern** (`accrue/lib/accrue/webhook/default_handler.ex:569-573`, `:785-789`):
```elixir
:telemetry.execute(
  [:accrue, :webhooks, :orphan_entitlement_summary],
  %{},
  %{customer_stripe_id: cus_id}
)

:telemetry.execute(
  [:accrue, :webhooks, :malformed_entitlement_summary],
  %{},
  %{event_id: evt_id, reason: reason}
)
```

**Cardinality guard pattern** (`accrue/lib/accrue/telemetry/metrics.ex:33-38`):
```elixir
Tags on the default counters are restricted to low-cardinality fields
(`:status`, `:source`, `:type`, `:stripe_status`). Customer ID,
subscription ID, and other unbounded identifiers are NEVER promoted to
metric tags
```

---

### `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs`

**Fixture-driven event setup pattern** (`accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs:458-462`):
```elixir
raw =
  StripeFixtures.entitlement_summary_event(
    [customer: customer.processor_id],
    %{"id" => "evt_pol02_second", "created" => DateTime.to_unix(ts_second)}
  )
```

**Current absence modeling to replace with new fixture option** (`accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs:464-470`):
```elixir
event_without_livemode = update_in(raw, ["data", "object"], &Map.delete(&1, "livemode"))

assert {:ok, %EntitlementSummary{} = saved} =
         Accrue.Webhook.DefaultHandler.handle(event_without_livemode)
```

**Telemetry assertion pattern** (`accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs:218-222`, `:227-229`):
```elixir
:telemetry.attach("test-ent-orphan-...", [:accrue, :webhooks, :orphan_entitlement_summary], fn evt, meas, meta, _ ->
  send(test_pid, {:orphan, evt, meas, meta})
end, nil)

assert_received {:orphan, _, _, %{customer_stripe_id: "cus_does_not_exist"}}
```

---

### `accrue/test/accrue/telemetry/metrics_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs`

**Event-name tuple presence assertion pattern** (`accrue/test/accrue/telemetry/metrics_ops_parity_test.exs:14-17`):
```elixir
for tuple <- TelemetryOpsInventory.expected_ops_events() do
  assert Enum.any?(defs, &(&1.event_name == tuple)),
         "missing Telemetry.Metrics default for ops event #{inspect(tuple)} ..."
end
```

**Existing helper style in target test** (`accrue/test/accrue/telemetry/metrics_test.exs:53-60`):
```elixir
defp has_metric?(name) do
  Enum.any?(M.defaults(), fn d -> metric_name_to_string(d.name) == name end)
end

defp metric_name_to_string(name) when is_list(name),
  do: name |> Enum.map(&Atom.to_string/1) |> Enum.join(".")
```

**Struct-field validation pattern** (`accrue/test/accrue/telemetry/metrics_test.exs:13-18`):
```elixir
for def <- M.defaults() do
  assert Map.has_key?(def, :name)
  assert Map.has_key?(def, :event_name)
end
```

## Shared Patterns

### Fixture option precedence and map shaping
**Source:** `accrue/test/support/stripe_fixtures.ex:423-451`, `:470-471`  
**Apply to:** Fixture option addition in `entitlement_summary_event/2`
```elixir
opts = Enum.into(opts, %{})
livemode = Map.get(opts, :livemode, false)
summary_object = %{"livemode" => livemode, ...}
defp maybe_put(map, _key, nil), do: map
```

### Telemetry emit tuple -> defaults event_name parity
**Source:** `accrue/lib/accrue/webhook/default_handler.ex:569-573`, `:785-789`; `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs:15`  
**Apply to:** Add default counters + tuple-based assertions
```elixir
:telemetry.execute([:accrue, :webhooks, :orphan_entitlement_summary], %{}, %{...})
assert Enum.any?(defs, &(&1.event_name == tuple))
```

### Low-cardinality metric tagging
**Source:** `accrue/lib/accrue/telemetry/metrics.ex:33-43`, `:72`, `:75`, `:83`, `:89`  
**Apply to:** malformed summary counter uses `tags: [:reason]`; orphan counter untagged
```elixir
counter("...", tags: [:source])
counter("...", tags: [:result])
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `accrue/test/support`, `accrue/lib/accrue/telemetry`, `accrue/lib/accrue/webhook`, `accrue/test/accrue/telemetry`, `accrue/test/accrue/webhook`  
**Files scanned:** 9  
**Pattern extraction date:** 2026-05-31

