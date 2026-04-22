defmodule Accrue.Billing.MeterEvents do
  @moduledoc """
  Phase 4 Plan 02 helper for asynchronous meter-event state transitions
  driven by Stripe webhooks (BILL-13, Pitfall 5).

  Kept separate from `Accrue.Billing.MeterEventActions` so the webhook
  path (`Accrue.Webhook.DefaultHandler`) doesn't pull the outbox/
  NimbleOptions surface into its dependency graph.

  Phase 44 centralizes **pending → failed** transitions with guarded updates
  and `[:accrue, :ops, :meter_reporting_failed]` so retries and duplicate
  deliveries do not inflate ops counters.
  """

  import Ecto.Query

  alias Accrue.Billing.MeterEvent
  alias Accrue.Repo

  @typedoc """
  Origin of a terminal failure for `meter_reporting_failed` metadata.

  * `:sync` — synchronous `report_usage/3` processor error
  * `:reconciler` — `MeterEventsReconciler` retry exhausted path
  * `:webhook` — Stripe `billing.meter.error_report_triggered` (or v1) path
  """
  @type failure_source :: :sync | :reconciler | :webhook

  @doc """
  Looks up the meter-event row by `identifier` and flips it to `failed`
  with the Stripe error-report object sanitized into `stripe_error`.

  Uses the same guarded transition as the sync path so duplicate webhook
  deliveries do not emit a second `meter_reporting_failed` for an already
  terminal row.

  `webhook_event_id` is optional metadata for ops telemetry (attach the
  Stripe event id when known).
  """
  @spec mark_failed_by_identifier(String.t() | nil, map(), String.t() | nil) ::
          {:ok, MeterEvent.t()} | {:error, :not_found}
  def mark_failed_by_identifier(identifier, stripe_obj, webhook_event_id \\ nil)

  def mark_failed_by_identifier(nil, _stripe_obj, _webhook_event_id), do: {:error, :not_found}

  def mark_failed_by_identifier(identifier, stripe_obj, webhook_event_id)
      when is_binary(identifier) do
    case Repo.get_by(MeterEvent, identifier: identifier) do
      nil ->
        {:error, :not_found}

      %MeterEvent{} = row ->
        opts = [
          from_statuses: ["pending", "reported"],
          webhook_event_id: webhook_event_id
        ]

        case mark_failed_with_telemetry(row, stripe_obj, :webhook, opts) do
          {:ok, :transitioned, updated} ->
            {:ok, updated}

          {:ok, :noop, current} ->
            {:ok, current}

          {:error, :not_found} ->
            {:error, :not_found}
        end
    end
  end

  @doc """
  Atomically flips a **single** meter-event row whose `stripe_status` is in
  `:from_statuses` (default `["pending"]`) to `failed`, persisting a sanitized
  `stripe_error` derived from `err`.

  Emits `[:accrue, :ops, :meter_reporting_failed]` **only** when the guarded
  update affects one row (`count == 1`). If no row matched (already terminal,
  wrong status, or deleted), **no telemetry** is emitted and `{:ok, :noop, row}`
  returns the current row when it still exists.

  ## Returns

    * `{:ok, :transitioned, %MeterEvent{}}` — this invocation performed the
      durable `pending` → `failed` transition (telemetry fired).
    * `{:ok, :noop, %MeterEvent{}}` — no qualifying row was updated; `row` is
      the latest state for the same primary key (e.g. idempotent replay or race).
    * `{:error, :not_found}` — the row id no longer exists.

  `source` is attached to ops telemetry metadata (`:sync`, `:reconciler`, or `:webhook`).

  ## Options

    * `:from_statuses` — list of `stripe_status` values that may transition to
      `failed` in this update (default `["pending"]` for sync/reconciler).
      Stripe meter error webhooks use `["pending", "reported"]` because Stripe
      may reject usage after an initial `reported` acknowledgement.

  """
  @spec mark_failed_with_telemetry(MeterEvent.t(), term(), failure_source(), keyword()) ::
          {:ok, :transitioned, MeterEvent.t()}
          | {:ok, :noop, MeterEvent.t()}
          | {:error, :not_found}
  def mark_failed_with_telemetry(%MeterEvent{} = row, err, source, opts \\ [])
      when source in [:sync, :reconciler, :webhook] do
    allowed = Keyword.get(opts, :from_statuses, ["pending"])

    cs = MeterEvent.failed_changeset(row, err)
    stripe_error = Ecto.Changeset.get_field(cs, :stripe_error)
    now = DateTime.utc_now()

    {count, _} =
      Repo.update_all(
        from(m in MeterEvent,
          where: m.id == ^row.id and m.stripe_status in ^allowed
        ),
        set: [stripe_status: "failed", stripe_error: stripe_error, updated_at: now]
      )

    case count do
      1 ->
        updated = Repo.get!(MeterEvent, row.id)

        :telemetry.execute(
          [:accrue, :ops, :meter_reporting_failed],
          %{count: 1},
          ops_metadata(updated, err, source, opts)
        )

        {:ok, :transitioned, updated}

      0 ->
        case Repo.get(MeterEvent, row.id) do
          nil -> {:error, :not_found}
          %MeterEvent{} = current -> {:ok, :noop, current}
        end
    end
  end

  defp ops_metadata(%MeterEvent{} = updated, err, source, opts) do
    base = %{
      meter_event_id: updated.id,
      event_name: updated.event_name,
      source: source,
      error: inspect(err)
    }

    base =
      case Keyword.get(opts, :webhook_event_id) do
        id when is_binary(id) -> Map.put(base, :webhook_event_id, id)
        _ -> base
      end

    if source == :webhook do
      enrich_webhook_ops_fields(base, updated.stripe_error || %{})
    else
      base
    end
  end

  defp enrich_webhook_ops_fields(meta, se) when is_map(se) do
    code =
      Map.get(se, "code") || Map.get(se, :code) ||
        Map.get(se, "error_code")

    msg =
      Map.get(se, "message") || Map.get(se, :message) ||
        Map.get(se, "error_message")

    meta
    |> maybe_put_meta(:error_code, code)
    |> maybe_put_meta(:message, msg)
  end

  defp maybe_put_meta(meta, _k, v) when v in [nil, ""], do: meta
  defp maybe_put_meta(meta, k, v), do: Map.put(meta, k, v)
end
