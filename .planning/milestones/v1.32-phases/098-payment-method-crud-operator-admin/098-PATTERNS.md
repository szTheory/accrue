# Phase 98: Payment Method CRUD & Operator Admin - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing.ex` | service | request-response | `accrue/lib/accrue/billing.ex` | exact |
| `accrue/lib/accrue/billing/payment_method_actions.ex` | service | CRUD | `accrue/lib/accrue/billing/payment_method_actions.ex` | exact |
| `accrue/lib/accrue/processor/braintree.ex` | service | request-response | `accrue/lib/accrue/processor/braintree.ex` | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | config | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/lib/accrue/errors.ex` | utility | request-response | `accrue/lib/accrue/errors.ex` | exact |
| `accrue/lib/accrue/webhook/default_handler.ex` | service | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/live/customer_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` | utility | request-response | `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` | exact |
| `accrue/test/accrue/billing/payment_method_actions_test.exs` | test | CRUD | `accrue/test/accrue/billing/payment_method_actions_test.exs` | exact |
| `accrue/test/accrue/billing/default_payment_method_test.exs` | test | CRUD | `accrue/test/accrue/billing/default_payment_method_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/customer_live_test.exs` | test | event-driven | `accrue_admin/test/accrue_admin/live/customer_live_test.exs` | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | service | request-response | `examples/accrue_host/lib/accrue_host/billing.ex` | exact |
| `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Facade span wrapper** (lines 299-359):
```elixir
def attach_payment_method(customer, pm_id_or_opts, opts \\ []) do
  span_billing(:payment_method, :attach, customer, opts, fn ->
    PaymentMethodActions.attach_payment_method(customer, pm_id_or_opts, opts)
  end)
end

def set_default_payment_method(customer, pm_id, opts \\ []) do
  span_billing(:payment_method, :set_default, customer, opts, fn ->
    PaymentMethodActions.set_default_payment_method(customer, pm_id, opts)
  end)
end

def list_payment_methods(customer, opts \\ []) do
  span_billing(:payment_method, :list, customer, opts, fn ->
    PaymentMethodActions.list_payment_methods(customer, opts)
  end)
end
```

**Use for Phase 98:** add new top-level CRUD verbs here with the same `span_billing/5` wrapper shape and bang/non-bang pairing. Keep old Stripe-shaped helpers as compatibility wrappers if needed, but make the new verbs canonical.

---

### `accrue/lib/accrue/billing/payment_method_actions.ex` (service, CRUD)

**Analog:** `accrue/lib/accrue/billing/payment_method_actions.ex`

**Imports and aliases** (lines 42-59):
```elixir
import Ecto.Query, only: [from: 2]

alias Accrue.Actor
alias Accrue.Billing.{Customer, PaymentMethod}
alias Accrue.Events
alias Accrue.Processor
alias Accrue.Processor.Idempotency
alias Accrue.Repo
```

**Transactional command pattern** (lines 72-90):
```elixir
def attach_payment_method(%Customer{} = customer, pm_processor_id, opts \\ [])
    when is_binary(pm_processor_id) do
  op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
  idem_key = Idempotency.key(:attach_payment_method, customer.id, op_id)

  Repo.transact(fn ->
    with {:ok, canonical} <- Processor.__impl__().retrieve_payment_method(pm_processor_id, []),
         fingerprint = get_card_fingerprint(canonical),
         {:ok, pm} <-
           dedup_or_attach(customer, canonical, fingerprint, pm_processor_id, idem_key, opts),
         {:ok, _} <-
           record_event("payment_method.attached", pm, %{
             deduped: pm.existing? == true,
             fingerprint: fingerprint
           }) do
      {:ok, pm}
    end
  end)
end
```

**Default mutation with strict ownership guard** (lines 219-252):
```elixir
unless pm.customer_id == customer.id do
  raise Accrue.Error.NotAttached,
    customer_id: customer.id,
    payment_method_id: pm.id,
    message:
      "Accrue.Billing.set_default_payment_method/2 refused to wire " <>
        "payment_method #{inspect(pm.id)} as the default for " <>
        "customer #{inspect(customer.id)} because the PM is attached " <>
        "to a different customer. Call attach_payment_method/2 first."
end

