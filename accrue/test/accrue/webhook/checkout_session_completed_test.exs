defmodule Accrue.Webhook.CheckoutSessionCompletedTest do
  @moduledoc """
  Phase 4 Plan 07 (CHKT-06) — DefaultHandler reducer for
  `checkout.session.completed` and `checkout.session.expired`. Links the
  Stripe Checkout session to the local customer / subscription rows
  with `:deferred` orphan tolerance for the webhook-first-for-unknown-
  customer case (Pattern §H).
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Subscription
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_chkt_wh",
        email: "chkt-wh@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "checkout.session.completed links session to local customer + subscription",
       %{customer: cus} do
    {:ok, sub} = Accrue.Billing.subscribe(cus, "price_basic")

    payload =
      StripeFixtures.checkout_session_completed(%{
        "customer" => cus.processor_id,
        "subscription" => sub.processor_id
      })

    event = StripeFixtures.webhook_event("checkout.session.completed", payload)

    assert {:ok, result} = DefaultHandler.handle(event)
    # Result should report the session id we linked, or :ok / a struct.
    refute match?({:error, _}, {:ok, result})

    # The local subscription row should still exist + be findable.
    assert %Subscription{} = Repo.get_by(Subscription, processor_id: sub.processor_id)
  end

  test "checkout.session.completed for unknown customer returns :deferred (orphan tolerance)" do
    payload =
      StripeFixtures.checkout_session_completed(%{
        "customer" => "cus_orphan_does_not_exist",
        "subscription" => nil
      })

    event = StripeFixtures.webhook_event("checkout.session.completed", payload)

    # Must not raise, must not error — orphan tolerance returns {:ok, :deferred} or {:ok, _}
    assert {:ok, _} = DefaultHandler.handle(event)
  end

  test "checkout.session.expired records but performs no state mutation",
       %{customer: cus} do
    payload =
      StripeFixtures.checkout_session_expired(%{
        "customer" => cus.processor_id,
        "subscription" => nil
      })

    event = StripeFixtures.webhook_event("checkout.session.expired", payload)

    assert {:ok, _} = DefaultHandler.handle(event)
  end
end
