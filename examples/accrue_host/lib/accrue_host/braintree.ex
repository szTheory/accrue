defmodule AccrueHost.Braintree do
  @moduledoc """
  Host-owned Braintree preparation seam.
  Keeps browser acquisition and vaulting isolated from the generic `Accrue.Billing` facade.
  """

  @doc """
  Generates a client token required by the Braintree Drop-in UI.
  """
  def client_token_for(customer_id \\ nil) do
    # Assuming Accrue.Processor.Braintree or Braintree lib handles this.
    # We will use the `Braintree.ClientToken.generate/1`
    case Braintree.ClientToken.generate(%{customer_id: customer_id}) do
      {:ok, token} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end
end
