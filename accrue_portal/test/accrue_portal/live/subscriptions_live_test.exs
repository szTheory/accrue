defmodule AccruePortal.SubscriptionsLiveTest do
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

  test "subscriptions page stays scoped to the signed-in customer when canceling", %{conn: conn} do
    %{
      user: user,
      subscription: subscription,
      foreign_subscription: foreign_subscription
    } = dashboard_fixture!()

    conn = sign_in_conn(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions")

    assert html =~ subscription.processor_id
    assert html =~ "Lifecycle"
    assert html =~ "Active and renewing."
    refute html =~ foreign_subscription.processor_id

    html =
      view
      |> element("button[phx-value-id='#{subscription.id}']")
      |> render_click()

    assert html =~ subscription.processor_id
    assert TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
    refute TestRepo.get!(Subscription, foreign_subscription.id).cancel_at_period_end
  end

  test "subscriptions list renders past due lifecycle wording without leaking raw status", %{conn: conn} do
    user = user_fixture()

    %{subscription: subscription} =
      Accrue.Test.Factory.past_due_subscription(%{
        owner_type: AccruePortal.Fixtures.TestUser.__accrue__(:billable_type),
        owner_id: user.id,
        email: "portal-past-due-#{user.id}@example.com"
      })

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions")

    assert html =~ subscription.processor_id
    assert html =~ "Past due"
    assert html =~ "Past due. Access may change if payment recovery does not complete."
  end
end
