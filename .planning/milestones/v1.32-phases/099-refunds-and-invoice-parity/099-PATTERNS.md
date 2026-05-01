# Phase 99: Refunds and Invoice Parity - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing.ex` | service | request-response | `accrue/lib/accrue/billing.ex` | exact |
| `accrue/lib/accrue/billing/refund_actions.ex` | service | CRUD | `accrue/lib/accrue/billing/refund_actions.ex` | exact |
| `accrue/lib/accrue/billing/refund.ex` | model | CRUD | `accrue/lib/accrue/billing/refund.ex` | exact |
| `accrue/priv/repo/migrations/*_add_processor_id_to_accrue_refunds.exs` | migration | CRUD | `accrue/priv/repo/migrations/20260414120000_phase3_schema_upgrades.exs` | role-match |
| `accrue/lib/accrue/processor/braintree.ex` | service | request-response | `accrue/lib/accrue/processor/braintree.ex` | role-match |
| `accrue/lib/accrue/webhook/default_handler.ex` | middleware | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |
| `accrue/lib/accrue/jobs/reconcile_refund_fees.ex` | service | batch | `accrue/lib/accrue/jobs/reconcile_refund_fees.ex` | exact |
| `accrue/lib/accrue/billing/invoice_projection.ex` | service | transform | `accrue/lib/accrue/billing/invoice_projection.ex` | exact |
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | request-response | `accrue/lib/accrue/billing/subscription_actions.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | component | event-driven | `accrue_admin/lib/accrue_admin/live/charge_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` | utility | transform | `accrue_admin/lib/accrue_admin/copy.ex` | exact |
| `accrue/test/accrue/billing/refund_braintree_test.exs` | test | CRUD | `accrue/test/accrue/billing/refund_test.exs` | role-match |
| `accrue/test/accrue/webhook/braintree_refund_convergence_test.exs` | test | event-driven | `accrue/test/accrue/webhook/default_handler_phase3_test.exs` | exact |
| `accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs` | test | transform | `accrue/test/accrue/billing/invoice_projection_test.exs` | exact |
| `accrue_admin/test/accrue_admin/live/charge_live_test.exs` | test | event-driven | `accrue_admin/test/accrue_admin/live/charge_live_test.exs` | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Public facade pattern** (lines 539-549):
```elixir
# Keep the public seam in Billing and wrap it in telemetry/span helpers.
def create_refund(charge, opts \\ []),
  do:
    span_billing(:refund, :create, charge, opts, fn ->
      RefundActions.create_refund(charge, opts)
    end)

def create_refund!(charge, opts \\ []),
  do:
    span_billing(:refund, :create, charge, opts, fn ->
      RefundActions.create_refund!(charge, opts)
    end)
```

**Use for Phase 99:** add `refund/2` and `refund!/2` beside this pattern, then keep `create_refund/2` delegating for v1.x compatibility.

---

### `accrue/lib/accrue/billing/refund_actions.ex` (service, CRUD)

**Analog:** `accrue/lib/accrue/billing/refund_actions.ex`

**Imports + collaborators** (lines 19-25):
```elixir
alias Accrue.Actor
alias Accrue.Billing.{Charge, Refund}
alias Accrue.Events
alias Accrue.Money
alias Accrue.Processor
alias Accrue.Processor.Idempotency
alias Accrue.Repo
```

**Canonical mutation + idempotency pattern** (lines 45-97):
```elixir
def create_refund(%Charge{} = charge, opts \\ []) do
  amount_minor =
    case Keyword.get(opts, :amount) do
      nil -> charge.amount_cents
      %Money{currency: cur, amount_minor: n} -> ...
      other -> raise ArgumentError, ...
    end

  op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
  subject_uuid = Idempotency.subject_uuid(:create_refund, op_id)
  idem_key = Idempotency.key(:create_refund, subject_uuid, op_id)

  params =
    %{
      charge: charge.processor_id,
      amount: amount_minor,
      expand: ["balance_transaction", "charge.balance_transaction"]
    }
    |> put_if_present(:reason, Keyword.get(opts, :reason))

  Repo.transact(fn ->
    with {:ok, stripe_refund} <-
           Processor.__impl__().create_refund(
             params,
             [idempotency_key: idem_key] ++ sanitize_opts(opts)
           ),
         {:ok, refund_row} <-
           insert_or_fetch_refund(subject_uuid, charge, stripe_refund, amount_minor),
         {:ok, _} <-
           record_event("refund.created", refund_row, %{
             amount_minor: amount_minor,
             charge_id: charge.id
           }) do
      {:ok, refund_row}
    end
  end)
