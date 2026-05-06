# Phase 102: Coupon/Discount Mapping - Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/discount_mapping.ex` | model | CRUD | `accrue/lib/accrue/billing/promotion_code.ex` | role-match |
| `accrue/lib/accrue/billing/discount_mapping_actions.ex` | service | CRUD | `accrue/lib/accrue/billing/coupon_actions.ex` | role-match |
| `accrue/lib/accrue/billing.ex` | service | request-response | `accrue/lib/accrue/billing.ex` | exact |
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | request-response | `accrue/lib/accrue/billing/subscription_actions.ex` | exact |
| `accrue/lib/accrue/processor/braintree.ex` | service | transform | `accrue/lib/accrue/processor/braintree.ex` | exact |
| `accrue/lib/accrue/errors.ex` | model | request-response | `accrue/lib/accrue/errors.ex` | exact |
| `accrue/lib/accrue/checkout/local_session.ex` | model | CRUD | `accrue/lib/accrue/checkout/local_session.ex` | exact |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | component | request-response | `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | exact |
| `accrue/priv/repo/migrations/*_create_accrue_discount_mappings.exs` | migration | CRUD | `accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs` | role-match |
| `accrue/guides/braintree-local-portal.md` | config | request-response | `accrue/guides/braintree-local-portal.md` | exact |
| `accrue/guides/stripe-vs-braintree-promotions.md` | config | transform | `accrue/guides/braintree-local-portal.md` | partial |
| `accrue/test/accrue/billing/discount_mapping_actions_test.exs` | test | CRUD | `accrue/test/accrue/billing/coupon_actions_test.exs` | role-match |
| `accrue/test/accrue/billing/subscription_actions_test.exs` | test | request-response | `accrue/test/accrue/billing/subscription_actions_test.exs` | exact |
| `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` | test | request-response | `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing/discount_mapping.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/promotion_code.ex`

**Schema + field layout** ([accrue/lib/accrue/billing/promotion_code.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/promotion_code.ex:15)):
```elixir
use Ecto.Schema

import Ecto.Changeset

alias Accrue.Billing.Metadata

@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

schema "accrue_promotion_codes" do
  field(:processor, :string, default: "stripe")
  field(:processor_id, :string)
  field(:code, :string)
```

**Changeset pattern** ([accrue/lib/accrue/billing/promotion_code.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/promotion_code.ex:46)):
```elixir
@cast_fields ~w[
  processor processor_id code coupon_id active
  max_redemptions times_redeemed expires_at data metadata
  last_stripe_event_ts last_stripe_event_id
]a

@required_fields ~w[processor processor_id code]a

def changeset(promo_or_changeset, attrs \\ %{}) do
  promo_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
  |> unique_constraint(:processor_id)
  |> unique_constraint(:code)
  |> foreign_key_constraint(:coupon_id)
end
```

**Copy forward:** keep the schema/changelog shape, metadata validation, optimistic lock, and DB-backed uniqueness constraints. Replace Stripe projection fields with local mapping fields such as `discount_id`, eligibility columns, and local canonical state.

---

### `accrue/lib/accrue/billing/discount_mapping_actions.ex` (service, CRUD)

**Analog:** `accrue/lib/accrue/billing/coupon_actions.ex`

**Imports + module posture** ([accrue/lib/accrue/billing/coupon_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon_actions.ex:30)):
```elixir
require Logger

alias Accrue.Actor

alias Accrue.Billing.{
  Coupon,
  PromotionCode,
  PromotionCodeProjection,
  Subscription
}

alias Accrue.Events
alias Accrue.Processor
alias Accrue.Processor.Idempotency
alias Accrue.Repo
```

**Transactional write + event pattern** ([accrue/lib/accrue/billing/coupon_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon_actions.ex:58)):
```elixir
@spec create_coupon(map(), keyword()) :: {:ok, Coupon.t()} | {:error, term()}
def create_coupon(params, opts \\ []) when is_map(params) and is_list(opts) do
  op_id = resolve_operation_id(opts)
  subject = to_string(params[:id] || params["id"] || params[:name] || "coupon_new")
  idem_key = Idempotency.key(:create_coupon, subject, op_id)

  Repo.transact(fn ->
    with {:ok, processor_result} <-
           Processor.__impl__().coupon_create(
             params,
             Keyword.put(opts, :idempotency_key, idem_key)
           ),
         attrs <- project_coupon(processor_result),
         {:ok, coupon} <- upsert_coupon(attrs),
         {:ok, _event} <-
           Events.record(%{
             type: "coupon.created",
             subject_type: "Coupon",
             subject_id: coupon.id,
             data: %{processor_id: coupon.processor_id}
           }) do
      {:ok, coupon}
    end
  end)
end
```

**Local validation result shape** ([accrue/lib/accrue/billing/coupon_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon_actions.ex:154)):
```elixir
@type apply_error ::
        :not_found
        | :inactive
        | :expired
        | :max_redemptions_reached
        | :coupon_missing
        | term()
```

**Eligibility checks** ([accrue/lib/accrue/billing/coupon_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon_actions.ex:220)):
```elixir
defp fetch_applicable(code) do
  now = Accrue.Clock.utc_now()

  case Repo.get_by(PromotionCode, code: code) do
    nil ->
      {:error, :not_found}

    %PromotionCode{active: false} ->
      {:error, :inactive}

    %PromotionCode{
      max_redemptions: max,
      times_redeemed: redeemed
    }
    when is_integer(max) and redeemed >= max ->
      {:error, :max_redemptions_reached}

    %PromotionCode{expires_at: %DateTime{} = exp} = promo ->
      if DateTime.compare(exp, now) == :lt do
        {:error, :expired}
      else
        {:ok, promo}
      end
```

**Copy forward:** use this file as the template for `create_discount_mapping/2` or `upsert_discount_mapping/2`, resolver helpers, typed local validation tuples, and `Repo.transact` + `Events.record` sequencing. Do not copy the processor-create call; Phase 102 is local-canonical.

---

### `accrue/lib/accrue/billing.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Alias aggregation** ([accrue/lib/accrue/billing.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:28)):
```elixir
alias Accrue.Billing.{
  ChargeActions,
  CouponActions,
  InvoiceActions,
  MeterEventActions,
  PaymentMethodActions,
  RefundActions,
  SubscriptionActions,
  SubscriptionItems,
  SubscriptionScheduleActions
}
```

**Facade wrapper pattern** ([accrue/lib/accrue/billing.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:651)):
```elixir
def create_coupon(params, opts \\ []),
  do:
    span_billing(:coupon, :create, params, opts, fn ->
      CouponActions.create_coupon(params, opts)
    end)

def create_promotion_code(params, opts \\ []),
  do:
    span_billing(:promotion_code, :create, params, opts, fn ->
      CouponActions.create_promotion_code(params, opts)
    end)

def apply_promotion_code(sub, code, opts \\ []) do
  span_billing(:promotion_code, :apply, sub, opts, fn ->
    CouponActions.apply_promotion_code(sub, code, opts)
  end)
end
```

**Copy forward:** add new facade-first functions here, wrapped in `span_billing/5`, instead of introducing a public `Accrue.Billing.Braintree.*` namespace.

---

### `accrue/lib/accrue/billing/subscription_actions.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing/subscription_actions.ex`

**Subscribe transaction seam** ([accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:114)):
```elixir
defp do_subscribe_supported(%Customer{} = customer, price_spec, opts) do
  {price_id, quantity} = normalize_price_spec(price_spec)
  op_id = resolve_operation_id(opts)
  idem_key = Idempotency.key(:create_subscription, customer.id, op_id)

  {item_params, trial_end} = build_subscribe_params({price_id, quantity}, opts)

  result =
    Repo.transact(fn ->
      with {:ok, processor_params} <-
             build_subscription_request(customer, item_params, trial_end, opts),
           :ok <- ensure_customer_tax_location(customer, opts),
           {:ok, stripe_sub} <-
             Processor.__impl__().create_subscription(
               processor_params,
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
```

**Braintree branch seam** ([accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:156)):
```elixir
defp build_subscription_request(%Customer{} = customer, item_params, trial_end, opts) do
  if Processor.__impl__() == Accrue.Processor.Braintree do
    case Keyword.get(opts, :payment_method) do
      %{vault_acquisition: %{reference: ref}} when is_binary(ref) ->
        {:ok,
         %{
           payment_method: %{vault_acquisition: %{reference: ref}},
           items: [item_params]
         }}
```

**Current Stripe-only coupon seam to replace for Braintree** ([accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:892)):
```elixir
defp maybe_put_coupon(params, opts) do
  case Keyword.get(opts, :coupon) do
    nil -> params
    id when is_binary(id) -> Map.put(params, :discounts, [%{coupon: id}])
  end
end
```

**Copy forward:** resolve the local mapping inside `build_subscription_request/4` for the Braintree branch, attach typed drift failures before processor create, and keep the Stripe `maybe_put_coupon/2` path isolated and unchanged.

---

### `accrue/lib/accrue/processor/braintree.ex` (service, transform)

**Analog:** `accrue/lib/accrue/processor/braintree.ex`

**Adapter entrypoint pattern** ([accrue/lib/accrue/processor/braintree.ex](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:46)):
```elixir
@impl Accrue.Processor
def create_subscription(params, opts) when is_map(params) and is_list(opts) do
  braintree_params = build_request(params)

  case subscription_gateway().create(braintree_params, opts) do
    {:ok, sub} -> {:ok, translate_subscription(sub)}
    {:error, raw} -> {:error, to_accrue_error(raw)}
  end
end
```

**Request translation seam** ([accrue/lib/accrue/processor/braintree.ex](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:73)):
```elixir
def build_request(params) do
  payment_method = params[:payment_method] || params["payment_method"] || %{}
  vault = payment_method[:vault_acquisition] || payment_method["vault_acquisition"] || %{}
  token = vault[:reference] || vault["reference"]

  items = params[:items] || params["items"] || []
  first_item = List.first(items) || %{}
  plan_id = first_item[:price] || first_item["price"]

  %{
    payment_method_token: token,
    plan_id: plan_id
  }
end
```

**Unsupported capability pattern** ([accrue/lib/accrue/processor/braintree.ex](/Users/jon/projects/accrue/accrue/lib/accrue/processor/braintree.ex:350)):
```elixir
def coupon_create(_params, _opts), do: {:error, unsupported()}
def coupon_retrieve(_id, _opts), do: {:error, unsupported()}
def promotion_code_create(_params, _opts), do: {:error, unsupported()}
def promotion_code_retrieve(_id, _opts), do: {:error, unsupported()}
```

**Copy forward:** extend `build_request/1` to map resolved local discount data into Braintree’s create payload, but preserve the adapter’s current translation boundary and its explicit `unsupported()` stance for processor-native coupon/promotion CRUD.

---

### `accrue/lib/accrue/errors.ex` (error model, request-response)

**Analog:** `accrue/lib/accrue/errors.ex`

**Typed exception shape** ([accrue/lib/accrue/errors.ex](/Users/jon/projects/accrue/accrue/lib/accrue/errors.ex:112)):
```elixir
defmodule Accrue.ConfigError do
  @type t :: %__MODULE__{}
  defexception [:message, :key, :diagnostic]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{diagnostic: %Accrue.SetupDiagnostic{} = diagnostic}),
    do: Accrue.SetupDiagnostic.format(diagnostic)

  def message(%__MODULE__{key: key}), do: "missing accrue config key: #{inspect(key)}"
end
```

**Domain-specific exception precedent** ([accrue/lib/accrue/errors.ex](/Users/jon/projects/accrue/accrue/lib/accrue/errors.ex:161)):
```elixir
defmodule Accrue.Error.InvalidState do
  @type t :: %__MODULE__{}
  defexception [:current, :attempted, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{current: current, attempted: attempted}) do
    "invalid state transition: cannot #{inspect(attempted)} from #{inspect(current)}"
  end
end
```

**Copy forward:** implement `%Accrue.Error.DiscountMappingInvalid{}` in this style: dedicated module, structured fields, explicit `message/1`, and no fallback to generic invalid-request tuples for operator drift.

---

### `accrue/lib/accrue/checkout/local_session.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/checkout/local_session.ex`

**Schema pattern for persisted portal state** ([accrue/lib/accrue/checkout/local_session.ex](/Users/jon/projects/accrue/accrue/lib/accrue/checkout/local_session.ex:20)):
```elixir
schema "accrue_checkout_sessions" do
  belongs_to(:customer, Customer)

  field(:processor, :string)
  field(:session_token, :string)
  field(:mode, :string)
  field(:ui_mode, :string)
  field(:status, :string, default: "open")
  field(:price_id, :string)
  field(:line_items, {:array, :map}, default: [])
  field(:success_url, :string)
  field(:cancel_url, :string)
  field(:return_url, :string)
  field(:operation_id, :string)
  field(:expires_at, :utc_datetime_usec)
  field(:metadata, :map, default: %{})
  field(:data, :map, default: %{})
```

**Create-or-reuse pattern** ([accrue/lib/accrue/checkout/local_session.ex](/Users/jon/projects/accrue/accrue/lib/accrue/checkout/local_session.ex:65)):
```elixir
def create_or_reuse(%Customer{} = customer, attrs) when is_map(attrs) do
  case Map.get(attrs, :operation_id) || Map.get(attrs, "operation_id") do
    op_id when is_binary(op_id) and op_id != "" ->
      case by_operation_id(customer, op_id) do
        %__MODULE__{} = existing -> {:ok, existing}
        nil -> insert_session(customer, attrs)
      end

    _ ->
      insert_session(customer, attrs)
  end
end
```

**Copy forward:** if checkout preview state persists locally, reuse this exact `data`/`metadata` pattern and `operation_id` reuse logic rather than inventing a second persistence style.

---

### `accrue_portal/lib/accrue_portal/live/checkout_live.ex` (component, request-response)

**Analog:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`

**Mount + assigns pattern** ([accrue_portal/lib/accrue_portal/live/checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:17)):
```elixir
def mount(%{"token" => token}, %{"accrue_portal" => portal}, socket) do
  session = LocalSession.by_token(token)

  case session do
    %LocalSession{customer_id: customer_id} = checkout
    when customer_id == socket.assigns.current_customer.id ->
      {:ok,
       socket
       |> assign(:page_title, Copy.checkout_page_title())
       |> assign(:portal, portal)
       |> assign(:base_path, portal["mount_path"])
       |> assign(:checkout_session, checkout)
       |> assign(:client_token, client_token)
       |> assign(:checkout_amount, checkout_amount(checkout))
       |> assign(:checkout_error, nil)
       |> assign(:checkout_success, false)}
```

**Submit path calling core facade** ([accrue_portal/lib/accrue_portal/live/checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:53)):
```elixir
def handle_event("checkout_tokenized", %{"nonce" => nonce}, socket)
    when is_binary(nonce) and nonce != "" do
  checkout = socket.assigns.checkout_session

  case Billing.subscribe(
         socket.assigns.current_customer,
         checkout.price_id,
         payment_method: %{vault_acquisition: %{reference: nonce}},
         operation_id: checkout.operation_id
       ) do
```

**Current CTA rendering seam** ([accrue_portal/lib/accrue_portal/live/checkout_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/checkout_live.ex:148)):
```heex
<form
  :if={@client_token && checkout_ready?(@checkout_session) && !@checkout_success}
  id="checkout-form"
  phx-hook="BraintreeHostedFields"
  phx-submit="checkout_submit"
  class="portal-hosted-fields-form"
  data-portal-hosted-fields="checkout"
  data-client-token={@client_token}
>
```

**Copy forward:** add promo preview events and aria-live status into this LiveView, but keep the core call in `Accrue.Billing`, preserve tokenized submit behavior, and treat preview as provisional UI state.

---

### `accrue/priv/repo/migrations/*_create_accrue_discount_mappings.exs` (migration, CRUD)

**Analog:** `accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs`

**Recent migration structure** ([accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs:1)):
```elixir
defmodule Accrue.Repo.Migrations.CreateAccrueCheckoutSessions do
  use Ecto.Migration

  def change do
    create table(:accrue_checkout_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :customer_id, references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
        null: false
```

**Index pattern** ([accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260501180000_create_accrue_checkout_sessions.exs:28)):
```elixir
create unique_index(:accrue_checkout_sessions, [:session_token])
create unique_index(:accrue_checkout_sessions, [:operation_id])
create index(:accrue_checkout_sessions, [:customer_id, :inserted_at])
```

**Secondary analog for uniqueness-by-code** ([accrue/priv/repo/migrations/20260414130200_create_accrue_promotion_codes.exs](/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260414130200_create_accrue_promotion_codes.exs:19)):
```elixir
create table(:accrue_promotion_codes, primary_key: false) do
  add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
  add :processor, :string, null: false, default: "stripe"
  add :processor_id, :string, null: false
  add :code, :string, null: false
```

**Copy forward:** prefer the newer migration style from checkout sessions, plus the `:code` uniqueness/indexing pattern from promotion codes.

---

### `accrue/guides/braintree-local-portal.md` and `accrue/guides/stripe-vs-braintree-promotions.md` (docs)

**Analog:** `accrue/guides/braintree-local-portal.md`

**Capability-boundary language** ([accrue/guides/braintree-local-portal.md](/Users/jon/projects/accrue/accrue/guides/braintree-local-portal.md:16)):
```markdown
Unlike Stripe, Braintree does not offer a pre-built, hosted customer billing
portal for self-serve subscription management. Accrue now closes that gap with
first-party local portal semantics while still exposing the core primitives for
hand-rolled flows.
```

**Guide example pattern** ([accrue/guides/braintree-local-portal.md](/Users/jon/projects/accrue/accrue/guides/braintree-local-portal.md:77)):
```elixir
def handle_event("add_payment_method", %{"nonce" => nonce}, socket) do
  customer = socket.assigns.customer
  attrs = %{vault_acquisition: %{reference: nonce}}
  
  case Billing.add_payment_method(customer, attrs) do
    {:ok, payment_method} ->
```

**Copy forward:** document Stripe vs Braintree promotions in the same explicit capability-boundary style, and include code snippets that call the public `Billing` facade rather than direct table writes.

---

### `accrue/test/accrue/billing/discount_mapping_actions_test.exs` (test, CRUD)

**Analog:** `accrue/test/accrue/billing/coupon_actions_test.exs`

**Fixture + setup pattern** ([accrue/test/accrue/billing/coupon_actions_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/coupon_actions_test.exs:12)):
```elixir
setup do
  {:ok, customer} =
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_fake_promo"
    })
    |> Repo.insert()

  %{customer: customer}
end
```

**Constraint assertion pattern** ([accrue/test/accrue/billing/coupon_actions_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/coupon_actions_test.exs:82)):
```elixir
cs =
  PromotionCode.changeset(%PromotionCode{}, %{
    processor: "fake",
    processor_id: "promo_fake_handmade",
    code: "DUP"
  })

assert {:error, %Ecto.Changeset{errors: errors}} = Repo.insert(cs)
assert Keyword.has_key?(errors, :code)
```

**Validation-branch test pattern** ([accrue/test/accrue/billing/coupon_actions_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/coupon_actions_test.exs:153)):
```elixir
test "unknown code returns :not_found", %{sub: sub} do
  assert {:error, :not_found} = Billing.apply_promotion_code(sub, "NOPE")
end
```

**Copy forward:** mirror this layout for create/upsert, duplicate-code rejection, local eligibility branches, and typed drift errors.

---

### `accrue/test/accrue/billing/subscription_actions_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/billing/subscription_actions_test.exs`

**Braintree gateway stub pattern** ([accrue/test/accrue/billing/subscription_actions_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/subscription_actions_test.exs:7)):
```elixir
defmodule BraintreeGatewayStub do
  def create(params, _opts) do
    {:ok,
     struct!(Braintree.Subscription,
       id: "sub_bt_created",
       plan_id: params[:plan_id],
       payment_method_token: params[:payment_method_token],
       status: "Active",
```

**Malformed handoff assertions** ([accrue/test/accrue/billing/subscription_actions_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/subscription_actions_test.exs:124)):
```elixir
assert {:error, %Accrue.APIError{code: "invalid_request_error"} = error} =
         Billing.subscribe(customer, "price_premium", payment_method: "pm_123")

assert error.message =~ "require a vaulted payment_method_token passed as"
```

**Copy forward:** add Braintree-specific coverage here for resolved discount attachment during `subscribe/3`, plus typed hard-failure when the local code is valid but `discount_id` is unusable.

---

### `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` (test, request-response)

**Analog:** `accrue_portal/test/accrue_portal/live/checkout_live_test.exs`

**LiveView session fixture pattern** ([accrue_portal/test/accrue_portal/live/checkout_live_test.exs](/Users/jon/projects/accrue/accrue_portal/test/accrue_portal/live/checkout_live_test.exs:198)):
```elixir
defp checkout_fixture(%Customer{} = customer, attrs \\ %{}) do
  attrs =
    Map.merge(
      %{
        processor: "braintree",
        mode: "subscription",
        ui_mode: "hosted",
        status: "open",
        price_id: "price_fixture",
        line_items: [%{"price" => "price_fixture", "amount" => "49.00"}],
        success_url: "https://app.example.test/billing/success",
```

**Submit-path assertion pattern** ([accrue_portal/test/accrue_portal/live/checkout_live_test.exs](/Users/jon/projects/accrue/accrue_portal/test/accrue_portal/live/checkout_live_test.exs:132)):
```elixir
assert {:error, {:redirect, %{to: "https://app.example.test/billing/success"}}} =
         render_hook(view, "checkout_tokenized", %{
           "nonce" => "fake-valid-nonce",
           "number" => "4111111111111111",
           "cvv" => "123"
         })

assert LocalSession.by_id(session.id).status == "completed"
```

**Expired/inline error assertions** ([accrue_portal/test/accrue_portal/live/checkout_live_test.exs](/Users/jon/projects/accrue/accrue_portal/test/accrue_portal/live/checkout_live_test.exs:152)):
```elixir
assert {:ok, expired_view, expired_html} = live(conn, "/billing/checkout/#{expired.session_token}")
assert expired_html =~ "This checkout link has expired"

html =
  render_hook(view, "checkout_failed", %{
    "message" => "Card verification failed."
  })
```

**Copy forward:** add promo preview interaction tests here, including updated displayed totals, aria-live feedback, typed safe customer copy for mapping drift, and revalidation failure on submit.

## Shared Patterns

### Public facade spans
**Source:** [accrue/lib/accrue/billing.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:49), [accrue/lib/accrue/billing.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing.ex:651)
**Apply to:** new `Accrue.Billing` write/read helpers
```elixir
def subscribe(user, price_id_or_opts \\ [], opts \\ []) do
  span_billing(:subscription, :create, user, opts, fn ->
    SubscriptionActions.subscribe(user, price_id_or_opts, opts)
  end)
end
```

### Transaction + event recording
**Source:** [accrue/lib/accrue/billing/coupon_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/coupon_actions.ex:64), [accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:122)
**Apply to:** local mapping writes and create-time redemption side effects
```elixir
Repo.transact(fn ->
  with {:ok, row} <- ...,
       {:ok, _event} <- Events.record(%{...}) do
    {:ok, row}
  end
end)
```

### Typed operator-failure exceptions
**Source:** [accrue/lib/accrue/errors.ex](/Users/jon/projects/accrue/accrue/lib/accrue/errors.ex:112), [accrue/lib/accrue/errors.ex](/Users/jon/projects/accrue/accrue/lib/accrue/errors.ex:161)
**Apply to:** mapping drift or unusable Braintree discount IDs
```elixir
defexception [:message, :key, :diagnostic]

@impl true
def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
```

### Ops telemetry
**Source:** [accrue/lib/accrue/telemetry/ops.ex](/Users/jon/projects/accrue/accrue/lib/accrue/telemetry/ops.ex:40)
**Apply to:** discount mapping drift, missing discount, incompatible discount
```elixir
@spec emit(suffix(), map(), map()) :: :ok
def emit(suffix, measurements, metadata \\ %{})

def emit(suffix, measurements, metadata)
    when is_list(suffix) and is_map(measurements) and is_map(metadata) do
  event = [:accrue, :ops] ++ suffix
  :telemetry.execute(event, measurements, merged_metadata)
  :ok
end
```

### Local checkout state
**Source:** [accrue/lib/accrue/checkout/local_session.ex](/Users/jon/projects/accrue/accrue/lib/accrue/checkout/local_session.ex:20), [accrue_portal/test/accrue_portal/live/checkout_live_test.exs](/Users/jon/projects/accrue/accrue_portal/test/accrue_portal/live/checkout_live_test.exs:198)
**Apply to:** preview totals, selected code, and submit-time revalidation correlation
```elixir
field(:metadata, :map, default: %{})
field(:data, :map, default: %{})
```

## No Analog Found

None. Every implied file has at least a role-match analog in the current codebase, though `discount_mapping.ex` and `discount_mapping_actions.ex` should deliberately diverge from the current Stripe projection semantics.

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/priv/repo/migrations`, `accrue/test`, `accrue/guides`, `accrue_portal/lib`, `accrue_portal/test`
**Files scanned:** 17
**Pattern extraction date:** 2026-05-02

## PATTERN MAPPING COMPLETE

**Phase:** 102 - Coupon/Discount Mapping
**Files classified:** 14
**Analogs found:** 14 / 14

### Coverage
- Files with exact analog: 7
- Files with role-match analog: 6
- Files with no analog: 0

### Key Patterns Identified
- All public `Accrue.Billing` entry points wrap action modules with `span_billing/5`.
- Billing writes use `Repo.transact` plus `Events.record` for atomic persistence and audit trails.
- Braintree subscription creation is already isolated behind `build_subscription_request/4` and `Accrue.Processor.Braintree.build_request/1`.
- Portal checkout UI calls core billing functions rather than duplicating domain logic in LiveView.
- Typed exceptions and `Accrue.Telemetry.Ops.emit/3` are the repo-standard path for operator-visible failures.

### File Created
`.planning/phases/102-coupon-discount-mapping/102-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files.
