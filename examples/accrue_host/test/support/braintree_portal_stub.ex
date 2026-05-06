defmodule AccrueHost.BraintreePortalStub do
  @moduledoc false

  defmodule ClientTokenGenerator do
    @moduledoc false

    def generate(%{customer_id: _customer_id}) do
      {:ok, "host-portal-client-token"}
    end
  end
end
