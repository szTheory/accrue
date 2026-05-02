defmodule AccruePortal.SubscriptionsLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.Subscription
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures

  test "subscriptions page stays scoped to the signed-in customer when canceling", %{conn: conn} do
    %{
      user: user,
      subscription: subscription,
      foreign_subscription: foreign_subscription
    } = dashboard_fixture!()

    conn = sign_in_customer(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions")

    assert html =~ subscription.processor_id
    refute html =~ foreign_subscription.processor_id

    html =
      view
      |> element("button[phx-value-id='#{subscription.id}']")
      |> render_click()

    assert html =~ "Subscription will cancel at the end of the current period."
    assert TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
    refute TestRepo.get!(Subscription, foreign_subscription.id).cancel_at_period_end
  end
end
