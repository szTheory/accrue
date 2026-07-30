# Phase 213: Stripe-native advisory entitlements sync (observational-only) - Pattern Map

**Mapped:** 2026-07-30
**Files analyzed:** 14 new/modified files
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/processor.ex` | service/facade behaviour | request-response | `accrue/lib/accrue/processor.ex` existing `list_payment_methods/2`, `list_charges/2`, optional callbacks | exact |
| `accrue/lib/accrue/processor/stripe.ex` | service adapter | streaming, request-response | `accrue/lib/accrue/processor/stripe.ex` `list_payment_methods/2`, `build_client!/1`, `translate_resource/1` | role-match |
| `accrue/lib/accrue/processor/fake/state.ex` | model/test state | CRUD | `accrue/lib/accrue/processor/fake/state.ex` existing resource maps | exact |
| `accrue/lib/accrue/processor/fake.ex` | service/test double | CRUD, request-response | `accrue/lib/accrue/processor/fake.ex` `list_payment_methods/2`, `list_charges/2`, `with_script_or_stub/4` | exact |
| `accrue/lib/accrue/processor/braintree.ex` | service adapter | request-response | `accrue/lib/accrue/processor.ex` optional callback pattern | role-match |
| `accrue/lib/accrue/entitlements/stripe_sync.ex` | service/domain seam | request-response | `accrue/lib/accrue/entitlements/stripe_sync.ex` `summary_for_customer/1`; `DefaultHandler` sync span/write path | role-match |
| `accrue/lib/accrue/entitlements/reconcile.ex` | service/shared writer | CRUD, transform | `accrue/lib/accrue/webhook/default_handler.ex` entitlement summary reducer/writer | extraction |
| `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex` | worker | event-driven, request-response | `accrue/lib/accrue/webhook/dispatch_worker.ex`; `accrue/lib/accrue/workers/dunning_step.ex` | role-match |
| `scripts/ci/verify_entitlement_sync_isolation.sh` | config/CI guard | batch | existing same script | exact |
| `accrue/lib/accrue/entitlements/admin.ex` | documentation/domain seam | read-only request-response | existing moduledoc in same file | exact |
| `accrue/guides/entitlements.md` | docs | read-only explanatory | existing advisory sync guide section | exact |
| `accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs` | test | CRUD, request-response | `default_handler_entitlement_summary_test.exs`, `stripe_sync_disabled_isolation_test.exs` | role-match |
| `accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs` | test | event-driven | `accrue/test/accrue/workers/dunning_step_test.exs` | role-match |
| isolation negative-path test under `accrue/test/accrue/entitlements/*` or script test | test | batch | `stripe_sync_disabled_isolation_test.exs`, `scripts/ci/verify_entitlement_sync_isolation.sh` | role-match |

## Pattern Assignments

### `accrue/lib/accrue/processor.ex` (service/facade behaviour, request-response)

**Analog:** `accrue/lib/accrue/processor.ex`

**Callback grouping pattern** (lines 187-205):
```elixir
# ---------------------------------------------------------------------------
# PaymentMethod
# ---------------------------------------------------------------------------

@callback create_payment_method(params(), opts()) :: result()
@callback retrieve_payment_method(id(), opts()) :: result()
@callback attach_payment_method(id(), params(), opts()) :: result()
@callback detach_payment_method(id(), opts()) :: result()
@callback list_payment_methods(params(), opts()) :: result()
@callback update_payment_method(id(), params(), opts()) :: result()
@callback set_default_payment_method(id(), params(), opts()) :: result()

# ---------------------------------------------------------------------------
# Charge
# ---------------------------------------------------------------------------

@callback create_charge(params(), opts()) :: result()
@callback retrieve_charge(id(), opts()) :: result()
@callback list_charges(params(), opts()) :: result()
```

**Optional callback pattern** (lines 284-302):
```elixir
# Connect callbacks are optional at the behaviour level so that adapter
# implementations can be added incrementally. Once all adapters implement
# the full Connect surface, this `@optional_callbacks` declaration can
# be removed to re-enable strict behaviour checks.
@callback capabilities() :: map()
@callback processor_name() :: String.t()

@optional_callbacks create_account: 2,
                    retrieve_account: 2,
                    update_account: 3,
                    delete_account: 2,
                    reject_account: 3,
                    list_accounts: 2,
                    create_account_link: 2,
                    create_login_link: 2,
                    create_transfer: 2,
                    retrieve_transfer: 2,
                    capabilities: 0,
                    processor_name: 0
```

**Facade dispatch pattern** (lines 351-370):
```elixir
@doc """
Creates an invoice item through the configured processor adapter.
"""
@spec invoice_item_create(params(), opts()) :: result()
def invoice_item_create(params, opts \\ []) when is_map(params) and is_list(opts) do
  __impl__().invoice_item_create(params, opts)
end

@doc false
@spec __impl__() :: module()
def __impl__, do: Application.get_env(:accrue, :processor, Accrue.Processor.Fake)
```

**Apply:** Add `list_active_entitlements/2` near the charge/payment-method list callbacks. Mark it optional in `@optional_callbacks` so `Braintree` and custom adapters stay source-compatible. Add a facade dispatch function with guards `when is_binary(id) and is_list(opts)`.

---

### `accrue/lib/accrue/processor/stripe.ex` (service adapter, streaming/request-response)

**Analog:** `accrue/lib/accrue/processor/stripe.ex`

**Facade boundary and PII pattern** (lines 12-57):
```elixir
> **Facade boundary:** This is the only module in the Accrue codebase
> allowed to reference `LatticeStripe` directly. A CI test enforces this
> by scanning `lib/accrue/**/*.ex` and failing if `LatticeStripe` appears
> anywhere except `stripe.ex` and `stripe/error_mapper.ex`.

## PII discipline

Raw Stripe responses can contain PII in fields like `email`, `name`,
`address`, `phone`, and `shipping`. This adapter:

- Does not log processor errors verbatim.
- Emits only `%{adapter: :stripe, operation: ...}` in telemetry metadata
  — never raw params or response bodies.
- Converts `LatticeStripe` structs to plain maps so downstream code never
  pattern-matches on library-internal struct types.
```

