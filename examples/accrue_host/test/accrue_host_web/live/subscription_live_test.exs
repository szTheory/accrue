defmodule AccrueHostWeb.SubscriptionLiveTest do
  use AccrueHostWeb.ConnCase, async: false

  alias Accrue.Billing.Customer
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

  defp cleanup_fake_billing_rows! do
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
