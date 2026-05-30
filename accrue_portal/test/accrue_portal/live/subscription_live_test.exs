defmodule AccruePortal.SubscriptionLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures
  import Ecto.Query

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

  test "subscription detail previews and commits a bounded plan change for supported providers",
       %{conn: conn} do
    %{user: user, subscription: subscription} = subscription_bundle_fixture!()
    conn = sign_in_conn(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Need to change plans?"
    assert html =~ "Preview plan change"
    assert html =~ "Current plan"
    assert html =~ "price_basic"

    html =
      view
      |> form("#plan-change-form", %{"plan_change" => %{"price_id" => "price_pro"}})
      |> render_submit()

    assert html =~ "Preview upcoming invoice"
    assert html =~ "Preview total"
    assert html =~ "Confirm plan change"
    assert html =~ "Choose a different plan"

    html =
      view
      |> element("button[phx-click='confirm_plan_change']")
      |> render_click()

    assert html =~ "Current plan"
    assert html =~ "price_pro"

    assert "price_pro" ==
             SubscriptionItem
             |> where([item], item.subscription_id == ^subscription.id)
             |> TestRepo.one!()
             |> Map.fetch!(:price_id)
  end

  test "subscription detail renders canceling lifecycle wording from shared copy helpers", %{
    conn: conn
  } do
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
    assert html =~ "Plan changes stay host-managed here"

    assert html =~
             "Braintree supports Cancel now through Accrue.Billing.cancel/2. If you need end-of-term non-renewal instead, keep that softer policy in your host app."

    assert html =~
             "Braintree immediate cancellation can end access now. Softer end-of-term handling belongs in your host app."

    assert html =~
             "Braintree plan changes can stay bounded to host-managed next steps. This mounted portal does not preview upcoming invoices for Braintree or offer direct self-serve swaps here."

    refute html =~ "Cancel renewal"
    refute html =~ "Preview plan change"
  end

  describe "recovery banner (DUN-06)" do
    test "renders a recovery banner with heading and CTA for a past-due subscription", %{
      conn: conn
    } do
      user = user_fixture()
      subscription = insert_recovery_subscription!(user, processor: "stripe", status: :past_due)
      conn = sign_in_conn(conn, user)

      assert {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      assert has_element?(view, "[data-role='subscription-recovery-banner']")

      assert has_element?(
               view,
               "[data-role='subscription-recovery-banner'] h2",
               "Your payment didn't go through"
             )

      assert has_element?(
               view,
               "[data-role='subscription-recovery-banner'] p",
               "We couldn't process your most recent payment. Update your payment method to keep your subscription active."
             )

      assert has_element?(
               view,
               "[data-role='subscription-recovery-banner'] a.portal-button-primary",
               "Update payment method"
             )
    end

    test "renders no recovery banner for a healthy subscription with no active campaign", %{
      conn: conn
    } do
      user = user_fixture()
      subscription = insert_recovery_subscription!(user, processor: "stripe", status: :active)
      conn = sign_in_conn(conn, user)

      assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      refute has_element?(view, "[data-role='subscription-recovery-banner']")
      refute html =~ "Your payment didn't go through"
    end

    test "deep-links a past-due Braintree banner CTA to the in-portal add-payment-method route",
         %{
           conn: conn
         } do
      user = user_fixture()

      subscription =
        insert_recovery_subscription!(user, processor: "braintree", status: :past_due)

      conn = sign_in_conn(conn, user)

      assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      href = recovery_cta_href(html)
      assert String.ends_with?(href, "/payment-methods/new")
    end

    test "deep-links a past-due non-Braintree banner CTA to the in-portal payment-methods list",
         %{
           conn: conn
         } do
      user = user_fixture()
      subscription = insert_recovery_subscription!(user, processor: "stripe", status: :past_due)
      conn = sign_in_conn(conn, user)

      assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      href = recovery_cta_href(html)
      assert String.ends_with?(href, "/payment-methods")
      refute String.ends_with?(href, "/payment-methods/new")
    end
  end

  defp insert_recovery_subscription!(user, opts) do
    processor = Keyword.fetch!(opts, :processor)
    status = Keyword.fetch!(opts, :status)

    customer =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: AccruePortal.Fixtures.TestUser.__accrue__(:billable_type),
        owner_id: user.id,
        processor: processor,
        processor_id: "cus_recovery_#{processor}_#{user.id}",
        email: "portal-recovery-#{user.id}@example.com",
        metadata: %{},
        data: %{}
      })
      |> TestRepo.insert!()

    %Subscription{}
    |> Subscription.changeset(%{
      customer_id: customer.id,
      processor: processor,
      processor_id: "sub_recovery_#{processor}_#{user.id}",
      status: status,
      currency: "usd",
      current_period_start: DateTime.add(DateTime.utc_now(), -86_400, :second),
      current_period_end: DateTime.add(DateTime.utc_now(), 2_592_000, :second)
    })
    |> TestRepo.insert!()
  end

  defp recovery_cta_href(html) do
    [_, href] =
      Regex.run(
        ~r/data-role="subscription-recovery-banner".*?<a[^>]*href="([^"]+)"/s,
        html
      )

    href
  end
end