**List callback shape** (lines 474-481):
```elixir
@impl Accrue.Processor
def list_payment_methods(params, opts) when is_map(params) and is_list(opts) do
  client = build_client!(opts)

  client
  |> LatticeStripe.PaymentMethod.list(stringify_keys(params), stripe_opts_no_idem(opts))
  |> translate_resource()
end
```

**Error mapping helper pattern** (lines 931-937):
```elixir
@dialyzer {:nowarn_function, translate_resource: 1}
@spec translate_resource({:ok, struct() | map()} | {:error, term()}) ::
        {:ok, map()} | {:error, Exception.t()}
defp translate_resource({:ok, %_{} = result}), do: {:ok, Map.from_struct(result)}
defp translate_resource({:ok, result}) when is_map(result), do: {:ok, result}
defp translate_resource({:error, raw}), do: {:error, ErrorMapper.to_accrue_error(raw)}
```

**Client construction pattern** (lines 1005-1032):
```elixir
@spec build_client!(keyword()) :: LatticeStripe.Client.t()
defp build_client!(opts) do
  key =
    case Application.get_env(:accrue, :stripe_secret_key) do
      nil ->
        raise Accrue.ConfigError,
          key: :stripe_secret_key,
          message:
            "Set config :accrue, :stripe_secret_key in runtime.exs before using " <>
              "Accrue.Processor.Stripe"

      "" ->
        raise Accrue.ConfigError,
          key: :stripe_secret_key,
          message: "config :accrue, :stripe_secret_key is empty; set it in runtime.exs"

      value when is_binary(value) ->
        value
    end

  api_version = resolve_api_version(opts)
  stripe_account = resolve_stripe_account(opts)

  LatticeStripe.Client.new!(
    api_key: key,
    api_version: api_version,
    stripe_account: stripe_account
  )
end
```

**Dependency API to copy from** (`deps/lattice_stripe/.../active_entitlement.ex`, lines 180-195):
```elixir
def stream!(%Client{} = client, params \\ %{}, opts \\ []) do
  # MUST be the first statement. `Stream.resource/3` defers its start function, so a
  # guard constructed lazily would not raise until the stream is consumed.
  Resource.require_param!(
    params,
    "customer",
    "LatticeStripe.Entitlements.ActiveEntitlement.stream!/3 requires a customer param"
  )

  req = %Request{method: :get, path: @list_path, params: params, opts: opts}

  LatticeStripe.List.stream!(client, req) |> Stream.map(&from_map/1)
end
```

