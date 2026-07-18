defmodule AccrueHostWeb.SubscriptionLiveTest do
  use AccrueHostWeb.ConnCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.MeterEvent
  alias Accrue.Billing.SubscriptionItem
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
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

  test "creates a checkout handoff link from workspace billing", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Checkout handoff"
    assert html =~ "Create checkout link"

    view
    |> element("button", "Create checkout link")
    |> render_click()

    html = render(view)
    assert html =~ "Checkout link"
    assert html =~ "https://checkout.stripe.test/c/pay/cs_fake_"
  end

  test "workspace billing copy stays customer-facing", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    assert {:ok, _} = Billing.subscribe(organization, "price_basic", trial_end: {:days, 14})

    {:ok, _view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Workspace billing"
    assert html =~ "This workspace is subscribed"
    assert html =~ "Launch"
    refute html =~ "Organization billing state"
    refute html =~ "AccrueHost.Billing"
    refute html =~ "PROOF-"
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

  test "workspace billing renders explicit immediate cancellation copy",
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

    assert html =~ "Need to stop access?"
    assert html =~ "Cancel workspace subscription"

    assert html =~
             "Use immediate cancellation when the workspace should stop billing and access right away."

    html =
      view
      |> element("button[phx-click='request_cancel']")
      |> render_click()

    assert html =~ "Cancel now for this workspace only. Access can end immediately."
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
