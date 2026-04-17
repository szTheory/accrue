defmodule AccrueAdmin.TaxOwnershipRow do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Repo

  @spec from_customer(Customer.t()) :: map()
  def from_customer(%Customer{} = customer) do
    sub =
      Subscription
      |> where([s], s.customer_id == ^customer.id)
      |> order_by([s], desc: s.inserted_at, desc: s.id)
      |> limit(1)
      |> Repo.one()

    base(customer, sub)
  end

  @spec from_subscription(Subscription.t(), Customer.t()) :: map()
  def from_subscription(%Subscription{} = subscription, %Customer{} = customer) do
    base(customer, subscription)
  end

  @spec from_invoice(map() | struct(), Customer.t()) :: map()
  def from_invoice(invoice, %Customer{} = customer) do
    %{
      owner_type: customer.owner_type,
      owner_id: customer.owner_id,
      automatic_tax: invoice.automatic_tax,
      automatic_tax_disabled_reason: invoice.automatic_tax_disabled_reason,
      last_finalization_error_code: invoice.last_finalization_error_code
    }
  end

  @spec from_charge(Customer.t()) :: map()
  def from_charge(%Customer{} = customer), do: from_customer(customer)

  defp base(%Customer{} = customer, nil) do
    %{
      owner_type: customer.owner_type,
      owner_id: customer.owner_id,
      automatic_tax: false,
      automatic_tax_disabled_reason: nil,
      last_finalization_error_code: nil
    }
  end

  defp base(%Customer{} = customer, %Subscription{} = subscription) do
    %{
      owner_type: customer.owner_type,
      owner_id: customer.owner_id,
      automatic_tax: subscription.automatic_tax,
      automatic_tax_disabled_reason: subscription.automatic_tax_disabled_reason,
      last_finalization_error_code: nil
    }
  end
end
