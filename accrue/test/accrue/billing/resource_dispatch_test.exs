defmodule Accrue.Billing.ResourceDispatchTest do
  use ExUnit.Case, async: true

  alias Accrue.Rails.GatewayRegistry
  alias Accrue.Rails.GatewayRegistry.Error

  describe "persisted gateway provenance" do
    test "resolves only the adapter named by the persisted processor" do
      assert {:ok, Accrue.Processor.Fake} = GatewayRegistry.resolve("fake")
      assert {:ok, Accrue.Processor.Stripe} = GatewayRegistry.resolve(:stripe)
      assert {:ok, Accrue.Processor.Braintree} = GatewayRegistry.resolve("braintree")
    end

    test "returns a stable typed error for an unknown or unavailable processor" do
      assert {:error, %Error{code: :unknown_processor, next_action: :inspect_resource_provenance}} =
               GatewayRegistry.resolve("apple")

      assert {:error, %Error{code: :missing_processor, next_action: :inspect_resource_provenance}} =
               GatewayRegistry.resolve(nil)
    end
  end
end
