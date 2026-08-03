defmodule Accrue.Entitlements.Apple.ReconciliationWakeupWorker do
  @moduledoc false
  use Oban.Worker, queue: :accrue_entitlements, max_attempts: 25

  alias Accrue.Entitlements.Apple.Reconciliation

  @impl Oban.Worker
  def perform(%Oban.Job{}), do: Reconciliation.drain_wakeups(Accrue.Repo.repo()) |> result()

  defp result({:ok, _count}), do: :ok
  defp result({:error, reason}), do: {:error, reason}
end
