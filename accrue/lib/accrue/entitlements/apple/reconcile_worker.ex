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

    Reconciliation.run(args,
      client: configured_client(),
      admit_transaction: configured_admission()
    )
    |> oban_result()
  end

  def perform(_), do: {:cancel, :invalid_reconciliation_args}

  defp configured_client do
    Application.get_env(:accrue, :apple_reconciliation, [])
    |> Keyword.get(:client)
  end

  defp configured_admission do
    Application.get_env(:accrue, :apple_reconciliation, [])
    |> Keyword.get(:admit_transaction)
  end

  defp oban_result({:ok, _}), do: :ok
  defp oban_result({:error, :config_invalid}), do: {:cancel, :needs_repair}
  defp oban_result({:error, reason}), do: {:error, reason}
end
