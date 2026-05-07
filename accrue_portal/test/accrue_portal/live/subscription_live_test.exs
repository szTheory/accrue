defmodule AccruePortal.SubscriptionLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.{Customer, Subscription}
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
    assert html =~ "Access ends at the current period end."
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

  test "subscription detail keeps Braintree hard-stop wording separate from host-owned renewal policy",
       %{conn: conn} do
    user = user_fixture()

    customer =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: AccruePortal.Fixtures.TestUser.__accrue__(:billable_type),
        owner_id: user.id,
        processor: "braintree",
        processor_id: "cus_bt_portal_detail",
        email: "portal-braintree-#{user.id}@example.com",
        metadata: %{},
        data: %{}
      })
      |> TestRepo.insert!()

    subscription =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id: "sub_bt_portal_detail",
        status: :active,
        currency: "usd",
        current_period_start: DateTime.add(DateTime.utc_now(), -86_400, :second),
        current_period_end: DateTime.add(DateTime.utc_now(), 2_592_000, :second)
      })
      |> TestRepo.insert!()

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Need to stop now?"
    assert html =~ "Cancel now"

    assert html =~
             "Braintree supports Cancel now through Accrue.Billing.cancel/2. If you need end-of-term non-renewal instead, keep that softer policy in your host app."

    assert html =~
             "Braintree immediate cancellation can end access now. Softer end-of-term handling belongs in your host app."

    refute html =~ "Cancel renewal"
  end
end
