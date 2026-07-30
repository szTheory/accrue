defmodule Accrue.Entitlements.StripeSync.RefreshWorker do
  @moduledoc """
  Thin Oban wrapper for advisory Stripe-native entitlement refreshes.

  Hosts may enqueue this worker with scalar JSON args to move
  `Accrue.Entitlements.StripeSync.refresh/1` off the request path. Accrue
  does not schedule, supervise, or poll this worker; it is inert unless a host
  runs the existing `:accrue_webhooks` queue and enqueues a customer id.
  """

  use Oban.Worker, queue: :accrue_webhooks, max_attempts: 25

  alias Accrue.Billing.{Customer, EntitlementSummary}
  alias Accrue.Entitlements.StripeSync
  alias Accrue.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"customer_id" => customer_id}} = job)
      when is_binary(customer_id) do
    Accrue.Oban.Middleware.put(job)

    case Repo.get(Customer, customer_id) do
      %Customer{} = customer ->
        customer
        |> StripeSync.refresh()
        |> oban_result()

      nil ->
        {:cancel, :customer_not_found}
    end
  end

  defp oban_result({:ok, %EntitlementSummary{} = summary}), do: {:ok, summary}
  defp oban_result({:ok, _non_row_success}), do: :ok
  defp oban_result({:error, reason}), do: {:error, reason}
end
