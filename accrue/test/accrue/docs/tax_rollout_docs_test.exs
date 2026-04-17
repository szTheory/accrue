defmodule Accrue.Docs.TaxRolloutDocsTest do
  use ExUnit.Case, async: true

  @live_guide "../guides/testing-live-stripe.md"
  @troubleshooting_guide "guides/troubleshooting.md"
  @required_phrases [
    "customer_tax_location_invalid",
    "does not retroactively update existing subscriptions",
    "payment links",
    "customer_update[address]=auto",
    "customer_update[shipping]=auto"
  ]

  test "live Stripe guide keeps the tax rollout migration warnings explicit" do
    guide = File.read!(@live_guide)

    Enum.each(@required_phrases, fn phrase ->
      assert guide =~ phrase
    end)
  end

  test "troubleshooting guide points operators at the live parity path" do
    guide = File.read!(@troubleshooting_guide)

    assert guide =~ "guides/testing-live-stripe.md"
  end
end
