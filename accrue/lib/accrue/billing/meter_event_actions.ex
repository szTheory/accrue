defmodule Accrue.Billing.MeterEventActions do
  @moduledoc """
  Phase 4 Plan 02 — metered billing write surface (BILL-13, D4-03).

  Implements `Accrue.Billing.report_usage/3` as a sync-through with a
  transactional-outbox audit table:

    1. `Repo.transact/2` inserts a `pending` `%MeterEvent{}` + an
       `accrue_events` ledger row, then commits.
    2. **Outside** the transaction, calls the configured processor's
       `report_meter_event/1` callback.
    3. On `{:ok, _}` → flips the row to `reported` (and stamps
       `reported_at`). On `{:error, _}` → `Accrue.Billing.MeterEvents`
       performs a guarded `pending` → `failed` transition and emits
       `[:accrue, :ops, :meter_reporting_failed]` at most once for that
       transition (`source: :sync`).

  Crashes between step 1 and step 2 leave a durable `pending` row that
  `Accrue.Jobs.MeterEventsReconciler` retries on its next cron tick.

  Idempotency: the caller's `operation_id` (via `Accrue.Actor`) + event
  name + value + timestamp derive a deterministic `identifier`. The
  unique index on `accrue_meter_events.identifier` dedupes at the audit
  layer; Stripe's body-level `identifier` + HTTP-level `idempotency_key`
  (forwarded in `Accrue.Processor.Stripe`) dedupe at the wire.
  """

  require Logger

  alias Accrue.Actor
  alias Accrue.Billing.Customer
  alias Accrue.Billing.MeterEvent
  alias Accrue.Billing.MeterEvents
  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Repo

  @report_usage_schema [
    value: [type: :non_neg_integer, default: 1],
    timestamp: [type: :any, default: nil],
    identifier: [type: {:or, [:string, nil]}, default: nil],
    operation_id: [type: {:or, [:string, nil]}, default: nil],
    payload: [type: {:or, [{:map, :any, :any}, nil]}, default: nil]
  ]

  @backdate_window_seconds 35 * 86_400
  @future_skew_seconds 300

  @doc """
  Reports a metered usage event. See `Accrue.Billing.report_usage/3` for
  the public entry point; this function is the implementation target.
  """
  @spec report_usage(Customer.t() | String.t(), String.t(), keyword()) ::
          {:ok, MeterEvent.t()} | {:error, term()}
  def report_usage(customer_or_id, event_name, opts \\ [])

  def report_usage(stripe_customer_id, event_name, opts)
      when is_binary(stripe_customer_id) and is_binary(event_name) do
    case Repo.get_by(Customer, processor_id: stripe_customer_id) do
      nil ->
        {:error,
         %Accrue.APIError{
           code: "resource_missing",
           http_status: 404,
           message: "customer #{stripe_customer_id} not found"
         }}

      %Customer{} = customer ->
        report_usage(customer, event_name, opts)
    end
  end

  def report_usage(%Customer{} = customer, event_name, opts)
      when is_binary(event_name) and is_list(opts) do
    opts = NimbleOptions.validate!(opts, @report_usage_schema)
    value = opts[:value]
    ts = normalize_timestamp(opts[:timestamp])
    identifier = opts[:identifier] || derive_identifier(customer, event_name, value, ts)
    override_op = opts[:operation_id]

    with :ok <- validate_backdating_window(ts),
         {:ok, row} <-
           insert_pending(customer, event_name, value, ts, identifier, override_op) do
      # Stripe call OUTSIDE Repo.transact/2 — D2-09 / D4-03. Crashes here
      # leave the row in `pending` for the reconciler to retry.
      cond do
        row.stripe_status in ["reported", "failed"] ->
          {:ok, row}

        row.stripe_status == "pending" ->
          case Processor.__impl__().report_meter_event(row) do
            {:ok, stripe_event} ->
              row
              |> MeterEvent.reported_changeset(stripe_event)
              |> Repo.update()

            {:error, err} ->
              case MeterEvents.mark_failed_with_telemetry(row, err, :sync) do
                {:ok, :transitioned, _} ->
                  {:error, err}

                {:ok, :noop, %MeterEvent{stripe_status: "failed"} = r} ->
                  {:ok, r}

                {:ok, :noop, %MeterEvent{}} ->
                  {:error, err}

                {:error, :not_found} ->
                  {:error, err}
              end
          end

        true ->
          {:ok, row}
      end
    end
  end

  @doc """
  Bang variant of `report_usage/3`.
  """
  @spec report_usage!(Customer.t() | String.t(), String.t(), keyword()) :: MeterEvent.t()
  def report_usage!(customer_or_id, event_name, opts \\ []) do
    case report_usage(customer_or_id, event_name, opts) do
      {:ok, %MeterEvent{} = row} -> row
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "report_usage!/3 failed: #{inspect(other)}"
    end
  end

  # -- internals --------------------------------------------------------

  defp normalize_timestamp(nil), do: DateTime.utc_now()
  defp normalize_timestamp(%DateTime{} = dt), do: dt

  defp normalize_timestamp(unix) when is_integer(unix) do
    DateTime.from_unix!(unix)
  end

  defp validate_backdating_window(%DateTime{} = ts) do
    diff = DateTime.diff(DateTime.utc_now(), ts, :second)

    cond do
      diff > @backdate_window_seconds -> {:error, :timestamp_out_of_window}
      diff < -@future_skew_seconds -> {:error, :timestamp_in_future}
      true -> :ok
    end
  end

  defp derive_identifier(%Customer{} = customer, event_name, value, %DateTime{} = ts) do
    op = Actor.current_operation_id() || "unscoped"

    hash =
      :erlang.phash2({
        customer.processor_id,
        event_name,
        value,
        DateTime.to_unix(ts, :microsecond)
      })

    "accrue_mev_#{op}_#{event_name}_#{hash}"
  end

  defp insert_pending(customer, event_name, value, ts, identifier, override_op) do
    # Pre-check for an existing row by identifier (replay-safe, avoids
    # the in_failed_sql_transaction footgun when the unique index trips
    # inside Repo.transact/2). This isn't a TOCTOU concern because the
    # unique index is still the canonical guard — see the insert-time
    # rescue clause below.
    case Repo.get_by(MeterEvent, identifier: identifier) do
      %MeterEvent{} = existing ->
        {:ok, existing}

      nil ->
        do_insert_pending(customer, event_name, value, ts, identifier, override_op)
    end
  end

  defp do_insert_pending(customer, event_name, value, ts, identifier, override_op) do
    attrs = %{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      event_name: event_name,
      value: value,
      identifier: identifier,
      occurred_at: ts,
      operation_id: override_op || Actor.current_operation_id()
    }

    result =
      Repo.transact(fn ->
        changeset = MeterEvent.pending_changeset(attrs)

        case Repo.insert(changeset) do
          {:ok, row} ->
            case Events.record(%{
                   type: "meter_event.reported",
                   subject_type: "MeterEvent",
                   subject_id: row.id,
                   data: %{
                     event_name: event_name,
                     value: value,
                     identifier: identifier,
                     stripe_customer_id: customer.processor_id
                   }
                 }) do
              {:ok, _event} -> {:ok, row}
              {:error, err} -> {:error, err}
            end

          {:error, %Ecto.Changeset{} = cs} ->
            if identifier_conflict?(cs),
              do: {:error, :identifier_conflict},
              else: {:error, cs}
        end
      end)

    case result do
      {:error, :identifier_conflict} ->
        # Race: another process inserted between the pre-check and our
        # txn. Fall back to the existing row.
        case Repo.get_by(MeterEvent, identifier: identifier) do
          nil -> {:error, :identifier_race}
          %MeterEvent{} = existing -> {:ok, existing}
        end

      other ->
        other
    end
  end

  defp identifier_conflict?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:identifier, _} -> true
      _ -> false
    end)
  end
end
