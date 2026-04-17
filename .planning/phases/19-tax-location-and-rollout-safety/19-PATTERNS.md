# Phase 19: Tax Location and Rollout Safety - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 24
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing.ex` | service | request-response | `accrue/lib/accrue/billing.ex` | exact |
| `accrue/lib/accrue/billing/customer.ex` | model | CRUD | `accrue/lib/accrue/billing/customer.ex` | exact |
| `accrue/lib/accrue/processor/stripe.ex` | service | request-response | `accrue/lib/accrue/processor/stripe.ex` | exact |
| `accrue/lib/accrue/processor/stripe/error_mapper.ex` | utility | transform | `accrue/lib/accrue/processor/stripe/error_mapper.ex` | exact |
| `accrue/lib/accrue/processor/fake.ex` | service | request-response | `accrue/lib/accrue/processor/fake.ex` | exact |
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | request-response | `accrue/lib/accrue/billing/subscription_actions.ex` | exact |
| `accrue/lib/accrue/billing/subscription_projection.ex` | model | transform | `accrue/lib/accrue/billing/subscription_projection.ex` | exact |
| `accrue/lib/accrue/billing/invoice_projection.ex` | model | transform | `accrue/lib/accrue/billing/invoice_projection.ex` | exact |
| `accrue/lib/accrue/billing/subscription.ex` | model | CRUD | `accrue/lib/accrue/billing/subscription.ex` | exact |
| `accrue/lib/accrue/billing/invoice.ex` | model | CRUD | `accrue/lib/accrue/billing/invoice.ex` | exact |
| `accrue/lib/accrue/webhook/default_handler.ex` | middleware | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/customer_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/customers_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/customers_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | component | request-response | `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/customers.ex` | utility | CRUD | `accrue_admin/lib/accrue_admin/queries/customers.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | utility | CRUD | `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` | exact |
| `accrue_admin/lib/accrue_admin/queries/invoices.ex` | utility | CRUD | `accrue_admin/lib/accrue_admin/queries/invoices.ex` | exact |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | component | request-response | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | service | request-response | `examples/accrue_host/lib/accrue_host/billing.ex` | exact |
| `accrue/guides/troubleshooting.md` | guide | transform | `accrue/guides/troubleshooting.md` | exact |
| `guides/testing-live-stripe.md` | guide | transform | `guides/testing-live-stripe.md` | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Facade telemetry + transaction pattern** (`accrue/lib/accrue/billing.ex:530-580`, `610-625`, `689-709`):
```elixir
def create_customer(%{__struct__: mod, id: id} = billable) do
  span_billing(:customer, :create, billable, [], fn ->
    Repo.transact(fn ->
      with {:ok, processor_result} <- Processor.create_customer(params),
           {:ok, customer} <- %Customer{} |> Customer.changeset(customer_attrs) |> Repo.insert(),
           {:ok, _event} <- Events.record(%{type: "customer.created", ...}) do
        {:ok, customer}
      end
    end)
  end)
end

def update_customer(%Customer{} = customer, attrs) when is_map(attrs) do
  span_billing(:customer, :update, customer, [], fn ->
    Repo.transact(fn ->
      with {:ok, updated} <- customer |> Customer.changeset(attrs) |> Repo.update(),
           {:ok, _event} <- Events.record(%{type: "customer.updated", ...}) do
        {:ok, updated}
      end
    end)
  end)
end
```

Use this for the new public tax-location API: keep telemetry at the facade, keep DB write + event record inside `Repo.transact/1`, and avoid silently changing `update_customer/2` semantics.

### `accrue/lib/accrue/billing/customer.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/customer.ex`

**Schema + additive field pattern** (`accrue/lib/accrue/billing/customer.ex:39-68`, `89-97`):
```elixir
schema "accrue_customers" do
  field(:owner_type, :string)
  field(:owner_id, :string)
  field(:processor, :string)
  field(:processor_id, :string)
  field(:metadata, :map, default: %{})
  field(:data, :map, default: %{})
  field(:lock_version, :integer, default: 1)
  ...
end

def changeset(customer_or_changeset, attrs \\ %{}) do
  customer_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
end
```

If Phase 19 stores narrow customer tax-state locally, add it as additive schema fields and keep raw provider payload in `data`.

### `accrue/lib/accrue/processor/stripe.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/stripe.ex`

