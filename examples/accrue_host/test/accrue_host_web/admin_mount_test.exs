defmodule AccrueHostWeb.AdminMountTest do
  use AccrueHostWeb.ConnCase, async: true

  @moduletag :phase10

  alias AccrueAdmin.OwnerScope
  alias AccrueHost.Repo

  import Phoenix.LiveViewTest

  test "anonymous users are redirected away from /billing", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/billing")
  end

  test "signed-in non-admin users are redirected away from /billing", %{conn: conn} do
    user = AccrueHost.AccountsFixtures.user_fixture()
    conn = log_in_user(conn, user)

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/billing")
  end

  test "signed-in billing admins can mount /billing with forwarded owner scope session", %{conn: conn} do
    user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    organization = AccrueHost.AccountsFixtures.organization_fixture(%{owner: user})

    conn =
      conn
      |> log_in_user(user, active_organization_id: organization.id)
      |> Plug.Conn.put_session(:active_organization_slug, organization.slug)
      |> Plug.Conn.put_session(:admin_organization_ids, [organization.id])

    user_token = get_session(conn, :user_token)
    user_id = user.id

    assert is_binary(user_token)

    assert %AccrueHost.Accounts.User{id: ^user_id, billing_admin: true} =
             AccrueHost.Auth.current_user(%{"user_token" => user_token})

    assert {:ok, view, html} = live(conn, "/billing")
    assert html =~ "Local billing projections at a glance"

    socket = live_socket(view)
    accrue_admin_session = socket.assigns.accrue_admin_session

    assert accrue_admin_session["user_token"] == user_token
    assert accrue_admin_session["active_organization_id"] == organization.id
    assert accrue_admin_session["active_organization_slug"] == organization.slug
    assert accrue_admin_session["admin_organization_ids"] == [organization.id]

    assert socket.assigns.current_owner_scope.mode == :global
    assert socket.assigns.current_owner_scope.platform_admin? == true
    assert socket.assigns.current_owner_scope.organization_id == nil
    assert socket.assigns.current_owner_scope.admin_org_ids == [organization.id]
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
      |> Plug.Conn.put_session(:admin_organization_ids, [allowed_org.id])

    session =
      AccrueAdmin.Router.__session__(
        conn,
        [:user_token, :active_organization_id, :active_organization_slug, :admin_organization_ids],
        "/billing"
      )

    assert {:ok, owner_scope} = OwnerScope.resolve(session, %{"org" => allowed_org.slug})
    assert owner_scope.mode == :organization
    assert owner_scope.organization_id == allowed_org.id
    assert owner_scope.organization_slug == allowed_org.slug
    assert owner_scope.platform_admin? == false

    assert {:error, :not_found} = OwnerScope.resolve(session, %{"org" => outsider_org.slug})
  end

  defp live_socket(view) do
    view.pid
    |> :sys.get_state()
    |> Map.fetch!(:socket)
  end
end
