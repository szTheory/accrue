defmodule Accrue.Billing.PaymentIntentTest do
  @moduledoc """
  Plan 06 Task 1: `Accrue.Billing.create_payment_intent/2` — thin
  IntentResult-wrapped wrapper around `Processor.create_payment_intent/2`.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing

  test "create_payment_intent returns {:ok, pi} on success" do
    assert {:ok, pi} =
             Billing.create_payment_intent(%{amount: 1000, currency: "usd"})

    assert (pi[:object] || pi["object"]) == "payment_intent"
    assert (pi[:status] || pi["status"]) in [:succeeded, "succeeded"]
  end

  test "requires_action_test flag yields next_action.type = use_stripe_sdk" do
    assert {:ok, :requires_action, pi} =
             Billing.create_payment_intent(%{
               amount: 1000,
               currency: "usd",
               requires_action_test: true
             })

    status = pi[:status] || pi["status"]
    assert status in ["requires_action", :requires_action]

    next_action = pi[:next_action] || pi["next_action"]
    assert (next_action[:type] || next_action["type"]) == "use_stripe_sdk"
  end

  test "create_payment_intent!/2 raises on requires_action" do
    assert_raise Accrue.ActionRequiredError, fn ->
      Billing.create_payment_intent!(%{
        amount: 1000,
        currency: "usd",
        requires_action_test: true
      })
    end
  end
end
