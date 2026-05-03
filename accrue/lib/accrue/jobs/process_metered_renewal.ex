defmodule Accrue.Jobs.ProcessMeteredRenewal do
  @moduledoc """
  Worker-owned BT-06 aggregation path for one metered renewal window.
  """

  use Oban.Worker, queue: :accrue_meters, max_attempts: 3

  alias Accrue.Billing.MeteredRenewalActions

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"metered_renewal_id" => metered_renewal_id}} = job)
      when is_binary(metered_renewal_id) do
    _ = Accrue.Oban.Middleware.put(job)

    case MeteredRenewalActions.author_local_invoice(metered_renewal_id) do
      {:ok, _result} -> :ok
      {:error, err} -> {:error, err}
    end
  end

  def perform(%Oban.Job{}), do: {:error, :missing_metered_renewal_id}
end