**Apply:** Alias or fully qualify `LatticeStripe.Entitlements.ActiveEntitlement` in `stripe.ex` only. Implement `list_active_entitlements(id, opts)` with `build_client!(opts)`, `stripe_opts_no_idem(opts)`, `ActiveEntitlement.stream!(client, %{"customer" => id, "limit" => "100"}, stripe_opts)`, `Enum.map(&to_plain_map/1)`, and rescue `%LatticeStripe.Error{}` through `ErrorMapper.to_accrue_error/1`.

---

### `accrue/lib/accrue/processor/fake/state.ex` (model/test state, CRUD)

**Analog:** `accrue/lib/accrue/processor/fake/state.ex`

**State map pattern** (lines 13-57):
```elixir
@type t :: %__MODULE__{
        customers: %{optional(id()) => map()},
        subscriptions: %{optional(id()) => map()},
        subscription_items: %{optional(id()) => map()},
        invoices: %{optional(id()) => map()},
        payment_methods: %{optional(id()) => map()},
        charges: %{optional(id()) => map()},
        refunds: %{optional(id()) => map()},
        call_counts: %{optional(atom()) => non_neg_integer()},
        stubs: %{optional(atom()) => (... -> term())},
        scripts: %{optional(atom()) => term()}
      }
```

**Defstruct pattern** (lines 61-103):
```elixir
defstruct customers: %{},
          subscriptions: %{},
          subscription_items: %{},
          invoices: %{},
          payment_methods: %{},
          charges: %{},
          refunds: %{},
          call_counts: %{},
          counters: %{
            customer: 0,
            subscription: 0,
            event: 0
          },
          clock: @epoch,
          stubs: %{},
          idempotency_cache: %{},
          scripts: %{}
```

**Apply:** Add `entitlements: %{optional(id()) => [map()]}` to the type and `entitlements: %{}` to the struct. Do not add a counter unless generating fake entitlement ids in Fake; D-04 only requires a seeded list.

---

### `accrue/lib/accrue/processor/fake.ex` (service/test double, CRUD/request-response)

**Analog:** `accrue/lib/accrue/processor/fake.ex`

**Lifecycle and reset pattern** (lines 31-42, 97-103):
```elixir
The Fake is a `GenServer` with a fixed name (`__MODULE__`). It is **not**
started by `Accrue.Application` — tests that need it call:

    setup do
      case Accrue.Processor.Fake.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end

      :ok = Accrue.Processor.Fake.reset()
      :ok
    end

@spec reset() :: :ok
def reset do
  call(:reset)
end
```

**Public callback wrapper pattern** (lines 454-487):
```elixir
@impl Accrue.Processor
def list_payment_methods(params, opts \\ []) when is_map(params) and is_list(opts) do
  call({:list_payment_methods, params, opts})
end

@impl Accrue.Processor
def list_charges(params, opts \\ []) when is_map(params) and is_list(opts) do
  call({:list_charges, params, opts})
end
```

**List handler pattern** (lines 1314-1324):
```elixir
def handle_call({:list_payment_methods, params, opts}, _from, state) do
  with_script_or_stub(state, :list_payment_methods, [params, opts], fn state ->
    customer = params[:customer] || params["customer"]

    data =
      state.payment_methods
      |> Map.values()
      |> Enum.filter(fn pm -> pm[:customer] == customer end)

    {{:ok, %{object: "list", data: data, has_more: false}}, state}
  end)
end
```

**Apply:** Add `put_entitlements(customer_processor_id, entitlements)` as a public seed helper that calls the GenServer. Add `list_active_entitlements(id, opts \\ [])` and a handler using `with_script_or_stub(state, :list_active_entitlements, [id, opts], fn state -> {{:ok, Map.get(state.entitlements, id, [])}, state} end)`.

---

### `accrue/lib/accrue/entitlements/stripe_sync.ex` (service/domain seam, request-response)

**Analog:** `accrue/lib/accrue/entitlements/stripe_sync.ex` plus `DefaultHandler` config gate.

**Observational-only dependency pattern** (lines 10-26):
```elixir
## Observational-only (D-01 / D-11)

The advisory cache is recorded, ledgered, telemetered, and surfaced here,
but it is **never consulted to decide a grant**. Local plan→feature
mapping stays canonical. The gate path — `Accrue.entitled?/2`,
`Accrue.has_active_plan?/2`, `Accrue.Entitlements.Resolver`, and
`Accrue.Entitlements.Resolver.LocalMap` — MUST NOT reference this module
or the `Accrue.Billing.EntitlementSummary` schema.
```

