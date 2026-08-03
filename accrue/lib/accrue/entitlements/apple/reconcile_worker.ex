defmodule Accrue.Entitlements.Apple.ReconcileWorker do
  @moduledoc false
  use Oban.Worker, queue: :accrue_entitlements, max_attempts: 25

  alias Accrue.Entitlements.Apple.Reconciliation

  @impl Oban.Worker
  def perform(
        %Oban.Job{args: %{"lineage_id" => lineage_id, "environment" => environment} = args} = job
      )
      when is_binary(lineage_id) and environment in ["production", "sandbox"] do
    Accrue.Oban.Middleware.put(job)

    case reconciliation_configuration() do
      {:ok, client, admission} ->
        Reconciliation.run(args, client: client, admission: admission) |> oban_result()

      {:error, reason} ->
        case Reconciliation.mark_configuration_failure(args, reason) do
          {:ok, _checkpoint} -> {:cancel, :needs_repair}
          {:error, persistence_reason} -> {:error, persistence_reason}
        end
    end
  end

  def perform(_), do: {:cancel, :invalid_reconciliation_args}

  defp reconciliation_configuration do
    case Application.get_env(:accrue, :apple_reconciliation) do
      nil ->
        {:error, :missing_reconciliation_configuration}

      config when is_list(config) ->
        client = Keyword.get(config, :client)
        admission = Keyword.get(config, :admission)

        cond do
          not Keyword.keyword?(config) -> {:error, :invalid_reconciliation_configuration}
          is_nil(client) -> {:error, :missing_reconciliation_configuration}
          not Keyword.keyword?(admission) -> {:error, :invalid_reconciliation_configuration}
          true -> {:ok, client, admission}
        end

      _ ->
        {:error, :invalid_reconciliation_configuration}
    end
  end

  defp oban_result({:ok, _}), do: :ok
  defp oban_result({:error, :config_invalid}), do: {:cancel, :needs_repair}
  defp oban_result({:error, reason}), do: {:error, reason}
end
