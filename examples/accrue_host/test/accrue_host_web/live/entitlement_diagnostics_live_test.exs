defmodule AccrueHostWeb.EntitlementDiagnosticsLiveTest do
  use AccrueHostWeb.ConnCase, async: false

  alias Accrue.Entitlements.Account
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

  test "an operator confirms a bounded repair and receives focus-safe completion guidance", %{
    conn: conn
  } do
    user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    {:ok, _account} = Account.fetch_or_create(Repo, "User", user.id)

    {:ok, view, html} =
      conn
      |> log_in_user(user)
      |> live("/app/entitlements/diagnostics")

    assert html =~ "Prepare signing-key rotation guidance"
    assert html =~ "No subscription, payment, or account ownership will change."

    view
    |> element("button", "Prepare signing-key rotation guidance")
    |> render_click()

    assert render(view) =~ "Confirm repair"

    assert render(view) =~
             "This records the operator action and refreshes this access diagnostic."

    view
    |> form("#repair-confirmation-form")
    |> render_submit()

    assert render(view) =~ "Repair recorded"
    assert render(view) =~ "The access diagnostic has been refreshed."
    assert render(view) =~ "tabindex=\"-1\""
  end
end
