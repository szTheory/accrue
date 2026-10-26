defmodule AccruePortal.SubscriptionsLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.Subscription
  alias AccruePortal.{BillingReadModel, TestRepo}

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
    assert html =~ "Billing reports this subscription as active."
    assert html =~ "Preview supported plan changes from details before you confirm."

    assert html =~
             "End at period end to turn off renewal now and keep billing through the current period."

    refute html =~ foreign_subscription.processor_id

    html =
      view
      |> element(
        "button[phx-click='toggle_cancel_confirmation'][phx-value-id='#{subscription.id}']"
      )
      |> render_click()

    assert html =~ "Keep subscription"
    assert html =~ subscription.processor_id
    assert html =~ "Billing for"
    refute TestRepo.get!(Subscription, subscription.id).cancel_at_period_end

    html =
      view
      |> element("button[phx-click='cancel'][phx-value-id='#{subscription.id}']")
      |> render_click()

    assert html =~ "Cancel renewal scheduled to stop at the current billing period end."

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
    assert html =~ "Payment is past due. Review billing details or update the payment method."
  end

  test "subscriptions list labels observed lifecycle states and preserves unknown observations",
       %{
         conn: conn
       } do
    user = user_fixture()

    %{customer: customer} =
      Accrue.Test.Factory.customer(%{
        owner_type: AccruePortal.Fixtures.TestUser.__accrue__(:billable_type),
        owner_id: user.id,
        email: "portal-lifecycle-#{user.id}@example.com"
      })

    expected = [
      {:trialing, "Trialing", "A trial is in progress."},
      {:incomplete, "Incomplete", "Subscription setup is incomplete."},
      {:unpaid, "Unpaid", "Billing reports this subscription as unpaid."},
      {:past_due, "Past due",
       "Payment is past due. Review billing details or update the payment method."},
      {:active, "Active", "Billing reports this subscription as active."},
      {:canceled, "Ended", "Billing reports that this subscription has ended."}
    ]

    for {status, _label, _summary} <- expected do
      read_only_subscription_fixture!(customer, %{status: status, current_period_end: nil})
    end

    previous_reader = Application.get_env(:accrue_portal, :subscription_reader)

    Application.put_env(:accrue_portal, :subscription_reader, fn read_customer ->
      unknown = %Subscription{
        id: Ecto.UUID.generate(),
        customer_id: read_customer.id,
        processor: "fake",
        processor_id: "sub-unknown-lifecycle",
        status: nil,
        cancel_at_period_end: false
      }

      {:ok, BillingReadModel.subscriptions(read_customer) ++ [unknown]}
    end)

    on_exit(fn ->
      if is_nil(previous_reader),
        do: Application.delete_env(:accrue_portal, :subscription_reader),
        else: Application.put_env(:accrue_portal, :subscription_reader, previous_reader)
    end)

    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live(conn, "/billing/subscriptions")

    for {_status, label, summary} <- expected do
      assert html =~ label
      assert html =~ summary
    end

    assert html =~ "Unknown"
    assert html =~ "Lifecycle status unavailable."

    refute html =~ "Access may change"
    refute html =~ "Access stays on"
  end

  test "a successful empty subscription read uses the empty state", %{conn: conn} do
    user = user_fixture()
    conn = sign_in_conn(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions")

    assert has_element?(view, ".portal-empty strong", "No active subscriptions")
    assert html =~ "When you subscribe to a plan, it will appear here."
    refute html =~ "Subscriptions unavailable"
  end

  test "an unsupported processor exposes no subscription change actions", %{conn: conn} do
    %{user: user, customer: customer} = subscription_bundle_fixture!()

    subscription =
      read_only_subscription_fixture!(customer, %{
        processor: "unsupported-provider",
        processor_id: "sub-unsupported-provider"
      })

    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Active"
    refute html =~ "toggle_cancel_confirmation"
    refute html =~ "Preview plan change"
  end

  test "cancellation rechecks eligibility after the confirmation was rendered", %{conn: conn} do
    %{user: user, subscription: subscription} = subscription_bundle_fixture!()
    conn = sign_in_conn(conn, user)
    assert {:ok, view, _html} = live(conn, "/billing/subscriptions")

    view
    |> element(
      "button[phx-click='toggle_cancel_confirmation'][phx-value-id='#{subscription.id}']"
    )
    |> render_click()

    subscription
    |> Subscription.changeset(%{status: :canceled})
    |> TestRepo.update!()

    provider_updates_before = Accrue.Processor.Fake.call_count(:update_subscription)

    html =
      view
      |> element("button[phx-click='cancel'][phx-value-id='#{subscription.id}']")
      |> render_click()

    assert html =~
             "Cancellation is no longer available for this subscription. Refresh and try again."

    assert TestRepo.get!(Subscription, subscription.id).status == :canceled
    assert Accrue.Processor.Fake.call_count(:update_subscription) == provider_updates_before
  end

  test "subscriptions list confirms the same immediate Braintree consequence shown on detail",
       %{conn: conn} do
    %{user: user, subscription: source} = subscription_bundle_fixture!()

    subscription =
      source
      |> Subscription.changeset(%{processor: "braintree"})
      |> TestRepo.update!()

    conn = sign_in_conn(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions")

    assert html =~ subscription.processor_id

    assert html =~
             "Braintree cancels this subscription immediately. Ask your app host about application access."

    assert html =~ "Plan changes for this subscription are handled by your account team."
    assert html =~ ~s(href="/billing/subscriptions/#{subscription.id}?context_pin=)
    assert html =~ ~s(phx-click="toggle_cancel_confirmation" phx-value-id="#{subscription.id}")
    assert html =~ "Cancel now"

    before = TestRepo.get!(Subscription, subscription.id)

    html =
      view
      |> element(
        "button[phx-click='toggle_cancel_confirmation'][phx-value-id='#{subscription.id}']"
      )
      |> render_click()

    assert html =~ "Keep subscription"
    assert TestRepo.get!(Subscription, subscription.id).status == before.status

    assert {:ok, _detail_view, detail_html} =
             live(conn, "/billing/subscriptions/#{subscription.id}")

    assert detail_html =~
             "Braintree cancels this subscription immediately. Ask your app host about application access."
  end

  test "canceled subscriptions show lifecycle state but no cancellation or plan-change actions",
       %{
         conn: conn
       } do
    %{user: user, customer: customer} = subscription_bundle_fixture!()
    subscription = read_only_subscription_fixture!(customer, %{status: :canceled})
    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Ended"
    assert html =~ "Billing reports that this subscription has ended."
    refute html =~ "toggle_cancel_confirmation"
    refute html =~ "Preview plan change"
  end

  test "failed subscription reads render unavailable instead of the empty state", %{conn: conn} do
    %{user: user} = subscription_bundle_fixture!()
    previous_reader = Application.get_env(:accrue_portal, :subscription_reader)

    Application.put_env(:accrue_portal, :subscription_reader, fn _customer ->
      {:error, :offline}
    end)

    on_exit(fn ->
      if is_nil(previous_reader),
        do: Application.delete_env(:accrue_portal, :subscription_reader),
        else: Application.put_env(:accrue_portal, :subscription_reader, previous_reader)
    end)

    conn = sign_in_conn(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions")

    assert html =~ "Subscriptions unavailable"
    assert html =~ "Subscriptions could not be loaded for this account. Try again in a moment."
    refute has_element?(view, ".portal-empty")
  end
end
