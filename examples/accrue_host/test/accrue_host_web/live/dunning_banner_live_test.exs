defmodule AccrueHostWeb.DunningBannerLiveTest do
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

  test "shows the default dunning banner when the active org is past-due in a dunning campaign (banner-ON)",
       %{conn: conn, organization: organization, user: user} do
    assert {:ok, _sub} = Billing.subscribe(organization, "price_basic")

    {:ok, %{subscription: subscription}} = Billing.billing_state_for(organization)

    now = DateTime.utc_now()

    subscription
    |> Accrue.Billing.Subscription.force_status_changeset(%{
      status: :past_due,
      past_due_since: now,
      dunning_campaign_started_at: now
    })
    |> Repo.update!()

    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Action Required"
    assert has_element?(view, ".accrue-default-dunning-banner")
  end

  test "does not show the dunning banner when the active org is healthy (banner-OFF)", %{
    conn: conn,
    organization: organization,
    user: user
  } do
    assert {:ok, _sub} = Billing.subscribe(organization, "price_basic")

    {:ok, view, html} =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    refute html =~ "Action Required"
    refute has_element?(view, ".accrue-default-dunning-banner")
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
