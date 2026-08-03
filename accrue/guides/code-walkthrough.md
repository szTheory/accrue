# Code walkthrough

This guide begins where the [Architecture guide](architecture.md) stops. Hold one route in your
head: a host asks for a direct subscription, Accrue persists the resulting local projection, and a
later webhook converges that projection before entitlements read it.

The excerpts below are shortened from current source. A `# ...` marks every deliberate cut.
Internal modules and private functions are shown to explain the design; they are not promised public
API. Integrations should enter through the documented host facade and `Accrue.Billing` surface.

## 1. The host owns the front door

The generated facade begins as a delegation point. In a real application, authorization and product
policy accumulate here while processor normalization stays in core.

```elixir
# ...
alias Accrue.Billing

# Host policy hook: authorize who may subscribe this billable.
def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end
# ...
```

Notice that the billable is still a host value. A controller or LiveView need not know how it maps to
a processor customer.

## 2. The library validates, then supervises nothing

Accrue's OTP application performs safety checks before any billing work. Its supervisor deliberately
has no children because the host owns Repo, Oban, HTTP clients, and optional PDF processes.

```elixir
# ...
@impl true
def start(_type, _args) do
  :ok = Accrue.Config.validate_at_boot!()
  :ok = Accrue.Auth.Default.boot_check!()
  :ok = warn_on_secret_collision()
  :ok = warn_pdf_adapter_unavailable()
  :ok = warn_oban_queue_vs_pdf_pool()
  :ok = warn_company_address_locale_mismatch()

  children = []

  Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
end
# ...
```

Boot failure is preferable to discovering an invalid adapter or missing safety boundary after a
money-moving request begins.

## 3. Configuration fails before billing starts

`Accrue.Config` validates only keys it owns. Adapter-specific keys can coexist in the application
environment without being mistaken for core options.

```elixir
# ...
@spec validate_at_boot!() :: :ok
def validate_at_boot! do
  known_keys = Keyword.keys(@schema)

  opts =
    :accrue
    |> Application.get_all_env()
    |> Keyword.take(known_keys)

  _ = NimbleOptions.validate!(opts, @schema)
  _ = maybe_validate_boot_setup!(opts)
  :ok
end
# ...
```

This is the configuration half of the ownership boundary: Accrue defines what must be true; the host
chooses values and starts the required infrastructure.

## 4. The public operation adds observability

The public context is intentionally small at the point of entry. Its added value here is a named
billing span and a stable facade; the detailed state transition lives elsewhere.

```elixir
# ...
def subscribe(user, price_id_or_opts \\ [], opts \\ []) do
  span_billing(:subscription, :create, user, opts, fn ->
    SubscriptionActions.subscribe(user, price_id_or_opts, opts)
  end)
end

def subscribe!(user, price_id_or_opts \\ [], opts \\ []) do
  span_billing(:subscription, :create, user, opts, fn ->
    SubscriptionActions.subscribe!(user, price_id_or_opts, opts)
  end)
end
# ...
```

The non-raising and raising variants share the same telemetry boundary.

## 5. A billable becomes a customer

Subscription actions accept either an existing local customer or a host billable. The latter takes
the lazy customer path before the direct-create operation continues.

```elixir
# ...
def subscribe(billable, price_spec, opts \\ [])

def subscribe(%Customer{} = customer, price_spec, opts) do
  do_subscribe(customer, price_spec, opts)
end

def subscribe(billable, price_spec, opts) do
  with {:ok, customer} <- Accrue.Billing.customer(billable) do
    do_subscribe(customer, price_spec, opts)
  end
end
# ...
```

That split keeps host identity concerns out of adapter request assembly.

## 6. One function establishes support, identity, and atomicity

This is the outbound journey's center. It checks the declared support slice, derives a deterministic
key, calls the adapter, and turns the response into one transactional local outcome. The source still
uses the historical variable name `stripe_sub`; the configured adapter is the actual authority.

