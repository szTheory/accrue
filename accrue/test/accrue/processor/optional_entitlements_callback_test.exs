defmodule Accrue.Processor.OptionalEntitlementsCallbackTest do
  use ExUnit.Case, async: false

  alias Accrue.Processor

  defmodule AdapterWithoutEntitlements do
  end

  defmodule AdapterWithEntitlements do
    def list_active_entitlements(customer_id, opts) do
      send(self(), {:list_active_entitlements, customer_id, opts})
      {:ok, [%{"id" => "ent_123", "lookup_key" => "reports"}]}
    end
  end

  setup do
    previous = Application.get_env(:accrue, :processor)

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    :ok
  end

  test "adapter without optional entitlement callback returns bounded typed unsupported error" do
    Application.put_env(:accrue, :processor, AdapterWithoutEntitlements)

    assert {:error, %Accrue.APIError{} = error} =
             Processor.list_active_entitlements("cus_secret_123", expand: ["feature"])

    assert error.code == "unsupported_operation"
    assert error.http_status == 501
    assert error.message =~ "list_active_entitlements/2"
    assert error.message =~ inspect(AdapterWithoutEntitlements)
    refute error.message =~ "cus_secret_123"
    refute error.message =~ "expand"
    refute error.message =~ "feature"
    assert is_nil(error.processor_error)
  end

  test "adapter with optional entitlement callback is delegated unchanged" do
    Application.put_env(:accrue, :processor, AdapterWithEntitlements)

    assert {:ok, [%{"id" => "ent_123", "lookup_key" => "reports"}]} =
             Processor.list_active_entitlements("cus_123", limit: 10)

    assert_received {:list_active_entitlements, "cus_123", [limit: 10]}
  end
end