**Existing read seam** (lines 29-40):
```elixir
alias Accrue.Billing.{Customer, EntitlementSummary}
alias Accrue.Repo

@doc false
@spec summary_for_customer(Customer.t()) :: EntitlementSummary.t() | nil
def summary_for_customer(%Customer{} = customer) do
  Repo.get_by(EntitlementSummary, customer_id: customer.id)
end
```

**Config-off no-I/O pattern** (`default_handler.ex`, lines 313-319):
```elixir
defp dispatch("entitlements.active_entitlement_summary.updated", evt_id, evt_ts, obj, processor) do
  if Accrue.Config.stripe_native_sync?() do
    reduce_entitlement_summary(evt_id, evt_ts, obj, processor)
  else
    {:ok, :ignored}
  end
end
```

**Telemetry span/write pattern** (`default_handler.ex`, lines 615-657):
```elixir
metadata = %{
  customer_id: customer.id,
  has_more: has_more,
  entitlement_count: entitlement_count
}

Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fn ->
  case upsert_entitlement_summary(row, attrs) do
    {:ok, :stale} ->
      :telemetry.execute(
        [:accrue, :entitlements, :summary_synced],
        %{count: 1, entitlement_count: entitlement_count},
        Map.put(metadata, :result, :unchanged)
      )

      {:ok, :stale}

    {:ok, saved} ->
      with {:ok, _} <- maybe_record_summary_event(material?, saved, evt_id) do
        :telemetry.execute(
          [:accrue, :entitlements, :summary_synced],
          %{count: 1, entitlement_count: entitlement_count},
          Map.put(metadata, :result, if(material?, do: :written, else: :unchanged))
        )

        {:ok, saved}
      end

    error ->
      error
  end
end)
```

**Apply:** Extend the moduledoc to say the cache is written by webhook and pull. Implement `refresh(customer, opts \\ [])` with the first executable branch checking `Accrue.Config.stripe_native_sync?()`. Only after the enabled branch should it call `Accrue.Processor.list_active_entitlements(customer.processor_id, opts)` and pass the materialized list to the shared reconciler with provenance/source `:pull`.

---

### `accrue/lib/accrue/entitlements/reconcile.ex` (service/shared writer, CRUD/transform)

**Analog:** Extract from `accrue/lib/accrue/webhook/default_handler.ex`

**Validation/reducer pattern** (lines 500-525):
```elixir
defp reduce_entitlement_summary(evt_id, evt_ts, obj, processor) do
  cus_id = get(obj, :customer)
  entitlements = get(obj, :entitlements)
  data = get(entitlements, :data)

  cond do
    not is_binary(cus_id) ->
      emit_summary_malformed(evt_id, :missing_customer)
      {:ok, :ignored}

    not is_list(data) ->
      emit_summary_malformed(evt_id, :non_list_entitlements)
      {:ok, :ignored}

    true ->
      reduce_entitlement_summary_for_customer(
        evt_id,
        evt_ts,
        obj,
        cus_id,
        entitlements,
        data,
        processor
      )
  end
end
```

**Transaction/customer lookup pattern** (lines 536-577):
```elixir
Repo.transact(fn ->
  case Repo.get_by(Customer, processor_id: cus_id, processor: to_string(processor)) do
    %Customer{} = customer ->
      row = Repo.get_by(EntitlementSummary, customer_id: customer.id)

      case check_stale(row, evt_ts) do
        :stale ->
          :telemetry.execute(
            [:accrue, :webhooks, :stale_event],
            %{},
            %{object_type: :entitlement_summary, stripe_id: cus_id, event_id: evt_id}
          )

          {:ok, :stale}

        :ok ->
          write_entitlement_summary(...)
      end

    _ ->
      :telemetry.execute(
        [:accrue, :webhooks, :orphan_entitlement_summary],
        %{},
        %{customer_stripe_id: cus_id}
      )

      {:ok, :deferred}
  end
end)
```

**Attrs/material-change pattern** (lines 591-614):
```elixir
has_more = get(entitlements, :has_more) == true
entitlement_count = length(data)
new_pairs = entitlement_pairs(data)
material? = summary_material_change?(row, new_pairs, has_more)

attrs =
  %{
    customer_id: customer.id,
    stripe_customer_id: cus_id,
    processor: to_string(processor),
    livemode: livemode_for_upsert(get(obj, :livemode), row),
    entitlement_count: entitlement_count,
    truncated: has_more,
    synced_at: synced_at_from_event(evt_ts),
    data: obj
  }
  |> stamp_summary_watermark(evt_ts, evt_id, row)
```