**Adapter boundary pattern** (`accrue/lib/accrue/processor/stripe.ex:45-73`, `99-113`, `125-133`):
```elixir
@behaviour Accrue.Processor

alias Accrue.Processor.Stripe.ErrorMapper
alias Accrue.Telemetry

def create_customer(params, opts) when is_map(params) and is_list(opts) do
  Telemetry.span([:accrue, :processor, :customer, :create], %{adapter: :stripe, operation: :create_customer}, fn ->
    client
    |> LatticeStripe.Customer.create(stringify_keys(params), stripe_opts)
    |> translate_customer()
  end)
end

def update_customer(id, params, opts)
    when is_binary(id) and is_map(params) and is_list(opts) do
  Telemetry.span([:accrue, :processor, :customer, :update], %{adapter: :stripe, operation: :update_customer}, fn ->
    client
    |> LatticeStripe.Customer.update(id, stringify_keys(params), stripe_opts)
    |> translate_customer()
  end)
end
```

Keep Stripe-specific `tax.validate_location`, address precedence params, and idempotency/version handling in this module only.

### `accrue/lib/accrue/processor/stripe/error_mapper.ex` (utility, transform)

**Analog:** `accrue/lib/accrue/processor/stripe/error_mapper.ex`

**Typed processor-error mapping** (`accrue/lib/accrue/processor/stripe/error_mapper.ex:51-126`):
```elixir
def to_accrue_error(%LatticeStripe.Error{type: :card_error} = raw) do
  %Accrue.CardError{message: raw.message, code: raw.code, processor_error: raw}
end

def to_accrue_error(%LatticeStripe.Error{type: type} = raw)
    when type in [:invalid_request_error, :authentication_error, :api_error, :connection_error] do
  %Accrue.APIError{
    message: raw.message,
    code: raw.code,
    http_status: raw.status,
    request_id: raw.request_id,
    processor_error: raw
  }
end
```

Map `customer_tax_location_invalid` here into a stable Accrue error subtype or an `Accrue.APIError` specialization with safe metadata.

### `accrue/lib/accrue/processor/fake.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/fake.ex`

**Behaviour callback surface** (`accrue/lib/accrue/processor/fake.ex:200-223`):
```elixir
def create_customer(params, opts \\ []) when is_map(params) and is_list(opts) do
  call({:create_customer, params, thread_scope(opts)})
end

def update_customer(id, params, opts \\ [])
    when is_binary(id) and is_map(params) and is_list(opts) do
  call({:update_customer, id, params, opts})
end

def create_subscription(params, opts \\ []) when is_map(params) and is_list(opts) do
  call({:create_subscription, params, opts})
end
```

**Deterministic tax-state helper** (`accrue/lib/accrue/processor/fake.ex:2110-2124`):
```elixir
defp automatic_tax_payload(params) do
  enabled? = automatic_tax_enabled?(params)
  %{enabled: enabled?, status: if(enabled?, do: "complete", else: nil)}
end
```

Phase 19 Fake work should follow this pattern: small helper-driven payload derivation and deterministic callback state, not ad hoc test-only branches in Billing code.

### `accrue/lib/accrue/billing/subscription_actions.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing/subscription_actions.ex`

**Subscription request builder** (`accrue/lib/accrue/billing/subscription_actions.ex:68-103`, `715-718`):
```elixir
stripe_params =
  %{
    customer: customer.processor_id,
    items: [item_params],
    payment_behavior: "default_incomplete",
    expand: ["latest_invoice.payment_intent"]
  }
  |> put_if(:trial_end, trial_end)
  |> maybe_put_automatic_tax(opts)
  |> maybe_put_default_pm(opts)
  |> maybe_put_coupon(opts)
  |> maybe_put_collection_method(opts)

defp maybe_put_automatic_tax(params, opts) do
  enabled = Keyword.get(opts, :automatic_tax, false)
  Map.put(params, :automatic_tax, %{enabled: enabled})
end
```

Use the existing option-normalization pipeline for tax-location preflight or explicit blocking when `automatic_tax: true` is combined with invalid customer location.

### `accrue/lib/accrue/billing/subscription_projection.ex` (model, transform)

**Analog:** `accrue/lib/accrue/billing/subscription_projection.ex`

