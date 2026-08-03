defmodule Accrue.Billing.ResourceDispatchTest do
  use ExUnit.Case, async: true

  alias Accrue.Rails.GatewayRegistry
  alias Accrue.Rails.GatewayRegistry.Error
  alias Accrue.Entitlements.Source.Outcome

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

  describe "external management" do
    test "returns Apple-owned management guidance as a successful outcome" do
      assert {:ok,
              %Outcome{
                source: :apple,
                capability: :management,
                state: :externally_managed,
                guidance: %{
                  key: :manage_apple_subscription,
                  text: "Manage this subscription in Apple.",
                  action_label: "Manage subscription",
                  url: "https://apps.apple.com/account/subscriptions"
                }
              }} = Accrue.Billing.management(:apple)
    end

    test "management emits one bounded start/stop span pair" do
      test_pid = self()
      handler_id = "resource-dispatch-management-#{System.unique_integer([:positive])}"

      :ok =
        :telemetry.attach_many(
          handler_id,
          [[:accrue, :billing, :management, :start], [:accrue, :billing, :management, :stop]],
          fn event, _measurements, metadata, _config ->
            send(test_pid, {:management_span, event, metadata})
          end,
          nil
        )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert {:ok, %Outcome{state: :externally_managed}} = Accrue.Billing.management(:apple)
      assert_received {:management_span, [:accrue, :billing, :management, :start], start_metadata}
      assert_received {:management_span, [:accrue, :billing, :management, :stop], stop_metadata}

      assert Map.take(start_metadata, [:action, :rail]) == %{action: :management, rail: :apple}
      assert Map.take(stop_metadata, [:action, :rail]) == %{action: :management, rail: :apple}
      refute Map.has_key?(start_metadata, :provider_payload)
      refute Map.has_key?(start_metadata, :email)
    end

    test "existing-resource action regions use the persisted dispatch boundary" do
      source = File.read!("lib/accrue/billing/subscription_actions.ex")

      for action <- [
            "swap_plan",
            "preview_upcoming_invoice",
            "update_quantity",
            "cancel",
            "cancel_at_period_end",
            "resume",
            "pause",
            "unpause"
          ] do
        assert source =~ "def #{action}"
      end

      refute source =~ "Processor.__impl__().cancel_subscription"
      refute source =~ "Processor.__impl__().create_invoice_preview"
    end
  end
end
