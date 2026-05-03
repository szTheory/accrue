defmodule Accrue.Billing.MeteredRenewalInvoice do
  @moduledoc """
  Authors one canonical local invoice for a closed metered renewal window.
  """

  import Ecto.Query

  alias Accrue.Billing.{
    Invoice,
    InvoiceItem,
    MeterEvent,
    MeteredRenewal,
    MeteredRenewalActions
  }

  alias Accrue.{Config, Repo}

  @authored_status "authored"

  @spec author_invoice(Ecto.UUID.t()) ::
          {:ok, %{invoice: Invoice.t(), renewal: MeteredRenewal.t()}} | {:error, term()}
  def author_invoice(metered_renewal_id) when is_binary(metered_renewal_id) do
    with %MeteredRenewal{} = renewal <- Repo.get(MeteredRenewal, metered_renewal_id) do
      case existing_invoice(renewal) do
        %Invoice{} = invoice ->
          {:ok, %{invoice: Repo.preload(invoice, :items), renewal: renewal}}

        nil ->
          do_author_invoice(renewal)
      end
    else
      nil -> {:error, :not_found}
    end
  end

  defp do_author_invoice(%MeteredRenewal{} = renewal) do
    definitions = definitions_from_snapshot(renewal.snapshot || %{})
    events = billable_events_for_renewal(renewal)
    classified = classify_events(events, definitions)
    grouped_matches = aggregate_matches(classified.matched)
    total_minor = Enum.reduce(grouped_matches, 0, fn match, acc -> acc + match.amount_minor end)

    Repo.transact(fn ->
      with {:ok, invoice} <- upsert_invoice(renewal, total_minor),
           {:ok, _items} <- upsert_items(invoice, renewal, grouped_matches),
           :ok <- persist_event_resolutions(classified, renewal),
           {:ok, updated_renewal} <-
             MeteredRenewalActions.mark_invoice_authored(renewal, invoice, %{
               matched_event_count: length(classified.matched),
               unmatched_event_count: length(classified.unmatched),
               unusable_event_count: length(classified.unusable)
             }) do
        {:ok, %{invoice: Repo.preload(invoice, :items, force: true), renewal: updated_renewal}}
      end
    end)
    |> normalize_transact_result()
  end

  defp existing_invoice(%MeteredRenewal{invoice_id: invoice_id, invoice_status: @authored_status})
       when is_binary(invoice_id) do
    Repo.get(Invoice, invoice_id)
  end

  defp existing_invoice(_renewal), do: nil

  defp definitions_from_snapshot(%{"meter_definitions" => definitions})
       when is_list(definitions) do
    Map.new(definitions, fn definition -> {definition["event_name"], definition} end)
  end

  defp definitions_from_snapshot(_snapshot), do: %{}

  defp billable_events_for_renewal(%MeteredRenewal{} = renewal) do
    from(event in MeterEvent,
      where:
        event.customer_id == ^renewal.customer_id and
          event.occurred_at >= ^renewal.period_start and
          event.occurred_at < ^renewal.period_end and
          is_nil(event.billing_status),
      order_by: [asc: event.occurred_at, asc: event.inserted_at]
    )
    |> Repo.all()
  end

  defp classify_events(events, definitions) do
    Enum.reduce(events, %{matched: [], unmatched: [], unusable: []}, fn event, acc ->
      case Map.get(definitions, event.event_name) do
        nil ->
          %{acc | unmatched: [%{event: event, error: "no_meter_definition"} | acc.unmatched]}

        definition ->
          if is_integer(event.value) and event.value >= 0 do
            %{acc | matched: [%{event: event, definition: definition} | acc.matched]}
          else
            %{acc | unusable: [%{event: event, error: "invalid_value"} | acc.unusable]}
          end
      end
    end)
  end

  defp aggregate_matches(matches) do
    matches
    |> Enum.group_by(fn %{definition: definition} -> definition["meter_definition_id"] end)
    |> Enum.map(fn {_definition_id, rows} -> build_match_summary(rows) end)
  end

  defp build_match_summary([%{definition: definition} | _] = rows) do
    aggregation_mode = definition["aggregation_mode"] || "sum"
    billing_snapshot = definition["billing_snapshot"] || %{}
    quantity = aggregate_quantity(rows, aggregation_mode)
    unit_amount_minor = billing_snapshot["unit_amount_minor"] || 0

    %{
      definition: definition,
      billing_snapshot: billing_snapshot,
      quantity: quantity,
      amount_minor: quantity * unit_amount_minor,
      event_ids: Enum.map(rows, & &1.event.id)
    }
  end

  defp aggregate_quantity(rows, "max"),
    do: rows |> Enum.map(& &1.event.value) |> Enum.max(fn -> 0 end)

  defp aggregate_quantity(rows, "last") do
    rows
    |> Enum.max_by(& &1.event.occurred_at, DateTime)
    |> then(& &1.event.value)
  end

  defp aggregate_quantity(rows, _mode),
    do: Enum.reduce(rows, 0, fn %{event: event}, acc -> acc + event.value end)

  defp upsert_invoice(%MeteredRenewal{} = renewal, total_minor) do
    attrs = %{
      customer_id: renewal.customer_id,
      subscription_id: renewal.subscription_id,
      processor: renewal.processor,
      processor_id: invoice_processor_id(renewal),
      status: :open,
      currency: default_currency(),
      total_cents: total_minor,
      subtotal_minor: total_minor,
      discount_minor: 0,
      tax_minor: 0,
      total_minor: total_minor,
      amount_due_minor: total_minor,
      amount_paid_minor: 0,
      amount_remaining_minor: total_minor,
      period_start: renewal.period_start,
      period_end: renewal.period_end,
      collection_method: "automatic",
      billing_reason: "metered_cycle",
      finalized_at: DateTime.utc_now(),
      data: %{
        "metered_renewal_id" => renewal.id,
        "source" => "braintree_metered_renewal"
      }
    }

    case Repo.get_by(Invoice,
           processor: renewal.processor,
           processor_id: invoice_processor_id(renewal)
         ) do
      nil ->
        %Invoice{}
        |> Invoice.force_status_changeset(attrs)
        |> Repo.insert()

      %Invoice{} = invoice ->
        invoice
        |> Invoice.force_status_changeset(attrs)
        |> Repo.update()
    end
  end

  defp upsert_items(%Invoice{} = invoice, %MeteredRenewal{} = renewal, grouped_matches) do
    grouped_matches
    |> Enum.reduce_while({:ok, []}, fn match, {:ok, acc} ->
      attrs = %{
        invoice_id: invoice.id,
        stripe_id: item_processor_id(renewal, match.definition),
        description: match.billing_snapshot["description"] || match.definition["event_name"],
        amount_minor: match.amount_minor,
        currency: default_currency(),
        quantity: match.quantity,
        period_start: renewal.period_start,
        period_end: renewal.period_end,
        price_ref: match.definition["price_id"],
        subscription_item_ref: match.definition["subscription_item_id"],
        data: %{
          "snapshot" => match.billing_snapshot,
          "meter_definition_id" => match.definition["meter_definition_id"],
          "meter_event_ids" => match.event_ids
        }
      }

      case Repo.get_by(InvoiceItem, stripe_id: attrs.stripe_id) do
        nil ->
          case %InvoiceItem{} |> InvoiceItem.changeset(attrs) |> Repo.insert() do
            {:ok, item} -> {:cont, {:ok, [item | acc]}}
            {:error, _} = err -> {:halt, err}
          end

        %InvoiceItem{} = existing ->
          case existing |> InvoiceItem.changeset(attrs) |> Repo.update() do
            {:ok, item} -> {:cont, {:ok, [item | acc]}}
            {:error, _} = err -> {:halt, err}
          end
      end
    end)
  end

  defp persist_event_resolutions(classified, renewal) do
    Enum.each(classified.matched, fn %{event: event, definition: definition} ->
      event
      |> MeterEvent.resolution_changeset(%{
        meter_definition_id: definition["meter_definition_id"],
        metered_renewal_id: renewal.id,
        billing_status: "matched",
        billing_error: nil
      })
      |> Repo.update!()
    end)

    Enum.each(classified.unmatched, fn %{event: event, error: error} ->
      event
      |> MeterEvent.resolution_changeset(%{
        metered_renewal_id: renewal.id,
        billing_status: "unmatched",
        billing_error: error
      })
      |> Repo.update!()
    end)

    Enum.each(classified.unusable, fn %{event: event, error: error} ->
      event
      |> MeterEvent.resolution_changeset(%{
        metered_renewal_id: renewal.id,
        billing_status: "unusable",
        billing_error: error
      })
      |> Repo.update!()
    end)

    :ok
  end

  defp invoice_processor_id(%MeteredRenewal{} = renewal), do: "metered-renewal:" <> renewal.id

  defp item_processor_id(%MeteredRenewal{} = renewal, definition) do
    "metered-renewal-item:" <> renewal.id <> ":" <> definition["meter_definition_id"]
  end

  defp default_currency do
    Config.get!(:default_currency)
    |> to_string()
  end

  defp normalize_transact_result({:ok, {:ok, result}}), do: {:ok, result}
  defp normalize_transact_result({:ok, result}), do: {:ok, result}
  defp normalize_transact_result({:error, err}), do: {:error, err}
end
