defmodule AccruePortal.BraintreeClient do
  @moduledoc false

  alias Accrue.Billing.Customer

  def client_token_for(%Customer{processor_id: customer_id}) do
    generator =
      Application.get_env(:accrue, :braintree_client_token_generator, Braintree.ClientToken)

    case generator.generate(%{customer_id: customer_id}) do
      {:ok, token} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end
end
