# Phase 18: Stripe Tax Core - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | request-response | `accrue/lib/accrue/billing/subscription_actions.ex` | exact |
| `accrue/lib/accrue/checkout/session.ex` | service | request-response | `accrue/lib/accrue/checkout/session.ex` | exact |
| `accrue/lib/accrue/processor/stripe.ex` | service | request-response | `accrue/lib/accrue/processor/stripe.ex` | exact |
| `accrue/lib/accrue/processor/fake.ex` | service | request-response | `accrue/lib/accrue/processor/fake.ex` | exact |
| `accrue/lib/accrue/billing/subscription_projection.ex` | model | transform | `accrue/lib/accrue/billing/subscription_projection.ex` | exact |
| `accrue/lib/accrue/billing/invoice_projection.ex` | model | transform | `accrue/lib/accrue/billing/invoice_projection.ex` | exact |
| `accrue/test/accrue/billing/subscription_test.exs` | test | request-response | `accrue/test/accrue/billing/subscription_test.exs` | exact |
| `accrue/test/accrue/checkout_test.exs` | test | request-response | `accrue/test/accrue/checkout_test.exs` | exact |
| `accrue/test/accrue/processor/fake_test.exs` | test | request-response | `accrue/test/accrue/processor/fake_test.exs` | exact |
| `accrue/test/accrue/billing/invoice_projection_test.exs` | test | transform | `accrue/test/accrue/billing/invoice_projection_test.exs` | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing/subscription_actions.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing/subscription_actions.ex`

**Imports + transaction surface** (`accrue/lib/accrue/billing/subscription_actions.ex:16-31`):
```elixir
require Logger

import Ecto.Query, only: [from: 2]

