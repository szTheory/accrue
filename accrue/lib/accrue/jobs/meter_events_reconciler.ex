defmodule Accrue.Jobs.MeterEventsReconciler do
  @moduledoc """
  Metered billing outbox reconciler.

  Scans `accrue_meter_events` for rows stuck in `stripe_status = "pending"`
  more than 60 seconds and retries the Stripe call. Closes the "row
  committed but the process died before the synchronous Stripe call
  returned" gap in `Accrue.Billing.MeterEventActions.report_usage/3`.

  ## Wiring

  Accrue does not start its own Oban — the host app schedules this
  worker in its Oban cron config:

      config :my_app, Oban,
        plugins: [
          {Oban.Plugins.Cron,
           crontab: [
             {"* * * * *", Accrue.Jobs.MeterEventsReconciler}
           ]}
        ]

  The worker runs on queue `:accrue_meters` (host must declare the
  queue in its Oban config). Each tick processes up to 1 000 rows.

  ## Failure handling

  On Stripe error the row flips to `failed` — the reconciler does NOT
  keep retrying the same row in the same tick, avoiding the
  "stuck row infinite retry" footgun. Failures emit
  `[:accrue, :ops, :meter_reporting_failed]` with `source: :reconciler`
  so ops can distinguish inline vs deferred failures.
  """

  use Oban.Worker, queue: :accrue_meters, max_attempts: 3

  import Ecto.Query

  alias Accrue.Billing.MeterEvent
  alias Accrue.Clock
  alias Accrue.Processor
  alias Accrue.Repo

  @limit 1_000
  @grace_seconds 60

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    _ = Accrue.Oban.Middleware.put(job)
    {:ok, _count} = reconcile()
    :ok
  end

  def perform(_other) do
    {:ok, _count} = reconcile()
    :ok
  end

  @doc """
  Runs a single reconciliation pass. Returns `{:ok, count}` where
  `count` is the number of pending rows this pass considered. Public
  so tests can drive it without Oban's job struct.
  """
  @spec reconcile() :: {:ok, non_neg_integer()}
  def reconcile do
    cutoff = DateTime.add(Clock.utc_now(), -@grace_seconds, :second)

    pending =
      from(m in MeterEvent,
        where: m.stripe_status == "pending" and m.inserted_at < ^cutoff,
        order_by: [asc: m.inserted_at],
        limit: @limit
      )
      |> Repo.all()

    for row <- pending do
      case Processor.__impl__().report_meter_event(row) do
        {:ok, stripe_event} ->
          _ =
            row
            |> MeterEvent.reported_changeset(stripe_event)
            |> Repo.update()

        {:error, err} ->
          _ =
            row
            |> MeterEvent.failed_changeset(err)
            |> Repo.update()

          :telemetry.execute(
            [:accrue, :ops, :meter_reporting_failed],
            %{count: 1},
            %{
              meter_event_id: row.id,
              event_name: row.event_name,
              source: :reconciler,
              error: inspect(err)
            }
          )
      end
    end

    {:ok, length(pending)}
  end
end