**Monotone upsert pattern** (lines 697-748):
```elixir
defp upsert_entitlement_summary(_row, attrs) do
  import Ecto.Query

  conflict_query =
    from(e in EntitlementSummary,
      where:
        fragment("EXCLUDED.last_stripe_event_ts IS NULL") or
          e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts"),
      update: [
        set: [
          processor: fragment("EXCLUDED.processor"),
          stripe_customer_id: fragment("EXCLUDED.stripe_customer_id"),
          livemode: fragment("EXCLUDED.livemode"),
          entitlement_count: fragment("EXCLUDED.entitlement_count"),
          truncated: fragment("EXCLUDED.truncated"),
          data: fragment("EXCLUDED.data"),
          synced_at: fragment("EXCLUDED.synced_at"),
          last_stripe_event_ts: fragment("EXCLUDED.last_stripe_event_ts"),
          last_stripe_event_id: fragment("EXCLUDED.last_stripe_event_id"),
          updated_at: fragment("EXCLUDED.updated_at")
        ]
      ]
    )

  %EntitlementSummary{}
  |> EntitlementSummary.force_changeset(attrs)
  |> Repo.insert(
    returning: true,
    conflict_target: :customer_id,
    on_conflict: conflict_query
  )
rescue
  Ecto.StaleEntryError -> {:ok, :stale}
end
```

**Watermark/livemode helpers** (lines 750-782):
```elixir
defp synced_at_from_event(%DateTime{} = evt_ts), do: evt_ts
defp synced_at_from_event(_), do: Accrue.Clock.utc_now()

defp stamp_summary_watermark(attrs, %DateTime{} = evt_ts, evt_id, _row),
  do: stamp_watermark(attrs, evt_ts, evt_id)

defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, nil), do: attrs

defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, %EntitlementSummary{} = row) do
  Map.merge(attrs, %{
    last_stripe_event_ts: row.last_stripe_event_ts,
    last_stripe_event_id: row.last_stripe_event_id
  })
end

defp livemode_for_upsert(nil, %EntitlementSummary{livemode: prior}) when not is_nil(prior),
  do: prior

defp livemode_for_upsert(incoming, _row), do: incoming
```

**Fixture summary shape** (`accrue/test/support/stripe_fixtures.ex`, lines 450-460):
```elixir
summary_object =
  %{
    "object" => "entitlements.active_entitlement_summary",
    "customer" => customer,
    "livemode" => livemode,
    "entitlements" => %{
      "object" => "list",
      "data" => Enum.map(entitlements, &normalize_entitlement/1),
      "has_more" => has_more,
      "url" => url
    }
  }
```

**Apply:** Create a public shared writer such as `write_from_webhook/5` and `write_from_pull/3`, or one normalized `write_summary/1` API. Pull writes should reconstruct the summary-shaped `data`, set `truncated: false`, preserve existing `last_stripe_event_ts/id`, and tag `data["_accrue"]` plus telemetry meta with `source: :pull`. Re-derive the proposed `synced_at` guard before changing the current DB guard.

---

### `accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex` (worker, event-driven/request-response)

**Analog:** `accrue/lib/accrue/webhook/dispatch_worker.ex` and `accrue/lib/accrue/workers/dunning_step.ex`

**Queue/max-attempt pattern** (`dispatch_worker.ex`, lines 39-52):
```elixir
use Oban.Worker,
  queue: :accrue_webhooks,
  max_attempts: 25

@impl Oban.Worker
def perform(%Oban.Job{
      args: %{"webhook_event_id" => id},
      attempt: attempt,
      max_attempts: max_attempts
    }) do
```

**JSON-safe args and load pattern** (`dunning_step.ex`, lines 81-108):
```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: args} = job) do
  Accrue.Oban.Middleware.put(job)

  %{
    "subscription_id" => subscription_id,
    "step_key" => step_key_str,
    "campaign_started_at" => anchor_iso
  } = args

  {:ok, anchor, _offset} = DateTime.from_iso8601(anchor_iso)

  case Repo.get(Subscription, subscription_id) do
    %Subscription{} = sub ->
      if campaign_active?(sub) do
        deliver_step(sub, step_key_str, anchor, args)
        chain_next(subscription_id, step_key_str, anchor, args)
        {:ok, :delivered}
      else
        {:cancel, :recovered}
      end

    nil ->
      {:cancel, :recovered}
  end
end
```