alias Accrue.Actor
alias Accrue.Billing.Customer
alias Accrue.Billing.IntentResult
alias Accrue.Billing.Subscription
alias Accrue.Billing.SubscriptionItem
alias Accrue.Billing.SubscriptionProjection
alias Accrue.Billing.Trial
alias Accrue.Billing.UpcomingInvoice
alias Accrue.Events
alias Accrue.Processor
alias Accrue.Processor.Idempotency
alias Accrue.Repo
```

**Core subscribe flow** (`accrue/lib/accrue/billing/subscription_actions.ex:68-103`):
```elixir
defp do_subscribe(%Customer{} = customer, price_spec, opts) do
  {price_id, quantity} = normalize_price_spec(price_spec)
  op_id = resolve_operation_id(opts)
  idem_key = Idempotency.key(:create_subscription, customer.id, op_id)

  {item_params, trial_end} = build_subscribe_params({price_id, quantity}, opts)

  stripe_params =
    %{
      customer: customer.processor_id,
      items: [item_params],
      payment_behavior: "default_incomplete",
      expand: ["latest_invoice.payment_intent"]
    }
    |> put_if(:trial_end, trial_end)
    |> maybe_put_default_pm(opts)
    |> maybe_put_coupon(opts)
    |> maybe_put_collection_method(opts)

  result =
    Repo.transact(fn ->
      with {:ok, stripe_sub} <-
             Processor.__impl__().create_subscription(
               stripe_params,
               [idempotency_key: idem_key] ++ sanitize_opts(opts)
             ),
           {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
           {:ok, sub} <- insert_subscription(customer.id, attrs),
           {:ok, _items} <- upsert_items(sub, stripe_sub),
           {:ok, _} <- record_event("subscription.created", sub, %{price_id: price_id}) do
        sub = Repo.preload(sub, :subscription_items, force: true)
        {:ok, sub}
      end
    end)

  IntentResult.wrap(result)
end
```

**Option-normalization helpers** (`accrue/lib/accrue/billing/subscription_actions.ex:694-731`):
```elixir
defp build_subscribe_params({price, qty}, opts) do
  trial_end =
    case Keyword.get(opts, :trial_end) do
      nil -> nil
      val -> Trial.normalize_trial_end(val)
    end

  {%{price: price, quantity: qty}, trial_end}
end

defp maybe_put_default_pm(params, opts) do
  case Keyword.get(opts, :default_payment_method) do
    nil -> params
    pm_id -> Map.put(params, :default_payment_method, pm_id)
  end
end

defp maybe_put_coupon(params, opts) do
  case Keyword.get(opts, :coupon) do
    nil -> params
    id when is_binary(id) -> Map.put(params, :discounts, [%{coupon: id}])
  end
end
```

**Item upsert + JSON-safe persistence** (`accrue/lib/accrue/billing/subscription_actions.ex:772-833`):
```elixir
defp upsert_items(sub, stripe_sub) do
  items =
    stripe_sub
    |> SubscriptionProjection.get(:items)
    |> case do
      nil -> []
      %{} = m -> SubscriptionProjection.get(m, :data) || []
      list when is_list(list) -> list
    end

  Enum.reduce_while(items, {:ok, []}, fn si, {:ok, acc} ->
    case upsert_item(sub, si) do
      {:ok, item} -> {:cont, {:ok, [item | acc]}}
      {:error, _} = err -> {:halt, err}
    end
  end)
end

defp upsert_item(sub, si) when is_map(si) do
  ...
  attrs = %{
    subscription_id: sub.id,
    processor: processor_name(),
    processor_id: stripe_id,
    ...
    data: stringify(si),
    metadata: SubscriptionProjection.get(si, :metadata) || %{}
  }
  ...
end
```

**Use for Phase 18:** add one flat public tax option in this module, translate it in the existing `stripe_params` builder, and keep it out of `sanitize_opts/1` only if the processor should still see it.

---

### `accrue/lib/accrue/checkout/session.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/checkout/session.ex`

**NimbleOptions boundary** (`accrue/lib/accrue/checkout/session.ex:49-80`):
```elixir
@create_schema [
  mode: [type: {:in, [:subscription, :payment, :setup]}, default: :subscription],
  ui_mode: [type: {:in, [:hosted, :embedded]}, default: :hosted],
  customer: [
    type: {:or, [:string, {:struct, Customer}, nil]},
    default: nil
  ],
  line_items: [type: {:list, {:map, :any, :any}}, default: []],
  success_url: [type: {:or, [:string, nil]}, default: nil],
  ...
]

def create(params) when is_map(params) do
  opts = NimbleOptions.validate!(Map.to_list(params), @create_schema)
  {stripe_params, request_opts} = build_stripe_params(opts)

  case Processor.__impl__().checkout_session_create(stripe_params, request_opts) do
    {:ok, stripe_session} -> {:ok, from_stripe(stripe_session)}
    {:error, err} -> {:error, err}
  end
end
```

**Request builder** (`accrue/lib/accrue/checkout/session.ex:136-164`):
```elixir
defp build_stripe_params(opts) do
  {operation_id, opts} = Keyword.pop(opts, :operation_id)

  customer_id =
    case opts[:customer] do
      nil -> nil
      bin when is_binary(bin) -> bin
      %Customer{processor_id: pid} -> pid
    end

  base =
    %{
      "mode" => Atom.to_string(opts[:mode]),
      "ui_mode" => Atom.to_string(opts[:ui_mode])
    }
    |> put_unless_nil("customer", customer_id)
    |> put_unless_nil("success_url", opts[:success_url])
    |> put_unless_nil("cancel_url", opts[:cancel_url])
    |> put_unless_nil("return_url", opts[:return_url])
    |> put_unless_nil("metadata", opts[:metadata])
    |> put_unless_nil("client_reference_id", opts[:client_reference_id])
    |> Map.put("line_items", opts[:line_items] || [])

  request_opts =
    []
    |> put_kw_unless_nil(:operation_id, operation_id)

  {base, request_opts}
end
```

**Projection pattern** (`accrue/lib/accrue/checkout/session.ex:115-133`):
```elixir
def from_stripe(stripe) when is_map(stripe) do
  %__MODULE__{
    id: get(stripe, :id),
    object: get(stripe, :object) || "checkout.session",
    mode: to_string_or_nil(get(stripe, :mode)),
    ui_mode: to_string_or_nil(get(stripe, :ui_mode)),
    ...
    metadata: get(stripe, :metadata) || %{},
    data: stripe
  }
end
```

**Use for Phase 18:** extend `@create_schema`, then add one more `put_unless_nil/3` into `build_stripe_params/1` for the tax intent without changing the public/create call shape elsewhere.

---

### `accrue/lib/accrue/processor/stripe.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/stripe.ex`

**Facade rule + imports** (`accrue/lib/accrue/processor/stripe.ex:45-50`):
```elixir
@behaviour Accrue.Processor

alias Accrue.Processor.Stripe.ErrorMapper
alias Accrue.Telemetry

require Logger
```

**Subscription adapter pattern** (`accrue/lib/accrue/processor/stripe.ex:124-133`):
```elixir
@impl Accrue.Processor
def create_subscription(params, opts) when is_map(params) and is_list(opts) do
  client = build_client!(opts)
  params = ensure_expand(params, ["latest_invoice.payment_intent"])
  stripe_opts = stripe_opts(:create_subscription, subject_of(params, "sub"), opts)

  client
  |> LatticeStripe.Subscription.create(stringify_keys(params), stripe_opts)
  |> translate_resource()
end
```

**Checkout adapter pattern** (`accrue/lib/accrue/processor/stripe.ex:687-695`):
```elixir
@impl Accrue.Processor
def checkout_session_create(params, opts) when is_map(params) and is_list(opts) do
  client = build_client!(opts)
  stripe_opts = stripe_opts(:checkout_session_create, subject_of(params, "cs"), opts)

  client
  |> LatticeStripe.Checkout.Session.create(stringify_keys(params), stripe_opts)
  |> translate_resource()
end
```

**Shared helper pattern** (`accrue/lib/accrue/processor/stripe.ex:825-871`):
```elixir
defp stripe_opts(op, subject_id, opts) do
  idem_key =
    Keyword.get(opts, :idempotency_key) ||
      compute_idempotency_key(op, subject_id, opts)

  opts
  |> Keyword.put(:idempotency_key, idem_key)
  |> Keyword.put(:stripe_version, resolve_api_version(opts))
end

defp ensure_expand(params, paths) do
  existing =
    Map.get(params, :expand) || Map.get(params, "expand") || []

  expand = Enum.uniq(existing ++ paths)

  params
  |> Map.delete("expand")
  |> Map.put(:expand, expand)
end

defp translate_resource({:ok, %_{} = result}), do: {:ok, Map.from_struct(result)}
defp translate_resource({:error, raw}), do: {:error, ErrorMapper.to_accrue_error(raw)}
```

**String-key conversion** (`accrue/lib/accrue/processor/stripe.ex:1000-1005`):
```elixir
defp stringify_keys(map) when is_map(map) do
  Map.new(map, fn
    {k, v} when is_atom(k) -> {Atom.to_string(k), v}
    {k, v} -> {k, v}
  end)
end
```

**Use for Phase 18:** keep the Stripe-specific `automatic_tax` map inside params passed into these two callbacks; do not leak any `LatticeStripe` structs or Stripe-specific branching into billing or checkout modules.

---

### `accrue/lib/accrue/processor/fake.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/fake.ex`

**Behaviour callback surface** (`accrue/lib/accrue/processor/fake.ex:219-232`, `accrue/lib/accrue/processor/fake.ex:523-530`):
```elixir
@impl Accrue.Processor
def create_subscription(params, opts \\ []) when is_map(params) and is_list(opts) do
  call({:create_subscription, params, opts})
end

@impl Accrue.Processor
def update_subscription(id, params, opts \\ [])
    when is_binary(id) and is_map(params) and is_list(opts) do
  call({:update_subscription, id, params, opts})
end

@impl Accrue.Processor
def checkout_session_create(params, opts \\ []) when is_map(params) and is_list(opts) do
  call({:checkout_session_create, params, opts})
end
```

**Scriptable deterministic test double** (`accrue/lib/accrue/processor/fake.ex:171-180`):
```elixir
@doc """
Pre-programs a one-shot return value for the named op. The next call
to that op consumes the scripted response; subsequent calls fall back
to the default in-memory behaviour.
"""
@spec scripted_response(atom(), {:ok, map()} | {:error, Exception.t()}) :: :ok
def scripted_response(op, result) when is_atom(op) do
  call({:script, op, result})
end
```

**Checkout session builder** (`accrue/lib/accrue/processor/fake.ex:1498-1538`):
```elixir
def handle_call({:checkout_session_create, params, opts}, _from, state) do
  with_script_or_stub(state, :checkout_session_create, [params, opts], fn state ->
    ...
    atom_params = atomize(params)
    ui_mode = atom_params[:ui_mode] || "hosted"
    mode = atom_params[:mode] || "subscription"
    ...
    session =
      atom_params
      |> Map.put(:id, id)
      |> Map.put(:object, "checkout.session")
      |> Map.put(:mode, mode)
      |> Map.put(:ui_mode, ui_mode)
      |> Map.put(:url, url)
      |> Map.put(:client_secret, client_secret)
      |> Map.put(:status, "open")
      |> Map.put(:payment_status, "unpaid")
      |> Map.put(:created, DateTime.to_unix(state.clock))
      |> Map.put_new(:customer, nil)
      |> Map.put_new(:subscription, nil)
      |> Map.put_new(:payment_intent, nil)
      |> Map.put_new(:amount_total, nil)
      |> Map.put_new(:currency, "usd")
      |> Map.put_new(:metadata, %{})
```

**Subscription builder** (`accrue/lib/accrue/processor/fake.ex:2018-2033`):
```elixir
%{
  id: id,
  object: "subscription",
  customer: customer,
  status: status,
  created: state.clock,
  trial_start: trial_start,
  trial_end: trial_end,
  cancel_at_period_end: false,
  pause_collection: nil,
  current_period_start: DateTime.to_unix(state.clock),
  current_period_end: DateTime.to_unix(DateTime.add(state.clock, 30 * 86_400, :second)),
  items: %{object: "list", data: items},
  latest_invoice: nil,
  metadata: params[:metadata] || params["metadata"] || %{}
}
```

**Use for Phase 18:** model tax-enabled and tax-disabled results directly in Fake’s native builders and `handle_call` path, instead of forcing tax tests to use `scripted_response/2`.

---

### `accrue/lib/accrue/billing/subscription_projection.ex` (model, transform)

**Analog:** `accrue/lib/accrue/billing/subscription_projection.ex`

**Projection shape** (`accrue/lib/accrue/billing/subscription_projection.ex:14-31`):
```elixir
@spec decompose(map()) :: {:ok, map()}
def decompose(stripe_sub) when is_map(stripe_sub) do
  {:ok,
   %{
     processor_id: get(stripe_sub, :id),
     status: parse_status(get(stripe_sub, :status)),
     cancel_at_period_end: get(stripe_sub, :cancel_at_period_end) || false,
     pause_collection: parse_pause_collection(get(stripe_sub, :pause_collection)),
     current_period_start: unix_to_dt(get(stripe_sub, :current_period_start)),
     current_period_end: unix_to_dt(get(stripe_sub, :current_period_end)),
     trial_start: unix_to_dt(get(stripe_sub, :trial_start)),
     trial_end: unix_to_dt(get(stripe_sub, :trial_end)),
     canceled_at: unix_to_dt(get(stripe_sub, :canceled_at)),
     ended_at: unix_to_dt(get(stripe_sub, :ended_at)),
     discount_id: parse_discount_id(get(stripe_sub, :discount)),
     data: normalize_data(stripe_sub),
     metadata: get(stripe_sub, :metadata) || %{}
   }}
end
```

**Cross-module helpers** (`accrue/lib/accrue/billing/subscription_projection.ex:43-110`):
```elixir
def get(map, key) when is_atom(key) do
  Map.get(map, key) || Map.get(map, Atom.to_string(key))
end

def unix_to_dt(nil), do: nil
def unix_to_dt(%DateTime{} = dt), do: dt
def unix_to_dt(0), do: nil
def unix_to_dt(n) when is_integer(n), do: DateTime.from_unix!(n)
def unix_to_dt("now"), do: Accrue.Clock.utc_now()

@spec to_string_keys(term()) :: term()
def to_string_keys(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
...
```

**Use for Phase 18:** add only narrow derived tax fields here, while continuing to persist the full upstream subscription payload in `data`.

---

### `accrue/lib/accrue/billing/invoice_projection.ex` (model, transform)

**Analog:** `accrue/lib/accrue/billing/invoice_projection.ex`

**Invoice attrs pattern** (`accrue/lib/accrue/billing/invoice_projection.ex:25-97`):
```elixir
@spec decompose(map()) :: {:ok, decomposed()}
def decompose(stripe_inv) when is_map(stripe_inv) do
  currency = SubscriptionProjection.get(stripe_inv, :currency)
  status_transitions = SubscriptionProjection.get(stripe_inv, :status_transitions) || %{}
  ...
  invoice_attrs = %{
    processor_id: SubscriptionProjection.get(stripe_inv, :id),
    status: parse_status(SubscriptionProjection.get(stripe_inv, :status)),
    subtotal_minor: SubscriptionProjection.get(stripe_inv, :subtotal),
    tax_minor: SubscriptionProjection.get(stripe_inv, :tax),
    discount_minor: discount_minor,
    total_discount_amounts: %{
      "data" => SubscriptionProjection.to_string_keys(total_discount_amounts)
    },
    total_minor: SubscriptionProjection.get(stripe_inv, :total),
    amount_due_minor: SubscriptionProjection.get(stripe_inv, :amount_due),
    amount_paid_minor: SubscriptionProjection.get(stripe_inv, :amount_paid),
    amount_remaining_minor: SubscriptionProjection.get(stripe_inv, :amount_remaining),
    ...
    data: SubscriptionProjection.to_string_keys(stripe_inv),
    metadata: SubscriptionProjection.get(stripe_inv, :metadata) || %{}
  }
```

**Nested line decomposition** (`accrue/lib/accrue/billing/invoice_projection.ex:99-126`):
```elixir
item_attrs =
  stripe_inv
  |> SubscriptionProjection.get(:lines)
  |> case do
    nil -> []
    %{} = m -> SubscriptionProjection.get(m, :data) || []
    list when is_list(list) -> list
  end
  |> Enum.map(fn line ->
    period = SubscriptionProjection.get(line, :period) || %{}
    price = SubscriptionProjection.get(line, :price)

    %{
      stripe_id: SubscriptionProjection.get(line, :id),
      description: SubscriptionProjection.get(line, :description),
      amount_minor: SubscriptionProjection.get(line, :amount),
      ...
      data: line
    }
  end)
```

**Use for Phase 18:** follow the existing pattern of adding a small number of top-level observability fields while keeping the full invoice payload in `data`.

---

### `accrue/test/accrue/billing/subscription_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/billing/subscription_test.exs`

**BillingCase setup + seeded customer** (`accrue/test/accrue/billing/subscription_test.exs:8-26`):
```elixir
use Accrue.BillingCase, async: false

alias Accrue.Billing
alias Accrue.Billing.Customer

setup do
  {:ok, customer} =
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_fake_test",
      email: "sub-test@example.com"
    })
    |> Repo.insert()

  %{customer: customer}
end
```

**Public API assertion style** (`accrue/test/accrue/billing/subscription_test.exs:28-40`):
```elixir
test "subscribe/2 with bare price_id creates trialing subscription", %{customer: cus} do
  assert {:ok, sub} = Billing.subscribe(cus, "price_basic", trial_end: {:days, 14})
  assert sub.status == :trialing
  assert sub.processor_id =~ ~r/^sub_fake_/
  assert length(sub.subscription_items) == 1
  [item] = sub.subscription_items
  assert item.price_id == "price_basic"
end
```

**Scripted parity/error path** (`accrue/test/accrue/billing/subscription_test.exs:48-90`):
```elixir
fake_sub = %{
  id: "sub_fake_scripted",
  object: "subscription",
  ...
  latest_invoice: %{
    id: "in_fake_scripted",
    object: "invoice",
    status: :open,
    payment_intent: %{
      id: "pi_fake_scripted",
      object: "payment_intent",
      status: "requires_action",
      client_secret: "pi_fake_scripted_secret",
      next_action: %{type: "use_stripe_sdk"}
    }
  }
}

Fake.scripted_response(:create_subscription, {:ok, fake_sub})

assert {:ok, :requires_action, pi} = Billing.subscribe(cus, "price_basic")
```

**Use for Phase 18:** mirror this shape for tax-enabled and tax-disabled subscription coverage, but prefer native Fake behavior over scripted responses for standard success paths.

---

### `accrue/test/accrue/checkout_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/checkout_test.exs`

**Create-path test shape** (`accrue/test/accrue/checkout_test.exs:28-47`):
```elixir
test "with mode :hosted returns a hosted session struct with :url and nil client_secret",
     %{customer: customer} do
  assert {:ok, %Session{} = session} =
           Session.create(%{
             customer: customer,
             mode: :subscription,
             ui_mode: :hosted,
             line_items: [LineItem.from_price("price_basic_monthly", 1)],
             success_url: "https://example.com/success",
             cancel_url: "https://example.com/cancel"
           })

  assert is_binary(session.id)
  assert String.starts_with?(session.id, "cs_fake_")
  assert is_binary(session.url)
  assert session.client_secret == nil
end
```

**Defaulting + customer-id coverage** (`accrue/test/accrue/checkout_test.exs:65-86`):
```elixir
test "defaults mode to :subscription and ui_mode to :hosted", %{customer: customer} do
  assert {:ok, %Session{} = session} =
           Session.create(%{
             customer: customer,
             line_items: [LineItem.from_price("price_basic_monthly", 1)],
             success_url: "https://example.com/s"
           })
  ...
end

test "accepts a stripe customer id string instead of a Customer struct",
     %{customer: customer} do
  assert {:ok, %Session{}} =
           Session.create(%{
             customer: customer.processor_id,
             line_items: [LineItem.from_price("price_basic_monthly", 1)],
             success_url: "https://example.com/s"
           })
end
```

**Use for Phase 18:** add assertions on the returned `%Session{}` tax fields and preserved raw payload, following this same direct context-level test style.

---

### `accrue/test/accrue/processor/fake_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/processor/fake_test.exs`

**Processor entrypoint style** (`accrue/test/accrue/processor/fake_test.exs:18-39`):
```elixir
describe "create_customer/2" do
  test "returns deterministic zero-padded ids starting at cus_fake_00001" do
    assert {:ok, %{id: "cus_fake_00001", email: "a@b"}} =
             Processor.create_customer(%{email: "a@b"}, [])
    ...
  end

  test "persists params into the returned customer map" do
    assert {:ok, customer} =
             Processor.create_customer(%{email: "x@y", name: "Jane"}, [])
    ...
  end
end
```

**Deterministic clock/reset pattern** (`accrue/test/accrue/processor/fake_test.exs:74-97`):
```elixir
describe "test clock" do
  test "current_time/0 defaults to the epoch module attribute" do
    assert %DateTime{year: 2026, month: 1, day: 1} = Fake.current_time()
  end

  test "reset/0 restores the clock and zeros counters" do
    {:ok, %{id: "cus_fake_00001"}} = Processor.create_customer(%{email: "a@b"}, [])
    :ok = Fake.advance(Fake, 7200)
    :ok = Fake.reset()
    assert {:ok, %{id: "cus_fake_00001"}} = Processor.create_customer(%{email: "x@y"}, [])
  end
end
```

**Use for Phase 18:** add direct `Processor.create_subscription/2` and `Processor.checkout_session_create/2` tests here when you need to prove Fake’s native tax payload shape independently from Billing/Checkout.

---

### `accrue/test/accrue/billing/invoice_projection_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/billing/invoice_projection_test.exs`

**String-keyed fixture pattern** (`accrue/test/accrue/billing/invoice_projection_test.exs:18-42`):
```elixir
describe "decompose/1 (string-keyed wire shape)" do
  test "decomposes status, rollups, and period dates" do
    inv =
      StripeFixtures.invoice(%{
        "status" => "open",
        "subtotal" => 1500,
        "total" => 1500,
        "amount_due" => 1500
      })

    {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(inv)
    assert attrs.processor_id == inv["id"]
    assert attrs.status == :open
    ...
  end
end
```

**Atom-keyed Fake shape coverage** (`accrue/test/accrue/billing/invoice_projection_test.exs:84-123`):
```elixir
describe "decompose/1 (atom-keyed Fake shape)" do
  test "handles atom-keyed invoices from Accrue.Processor.Fake" do
    fake_inv = %{
      id: "in_fake_00001",
      object: "invoice",
      status: :draft,
      amount_due: 2000,
      ...
      lines: %{
        object: "list",
        data: [
          %{
            id: "il_fake_1",
            object: "line_item",
            description: "Pro Plan",
            amount: 2000,
            ...
          }
        ]
      }
    }

    {:ok, %{invoice_attrs: attrs, item_attrs: items}} =
      InvoiceProjection.decompose(fake_inv)
```

**Use for Phase 18:** follow this exact two-shape test structure for any new tax projection fields, and reuse it as the role-match template for subscription projection tests if you add one.

## Shared Patterns

### Test Harness
**Source:** `accrue/test/support/billing_case.ex:23-77`
**Apply to:** Billing/checkout integration tests that touch Repo + Fake
```elixir
use ExUnit.CaseTemplate

setup tags do
  pid =
    Ecto.Adapters.SQL.Sandbox.start_owner!(
      Accrue.TestRepo,
      shared: not tags[:async]
    )

  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

  case Accrue.Processor.Fake.start_link([]) do
    {:ok, _} -> :ok
    {:error, {:already_started, _}} -> :ok
  end

  :ok = Accrue.Processor.Fake.reset()
  ...
  :ok = Accrue.Actor.put_operation_id("test-" <> Ecto.UUID.generate())
end
```

### Processor Boundary + Idempotency
**Source:** `accrue/lib/accrue/billing/subscription_actions.ex:68-103`, `accrue/lib/accrue/processor/stripe.ex:825-840`
**Apply to:** subscription create and checkout session create tax plumbing
```elixir
op_id = resolve_operation_id(opts)
idem_key = Idempotency.key(:create_subscription, customer.id, op_id)

Processor.__impl__().create_subscription(
  stripe_params,
  [idempotency_key: idem_key] ++ sanitize_opts(opts)
)

defp stripe_opts(op, subject_id, opts) do
  idem_key =
    Keyword.get(opts, :idempotency_key) ||
      compute_idempotency_key(op, subject_id, opts)

  opts
  |> Keyword.put(:idempotency_key, idem_key)
  |> Keyword.put(:stripe_version, resolve_api_version(opts))
end
```

### Validation at Public Boundaries
**Source:** `accrue/lib/accrue/checkout/session.ex:49-76`, `accrue/lib/accrue/billing/subscription_actions.ex:138-163`
**Apply to:** any new public tax option
```elixir
@create_schema [...]
opts = NimbleOptions.validate!(Map.to_list(params), @create_schema)

@swap_schema [...]
case NimbleOptions.validate(opts, @swap_schema) do
  {:ok, validated} -> validated
  {:error, %NimbleOptions.ValidationError{} = err} -> ...
end
```

### Raw Payload Retention + String-Key Normalization
**Source:** `accrue/lib/accrue/billing/subscription_projection.ex:83-110`, `accrue/lib/accrue/billing/invoice_projection.ex:92-96`
**Apply to:** all new tax observability fields in subscription/invoice projections
```elixir
defp normalize_data(map) when is_map(map) do
  map
  |> to_string_keys()
end

data: SubscriptionProjection.to_string_keys(stripe_inv),
metadata: SubscriptionProjection.get(stripe_inv, :metadata) || %{}
```

### Fake/Stripe Parity Rule
**Source:** `accrue/lib/accrue/processor/stripe.ex:124-133`, `accrue/lib/accrue/processor/fake.ex:1498-1538`, `accrue/test/accrue/billing/invoice_projection_test.exs:84-123`
**Apply to:** tax-enabled subscription and checkout payloads
```elixir
client
|> LatticeStripe.Subscription.create(stringify_keys(params), stripe_opts)
|> translate_resource()

session =
  atom_params
  |> Map.put(:id, id)
  |> Map.put(:object, "checkout.session")
  ...

test "handles atom-keyed invoices from Accrue.Processor.Fake" do
  fake_inv = %{...}
  {:ok, %{invoice_attrs: attrs}} = InvoiceProjection.decompose(fake_inv)
end
```

## No Analog Found

None. Phase 18 fits existing billing, checkout, processor, and projection seams directly.

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/test`
**Files scanned:** 325 via search, 12 read for extraction
**Pattern extraction date:** 2026-04-17
