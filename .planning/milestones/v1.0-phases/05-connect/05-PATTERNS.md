# Phase 5: Connect - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 18 new + 5 modified
**Analogs found:** 23 / 23 (every Phase 5 file has a verbatim or near-verbatim analog in the Phase 1-4 codebase)

## Summary

Phase 5 is structurally additive: every locked decision (D5-01..D5-06) mirrors a pattern that already shipped in Phases 1-4. Pattern mapping coverage is 100%. The Critical Finding from research (webhook event `endpoint` column gap) maps cleanly to the existing `add_*_columns_to_*` Phase 4 migration shape, the `WebhookEvent` schema, and the `Ingest`/`DispatchWorker` pair.

## File Classification

### NEW files (18)

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/connect.ex` | context (facade) | request-response | `accrue/lib/accrue/billing.ex` + `accrue/lib/accrue/stripe.ex` | exact (composite) |
| `accrue/lib/accrue/connect/account.ex` | model (Ecto schema) | CRUD + webhook reducer | `accrue/lib/accrue/billing/subscription.ex` | exact |
| `accrue/lib/accrue/connect/account_link.ex` | value module (credential struct) | request-response | `accrue/lib/accrue/billing_portal/session.ex` | exact |
| `accrue/lib/accrue/connect/login_link.ex` | value module (credential struct) | request-response | `accrue/lib/accrue/billing_portal/session.ex` | exact |
| `accrue/lib/accrue/connect/projection.ex` | utility (mapper) | transform | `accrue/lib/accrue/billing/subscription_projection.ex` | exact |
| `accrue/lib/accrue/connect/platform_fee.ex` (or inlined in connect.ex) | utility (pure value) | transform | `accrue/lib/accrue/money.ex` + `Accrue.Config` schema | role-match |
| `accrue/lib/accrue/plug/put_connected_account.ex` | middleware (Plug) | request-response | `accrue/lib/accrue/plug/put_operation_id.ex` | exact |
| `accrue/lib/accrue/webhook/connect_handler.ex` | webhook handler | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |
| `accrue/priv/repo/migrations/20260415xxxxxx_create_accrue_connect_accounts.exs` | migration (create table) | CRUD | `accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs` | exact |
| `accrue/priv/repo/migrations/20260415xxxxxx_add_endpoint_to_accrue_webhook_events.exs` | migration (alter table) | CRUD | `accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs` | exact |
| `accrue/test/support/connect_case.ex` | test support | test setup | `accrue/test/support/billing_case.ex` | exact |
| `accrue/test/support/connect_fixtures.ex` (or inlined factory) | test support (fixtures) | test setup | `accrue/test/support/stripe_fixtures.ex` | exact |
| `accrue/test/accrue/connect/account_test.exs` | test (unit) | test | existing `test/accrue/billing/*_test.exs` patterns | exact |
| `accrue/test/accrue/connect/account_link_test.exs` | test (unit + Inspect) | test | existing `test/accrue/billing_portal/session_test.exs` (Inspect masking precedent) | exact |
| `accrue/test/accrue/connect/login_link_test.exs` | test (unit + Inspect) | test | same as account_link_test | exact |
| `accrue/test/accrue/connect/charges_test.exs` | test (unit, Mox boundary) | test | existing `test/accrue/billing/charge_*_test.exs` | exact |
| `accrue/test/accrue/connect/platform_fee_test.exs` | test (unit + StreamData) | test | existing money property tests under `test/property/` | role-match |
| `accrue/test/accrue/webhook/connect_handler_test.exs` | test (integration) | test | existing `test/accrue/webhook/default_handler_test.exs` | exact |

### MODIFIED files (5)

| Modified File | Role | Change Type | Closest In-File Analog | Match Quality |
|---------------|------|-------------|------------------------|---------------|
| `accrue/lib/accrue/processor/stripe.ex` | adapter | add `resolve_stripe_account/1` + extend `build_client!/1` | `resolve_api_version/1` (lines 820-825) + `build_client!/1` (lines 831-854) | exact (sibling fn) |
| `accrue/lib/accrue/processor.ex` | behaviour | add Connect callbacks (`create_account/2`, `retrieve_account/2`, `update_account/3`, `delete_account/2`, `reject_account/3`, `list_accounts/2`, `create_account_link/2`, `create_login_link/2`, `create_transfer/2`, `retrieve_transfer/2`) | existing customer/subscription/invoice callback blocks (lines 73-130) | exact |
| `accrue/lib/accrue/processor/fake.ex` | adapter (test) | add Connect lifecycle + scope ETS keyspace on `{stripe_account, type}` | existing customer/subscription Fake clauses | exact |
| `accrue/lib/accrue/oban/middleware.ex` | middleware | extend `put/1` to also stash `stripe_account` | existing operation_id put logic | exact (sibling pattern) |
| `accrue/lib/accrue/config.ex` | config | add `:connect` key (`default_stripe_account`, `platform_fee` schema) | existing `:dunning`, `:webhook_endpoints` schema entries (lines 174-217) | exact |
| `accrue/lib/accrue/webhook/webhook_event.ex` | model | add `field :endpoint, Ecto.Enum, values: [...]` + thread through `ingest_changeset/1` | existing `:status` Ecto.Enum field (line 43) | exact |
| `accrue/lib/accrue/webhook/ingest.ex` | service | thread `endpoint` from plug call into `ingest_changeset` | existing changeset construction (lines 63-73) | exact |
| `accrue/lib/accrue/webhook/dispatch_worker.ex` | worker | branch `handler` on `ctx.endpoint` (read from row) | existing handler dispatch (lines 56-62) | exact |
| `accrue/lib/accrue/webhook/plug.ex` | plug | already has `endpoint` from Phase 4 — pass into `Ingest.run/4` (currently dropped) | existing `do_call/3` (lines 52-66) | exact |

---

## Pattern Assignments

### `accrue/lib/accrue/connect.ex` (context facade, request-response)

**Composite analog.** Three sources:

1. **Pdict scoped block** — copy verbatim from `accrue/lib/accrue/stripe.ex:30-44`:

```elixir
@spec with_api_version(String.t(), (-> result)) :: result when result: var
def with_api_version(version, fun) when is_binary(version) and is_function(fun, 0) do
  old = Process.get(:accrue_stripe_api_version)
  Process.put(:accrue_stripe_api_version, version)

  try do
    fun.()
  after
    if old do
      Process.put(:accrue_stripe_api_version, old)
    else
      Process.delete(:accrue_stripe_api_version)
    end
  end
end
```

For Phase 5 substitute the pdict key `{:accrue, :connected_account_id}` (or `:accrue_connected_account_id` for symmetry with `:accrue_stripe_api_version`) and rename to `with_account/2`.

2. **Pdict reader** — copy from `accrue/lib/accrue/actor.ex:79-82`:

```elixir
@spec current_operation_id() :: String.t() | nil
def current_operation_id do
  Process.get(:accrue_operation_id)
end
```

Becomes `current_account_id/0`.

3. **defdelegate-heavy facade** — copy from `accrue/lib/accrue/billing.ex:58-78`:

```elixir
defdelegate subscribe(user, price_id_or_opts \\ [], opts \\ []), to: SubscriptionActions
defdelegate subscribe!(user, price_id_or_opts \\ [], opts \\ []), to: SubscriptionActions
```

Phase 5 may keep the actions inline (Connect surface is small enough not to need a `ConnectActions` module split), but the dual bang/tuple pair-per-function rhythm is identical.

**Dual bang/tuple pattern** — copy from `accrue/lib/accrue/billing_portal/session.ex:62-91`:

```elixir
@spec create(map() | keyword()) :: {:ok, t()} | {:error, term()}
def create(params) when is_list(params), do: create(Map.new(params))

def create(params) when is_map(params) do
  opts = NimbleOptions.validate!(Map.to_list(params), @create_schema)
  {stripe_params, request_opts} = build_params(opts)

  case Processor.__impl__().portal_session_create(stripe_params, request_opts) do
    {:ok, stripe_session} -> {:ok, from_stripe(stripe_session)}
    {:error, err} -> {:error, err}
  end
end

@spec create!(map() | keyword()) :: t()
def create!(params) do
  case create(params) do
    {:ok, session} -> session
    {:error, err} when is_exception(err) -> raise err
    {:error, other} -> raise "Accrue.BillingPortal.Session.create/1 failed: #{inspect(other)}"
  end
end
```

---

### `accrue/lib/accrue/connect/account.ex` (Ecto schema, CRUD + webhook reducer)

**Analog:** `accrue/lib/accrue/billing/subscription.ex`

**Schema header pattern** (lines 25-74):

```elixir
use Ecto.Schema
import Ecto.Changeset

@statuses [:trialing, :active, :past_due, :canceled, :unpaid, :incomplete, :incomplete_expired, :paused]

@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "accrue_subscriptions" do
  belongs_to :customer, Accrue.Billing.Customer

  field :processor, :string
  field :processor_id, :string
  field :status, Ecto.Enum, values: @statuses
  # ...
  field :metadata, :map, default: %{}
  field :data, :map, default: %{}
  field :lock_version, :integer, default: 1
  has_many :subscription_items, Accrue.Billing.SubscriptionItem
  timestamps(type: :utc_datetime_usec)
end
```

For Connect Account: substitute `@types ["standard", "express", "custom"]`, the columns from D5-02, no FK to customer (use `owner_type`/`owner_id` polymorphic per D2-01/02 — see also `accrue/lib/accrue/billing/customer.ex:46-47`).

**Webhook-path `force_status_changeset/2`** (D3-17) — copy from `subscription.ex:88-100`:

```elixir
@doc """
Webhook-path changeset (D3-17). Skips user-path validation guards so
out-of-order webhook events can settle arbitrary state without the
state-machine check failing on an otherwise-valid transition.
"""
@spec force_status_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
def force_status_changeset(subscription_or_changeset, attrs \\ %{}) do
  subscription_or_changeset
  |> cast(attrs, @cast_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
  |> foreign_key_constraint(:customer_id)
end
```

For Account: drop `Metadata.validate_metadata` (capabilities is jsonb, not Stripe-metadata-shaped) and the customer FK constraint. Keep optimistic lock.

**User-path `changeset/2`** — copy from `subscription.ex:106-117`:

```elixir
@spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
def changeset(subscription_or_changeset, attrs \\ %{}) do
  subscription_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
  |> foreign_key_constraint(:customer_id)
end
```

For Account: add `validate_inclusion(:type, ["standard", "express", "custom"])` and `unique_constraint(:stripe_account_id)`.

**Predicates pattern (D3-04)** — copy from `subscription.ex:124-192`:

```elixir
@doc "True if the subscription is currently in a trial."
@spec trialing?(%__MODULE__{} | map()) :: boolean()
def trialing?(%__MODULE__{status: :trialing}), do: true
def trialing?(%{status: :trialing}), do: true
def trialing?(_), do: false
```

For Account: `charges_enabled?/1`, `payouts_enabled?/1`, `details_submitted?/1`, `fully_onboarded?/1`, `deauthorized?/1`. Each clause matches `%__MODULE__{}`, then a bare `%{}` map fallback (lets predicates work on raw Stripe payloads), then catch-all `false`.

---

### `accrue/lib/accrue/connect/account_link.ex` & `login_link.ex` (credential struct, request-response)

**Analog:** `accrue/lib/accrue/billing_portal/session.ex` — verbatim.

**Struct + enforce_keys** (lines 28-44):

```elixir
@enforce_keys [:id]
defstruct [
  :id,
  :object,
  :customer,
  :url,
  :return_url,
  # ...
]

@type t :: %__MODULE__{}
```

For `AccountLink`: `@enforce_keys [:url, :expires_at, :created, :object]`. For `LoginLink`: `@enforce_keys [:url, :created]`.

**`from_stripe/1` constructor** (lines 94-110):

```elixir
@doc false
@spec from_stripe(map()) :: t()
def from_stripe(stripe) when is_map(stripe) do
  %__MODULE__{
    id: get(stripe, :id),
    object: get(stripe, :object) || "billing_portal.session",
    # ...
    data: stripe
  }
end

defp get(%{} = map, key) when is_atom(key) do
  Map.get(map, key) || Map.get(map, Atom.to_string(key))
end

defp get(_, _), do: nil
```

The dual-key fallback (`Map.get(map, key) || Map.get(map, Atom.to_string(key))`) is mandatory — Fake adapter returns atom-keyed maps; Stripe adapter returns string-keyed maps after `Map.from_struct`. Phase 5 must follow this exactly, and the projection module shares the helper.

**`defimpl Inspect` masking** (lines 149-178) — **THE canonical pattern for D5-06**:

```elixir
defimpl Inspect, for: Accrue.BillingPortal.Session do
  import Inspect.Algebra

  # T-04-07-01: `:url` is a single-use, short-lived (~5 min) bearer
  # credential that impersonates the customer in the portal until it
  # expires. Any leak via Logger / APM / crash dumps / telemetry
  # handlers is an account-takeover vector. Mask it in Inspect output
  # the same way Phase 2 masks WebhookEvent.raw_body.
  def inspect(%Accrue.BillingPortal.Session{} = session, opts) do
    fields = [
      id: session.id,
      object: session.object,
      customer: session.customer,
      url: if(session.url, do: "<redacted>", else: nil),
      return_url: session.return_url,
      configuration: session.configuration,
      locale: session.locale,
      livemode: session.livemode
    ]

    pairs =
      fields
      |> Enum.map(fn {k, v} ->
        concat([Atom.to_string(k), ": ", to_doc(v, opts)])
      end)
      |> Enum.intersperse(", ")

    concat(["#Accrue.BillingPortal.Session<" | pairs] ++ [">"])
  end
end
```

Phase 5 copies this verbatim, swapping the field list and the module name. For `AccountLink`: `[url: if(s.url, do: "<redacted>"), expires_at: s.expires_at, created: s.created, object: s.object]`. For `LoginLink`: `[url: if(s.url, do: "<redacted>"), created: s.created]`.

**NimbleOptions create schema** (lines 46-57) — copy for `create_account_link/2` opts validation:

```elixir
@create_schema [
  customer: [type: {:or, [:string, {:struct, Customer}]}, required: true],
  return_url: [type: {:or, [:string, nil]}, default: nil],
  configuration: [type: {:or, [:string, nil]}, default: nil],
  flow_data: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
  locale: [type: {:or, [:string, nil]}, default: nil],
  on_behalf_of: [type: {:or, [:string, nil]}, default: nil],
  operation_id: [type: {:or, [:string, nil]}, default: nil]
]
```

For `create_account_link/2`: `:return_url` and `:refresh_url` BOTH `required: true` (per D5-06), plus `:type` with `default: "account_onboarding"` and `:collect` with `default: "currently_due"`.

---

### `accrue/lib/accrue/connect/projection.ex` (mapper, transform)

**Analog:** `accrue/lib/accrue/billing/subscription_projection.ex`

**Decomposer pattern** (lines 14-32):

```elixir
@spec decompose(map()) :: {:ok, map()}
def decompose(stripe_sub) when is_map(stripe_sub) do
  {:ok,
   %{
     processor_id: get(stripe_sub, :id),
     status: parse_status(get(stripe_sub, :status)),
     cancel_at_period_end: get(stripe_sub, :cancel_at_period_end) || false,
     # ...
     data: normalize_data(stripe_sub),
     metadata: get(stripe_sub, :metadata) || %{}
   }}
end
```

For Connect Account: extract `stripe_account_id`, `type`, `country`, `email`, `charges_enabled`, `details_submitted`, `payouts_enabled`, `capabilities` (jsonb verbatim), `requirements` (jsonb verbatim), full `data`. Use the same `get/2` dual-key helper (lines 45-47) to handle atom vs string keys from Fake vs Stripe.

---

### `accrue/lib/accrue/plug/put_connected_account.ex` (middleware Plug, request-response)

**Analog:** `accrue/lib/accrue/plug/put_operation_id.ex` — verbatim shape.

**Behaviour boilerplate** (lines 33-49):

```elixir
@behaviour Plug

import Plug.Conn

@impl true
def init(opts), do: opts

@impl true
def call(conn, _opts) do
  id =
    conn.assigns[:request_id] ||
      conn |> get_req_header("x-request-id") |> List.first() |> sanitize_header_id() ||
      "http-" <> random_id()

  Accrue.Actor.put_operation_id(id)
  conn
end
```

For `PutConnectedAccount`: per the CONTEXT.md `from: {Mod, :fun, args}` MFA opt pattern, `init/1` validates the MFA tuple, `call/2` invokes `apply(mod, fun, args)` and stashes the result via `Accrue.Connect.put_account_id/1` (or by direct `Process.put`). Drop the request_id sanitization branch — connected account ids come from server-trusted code, not headers.

---

### `accrue/lib/accrue/webhook/connect_handler.ex` (webhook handler, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Module shape** (lines 44-104):

```elixir
use Accrue.Webhook.Handler

require Logger

alias Accrue.{Events, Processor, Repo}

alias Accrue.Billing.{
  Charge,
  Customer,
  # ...
}

# ---------------------------------------------------------------------
# Phase 2 customer path (preserved)
# ---------------------------------------------------------------------

def handle_event("customer.created", event, _ctx) do
  Logger.debug("DefaultHandler: customer.created for #{event.object_id}")
  :ok
end

# ---------------------------------------------------------------------
# Phase 3 event families — dispatch from Accrue.Webhook.Event struct
# ---------------------------------------------------------------------

def handle_event(type, %Accrue.Webhook.Event{object_id: nil}, _ctx) when is_binary(type) do
  :telemetry.execute([:accrue, :webhooks, :missing_object_id], %{}, %{type: type})
  :ok
end

def handle_event(type, %Accrue.Webhook.Event{} = event, _ctx) when is_binary(type) do
  case dispatch(type, event.processor_event_id, event.created_at, %{"id" => event.object_id}) do
    {:ok, _} -> :ok
    other -> other
  end
end

# Fallthrough for all other event types (D2-28).
def handle_event(_type, _event, _ctx), do: :ok
```

For ConnectHandler: `use Accrue.Webhook.Handler`, alias `Accrue.Connect.Account`, then `handle_event/3` clauses for `"account.updated"`, `"account.application.authorized"`, `"account.application.deauthorized"`, `"capability.updated"`, `"payout.created" | "payout.paid" | "payout.failed"`, and a passthrough catch-all (NOT a default-handler crash — Connect events should never fall through to DefaultHandler since dispatch already routed them).

**Dispatch + reducer pattern** (lines 139-160):

```elixir
defp dispatch("customer.subscription." <> action, evt_id, evt_ts, obj)
     when action in ~w(created updated trial_will_end deleted paused resumed) do
  reduce_subscription(action, evt_id, evt_ts, obj)
end
```

For Connect: `dispatch("account." <> action, ...)` and `dispatch("payout." <> action, ...)`.

**Reducer body shape** (canonical: load-or-fetch → force_status_changeset → Repo.transact + Events.record_multi). The exact code lives further into `default_handler.ex` (read offset 200+ for `reduce_subscription/4`); the shape is described in research Pattern 5. The Connect reducer for `account.updated` MUST handle the out-of-order case (Pitfall 3): `Repo.get_by(Account, stripe_account_id: id) || fetch_via_processor_then_seed(id)`.

---

### `accrue/lib/accrue/webhook/webhook_event.ex` (MODIFIED — model)

**In-file analog:** `field :status, Ecto.Enum, values: @statuses, default: :received` (line 43)

**Add the endpoint field**:

```elixir
@endpoints [:default, :connect]   # extensible

field :endpoint, Ecto.Enum, values: @endpoints, default: :default
```

**Update `@ingest_fields`** (line 58):

```elixir
@ingest_fields ~w[processor processor_event_id type livemode raw_body received_at data]a
```

Add `endpoint` to this list. `@ingest_required` need NOT include it (default `:default` covers Phase 1-4 single-endpoint callers).

**Migration analog for the column add:** `accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs:20-27`:

```elixir
def change do
  alter table(:accrue_subscriptions) do
    add :past_due_since, :utc_datetime_usec, null: true
    add :dunning_sweep_attempted_at, :utc_datetime_usec, null: true
    add :paused_at, :utc_datetime_usec, null: true
    add :pause_behavior, :string, null: true
    add :discount_id, :string, null: true
  end

  create index(
           :accrue_subscriptions,
           [:past_due_since],
           where: "past_due_since IS NOT NULL",
           name: :accrue_subscriptions_past_due_since_idx
         )
end
```

For the new endpoint migration: `add :endpoint, :string, null: false, default: "default"` on `:accrue_webhook_events`. Backfill is implicit via the column default — existing rows become `:default`, satisfying the Phase 4 invariant. Optional partial index `where: "endpoint = 'connect'"` for fast Connect-only queries.

---

### `accrue/lib/accrue/webhook/ingest.ex` (MODIFIED — service)

**In-file analog:** `WebhookEvent.ingest_changeset/1` invocation at lines 63-73:

```elixir
changeset =
  WebhookEvent.ingest_changeset(%{
    processor: processor_str,
    processor_event_id: stripe_event.id,
    type: stripe_event.type,
    livemode: stripe_event.livemode,
    status: :received,
    raw_body: raw_body,
    received_at: DateTime.utc_now(),
    data: Map.from_struct(stripe_event)
  })
```

**Change required:** Phase 5 must thread `endpoint` from `Accrue.Webhook.Plug.do_call/3` (`plug.ex:52-66`) through `Ingest.run/4` as a 5th positional arg (or by promoting the signature to keyword opts). Then add `endpoint: endpoint` (default `:default`) to the changeset map.

**Phase 5 must also update `plug.ex` line 65** from:

```elixir
Accrue.Webhook.Ingest.run(conn, processor, stripe_event, raw_body)
```

to pass `endpoint` (currently held in `do_call/3`'s closure but dropped at the boundary).

---

### `accrue/lib/accrue/webhook/dispatch_worker.ex` (MODIFIED — worker)

**In-file analog:** existing `safe_handle(DefaultHandler, event, ctx)` at line 57:

```elixir
default_result = safe_handle(DefaultHandler, event, ctx)
```

**Change required:** Read `endpoint` from `row` (now persisted), include in `ctx`, branch:

```elixir
ctx = %{
  attempt: attempt,
  max_attempts: max_attempts,
  webhook_event_id: id,
  endpoint: row.endpoint
}

handler =
  case row.endpoint do
    :connect -> Accrue.Webhook.ConnectHandler
    _ -> Accrue.Webhook.DefaultHandler
  end

default_result = safe_handle(handler, event, ctx)
```

User handlers loop (lines 59-61) is unchanged — they're agnostic to endpoint by design (a host may want both).

---

### `accrue/lib/accrue/processor/stripe.ex` (MODIFIED — adapter)

**In-file analog #1:** `resolve_api_version/1` (lines 813-825):

```elixir
@doc """
Resolves the Stripe API version using three-level precedence (D2-14):

  1. `opts[:api_version]` (explicit per-call override)
  2. `Process.get(:accrue_stripe_api_version)` (scoped via `Accrue.Stripe.with_api_version/2`)
  3. `Accrue.Config.stripe_api_version/0` (application config default)
"""
@spec resolve_api_version(keyword()) :: String.t()
def resolve_api_version(opts \\ []) when is_list(opts) do
  Keyword.get(opts, :api_version) ||
    Process.get(:accrue_stripe_api_version) ||
    Accrue.Config.stripe_api_version()
end
```

**Phase 5 sibling:**

```elixir
@doc """
Resolves the Stripe-Account header using three-level precedence (D5-01):

  1. `opts[:stripe_account]` (explicit per-call override)
  2. `Accrue.Connect.current_account_id/0` (scoped via `Accrue.Connect.with_account/2`)
  3. `Accrue.Config.get(:default_stripe_account)` (application config default, usually nil)
"""
@spec resolve_stripe_account(keyword()) :: String.t() | nil
def resolve_stripe_account(opts \\ []) when is_list(opts) do
  Keyword.get(opts, :stripe_account) ||
    Accrue.Connect.current_account_id() ||
    Accrue.Config.get(:default_stripe_account)
end
```

**In-file analog #2:** `build_client!/1` (lines 831-854):

```elixir
@spec build_client!(keyword()) :: LatticeStripe.Client.t()
defp build_client!(opts) do
  key =
    case Application.get_env(:accrue, :stripe_secret_key) do
      nil -> raise Accrue.ConfigError, key: :stripe_secret_key, message: "..."
      "" -> raise Accrue.ConfigError, key: :stripe_secret_key, message: "..."
      value when is_binary(value) -> value
    end

  api_version = resolve_api_version(opts)

  LatticeStripe.Client.new!(api_key: key, api_version: api_version)
end
```

**Phase 5 one-line extension:**

```elixir
api_version = resolve_api_version(opts)
stripe_account = resolve_stripe_account(opts)

LatticeStripe.Client.new!(
  api_key: key,
  api_version: api_version,
  stripe_account: stripe_account
)
```

`LatticeStripe.Client.new!/1` already accepts a nil `stripe_account:` (per RESEARCH.md A6 + lattice_stripe sibling-repo verification); platform-scoped behavior is preserved.

---

### `accrue/lib/accrue/processor.ex` (MODIFIED — behaviour)

**In-file analog:** existing callback blocks at lines 73-130:

```elixir
# ---------------------------------------------------------------------------
# Customer (Phase 1)
# ---------------------------------------------------------------------------

@callback create_customer(params(), opts()) :: result()
@callback retrieve_customer(id(), opts()) :: result()
@callback update_customer(id(), params(), opts()) :: result()

# ---------------------------------------------------------------------------
# Subscription (Phase 3)
# ---------------------------------------------------------------------------

@callback create_subscription(params(), opts()) :: result()
@callback retrieve_subscription(id(), opts()) :: result()
@callback update_subscription(id(), params(), opts()) :: result()
# ...
```

**Phase 5 addition:**

```elixir
# ---------------------------------------------------------------------------
# Connect (Phase 5)
# ---------------------------------------------------------------------------

@callback create_account(params(), opts()) :: result()
@callback retrieve_account(id(), opts()) :: result()
@callback update_account(id(), params(), opts()) :: result()
@callback delete_account(id(), opts()) :: result()
@callback reject_account(id(), params(), opts()) :: result()
@callback list_accounts(params(), opts()) :: result()
@callback create_account_link(params(), opts()) :: result()
@callback create_login_link(id(), opts()) :: result()
@callback create_transfer(params(), opts()) :: result()
@callback retrieve_transfer(id(), opts()) :: result()
```

---

### `accrue/lib/accrue/oban/middleware.ex` (MODIFIED — middleware)

**In-file analog:** the entire `put/1` (lines 31-35):

```elixir
@spec put(%{id: any(), attempt: integer()}) :: :ok
def put(%{id: id, attempt: attempt}) do
  Accrue.Actor.put_operation_id("oban-#{id}-#{attempt}")
  :ok
end
```

**Phase 5 extension:** read `stripe_account` from job args (or pass it as 2nd arg) and call `Accrue.Connect.put_account_id/1`. The wire format follows the `operation_id` pattern verbatim — encode in `args["stripe_account"]` at enqueue time, restore in `put/1` at perform time. Workers that enqueue via D5-01 must include `stripe_account: ctx_value` in their args map.

---

### `accrue/lib/accrue/config.ex` (MODIFIED — config)

**In-file analog:** the `:dunning` keyword_list entry (lines 174-189):

```elixir
dunning: [
  type: :keyword_list,
  default: [
    mode: :stripe_smart_retries,
    grace_days: 14,
    terminal_action: :unpaid,
    telemetry_prefix: [:accrue, :ops]
  ],
  doc:
    "Dunning grace-period overlay config (D4-02). `:mode` is " <>
      "`:stripe_smart_retries` or `:disabled`; `:terminal_action` is " <>
      "`:unpaid` or `:canceled`; `:grace_days` adds N days past Stripe's " <>
      "last retry before Accrue asks the processor facade to move the " <>
      "subscription to the terminal action."
],
```

**Phase 5 addition:** add a `:connect` keyword_list under the same schema rhythm:

```elixir
connect: [
  type: :keyword_list,
  default: [
    default_stripe_account: nil,
    platform_fee: [
      percent: Decimal.new("2.9"),
      fixed: nil,
      min: nil,
      max: nil
    ]
  ],
  doc:
    "Connect (Stripe Connect) config (D5-01, D5-04). " <>
      "`:default_stripe_account` is a fallback connected-account id used by " <>
      "`Accrue.Processor.Stripe.resolve_stripe_account/1` when neither per-call " <>
      "opts nor `Accrue.Connect.with_account/2` supply one (rare; useful for " <>
      "single-tenant platforms). `:platform_fee` is the default flat-rate fee " <>
      "config consumed by `Accrue.Connect.platform_fee/2`."
]
```

`Accrue.Config.get/1` reader pattern (line 257) is unchanged.

---

### `accrue/lib/accrue/connect/platform_fee.ex` (utility, transform)

**Analog:** No exact match — closest is `accrue/lib/accrue/money.ex` for the Money primitives + the Phase 4 `dunning` config-driven helper shape. **Use RESEARCH.md Code Example 6 directly.** Property tests use existing `test/property/` patterns.

**Property test analog:** look at any existing file under `accrue/test/property/` for the StreamData generator + `check all` shape. (No specific file named in CONTEXT.md / RESEARCH.md, but Phase 1 FND-01 mandates property tests exist for `Accrue.Money` — check `accrue/test/property/` directory at plan time.)

---

### `accrue/test/support/connect_case.ex` (test support)

**Analog:** `accrue/test/support/billing_case.ex` — verbatim.

**Full pattern** (lines 1-78, see file in step 2 above):

```elixir
defmodule Accrue.BillingCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Accrue.{Billing, Money}
      alias Accrue.TestRepo, as: Repo
      alias Accrue.Billing.{Charge, Customer, Invoice, PaymentMethod, Subscription, SubscriptionItem}
      alias Accrue.Processor.Fake
      alias Accrue.Test.StripeFixtures
      import Accrue.Test.StripeFixtures
      import Ecto.Query
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    prior_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :test)

    on_exit(fn ->
      if prior_env, do: Application.put_env(:accrue, :env, prior_env), else: Application.delete_env(:accrue, :env)
    end)

    :ok = Accrue.Actor.put_operation_id("test-" <> Ecto.UUID.generate())

    :ok
  end
end
```

For ConnectCase: alias `Accrue.Connect` and `Accrue.Connect.Account`; in `setup`, also clear any leftover `with_account/2` pdict (`Process.delete(:accrue_connected_account_id)`). Optional: stash a default Standard-account id and seed it via `Fake` so tests that don't care about onboarding can just use `with_account(default_acct, fn -> ... end)`.

---

## Shared Patterns

### Three-level precedence resolver (D5-01)

**Source:** `accrue/lib/accrue/processor/stripe.ex:820-825` (`resolve_api_version/1`)
**Apply to:** `resolve_stripe_account/1` (new sibling in same file)
**Pattern:** `opts > pdict > Accrue.Config`. Both members of the OR-chain MUST short-circuit on `nil`, not on falsy — this allows `false` config values where applicable.

### Pdict scoped-block helper

**Source:** `accrue/lib/accrue/stripe.ex:30-44` (`with_api_version/2`)
**Apply to:** `Accrue.Connect.with_account/2`
**Pattern:** `try { Process.put(...) ; fun.() } after { restore prior or delete }`. Restoring prior (not just deleting) makes the helper safely composable inside other scoped blocks.

### Dual bang/tuple API (D-05)

**Source:** `accrue/lib/accrue/billing_portal/session.ex:62-91`
**Apply to:** every public Phase 5 fn — `create_account`, `retrieve_account`, `update_account`, `delete_account`, `reject_account`, `list_accounts`, `create_account_link`, `create_login_link`, `destination_charge`, `separate_charge_and_transfer`, `transfer`, `platform_fee`
**Pattern:** non-bang returns `{:ok, t} | {:error, term}`; bang variant case-matches and re-raises. Crash on non-exception errors via `raise "...failed: #{inspect(other)}"`.

### Inspect masking for credentials (Phase 4 CHKT-04)

**Source:** `accrue/lib/accrue/billing_portal/session.ex:149-178`
**Apply to:** `Accrue.Connect.AccountLink`, `Accrue.Connect.LoginLink`
**Pattern:** `defimpl Inspect`, build a `fields` keyword list with `url: if(s.url, do: "<redacted>", else: nil)`, fold via `Inspect.Algebra.concat/to_doc`. Same idiom protects against Logger, Sentry, telemetry handlers, and IEx output.

### Webhook-path `force_status_changeset/2` (D3-17)

**Source:** `accrue/lib/accrue/billing/subscription.ex:88-100`
**Apply to:** `Accrue.Connect.Account.force_status_changeset/2`
**Pattern:** Cast all fields, optimistic_lock, but skip `validate_required` and `validate_inclusion` calls that the user-path `changeset/2` enforces. Justification: webhook events may legitimately deliver partial state during reconciliation windows; D2-29 says Stripe is canonical so refusing to absorb its payload is wrong.

### Atom/string dual-key map accessor

**Source:** `accrue/lib/accrue/billing_portal/session.ex:142-146` AND `accrue/lib/accrue/billing/subscription_projection.ex:45-47`
**Apply to:** every Phase 5 `from_stripe/1` constructor and projection
**Pattern:**
```elixir
defp get(%{} = map, key) when is_atom(key) do
  Map.get(map, key) || Map.get(map, Atom.to_string(key))
end

defp get(_, _), do: nil
```
Required for Fake-vs-Stripe payload compatibility — Fake returns atom-keyed maps, Stripe returns string-keyed (via `Map.from_struct`).

### NimbleOptions schema for opts validation

**Source:** `accrue/lib/accrue/billing_portal/session.ex:46-57` (per-fn) AND `accrue/lib/accrue/config.ex:2-217` (app-wide)
**Apply to:**
- `create_account_link/2` per-fn schema (per-fn validation at call time)
- `Accrue.Config` `:connect` keyword_list entry (app-wide for `default_stripe_account` + `platform_fee` defaults)

### Predicates over raw status (D3-04)

**Source:** `accrue/lib/accrue/billing/subscription.ex:124-192`
**Apply to:** `Accrue.Connect.Account` predicates
**Pattern:** `def fn?(%__MODULE__{field: matched}), do: true` then a bare-map fallback `def fn?(%{field: matched}), do: true` then a catch-all `def fn?(_), do: false`. Lint rule `Accrue.Credo.NoRawStatusAccess` forbids `acct.charges_enabled` outside the schema module — callers MUST use `Account.charges_enabled?/1`.

### Migration: alter table column add

**Source:** `accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs:20-35`
**Apply to:** `add_endpoint_to_accrue_webhook_events.exs`
**Pattern:** `alter table` with nullable adds (or with explicit default for backfill), optional partial index for query acceleration.

### Migration: create table

**Source:** `accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs:11-71`
**Apply to:** `create_accrue_connect_accounts.exs`
**Pattern:** `create table(:name, primary_key: false)` with `add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")`, polymorphic `owner_type`/`owner_id`, jsonb columns with `default: %{}, null: false`, `metadata` + `data` + `lock_version` housekeeping, then unique index on `(processor, processor_id)` (Phase 5: on `stripe_account_id`).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `accrue/lib/accrue/connect/platform_fee.ex` (or inlined fn in `connect.ex`) | utility (pure Money math) | transform | No prior Phase ships a Money-in/Money-out helper of comparable shape. Closest pattern is `Accrue.Money` primitive ops + the `Accrue.Config` schema entry. Use RESEARCH.md Pattern + Code Example 6 directly. Property test file under `accrue/test/property/` (planner should glob the directory at plan time to find the existing StreamData rhythm — no specific named example in the canonical refs). |

Everything else in Phase 5 has a clean Phase 1-4 analog.

---

## Metadata

**Analog search scope:**
- `accrue/lib/accrue/` (recursive) — context modules, schemas, processors, plugs, webhook layer
- `accrue/lib/accrue/billing_portal/` — credential struct + Inspect masking
- `accrue/lib/accrue/processor/` — adapter behaviour + Stripe + Fake
- `accrue/lib/accrue/webhook/` — handler shape + ingest + dispatch + plug + schema
- `accrue/lib/accrue/oban/` — middleware
- `accrue/lib/accrue/plug/` — sibling plug template
- `accrue/priv/repo/migrations/` — both `create table` and `alter table` exemplars
- `accrue/test/support/` — case template

**Files inspected:** 16 analog files read in full or partially
**Pattern extraction date:** 2026-04-15
**CONTEXT.md canonical refs verified:** D5-01 → `processor/stripe.ex:820-825` ✓ / D5-01 pdict → `actor.ex:74-98` ✓ / D5-06 → `billing_portal/session.ex:149-178` ✓ / D5-05 → `webhook/default_handler.ex` ✓ / D3-17 force_status_changeset → `billing/subscription.ex:88-100` ✓
**Critical Finding (Pitfall 1) confirmed by direct grep/read:** `webhook/webhook_event.ex` has no `endpoint` field; `webhook/ingest.ex:63-73` does not pass it; `webhook/dispatch_worker.ex:51-57` does not read it; `webhook/plug.ex:40` knows `endpoint` but drops it at the `Ingest.run/4` boundary. The Wave 0 plumbing addition is a real ~4-file change exactly as research described.