Repo.transact(fn ->
  with {:ok, _} <-
         Processor.__impl__().set_default_payment_method(
           customer.processor_id,
           %{invoice_settings: %{default_payment_method: pm.processor_id}},
           [idempotency_key: idem_key] ++ sanitize_opts(opts)
         ),
       {:ok, updated} <-
         customer
         |> Customer.changeset(%{default_payment_method_id: pm.id})
         |> Repo.update(),
       {:ok, _} <-
         record_event("customer.default_payment_method_changed", updated, %{
           payment_method_id: pm.id
         }) do
    {:ok, updated}
  end
end)
```

**Capability gate pattern** (lines 315-324):
```elixir
if Processor.first_party_supported?([:payment_method, :list]) do
  :ok
else
  {:error,
   %Accrue.APIError{
     code: "processor_operation_unsupported",
     message: "#{Processor.name()} does not support payment-method listing"
   }}
end
```

**Supplemental sync-through pattern:** `accrue/lib/accrue/billing/meter_event_actions.ex` lines 81-116 shows the repo’s preferred "local durable row first, provider write after, explicit failure/retry posture" pattern when Phase 98 needs a reconcile/resync command instead of a pure in-txn provider write.

**Use for Phase 98:** keep the same `Repo.transact` + `with` + event-recording shape, but move Braintree-safe delete/default/update flows to projection-first orchestration: guard locally, write to provider, refetch canonical state, then reproject.

---

### `accrue/lib/accrue/processor/braintree.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/braintree.ex`

**Capability declaration** (lines 13-31):
```elixir
def capabilities do
  %{
    payment_method: %{vault_acquisition: true},
    subscription: %{
      direct_create: true,
      cancel: true,
      fetch: true,
      lifecycle_webhook_projection: true,
      update: true,
      cancel_at_period_end: false,
      cancel_immediately: true,
      pause: false,
      resume: false
    },
    invoice: %{lifecycle_webhook_projection: true},
    webhook: %{verify: true, parse: true}
  }
end
```

**Host-owned vault handoff translator** (lines 55-69):
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

**Error translation and unsupported semantic pattern** (lines 235-349):
```elixir
defp to_accrue_error(raw) do
  %APIError{
    code: "braintree_error",
    http_status: 400,
    message: inspect(raw)
  }
end

defp unsupported_semantic(semantic) do
  %APIError{
    code: "processor_operation_unsupported",
    http_status: 422,
    message: "Braintree does not support Accrue's #{semantic} semantic."
  }
end

defp unsupported do
  %APIError{
    code: "unsupported_operation",
    http_status: 501,
    message: "This operation is out of slice for the Braintree adapter."
  }
end
```

**Stripe payment-method callback shape to mirror** from `accrue/lib/accrue/processor/stripe.ex` lines 420-479:
```elixir
def retrieve_payment_method(id, opts) when is_binary(id) and is_list(opts) do
  client = build_client!(opts)

  client
  |> LatticeStripe.PaymentMethod.retrieve(id, stripe_opts_no_idem(opts))
  |> translate_resource()
end

def update_payment_method(id, params, opts)
    when is_binary(id) and is_map(params) and is_list(opts) do
  client = build_client!(opts)
  stripe_opts = stripe_opts(:update_payment_method, id, opts)

  client
  |> LatticeStripe.PaymentMethod.update(id, stringify_keys(params), stripe_opts)
  |> translate_resource()
end
```

**Use for Phase 98:** keep Braintree adapter functions narrow and honest. Translate Accrue’s public attrs to Braintree’s `Customer`/`PaymentMethod` gateway calls in this adapter; do not leak provider vocabulary back into the facade.

---

### `accrue/lib/accrue/processor/capabilities.ex` (config, transform)

**Analog:** `accrue/lib/accrue/processor/capabilities.ex`

**Support-label SSOT** (lines 11-48):
```elixir
@support_labels %{
  customer: %{
    create: "all first-party",
    retrieve: "all first-party",
    update: "staged first-party target"
  },
  payment_method: %{
    vault_acquisition: "all first-party",
    list: "out of slice"
  },
  subscription: %{
    direct_create: "all first-party",
    fetch: "all first-party",
    cancel: "staged first-party target",
    lifecycle_webhook_projection: "all first-party",
    update: "staged first-party target"
  }
}
```

**First-party support predicate** (lines 82-89):
```elixir
def first_party_supported?(capabilities, path)
    when is_map(capabilities) and is_list(path) do
  support_label(path) == "all first-party" and supports?(capabilities, path)
