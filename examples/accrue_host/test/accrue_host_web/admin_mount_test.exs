defmodule AccrueHostWeb.AdminMountTest do
  # Serial: Factory + Fake processor ids must not race across cases.
  use AccrueHostWeb.ConnCase, async: false

  @moduletag :phase10

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueHost.Repo

  import Ecto.Query
  import Phoenix.LiveViewTest

  test "anonymous users are redirected away from /billing", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/billing")
  end

  test "signed-in non-admin users are redirected away from /billing", %{conn: conn} do
    user = AccrueHost.AccountsFixtures.user_fixture()
    conn = log_in_user(conn, user)

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/billing")
  end

  test "signed-in billing admins can mount /billing with forwarded owner scope session", %{
    conn: conn
  } do
    user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    organization = AccrueHost.AccountsFixtures.organization_fixture(%{owner: user})

    conn =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> Plug.Conn.put_session(:active_organization_slug, organization.slug)
      |> Plug.Conn.put_session(:active_organization_name, organization.name)
      |> Plug.Conn.put_session(:admin_organization_ids, [organization.id])

    user_token = get_session(conn, :user_token)
    user_id = user.id

    assert is_binary(user_token)

    assert %AccrueHost.Accounts.User{id: ^user_id, billing_admin: true} =
             AccrueHost.Auth.current_user(%{"user_token" => user_token})

    assert {:ok, view, html} = live(conn, "/billing")
    assert html =~ Copy.dashboard_display_headline()

    socket = live_socket(view)
    accrue_admin_session = socket.assigns.accrue_admin_session

    assert accrue_admin_session["user_token"] == user_token
    assert accrue_admin_session["active_organization_id"] == organization.id
    assert accrue_admin_session["active_organization_slug"] == organization.slug
    assert accrue_admin_session["active_organization_name"] == organization.name
    assert accrue_admin_session["admin_organization_ids"] == [organization.id]

    assert socket.assigns.current_owner_scope.mode == :global
    assert socket.assigns.current_owner_scope.platform_admin? == true
    assert socket.assigns.current_owner_scope.organization_id == nil
    assert socket.assigns.current_owner_scope.admin_org_ids == [organization.id]
  end

  test "billing admin can open mounted subscription detail drill", %{conn: conn} do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    cleanup_fake_billing_rows!()

    user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    organization = AccrueHost.AccountsFixtures.organization_fixture(%{owner: user})

    %{customer: customer, subscription: subscription} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: to_string(organization.id),
        email: "phase49-drill@example.com"
      })

    conn =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> Plug.Conn.put_session(:active_organization_slug, organization.slug)
      |> Plug.Conn.put_session(:active_organization_name, organization.name)
      |> Plug.Conn.put_session(:admin_organization_ids, [organization.id])

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "/customers/#{customer.id}"
    assert html =~ Copy.subscription_drill_related_card_title()
  end

  test "out-of-scope organization routes do not resolve as a valid owner scope", %{conn: conn} do
    user = AccrueHost.AccountsFixtures.user_fixture()
    allowed_org = AccrueHost.AccountsFixtures.organization_fixture(%{owner: user})
    outsider_org = AccrueHost.AccountsFixtures.organization_fixture()

    conn =
      conn
      |> log_in_user(user)
      |> Plug.Conn.put_session(:active_organization_id, allowed_org.id)
      |> Plug.Conn.put_session(:active_organization_slug, allowed_org.slug)
      |> Plug.Conn.put_session(:active_organization_name, allowed_org.name)
      |> Plug.Conn.put_session(:admin_organization_ids, [allowed_org.id])

    session =
      AccrueAdmin.Router.__session__(
        conn,
        [
          :user_token,
          :active_organization_id,
          :active_organization_slug,
          :active_organization_name,
          :admin_organization_ids
        ],
        "/billing"
      )

    assert {:ok, owner_scope} = OwnerScope.resolve(session, %{"org" => allowed_org.slug})
    assert owner_scope.mode == :organization
    assert owner_scope.organization_id == allowed_org.id
    assert owner_scope.organization_slug == allowed_org.slug
    assert owner_scope.organization_display_name == allowed_org.name
    assert owner_scope.platform_admin? == false

    assert {:error, :not_found} = OwnerScope.resolve(session, %{"org" => outsider_org.slug})
  end

  defp live_socket(view) do
    view.pid
    |> :sys.get_state()
    |> Map.fetch!(:socket)
  end

  defp cleanup_fake_billing_rows! do
    Repo.delete_all(
      from(item in SubscriptionItem,
        join: subscription in Subscription,
        on: subscription.id == item.subscription_id,
        where: like(subscription.processor_id, "sub_fake_%")
      )
    )

    Repo.delete_all(from(s in Subscription, where: like(s.processor_id, "sub_fake_%")))
    Repo.delete_all(from(c in Customer, where: like(c.processor_id, "cus_fake_%")))
  end
end