**Projection helper pattern** (`accrue/lib/accrue/billing/subscription_projection.ex:15-32`, `69-78`):
```elixir
automatic_tax = automatic_tax_fields(get(stripe_sub, :automatic_tax))

%{
  processor_id: get(stripe_sub, :id),
  status: parse_status(get(stripe_sub, :status)),
  automatic_tax: automatic_tax.enabled,
  automatic_tax_status: automatic_tax.status,
  data: normalize_data(stripe_sub),
  metadata: get(stripe_sub, :metadata) || %{}
}

def automatic_tax_fields(%{} = automatic_tax) do
  %{enabled: get(automatic_tax, :enabled) || false, status: get(automatic_tax, :status)}
end
```

Extend this helper-first pattern for `automatic_tax.disabled_reason` instead of parsing nested fields inline in the caller.

### `accrue/lib/accrue/billing/invoice_projection.ex` (model, transform)

**Analog:** `accrue/lib/accrue/billing/invoice_projection.ex`

**Flat invoice attrs + fallback extraction** (`accrue/lib/accrue/billing/invoice_projection.ex:26-99`, `155-165`):
```elixir
invoice_attrs = %{
  processor_id: SubscriptionProjection.get(stripe_inv, :id),
  status: parse_status(SubscriptionProjection.get(stripe_inv, :status)),
  tax_minor: tax_minor(stripe_inv, automatic_tax.enabled),
  automatic_tax: automatic_tax.enabled,
  automatic_tax_status: automatic_tax.status,
  data: SubscriptionProjection.to_string_keys(stripe_inv),
  metadata: SubscriptionProjection.get(stripe_inv, :metadata) || %{}
}

defp tax_minor(stripe_inv, automatic_tax_enabled?) do
  total_details = SubscriptionProjection.get(stripe_inv, :total_details) || %{}
  ...
end
```

Use this same shape for `automatic_tax.disabled_reason`, `last_finalization_error.code`, and other narrow invoice observability fields.

### `accrue/lib/accrue/billing/subscription.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/subscription.ex`

**Additive schema + changeset** (`accrue/lib/accrue/billing/subscription.ex:46-71`, `76-88`, `115-122`):
```elixir
field(:automatic_tax, :boolean, default: false)
field(:automatic_tax_status, :string)
field(:data, :map, default: %{})

@cast_fields ~w[
  ...
  automatic_tax automatic_tax_status
  ...
]a

def changeset(subscription_or_changeset, attrs \\ %{}) do
  subscription_or_changeset
  |> cast(attrs, @cast_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
end
```

Add `automatic_tax_disabled_reason` here if the plan chooses first-class subscription observability.

### `accrue/lib/accrue/billing/invoice.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/invoice.ex`

**Webhook-safe dual changeset pattern** (`accrue/lib/accrue/billing/invoice.ex:41-75`, `81-90`, `109-145`):
```elixir
field(:automatic_tax, :boolean, default: false)
field(:automatic_tax_status, :string)
field(:data, :map, default: %{})

def changeset(invoice_or_changeset, attrs \\ %{}) do
  invoice_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_transition()
  |> optimistic_lock(:lock_version)
end

def force_status_changeset(invoice_or_changeset, attrs \\ %{}) do
  invoice_or_changeset
  |> cast(attrs, @cast_fields)
  |> optimistic_lock(:lock_version)
end
```

Phase 19 invoice error-state fields belong in this additive cast/force-changeset surface, not in bespoke update functions.

### `accrue/lib/accrue/webhook/default_handler.ex` (middleware, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Event-family dispatch pattern** (`accrue/lib/accrue/webhook/default_handler.ex:69-104`, `117-129`):
```elixir
def handle_event("customer.updated", event, _ctx) do
  Logger.debug("DefaultHandler: customer.updated for #{event.object_id}")
  :ok
end

def handle_event(type, %Accrue.Webhook.Event{} = event, _ctx) when is_binary(type) do
  case dispatch(type, event.processor_event_id, event.created_at, %{"id" => event.object_id}) do
    {:ok, _} -> :ok
    other -> other
  end
end

def handle(event) when is_map(event) do
  type = get(event, :type)
  ...
  dispatch(type, evt_id, evt_ts, obj)
end
```

Add `invoice.finalization_failed` here by following the existing `handle_event/3 -> dispatch/4 -> reducer` shape; do not bolt event logic onto LiveViews or tests.

### `accrue_admin/lib/accrue_admin/queries/customers.ex` (utility, CRUD)

**Analog:** `accrue_admin/lib/accrue_admin/queries/customers.ex`