end
```

**Use for Phase 98:** extend the `payment_method` support labels here when CRUD verbs become official. Keep support language and executable gating aligned.

---

### `accrue/lib/accrue/errors.ex` (utility, request-response)

**Analog:** `accrue/lib/accrue/errors.ex`

**Typed exception pattern** (lines 178-209):
```elixir
defmodule Accrue.Error.NotAttached do
  @type t :: %__MODULE__{}
  defexception [:customer_id, :payment_method_id, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{customer_id: cus_id, payment_method_id: pm_id}) do
    "payment method #{inspect(pm_id)} is not attached to customer #{inspect(cus_id)}"
  end
end

defmodule Accrue.Error.NoDefaultPaymentMethod do
  @type t :: %__MODULE__{}
  defexception [:customer_id, :message]
end
```

**APIError posture** (lines 6-17):
```elixir
defmodule Accrue.APIError do
  @type t :: %__MODULE__{}
  defexception [:message, :code, :http_status, :request_id, :processor_error]
end
```

**Use for Phase 98:** add new payment-method-specific failure types here only when they need distinct matchable semantics. Otherwise reuse `%Accrue.APIError{code: ...}` for unsupported, in-use, stale/conflict, and provider failure cases.

---

### `accrue/lib/accrue/webhook/default_handler.ex` (service, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Refetch-and-reproject reducer** (lines 891-952):
```elixir
defp reduce_payment_method(action, evt_id, evt_ts, obj) do
  stripe_id = get(obj, :id)

  reduce_row(:payment_method, stripe_id, evt_ts, evt_id, fn row ->
    with {:ok, canonical} <- Processor.__impl__().fetch(:payment_method, stripe_id),
         {:ok, updated} <- upsert_payment_method(row, canonical, evt_ts, evt_id),
         {:ok, _} <- record_event(pm_event_type(action), "PaymentMethod", updated.id, evt_id) do
      {:ok, updated}
    end
  end)
end
```

**Projection write pattern** (lines 908-946):
```elixir
attrs = %{
  fingerprint: SubscriptionProjection.get(card, :fingerprint),
  exp_month: SubscriptionProjection.get(card, :exp_month),
  exp_year: SubscriptionProjection.get(card, :exp_year),
  card_brand: SubscriptionProjection.get(card, :brand),
  card_last4: SubscriptionProjection.get(card, :last4),
  last_stripe_event_ts: evt_ts,
  last_stripe_event_id: evt_id
}

%PaymentMethod{customer_id: customer_id, processor: processor_name()}
|> PaymentMethod.changeset(
  Map.merge(attrs, %{
    processor_id: SubscriptionProjection.get(canonical, :id),
    type: SubscriptionProjection.get(canonical, :type) || "card"
  })
)
|> Repo.insert()
```

**Use for Phase 98:** copy this canonical refetch-and-project posture for post-write sync and explicit reconcile commands. This is the cleanest existing example of "provider truth -> normalized local row".

---

### `accrue_admin/lib/accrue_admin/live/customer_live.ex` (component, event-driven)

**Analog:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`

**LiveView mount/assign pattern** (lines 30-55):
```elixir
def mount(%{"id" => customer_id}, session, socket) do
  admin = Map.get(session, "accrue_admin", %{})

  case Customers.detail(customer_id, socket.assigns.current_owner_scope) do
    :not_found ->
      {:ok,
       socket
       |> put_flash(:error, Copy.Locked.owner_access_denied())
       |> redirect(to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/customers"))}

    {:ok, customer} ->
      {:ok,
       socket
       |> assign_shell(admin)
       |> assign(:customer, customer)
       |> assign(:params, %{})
       |> assign(:tab, "subscriptions")
       |> assign(:tab_counts, tab_counts(customer))}
  end
end
```

**Existing payment-method tab render seam** (lines 176-184):
```elixir
<section class="ax-card">
  <h3 class="ax-heading"><%= Copy.customer_payment_methods_section_heading() %></h3>
  <div :for={payment_method <- payment_methods(@customer)} class="ax-list-row">
    <span class="ax-body"><%= payment_method.card_brand || payment_method.type || Copy.customer_payment_methods_row_fallback_label() %> <%= Copy.customer_payment_methods_card_last4_mask() %> <%= payment_method.card_last4 || "--" %></span>
    <span class="ax-body"><%= expiry(payment_method) %></span>
  </div>
  <p :if={payment_methods(@customer) == []} class="ax-body"><%= Copy.customer_payment_methods_empty_copy() %></p>
</section>
```

**Query helper pattern** (lines 275-279):
```elixir
defp payment_methods(customer) do
  PaymentMethod
  |> where([payment_method], payment_method.customer_id == ^customer.id)
  |> order_by([payment_method], desc: payment_method.inserted_at, desc: payment_method.id)
  |> Repo.all()
end
```