end
```

**Projection insert pattern** (lines 124-188):
```elixir
defp insert_refund(id, %Charge{} = charge, stripe_refund, amount_minor) do
  charge_bt =
    case get_field(stripe_refund, :charge) do
      %{} = c -> get_field(c, :balance_transaction) || %{}
      _ -> %{}
    end

  fee = get_field(charge_bt, :fee)
  fee_refunded = get_field(charge_bt, :fee_refunded)

  {stripe_fee_refunded, merchant_loss, settled_at} =
    case {fee, fee_refunded} do
      {f, fr} when is_integer(f) and is_integer(fr) ->
        {fr, max(0, f - fr), Accrue.Clock.utc_now()}
      _ ->
        {nil, nil, nil}
    end

  attrs = %{
    charge_id: charge.id,
    stripe_id: get_field(stripe_refund, :id),
    amount_minor: get_field(stripe_refund, :amount) || amount_minor,
    currency: currency,
    reason: get_field(stripe_refund, :reason),
    status: status,
    stripe_fee_refunded_amount_minor: stripe_fee_refunded,
    merchant_loss_amount_minor: merchant_loss,
    fees_settled_at: settled_at,
    data: stringify(stripe_refund),
    metadata: get_field(stripe_refund, :metadata) || %{}
  }

  %Refund{}
  |> Refund.changeset(attrs)
  |> Ecto.Changeset.force_change(:id, id)
  |> Repo.insert()
end
```

**Use for Phase 99:** preserve `Repo.transact`, actor/idempotency, and append-only event recording. Change the inserted attrs to dual-write `processor_id` plus compatibility `stripe_id`, and keep `data` as the provider payload sink.

---

### `accrue/lib/accrue/billing/refund.ex` (model, CRUD)

**Analog:** `accrue/lib/accrue/billing/refund.ex`

**Schema shape** (lines 28-46):
```elixir
schema "accrue_refunds" do
  belongs_to(:charge, Accrue.Billing.Charge)

  field(:stripe_id, :string)
  field(:amount_minor, :integer)
  field(:currency, :string)
  field(:reason, :string)
  field(:status, Ecto.Enum, values: @statuses, default: :pending)
  field(:stripe_fee_refunded_amount_minor, :integer)
  field(:merchant_loss_amount_minor, :integer)
  field(:fees_settled_at, :utc_datetime_usec)
  field(:last_stripe_event_ts, :utc_datetime_usec)
  field(:last_stripe_event_id, :string)
  field(:data, :map, default: %{})
  field(:metadata, :map, default: %{})
  field(:lock_version, :integer, default: 1)

  timestamps(type: :utc_datetime_usec)
end
```

**Changeset pattern** (lines 48-70):
```elixir
@cast_fields ~w[
  charge_id stripe_id amount_minor currency reason status
  stripe_fee_refunded_amount_minor merchant_loss_amount_minor
  fees_settled_at last_stripe_event_ts last_stripe_event_id
  data metadata lock_version
]a

@required_fields ~w[charge_id amount_minor currency]a

def changeset(refund_or_changeset, attrs \\ %{}) do
  refund_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
  |> foreign_key_constraint(:charge_id)
