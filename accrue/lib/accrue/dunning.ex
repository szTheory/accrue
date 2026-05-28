defmodule Accrue.Dunning do
  @moduledoc """
  Public API for checking dunning state, enabling host applications to 
  display in-app banners or alerts for active dunning campaigns without 
  false positives from projection lag.
  """

  import Ecto.Query

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Repo
  alias Accrue.Billing.Query, as: BillingQuery

  @doc """
  Returns `true` if the customer currently has an active dunning campaign,
  `false` otherwise. Uses the ledger state as the source of truth to avoid
  projection lag false positives.
  """
  @spec requires_attention?(struct()) :: boolean()
  def requires_attention?(%Customer{} = customer) do
    Subscription
    |> where(customer_id: ^customer.id)
    |> BillingQuery.in_active_dunning_campaign()
    |> Repo.repo().exists?()
  end

  def requires_attention?(billable) do
    case Accrue.Billing.customer(billable) do
      {:ok, %Customer{} = customer} -> requires_attention?(customer)
      _ -> false
    end
  end
end