```elixir
# ...
defp do_subscribe(%Customer{} = customer, price_spec, opts) do
  with :ok <- ensure_subscribe_support() do
    do_subscribe_supported(customer, price_spec, opts)
  end
end

defp do_subscribe_supported(%Customer{} = customer, price_spec, opts) do
  {price_id, quantity} = normalize_price_spec(price_spec)
  op_id = resolve_operation_id(opts)
  idem_key =
    Idempotency.key(
      :create_subscription,
      customer.id,
      op_id,
      subscribe_sequence(price_id, quantity, opts)
    )

  {item_params, trial_end} = build_subscribe_params({price_id, quantity}, opts)

  result =
    with {:ok, processor_params} <-
           build_subscription_request(customer, item_params, trial_end, opts),
         _result <- :ok do
      case ensure_customer_tax_location(customer, opts) do
        :ok ->
          case Processor.__impl__().create_subscription(
                 processor_params,
                 [idempotency_key: idem_key] ++ sanitize_opts(opts)
               ) do
            {:ok, stripe_sub} ->
              Repo.transact(fn ->
                with :ok <- ensure_valid_tax_location(stripe_sub, opts),
                     {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
                     {:ok, sub} <- insert_subscription(customer.id, attrs),
                     {:ok, _items} <- upsert_items(sub, stripe_sub),
                     {:ok, _} <-
                       record_event("subscription.created", sub, %{price_id: price_id}) do
                  sub = Repo.preload(sub, :subscription_items, force: true)
                  {:ok, sub}
                end
              end)

            # ...
          end

        # ...
      end
    end

  IntentResult.wrap(result)
end
# ...
```

The omitted branches release reserved discount state and return errors. They do not create an
alternate success path. `IntentResult.wrap/1` promotes payment authentication into the public
action-required shape.

## 7. The processor behaviour is a narrow waist

The behaviour defines the value crossing the boundary. Runtime resolution and capability labels let
the same core choose Stripe, Braintree, Fake, or a custom adapter without claiming they support the
same slices.

```elixir
# ...
@callback create_subscription(params(), opts()) :: result()
@callback retrieve_subscription(id(), opts()) :: result()
@callback update_subscription(id(), params(), opts()) :: result()
@callback cancel_subscription(id(), opts()) :: result()

# ...
@doc false
@spec __impl__() :: module()
def __impl__, do: Application.get_env(:accrue, :processor, Accrue.Processor.Fake)

# ...
@spec first_party_supported?(atom() | [atom()]) :: boolean()
def first_party_supported?(path) when is_atom(path), do: first_party_supported?([path])

def first_party_supported?(path) when is_list(path),
  do: Accrue.Processor.Capabilities.first_party_supported?(capabilities(), path)
# ...
```

Fake is an executable contract for deterministic tests and demos. It is not evidence that remote
authentication, vaulting, webhook naming, or provider failures are interchangeable.

## 8. Stripe implements the direct-create contract

The Stripe adapter adds the expansion needed for SCA inspection, derives processor options, calls
LatticeStripe, and translates its response into Accrue's map-shaped adapter result.

```elixir
# ...
@impl Accrue.Processor
def create_subscription(params, opts) when is_map(params) and is_list(opts) do
  client = build_client!(opts)
  params = ensure_expand(params, ["latest_invoice.payment_intent"])
  stripe_opts = stripe_opts(:create_subscription, subject_of(params, "sub"), opts)

  client
  |> LatticeStripe.Subscription.create(stringify_keys(params), stripe_opts)
  |> translate_resource()
end
# ...
```

Braintree's direct-create implementation is intentionally not excerpted here. Its supported path
requires a host-acquired vault reference, while Stripe accepts the Stripe-shaped request assembled
by subscription actions.

## 9. Processor data becomes a local projection

Projection code is where provider response shape stops leaking. It selects a provider-specific
normalizer and produces attributes accepted by the local subscription schema.

```elixir
# ...
@spec decompose(map(), keyword()) :: {:ok, map()}
def decompose(subscription, opts \\ [])

def decompose(subscription, opts) when is_map(subscription) and is_list(opts) do
  processor = Keyword.get(opts, :processor, processor_atom())

  case processor do
    :paddle -> {:ok, paddle_attrs(subscription)}
    :braintree -> {:ok, braintree_attrs(subscription)}
    _ -> {:ok, stripe_attrs(subscription)}
  end
end

defp stripe_attrs(stripe_sub) do
  automatic_tax = automatic_tax_fields(get(stripe_sub, :automatic_tax))

  %{
    processor_id: get(stripe_sub, :id),
    status: parse_status(get(stripe_sub, :status)),
    cancel_at_period_end: get(stripe_sub, :cancel_at_period_end) || false,
    pause_collection: parse_pause_collection(get(stripe_sub, :pause_collection)),
    automatic_tax: automatic_tax.enabled,
    automatic_tax_status: automatic_tax.status,
    automatic_tax_disabled_reason: automatic_tax.disabled_reason,
    current_period_start: unix_to_dt(get(stripe_sub, :current_period_start)),
    current_period_end: unix_to_dt(get(stripe_sub, :current_period_end)),
    # ...
    data: normalize_data(stripe_sub),
    metadata: get(stripe_sub, :metadata) || %{}
  }
end
# ...
```

