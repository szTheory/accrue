defmodule AccrueHostWeb.EntitlementDiagnosticsLiveTest do
  use AccrueHostWeb.ConnCase, async: false

  alias AccrueHost.Repo

  import Phoenix.LiveViewTest

  test "anonymous and non-operator visitors cannot open diagnostics", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/users/log-in"}}} =
             live(conn, "/app/entitlements/diagnostics")

    user = AccrueHost.AccountsFixtures.user_fixture()

    assert {:error, {:redirect, %{to: "/"}}} =
             conn |> log_in_user(user) |> live("/app/entitlements/diagnostics")
  end

  test "an operator sees bounded unavailable state without internal account data", %{conn: conn} do
    user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    {:ok, _view, html} =
      conn
      |> log_in_user(user)
      |> live("/app/entitlements/diagnostics")

    assert html =~ "Access diagnostic"
    assert html =~ "Access check unavailable"
    refute html =~ user.email
  end
end