**Destructive operator flow analog:** `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` lines 102-141 is the clearest local proof of step-up-gated admin mutation plus audit assertions. Reuse that interaction pattern for guarded delete and explicit default changes if step-up is required.

**Use for Phase 98:** keep all mutations server-driven in this LiveView. Add `phx-click`/`phx-submit` handlers here rather than browser-side provider calls.

---

### `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` (utility, request-response)

**Analog:** `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex`

**Copy module shape** (lines 1-15):
```elixir
defmodule AccrueAdmin.Copy.CustomerPaymentMethods do
  @moduledoc false

  def section_heading, do: "Payment methods"
  def empty_copy, do: "No payment methods on file."
  def row_fallback_label, do: "Payment method"
  def card_last4_mask, do: "·••••"
end
```

**Use for Phase 98:** add operator warning, set-default, delete, sync, and host-handoff copy here instead of hardcoding strings in the LiveView.

---

### `accrue/test/accrue/billing/payment_method_actions_test.exs` (test, CRUD)

**Analog:** `accrue/test/accrue/billing/payment_method_actions_test.exs`

**Processor override setup** (lines 7-18):
```elixir
setup do
  previous = Application.get_env(:accrue, :processor)
  Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

  on_exit(fn ->
    if previous do
      Application.put_env(:accrue, :processor, previous)
    else
      Application.delete_env(:accrue, :processor)
    end
  end)
end
```

**Tuple/raise assertion pattern** (lines 33-43):
```elixir
assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
         Billing.list_payment_methods(customer, [])

assert_raise Accrue.APIError, ~r/does not support payment-method listing/, fn ->
  Billing.list_payment_methods!(customer, [])
end
```

**Use for Phase 98:** follow this structure for new CRUD facade tests, especially for unsupported capability and error-code assertions.

---

### `accrue/test/accrue/billing/default_payment_method_test.exs` (test, CRUD)

**Analog:** `accrue/test/accrue/billing/default_payment_method_test.exs`

**Fixture setup pattern** (lines 11-45):
```elixir
{:ok, customer} =
  %Customer{}
  |> Customer.changeset(%{owner_type: "User", owner_id: Ecto.UUID.generate(), processor: "fake"})
  |> Repo.insert()

{:ok, pm} =
  %PaymentMethod{}
  |> PaymentMethod.changeset(%{
    customer_id: customer.id,
    processor: "fake",
    processor_id: "pm_fake_default_owned",
    type: "card"
  })
  |> Repo.insert()
```

**Guarded default assertions** (lines 48-99):
```elixir
Fake.scripted_response(:set_default_payment_method, {:ok, %{id: cus.processor_id}})
assert {:ok, %Customer{} = updated} = Billing.set_default_payment_method(cus, pm)
assert updated.default_payment_method_id == pm.id

assert_raise Accrue.Error.NotAttached, fn ->
  Billing.set_default_payment_method(cus, foreign_pm)
end
```

**Use for Phase 98:** extend this exact style for replacement-required, in-use, and stale/conflict cases.

---

### `accrue_admin/test/accrue_admin/live/customer_live_test.exs` (test, event-driven)

**Analog:** `accrue_admin/test/accrue_admin/live/customer_live_test.exs`

**Render assertion pattern** (lines 229-253):
```elixir
assert {:ok, _view, html} =
         live(conn, "/billing/customers/#{customer.id}?tab=payment_methods")

assert html =~ Copy.customer_payment_methods_section_heading()
assert html =~ Copy.customer_payment_methods_card_last4_mask()
assert html =~ "4242"
assert html =~ "visa"

assert {:ok, _view, html} =
         live(conn, "/billing/customers/#{bare_customer.id}?tab=payment_methods")

assert html =~ Copy.customer_payment_methods_empty_copy()
```

**Use for Phase 98:** follow this exact test style for operator controls and warning copy on the customer payment-method tab.

---

### `examples/accrue_host/lib/accrue_host/billing.ex` (service, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host/billing.ex`

**Host policy wrapper pattern** (lines 89-95):
```elixir
def subscribe_with_vault_reference(%Scope{} = scope, price_id, vault_reference, opts \\ []) do
  with {:ok, organization} <- organization_from_scope(scope),
       :ok <- authorize_billing_mutation(scope) do
    opts = Keyword.put(opts, :payment_method, %{vault_acquisition: %{reference: vault_reference}})
    subscribe(organization, price_id, opts)
  end
end
```