**Cursor-query pattern** (`accrue_admin/lib/accrue_admin/queries/customers.ex:17-37`, `56-71`, `73-98`):
```elixir
Customer
|> filter_query(filter)
|> Behaviour.apply_cursor(@time_field, cursor)
|> order_by([customer], desc: customer.inserted_at, desc: customer.id)
|> limit(^Enum.max([limit + 1, 2]))
|> select([customer], %{id: customer.id, owner_type: customer.owner_type, ...})
|> Repo.all()
|> Behaviour.paginate(limit, @time_field)
```

Add customer tax-risk filters here if customer rows gain narrow location-state fields.

### `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` (utility, CRUD)

**Analog:** `accrue_admin/lib/accrue_admin/queries/subscriptions.ex`

**Joined list + reusable filter dispatch** (`accrue_admin/lib/accrue_admin/queries/subscriptions.ex:18-39`, `63-76`, `78-103`):
```elixir
Subscription
|> join(:inner, [subscription], customer in Customer, on: customer.id == subscription.customer_id)
|> filter_query(filter)
|> select([subscription, customer], %{id: subscription.id, customer_name: customer.name, ...})

defp filter_status(query, "active"), do: Billing.Query.active(query)
defp filter_status(query, "canceling"), do: Billing.Query.canceling(query)
```

Add subscription tax-risk filters in `decode_filter/1` + `filter_query/2`, and prefer shared `Billing.Query` predicates where they exist.

### `accrue_admin/lib/accrue_admin/queries/invoices.ex` (utility, CRUD)

**Analog:** `accrue_admin/lib/accrue_admin/queries/invoices.ex`

**Search + enum coercion pattern** (`accrue_admin/lib/accrue_admin/queries/invoices.ex:17-42`, `64-81`, `83-104`):
```elixir
Invoice
|> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
|> filter_query(filter)
|> select([invoice, customer], %{id: invoice.id, number: invoice.number, status: invoice.status, ...})

{:status, status}, query ->
  where(query, [invoice, _customer], invoice.status == ^String.to_existing_atom(status))
```

Use this module for invoice finalization-failure filters once those fields are projected locally.

### `accrue_admin/lib/accrue_admin/live/customers_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/customers_live.ex`

**List-page shell + KPI pattern** (`accrue_admin/lib/accrue_admin/live/customers_live.ex:14-26`, `123-134`):
```elixir
def mount(_params, session, socket) do
  {:ok,
   socket
   |> assign_shell(admin)
   |> assign(:params, %{})
   |> assign(:table_path, admin_path(admin, "/customers"))
   |> assign(:summary, customer_summary())}
end

defp customer_summary do
  %{
    customer_count: Repo.aggregate(Customer, :count, :id),
    with_default_payment_method_count: ...,
    owner_type_count: ...
  }
end
```

Keep tax-risk list-level summaries here, fed only by query modules or aggregates over local rows.

### `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`

**Shared table component pattern** (`accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:12-24`, `129-161`):
```elixir
<.live_component
  module={DataTable}
  id="subscriptions"
  query_module={Subscriptions}
  path={@table_path}
  params={@params}
  filter_fields={[...]}
/>

defp subscription_summary do
  %{
    active_count: Subscription |> Query.active() |> Repo.aggregate(:count, :id),
    canceling_count: Subscription |> Query.canceling() |> Repo.aggregate(:count, :id),
    paused_count: Subscription |> Query.paused() |> Repo.aggregate(:count, :id),
    past_due_count: Subscription |> Query.past_due() |> Repo.aggregate(:count, :id)
  }
end
```

Phase 19 subscription tax rollup belongs in this summary/table structure, not in ad hoc markup loops.

### `accrue_admin/lib/accrue_admin/live/invoices_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex`

**List KPI + formatter pattern** (`accrue_admin/lib/accrue_admin/live/invoices_live.ex:14-26`, `141-180`):
```elixir
defp invoice_summary do
  %{
    open_count: count_invoices(:open),
    paid_count: count_invoices(:paid),
    uncollectible_count: count_invoices(:uncollectible),
    void_count: count_invoices(:void)
  }
end

defp balance_summary(row) do
  due = format_money(row.amount_due_minor, row.currency)
  paid = format_money(row.amount_paid_minor, row.currency)
  remaining = format_money(row.amount_remaining_minor, row.currency)
  "#{due} due · #{paid} paid · #{remaining} remaining"
end
```

Invoice tax-failure visibility should reuse this balance/status summary style.

### `accrue_admin/lib/accrue_admin/live/customer_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`

