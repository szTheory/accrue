defmodule Accrue.Entitlements.Apple.ReconciliationSweeper do
  @moduledoc """
  Host-scheduled Oban entry point for Apple reconciliation checkpoints.

  Accrue starts no scheduler. Hosts add this worker to their existing Oban Cron
  plugin; each tick durably claims a bounded batch of due checkpoints.
  """
  use Oban.Worker, queue: :accrue_entitlements, max_attempts: 3

  alias Accrue.Entitlements.Apple.Reconciliation

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Accrue.Oban.Middleware.put(job)

    case sweep(Accrue.Repo.repo()) do
      {:ok, _count} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def sweep(repo, opts \\ []), do: Reconciliation.enqueue_due(repo, opts)
end