The full raw map remains normalized into `data` for round-trip safety, but named fields give local
queries stable lifecycle semantics.

## 10. Lifecycle is more than a status atom

The schema stores remote identity, lifecycle overlays, and ordering watermarks. The entitlement
predicate composes the meaningful conditions instead of asking product code to repeat them.

```elixir
# ...
schema "accrue_subscriptions" do
  belongs_to(:customer, Accrue.Billing.Customer)

  field(:processor, :string)
  field(:processor_id, :string)
  field(:status, Ecto.Enum, values: @statuses)
  field(:cancel_at_period_end, :boolean, default: false)
  field(:pause_collection, :map)
  field(:ended_at, :utc_datetime_usec)
  field(:last_stripe_event_ts, :utc_datetime_usec)
  field(:last_stripe_event_id, :string)
  # ...
end

# ...
@spec entitling?(%__MODULE__{} | map()) :: boolean()
def entitling?(sub), do: active?(sub) and not paused?(sub) and not canceled?(sub)
# ...
```

The `last_stripe_event_*` names are legacy Stripe-shaped column names even when another adapter owns
the row. They are local ordering metadata, not proof that Stripe is always configured.

## 11. Webhook receipt verifies raw bytes

The inbound journey starts from bytes retained before body parsing. A missing signature is an error,
not a development-mode bypass.

```elixir
# ...
defp do_call(conn, :stripe, endpoint) do
  raw_body = flatten_raw_body(conn)
  sig_header = get_req_header(conn, "stripe-signature") |> List.first()

  unless sig_header do
    raise Accrue.SignatureError, reason: "missing stripe-signature header"
  end

  secrets = resolve_secrets!(endpoint, :stripe)
  stripe_event = Signature.verify!(raw_body, sig_header, secrets)

  # Transactional persist + Oban enqueue.
  Accrue.Webhook.Ingest.run(conn, :stripe, stripe_event, raw_body, endpoint)
end
# ...
```

Only a verified event reaches ingest. Endpoint-aware secret lookup also fails closed when the named
endpoint is not configured.

## 12. Receipt becomes three durable facts

Ingest commits the evidence row, dispatch job, and received ledger event together. The duplicate
branch returns the already stored row and skips both secondary writes.

```elixir
# ...
result =
  Accrue.Repo.transact(fn repo ->
    case persist_event(repo, processor_str, stripe_event, raw_body, endpoint_atom) do
      {:ok, {:duplicate, _} = duplicate} ->
        {:ok, duplicate}

      {:ok, {:new, row} = persisted} ->
        with {:ok, _job} <- repo.insert(DispatchWorker.new(%{webhook_event_id: row.id})),
             {:ok, _event} <- record_received_event(processor_str, stripe_event, row) do
          {:ok, persisted}
        else
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end)

case result do
  {:ok, {:new, _}} ->
    conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

  {:ok, {:duplicate, _}} ->
    conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

  {:error, reason} ->
    Logger.error("Webhook ingest failed: #{inspect(reason, limit: 200)}")
    conn |> send_resp(500, Jason.encode!(%{ok: false})) |> halt()
end
# ...
```

The HTTP response can be retried safely because uniqueness is enforced at persistence, not inferred
from timing in the Plug process.

## 13. The queued event is intentionally lean

The worker projection extracts only the identity required to route and refetch. This excerpt also
exposes two current constraints: queued `created_at` is receipt time, and the bounded processor map
does not include Braintree.

```elixir
# ...
@processor_atoms %{
  "stripe" => :stripe,
  "stripe_connect" => :stripe_connect,
  "fake" => :fake
}

# ...
@spec from_webhook_event(Accrue.Webhook.WebhookEvent.t()) :: t()
def from_webhook_event(%Accrue.Webhook.WebhookEvent{} = row) do
  object_id =
    case row.data do
      %{"data" => %{"object" => %{"id" => id}}} -> id
      _ -> nil
    end

  %__MODULE__{
    type: row.type,
    object_id: object_id,
    livemode: row.livemode,
    created_at: row.received_at,
    processor_event_id: row.processor_event_id,
    processor: processor_to_atom(row.processor)
  }
end
# ...
```

Consequently, canonical refetch is the queued path's primary convergence guarantee. Braintree
receipt persists, but queued conversion currently raises before its dedicated handler can run.
Direct Braintree subscription creation does not use this dispatch conversion and is unaffected.

## 14. Dispatch separates core retries from user extensions

