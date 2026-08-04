defmodule Accrue.Entitlements.Offline.ReconnectWorker do
  @moduledoc false
  use Oban.Worker, queue: :accrue_entitlements, max_attempts: 25
  alias Accrue.Entitlements.Offline.Reconnect
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"attempt_id" => id}} = job) when is_binary(id) do
    Accrue.Oban.Middleware.put(job)

    case Reconnect.execute_attempt(id) do
      :ok -> :ok
      {:error, :config_invalid} -> {:cancel, :config_invalid}
      {:error, reason} -> {:error, reason}
    end
  end

  def perform(_), do: {:cancel, :invalid_reconnect_args}
end
