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
    assert html =~ "Lifecycle summary"
    assert html =~ "Active and renewing."
    assert html =~ "Cancel renewal"
    refute html =~ "Keep subscription"

    html =
      view
      |> element("button[phx-click='toggle_cancel_confirmation']")
      |> render_click()

    assert html =~ "Keep subscription"
    assert html =~ "End at period end"

    html =
      view
      |> element("button[phx-click='cancel']")
      |> render_click()

    assert html =~ subscription.processor_id
    assert html =~ "Cancel renewal scheduled"
    assert TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
  end

  test "subscription detail renders canceling lifecycle wording from shared copy helpers", %{conn: conn} do
    user = user_fixture()

    %{subscription: subscription} =
      Accrue.Test.Factory.canceling_subscription(%{
        owner_type: AccruePortal.Fixtures.TestUser.__accrue__(:billable_type),
        owner_id: user.id,
        email: "portal-canceling-#{user.id}@example.com"
      })

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Canceling"
    assert html =~ "Cancel renewal scheduled. Access ends at the current period end."
    assert html =~ "Access ends on the current period end date shown below."
  end
end
