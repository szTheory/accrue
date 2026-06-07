defmodule AccrueHostWeb.OrgBillingLiveTest do
  use AccrueHostWeb.ConnCase, async: false

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias AccrueHost.AccountsFixtures
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

    owner = AccountsFixtures.user_fixture()
    organization = AccountsFixtures.organization_fixture(%{owner: owner})
    outsider_org = AccountsFixtures.organization_fixture()

    %{owner: owner, organization: organization, outsider_org: outsider_org}
  end

  test "owner can start workspace billing for the active workspace only", %{
    conn: conn,
    owner: owner,
    organization: organization,
    outsider_org: outsider_org
  } do
    conn = log_in_user(conn, owner, active_organization_id: organization.id)

    {:ok, view, html} = live(conn, ~p"/app/billing")

    assert html =~ "Active workspace"
    assert html =~ organization.name
    assert html =~ "Plan changes and payment actions apply to this workspace only."
    assert html =~ "No workspace subscription yet"

    assert html =~
             "Choose a plan to start billing for this cohort workspace."

    html =
      render_click(view, "start_subscription", %{
        "plan" => "price_basic",
        "organization_id" => outsider_org.id,
        "operation_id" => "forged-start"
      })

    refute html =~
             "We couldn't complete that billing action for the active workspace. Check access, billing setup, or payment state, then try again."

    customer =
      Repo.one!(
        from(customer in Customer,
          where: customer.owner_type == "Organization" and customer.owner_id == ^organization.id,
          limit: 1
        )
      )

    assert customer.owner_type == "Organization"
    assert customer.owner_id == organization.id

    assert Repo.aggregate(
             from(customer in Customer,
               where:
                 customer.owner_type == "Organization" and customer.owner_id == ^outsider_org.id
             ),
             :count,
             :id
           ) == 0
  end

  test "no active organization shows locked copy and rejects mutations", %{
    conn: conn,
    owner: owner
  } do
    customer_count_before = organization_customer_count()
    subscription_count_before = organization_subscription_count()

    {:ok, view, html} =
      conn
      |> log_in_user(owner)
      |> live(~p"/app/billing")

    assert html =~ "Select an active workspace before managing billing."

    html =
      render_click(view, "start_subscription", %{
        "plan" => "price_basic",
        "organization_id" => Ecto.UUID.generate(),
        "operation_id" => "missing-org"
      })

    assert html =~ "Select an active workspace before managing billing."

    assert organization_customer_count() == customer_count_before
    assert organization_subscription_count() == subscription_count_before
  end

  test "members can review billing state but cannot mutate it", %{
    conn: conn,
    organization: organization
  } do
    member = AccountsFixtures.user_fixture()

    _membership =
      AccountsFixtures.organization_membership_fixture(%{
        organization: organization,
        user: member,
        role: :member
      })

    customer_count_before = organization_customer_count()
    subscription_count_before = organization_subscription_count()

    {:ok, view, html} =
      conn
      |> log_in_user(member, active_organization_id: organization.id)
      |> live(~p"/app/billing")

    assert html =~ "Billing is managed by workspace admins."
    assert html =~ "you can&#39;t change it."

    html =
      render_click(view, "start_subscription", %{
        "plan" => "price_basic",
        "organization_id" => organization.id,
        "operation_id" => "member-blocked"
      })

    assert html =~ "Billing is managed by workspace admins."
    assert html =~ "you can&#39;t change it."

    assert render(view) =~ "Billing is managed by workspace admins."
    assert render(view) =~ "you can&#39;t change it."

    assert organization_customer_count() == customer_count_before
    assert organization_subscription_count() == subscription_count_before
  end

  test "forged organization ids do not change the billed owner on follow-up mutations", %{
    conn: conn,
    owner: owner,
    organization: organization,
    outsider_org: outsider_org
  } do
    conn = log_in_user(conn, owner, active_organization_id: organization.id)
    {:ok, view, _html} = live(conn, ~p"/app/billing")

    _start_html =
      render_click(view, "start_subscription", %{
        "plan" => "price_basic",
        "organization_id" => outsider_org.id,
        "operation_id" => "forged-first"
      })

    html =
      render_submit(view, "update_tax_location", %{
        "tax_location" => %{
          "line1" => "27 Fredrick Ave",
          "city" => "Albany",
          "state" => "NY",
          "postal_code" => "12207",
          "country" => "US"
        },
        "organization_id" => outsider_org.id
      })

    refute html =~
             "We couldn't complete that billing action for the active workspace. Check access, billing setup, or payment state, then try again."

    customer =
      Repo.one!(
        from(customer in Customer,
          where: customer.owner_type == "Organization" and customer.owner_id == ^organization.id,
          limit: 1
        )
      )

    assert customer.owner_type == "Organization"
    assert customer.owner_id == organization.id

    assert Repo.aggregate(
             from(customer in Customer,
               where:
                 customer.owner_type == "Organization" and customer.owner_id == ^outsider_org.id
             ),
             :count,
             :id
           ) == 0
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

  defp organization_customer_count do
    Repo.aggregate(
      from(customer in Customer, where: customer.owner_type == "Organization"),
      :count,
      :id
    )
  end

  defp organization_subscription_count do
    Repo.aggregate(
      from(subscription in Subscription,
        join: customer in Customer,
        on: customer.id == subscription.customer_id,
        where: customer.owner_type == "Organization"
      ),
      :count,
      :id
    )
  end
end
