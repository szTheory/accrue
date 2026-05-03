defmodule Accrue.Billing.MeteredRenewalActions do
  @moduledoc """
  Opens immutable metered renewal windows from canonical Braintree renewal evidence.
  """

  alias Accrue.Billing.{
    Invoice,
    MeterDefinitions,
    MeteredRenewal,
    MeteredRenewalInvoice,
    Subscription,
    SubscriptionProjection
  }

  alias Accrue.{Events, Processor, Repo}

  @processor "braintree"

  @spec open_braintree_renewal_window(
          String.t(),
          DateTime.t() | nil,
          String.t() | nil,
          String.t()
        ) ::
          {:ok, MeteredRenewal.t() | :ignored}
          | {:error, term()}
  def open_braintree_renewal_window(subscription_processor_id, evt_ts, evt_id, raw_type)
      when is_binary(subscription_processor_id) and is_binary(raw_type) do
    with %Subscription{} = subscription <-
           Repo.get_by(Subscription,
             processor: @processor,
             processor_id: subscription_processor_id
           ),
         {:ok, canonical} <- Processor.__impl__().fetch(:subscription, subscription_processor_id),
         {:ok, canonical_attrs} <-
           SubscriptionProjection.decompose(canonical, processor: :braintree),
         {:ok, renewal_attrs} <-
           renewal_attrs(subscription, canonical_attrs, evt_ts, evt_id, raw_type) do
      case renewal_attrs do
        :ignored -> {:ok, :ignored}
        attrs -> persist_renewal(subscription, attrs)
      end
    else
      nil -> {:ok, :ignored}
      {:ok, :ignored} -> {:ok, :ignored}
      other -> other
    end
  end

  @spec author_local_invoice(Ecto.UUID.t()) ::
          {:ok, %{invoice: Invoice.t(), renewal: MeteredRenewal.t()}} | {:error, term()}
  def author_local_invoice(metered_renewal_id) when is_binary(metered_renewal_id) do
    MeteredRenewalInvoice.author_invoice(metered_renewal_id)
  end

  @spec mark_invoice_authored(MeteredRenewal.t(), Invoice.t(), map()) ::
          {:ok, MeteredRenewal.t()} | {:error, term()}
  def mark_invoice_authored(%MeteredRenewal{} = renewal, %Invoice{} = invoice, attrs \\ %{})
      when is_map(attrs) do
    now = DateTime.utc_now()

    summary =
      attrs
      |> Map.new()
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> Map.put("invoice_id", invoice.id)
      |> Map.put("invoice_status", "authored")

    with {:ok, updated} <-
           renewal
           |> MeteredRenewal.changeset(%{
             invoice_id: invoice.id,
             invoice_status: "authored",
             invoice_authored_at: now,
             data: Map.merge(renewal.data || %{}, summary)
           })
           |> Repo.update(),
         {:ok, _event} <- record_invoice_authored_event(updated, invoice, attrs) do
      {:ok, updated}
    end
  end

  defp renewal_attrs(%Subscription{} = subscription, canonical_attrs, evt_ts, evt_id, raw_type) do
    local_start = subscription.current_period_start
    local_end = subscription.current_period_end
    next_start = canonical_attrs[:current_period_start]
    next_end = canonical_attrs[:current_period_end]

    cond do
      is_nil(local_start) or is_nil(local_end) or is_nil(next_start) or is_nil(next_end) ->
        {:ok, :ignored}

      evt_ts && DateTime.compare(evt_ts, local_end) == :lt ->
        {:ok, :ignored}

      DateTime.compare(next_start, local_end) == :lt ->
        {:ok, :ignored}

      DateTime.compare(next_end, local_end) != :gt ->
        {:ok, :ignored}

      true ->
        snapshot = build_snapshot(subscription)

        {:ok,
         %{
           subscription_id: subscription.id,
           customer_id: subscription.customer_id,
           processor: @processor,
           state: :pending,
           period_start: local_start,
           period_end: local_end,
           trigger_source: "braintree_webhook",
           snapshot: snapshot,
           last_processor_event_id: evt_id,
           last_processor_event_ts: evt_ts,
           data: %{
             "raw_event_type" => raw_type,
             "next_period_start" => maybe_iso8601(next_start),
             "next_period_end" => maybe_iso8601(next_end)
           }
         }}
    end
  end

  defp persist_renewal(%Subscription{} = subscription, attrs) do
    case Repo.transact(fn ->
           case Repo.get_by(MeteredRenewal,
                  subscription_id: subscription.id,
                  period_start: attrs.period_start,
                  period_end: attrs.period_end
                ) do
             %MeteredRenewal{} = existing ->
               {:ok, existing}

             nil ->
               with {:ok, renewal} <-
                      %MeteredRenewal{}
                      |> MeteredRenewal.changeset(attrs)
                      |> Repo.insert(),
                    {:ok, _event} <- record_opened_event(renewal, subscription, attrs),
                    {:ok, _job} <- enqueue_processing(renewal) do
                 {:ok, renewal}
               end
           end
         end) do
      {:ok, %MeteredRenewal{} = renewal} -> {:ok, renewal}
      {:ok, {:ok, %MeteredRenewal{} = renewal}} -> {:ok, renewal}
      {:ok, {:error, err}} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  defp build_snapshot(%Subscription{} = subscription) do
    definitions = MeterDefinitions.active_definitions_for_subscription(subscription.id)

    definition_snapshots =
      Enum.map(definitions, fn definition ->
        item = definition.subscription_item

        %{
          "meter_definition_id" => definition.id,
          "event_name" => definition.event_name,
          "subscription_item_id" => definition.subscription_item_id,
          "price_id" => definition.price_id,
          "processor_plan_id" => item && item.processor_plan_id,
          "aggregation_mode" => definition.aggregation_mode,
          "billing_snapshot" => definition.billing_snapshot
        }
      end)

    first = List.first(definition_snapshots) || %{}

    %{
      "subscription_id" => subscription.id,
      "subscription_processor_id" => subscription.processor_id,
      "subscription_item_id" => Map.get(first, "subscription_item_id"),
      "price_id" => Map.get(first, "price_id"),
      "processor_plan_id" => Map.get(first, "processor_plan_id"),
      "meter_definitions" => definition_snapshots
    }
  end

  defp record_opened_event(%MeteredRenewal{} = renewal, %Subscription{} = subscription, attrs) do
    Events.record(%{
      type: "metered_renewal.opened",
      subject_type: "MeteredRenewal",
      subject_id: renewal.id,
      data: %{
        source: "webhook",
        processor: @processor,
        subscription_id: subscription.id,
        subscription_processor_id: subscription.processor_id,
        period_start: maybe_iso8601(attrs.period_start),
        period_end: maybe_iso8601(attrs.period_end),
        processor_event_id: attrs.last_processor_event_id
      },
      idempotency_key:
        "metered-renewal-opened:" <>
          subscription.id <>
          ":" <> maybe_iso8601(attrs.period_start) <> ":" <> maybe_iso8601(attrs.period_end)
    })
  end

  defp record_invoice_authored_event(%MeteredRenewal{} = renewal, %Invoice{} = invoice, attrs) do
    Events.record(%{
      type: "metered_renewal.invoice_authored",
      subject_type: "MeteredRenewal",
      subject_id: renewal.id,
      data: %{
        source: "worker",
        processor: renewal.processor,
        invoice_id: invoice.id,
        invoice_processor_id: invoice.processor_id,
        matched_event_count: Map.get(attrs, :matched_event_count, 0),
        unmatched_event_count: Map.get(attrs, :unmatched_event_count, 0),
        unusable_event_count: Map.get(attrs, :unusable_event_count, 0)
      },
      idempotency_key: "metered-renewal-invoice-authored:" <> renewal.id
    })
  end

  defp enqueue_processing(%MeteredRenewal{} = renewal) do
    %{metered_renewal_id: renewal.id}
    |> Oban.Job.new(
      worker: "Accrue.Jobs.ProcessMeteredRenewal",
      queue: :accrue_meters,
      unique: [fields: [:worker, :args], keys: [:metered_renewal_id], period: 60]
    )
    |> Oban.insert()
  end

  defp maybe_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp maybe_iso8601(_), do: nil
end
