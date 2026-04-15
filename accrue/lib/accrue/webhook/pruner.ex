defmodule Accrue.Webhook.Pruner do
  @moduledoc """
  Oban cron worker for webhook event retention (D2-34).

  Deletes `:succeeded` and `:dead` webhook events older than their
  configured retention periods. Forced because Oban 2.21 CE's
  `Plugins.Pruner` has a single `max_age` that cannot differentiate
  between succeeded and dead events.

  ## Configuration

  - `:succeeded_retention_days` -- default 14 days
  - `:dead_retention_days` -- default 90 days

  Set either to `:infinity` to disable pruning for that status.

  ## Host wiring

  The host application must wire this worker into their Oban cron config:

      config :my_app, Oban,
        plugins: [
          {Oban.Plugins.Cron,
           crontab: [
             {"0 3 * * *", Accrue.Webhook.Pruner}
           ]}
        ]
  """

  use Oban.Worker, queue: :accrue_maintenance

  @impl Oban.Worker
  def perform(_job) do
    succeeded_days = Accrue.Config.succeeded_retention_days()
    dead_days = Accrue.Config.dead_retention_days()

    {:ok, dead_deleted} = Accrue.Webhooks.DLQ.prune(dead_days)
    {:ok, succeeded_deleted} = Accrue.Webhooks.DLQ.prune_succeeded(succeeded_days)

    :telemetry.execute(
      [:accrue, :ops, :webhook_dlq, :prune],
      %{dead_deleted: dead_deleted, succeeded_deleted: succeeded_deleted},
      %{
        dead_retention_days: dead_days,
        succeeded_retention_days: succeeded_days
      }
    )

    :ok
  end
end
