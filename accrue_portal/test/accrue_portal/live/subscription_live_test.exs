defmodule AccruePortal.SubscriptionLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.Subscription
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)
    end)

    :ok
  end

  test "subscription detail stays customer-scoped through cancel confirmation", %{conn: conn} do
    %{user: user, subscription: subscription} = subscription_bundle_fixture!()
    conn = sign_in_conn(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ subscription.processor_id
    refute html =~ "Keep subscription"

    html =
      view
      |> element("button[phx-click='toggle_cancel_confirmation']")
      |> render_click()

    assert html =~ "Keep subscription"

    html =
      view
      |> element("button[phx-click='cancel']")
      |> render_click()

    assert html =~ subscription.processor_id
    assert TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
  end
end
