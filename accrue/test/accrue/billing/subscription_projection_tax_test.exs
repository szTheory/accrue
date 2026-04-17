defmodule Accrue.Billing.SubscriptionProjectionTaxTest do
  use ExUnit.Case, async: true

  alias Accrue.Billing.SubscriptionProjection
  alias Accrue.Test.StripeFixtures

  describe "decompose/1 automatic tax projection" do
    test "projects enabled automatic tax state from string-keyed payloads" do
      sub =
        StripeFixtures.subscription_created(%{
          "automatic_tax" => %{
            "enabled" => true,
            "status" => "complete",
            "disabled_reason" => nil
          }
        })

      assert {:ok, attrs} = SubscriptionProjection.decompose(sub)
      assert attrs.automatic_tax == true
      assert attrs.automatic_tax_status == "complete"
      assert attrs.automatic_tax_disabled_reason == nil
    end

    test "projects disabled automatic tax state from atom-keyed payloads" do
      sub = %{
        id: "sub_fake_00001",
        status: :active,
        cancel_at_period_end: false,
        pause_collection: nil,
        automatic_tax: %{
          enabled: false,
          status: "requires_location_inputs",
          disabled_reason: "requires_location_inputs"
        },
        current_period_start: 0,
        current_period_end: 0,
        metadata: %{}
      }

      assert {:ok, attrs} = SubscriptionProjection.decompose(sub)
      assert attrs.automatic_tax == false
      assert attrs.automatic_tax_status == "requires_location_inputs"
      assert attrs.automatic_tax_disabled_reason == "requires_location_inputs"
    end

    test "defaults automatic tax fields when payload omits the tax map" do
      sub = StripeFixtures.subscription_created() |> Map.delete("automatic_tax")

      assert {:ok, attrs} = SubscriptionProjection.decompose(sub)
      assert attrs.automatic_tax == false
      assert attrs.automatic_tax_status == nil
      assert attrs.automatic_tax_disabled_reason == nil
    end
  end
end
