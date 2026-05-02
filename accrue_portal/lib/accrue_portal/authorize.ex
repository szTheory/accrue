defmodule AccruePortal.Authorize do
  @moduledoc false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias AccruePortal.BillingReadModel

  def current_customer!(%{assigns: %{current_customer: %Customer{} = customer}}), do: customer

  def subscription(socket, id) when is_binary(id) do
    socket
    |> current_customer!()
    |> BillingReadModel.subscription(id)
  end

  def subscription!(socket, id) when is_binary(id) do
    case subscription(socket, id) do
      {:ok, %Subscription{} = subscription} -> subscription
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: Subscription
    end
  end
end
