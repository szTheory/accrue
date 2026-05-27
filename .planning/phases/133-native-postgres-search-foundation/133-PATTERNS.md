# Phase 133: Native Postgres Search Foundation - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/priv/repo/migrations/[timestamp]_add_pg_trgm_and_search_indices.exs` | migration | N/A | `accrue/examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs` | role-match |
| `accrue/lib/accrue/billing.ex` | facade | request-response | `accrue/lib/accrue/billing.ex` | exact |
| `accrue/lib/accrue/billing/search.ex` | service | request-response | `accrue/lib/accrue/billing/payment_method_actions.ex` | role-match |

## Pattern Assignments

### `accrue/priv/repo/migrations/[timestamp]_add_pg_trgm_and_search_indices.exs` (migration, N/A)

**Analog:** `accrue/examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs`

**Extension pattern** (lines 4-5):
```elixir
  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
```

**Index pattern** (from `accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs` lines 29-30):
```elixir
    create index(:accrue_customers, [:processor_id])
    create index(:accrue_customers, [:processor])
```
*(Planner note: Need to add `using: "GIN"` and specific `pg_trgm` operators to these indices.)*

---

### `accrue/lib/accrue/billing.ex` (facade, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Facade pattern** (lines 401-405):
```elixir
  def list_payment_methods(customer, opts \\ []) do
    span_billing(:payment_method, :list, customer, opts, fn ->
      PaymentMethodActions.list_payment_methods(customer, opts)
    end)
  end
```

---

### `accrue/lib/accrue/billing/search.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing/payment_method_actions.ex`

**Imports pattern** (lines 20-22):
```elixir
  import Ecto.Query, only: [from: 2]

  alias Accrue.Repo
```

**Function pattern** (lines 463-466):
```elixir
  def list_payment_methods(%Customer{} = customer, opts \\ []) when is_list(opts) do
    NimbleOptions.validate!(opts, @list_payment_methods_opts_schema)
    {:ok, local_payment_methods(customer)}
  end
```

---

## Shared Patterns

### Telemetry Spans
**Source:** `accrue/lib/accrue/billing.ex`
**Apply to:** `Accrue.Billing` facade search methods
```elixir
    span_billing(:search, :query, query, opts, fn ->
      # Delegate to Search module
    end)
```

## Metadata

**Analog search scope:** `accrue/lib/accrue/billing/*.ex`, `accrue/priv/repo/migrations/*.exs`
**Files scanned:** 43 context files, 29 migration files
**Pattern extraction date:** 2024-05-24