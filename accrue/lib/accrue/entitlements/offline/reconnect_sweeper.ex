defmodule Accrue.Entitlements.Offline.ReconnectSweeper do
  @moduledoc "Host-scheduled recovery worker for stranded offline reconnect attempts."
  use Oban.Worker, queue: :accrue_entitlements, max_attempts: 3
  alias Accrue.Entitlements.Offline.Reconnect
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    case Reconnect.enqueue_due(Accrue.Repo.repo()) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