**Enqueue args pattern** (`dunning_step.ex`, lines 124-135):
```elixir
@spec enqueue_step(binary(), atom(), DateTime.t(), map()) ::
        {:ok, Oban.Job.t()} | {:error, term()}
def enqueue_step(subscription_id, step_key, %DateTime{} = campaign_started_at, extra \\ %{})
    when is_binary(subscription_id) and is_atom(step_key) and is_map(extra) do
  %{
    "subscription_id" => subscription_id,
    "step_key" => Atom.to_string(step_key),
    "campaign_started_at" => maybe_iso8601(campaign_started_at),
    "customer_id" => Map.get(extra, :customer_id) || Map.get(extra, "customer_id"),
    "invoice_id" => Map.get(extra, :invoice_id) || Map.get(extra, "invoice_id")
  }
```

**Apply:** Use `queue: :accrue_webhooks`, string-keyed scalar args like `%{"customer_id" => customer.id}`, `Repo.get(Customer, customer_id)`, and return `{:cancel, :customer_not_found}` for missing rows. Avoid struct args and atom-key matching.

---

### `scripts/ci/verify_entitlement_sync_isolation.sh` (config/CI guard, batch)

**Analog:** same script.

**Gate files and token pattern** (lines 33-49):
```bash
gate_path_files=(
  "${lib}/accrue/entitlements.ex"
  "${lib}/accrue/entitlements/resolver.ex"
  "${lib}/accrue/entitlements/resolver/local_map.ex"
)

hits=$(grep -rnE \
  '^[^#]*(EntitlementSummary|StripeSync|accrue_entitlement_summaries|stripe_native_sync)' \
  "${gate_path_files[@]}" \
  || true)
```

**Failure contract** (lines 51-56):
```bash
if [[ -n "${hits}" ]]; then
  echo "verify_entitlement_sync_isolation: FAIL — advisory-cache ref reachable from the always-on gate path:" >&2
  echo "${hits}" >&2
  echo "The Stripe-native entitlement-summary cache is observational-only (D-01); it must NEVER be referenced from the gate-decision path (T-127-09)." >&2
  exit 1
fi
```

**Apply:** Extend the alternation with `list_active_entitlements` and the final shared writer symbol, likely `Reconcile`. Add a negative-path proof that inserts or points the script at a gate-path fixture containing real code references and asserts non-zero exit.

---

### `accrue/lib/accrue/entitlements/admin.ex` (documentation/domain seam, read-only request-response)

**Analog:** same file.

**Existing deferral line to replace** (lines 6-10):
```elixir
NOT a public gate API — there is no boolean `entitled?`-style surface here
(Phase 123 D-07 `fetch_entitled/2` stays deferred). This module answers the
operator question *"what does the resolver currently grant this customer, and
what entitling `price_id`s is it silently discarding?"* by returning a
`{resolved, unmapped_price_ids}` pair — never a grant/deny decision.
```

**Read-only resolver pattern** (lines 34-49):
```elixir
alias Accrue.Entitlements.Resolver.LocalMap

@spec resolve_for_customer(Accrue.Billing.Customer.t()) ::
        {resolved :: map(), unmapped_price_ids :: [String.t()]}
def resolve_for_customer(%Accrue.Billing.Customer{} = customer) do
  {LocalMap.fold_for_customer(customer), LocalMap.unmapped_entitling_price_ids(customer)}
end
```

**Apply:** Replace the parenthetical with closure language: `fetch_entitled/2` is closed/will-not-build because network-backed grant predicates fail open; diagnostics are served by `resolve_for_customer/1` and `StripeSync.summary_for_customer/1`.

---

### `accrue/guides/entitlements.md` (docs, read-only explanatory)

**Analog:** existing advisory sync section.

**Observational-only wording** (lines 250-269):
```markdown
> **The disclaimer, plainly: `:advisory` does NOT change `entitled?` /
> `has_active_plan?`.** When sync is enabled, Accrue records each
> `entitlements.active_entitlement_summary.updated` webhook into an advisory
> cache for **audit, telemetry, and the admin read-seam** — and nothing else.
> Local plan→feature mapping stays **canonical** in v1.x; the gate path never
> reads the cache. `entitled?` behaves byte-for-byte the same with sync ON, OFF,
> or as it did after Phase 126.
```

