defmodule AccrueHostWeb.AdminMountTest do
  use AccrueHostWeb.ConnCase, async: true

  @moduletag :phase10

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

  test "signed-in billing admins can mount /billing with forwarded user_token", %{conn: conn} do
    user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    conn = log_in_user(conn, user)
    user_token = get_session(conn, :user_token)
    user_id = user.id

    assert is_binary(user_token)

    assert %AccrueHost.Accounts.User{id: ^user_id, billing_admin: true} =
             AccrueHost.Auth.current_user(%{"user_token" => user_token})

    assert {:ok, _view, html} = live(conn, "/billing")
    assert html =~ "Local billing projections at a glance"
  end
end
