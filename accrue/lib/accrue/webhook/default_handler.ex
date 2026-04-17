defmodule Accrue.Webhook.DefaultHandler do
  @moduledoc """
  Non-disableable default handler for built-in state reconciliation
  (D2-30, WH-07, WH-09, WH-10).

  Runs first in the dispatch chain before any user-registered handlers.
  Cannot be removed or reordered by configuration.

  ## Phase 3 scope (Plan 07)

  Extends the Phase 2 customer skeleton with the full Phase 3 event
  family covering subscription, invoice, charge, refund, and payment
  method reconcilation. Each reducer:

    1. Derives `evt_ts` from the raw event `created` unix timestamp.
    2. Loads the local row by processor id.
    3. **Skip-stale (WH-09):** if `row.last_stripe_event_ts != nil`
       and `evt_ts` is strictly less than it, emit
       `[:accrue, :webhooks, :stale_event]` telemetry and return
       `{:ok, :stale}` **without** calling the processor. Ties
       (`:eq`) proceed per D3-49.
    4. **Refetch canonical (WH-10):** always call
       `Accrue.Processor.fetch/2` to pull the current object —
       never trust the payload snapshot.
    5. Project via the appropriate `*Projection.decompose/1` (or
       schema-specific upsert) and write via the webhook-path
       changeset (`Invoice.force_status_changeset/2` where a legal
       transition bypass is required).
    6. Stamp `last_stripe_event_ts` / `last_stripe_event_id` on the
       row so the next out-of-order event can skip.
    7. Record an `accrue_events` row in the same `Repo.transact/1`.

  ## Entry points

    * `handle/1` — accepts the raw event map (both string- and
      atom-keyed shapes). Used by `Accrue.Processor.Fake.synthesize_event/3`
      for in-process test dispatch.
    * `handle_event/3` — the `Accrue.Webhook.Handler` behaviour entry
      point invoked by `Accrue.Webhook.DispatchWorker`. Dispatches
      via the existing `%Accrue.Webhook.Event{}` struct (object_id +
      created_at + type) to the shared reducer.
  """

  use Accrue.Webhook.Handler

  require Logger

  alias Accrue.{Events, Processor, Repo}

  alias Accrue.Billing.{
    Charge,
    Customer,
    Invoice,
    InvoiceItem,
    InvoiceProjection,
    PaymentMethod,
    Refund,
    Subscription,
    SubscriptionItem,
    SubscriptionProjection,
    SubscriptionSchedule,
    SubscriptionScheduleProjection
  }

  # ---------------------------------------------------------------------
  # Phase 2 customer path (preserved)
  # ---------------------------------------------------------------------

  def handle_event("customer.created", event, _ctx) do
    Logger.debug("DefaultHandler: customer.created for #{event.object_id}")
    :ok
  end

  def handle_event("customer.updated", event, _ctx) do
    Logger.debug("DefaultHandler: customer.updated for #{event.object_id}")
    :ok
  end

  def handle_event("customer.deleted", event, _ctx) do
    Logger.debug("DefaultHandler: customer.deleted for #{event.object_id}")
    :ok
  end

  # ---------------------------------------------------------------------
  # Phase 3 event families — dispatch from Accrue.Webhook.Event struct
  # ---------------------------------------------------------------------

  def handle_event(type, %Accrue.Webhook.Event{object_id: nil}, _ctx) when is_binary(type) do
    # WR-10: Guard against nil object_id — the downstream reducer would
    # call Processor.fetch/2 with nil and crash in the Stripe adapter
    # with FunctionClauseError. Emit telemetry and short-circuit.
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

  # ---------------------------------------------------------------------
  # `handle/1` — raw event map entry point (Fake.synthesize_event path)
  # ---------------------------------------------------------------------

  @doc """
  Reduces a raw event map (atom- or string-keyed) through the Phase 3
  reducer chain. Returns `{:ok, row}` on success, `{:ok, :stale}` if
  the event is older than `row.last_stripe_event_ts`, or `{:ok, :ignored}`
  if the type is not a Phase 3 family.
  """
  @spec handle(map()) :: {:ok, struct() | :stale | :ignored} | {:error, term()}
  def handle(event) when is_map(event) do
    type = get(event, :type)
    evt_id = get(event, :id)
    created = get(event, :created)
    obj = get(event, :data) |> get(:object) || %{}

    evt_ts =
      case created do
        n when is_integer(n) -> DateTime.from_unix!(n)
        %DateTime{} = dt -> dt
        _ -> nil
      end

    dispatch(type, evt_id, evt_ts, obj)
  end

  def handle(_), do: {:ok, :ignored}

  # ---------------------------------------------------------------------
  # Dispatch — one clause per Phase 3 event family
  # ---------------------------------------------------------------------

  defp dispatch("customer.subscription." <> action, evt_id, evt_ts, obj)
       when action in ~w(created updated trial_will_end deleted paused resumed) do
    result = reduce_subscription(action, evt_id, evt_ts, obj)
    maybe_dispatch_subscription_email(action, result, obj)
    result
  end

  defp dispatch("subscription_schedule." <> action, evt_id, evt_ts, obj)
       when action in ~w(created updated released completed canceled expiring) do
    reduce_subscription_schedule(action, evt_id, evt_ts, obj)
  end

  defp dispatch("invoice." <> action, evt_id, evt_ts, obj)
       when action in ~w(created updated finalized finalization_failed paid payment_failed voided marked_uncollectible sent) do
    result = reduce_invoice(action, evt_id, evt_ts, obj)
    maybe_dispatch_invoice_email(action, result, obj)
    result
  end

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

  defp dispatch("charge." <> action, evt_id, evt_ts, obj)
       when action in ~w(succeeded failed updated refunded) do
    result = reduce_charge(action, evt_id, evt_ts, obj)
    maybe_dispatch_charge_email(action, result, obj)
    result
  end

  defp dispatch("payment_method." <> action, evt_id, evt_ts, obj)
       when action in ~w(attached detached updated card_automatically_updated) do
    reduce_payment_method(action, evt_id, evt_ts, obj)
  end

  # Phase 4 Plan 07 — Checkout session lifecycle (CHKT-06).
  defp dispatch("checkout.session." <> action, evt_id, evt_ts, obj)
       when action in ~w(completed expired async_payment_succeeded async_payment_failed) do
    reduce_checkout_session(action, evt_id, evt_ts, obj)
  end

  # Phase 4 Plan 02 — metered billing error report (BILL-13, Pitfall 5).
  defp dispatch("v1.billing.meter.error_report_triggered", evt_id, _evt_ts, obj) do
    reduce_meter_error_report(evt_id, obj)
  end

  defp dispatch("billing.meter.error_report_triggered", evt_id, _evt_ts, obj) do
    reduce_meter_error_report(evt_id, obj)
  end

  defp dispatch(_type, _evt_id, _evt_ts, _obj), do: {:ok, :ignored}

  # ---------------------------------------------------------------------
  # Checkout session reducer (Phase 4 Plan 07, CHKT-06)
  # ---------------------------------------------------------------------

  defp reduce_checkout_session(action, evt_id, _evt_ts, obj) do
    Repo.transact(fn ->
      session_id = get(obj, :id)
      customer_stripe_id = get(obj, :customer)
      subscription_stripe_id = get(obj, :subscription)

      with :ok <- maybe_link_subscription(action, customer_stripe_id, subscription_stripe_id),
           {:ok, _} <-
             record_event(
               "checkout.session." <> action,
               "CheckoutSession",
               session_id || "unknown",
               evt_id
             ) do
        {:ok, %{session_id: session_id, action: action}}
      else
        {:deferred, reason} ->
          :telemetry.execute(
            [:accrue, :webhooks, :orphan_checkout_session],
            %{},
            %{
              session_id: session_id,
              customer_stripe_id: customer_stripe_id,
              reason: reason
            }
          )

          {:ok, :deferred}

        {:error, _} = err ->
          err
      end
    end)
  end

  defp maybe_link_subscription("completed", customer_stripe_id, subscription_stripe_id)
       when is_binary(customer_stripe_id) and is_binary(subscription_stripe_id) do
    case Repo.get_by(Customer, processor_id: customer_stripe_id) do
      %Customer{} = customer ->
        case Processor.__impl__().fetch(:subscription, subscription_stripe_id) do
          {:ok, canonical} ->
            link_subscription_to_customer(customer, canonical, subscription_stripe_id)

          {:error, _} ->
            {:deferred, :subscription_fetch_failed}
        end

      _ ->
        {:deferred, :unknown_customer}
    end
  end

  defp maybe_link_subscription(_action, _customer_id, _sub_id), do: :ok

  defp link_subscription_to_customer(customer, canonical, sub_id) do
    {:ok, attrs} = SubscriptionProjection.decompose(canonical)

    case Repo.get_by(Subscription, processor_id: sub_id) do
      nil ->
        %Subscription{customer_id: customer.id, processor: processor_name()}
        |> Subscription.force_status_changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, _} -> :ok
          {:error, _} = err -> err
        end

      %Subscription{} = existing ->
        existing
        |> Subscription.force_status_changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, _} -> :ok
          {:error, _} = err -> err
        end
    end
  end

  # ---------------------------------------------------------------------
  # Meter error report reducer (Phase 4 Plan 02, BILL-13)
  # ---------------------------------------------------------------------

  defp reduce_meter_error_report(evt_id, obj) do
    identifier = extract_meter_identifier(obj)

    case Accrue.Billing.MeterEvents.mark_failed_by_identifier(identifier, obj) do
      {:ok, row} ->
        :telemetry.execute(
          [:accrue, :ops, :meter_reporting_failed],
          %{count: 1},
          %{
            meter_event_id: row.id,
            event_name: row.event_name,
            source: :webhook,
            webhook_event_id: evt_id
          }
        )

        {:ok, row}

      {:error, :not_found} ->
        Logger.warning(
          "meter error report for unknown identifier: #{inspect(identifier)} " <>
            "(event #{inspect(evt_id)})"
        )

        {:ok, :ignored}
    end
  end

  defp extract_meter_identifier(obj) do
    case get(obj, :identifier) do
      nil ->
        case get(obj, :reason) do
          %{} = reason -> get(reason, :identifier)
          _ -> nil
        end

      id when is_binary(id) ->
        id
    end
  end

  # ---------------------------------------------------------------------
  # Subscription reducer
  # ---------------------------------------------------------------------

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
                 :ok <- maybe_emit_dunning_exhaustion(row, updated),
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

  # Phase 4 Plan 04 — BILL-15 / D4-02. Emits terminal-action telemetry
  # when Stripe echoes a transition out of :past_due into :unpaid or
  # :canceled. Runs inside the enclosing Repo.transact/2 so the write
  # and the signal are atomic (idempotent under webhook replay because
  # dedup at the dispatch layer short-circuits before the reducer body).
  defp maybe_emit_dunning_exhaustion(nil, _updated), do: :ok

  defp maybe_emit_dunning_exhaustion(%Subscription{} = row, %Subscription{} = updated) do
    with true <- Subscription.dunning_sweepable?(row),
         to_status when not is_nil(to_status) <-
           Subscription.dunning_exhausted_status(updated) do
      :telemetry.execute(
        [:accrue, :ops, :dunning_exhaustion],
        %{count: 1},
        %{
          subscription_id: updated.id,
          from_status: :past_due,
          to_status: to_status,
          source: dunning_source(row.dunning_sweep_attempted_at)
        }
      )
    end

    :ok
  end

  defp dunning_source(nil), do: :stripe_native

  defp dunning_source(%DateTime{} = attempted_at) do
    if DateTime.diff(DateTime.utc_now(), attempted_at, :second) < 300 do
      :accrue_sweeper
    else
      :stripe_native
    end
  end

  defp subscription_event_type("trial_will_end"), do: "subscription.trial_ended"
  defp subscription_event_type(action), do: "subscription." <> action

  defp upsert_subscription(nil, canonical, attrs) do
    # CR-03: Tolerate webhook-first-for-unknown-customer. Return
    # :deferred so Oban doesn't retry-loop into DLQ — a later customer
    # event will create the row and a later subscription event will
    # project it.
    customer_stripe_id = get(canonical, :customer)

    case customer_stripe_id && Repo.get_by(Customer, processor_id: customer_stripe_id) do
      %Customer{} = customer ->
        %Subscription{customer_id: customer.id, processor: processor_name()}
        |> Subscription.changeset(attrs)
        |> Repo.insert()

      _ ->
        :telemetry.execute(
          [:accrue, :webhooks, :orphan_subscription],
          %{},
          %{customer_stripe_id: customer_stripe_id}
        )

        {:ok, :deferred}
    end
  end

  defp upsert_subscription(row, _canonical, attrs) do
    row
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  defp upsert_subscription_items(%Subscription{} = sub, canonical) do
    items =
      canonical
      |> SubscriptionProjection.get(:items)
      |> case do
        nil -> []
        %{} = m -> SubscriptionProjection.get(m, :data) || []
        list when is_list(list) -> list
      end

    # WR-09: reduce_while + non-bang variants.
    Enum.reduce_while(items, {:ok, []}, fn si, {:ok, acc} ->
      case upsert_subscription_item(sub, si) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp upsert_subscription_item(sub, si) when is_map(si) do
    stripe_id = SubscriptionProjection.get(si, :id)
    price = SubscriptionProjection.get(si, :price) || %{}

    price_id =
      case price do
        s when is_binary(s) -> s
        %{} = m -> SubscriptionProjection.get(m, :id)
        _ -> nil
      end

    attrs = %{
      subscription_id: sub.id,
      processor: processor_name(),
      processor_id: stripe_id,
      price_id: price_id,
      processor_plan_id: price_id,
      processor_product_id: SubscriptionProjection.get(price, :product),
      quantity: SubscriptionProjection.get(si, :quantity) || 1
    }

    import Ecto.Query, only: [from: 2]

    case Repo.one(from(i in SubscriptionItem, where: i.processor_id == ^stripe_id)) do
      nil -> %SubscriptionItem{} |> SubscriptionItem.changeset(attrs) |> Repo.insert()
      existing -> existing |> SubscriptionItem.changeset(attrs) |> Repo.update()
    end
  end

  # ---------------------------------------------------------------------
  # SubscriptionSchedule reducer (Phase 4 Plan 03, BILL-16)
  # ---------------------------------------------------------------------

  defp reduce_subscription_schedule(action, evt_id, evt_ts, obj) do
    stripe_id = get(obj, :id)

    reduce_row(:subscription_schedule, stripe_id, evt_ts, evt_id, fn row ->
      with {:ok, canonical} <-
             Processor.__impl__().subscription_schedule_fetch(stripe_id),
           {:ok, attrs} <- SubscriptionScheduleProjection.decompose(canonical),
           attrs <- stamp_watermark(attrs, evt_ts, evt_id),
           {:ok, upsert_result} <- upsert_subscription_schedule(row, canonical, attrs) do
        case upsert_result do
          :deferred ->
            {:ok, :deferred}

          %SubscriptionSchedule{} = updated ->
            with {:ok, _} <-
                   record_event(
                     schedule_event_type(action),
                     "SubscriptionSchedule",
                     updated.id,
                     evt_id
                   ) do
              {:ok, updated}
            end
        end
      end
    end)
  end

  defp schedule_event_type(action), do: "subscription_schedule." <> action

  defp upsert_subscription_schedule(nil, canonical, attrs) do
    # CR-03: Tolerate webhook-first-for-unknown-customer (Pitfall 4). A
    # subscription_schedule.updated can legitimately arrive before the
    # .created event when Stripe reorders deliveries — return :deferred
    # so Oban doesn't retry-loop into DLQ.
    customer_stripe_id = get(canonical, :customer)

    case customer_stripe_id && Repo.get_by(Customer, processor_id: customer_stripe_id) do
      %Customer{} = customer ->
        %SubscriptionSchedule{customer_id: customer.id, processor: processor_name()}
        |> SubscriptionSchedule.force_status_changeset(attrs)
        |> Repo.insert()

      _ ->
        :telemetry.execute(
          [:accrue, :webhooks, :orphan_subscription_schedule],
          %{},
          %{customer_stripe_id: customer_stripe_id}
        )

        {:ok, :deferred}
    end
  end

  defp upsert_subscription_schedule(row, _canonical, attrs) do
    row
    |> SubscriptionSchedule.force_status_changeset(attrs)
    |> Repo.update()
  end

  # ---------------------------------------------------------------------
  # Invoice reducer
  # ---------------------------------------------------------------------

  defp reduce_invoice(action, evt_id, evt_ts, obj) do
    stripe_id = get(obj, :id)

    reduce_row(:invoice, stripe_id, evt_ts, evt_id, fn row ->
      with {:ok, canonical} <- Processor.__impl__().fetch(:invoice, stripe_id),
           {:ok, %{invoice_attrs: attrs, item_attrs: item_attrs}} <-
             InvoiceProjection.decompose(canonical),
           attrs <- stamp_watermark(attrs, evt_ts, evt_id),
           {:ok, upsert_result} <- upsert_invoice(row, canonical, attrs) do
        case upsert_result do
          :deferred ->
            {:ok, :deferred}

          %Invoice{} = updated ->
            with {:ok, _} <- upsert_invoice_items(updated, item_attrs),
                 :ok <- maybe_bump_past_due_since(action, canonical),
                 {:ok, _} <- record_event("invoice." <> action, "Invoice", updated.id, evt_id) do
              {:ok, updated}
            end
        end
      end
    end)
  end

  # Phase 4 Plan 04 — BILL-15 / D4-02. On invoice.payment_failed, bump
  # the linked subscription's past_due_since from Stripe's
  # next_payment_attempt so the grace window is measured from Stripe's
  # last retry attempt. Never clears past_due_since (a nil attempt
  # means Stripe has stopped retrying — the grace window still runs).
  defp maybe_bump_past_due_since("payment_failed", canonical) do
    with sub_stripe_id when is_binary(sub_stripe_id) <- get(canonical, :subscription),
         %Subscription{} = sub <- Repo.get_by(Subscription, processor_id: sub_stripe_id),
         attempt_unix when is_integer(attempt_unix) <- get(canonical, :next_payment_attempt) do
      past_due_since =
        attempt_unix
        |> DateTime.from_unix!()
        |> Map.put(:microsecond, {0, 6})

      case sub
           |> Subscription.force_status_changeset(%{past_due_since: past_due_since})
           |> Repo.update() do
        {:ok, _} -> :ok
        {:error, _} = err -> err
      end
    else
      _ -> :ok
    end
  end

  defp maybe_bump_past_due_since(_action, _canonical), do: :ok

  defp upsert_invoice(nil, canonical, attrs) do
    # CR-03: Tolerate webhook-first-for-unknown-customer.
    customer_stripe_id = get(canonical, :customer)

    case customer_stripe_id && Repo.get_by(Customer, processor_id: customer_stripe_id) do
      %Customer{} = customer ->
        %Invoice{customer_id: customer.id, processor: processor_name()}
        |> Invoice.force_status_changeset(attrs)
        |> Repo.insert()

      _ ->
        :telemetry.execute(
          [:accrue, :webhooks, :orphan_invoice],
          %{},
          %{customer_stripe_id: customer_stripe_id}
        )

        {:ok, :deferred}
    end
  end

  defp upsert_invoice(row, _canonical, attrs) do
    row
    |> Invoice.force_status_changeset(attrs)
    |> Repo.update()
  end

  defp upsert_invoice_items(%Invoice{} = invoice, item_attrs_list)
       when is_list(item_attrs_list) do
    import Ecto.Query, only: [from: 2]

    # WR-09: reduce_while + non-bang variants so changeset errors
    # propagate rather than escaping Repo.transact via
    # Ecto.InvalidChangesetError.
    Enum.reduce_while(item_attrs_list, {:ok, []}, fn attrs, {:ok, acc} ->
      attrs = Map.put(attrs, :invoice_id, invoice.id)

      result =
        case attrs[:stripe_id] do
          nil ->
            %InvoiceItem{} |> InvoiceItem.changeset(attrs) |> Repo.insert()

          sid when is_binary(sid) ->
            case Repo.one(from(i in InvoiceItem, where: i.stripe_id == ^sid)) do
              nil -> %InvoiceItem{} |> InvoiceItem.changeset(attrs) |> Repo.insert()
              existing -> existing |> InvoiceItem.changeset(attrs) |> Repo.update()
            end
        end

      case result do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  # ---------------------------------------------------------------------
  # Charge reducer
  # ---------------------------------------------------------------------

  defp reduce_charge(action, evt_id, evt_ts, obj) do
    stripe_id = get(obj, :id)

    reduce_row(:charge, stripe_id, evt_ts, evt_id, fn row ->
      with {:ok, canonical} <- Processor.__impl__().fetch(:charge, stripe_id),
           {:ok, upsert_result} <- upsert_charge(row, canonical, evt_ts, evt_id) do
        case upsert_result do
          :deferred ->
            {:ok, :deferred}

          %Charge{} = updated ->
            with {:ok, _} <- record_event("charge." <> action, "Charge", updated.id, evt_id) do
              {:ok, updated}
            end
        end
      end
    end)
  end

  defp upsert_charge(row, canonical, evt_ts, evt_id) do
    bt = SubscriptionProjection.get(canonical, :balance_transaction) || %{}
    fee = SubscriptionProjection.get(bt, :fee)
    fee_currency = SubscriptionProjection.get(bt, :currency) || "usd"
    status = canonical |> SubscriptionProjection.get(:status) |> to_string_or_nil()

    attrs = %{
      stripe_fee_amount_minor: fee,
      stripe_fee_currency: fee_currency,
      fees_settled_at: if(is_integer(fee), do: Accrue.Clock.utc_now(), else: nil),
      status: status,
      last_stripe_event_ts: evt_ts,
      last_stripe_event_id: evt_id
    }

    case row do
      nil ->
        # CR-03: Tolerate webhook-first-for-unknown-customer — return
        # :deferred rather than raise Ecto.NoResultsError inside the
        # enclosing Repo.transact.
        customer_stripe_id = SubscriptionProjection.get(canonical, :customer)

        case customer_stripe_id && Repo.get_by(Customer, processor_id: customer_stripe_id) do
          %Customer{} = customer ->
            %Charge{customer_id: customer.id, processor: processor_name()}
            |> Charge.changeset(
              Map.merge(attrs, %{
                processor_id: SubscriptionProjection.get(canonical, :id),
                amount_cents: SubscriptionProjection.get(canonical, :amount),
                currency: SubscriptionProjection.get(canonical, :currency) || "usd"
              })
            )
            |> Repo.insert()

          _ ->
            :telemetry.execute(
              [:accrue, :webhooks, :orphan_charge],
              %{},
              %{customer_stripe_id: customer_stripe_id}
            )

            {:ok, :deferred}
        end

      existing ->
        existing
        |> Charge.changeset(attrs)
        |> Repo.update()
    end
  end

  # ---------------------------------------------------------------------
  # Refund reducer
  # ---------------------------------------------------------------------

  defp reduce_refund(action, evt_id, evt_ts, obj) do
    stripe_id = get(obj, :id)

    reduce_row(:refund, stripe_id, evt_ts, evt_id, fn row ->
      with {:ok, canonical} <- Processor.__impl__().fetch(:refund, stripe_id),
           {:ok, upsert_result} <- upsert_refund(row, canonical, evt_ts, evt_id) do
        case upsert_result do
          # CR-03: parent charge not yet projected locally — skip event
          # recording and let a later event refetch canonical state.
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

  defp refund_event_type(updated, _action) do
    if Refund.fees_settled?(updated), do: "refund.fees_settled", else: "refund.updated"
  end

  defp upsert_refund(row, canonical, evt_ts, evt_id) do
    charge_ref = SubscriptionProjection.get(canonical, :charge)

    {charge_stripe_id, charge_bt} =
      case charge_ref do
        s when is_binary(s) ->
          {s, SubscriptionProjection.get(canonical, :balance_transaction) || %{}}

        %{} = nested ->
          {SubscriptionProjection.get(nested, :id),
           SubscriptionProjection.get(nested, :balance_transaction) ||
             SubscriptionProjection.get(canonical, :balance_transaction) || %{}}

        _ ->
          {nil, SubscriptionProjection.get(canonical, :balance_transaction) || %{}}
      end

    fee = SubscriptionProjection.get(charge_bt, :fee)
    fee_refunded = SubscriptionProjection.get(charge_bt, :fee_refunded)

    {stripe_fee_refunded, merchant_loss, settled_at} =
      case {fee, fee_refunded} do
        {f, fr} when is_integer(f) and is_integer(fr) ->
          # WR-03: Clamp merchant_loss at 0 — fee_refunded can exceed
          # fee in fee-adjustment scenarios, which would otherwise
          # violate the (migration-enforced) non-negative invariant.
          {fr, max(0, f - fr), Accrue.Clock.utc_now()}

        _ ->
          {nil, nil, nil}
      end

    status_atom =
      case SubscriptionProjection.get(canonical, :status) do
        nil ->
          :pending

        a when is_atom(a) ->
          a

        s when is_binary(s) ->
          try do
            String.to_existing_atom(s)
          rescue
            ArgumentError -> :pending
          end
      end

    attrs = %{
      stripe_fee_refunded_amount_minor: stripe_fee_refunded,
      merchant_loss_amount_minor: merchant_loss,
      fees_settled_at: settled_at,
      status: status_atom,
      last_stripe_event_ts: evt_ts,
      last_stripe_event_id: evt_id
    }

    case row do
      nil ->
        # CR-03: Out-of-order `charge.refund.updated` can arrive before
        # the parent charge has been projected locally (D3-50). Rather
        # than crash with Ecto.NoResultsError inside Repo.transact and
        # let Oban retry-loop into DLQ, tolerate the missing parent:
        # emit telemetry and return :deferred so the enclosing reducer
        # commits cleanly. The refund will be picked up on the next
        # event (which refetches canonical state).
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
              %{
                refund_stripe_id: SubscriptionProjection.get(canonical, :id),
                charge_stripe_id: charge_stripe_id
              }
            )

            {:ok, :deferred}
        end

      existing ->
        existing
        |> Refund.changeset(attrs)
        |> Repo.update()
    end
  end

  # ---------------------------------------------------------------------
  # Payment method reducer
  # ---------------------------------------------------------------------

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

  defp pm_event_type("attached"), do: "payment_method.attached"
  defp pm_event_type("detached"), do: "payment_method.detached"
  defp pm_event_type("updated"), do: "payment_method.updated"
  defp pm_event_type("card_automatically_updated"), do: "payment_method.auto_updated"

  defp upsert_payment_method(row, canonical, evt_ts, evt_id) do
    card = SubscriptionProjection.get(canonical, :card) || %{}

    attrs = %{
      fingerprint: SubscriptionProjection.get(card, :fingerprint),
      exp_month: SubscriptionProjection.get(card, :exp_month),
      exp_year: SubscriptionProjection.get(card, :exp_year),
      card_exp_month: SubscriptionProjection.get(card, :exp_month),
      card_exp_year: SubscriptionProjection.get(card, :exp_year),
      card_brand: SubscriptionProjection.get(card, :brand),
      card_last4: SubscriptionProjection.get(card, :last4),
      last_stripe_event_ts: evt_ts,
      last_stripe_event_id: evt_id
    }

    case row do
      nil ->
        customer_stripe_id = SubscriptionProjection.get(canonical, :customer)

        customer_id =
          case customer_stripe_id do
            nil ->
              nil

            sid ->
              case Repo.get_by(Customer, processor_id: sid) do
                nil -> nil
                c -> c.id
              end
          end

        %PaymentMethod{customer_id: customer_id, processor: processor_name()}
        |> PaymentMethod.changeset(
          Map.merge(attrs, %{
            processor_id: SubscriptionProjection.get(canonical, :id),
            type: SubscriptionProjection.get(canonical, :type) || "card"
          })
        )
        |> Repo.insert()

      existing ->
        existing
        |> PaymentMethod.changeset(attrs)
        |> Repo.update()
    end
  end

  # ---------------------------------------------------------------------
  # Skip-stale gate + shared reduce_row wrapper
  # ---------------------------------------------------------------------

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

  defp check_stale(nil, _evt_ts), do: :ok
  defp check_stale(%{last_stripe_event_ts: nil}, _evt_ts), do: :ok
  defp check_stale(_row, nil), do: :ok

  defp check_stale(%{last_stripe_event_ts: last}, evt_ts) do
    case DateTime.compare(evt_ts, last) do
      :lt -> :stale
      _ -> :ok
    end
  end

  defp load_row(:subscription, id), do: Repo.get_by(Subscription, processor_id: id)

  defp load_row(:subscription_schedule, id),
    do: Repo.get_by(SubscriptionSchedule, processor_id: id)

  defp load_row(:invoice, id), do: Repo.get_by(Invoice, processor_id: id)
  defp load_row(:charge, id), do: Repo.get_by(Charge, processor_id: id)
  defp load_row(:refund, id), do: Repo.get_by(Refund, stripe_id: id)
  defp load_row(:payment_method, id), do: Repo.get_by(PaymentMethod, processor_id: id)

  defp stamp_watermark(attrs, evt_ts, evt_id) do
    Map.merge(attrs, %{last_stripe_event_ts: evt_ts, last_stripe_event_id: evt_id})
  end

  defp record_event(type, subject_type, subject_id, stripe_event_id)
       when is_binary(type) and is_binary(subject_type) do
    Events.record(%{
      type: type,
      subject_type: subject_type,
      subject_id: subject_id,
      data: %{source: "webhook", stripe_event_id: stripe_event_id}
    })
  end

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  # Dual atom/string key lookup — handles both Fake (atom) and Stripe
  # (string) shapes without forcing callers to normalize.
  defp get(%{} = map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp get(_, _), do: nil

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(v) when is_atom(v), do: Atom.to_string(v)
  defp to_string_or_nil(v) when is_binary(v), do: v
  defp to_string_or_nil(_), do: nil

  # ---------------------------------------------------------------------
  # Plan 06-07: Mailer dispatch after state reconciliation (Pitfall 7)
  #
  # Reducers are the SINGLE dispatch point for state-change emails in
  # the Email Type Catalogue. Action modules (Billing.*) do NOT call
  # `Accrue.Mailer.deliver/2` for these types — the single exceptions
  # are `:card_expiring_soon` (cron in Accrue.Jobs.DetectExpiringCards)
  # and `:coupon_applied` (Accrue.Billing.CouponActions). This file
  # dispatches everything else.
  #
  # Dispatch happens OUTSIDE the Repo.transact/1 wrapper so a rollback
  # never enqueues a ghost email. Scalar-only assigns (IDs + URLs) per
  # D-27 / Plan 06-04 `only_scalars!/1`.
  # ---------------------------------------------------------------------

  defp maybe_dispatch_charge_email("succeeded", {:ok, %Charge{} = charge}, obj) do
    customer_id = charge_customer_id(charge, obj)
    do_dispatch(:receipt, charge.id, customer_id, obj)
  end

  defp maybe_dispatch_charge_email("failed", {:ok, %Charge{} = charge}, obj) do
    customer_id = charge_customer_id(charge, obj)
    do_dispatch(:payment_failed, charge.id, customer_id, obj)
  end

  defp maybe_dispatch_charge_email("refunded", {:ok, %Charge{} = charge}, obj) do
    customer_id = charge_customer_id(charge, obj)
    do_dispatch(:refund_issued, charge.id, customer_id, obj)
  end

  defp maybe_dispatch_charge_email(_action, _result, _obj), do: :ok

  defp maybe_dispatch_refund_email({:ok, %Refund{} = refund}, obj) do
    charge_id = get(obj, :charge)
    customer_id = refund_customer_id(refund)

    assigns = %{
      refund_id: refund.id,
      charge_id: charge_id_or_nil(charge_id),
      customer_id: customer_id
    }

    safe_deliver(:refund_issued, assigns)
  end

  defp maybe_dispatch_refund_email(_result, _obj), do: :ok

  defp maybe_dispatch_invoice_email("finalized", {:ok, %Invoice{} = invoice}, obj) do
    do_dispatch_invoice(:invoice_finalized, invoice, obj)
  end

  defp maybe_dispatch_invoice_email("paid", {:ok, %Invoice{} = invoice}, obj) do
    do_dispatch_invoice(:invoice_paid, invoice, obj)
  end

  defp maybe_dispatch_invoice_email("payment_failed", {:ok, %Invoice{} = invoice}, obj) do
    do_dispatch_invoice(:invoice_payment_failed, invoice, obj)
  end

  defp maybe_dispatch_invoice_email(_action, _result, _obj), do: :ok

  defp do_dispatch_invoice(type, %Invoice{} = invoice, obj) do
    hosted_url = get(obj, :hosted_invoice_url)
    invoice_number = get(obj, :number)
    customer_id = invoice_customer_id(invoice)

    assigns =
      %{
        invoice_id: invoice.id,
        customer_id: customer_id,
        invoice_number: invoice_number,
        hosted_invoice_url: hosted_url
      }
      |> drop_nils()

    safe_deliver(type, assigns)
  end

  defp maybe_dispatch_subscription_email("trial_will_end", {:ok, %Subscription{} = sub}, _obj) do
    safe_deliver(:trial_ending, %{
      subscription_id: sub.id,
      customer_id: sub.customer_id
    })
  end

  defp maybe_dispatch_subscription_email("deleted", {:ok, %Subscription{} = sub}, _obj) do
    safe_deliver(:subscription_canceled, %{
      subscription_id: sub.id,
      customer_id: sub.customer_id
    })
  end

  defp maybe_dispatch_subscription_email("updated", {:ok, %Subscription{} = sub}, obj) do
    # pause_collection set ⇒ :subscription_paused
    # pause_collection cleared (nil) + status resumed from paused ⇒ :subscription_resumed
    case get(obj, :pause_collection) do
      %{} ->
        safe_deliver(:subscription_paused, %{
          subscription_id: sub.id,
          customer_id: sub.customer_id
        })

      nil ->
        if Subscription.active?(sub) do
          safe_deliver(:subscription_resumed, %{
            subscription_id: sub.id,
            customer_id: sub.customer_id
          })
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp maybe_dispatch_subscription_email(_action, _result, _obj), do: :ok

  # ---------------------------------------------------------------------
  # Dispatch helpers
  # ---------------------------------------------------------------------

  defp do_dispatch(type, subject_id_key, customer_id, _obj) do
    assigns =
      %{
        type_subject_id(type) => subject_id_key,
        customer_id: customer_id
      }
      |> drop_nils()

    safe_deliver(type, assigns)
  end

  defp type_subject_id(:receipt), do: :charge_id
  defp type_subject_id(:payment_failed), do: :charge_id
  defp type_subject_id(:refund_issued), do: :charge_id

  # Wraps the mailer deliver in a try/rescue so dispatch failures don't
  # rollback state reconciliation. Emits telemetry per T-06-07-08.
  defp safe_deliver(type, assigns) do
    Accrue.Mailer.deliver(type, assigns)
  rescue
    e ->
      :telemetry.execute(
        [:accrue, :mailer, :dispatch_failed],
        %{count: 1},
        %{type: type, reason: inspect(e)}
      )

      :ok
  catch
    kind, reason ->
      :telemetry.execute(
        [:accrue, :mailer, :dispatch_failed],
        %{count: 1},
        %{type: type, reason: inspect({kind, reason})}
      )

      :ok
  end

  defp drop_nils(map) when is_map(map) do
    for {k, v} <- map, not is_nil(v), into: %{}, do: {k, v}
  end

  defp charge_id_or_nil(id) when is_binary(id), do: id
  defp charge_id_or_nil(_), do: nil

  defp charge_customer_id(%Charge{customer_id: cid}, _obj) when not is_nil(cid), do: cid
  defp charge_customer_id(_charge, obj), do: get(obj, :customer)

  defp invoice_customer_id(%Invoice{customer_id: cid}) when not is_nil(cid), do: cid
  defp invoice_customer_id(_), do: nil

  defp refund_customer_id(%Refund{charge_id: charge_id}) when is_binary(charge_id) do
    case Repo.get(Charge, charge_id) do
      %Charge{customer_id: cid} -> cid
      _ -> nil
    end
  end

  defp refund_customer_id(_), do: nil
end
