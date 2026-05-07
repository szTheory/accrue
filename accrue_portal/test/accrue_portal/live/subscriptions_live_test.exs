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
    assert html =~ "Preview supported plan changes from details before you confirm."
    refute html =~ foreign_subscription.processor_id

    html =
      view
      |> element("button[phx-value-id='#{subscription.id}']")
      |> render_click()

    assert html =~ subscription.processor_id
    assert html =~ "Cancel renewal scheduled. Access ends at the current period end."
    assert TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
    refute TestRepo.get!(Subscription, foreign_subscription.id).cancel_at_period_end
    refute html =~ "Cancel subscription"
  end

  test "subscriptions list renders past due lifecycle wording without leaking raw status", %{
    conn: conn
  } do
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

  test "subscriptions list routes Braintree cancellation through the detail page instead of a one-click hard stop",
       %{conn: conn} do
    user = user_fixture()

    %{customer: customer} =
      Accrue.Test.Factory.customer(%{
        owner_type: AccruePortal.Fixtures.TestUser.__accrue__(:billable_type),
        owner_id: user.id,
        email: "portal-braintree-list-#{user.id}@example.com",
        processor: "braintree",
        processor_id: "cus_bt_list_#{System.unique_integer([:positive])}"
      })

    subscription =
      read_only_subscription_fixture!(customer, %{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_bt_list_#{System.unique_integer([:positive])}",
        status: :active
      })

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions")

    assert html =~ subscription.processor_id
    assert html =~ "Braintree immediate cancellation can end access now."
    assert html =~ "Plan changes stay host-managed for this Braintree subscription."
    assert html =~ ~s(href="/billing/subscriptions/#{subscription.id}")
    refute html =~ ~s(phx-value-id="#{subscription.id}")
    refute html =~ "Cancel now"
  end
end
