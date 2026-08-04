defmodule Accrue.Entitlements.Offline.ReconnectWakeupWorker do
  @moduledoc false
  use Oban.Worker, queue: :accrue_entitlements, max_attempts: 25
  alias Accrue.Entitlements.Offline.Reconnect
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    case Reconnect.drain_wakeups(Accrue.Repo.repo()) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
