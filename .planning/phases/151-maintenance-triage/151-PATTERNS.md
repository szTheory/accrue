# Phase 151: Maintenance & Triage - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/mix.exs` | config | build | `accrue/mix.exs` | exact (self) |
| `accrue_admin/mix.exs` | config | build | `accrue_admin/mix.exs` | exact (self) |
| `accrue_portal/mix.exs` | config | build | `accrue_portal/mix.exs` | exact (self) |
| `accrue/mix.lock` | config | build | `accrue/mix.lock` | exact (self) |
| `accrue_admin/mix.lock` | config | build | `accrue_admin/mix.lock` | exact (self) |
| `accrue_portal/mix.lock` | config | build | `accrue_portal/mix.lock` | exact (self) |
| `accrue/lib/accrue/webhook/default_handler.ex` | handler | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact (self) |
| `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | test | event-driven | `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | exact (self) |

## Pattern Assignments

### `accrue/lib/accrue/webhook/default_handler.ex` (handler, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Core Pattern (Webhook Routing)** (lines 126-137):
```elixir
  def handle_event(
        "entitlements.active_entitlement_summary.updated",
        %Accrue.Webhook.Event{} = event,
        ctx
      ) do
    obj = entitlement_summary_object_from_ctx(ctx)

    case dispatch(event.type, event.processor_event_id, event.created_at, obj) do
      {:ok, _} -> :ok
      other -> other
    end
  end
```

**Core Pattern (Reducer Query)** (lines 513-520):
```elixir
  defp reduce_entitlement_summary_for_customer(evt_id, evt_ts, obj, cus_id, entitlements, data) do
    Repo.transact(fn ->
      case Repo.get_by(Customer, processor_id: cus_id) do
        %Customer{} = customer ->
          row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
```

*(Note for Planner: To resolve ENT-10 scoping collisions, pass `event.processor` into `dispatch` and then into `reduce_entitlement_summary_for_customer`, allowing the query to strictly filter by both `processor: to_string(event.processor)` and `processor_id: cus_id`)*

---

### `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` (test, event-driven)

**Analog:** `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs`

**Core Pattern (Customer Setup)** (lines 35-47):
```elixir
  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_ent_summary",
        email: "ent-summary@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end
```
*(Note for Planner: `processor: "fake"` will fail if the handler correctly scopes to the webhook's `processor: :stripe`. Update this test setup to use `processor: "stripe"`.)*

---

### `mix.exs` & `mix.lock` files (config, build)

**Applies to:** 
- `accrue/mix.exs`, `accrue/mix.lock`
- `accrue_admin/mix.exs`, `accrue_admin/mix.lock`
- `accrue_portal/mix.exs`, `accrue_portal/mix.lock`

*These are standard Elixir dependency files. Modifications are purely version bumps via `mix deps.update --all`, so code patterns are not applicable.*

## Shared Patterns

### Error Handling (Telemetry & Telemetry-Based Ignored States)
**Source:** `accrue/lib/accrue/webhook/default_handler.ex`
**Apply to:** Webhook reducers
```elixir
        not is_binary(cus_id) ->
          emit_summary_malformed(evt_id, :missing_customer)
          {:ok, :ignored}
```

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | | | All phase tasks modify existing files with established patterns. |

## Metadata

**Analog search scope:** `accrue/lib/accrue/webhook/`, `accrue/test/accrue/webhook/`
**Files scanned:** 8
**Pattern extraction date:** 2026-05-29