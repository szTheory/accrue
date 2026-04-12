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

  alias Accrue.Webhook.WebhookEvent

  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    repo = Accrue.Repo.repo()
    succeeded_days = Accrue.Config.succeeded_retention_days()
    dead_days = Accrue.Config.dead_retention_days()

    unless succeeded_days == :infinity do
      cutoff = DateTime.utc_now() |> DateTime.add(-succeeded_days * 86_400, :second)

      from(w in WebhookEvent, where: w.status == :succeeded and w.inserted_at < ^cutoff)
      |> repo.delete_all()
    end

    unless dead_days == :infinity do
      cutoff = DateTime.utc_now() |> DateTime.add(-dead_days * 86_400, :second)

      from(w in WebhookEvent, where: w.status == :dead and w.inserted_at < ^cutoff)
      |> repo.delete_all()
    end

    :ok
  end
end