**Detail-page tab/query pattern** (`accrue_admin/lib/accrue_admin/live/customer_live.ex:25-44`, `179-236`, `265-274`):
```elixir
socket
|> assign(:customer, customer)
|> assign(:params, %{})
|> assign(:tab, "subscriptions")
|> assign(:tab_counts, tab_counts(customer))

defp tab_counts(customer) do
  %{subscriptions: ..., invoices: ..., charges: ..., payment_methods: ..., events: ..., metadata: ...}
end

defp predicate_summary(subscription) do
  Enum.join([...], " · ")
end
```

If customer detail shows tax-location risk, follow the existing tab-count + local query approach.

### `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex`

**Detail action workflow** (`accrue_admin/lib/accrue_admin/live/subscription_live.ex:31-47`, `237-248`, `319-330`, `353-418`, `454-464`):
```elixir
defp source_event_select(assigns) do
  ~H""" ... """
end

defp pending_action(params, socket) do
  %{
    type: Map.fetch!(params, "action_type"),
    source_event_id: source_event && source_event.id,
    source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
  }
end

defp with_admin_context(user, fun) do
  Actor.with_actor(%{type: :admin, id: Auth.actor_id(user)}, fn -> ... end)
end
```

Any admin recovery action for invalid tax location should follow this staged-action, optional-source-event, admin-audit pattern.

### `accrue_admin/lib/accrue_admin/live/invoice_live.ex` (component, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/live/invoice_live.ex`

**Invoice detail action pattern** (`accrue_admin/lib/accrue_admin/live/invoice_live.ex:27-42`, `307-318`, `334-348`, `353-419`, `421-431`):
```elixir
defp assign_invoice(socket, invoice) do
  socket
  |> assign(:invoice, invoice)
  |> assign(:customer, invoice.customer)
  |> assign(:line_items, invoice.items || [])
  |> assign(:timeline_events, timeline_events(invoice.id))
end

defp run_invoice_action(invoice, %{type: "finalize"}, operation_id) do
  Billing.finalize_invoice(invoice, operation_id: operation_id)
end
```

Use this surface if Phase 19 adds invoice-level recovery affordances or makes finalization-failure state visible in the detail view.

### `examples/accrue_host/lib/accrue_host/billing.ex` (service, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host/billing.ex`

**Host-owned facade wrapper** (`examples/accrue_host/lib/accrue_host/billing.ex:18-40`, `42-59`):
```elixir
def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end

def billing_state_for(billable) do
  customer = find_customer(billable)
  subscription = current_subscription(customer)
  {:ok, %{customer: customer, subscription: subscription}}
end
```

Put host tax-location policy hooks here, not directly in the LiveView.

### `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` (component, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`

**Host UX event/load-state pattern** (`examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:14-31`, `172-194`):
```elixir
def handle_event("start_subscription", %{"plan" => plan_id} = params, socket) do
  case Billing.subscribe(user, plan_id, operation_id: operation_id(params, "subscribe")) do
    {:ok, _subscription} -> {:noreply, socket |> put_flash(:info, "Subscription started.") |> load_state()}
    {:error, _reason} -> {:noreply, put_flash(socket, :error, @error_copy)}
  end
end

defp load_state(socket) do
  {:ok, %{customer: customer, subscription: subscription}} =
    Billing.billing_state_for(socket.assigns.current_scope.user)
  ...
end
```

Add tax-location collection and repair through new host events that still round-trip through `AccrueHost.Billing`.

### `accrue/guides/troubleshooting.md` (guide, transform)

**Analog:** `accrue/guides/troubleshooting.md`

**Troubleshooting matrix + anchored sections** (`accrue/guides/troubleshooting.md:1-18`, `84-132`, `201-232`):
```markdown
| Code | What happened | Why Accrue cares | Fix | How to verify |
| --- | --- | --- | --- | --- |
...
## `ACCRUE-DX-WEBHOOK-SECRET-MISSING`
### What happened
### Why Accrue cares
### Fix
### How to verify
```

Phase 19 rollout and invalid-location recovery docs should use the same matrix-plus-anchored-remediation format.

### `guides/testing-live-stripe.md` (guide, transform)

**Analog:** `guides/testing-live-stripe.md`