**Deferred pull wording to update** (lines 337-347):
```markdown
### Deferred: the full paginated read (`lattice_stripe >= 1.2`)

The complete fix for both missed webhooks (eventual consistency) and the
10-entitlement cap is a **full paginated read** of Stripe's
`GET /v1/entitlements/active_entitlements` API — fetched on startup and to
reconcile after a webhook delivery failure, following Stripe's own guidance.
That read is **deferred**: `lattice_stripe 1.1` has no Entitlements list API, so
the monotonic-snapshot reducer is the complete in-scope path for v1.x.
```

**Apply:** Update this section for the Phase 213 opt-in pull refresh now that `lattice_stripe ~> 2.0` is present. Add the same `fetch_entitled/2` closed/will-not-build sentence from `admin.ex`.

---

### `accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs` (test, CRUD/request-response)

**Analog:** `default_handler_entitlement_summary_test.exs`, `stripe_sync_disabled_isolation_test.exs`, `BillingCase`.

**BillingCase setup pattern** (`billing_case.ex`, lines 25-44, 47-62):
```elixir
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

  :ok = Accrue.Processor.Fake.reset_preserve_connect()
```

**Config setup pattern** (`default_handler_entitlement_summary_test.exs`, lines 46-58):
```elixir
defp enable_advisory_sync do
  prev = Application.get_env(:accrue, :entitlements)
  merged = Keyword.put(prev || [], :stripe_native_sync, :advisory)
  Application.put_env(:accrue, :entitlements, merged)

  on_exit(fn ->
    if prev do
      Application.put_env(:accrue, :entitlements, prev)
    else
      Application.delete_env(:accrue, :entitlements)
    end
  end)
end
```

**Disabled/no row assertion pattern** (`default_handler_entitlement_summary_test.exs`, lines 252-260):
```elixir
describe "disabled (default) off-lane" do
  test "sync :disabled -> {:ok, :ignored}, no row written", %{customer: customer} do
    refute Accrue.Config.stripe_native_sync?()

    event = StripeFixtures.entitlement_summary_event(customer: customer.processor_id)

    assert {:ok, :ignored} = Accrue.Webhook.DefaultHandler.handle(event)
    assert Repo.aggregate(EntitlementSummary, :count) == 0
  end
end
```

**Gate isolation runtime pattern** (`stripe_sync_disabled_isolation_test.exs`, lines 61-90):
```elixir
test "entitled?/2 issues zero queries against the cache table with sync :disabled" do
  refute Accrue.Config.stripe_native_sync?()

  oid = Ecto.UUID.generate()
  Factory.active_subscription(%{owner_id: oid, price_id: "price_pro"})
  billable = %TestUser{id: oid}

  test_pid = self()
  handler_id = "ent-isolation-#{System.unique_integer([:positive])}"

  :telemetry.attach_many(
    handler_id,
    [@test_repo_query_event, @canonical_repo_query_event],
    fn _event, _meas, meta, _ ->
      sql = Map.get(meta, :query, "")

      if is_binary(sql) and String.contains?(sql, @cache_table) do
        send(test_pid, {:cache_query, sql})
      end
    end,
    nil
  )

  assert Accrue.entitled?(billable, :reports)
  refute_received {:cache_query, _}
end
```

**Apply:** Tests should seed Fake entitlements, call `StripeSync.refresh/2`, assert row shape/count/truncated false/source pull, assert disabled does not increment `Fake.call_count(:list_active_entitlements)` or create a row, and assert grant decisions are identical with empty/stale/contradictory advisory rows.

---

### `accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs` (test, event-driven)

**Analog:** `accrue/test/accrue/workers/dunning_step_test.exs`

**Oban.Testing pattern** (lines 27-35):
```elixir
use Accrue.BillingCase, async: false

use Oban.Testing, repo: Accrue.TestRepo

import Ecto.Query, only: [from: 2]

alias Accrue.Billing.{Customer, Subscription}
alias Accrue.Events.Event, as: LedgerEvent
alias Accrue.Workers.DunningStep
```

**String args and perform_job pattern** (lines 71-78, 105-115):
```elixir
defp args(sub, step_key, campaign_started_at, customer) do
  %{
    "subscription_id" => sub.id,
    "step_key" => Atom.to_string(step_key),
    "campaign_started_at" => DateTime.to_iso8601(campaign_started_at),
    "customer_id" => customer.id,
    "invoice_id" => "in_step_test"
  }
end

test "a recovered (not past_due) sub returns {:cancel, :recovered} and delivers nothing",
     %{customer: cus} do
  sub = seed_sub(cus, %{status: :active, dunning_campaign_started_at: @anchor})

  assert {:cancel, :recovered} =
           perform_job(DunningStep, args(sub, :reminder, @anchor, cus))

  refute_received {:accrue_email_delivered, _type, _assigns}
  assert [] = all_enqueued(worker: DunningStep)
end
```

