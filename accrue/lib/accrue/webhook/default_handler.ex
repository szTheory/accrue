defmodule Accrue.Webhook.DefaultHandler do
  @moduledoc """
  Non-disableable default handler for built-in state reconciliation.

  Runs first in the dispatch chain before any user-registered handlers.
  Cannot be removed or reordered by configuration.

  ## Behaviour

  Reconciles Stripe webhook families covering subscription, invoice, charge,
  refund, and payment method state. Each reducer:

    1. Derives `evt_ts` from the raw event `created` unix timestamp.
    2. Loads the local row by processor id.
    3. **Skip stale:** if `row.last_stripe_event_ts != nil`
       and `evt_ts` is strictly less than it, emit
       `[:accrue, :webhooks, :stale_event]` telemetry and return
       `{:ok, :stale}` **without** calling the processor. Timestamp ties
       (`:eq`) still proceed.
    4. **Refetch canonical:** always call
       `Accrue.Processor.fetch/2` to pull the current object —
       never trust the payload snapshot alone.
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
    EntitlementSummary,
    Invoice,
    InvoiceItem,
    InvoiceProjection,
    MeteredRenewalActions,
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

  def handle_event("billing.meter.error_report_triggered", %Accrue.Webhook.Event{} = event, ctx) do
    obj = meter_error_object_from_ctx(ctx)

    {:ok, _} = reduce_meter_error_report(event.processor_event_id, obj)
    :ok
  end

  def handle_event(
        "accrue.portal.checkout.completed",
        %Accrue.Webhook.Event{} = event,
        ctx
      ) do
    obj = portal_checkout_object_from_ctx(ctx, event)

    case dispatch(event.type, event.processor_event_id, event.created_at, obj) do
      {:ok, _} -> :ok
      other -> other
    end
  end

  def handle_event(
        "v1.billing.meter.error_report_triggered",
        %Accrue.Webhook.Event{} = event,
        ctx
      ) do
    obj = meter_error_object_from_ctx(ctx)

    {:ok, _} = reduce_meter_error_report(event.processor_event_id, obj)
    :ok
  end

  # Phase 127 — ENT-10 optional Stripe-native entitlement-summary sync.
  #
  # The `entitlements.active_entitlement_summary` object has NO top-level
  # `id`, so `Accrue.Webhook.Event.from_webhook_event/1` derives
  # `object_id: nil`. Without this dedicated clause the event would fall
  # through to the generic `object_id: nil` short-circuit below and never
  # reach `dispatch/4` — the reducer would be unreachable on the real
  # `DispatchWorker` path even with `stripe_native_sync: :advisory` enabled.
  # Mirror the meter-error/portal pattern: pull the full object out of `ctx`
  # (DispatchWorker stows `data.data.object` there) and dispatch explicitly.
  # The config gate still runs first inside `dispatch/4`.
  def handle_event(
        "entitlements.active_entitlement_summary.updated",
        %Accrue.Webhook.Event{} = event,
        ctx
      ) do
    obj = entitlement_summary_object_from_ctx(ctx)

    case dispatch(event.type, event.processor_event_id, event.created_at, obj, event.processor) do
      {:ok, _} -> :ok
      other -> other
    end
  end

  # ---------------------------------------------------------------------
  # Phase 3 event families — dispatch from Accrue.Webhook.Event struct
  # ---------------------------------------------------------------------

  def handle_event(type, %Accrue.Webhook.Event{processor: :braintree, object_id: nil}, _ctx)
      when is_binary(type) do
    :telemetry.execute([:accrue, :webhooks, :missing_object_id], %{}, %{
      type: type,
      processor: :braintree
    })

    :ok
  end

  def handle_event(type, %Accrue.Webhook.Event{processor: :braintree} = event, _ctx)
      when is_binary(type) do
    case normalize_braintree_type(type) do
      {:ok, normalized_type} ->
        with {:ok, _} <-
               maybe_open_braintree_metered_renewal(
                 type,
                 event.object_id,
                 event.created_at,
                 event.processor_event_id
               ),
             result <-
               dispatch(normalized_type, event.processor_event_id, event.created_at, %{
                 "id" => event.object_id
               }) do
          case result do
            {:ok, _} -> :ok
            other -> other
          end
        end

      :ignored ->
        :ok
    end
  end

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
  Reduces a raw event map (atom- or string-keyed) through the built-in
  reducer chain. Returns `{:ok, row}` on success, `{:ok, :stale}` if
  the event is older than `row.last_stripe_event_ts`, or `{:ok, :ignored}`
  if the type has no dedicated reducer.
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
    # POST-COMMIT (D-12): the reducer transaction has now committed; run the
    # cancel-on-recovery bulk cancel OUTSIDE any Repo.transact. Only fire on
    # a committed success — a rolled-back reducer means the anchor-clear was
    # undone, so the stale stash must be discarded WITHOUT cancelling.
    run_post_commit_dunning_cancel(result)
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

  defp dispatch("accrue.portal.checkout.completed", evt_id, evt_ts, obj) do
    reduce_portal_checkout_completed(evt_id, evt_ts, obj)
  end

  # Phase 4 Plan 02 — metered billing error report (BILL-13, Pitfall 5).
  defp dispatch("v1.billing.meter.error_report_triggered", evt_id, _evt_ts, obj) do
    reduce_meter_error_report(evt_id, obj)
  end

  defp dispatch("billing.meter.error_report_triggered", evt_id, _evt_ts, obj) do
    reduce_meter_error_report(evt_id, obj)
  end

  # Phase 127 — ENT-10 optional Stripe-native entitlement-summary sync.
  #
  # OFF by default (D-04 layer 1): the runtime gate is checked FIRST and
  # the off lane early-returns `{:ok, :ignored}` BEFORE any `Repo` call,
  # so a host that has not opted into `stripe_native_sync: :advisory`
  # behaves byte-for-byte as Phase 126 — the cache table is never read or
  # written from the webhook path.
  defp dispatch("entitlements.active_entitlement_summary.updated", evt_id, evt_ts, obj) do
    # Fallback for handle/1 (raw event map path, implies Stripe)
    dispatch("entitlements.active_entitlement_summary.updated", evt_id, evt_ts, obj, :stripe)
  end

  defp dispatch(_type, _evt_id, _evt_ts, _obj), do: {:ok, :ignored}

  defp dispatch("entitlements.active_entitlement_summary.updated", evt_id, evt_ts, obj, processor) do
    if Accrue.Config.stripe_native_sync?() do
      reduce_entitlement_summary(evt_id, evt_ts, obj, processor)
    else
      {:ok, :ignored}
    end
  end

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

  defp reduce_portal_checkout_completed(evt_id, evt_ts, obj) do
    Repo.transact(fn ->
      session_id = get(obj, :id) || get(obj, :checkout_session_id)
      customer_processor_id = get(obj, :customer)
      subscription_processor_id = get(obj, :subscription)

      with :ok <-
             maybe_link_subscription(
               "completed",
               customer_processor_id,
               subscription_processor_id
             ),
           {:ok, _} <-
             record_event(
               "checkout.session.completed",
               "CheckoutSession",
               session_id || "unknown",
               evt_id,
               idempotency_key: "portal-checkout-completed:" <> evt_id
             ) do
        :telemetry.execute(
          [:accrue, :portal, :checkout, :completed],
          %{count: 1},
          %{
            checkout_session_id: session_id,
            customer_id: get(obj, :customer_id),
            subscription_id: get(obj, :subscription_id),
            customer_processor_id: customer_processor_id,
            subscription_processor_id: subscription_processor_id,
            processor: :braintree,
            source: :default_handler,
            event_timestamp: evt_ts
          }
        )

        {:ok, %{session_id: session_id, action: "completed"}}
      else
        {:deferred, reason} ->
          :telemetry.execute(
            [:accrue, :webhooks, :orphan_checkout_session],
            %{},
            %{
              session_id: session_id,
              customer_stripe_id: customer_processor_id,
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

    case Accrue.Billing.MeterEvents.mark_failed_by_identifier(identifier, obj, evt_id) do
      {:ok, row} ->
        {:ok, row}

      {:error, :not_found} ->
        Logger.warning(
          "meter error report for unknown identifier: #{inspect(identifier)} " <>
            "(event #{inspect(evt_id)})"
        )

        {:ok, :ignored}
    end
  end

  # ---------------------------------------------------------------------
  # Entitlement-summary reducer (Phase 127 Plan 02, ENT-10)
  #
  # Monotonic-snapshot, NOT refetch-canonical. The Connect reducer
  # (`Accrue.Webhook.ConnectHandler`) refetches canonical state from the
  # Stripe API on every event to immunize itself against out-of-order
  # delivery. That option is unavailable here: `lattice_stripe` 1.1 ships
  # no Entitlements list API (verified — typed reads land in
  # `lattice_stripe >= 1.2`), so there is nothing to refetch. Instead this
  # reducer trusts the full-snapshot summary payload and enforces ordering
  # the same way the subscription/invoice/charge reducers do — via
  # `check_stale/2` keyed on the event `created` watermark (D-06). A
  # strictly-older event (`:lt`) is skipped; `:eq`/`:gt` proceed. The
  # result is the same monotonic guarantee without an API round-trip.
  #
  # The cache is **observational-only** (D-01): it is written, ledgered,
  # telemetered, and exposed via a read-only seam, but the gate path
  # (`Accrue.entitled?/2`, `has_active_plan?/2`, `Resolver`, `LocalMap`)
  # NEVER reads it. Truncation (`has_more` → `truncated`) is recorded for
  # operator honesty (D-07) but can never affect a grant decision.
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

  defp reduce_entitlement_summary_for_customer(
         evt_id,
         evt_ts,
         obj,
         cus_id,
         entitlements,
         data,
         processor
       ) do
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
              write_entitlement_summary(
                evt_id,
                evt_ts,
                obj,
                cus_id,
                customer,
                row,
                entitlements,
                data
              )
          end

        _ ->
          # Out-of-order delivery: the summary can arrive before the
          # customer.created event. Tolerate it (clone of orphan_charge,
          # :840-848) — never raise, never create a customer.
          :telemetry.execute(
            [:accrue, :webhooks, :orphan_entitlement_summary],
            %{},
            %{customer_stripe_id: cus_id}
          )

          {:ok, :deferred}
      end
    end)
  end

  defp write_entitlement_summary(evt_id, evt_ts, obj, cus_id, customer, row, entitlements, data) do
    has_more = get(entitlements, :has_more) == true
    entitlement_count = length(data)
    new_pairs = entitlement_pairs(data)

    # D-08: on-change-only ledger. The set is the sorted {feature_id,
    # lookup_key} pairs; a first-ever write (no prior row) is material;
    # otherwise material iff the pairs OR the truncated flag changed. A
    # byte-identical re-delivery is NOT material — it is observable via the
    # `result: :unchanged` telemetry but writes no ledger row.
    material? = summary_material_change?(row, new_pairs, has_more)

    attrs =
      %{
        customer_id: customer.id,
        stripe_customer_id: cus_id,
        processor: processor_name(),
        livemode: get(obj, :livemode),
        entitlement_count: entitlement_count,
        truncated: has_more,
        synced_at: synced_at_from_event(evt_ts),
        data: obj
      }
      |> stamp_summary_watermark(evt_ts, evt_id, row)

    metadata = %{
      customer_id: customer.id,
      has_more: has_more,
      entitlement_count: entitlement_count
    }

    Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fn ->
      with {:ok, saved} <- upsert_entitlement_summary(row, attrs),
           {:ok, _} <- maybe_record_summary_event(material?, saved, evt_id) do
        :telemetry.execute(
          [:accrue, :entitlements, :summary_synced],
          %{count: 1, entitlement_count: entitlement_count},
          Map.put(metadata, :result, if(material?, do: :written, else: :unchanged))
        )

        if has_more do
          Accrue.Telemetry.Ops.emit(
            :entitlement_summary_truncated,
            %{count: 1},
            %{customer_id: customer.id}
          )
        end

        {:ok, saved}
      end
    end)
  end

  # D-08: ledger row ONLY on material change. The ledger `data` carries
  # IDs/counts only (via record_event/5's fixed {source, stripe_event_id}
  # shape) — NEVER the raw summary payload (V7). The idempotency key
  # collapses Oban retries of the same Stripe event via the partial unique
  # index on accrue_events.idempotency_key.
  defp maybe_record_summary_event(false, _saved, _evt_id), do: {:ok, :unchanged}

  defp maybe_record_summary_event(true, %EntitlementSummary{} = saved, evt_id) do
    record_event(
      "entitlements.summary.synced",
      "EntitlementSummary",
      saved.id,
      evt_id,
      idempotency_key: "entitlements.summary.synced:" <> evt_id
    )
  end

  # First-ever write is always material. Otherwise material iff the sorted
  # {feature_id, lookup_key} pair set OR the truncated flag differs from
  # the persisted row.
  defp summary_material_change?(nil, _new_pairs, _has_more), do: true

  defp summary_material_change?(%EntitlementSummary{} = row, new_pairs, has_more) do
    existing = get(row.data || %{}, :entitlements) |> get(:data)
    new_pairs != entitlement_pairs(existing) or (row.truncated || false) != has_more
  end

  # Sorted list of {feature_id, lookup_key} pairs from an entitlements
  # data list, tolerant of nil / non-list / missing keys.
  defp entitlement_pairs(data) when is_list(data) do
    data
    |> Enum.map(fn ent -> {get(ent, :feature), get(ent, :lookup_key)} end)
    |> Enum.sort()
  end

  defp entitlement_pairs(_), do: []

  defp upsert_entitlement_summary(_row, attrs) do
    import Ecto.Query

    # WR-05: move from optimistic_lock with Repo.update to a DB-level atomic
    # upsert. This prevents Ecto.StaleEntryError during concurrent deliveries
    # for the same customer. The on_conflict_where clause enforces the
    # skip-stale watermark at the DB level (D-06).
    %EntitlementSummary{}
    |> EntitlementSummary.force_changeset(attrs)
    |> Repo.insert(
      returning: true,
      conflict_target: :customer_id,
      on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]},
      on_conflict_where:
        from(e in EntitlementSummary,
          where: e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
        )
    )
  end

  defp synced_at_from_event(%DateTime{} = evt_ts), do: evt_ts
  defp synced_at_from_event(_), do: Accrue.Clock.utc_now()

  # WR-02 (D-06 monotonicity): never let a nil/missing event timestamp
  # clobber an existing watermark. A null `last_stripe_event_ts` re-opens the
  # stale gate (`check_stale/2` treats nil as "always proceed"), so a
  # timestamp-less event could wipe a newer snapshot's watermark and let a
  # later older event overwrite it. Stamp only on a real `%DateTime{}`;
  # otherwise carry the prior row's watermark forward (or leave unset on the
  # first-ever write). Scoped to the summary reducer — the shared
  # `stamp_watermark/3` keeps its existing behaviour for other reducers.
  defp stamp_summary_watermark(attrs, %DateTime{} = evt_ts, evt_id, _row),
    do: stamp_watermark(attrs, evt_ts, evt_id)

  defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, nil), do: attrs

  defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, %EntitlementSummary{} = row) do
    Map.merge(attrs, %{
      last_stripe_event_ts: row.last_stripe_event_ts,
      last_stripe_event_id: row.last_stripe_event_id
    })
  end

  defp emit_summary_malformed(evt_id, reason) do
    :telemetry.execute(
      [:accrue, :webhooks, :malformed_entitlement_summary],
      %{},
      %{event_id: evt_id, reason: reason}
    )
  end

  defp meter_error_object_from_ctx(ctx) when is_map(ctx) do
    Map.get(ctx, :meter_error_object) ||
      Map.get(ctx, "meter_error_object") ||
      %{}
  end

  # Phase 127 — the full summary object is needed (customer, entitlements.data,
  # has_more, livemode) and is NOT recoverable from the lean event struct.
  # DispatchWorker stows the raw `data.data.object` under `:meter_error_object`
  # for every event type, so reuse it (preferring a dedicated key if a future
  # caller supplies one).
  defp entitlement_summary_object_from_ctx(ctx) when is_map(ctx) do
    Map.get(ctx, :entitlement_summary_object) ||
      Map.get(ctx, "entitlement_summary_object") ||
      Map.get(ctx, :meter_error_object) ||
      Map.get(ctx, "meter_error_object") ||
      %{}
  end

  defp portal_checkout_object_from_ctx(ctx, event) when is_map(ctx) do
    Map.get(ctx, :portal_checkout_object) ||
      Map.get(ctx, "portal_checkout_object") ||
      %{"id" => event.object_id}
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

  # Phase 4 Plan 04 — BILL-15 / D4-02. Emits terminal-action telemetry
  # when Stripe echoes a transition out of :past_due into :unpaid or
  # :canceled. Runs inside the enclosing Repo.transact/2 so the write
  # and the signal are atomic (idempotent under webhook replay because
  # dedup at the dispatch layer short-circuits before the reducer body).
  defp maybe_emit_dunning_exhaustion(nil, _updated, _canonical), do: :ok

  defp maybe_emit_dunning_exhaustion(%Subscription{} = row, %Subscription{} = updated, canonical) do
    with true <- Subscription.dunning_sweepable?(row),
         to_status when not is_nil(to_status) <-
           Subscription.dunning_exhausted_status(updated) do
      source = dunning_source(row.dunning_sweep_attempted_at)
      mrr_value_cents = calculate_mrr_cents(canonical)
      currency = get(canonical, :currency) || "usd"

      # DAN-02 forward-fix (Phase 144 Plan 02): snapshot the campaign anchor onto
      # the event payload so the DAN-01 funnel can DISTINCT-tuple by
      # (subject_id, campaign_anchor) and avoid double-counting cycled dunning.
      # `row.dunning_campaign_started_at` may be `nil` when a past_due
      # subscription transitions to canceled/unpaid via a non-Accrue path
      # (Stripe-native dunning never sets the anchor) — `Subscription.dunning_sweepable?/1`
      # only checks `status: :past_due`. The defensive `case` prevents a
      # `KeyError` on bare `DateTime.to_iso8601(nil)`; the funnel's
      # COALESCE-to-sentinel folds nil-anchor exhaustions into the legacy bucket.
      iso_anchor =
        case row.dunning_campaign_started_at do
          %DateTime{} = dt -> DateTime.to_iso8601(dt)
          _ -> nil
        end

      :telemetry.execute(
        [:accrue, :ops, :dunning_exhaustion],
        %{count: 1},
        %{
          subscription_id: updated.id,
          from_status: :past_due,
          to_status: to_status,
          source: source
        }
      )

      # DUN-08 observability: `dunning.exhausted` is the SOLE canonical loss
      # signal (the recovered-vs-lost counter folds over it — Plan 02). It
      # fires ONLY on this confirmed transition, covering all loss sources;
      # the sweeper's request-time `dunning.terminal_action_requested` is left
      # untouched and excluded so loss can never be double-counted (T-129-04).
      # The ledger write runs inside the reducer's enclosing Repo.transact, so
      # it is atomic with the status write. Data + metadata carry only IDs +
      # bounded enums — no PII (T-129-01).
      Events.record(%{
        type: "dunning.exhausted",
        subject_type: "Subscription",
        subject_id: updated.id,
        data: %{
          to_status: to_status,
          source: source,
          mrr_value_cents: mrr_value_cents,
          currency: currency,
          campaign_anchor: iso_anchor
        }
      })

      Accrue.Telemetry.Ops.emit(:dunning_exhausted, %{count: 1}, %{
        subscription_id: updated.id,
        to_status: to_status,
        source: source
      })
    end

    :ok
  end

  # D-12 cancel-on-recovery — IN-TRANSACTION anchor-clear half (DUN-05).
  #
  # When the subscription was running a dunning campaign (`row` had a
  # non-nil anchor) and it has now recovered (`updated` is active/paid),
  # nil the anchor DURABLY: the `force_status_changeset` write runs inside
  # the reducer's enclosing `reduce_row -> Repo.transact`, so the
  # anchor-clear commits ATOMICALLY with the status write — there is no
  # window where the row is recovered but still carries a live anchor.
  #
  # The bulk `Oban.cancel_all_jobs` is NOT run here: Oban dispatches
  # against `conf.repo` and is not guaranteed to enlist in this
  # surrounding transaction connection (verified deps/oban/lib/oban.ex).
  # Instead we capture `iso_anchor` (the anchor value AT recovery, read
  # from `row` BEFORE the clear) and stash a post-commit cancel
  # instruction; the dispatch site runs the bulk cancel AFTER this
  # transaction commits. Post-commit is correct because the per-step
  # cancel-guard (Plan 05, D-11) self-cancels any step that races the
  # cancel — so a cancel failure can never leave a zombie campaign.
  #
  # DUN-08 observability (recovery edge only): on the `:past_due` → active/paid
  # recovery transition, a `dunning.recovered` ledger entry is folded into the
  # SAME multi as the anchor-clear write (atomic with the status write), and
  # `[:accrue, :ops, :dunning_recovered]` telemetry fires post-commit. The
  # terminal/exhaustion edge does NOT emit `dunning.recovered` — that loss
  # signal is the dedicated `dunning.exhausted` event in
  # `maybe_emit_dunning_exhaustion/2`. Metadata + data carry only IDs +
  # bounded enums — no PII (T-129-01).
  @dialyzer {:no_opaque, maybe_finalize_dunning_campaign: 3}
  defp maybe_finalize_dunning_campaign(nil, _updated, _canonical), do: :ok

  defp maybe_finalize_dunning_campaign(
         %Subscription{} = row,
         %Subscription{} = updated,
         canonical
       ) do
    # A campaign FINALIZES on EITHER edge out of the live (`:past_due`)
    # window: recovery (the sub is active/paid again) OR terminal exhaustion
    # (CR-02: the sub reached `:unpaid`/`:canceled` via the Accrue sweeper or
    # Stripe-native termination). In BOTH cases the still-set anchor must be
    # cleared and the scheduled steps proactively cancelled — otherwise an
    # in-flight `:action_required`/`:final_notice` step keeps firing to a
    # subscription that has left the dunning window. Previously only the
    # recovery edge was handled, so a terminal `:unpaid` transition left the
    # anchor live and the per-step guard as the sole backstop.
    with true <- Subscription.dunning_campaign_active?(row),
         true <- finalizing_transition?(updated),
         %DateTime{} = anchor <- row.dunning_campaign_started_at do
      iso_anchor = DateTime.to_iso8601(anchor)
      recovery? = Subscription.active?(updated)

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.update(
          :clear_anchor,
          Subscription.force_status_changeset(updated, %{dunning_campaign_started_at: nil})
        )

      multi =
        if recovery? do
          mrr_value_cents = calculate_mrr_cents(canonical)
          currency = get(canonical, :currency) || "usd"

          # Fold the `dunning.recovered` ledger record into the SAME
          # transaction as the anchor-clear (atomic with the status write).
          #
          # DAN-02 forward-fix (Phase 144 Plan 02): snapshot the anchor that is
          # about to be cleared onto the event payload, so the DAN-01 funnel
          # can DISTINCT-tuple by (subject_id, campaign_anchor). `iso_anchor`
          # is already in lexical scope from line 884 — the `with` clause
          # guarantees it is a non-nil ISO-8601 string at this point.
          Events.record_multi(multi, :dunning_recovered_event, %{
            type: "dunning.recovered",
            subject_type: "Subscription",
            subject_id: updated.id,
            data: %{
              source: dunning_source(row.dunning_sweep_attempted_at),
              mrr_value_cents: mrr_value_cents,
              currency: currency,
              campaign_anchor: iso_anchor
            }
          })
        else
          multi
        end

      case Repo.transaction(multi) do
        {:ok, _changes} ->
          # Stash the post-commit bulk-cancel instruction for the dispatch
          # site to run AFTER this transaction commits. Tightly scoped to
          # this synchronous webhook call; consumed-and-deleted once.
          Process.put(:accrue_dunning_cancel, {updated, iso_anchor})

          if recovery? do
            Accrue.Telemetry.Ops.emit(:dunning_recovered, %{count: 1}, %{
              subscription_id: updated.id,
              source: dunning_source(row.dunning_sweep_attempted_at)
            })
          end

          :ok

        {:error, _failed_op, reason, _changes} ->
          {:error, reason}
      end
    else
      _ -> :ok
    end
  end

  # A subscription leaves the dunning campaign on EITHER edge out of
  # `:past_due`: recovery (active/paid again) OR terminal exhaustion
  # (`:unpaid`/`:canceled`). `dunning_exhausted_status/1` returns a non-nil
  # status atom for the terminal edge.
  defp finalizing_transition?(%Subscription{} = updated) do
    Subscription.active?(updated) or
      not is_nil(Subscription.dunning_exhausted_status(updated))
  end

  # POST-COMMIT bulk cancel (D-12). Run by the dispatch site AFTER the
  # reducer transaction commits — NEVER inside any `Repo.transact`. Keyed
  # on `campaign_started_at` so a stale recovery for an old campaign cannot
  # cancel a fresh re-lapse campaign's steps (Pitfall 3). Wrapped so a
  # cancel error/raise does NOT propagate: the anchor-clear is already
  # committed and the per-step cancel-guard backstops any uncancelled step.
  defp run_post_commit_dunning_cancel({:ok, %Subscription{}}) do
    case Process.delete(:accrue_dunning_cancel) do
      {%Subscription{} = sub, iso_anchor} when is_binary(iso_anchor) ->
        Accrue.Config.dunning_engine().cancel_campaign(sub, iso_anchor, [])

      _ ->
        :ok
    end
  end

  # Reducer did not commit a subscription success (rolled back / deferred /
  # stale) — discard any stale stash WITHOUT cancelling. The anchor-clear,
  # if it ran, was rolled back with the transaction.
  defp run_post_commit_dunning_cancel(_result) do
    _ = Process.delete(:accrue_dunning_cancel)
    :ok
  end

  defp dunning_source(nil), do: :stripe_native

  defp dunning_source(%DateTime{} = attempted_at) do
    # WR-03: read the wall clock via Accrue.Clock for Fake-lane determinism
    # (Phase 130), consistent with every other clock read in this phase. A
    # direct DateTime.utc_now/0 made the exhaustion-telemetry `source` tag
    # non-deterministic under the Fake clock and could flap at the 300s boundary.
    if DateTime.diff(Accrue.Clock.utc_now(), attempted_at, :second) < 300 do
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

    # For Braintree, the payload's ID is the subscription ID. The most recent
    # transaction on that subscription will be projected as the invoice.
    fetch_type = if processor_name() == "braintree", do: :subscription, else: :invoice

    reduce_row(:invoice, stripe_id, evt_ts, evt_id, fn row ->
      with {:ok, canonical} <- Processor.__impl__().fetch(fetch_type, stripe_id),
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
         %Subscription{} = sub <- Repo.get_by(Subscription, processor_id: sub_stripe_id) do
      maybe_bump_attempt(sub, canonical)
      maybe_start_dunning_campaign(sub, canonical)
      :ok
    else
      _ -> :ok
    end
  end

  defp maybe_bump_past_due_since(_action, _canonical), do: :ok

  # Bump past_due_since from Stripe's next_payment_attempt (UNCHANGED from
  # the Phase 4 behaviour). Never clears it (nil attempt = Stripe stopped
  # retrying; the grace window still runs).
  defp maybe_bump_attempt(%Subscription{} = sub, canonical) do
    case get(canonical, :next_payment_attempt) do
      attempt_unix when is_integer(attempt_unix) ->
        past_due_since =
          attempt_unix
          |> DateTime.from_unix!()
          |> Map.put(:microsecond, {0, 6})

        sub
        |> Subscription.force_status_changeset(%{past_due_since: past_due_since})
        |> Repo.update()

      _ ->
        :ok
    end
  end

  # D-09 first-transition elector + day-0 enqueue (DUN-02, DUN-05).
  #
  # Race-safe campaign start: an atomic
  # `update_all WHERE is_nil(dunning_campaign_started_at)` is the ONLY
  # exactly-one-winner primitive under concurrent `invoice.payment_failed`
  # webhooks (Oban OSS `unique` is advisory-only — backstop, not the
  # elector). count==1 wins the first nil→past_due edge and enqueues the
  # day-0 `DunningStep`; count==0 means the campaign is already running
  # (a later failure in the same window) — no-op, no second start.
  #
  # This is a SIBLING `update_all`, NOT a `force_status_changeset`/
  # `optimistic_lock` write — it sets one column and never touches
  # `lock_version`, so it cannot contend with the status/past_due_since
  # changeset path above. Gated on `dunning_campaign_enabled?/0`: a host
  # that opted out never starts a campaign (the standalone email fires
  # instead via the D-15 gate).
  defp maybe_start_dunning_campaign(%Subscription{} = sub, canonical) do
    if Accrue.Config.dunning_campaign_enabled?() do
      import Ecto.Query, only: [from: 2]

      now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}

      {count, _} =
        from(s in Subscription, where: s.id == ^sub.id and is_nil(s.dunning_campaign_started_at))
        |> Repo.update_all(set: [dunning_campaign_started_at: now_usec])

      case count do
        1 ->
          emit_campaign_started(sub, canonical)
          opts = [invoice_id: get(canonical, :id)]
          Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)

        _ ->
          :ok
      end
    end

    :ok
  end

  # DUN-08 observability: the first nil→past_due elector winner records a
  # `dunning.campaign_started` ledger entry AND fires
  # `[:accrue, :ops, :dunning_campaign_started]` telemetry. This runs in the
  # campaign-start path, which is a standalone `update_all` (D-09), NOT inside
  # the reducer's Repo.transact — so we use the post-write `Events.record/1`.
  # `step_count` is the configured cadence length. There is NO `:source` key
  # for this event (a campaign start has no loss/recovery source). Metadata +
  # data carry only IDs + bounded values — no PII (T-129-01).
  defp emit_campaign_started(%Subscription{} = sub, canonical) do
    step_count = length(Accrue.Config.dunning_campaign_steps())

    Events.record(%{
      type: "dunning.campaign_started",
      subject_type: "Subscription",
      subject_id: sub.id,
      data: %{step_count: step_count, invoice_id: get(canonical, :id)}
    })

    Accrue.Telemetry.Ops.emit(:dunning_campaign_started, %{count: 1}, %{
      subscription_id: sub.id,
      step_count: step_count
    })

    :ok
  end

  # The day-0 step is the configured step at `after_days: 0`.
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

  defp load_row(:refund, id),
    do: Repo.get_by(Refund, processor_id: id) || Repo.get_by(Refund, stripe_id: id)

  defp load_row(:payment_method, id), do: Repo.get_by(PaymentMethod, processor_id: id)

  defp stamp_watermark(attrs, evt_ts, evt_id) do
    Map.merge(attrs, %{last_stripe_event_ts: evt_ts, last_stripe_event_id: evt_id})
  end

  defp record_event(type, subject_type, subject_id, stripe_event_id, opts \\ [])
       when is_binary(type) and is_binary(subject_type) do
    Events.record(%{
      type: type,
      subject_type: subject_type,
      subject_id: subject_id,
      data: %{source: "webhook", stripe_event_id: stripe_event_id},
      idempotency_key: Keyword.get(opts, :idempotency_key)
    })
  end

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp maybe_open_braintree_metered_renewal(type, object_id, evt_ts, evt_id)
       when type in ["subscription_charged_successfully", "subscription_went_active"] and
              is_binary(object_id) do
    MeteredRenewalActions.open_braintree_renewal_window(object_id, evt_ts, evt_id, type)
  end

  defp maybe_open_braintree_metered_renewal(_type, _object_id, _evt_ts, _evt_id),
    do: {:ok, :ignored}

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
    # D-15 REPLACE: when the campaign is ENABLED, campaign step-1 owns
    # day-0 — SKIP the standalone email so only one day-0 email is sent.
    # When DISABLED, the standalone fires (deduped at enqueue by Plan 04).
    if Accrue.Config.dunning_campaign_enabled?() do
      :ok
    else
      do_dispatch_invoice(:invoice_payment_failed, invoice, obj)
    end
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
  # rollback state reconciliation. Emits telemetry on dispatch failure.
  #
  # WR-05: a swallowed dunning email is a revenue event, so the telemetry now
  # carries enough to reconstruct WHICH email was dropped (subscription_id +
  # invoice_id from assigns, in addition to type). The `catch` is narrowed to
  # `:throw` only; an abnormal `exit` (e.g. DBConnection.OwnershipError,
  # `exit(:shutdown)`) is RE-RAISED rather than masked as a silent `:ok`,
  # since suppressing it would hide genuine infrastructure failures behind a
  # successful reconciliation.
  defp safe_deliver(type, assigns) do
    Accrue.Mailer.deliver(type, assigns)
  rescue
    e ->
      emit_dispatch_failed(type, assigns, inspect(e))
      :ok
  catch
    :throw, reason ->
      emit_dispatch_failed(type, assigns, inspect({:throw, reason}))
      :ok
  end

  defp emit_dispatch_failed(type, assigns, reason) do
    :telemetry.execute(
      [:accrue, :mailer, :dispatch_failed],
      %{count: 1},
      %{
        type: type,
        reason: reason,
        subscription_id: Map.get(assigns, :subscription_id),
        invoice_id: Map.get(assigns, :invoice_id)
      }
    )
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

  defp normalize_braintree_type("subscription_charged_successfully"), do: {:ok, "invoice.paid"}

  defp normalize_braintree_type("subscription_charged_unsuccessfully"),
    do: {:ok, "invoice.payment_failed"}

  defp normalize_braintree_type("subscription_canceled"),
    do: {:ok, "customer.subscription.deleted"}

  defp normalize_braintree_type("subscription_expired"),
    do: {:ok, "customer.subscription.deleted"}

  defp normalize_braintree_type("subscription_went_past_due"),
    do: {:ok, "customer.subscription.updated"}

  defp normalize_braintree_type("subscription_went_active"),
    do: {:ok, "customer.subscription.updated"}

  defp normalize_braintree_type("subscription_trial_ended"),
    do: {:ok, "customer.subscription.trial_will_end"}

  defp normalize_braintree_type(_), do: :ignored

  defp calculate_mrr_cents(canonical) do
    items = get(canonical, :items) || %{}
    data_list = get(items, :data) || []
    data_list = if is_list(data_list), do: data_list, else: []

    Enum.reduce(data_list, 0, fn item, acc ->
      quantity = get(item, :quantity) || 1
      plan = get(item, :plan) || %{}
      price = get(item, :price) || %{}

      amount = get(plan, :amount) || get(price, :unit_amount) || 0

      recurring = get(price, :recurring) || %{}
      interval = get(plan, :interval) || get(recurring, :interval) || "month"
      interval_count = get(plan, :interval_count) || get(recurring, :interval_count) || 1

      mrr_cents =
        case interval do
          "month" -> div(amount * quantity, interval_count)
          "year" -> div(amount * quantity, interval_count * 12)
          "week" -> div(amount * quantity * 52, interval_count * 12)
          "day" -> div(amount * quantity * 365, interval_count * 12)
          _ -> 0
        end

      acc + mrr_cents
    end)
  end
end
