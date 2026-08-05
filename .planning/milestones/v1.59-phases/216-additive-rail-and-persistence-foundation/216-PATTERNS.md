# Phase 216: Additive rail and persistence foundation - Pattern Map

**Mapped:** 2026-08-02  
**Files analyzed:** 12 planned new/modified files  
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/config.ex` | config | transform | `accrue/lib/accrue/config.ex` | exact-extension |
| `accrue/lib/accrue/entitlements/account.ex` | model | CRUD | `accrue/lib/accrue/billing/customer.ex` | exact-role |
| `accrue/lib/accrue/entitlements/grant.ex` | model | CRUD | `accrue/lib/accrue/billing/customer.ex` | role-match |
| `accrue/lib/accrue/entitlements/observation.ex` | model | event-driven | `accrue/lib/accrue/webhook/webhook_event.ex` | exact-data-flow |
| `accrue/lib/accrue/entitlements/device.ex` | model | CRUD | `accrue/lib/accrue/billing/customer.ex` | role-match |
| `accrue/priv/repo/migrations/*_create_accrue_entitlement_persistence.exs` | migration | CRUD | `accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs` | exact-role |
| `accrue/priv/accrue/templates/install/runtime_config.exs.eex` | config | transform | `accrue/lib/accrue/install/templates.ex` | role-match |
| `accrue/test/accrue/config_entitlements_test.exs` | test | transform | `accrue/test/accrue/config_entitlements_test.exs` | exact-extension |
| `accrue/test/accrue/entitlements/persistence_test.exs` | test | CRUD | `accrue/test/accrue/events/record_test.exs` | data-flow-match |
| `accrue/test/accrue/entitlements/fake_fixture_test.exs` | test | event-driven | `accrue/test/accrue/entitlements/decision_cases_test.exs` | role-match |
| `accrue/test/mix/tasks/accrue_install_test.exs` | test | file-I/O | `accrue/test/mix/tasks/accrue_install_test.exs` | exact-extension |
| `accrue/lib/accrue/install/templates.ex` | utility | file-I/O | `accrue/lib/accrue/install/templates.ex` | exact-extension |

The migration filename and whether all four tables share it are planner discretion. The existing installer automatically copies every `priv/repo/migrations/*.exs`, so adding the migration is already propagated by `Templates.migration_templates/2`.

## Pattern Assignments

### `accrue/lib/accrue/config.ex` (config, transform)

**Analog:** same file, entitlement schema and cross-plan guard.

**Nested NimbleOptions schema** ([lines 454-479](../../../accrue/lib/accrue/config.ex)):

```elixir
entitlements: [
  type: :keyword_list,
  default: [],
  keys: [
    plans: [
      type: :keyword_list,
      default: [],
      keys: [*: [type: :keyword_list, keys: [
        features: [type: {:list, :atom}, default: []],
        limits: [type: :keyword_list, default: [], keys: [*: [type: :pos_integer]]],
        price_ids: [type: {:list, :string}, default: []]
      ]]]
    ]
  ]
]
```

Extend this existing `:entitlements` shape with nested qualified products; add top-level additive `:rails`/`:default_rail` beside the retained `:processor`, never replace it.

**Runtime catalog access and boot guard** ([lines 1141-1185](../../../accrue/lib/accrue/config.ex), [1193-1219](../../../accrue/lib/accrue/config.ex)):

```elixir
def entitlements do
  :entitlements
  |> get!()
  |> Keyword.put_new(:billable, nil)
  |> Keyword.put_new(:on_deny, :forbidden)
  |> Keyword.put_new(:deny_path, "/")
end

_ = validate_entitlements_price_ids!(opts)

Enum.reduce(plans, %{}, fn {plan, entry}, seen ->
  entry
  |> Keyword.get(:price_ids, [])
  |> Enum.reduce(seen, fn price_id, acc ->
    case Map.fetch(acc, price_id) do
      {:ok, ^plan} -> acc
      {:ok, other_plan} ->
        raise Accrue.ConfigError, key: :entitlements,
          message: "price_id #{inspect(price_id)} mapped to both #{inspect(other_plan)} and #{inspect(plan)}"
      :error -> Map.put(acc, price_id, plan)
    end
  end)
end)
```

Replace/extend only the reducer input: normalize bare `price_ids` to the configured default `{rail, environment, product_id}` and reduce the full qualified catalog. Preserve same-plan repeats, and raise `Accrue.ConfigError` with both plans plus the complete tuple.

**Closed vocabulary source:** `accrue/lib/accrue/entitlements/decision_cases.ex` [lines 4-7, 91-95] defines `@rails [:stripe, :apple]` and the allowed environments. Use this authority rather than accepting arbitrary atoms. `Source.Registry` [lines 7-25] provides the related deterministic registry-validation shape.

---

### `accrue/lib/accrue/entitlements/account.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/customer.ex`.

**Schema, UUID, typed timestamps, and named constraint** ([lines 36-98](../../../accrue/lib/accrue/billing/customer.ex)):

```elixir
use Accrue.Schema
import Ecto.Changeset

@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "accrue_customers" do
  field(:owner_type, :string)
  field(:owner_id, :string)
  field(:lock_version, :integer, default: 1)
  timestamps(type: :utc_datetime_usec)
end

customer_or_changeset
|> cast(attrs, @cast_fields)
|> validate_required(@required_fields)
|> unique_constraint(:owner_id,
  name: :accrue_customers_owner_type_owner_id_processor_index
)
```

Copy the module setup, but make the durable account unique only on `owner_type, owner_id`, initialize revision to zero, and do not derive its UUID from owner fields or introduce Phase-217 writes.

---

### `accrue/lib/accrue/entitlements/grant.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/customer.ex` plus partial-index migration precedent below.

Copy `Accrue.Schema`, `:binary_id`, explicit cast/required field lists, and named `unique_constraint/3` pattern from `Customer` [lines 36-98]. The changeset must name the current-row composite index and account FK constraint; model history via `superseded_at` rather than deletes/global uniqueness.

---

### `accrue/lib/accrue/entitlements/observation.ex` (model, event-driven)

**Analog:** `accrue/lib/accrue/webhook/webhook_event.ex`.

**Narrow ingest changeset and idempotency constraint** ([lines 29-79](../../../accrue/lib/accrue/webhook/webhook_event.ex)):

```elixir
use Accrue.Schema
import Ecto.Changeset

@primary_key {:id, :binary_id, autogenerate: true}

@ingest_fields ~w[processor processor_event_id type livemode endpoint raw_body received_at data]a
@ingest_required ~w[processor processor_event_id type]a

def ingest_changeset(attrs) when is_map(attrs) do
  %__MODULE__{}
  |> cast(attrs, @ingest_fields)
  |> validate_required(@ingest_required)
  |> unique_constraint([:processor, :processor_event_id],
    name: :accrue_webhook_events_processor_event_id_index
  )
end
```

Use a dedicated `ingest_changeset/1` with rail/environment-scoped event identity and a second transaction-plus-kind fallback constraint. Unlike this analog, never add raw body/JWS/receipt fields: only bounded redacted metadata, digest, and optional opaque evidence reference/expiry.

---

### `accrue/lib/accrue/entitlements/device.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/customer.ex`.

Use the same `Accrue.Schema` / binary UUID / changeset constraint pattern [lines 36-98]. Tie each current identity key to `account_id`; map both account FK and named partial current-registration index in the changeset. Preserve prior rows by setting a revocation/supersession timestamp.

---

### `accrue/priv/repo/migrations/*_create_accrue_entitlement_persistence.exs` (migration, CRUD)

**Analogs:** `20260412100001_create_accrue_customers.exs` and `20260412100003_create_accrue_webhook_events.exs`.

**Prefix-safe table and named unique index** ([customers lines 7-32](../../../accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs)):

```elixir
use Ecto.Migration

def change do
  create Accrue.Migration.table(:accrue_customers, primary_key: false) do
    add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))
    add(:owner_type, :string, null: false)
    add(:owner_id, :string, null: false)
    timestamps(type: :utc_datetime_usec)
  end

  create(
    Accrue.Migration.unique_index(:accrue_customers, [:owner_type, :owner_id, :processor],
      name: :accrue_customers_owner_type_owner_id_processor_index
    )
  )
end
```

**Partial-index syntax** ([webhook lines 38-43](../../../accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs)):

```elixir
create(
  Accrue.Migration.index(:accrue_webhook_events, [:status],
    where: "status IN ('failed', 'dead')",
    name: :accrue_webhook_events_failed_dead_index
  )
)
```

All new tables/foreign keys/indexes must use `Accrue.Migration.table/references/index/unique_index`, explicit stable names, UUID defaults, and `:utc_datetime_usec`. Create account, grant, observation, and device tables additively in `change/0`; do not alter existing customer/subscription/webhook tables. Use partial unique indexes for current grants/devices and the two observation identities.

---

### Installer config/templates (file-I/O)

**Files:** `accrue/priv/accrue/templates/install/runtime_config.exs.eex`, `accrue/lib/accrue/install/templates.ex`, and `accrue/test/mix/tasks/accrue_install_test.exs`.

**Analog:** `accrue/lib/accrue/install/templates.ex` [lines 18-25, 123-138].

```elixir
[{project.runtime_config_path, render("runtime_config.exs.eex", assigns)}] ++
  migration_templates(project, assigns)

@migration_root Path.expand("../../../priv/repo/migrations", __DIR__)

copied =
  @migration_root
  |> Path.join("*.exs")
  |> Path.wildcard()
  |> Enum.map(fn path ->
    {Path.join(project.migrations_path, Path.basename(path)), File.read!(path)}
  end)
```

Add the canonical additive rails/catalog example to the runtime template only if it remains opt-in and keeps the legacy processor example valid. Do not write bespoke migration-copy logic: the wildcard copier delivers the new migration. Extend installer tests with `InstallFixture.assert_contains!/3`, as used by `accrue_install_test.exs` [lines 34-96], to assert generated config/migration propagation.

---

### Entitlement tests (config transform, persistence CRUD, fake fixtures event-driven)

**Config analog:** `accrue/test/accrue/config_entitlements_test.exs` uses direct `Application.put_env/3` followed by `Config.validate_at_boot!/0` (for example lines 228-272).

```elixir
Application.put_env(:accrue, :entitlements, plans: [pro: [features: [:api_access]]])
assert Config.validate_at_boot!() == :ok
```

Follow its existing app-env setup/restore style. Cover legacy-only compatibility, registered default rail agreement, collision rejection, alias-vs-qualified conflicts, and permitted same raw ID across different rail/environment tuples.

**Persistence test harness:** `accrue/test/support/repo_case.ex` [lines 16-31].

```elixir
use ExUnit.CaseTemplate

using do
  quote do
    alias Accrue.TestRepo
    import Ecto
    import Ecto.Changeset
    import Ecto.Query
  end
end

setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  :ok
end
```

Use `Accrue.RepoCase, async: false` for real constraint/index checks. For an idempotent insert/count assertion, copy `accrue/test/accrue/events/record_test.exs` [lines 109-137]: submit two transactions, query with `Ecto.Query`, and assert only one row exists.

**Fixture vocabulary:** `accrue/lib/accrue/entitlements/decision_cases.ex` [lines 136-177] builds deterministic fixtures from keyword options, and `decision_cases_test.exs` [lines 7-13] asserts stable sorted unique fixture identifiers. Fake fixture tests should source Stripe/Apple and production/sandbox from that closed vocabulary; no live processor, sandbox, Crosswake, or device dependency.

## Shared Patterns

### Schema prefix, opaque UUIDs, and timestamps

**Source:** `accrue/lib/accrue/schema.ex` [lines 10-19] and `accrue/lib/accrue/migration.ex` [lines 12-35].  
**Apply to:** all four schemas and the new migration.

```elixir
use Ecto.Schema
@schema_prefix billing_schema

def table(name, opts \\ []) do
  Ecto.Migration.table(name, Keyword.put_new(opts, :prefix, billing_prefix()))
end

def unique_index(table, columns, opts \\ []) do
  Ecto.Migration.unique_index(table, columns, Keyword.put_new(opts, :prefix, billing_prefix()))
end
```

### Constraint authority and error surfacing

**Source:** `Customer.changeset/2` [lines 89-98] and `WebhookEvent.ingest_changeset/1` [lines 71-79].  
**Apply to:** all database identity invariants.

Define explicit migration names, then repeat each in `unique_constraint/3` / `foreign_key_constraint/2`. Do not add application prechecks as the concurrency guard.

### Privacy boundary

**Source contrast:** `WebhookEvent` documents raw-body storage at [lines 15-20](../../../accrue/lib/accrue/webhook/webhook_event.ex), but Phase 216 observations explicitly must not reuse it.  
**Apply to:** observation schema, fixtures, error messages, logs, and telemetry.

Observations may contain redacted/bounded `data`, evidence digest, and a nullable opaque reference/expiry only; never raw receipt/JWS/notification body or PII.

## No Analog Found

None. The exact entitlement persistence model is new, but all implementation mechanisms have direct, current analogs.

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue/lib/mix/tasks`, `accrue/priv/repo/migrations`, `accrue/test`  
**Files scanned:** 14 primary analog/configuration files plus migration/test candidate search  
**Pattern extraction date:** 2026-08-02