**Apply:** Use `perform_job(Accrue.Entitlements.StripeSync.RefreshWorker, %{"customer_id" => customer.id})`; assert it delegates to `StripeSync.refresh/1`, writes when enabled, returns cancel for missing customer, and inherits disabled no-op behavior.

---

### `accrue/test/accrue/processor/stripe_test.exs` (test, facade boundary)

**Analog:** same file.

**Static facade test pattern** (lines 296-325):
```elixir
describe "facade lockdown — lattice_stripe is isolated" do
  test "LatticeStripe module references only appear inside Accrue.Processor.Stripe.* files" do
    files =
      Path.wildcard("lib/accrue/**/*.ex")
      |> Enum.filter(fn path ->
        File.read!(path) =~ ~r/\bLatticeStripe\b/
      end)
      |> Enum.sort()

    allowed =
      Enum.sort([
        "lib/accrue/processor/stripe.ex",
        "lib/accrue/processor/stripe/error_mapper.ex",
        "lib/accrue/webhook/event.ex",
        "lib/accrue/webhook/ingest.ex",
        "lib/accrue/webhook/plug.ex",
        "lib/accrue/webhook/signature.ex"
      ])

    assert files == allowed,
           "LatticeStripe may only be referenced inside Accrue.Processor.Stripe. " <>
             "Found in: #{inspect(files)}"
  end
end
```

**Apply:** Do not expand allowed modules for entitlements pull. The new raw SDK reference belongs in `processor/stripe.ex`, so this test should remain green.

## Shared Patterns

### Observational-Only Gate Isolation
**Source:** `accrue/lib/accrue/entitlements/stripe_sync.ex`, `scripts/ci/verify_entitlement_sync_isolation.sh`  
**Apply to:** `StripeSync.refresh/2`, `Reconcile`, tests, docs, isolation guard

The allowed dependency direction is `sync/read seam -> billing cache`; gate files must not reference `EntitlementSummary`, `StripeSync`, `stripe_native_sync`, `list_active_entitlements`, or the shared writer symbol.

### Config-Off Early Return
**Source:** `accrue/lib/accrue/webhook/default_handler.ex` lines 313-319; `accrue/lib/accrue/config.ex` lines 959-979  
**Apply to:** `StripeSync.refresh/2`

`Accrue.Config.stripe_native_sync?()` is the first branch. Disabled returns before processor or repo work. For `refresh/2`, use `{:ok, :disabled}` rather than webhook's `{:ok, :ignored}` per phase decision.

### Fake Processor Over Mocking
**Source:** `accrue/lib/accrue/processor/fake.ex`, `accrue/test/support/billing_case.ex`  
**Apply to:** Refresh tests and callback tests

Follow the named GenServer state/stub pattern and `BillingCase` setup. Seed entitlements in Fake; do not mock `LatticeStripe` and do not call live Stripe.

### Summary Writer Extraction
**Source:** `accrue/lib/accrue/webhook/default_handler.ex` lines 500-782  
**Apply to:** `Accrue.Entitlements.Reconcile` and `DefaultHandler`

Extract rather than duplicate `reduce_entitlement_summary` validation, customer lookup, material-change detection, `EntitlementSummary.force_changeset/2`, telemetry, ledger write, stale rescue, watermark carry-forward, and livemode carry-forward.

### Oban Worker Args
**Source:** `accrue/lib/accrue/workers/dunning_step.ex` lines 81-135  
**Apply to:** `RefreshWorker` and worker test

Use string-keyed scalar JSON args. Reload local rows inside `perform/1`. Return `{:cancel, reason}` for non-retryable missing state.

## No Analog Found

No files lack an analog. The shared reconciler is a new module, but its implementation should be an extraction from `DefaultHandler`, so it has a strong source analog.

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue/test/accrue`, `accrue/test/support`, `scripts/ci`, `accrue/deps/lattice_stripe/lib/lattice_stripe/entitlements`  
**Files scanned:** 473 source/test/script/docs files under the focused scopes  
**Pattern extraction date:** 2026-07-30