The worker records status, establishes webhook actor context, runs the non-disableable reducer first,
then isolates user handlers. Only a built-in handler failure drives the 25-attempt retry and eventual
dead-letter lifecycle.

```elixir
# ...
use Oban.Worker,
  queue: :accrue_webhooks,
  max_attempts: 25

# ...
event = Event.from_webhook_event(row)

ctx = %{
  attempt: attempt,
  max_attempts: max_attempts,
  webhook_event_id: id,
  endpoint: row.endpoint,
  meter_error_object: meter_error_object
}

Accrue.Actor.put_current(%{type: :webhook, id: row.processor_event_id})

default_handler =
  case row.endpoint do
    :connect -> ConnectHandler
    _ -> DefaultHandler
  end

default_result = safe_handle(default_handler, event, ctx)

_user_results =
  Accrue.Config.webhook_handlers()
  |> Enum.map(fn handler -> safe_handle(handler, event, ctx) end)

case default_result do
  :ok ->
    mark_succeeded(repo, row)
    :ok

  {:error, reason} ->
    mark_failed_or_dead(repo, row, attempt, max_attempts)
    {:error, reason}
end

# ...
def safe_handle(handler, event, ctx) do
  handler.handle_event(event.type, event, ctx)
rescue
  e ->
    Logger.error(
      "Webhook handler #{inspect(handler)} crashed: #{Exception.format(:error, e, __STACKTRACE__)}"
    )

    :telemetry.execute(
      [:accrue, :webhook, :handler, :exception],
      %{},
      %{module: handler, error: e}
    )

    {:error, e}
end
# ...
```

The rescue contains the failure locally, logs it, and emits telemetry before returning the error
tuple to the caller that decides whether the failure is retryable.

## 15. Reduction checks order, then refetches truth

Subscription reduction runs inside the shared transactional wrapper. A strictly older watermark
returns without a processor call. Otherwise the reducer refetches canonical state, projects it,
updates items, and appends its domain event before the transaction completes.

```elixir
# ...
defp reduce_subscription(action, evt_id, evt_ts, obj) do
  stripe_id = get(obj, :id)

  reduce_row(:subscription, stripe_id, evt_ts, evt_id, fn row ->
    with {:ok, canonical} <- Processor.__impl__().fetch(:subscription, stripe_id),
         {:ok, attrs} <- SubscriptionProjection.decompose(canonical),
         attrs <- stamp_watermark(attrs, evt_ts, evt_id),
         {:ok, upsert_result} <- upsert_subscription(row, canonical, attrs) do
      case upsert_result do
        :deferred ->
          {:ok, :deferred}

        %Subscription{} = updated ->
          with {:ok, _} <- upsert_subscription_items(updated, canonical),
               :ok <- maybe_emit_dunning_exhaustion(row, updated, canonical),
               :ok <- maybe_finalize_dunning_campaign(row, updated, canonical),
               {:ok, _} <-
                 record_event(
                   subscription_event_type(action),
                   "Subscription",
                   updated.id,
                   evt_id
                 ) do
            {:ok, updated}
          end
      end
    end
  end)
end

# ...
defp reduce_row(object_type, stripe_id, evt_ts, evt_id, fun) do
  Repo.transact(fn ->
    row = load_row(object_type, stripe_id)

    case check_stale(row, evt_ts) do
      :stale ->
        :telemetry.execute(
          [:accrue, :webhooks, :stale_event],
          %{},
          %{object_type: object_type, stripe_id: stripe_id, event_id: evt_id}
        )

        {:ok, :stale}

      :ok ->
        fun.(row)
    end
  end)
end
# ...
```

For queued events, `evt_ts` is receipt time because of the previous projection. For the raw/Fake
entry point, it can be processor-created time. Either way, the reducer never treats the event's
object snapshot as the canonical current subscription.

## 16. Entitlements read the projection and fail closed

The default resolver performs a local query only. `Query.entitling/1` is the SQL twin of the
subscription predicate; joining items yields the processor price IDs and quantities that the
configured plan catalog can fold.

```elixir
# ...
defp none_lane_items(customer_id) do
  Subscription
  |> Query.entitling()
  |> where([s], s.customer_id == ^customer_id)
  |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
  |> select([_s, i], {i.price_id, i.quantity})
  |> Accrue.Repo.all()
  |> Enum.map(fn {price_id, quantity} -> {price_id, quantity, false} end)
end
# ...
```

No customer, no qualifying subscription, no catalog mapping, or a resolver failure all produce a
deny result at the public `Accrue.Entitlements` boundary. Admin may diagnose the same local fold, but
it does not become authoritative for access.

