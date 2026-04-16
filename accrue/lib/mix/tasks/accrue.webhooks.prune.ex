defmodule Mix.Tasks.Accrue.Webhooks.Prune do
  @shortdoc "Run the webhook event retention sweep on demand"
  @moduledoc """
  Manually trigger the same retention sweep that `Accrue.Webhook.Pruner`
  runs on its Oban cron schedule. Useful for ops engineers who want to
  reclaim DB space without waiting for the next scheduled run.

  ## Usage

      mix accrue.webhooks.prune

  Configuration is read from `Accrue.Config`:

    * `:succeeded_retention_days` (default `14`)
    * `:dead_retention_days` (default `90`)
  """

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("app.start")

    case Accrue.Webhook.Pruner.perform(%Oban.Job{}) do
      :ok ->
        Mix.shell().info("Webhook event retention sweep complete.")
    end
  end
end