**Use for Phase 98:** any host-assisted add/replace seam should stay here, not in `accrue_admin`. Keep authorization and scope handling in the host layer, then pass only narrow `vault_acquisition` attrs into `Accrue.Billing`.

---

### `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` (test, request-response)

**Analog:** `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs`

**Inline adapter mock pattern** (lines 10-17, 115-121):
```elixir
defmodule BraintreeMockAdapter.Braintree do
  @behaviour Accrue.Processor

  def processor_name, do: "braintree"
  def capabilities, do: Accrue.Processor.Braintree.capabilities()

  def create_payment_method(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
  def retrieve_payment_method(_, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
  def attach_payment_method(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
  def set_default_payment_method(_, _, _), do: {:error, %Accrue.APIError{message: "Unsupported"}}
end
```

**Host proof assertion pattern** (lines 162-184):
```elixir
assert {:ok, %Accrue.Billing.Subscription{} = subscription} =
  Billing.subscribe_with_vault_reference(scope, sandbox_plan_id, vault_reference)

assert subscription.processor == "braintree"
assert subscription.processor_id == "sub_braintree_123"
```

**Use for Phase 98:** if host proof expands to payment-method add/replace flows, keep it hermetic with the same inline adapter approach and assert the public host facade, not internal adapter calls.

## Shared Patterns

### Public Billing Facade
**Source:** `accrue/lib/accrue/billing.ex` lines 299-359  
**Apply to:** all new public CRUD verbs
```elixir
def some_public_command(subject, opts \\ []) do
  span_billing(:payment_method, :action_name, subject, opts, fn ->
    PaymentMethodActions.some_public_command(subject, opts)
  end)
end
```

### Transaction + Event Ledger
**Source:** `accrue/lib/accrue/billing/payment_method_actions.ex` lines 77-90, 234-252  
**Apply to:** add, replace, delete, set-default commands
```elixir
Repo.transact(fn ->
  with {:ok, provider_result} <- provider_call(...),
       {:ok, updated_local} <- local_write(...),
       {:ok, _} <- record_event("...", updated_local, %{...}) do
    {:ok, updated_local}
  end
end)
```

### Write-Through Refetch / Reprojection
**Source:** `accrue/lib/accrue/webhook/default_handler.ex` lines 891-952  
**Apply to:** Braintree post-write sync and explicit reconcile
```elixir
with {:ok, canonical} <- Processor.__impl__().fetch(:payment_method, processor_id),
     {:ok, updated} <- upsert_payment_method(row, canonical, evt_ts, evt_id) do
  {:ok, updated}
end
```

### Capability Gating
**Source:** `accrue/lib/accrue/processor/capabilities.ex` lines 11-48, `accrue/lib/accrue/billing/payment_method_actions.ex` lines 315-324  
**Apply to:** list/update/delete/default verbs across processors
```elixir
if Processor.first_party_supported?([:payment_method, :list]) do
  :ok
else
  {:error, %Accrue.APIError{code: "processor_operation_unsupported", ...}}
end
```

### Host-Owned Vault Acquisition
**Source:** `examples/accrue_host/lib/accrue_host/billing.ex` lines 89-95 and `accrue/lib/accrue/processor/braintree.ex` lines 55-69  
**Apply to:** add/replace payment method flows
```elixir
opts = Keyword.put(opts, :payment_method, %{vault_acquisition: %{reference: vault_reference}})
subscribe(organization, price_id, opts)
```

### Admin Copy Isolation
**Source:** `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` lines 1-15  
**Apply to:** all new operator-facing payment-method copy
```elixir
def warning_copy, do: "..."
def sync_cta, do: "..."
def delete_confirm_copy, do: "..."
```

## No Analog Found

Files the planner may choose to introduce, but which do not have a close existing payment-method-specific analog yet:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `accrue/lib/accrue/jobs/payment_method_reconciler.ex` | job/service | batch | Repo has reconcile patterns for meter events, but no payment-method-specific reconcile worker exists yet. Prefer `MeterEventActions` / `Jobs.MeterEventsReconciler` style if planner chooses an async repair path. |
| `accrue/test/accrue/billing/payment_method_delete_guard_test.exs` | test | CRUD | Existing payment-method tests cover attach/list/default, but not Braintree-specific guarded delete semantics. Use the existing payment-method test modules as structure analogs. |

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue/test/accrue`, `accrue_admin/lib/accrue_admin`, `accrue_admin/test/accrue_admin`, `examples/accrue_host/lib`, `examples/accrue_host/test`  
**Files scanned:** 19  
**Pattern extraction date:** 2026-04-30