end
```

**Use for Phase 99:** add `processor_id` additively to the schema and cast fields, keep `stripe_id` in place, and preserve optimistic locking plus metadata validation unchanged.

---

### `accrue/priv/repo/migrations/*_add_processor_id_to_accrue_refunds.exs` (migration, CRUD)

**Analog:** `accrue/priv/repo/migrations/20260414120000_phase3_schema_upgrades.exs`

**Additive column style** (lines 12-15, 122-156):
```elixir
# All changes are additive. Existing rows survive unchanged.

create table(:accrue_refunds, primary_key: false) do
  add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
  add :charge_id,
      references(:accrue_charges, type: :binary_id, on_delete: :restrict),
      null: false
  add :stripe_id, :string, null: true
  add :amount_minor, :bigint, null: false
  ...
end

create unique_index(:accrue_refunds, [:stripe_id],
         where: "stripe_id IS NOT NULL",
         name: :accrue_refunds_stripe_id_index
       )
```

**Alter-table style** (lines 22-28):
```elixir
alter table(:accrue_subscriptions) do
  modify :status, :string, null: false, default: "incomplete", from: {:string, null: true}
  add :cancel_at_period_end, :boolean, null: false, default: false
  add :pause_collection, :map, null: true
  add :last_stripe_event_ts, :utc_datetime_usec, null: true
  add :last_stripe_event_id, :string, null: true
end
```

**Use for Phase 99:** create a small additive migration: `alter table(:accrue_refunds)`, `add :processor_id, :string, null: true`, backfill from `stripe_id` in SQL if needed, and add a partial unique index on `processor_id`. Do not rename or drop `stripe_id`.

---

### `accrue/lib/accrue/processor/braintree.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/braintree.ex`

**Fetch contract pattern** (lines 59-61):
```elixir
@impl Accrue.Processor
def fetch(:subscription, id), do: retrieve_subscription(id, [])
def fetch(_type, _id), do: {:error, unsupported()}
```

**Current refund stub seam** (lines 274-278):
```elixir
# Refund
@impl Accrue.Processor
def create_refund(_params, _opts), do: {:error, unsupported()}
@impl Accrue.Processor
def retrieve_refund(_id, _opts), do: {:error, unsupported()}
```

**Unsupported-semantic error shape** (lines 332-347, 554-567):
```elixir
defp translate_update_params(params) do
  cond do
    Map.has_key?(params, :items) or Map.has_key?(params, "items") ->
      translate_item_update(params[:items] || params["items"])
    ...
    true ->
      {:error, invalid_request("Unsupported Braintree subscription update payload: #{inspect(params)}")}
  end
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

**Use for Phase 99:** implement `create_refund/2`, `retrieve_refund/2`, and `fetch(:refund, id)` in the same adapter style as subscription fetch. Keep all error translation returning `%Accrue.APIError{}` instead of raw SDK terms.

---

### `accrue/lib/accrue/webhook/default_handler.ex` (middleware, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Refund dispatch pattern** (lines 191-201):
```elixir
defp dispatch("charge.refund.updated", evt_id, evt_ts, obj) do
  result = reduce_refund("updated", evt_id, evt_ts, obj)
  maybe_dispatch_refund_email(result, obj)
  result
end

defp dispatch("refund." <> action, evt_id, evt_ts, obj)
     when action in ~w(created updated) do
  result = reduce_refund(action, evt_id, evt_ts, obj)
  maybe_dispatch_refund_email(result, obj)
  result
end
```

**Reducer + canonical refetch** (lines 762-787):
```elixir
defp reduce_refund(action, evt_id, evt_ts, obj) do
  stripe_id = get(obj, :id)

  reduce_row(:refund, stripe_id, evt_ts, evt_id, fn row ->
    with {:ok, canonical} <- Processor.__impl__().fetch(:refund, stripe_id),
         {:ok, upsert_result} <- upsert_refund(row, canonical, evt_ts, evt_id) do
      case upsert_result do
        :deferred ->
          {:ok, :deferred}

        %Refund{} = updated ->
          event_type = refund_event_type(updated, action)

          with {:ok, _} <- record_event(event_type, "Refund", updated.id, evt_id) do
            {:ok, updated}
          end
      end
    end
  end)
end
```

**Out-of-order deferral pattern** (lines 846-877):
```elixir
case row do
  nil ->
    case charge_stripe_id && Repo.get_by(Charge, processor_id: charge_stripe_id) do
      %Charge{} = charge ->
        %Refund{charge_id: charge.id}
        |> Refund.changeset(
          Map.merge(attrs, %{
            stripe_id: SubscriptionProjection.get(canonical, :id),
            amount_minor: SubscriptionProjection.get(canonical, :amount),
            currency: SubscriptionProjection.get(canonical, :currency) || "usd"
          })
        )
        |> Repo.insert()

      _ ->
        :telemetry.execute(
          [:accrue, :webhooks, :orphan_refund],
          %{},
          %{refund_stripe_id: ..., charge_stripe_id: charge_stripe_id}
        )

        {:ok, :deferred}
    end
```

**Shared stale-event wrapper** (lines 959-985):
```elixir
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
```

**Braintree normalization precedent** (lines 1219-1226):
```elixir
defp normalize_braintree_type("subscription_charged_successfully"), do: {:ok, "invoice.paid"}
defp normalize_braintree_type("subscription_charged_unsuccessfully"), do: {:ok, "invoice.payment_failed"}
...
defp normalize_braintree_type(_), do: :ignored
```

**Use for Phase 99:** extend this reducer path, not a parallel Braintree-only path. Add Braintree refund convergence by normalizing only real Braintree signals and falling back to explicit fetch/reconcile where webhook coverage is absent.

---

### `accrue/lib/accrue/jobs/reconcile_refund_fees.ex` (service, batch)

**Analog:** `accrue/lib/accrue/jobs/reconcile_refund_fees.ex`

**Oban worker + sweep pattern** (lines 37-63):
```elixir
use Oban.Worker, queue: :accrue_reconcilers, max_attempts: 3

def perform(%Oban.Job{} = job) do
  Accrue.Oban.Middleware.put(job)
  sweep()
end

def sweep do
  cutoff = DateTime.add(Accrue.Clock.utc_now(), -86_400, :second)

  query =
    from(r in Refund,
      where: is_nil(r.fees_settled_at) and r.inserted_at < ^cutoff
    )

  query
  |> Repo.all()
  |> Enum.each(&reconcile/1)

  :ok
end
```

**Reconcile + telemetry + event pattern** (lines 66-99):
```elixir
with {:ok, canonical} <-
       Processor.__impl__().retrieve_refund(sid,
         expand: ["balance_transaction", "charge.balance_transaction"]
       ),
     ... do
  {:ok, updated} = row |> Refund.changeset(attrs) |> Repo.update()

  :telemetry.execute(
    [:accrue, :billing, :refund, :fees_settled],
    %{},
    %{refund_id: updated.id, source: :reconciler}
  )

  _ =
    Events.record(%{
      type: "refund.fees_settled",
      subject_type: "Refund",
      subject_id: updated.id,
      data: %{source: "reconciler"}
    })

  :ok
else
  _ -> :skip
end
```

**Use for Phase 99:** if refund truth needs a Braintree batch backstop, mirror this worker shape: targeted query, canonical retrieve, row update, telemetry, append-only event.

---

### `accrue/lib/accrue/billing/invoice_projection.ex` (service, transform)

**Analog:** `accrue/lib/accrue/billing/invoice_projection.ex`

**Provider branch pattern** (lines 25-94):
```elixir
@spec decompose(map()) :: {:ok, decomposed()}
def decompose(%{"transactions" => transactions} = braintree_sub) when is_list(transactions) do
  tx = List.first(transactions) || %{}

  status =
    case tx["status"] do
      "settled" -> :paid
      "settling" -> :paid
      "submitted_for_settlement" -> :paid
      "processor_declined" -> :uncollectible
      "gateway_rejected" -> :uncollectible
      "failed" -> :uncollectible
      "voided" -> :void
      _ -> :draft
    end

  amount_due = if status == :paid, do: 0, else: (tx["amount"] || 0) * 100
  amount_paid = if status == :paid, do: (tx["amount"] || 0) * 100, else: 0

  invoice_attrs = %{... data: SubscriptionProjection.to_string_keys(braintree_sub), metadata: %{}}
  item_attrs = [%{... data: tx}]

  {:ok, %{invoice_attrs: invoice_attrs, item_attrs: item_attrs}}
end
```

**Stripe/fake decomposition pattern** (lines 128-205):
```elixir
invoice_attrs = %{
  processor_id: SubscriptionProjection.get(stripe_inv, :id),
  status: parse_status(SubscriptionProjection.get(stripe_inv, :status)),
  subtotal_minor: SubscriptionProjection.get(stripe_inv, :subtotal),
  ...
  data: SubscriptionProjection.to_string_keys(stripe_inv),
  metadata: SubscriptionProjection.get(stripe_inv, :metadata) || %{}
}

item_attrs =
  stripe_inv
  |> SubscriptionProjection.get(:lines)
  |> ...
  |> Enum.map(fn line ->
    %{
      stripe_id: SubscriptionProjection.get(line, :id),
      description: SubscriptionProjection.get(line, :description),
      amount_minor: SubscriptionProjection.get(line, :amount),
      ...
    }
  end)
```

**Use for Phase 99:** keep invoices as sale-cycle projections. Add refund-derived rollups as additive read-model fields or helper outputs; do not mutate invoice status into a net-refund status machine.

---

### `accrue/lib/accrue/billing/subscription_actions.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/billing/subscription_actions.ex`

**Explicit option schema pattern** (lines 228-257):
```elixir
@swap_schema [
  proration: [
    type: {:in, [:create_prorations, :none, :always_invoice]},
    required: true
  ],
  proration_date: [type: :any, default: nil],
  billing_cycle_anchor: [
    type: {:in, [:unchanged, :now]},
    default: :unchanged
  ],
  payment_behavior: [...],
  ...
]

@required_proration_msg "Accrue.Billing.swap_plan/3 requires an explicit :proration option ..."
```

**Fail-clearly processor gate** (lines 263-314):
```elixir
validated = validate_swap_opts!(opts)
sub = Repo.preload(sub, :subscription_items)

result =
  if braintree_processor?() do
    {:error,
     %Accrue.APIError{
       code: "processor_operation_unsupported",
       http_status: 422,
       message:
         "Braintree plan swaps are unsupported through Accrue's generic swap_plan/3 facade " <>
           "because the provider requires an explicit subscription price update alongside plan_id."
     }}
  else
    ...
  end

IntentResult.wrap(result)
```

**Validation error pattern** (lines 326-346):
```elixir
case NimbleOptions.validate(opts, @swap_schema) do
  {:ok, v} -> v
  {:error, %NimbleOptions.ValidationError{key: :proration} = err} -> ...
  {:error, %NimbleOptions.ValidationError{message: msg}} -> ...
end
```

**Use for Phase 99:** copy this explicit gating style for Braintree proration support. Reject unsupported knobs with typed `%Accrue.APIError{}` instead of silently degrading behavior.

---

### `accrue_admin/lib/accrue_admin/live/charge_live.ex` (component, event-driven)

**Analog:** `accrue_admin/lib/accrue_admin/live/charge_live.ex`

**Thin server-driven action flow** (lines 45-69):
```elixir
def handle_event("prepare_refund", params, socket) do
  case build_refund_action(params, socket.assigns.charge, socket.assigns.timeline_events) do
    {:ok, action} ->
      {:noreply, assign(socket, :pending_refund, action)}

    {:error, reason} ->
      {:noreply, push_flash(socket, :error, reason)}
  end
end

def handle_event("confirm_refund", _params, socket) do
  action = socket.assigns.pending_refund

  if is_nil(action) do
    {:noreply, push_flash(socket, :warning, Copy.charge_prepare_refund_warning())}
  else
    case StepUp.require_fresh(socket, step_up_action(action), &execute_refund(&1, action)) do
      {:ok, socket} -> {:noreply, socket}
      {:challenge, socket} -> {:noreply, socket}
      {:error, reason, socket} -> {:noreply, push_flash(socket, :error, inspect(reason))}
    end
  end
end
```

**Operator UI shape** (lines 176-243):
```elixir
<article class="ax-card">
  <header class="ax-page-header">
    <p class="ax-eyebrow">Refund</p>
    <h3 class="ax-heading">Initiate a fee-aware refund</h3>
    <p class="ax-body">
      Leave the amount blank to refund the full charge. Existing fee fields surface after
      the refund is created.
    </p>
  </header>

  <form phx-submit="prepare_refund" class="ax-stack-xl" data-role="refund-form">
    ...
  </form>

  <section :if={@pending_refund} class="ax-card" data-role="confirm-panel">
    <p class="ax-label">Confirm refund</p>
    <p class="ax-body"><%= refund_copy(@pending_refund, @charge.currency) %></p>
    ...
  </section>
</article>

<div :for={refund <- @refunds} class="ax-list-row">
  <p class="ax-label"><%= refund.stripe_id || refund.id %></p>
  ...
</div>
```

**Execution + admin audit trail** (lines 378-445):
```elixir
defp execute_refund(socket, action) do
  result =
    with_admin_context(socket.assigns.current_admin, fn operation_id ->
      opts = refund_opts(action, socket.assigns.charge.currency, operation_id)
      Billing.create_refund(socket.assigns.charge, opts)
    end)

  case result do
    {:ok, %Refund{} = refund} ->
      socket
      |> record_admin_audit(action, refund.id)
      |> refresh_charge(socket.assigns.charge.id)
      |> push_flash(:info, Copy.charge_refund_created_info())

    {:error, reason} ->
      push_flash(socket, :error, inspect(reason))
  end
  |> assign(:pending_refund, nil)
end

defp record_admin_audit(socket, action, refund_id) do
  {:ok, _event} =
    Events.record(%{
      type: "admin.charge.refund.completed",
      subject_type: "Charge",
      subject_id: socket.assigns.charge.id,
      actor_type: "admin",
      actor_id: Auth.actor_id(socket.assigns.current_admin),
      caused_by_event_id: action.source_event_id,
      caused_by_webhook_event_id: action.source_webhook_event_id,
      data: %{"action_type" => "refund", "refund_id" => refund_id}
    })
end
```

**Use for Phase 99:** keep admin thin over `Accrue.Billing`. Change the actual call site to canonical `Billing.refund/2` once introduced, add Braintree eligibility/void copy here, and keep step-up plus audit intact.

---

### `accrue_admin/lib/accrue_admin/copy.ex` (utility, transform)

**Analog:** `accrue_admin/lib/accrue_admin/copy.ex`

**Existing refund copy hooks** (lines 409-412):
```elixir
def charge_prepare_refund_warning, do: "Prepare a refund before confirming."

def charge_refund_created_info,
  do: "Refund created with fee-aware fields from the billing facade."
```

**Step-up copy hooks** (lines 498-508):
```elixir
def step_up_eyebrow, do: "Sensitive action"
def step_up_title, do: "Step-up required"
def step_up_default_challenge_message, do: "Confirm your identity to continue."
def step_up_cancel_label, do: "Cancel"
```

**Use for Phase 99:** add narrow copy functions here for Braintree-only refund eligibility, void-vs-refund warning, pending-settlement honesty, and confirmation text. Keep string ownership centralized in `Copy`, not inline in LiveView.

---

### `accrue/test/accrue/billing/refund_braintree_test.exs` (test, CRUD)

**Analogs:** `accrue/test/accrue/billing/refund_test.exs`, `accrue/test/accrue/billing/payment_method_crud_braintree_test.exs`

**BillingCase + local projection setup** from `refund_test.exs` (lines 8-39):
```elixir
use Accrue.BillingCase, async: false

alias Accrue.Billing
alias Accrue.Billing.{Charge, Customer, Refund}

setup do
  {:ok, customer} =
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_fake_refund_test",
      email: "refund@example.com"
    })
    |> Repo.insert()

  {:ok, charge} =
    %Charge{}
    |> Charge.changeset(%{
      customer_id: customer.id,
      processor: "fake",
      processor_id: "ch_fake_refund_src",
      amount_cents: 10_000,
      currency: "usd",
      status: "succeeded"
    })
    |> Repo.insert()

  %{customer: customer, charge: charge}
end
```

**Assertion style** from `refund_test.exs` (lines 98-116, 145-163):
```elixir
assert {:ok, %Refund{} = refund} =
         Billing.create_refund(charge, amount: Accrue.Money.new(5000, :usd))

assert refund.amount_minor == 5000

result = Billing.create_refund(charge)
assert match?({:ok, %Refund{}}, result)
refute match?({:ok, :pending_fees, _}, result)
```

**Braintree processor stub pattern** from `payment_method_crud_braintree_test.exs` (lines 7-42, 158-182):
```elixir
defmodule BraintreeCRUDStub do
  use Agent
  ...
  def processor_name, do: "braintree"
  def capabilities do
    %{
      customer: %{create: true, retrieve: true, update: true},
      payment_method: %{...},
      subscription: %{direct_create: true, fetch: true, cancel: true, update: true},
      invoice: %{lifecycle_webhook_projection: true},
      webhook: %{verify: true, parse: true}
    }
  end
end

setup do
  previous = Application.get_env(:accrue, :processor)
  Application.put_env(:accrue, :processor, BraintreeCRUDStub)
  ...
  {:ok, customer} = %Customer{} |> Customer.changeset(%{processor: "braintree", ...}) |> Repo.insert()
  %{customer: customer}
end
```

**Use for Phase 99:** combine these two patterns. Keep the test in `BillingCase`, swap the processor to a Braintree stub, seed a `processor: "braintree"` charge, and assert canonical `Billing.refund/2` behavior plus `create_refund/2` compatibility delegation.

---

### `accrue/test/accrue/webhook/braintree_refund_convergence_test.exs` (test, event-driven)

**Analog:** `accrue/test/accrue/webhook/default_handler_phase3_test.exs`

**Test module shape** (lines 1-12):
```elixir
defmodule Accrue.Webhook.DefaultHandlerPhase3Test do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Charge, Invoice, PaymentMethod, Refund}
  alias Accrue.Webhook.DefaultHandler
```

**Refund upsert proof pattern** (lines 112-142):
```elixir
test "charge.refund.updated upserts refund row even when no local row exists", %{customer: cus} do
  {:ok, stripe_ch} =
    Fake.create_charge(
      %{amount: 10_000, currency: "usd", customer: cus.processor_id},
      []
    )

  {:ok, _} =
    %Charge{customer_id: cus.id, processor: "fake"}
    |> Charge.changeset(%{
      processor_id: stripe_ch.id,
      amount_cents: 10_000,
      currency: "usd",
      status: "succeeded"
    })
    |> Repo.insert()

  {:ok, stripe_refund} = Fake.create_refund(%{charge: stripe_ch.id, amount: 10_000}, [])

  event =
    StripeFixtures.webhook_event(
      "charge.refund.updated",
      StripeFixtures.refund(%{"id" => stripe_refund.id, "charge" => stripe_ch.id})
    )

  assert {:ok, ref} = DefaultHandler.handle(event)
  assert %Refund{} = ref
  assert ref.stripe_id == stripe_refund.id
end
```

**Use for Phase 99:** keep the same proof lane: seed parent projection, synthesize provider event/fetch state, run `DefaultHandler.handle/1`, and assert deferred/upsert/stale behavior explicitly.

---

### `accrue/test/accrue/billing/invoice_projection_braintree_refund_test.exs` (test, transform)

**Analog:** `accrue/test/accrue/billing/invoice_projection_test.exs`

**Test module + assertion style** (lines 13-17, 217-279):
```elixir
use ExUnit.Case, async: true

alias Accrue.Billing.InvoiceProjection

describe "decompose/1 (Braintree shape)" do
  test "decomposes braintree subscription transactions into an invoice and single line item" do
    braintree_sub = %{
      "id" => "sub_12345",
      "plan_id" => "basic_plan",
      "transactions" => [
        %{
          "id" => "tx_abcde",
          "status" => "settled",
          "amount" => 15.00,
          "tax_amount" => 1.50,
          "currency_iso_code" => "USD",
          "created_at" => now_unix
        }
      ]
    }

    {:ok, %{invoice_attrs: attrs, item_attrs: items}} = InvoiceProjection.decompose(braintree_sub)

    assert attrs.processor_id == "tx_abcde"
    assert attrs.status == :paid
    assert attrs.amount_due_minor == 0
    assert attrs.amount_paid_minor == 1500
    assert item.description == "Braintree subscription sub_12345"
  end
end
```

**Use for Phase 99:** extend this exact assertion style to derived refund rollups while keeping sale-truth assertions primary: invoice status/amounts should still reflect the sale projection, with refund summary proven separately.

---

### `accrue_admin/test/accrue_admin/live/charge_live_test.exs` (test, event-driven)

**Analog:** `accrue_admin/test/accrue_admin/live/charge_live_test.exs`

**Auth + step-up harness** (lines 13-38):
```elixir
defmodule AuthAdapter do
  @behaviour Accrue.Auth

  def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
  def current_user(_session), do: nil
  def require_admin_plug, do: fn conn, _opts -> conn end
  def user_schema, do: nil
  def log_audit(_user, _event), do: :ok
  def actor_id(user), do: user[:id]
  def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify refund"}
  def verify_step_up(_user, %{"code" => "123456"}, _action), do: :ok
end
```

**Seed-data pattern** (lines 40-87, 257-269):
```elixir
setup do
  ...
  charge =
    insert_charge(customer, subscription, %{
      processor: "fake",
      processor_id: "ch_detail",
      status: "succeeded",
      amount_cents: 10_000,
      stripe_fee_amount_minor: 300,
      fees_settled_at: DateTime.utc_now(),
      data: %{
        "application_fee_amount" => 200,
        "balance_transaction" => %{"net" => 9_700}
      }
    })

  insert_refund(charge, %{stripe_id: "re_seeded_...", amount_minor: 2_500, ...})
  {:ok, source_event} = Events.record(%{type: "charge.succeeded", subject_type: "Charge", subject_id: charge.id, actor_type: "system"})
  {:ok, charge: charge, source_event: source_event}
end
```

**Operator-flow proof pattern** (lines 104-154):
```elixir
{:ok, view, _html} = live(conn, "/billing/charges/#{charge.id}")

html =
  render_submit(
    element(view, "[data-role='refund-form']"),
    %{
      "amount_minor" => "4000",
      "reason" => "requested_by_customer",
      "source_event_id" => Integer.to_string(source_event.id)
    }
  )

assert html =~ "Confirm refund"

html = render_click(element(view, "[data-role='confirm-refund']"))
assert html =~ "Step-up required"

html =
  render_submit(element(view, "form[phx-submit='step_up_submit']"), %{"code" => "123456"})

assert html =~ Copy.charge_refund_created_info()
```

**Use for Phase 99:** extend this file, do not create a new LiveView test. Keep end-to-end operator assertions: eligibility copy, confirmation text, step-up, flash, audit event, and updated charge/refund projection.

## Shared Patterns

### Public Billing Boundary
**Source:** `accrue/lib/accrue/billing.ex:539-549`
**Apply to:** `billing.ex`, `charge_live.ex`
```elixir
span_billing(:refund, :create, charge, opts, fn ->
  RefundActions.create_refund(charge, opts)
end)
```

### Idempotent Money-Moving Writes
**Source:** `accrue/lib/accrue/billing/refund_actions.ex:70-97`
**Apply to:** `refund_actions.ex`, any admin-triggered refund mutation
```elixir
op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
subject_uuid = Idempotency.subject_uuid(:create_refund, op_id)
idem_key = Idempotency.key(:create_refund, subject_uuid, op_id)

Repo.transact(fn ->
  with {:ok, stripe_refund} <- Processor.__impl__().create_refund(...),
       {:ok, refund_row} <- insert_or_fetch_refund(...),
       {:ok, _} <- record_event("refund.created", refund_row, ...) do
    {:ok, refund_row}
  end
end)
```

### Additive Brownfield Schema Evolution
**Source:** `accrue/priv/repo/migrations/20260414120000_phase3_schema_upgrades.exs:12-15,122-156`
**Apply to:** new refunds migration, `refund.ex`
```elixir
# All changes are additive. Existing rows survive unchanged.
add :stripe_id, :string, null: true
...
create unique_index(:accrue_refunds, [:stripe_id],
  where: "stripe_id IS NOT NULL",
  name: :accrue_refunds_stripe_id_index
)
```

### Projection-First Fetch Convergence
**Source:** `accrue/lib/accrue/webhook/default_handler.ex:762-877,959-985`
**Apply to:** `default_handler.ex`, Braintree reconcile path
```elixir
with {:ok, canonical} <- Processor.__impl__().fetch(:refund, stripe_id),
     {:ok, upsert_result} <- upsert_refund(row, canonical, evt_ts, evt_id) do
  ...
end

case check_stale(row, evt_ts) do
  :stale -> {:ok, :stale}
  :ok -> fun.(row)
end
```

### Typed Fail-Clearly Validation
**Source:** `accrue/lib/accrue/billing/subscription_actions.ex:228-257,263-314,326-346`
**Apply to:** `subscription_actions.ex`, `processor/braintree.ex`, `charge_live.ex`
```elixir
@swap_schema [...]

{:error,
 %Accrue.APIError{
   code: "processor_operation_unsupported",
   http_status: 422,
   message: ...
 }}
```

### Thin Admin Shell + Step-Up + Audit
**Source:** `accrue_admin/lib/accrue_admin/live/charge_live.ex:59-69,378-445`
**Apply to:** `charge_live.ex`, `charge_live_test.exs`
```elixir
case StepUp.require_fresh(socket, step_up_action(action), &execute_refund(&1, action)) do
  {:ok, socket} -> {:noreply, socket}
  {:challenge, socket} -> {:noreply, socket}
end

Events.record(%{
  type: "admin.charge.refund.completed",
  subject_type: "Charge",
  subject_id: socket.assigns.charge.id,
  actor_type: "admin",
  actor_id: Auth.actor_id(socket.assigns.current_admin),
  data: %{"action_type" => "refund", "refund_id" => refund_id}
})
```

### Centralized UI Copy
**Source:** `accrue_admin/lib/accrue_admin/copy.ex:409-412,498-508`
**Apply to:** `copy.ex`, `charge_live.ex`
```elixir
def charge_prepare_refund_warning, do: "Prepare a refund before confirming."
def charge_refund_created_info, do: "Refund created with fee-aware fields from the billing facade."
def step_up_title, do: "Step-up required"
```

## No Analog Found

None. Every planned file has at least a role-match analog in the current codebase.

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue_admin/lib/accrue_admin`, `accrue/test/accrue`, `accrue_admin/test/accrue_admin`, `accrue/priv/repo/migrations`
**Files scanned:** 18 focused analog files/ranges
**Pattern extraction date:** 2026-04-30
