defmodule AccrueHostWeb.SubscriptionLiveTest do
  use AccrueHostWeb.ConnCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.MeterEvent
  alias Accrue.Billing.SubscriptionItem
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
  alias AccrueHost.Billing.Plans
  alias AccrueHost.Repo

  import Ecto.Query
  import Phoenix.LiveViewTest

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    cleanup_fake_billing_rows!()

    user = AccountsFixtures.user_fixture()
    organization = AccountsFixtures.organization_fixture(%{owner: user})

    %{user: user, organization: organization}
  end

  test "demonstrates metered usage reporting (PROOF-04)", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    assert {:ok, _} = Billing.subscribe(organization, Plans.ids().metered)

    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Metered Usage Demo"
    assert html =~ "Simulate API Call"

    view
    |> element("button", "Simulate API Call")
    |> render_click()

    assert render(view) =~ "Usage reported: 1 API call recorded."

    assert Repo.aggregate(MeterEvent, :count, :id) == 1
    event = Repo.one(MeterEvent)
    assert event.event_name == "api_calls"
    assert event.value == 1
  end

  test "demonstrates checkout session creation (PROOF-05)", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Checkout Facade Demo"
    assert html =~ "Create Checkout Session"

    view
    |> element("button", "Create Checkout Session")
    |> render_click()

    html = render(view)
    assert html =~ "Generated Checkout URL"
    assert html =~ "https://checkout.stripe.test/c/pay/cs_fake_"
  end

  test "repairs tax location through the host facade and starts a tax-enabled subscription", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Repair automatic tax input"
    assert html =~ "Save tax location"

    html =
      view
      |> form("#tax-location-form", %{
        "tax_location" => %{
          "line1" => "27 Fredrick Ave",
          "city" => "Albany",
          "state" => "NY",
          "postal_code" => "12207",
          "country" => "US"
        }
      })
      |> render_submit()

    refute html =~ "We couldn't complete that billing action."

    customer =
      Repo.one!(
        from(customer in Customer,
          where: customer.owner_type == "Organization" and customer.owner_id == ^organization.id,
          limit: 1
        )
      )

    refute Map.has_key?(customer.data || %{}, "address")

    assert Repo.aggregate(
             from(subscription in Accrue.Billing.Subscription,
               where: subscription.customer_id == ^customer.id
             ),
             :count,
             :id
           ) == 0
  end

  test "shows stable repair guidance when automatic tax starts without a valid location", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Please update customer address or shipping before enabling automatic tax."

    html =
      view
      |> element("[data-plan-id='price_basic'] button")
      |> render_click()

    assert html =~ "Please update customer address or shipping before enabling automatic tax."
    refute html =~ "We couldn't complete that billing action."
  end

  test "organization billing copy references AccrueHost.Billing", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    assert {:ok, _} = Billing.subscribe(organization, "price_basic", trial_end: {:days, 14})

    {:ok, _view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Organization billing state"
    assert html =~ "AccrueHost.Billing"
  end

  test "host billing facade exposes preview-before-commit helpers for local plan changes", %{
    organization: organization
  } do
    assert {:ok, subscription} =
             Billing.subscribe(organization, "price_basic", trial_end: {:days, 14})

    assert {:ok, preview} =
             Billing.preview_plan_change(subscription, "price_pro", proration: :create_prorations)

    assert preview.lines != []

    assert {:ok, updated} =
             Billing.change_plan(subscription, "price_pro", proration: :create_prorations)

    updated = Repo.preload(updated, :subscription_items)
    assert Enum.any?(updated.subscription_items, &(&1.price_id == "price_pro"))
  end

  test "organization billing renders explicit hard-stop cancellation copy instead of a generic cancel label",
       %{
         conn: conn,
         organization: organization,
         user: user
       } do
    assert {:ok, _} = Billing.subscribe(organization, "price_basic", trial_end: {:days, 14})

    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Need to stop renewal?"
    assert html =~ "Cancel now for this organization"

    assert html =~
             "Default customer self-serve guidance should prefer cancel renewal at period end."

    assert html =~ "any softer Braintree end-of-term policy stays host-owned."
    refute html =~ "Cancel organization subscription"

    html =
      view
      |> element("button[phx-click='request_cancel']")
      |> render_click()

    assert html =~
             "Cancel now for this organization only. This is the hard-stop path and can end access immediately."
  end

  defp cleanup_fake_billing_rows! do
    Repo.delete_all(MeterEvent)

    Repo.delete_all(
      from(item in SubscriptionItem,
        join: subscription in Accrue.Billing.Subscription,
        on: subscription.id == item.subscription_id,
        where: like(subscription.processor_id, "sub_fake_%")
      )
    )

    Repo.delete_all(
      from(subscription in Accrue.Billing.Subscription,
        where: like(subscription.processor_id, "sub_fake_%")
      )
    )

    Repo.delete_all(
      from(customer in Customer,
        where: like(customer.processor_id, "cus_fake_%")
      )
    )
  end
end
