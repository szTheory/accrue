defmodule AccruePortal.SubscriptionLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.Subscription
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures

  test "subscription detail stays customer-scoped through cancel confirmation", %{conn: conn} do
    %{user: user, subscription: subscription} = subscription_bundle_fixture!()
    conn = sign_in_customer(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ subscription.processor_id
    assert html =~ "Keep subscription"

    html =
      view
      |> element("button[phx-click='toggle_cancel_confirmation']")
      |> render_click()

    assert html =~ "Keep subscription"

    html =
      view
      |> element("button[phx-click='cancel']")
      |> render_click()

    assert html =~ "Subscription will cancel at the end of the current period."
    assert TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
  end
end