## 17. The duplicate test states the ingest contract

The most useful tests read like architecture. This one proves that HTTP success on a retry does not
mean duplicated durable work.

```elixir
# ...
test "duplicate POST returns 200 with no second row or Oban job" do
  {body, _sig} = signed_event()
  stripe_event = build_lattice_event(body)

  conn1 = Plug.Test.conn(:post, "/webhook/stripe")
  result1 = Ingest.run(conn1, @processor, stripe_event, body)
  assert result1.status == 200

  # Second call with same event
  conn2 = Plug.Test.conn(:post, "/webhook/stripe")
  result2 = Ingest.run(conn2, @processor, stripe_event, body)
  assert result2.status == 200

  # Still only one row
  events = Accrue.TestRepo.all(WebhookEvent)
  assert length(events) == 1

  # Only one Oban job (from first call)
  jobs = Accrue.TestRepo.all(Oban.Job)
  assert length(jobs) == 1
end
# ...
```

The database uniqueness contract, not a mocked call count, is the behavior under test.

## 18. The ordering test states the reducer contract

The raw/Fake reducer test pins the strict comparison: an older processor-created timestamp emits
stale telemetry and cannot move the watermark backward.

```elixir
# ...
test "older event is skipped with :stale_event telemetry and no refetch", %{sub: sub} do
  newer_ts = DateTime.add(Accrue.Clock.utc_now(), 3600, :second)

  {:ok, _} =
    sub
    |> Subscription.changeset(%{
      last_stripe_event_ts: newer_ts,
      last_stripe_event_id: "evt_new"
    })
    |> Repo.update()

  test_pid = self()

  :telemetry.attach(
    "test-stale-#{System.unique_integer([:positive])}",
    [:accrue, :webhooks, :stale_event],
    fn evt, meas, meta, _ -> send(test_pid, {:stale, evt, meas, meta}) end,
    nil
  )

  older_event =
    StripeFixtures.webhook_event(
      "customer.subscription.updated",
      StripeFixtures.subscription_created(%{"id" => sub.processor_id}),
      %{
        "id" => "evt_older",
        "created" => DateTime.to_unix(DateTime.add(newer_ts, -1800, :second))
      }
    )

  DefaultHandler.handle(older_event)

  assert_received {:stale, _, _, %{event_id: "evt_older"}}

  unchanged = Repo.get!(Subscription, sub.id)
  assert unchanged.last_stripe_event_id == "evt_new"
end
# ...
```

Read this beside the queued timestamp caveat rather than generalizing it to provider-created ordering
on every entry path.

## Your next source-reading sessions

- **Subscribe:** `Accrue.Billing` → `Accrue.Billing.SubscriptionActions` →
  `Accrue.Processor` → `Accrue.Billing.SubscriptionProjection`. Where do host policy, remote
  authority, and local atomicity change hands?
- **Webhook:** `Accrue.Webhook.Plug` → `Accrue.Webhook.Ingest` →
  `Accrue.Webhook.DispatchWorker` → `Accrue.Webhook.DefaultHandler`. What survives a duplicate, a
  crash, and a final retry?
- **Entitlements:** `Accrue.Entitlements` → `Accrue.Entitlements.Resolver.LocalMap` →
  `Accrue.Billing.Query`. Which exact local states can grant access, and how does uncertainty deny?
- **Dunning:** `Accrue.Jobs.DunningSweeper` → `Accrue.Workers.DunningStep` → subscription
  predicates. What anchors a campaign, and what makes recovery cancel outstanding work?
- **Invoice and PDF:** `Accrue.Billing.InvoiceActions` → `Accrue.InvoiceRenderer` → the configured
  renderer. Which work is synchronous, queued, or host-supervised?
- **Audit:** `Accrue.Events` → `Accrue.Events.Event`. Which writes share a transaction with their
  audit evidence, and how is tampering blocked?
- **Admin:** `AccrueAdmin.Router` → an Admin LiveView → core queries or facade. Does each operator
  mutation preserve host auth and reuse core semantics?
- **Portal:** `AccruePortal.Router` → `AccruePortal.BillingReadModel` → `Accrue.Billing`. Which actions
  are local UI concerns, and which cross the processor boundary?

Return to the [Architecture guide](architecture.md) when you need the package and data-authority map.
For operational depth, continue with [Webhooks](webhooks.md),
[Lifecycle semantics](lifecycle_semantics.md), [Entitlements](entitlements.md),
[Testing](testing.md), [Dunning](dunning.md), [PDF rendering](pdf.md), and
[Email](email.md).