**Guide structure for provider-parity lanes** (`guides/testing-live-stripe.md:1-17`, `35-49`, `89-104`):
```markdown
1. Fake-asserted correctness tests
2. Live-Stripe fidelity tests

## Running locally
cd accrue
export STRIPE_TEST_SECRET_KEY=sk_test_...
mix test.live

## Philosophy
The live-Stripe suite exists to catch one specific class of bug:
Stripe API contract drift.
```

Use this structure if Phase 19 extends the live-Stripe guide with tax-location parity checks.

## Shared Patterns

### Billing facade telemetry
**Source:** `accrue/lib/accrue/billing.ex:530-580`, `610-625`, `689-709`
**Apply to:** New public `Accrue.Billing` tax-location APIs
```elixir
span_billing(:customer, :create, billable, [], fn ->
  Repo.transact(fn -> ... end)
end)
```

### Stripe adapter containment
**Source:** `accrue/lib/accrue/processor/stripe.ex:45-73`, `99-113`
**Apply to:** All Stripe location-validation request shaping
```elixir
Telemetry.span([:accrue, :processor, :customer, :update], %{adapter: :stripe, operation: :update_customer}, fn ->
  client
  |> LatticeStripe.Customer.update(id, stringify_keys(params), stripe_opts)
  |> translate_customer()
end)
```

### Error mapping
**Source:** `accrue/lib/accrue/processor/stripe/error_mapper.ex:98-126`
**Apply to:** `customer_tax_location_invalid` and adjacent Stripe invalid-request failures
```elixir
%Accrue.APIError{
  message: raw.message,
  code: raw.code,
  http_status: raw.status,
  request_id: raw.request_id,
  processor_error: raw
}
```

### Projection-first observability
**Source:** `accrue/lib/accrue/billing/subscription_projection.ex:15-32`, `69-78`; `accrue/lib/accrue/billing/invoice_projection.ex:26-99`
**Apply to:** `automatic_tax.disabled_reason`, finalization-error fields
```elixir
automatic_tax = automatic_tax_fields(get(stripe_sub, :automatic_tax))
...
automatic_tax_status: automatic_tax.status
```

### Webhook event-family extension
**Source:** `accrue/lib/accrue/webhook/default_handler.ex:69-104`, `117-129`
**Apply to:** `invoice.finalization_failed`, richer `customer.updated` reconciliation
```elixir
def handle_event(type, %Accrue.Webhook.Event{} = event, _ctx) when is_binary(type) do
  case dispatch(type, event.processor_event_id, event.created_at, %{"id" => event.object_id}) do
    {:ok, _} -> :ok
    other -> other
  end
end
```

### Admin action staging
**Source:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:319-330`, `353-418`; `accrue_admin/lib/accrue_admin/live/invoice_live.ex:353-419`
**Apply to:** Any operator recovery action added in Phase 19
```elixir
%{
  type: Map.fetch!(params, "action_type"),
  source_event_id: source_event && source_event.id,
  source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
}
```

### Host-owned boundary
**Source:** `examples/accrue_host/lib/accrue_host/billing.ex:18-40`; `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:23-31`
**Apply to:** User-facing tax-location collection/update flow
```elixir
def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end
```

## Notes

- Research named `accrue/guides/testing-live-stripe.md`; the repo path is `guides/testing-live-stripe.md`.
- Research also mentions broader tax/checkout guides, but the concrete guide analogs present today are `accrue/guides/troubleshooting.md` and `guides/testing-live-stripe.md`.

## No Analog Found

None. Every Phase 19 target named in research already has a close in-repo analog, usually the exact file being extended.

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue_admin/lib/accrue_admin`, `examples/accrue_host/lib`, `accrue/guides`, `guides`
**Files scanned:** 24 core analog files plus Phase 18 pattern map and Phase 19 research inputs
**Pattern extraction date:** 2026-04-17

## PATTERN MAPPING COMPLETE

**Phase:** 19 - Tax Location and Rollout Safety
**Files classified:** 24
**Analogs found:** 24 / 24

### Coverage
- Files with exact analog: 24
- Files with role-match analog: 0
- Files with no analog: 0

### Key Patterns Identified
- All public billing entry points stay inside `Accrue.Billing` telemetry spans and `Repo.transact/1`.
- Stripe-specific request shaping and error translation stay behind `Accrue.Processor.Stripe` and `Stripe.ErrorMapper`.
- Tax observability should be projected into narrow local fields, then surfaced through admin query modules and LiveViews.

### File Created
`.planning/phases/19-tax-location-and-rollout-safety/19-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference these analogs directly in Phase 19 plan actions.
