defmodule Accrue.Entitlements.Reconcile do
  @moduledoc """
  Shared writer for advisory entitlement-summary snapshots.

  Webhooks and pull refreshes both reduce to the same summary-shaped
  `Accrue.Billing.EntitlementSummary` row. This module owns only that
  observational cache write; grant decisions remain local-only.
  """

  import Ecto.Query

  alias Accrue.Billing.{Customer, EntitlementSummary}
  alias Accrue.{Events, Repo}

  @type source :: :webhook | :pull

  @spec write_webhook(String.t() | nil, DateTime.t() | nil, map(), atom() | String.t()) ::
          {:ok, EntitlementSummary.t() | :stale | :deferred | :ignored} | {:error, term()}
  def write_webhook(evt_id, evt_ts, obj, processor) do
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
        synced_at = synced_at_from_event(evt_ts)

        Repo.transact(fn ->
          case Repo.get_by(Customer, processor_id: cus_id, processor: to_string(processor)) do
            %Customer{} = customer ->
              row = Repo.get_by(EntitlementSummary, customer_id: customer.id)

              case check_stale(row, synced_at, evt_id) do
                :stale_same ->
                  emit_webhook_stale(cus_id, evt_id)

                  emit_summary_synced(
                    %{
                      customer_id: customer.id,
                      has_more: get(entitlements, :has_more) == true,
                      entitlement_count: length(data),
                      source: :webhook
                    },
                    length(data),
                    :unchanged
                  )

                  {:ok, :stale}

                :stale ->
                  emit_webhook_stale(cus_id, evt_id)

                  {:ok, :stale}

                :ok ->
                  write_summary(%{
                    source: :webhook,
                    event_id: evt_id,
                    synced_at: synced_at,
                    event_ts: evt_ts,
                    payload: obj,
                    customer: customer,
                    row: row,
                    customer_processor_id: cus_id,
                    processor: to_string(processor),
                    entitlements: entitlements,
                    data: data
                  })
              end

            _ ->
              :telemetry.execute(
                [:accrue, :webhooks, :orphan_entitlement_summary],
                %{},
                %{customer_stripe_id: cus_id}
              )

              {:ok, :deferred}
          end
        end)
    end
  end

  @spec write_pull(Customer.t(), DateTime.t(), [map()], String.t()) ::
          {:ok, EntitlementSummary.t() | :unchanged | :stale} | {:error, term()}
  def write_pull(%Customer{} = customer, %DateTime{} = pull_started_at, data, list_path)
      when is_list(data) and is_binary(list_path) do
    payload = pull_payload(customer.processor_id, data, list_path)

    Repo.transact(fn ->
      row = Repo.get_by(EntitlementSummary, customer_id: customer.id)

      write_summary(%{
        source: :pull,
        event_id: nil,
        synced_at: pull_started_at,
        event_ts: nil,
        payload: payload,
        customer: customer,
        row: row,
        customer_processor_id: customer.processor_id,
        processor: customer.processor || Accrue.Processor.name(),
        entitlements: payload["entitlements"],
        data: data
      })
    end)
  end

  defp pull_payload(customer_processor_id, data, list_path) do
    %{
      "object" => "entitlements.active_entitlement_summary",
      "customer" => customer_processor_id,
      "livemode" => livemode_from_entitlements(data),
      "entitlements" => %{
        "object" => "list",
        "has_more" => false,
        "url" => list_path,
        "data" => data
      },
      "_accrue" => %{
        "source" => "pull",
        "synced_by" => "Accrue.Entitlements.StripeSync.refresh/2"
      }
    }
  end

  defp write_summary(args) do
    row = args.row
    data = args.data
    entitlements = args.entitlements
    source = args.source
    has_more = get(entitlements, :has_more) == true
    entitlement_count = length(data)
    new_pairs = entitlement_pairs(data)
    material? = summary_material_change?(row, new_pairs, has_more)

    attrs =
      %{
        customer_id: args.customer.id,
        stripe_customer_id: args.customer_processor_id,
        processor: to_string(args.processor),
        livemode: livemode_for_upsert(get(args.payload, :livemode), row),
        entitlement_count: entitlement_count,
        truncated: has_more,
        synced_at: args.synced_at,
        data: args.payload
      }
      |> stamp_summary_watermark(source, args.event_ts, args.event_id, row)

    metadata = %{
      customer_id: args.customer.id,
      has_more: has_more,
      entitlement_count: entitlement_count,
      source: source
    }

    if source == :pull and not material? do
      emit_summary_synced(metadata, entitlement_count, :unchanged)
      {:ok, :unchanged}
    else
      write_material_summary(attrs, metadata, entitlement_count, material?, source, args.event_id)
    end
  end

  defp write_material_summary(attrs, metadata, entitlement_count, material?, source, event_id) do
    case upsert_entitlement_summary(attrs) do
      {:ok, :stale} ->
        emit_summary_synced(metadata, entitlement_count, :unchanged)
        {:ok, :stale}

      {:ok, saved} ->
        with {:ok, _} <- maybe_record_summary_event(material?, source, saved, event_id) do
          emit_summary_synced(
            metadata,
            entitlement_count,
            if(material?, do: :written, else: :unchanged)
          )

          if saved.truncated do
            Accrue.Telemetry.Ops.emit(
              :entitlement_summary_truncated,
              %{count: 1},
              %{customer_id: saved.customer_id}
            )
          end

          {:ok, saved}
        end

      error ->
        error
    end
  end

  defp emit_summary_synced(metadata, entitlement_count, result) do
    :telemetry.execute(
      [:accrue, :entitlements, :summary_synced],
      %{count: 1, entitlement_count: entitlement_count},
      Map.put(metadata, :result, result)
    )
  end

  defp maybe_record_summary_event(false, _source, _saved, _event_id), do: {:ok, :unchanged}

  defp maybe_record_summary_event(true, :webhook, %EntitlementSummary{} = saved, evt_id) do
    record_event(saved, "webhook", evt_id, "entitlements.summary.synced:" <> to_string(evt_id))
  end

  defp maybe_record_summary_event(true, :pull, %EntitlementSummary{} = saved, _evt_id) do
    record_event(
      saved,
      "pull",
      nil,
      "entitlements.summary.synced:pull:" <>
        saved.id <> ":" <> DateTime.to_iso8601(saved.synced_at)
    )
  end

  defp record_event(%EntitlementSummary{} = saved, source, stripe_event_id, idempotency_key) do
    Events.record(%{
      type: "entitlements.summary.synced",
      subject_type: "EntitlementSummary",
      subject_id: saved.id,
      data: %{source: source, stripe_event_id: stripe_event_id},
      idempotency_key: idempotency_key
    })
  end

  defp summary_material_change?(nil, _new_pairs, _has_more), do: true

  defp summary_material_change?(%EntitlementSummary{} = row, new_pairs, has_more) do
    existing = get(row.data || %{}, :entitlements) |> get(:data)
    new_pairs != entitlement_pairs(existing) or (row.truncated || false) != has_more
  end

  defp entitlement_pairs(data) when is_list(data) do
    data
    |> Enum.map(fn ent -> {get(ent, :feature), get(ent, :lookup_key)} end)
    |> Enum.sort()
  end

  defp entitlement_pairs(_), do: []

  defp upsert_entitlement_summary(attrs) do
    conflict_query =
      from(e in EntitlementSummary,
        where:
          (is_nil(e.synced_at) and is_nil(e.last_stripe_event_ts)) or
            fragment("COALESCE(?, ?) < EXCLUDED.synced_at", e.synced_at, e.last_stripe_event_ts) or
            fragment(
              """
              COALESCE(?, ?) = EXCLUDED.synced_at
              AND EXCLUDED.last_stripe_event_id IS NOT NULL
              AND (? IS NULL OR ? COLLATE "C" < EXCLUDED.last_stripe_event_id COLLATE "C")
              """,
              e.synced_at,
              e.last_stripe_event_ts,
              e.last_stripe_event_id,
              e.last_stripe_event_id
            ),
        update: [
          set: [
            processor: fragment("EXCLUDED.processor"),
            stripe_customer_id: fragment("EXCLUDED.stripe_customer_id"),
            livemode: fragment("EXCLUDED.livemode"),
            entitlement_count: fragment("EXCLUDED.entitlement_count"),
            truncated: fragment("EXCLUDED.truncated"),
            data: fragment("EXCLUDED.data"),
            synced_at: fragment("EXCLUDED.synced_at"),
            last_stripe_event_ts: fragment("EXCLUDED.last_stripe_event_ts"),
            last_stripe_event_id: fragment("EXCLUDED.last_stripe_event_id"),
            updated_at: fragment("EXCLUDED.updated_at")
          ]
        ]
      )

    %EntitlementSummary{}
    |> EntitlementSummary.force_changeset(attrs)
    |> Repo.insert(
      returning: true,
      conflict_target: :customer_id,
      on_conflict: conflict_query
    )
  rescue
    Ecto.StaleEntryError -> {:ok, :stale}
  end

  defp synced_at_from_event(%DateTime{} = evt_ts), do: evt_ts
  defp synced_at_from_event(_), do: Accrue.Clock.utc_now()

  defp stamp_summary_watermark(attrs, :webhook, %DateTime{} = evt_ts, evt_id, _row) do
    Map.merge(attrs, %{last_stripe_event_ts: evt_ts, last_stripe_event_id: evt_id})
  end

  defp stamp_summary_watermark(attrs, _source, _evt_ts, _evt_id, nil), do: attrs

  defp stamp_summary_watermark(attrs, _source, _evt_ts, _evt_id, %EntitlementSummary{} = row) do
    Map.merge(attrs, %{
      last_stripe_event_ts: row.last_stripe_event_ts,
      last_stripe_event_id: row.last_stripe_event_id
    })
  end

  defp livemode_for_upsert(nil, %EntitlementSummary{livemode: prior}) when not is_nil(prior),
    do: prior

  defp livemode_for_upsert(incoming, _row), do: incoming

  defp livemode_from_entitlements([first | _]), do: get(first, :livemode)
  defp livemode_from_entitlements(_), do: nil

  defp check_stale(nil, _synced_at, _event_id), do: :ok
  defp check_stale(_row, nil, _event_id), do: :ok

  defp check_stale(row, synced_at, event_id) do
    case summary_order(row, synced_at, event_id) do
      :older -> :stale
      :same -> :stale_same
      :newer -> :ok
    end
  end

  defp summary_order(%EntitlementSummary{} = row, %DateTime{} = synced_at, event_id) do
    case row_order_timestamp(row) do
      nil ->
        :newer

      %DateTime{} = existing_ts ->
        case DateTime.compare(synced_at, existing_ts) do
          :gt -> :newer
          :lt -> :older
          :eq -> compare_event_id(event_id, row.last_stripe_event_id)
        end
    end
  end

  defp row_order_timestamp(%EntitlementSummary{} = row) do
    row.synced_at || row.last_stripe_event_ts
  end

  defp compare_event_id(nil, _existing_id), do: :same
  defp compare_event_id(event_id, nil) when is_binary(event_id), do: :newer

  defp compare_event_id(event_id, existing_id)
       when is_binary(event_id) and is_binary(existing_id) do
    cond do
      event_id > existing_id -> :newer
      event_id < existing_id -> :older
      true -> :same
    end
  end

  defp emit_webhook_stale(cus_id, evt_id) do
    :telemetry.execute(
      [:accrue, :webhooks, :stale_event],
      %{},
      %{object_type: :entitlement_summary, stripe_id: cus_id, event_id: evt_id}
    )
  end

  defp emit_summary_malformed(evt_id, reason) do
    :telemetry.execute(
      [:accrue, :webhooks, :malformed_entitlement_summary],
      %{},
      %{event_id: evt_id, reason: reason}
    )
  end

  defp get(%{} = map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp get(_, _), do: nil
end
