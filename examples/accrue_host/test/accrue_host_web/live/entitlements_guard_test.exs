defmodule AccrueHostWeb.EntitlementsGuardTest do
  use AccrueHost.HostFlowProofCase, async: false

  import Phoenix.LiveViewTest

  alias AccrueHost.Billing

  test "entitled organization can access the gated advanced reports route", %{conn: conn} do
    user = AccrueHost.AccountsFixtures.user_fixture()
    entitled_org = AccrueHost.AccountsFixtures.organization_fixture(%{owner: user})

    assert {:ok, _subscription} =
             Billing.subscribe(entitled_org, "price_premium", trial_end: {:days, 14})

    conn =
      conn
      |> log_in_user(user, active_organization_id: entitled_org.id)
      |> Plug.Conn.put_session(:active_organization_slug, entitled_org.slug)

    {:ok, _view, html} = live(conn, "/app/reports/advanced")
    assert html =~ "Advanced Reports"
    assert html =~ "You have access to this premium feature"
  end

  test "non-entitled organization is denied access to the gated advanced reports route", %{conn: conn} do
    user = AccrueHost.AccountsFixtures.user_fixture()
    basic_org = AccrueHost.AccountsFixtures.organization_fixture(%{owner: user})

    assert {:ok, _subscription} =
             Billing.subscribe(basic_org, "price_basic", trial_end: {:days, 14})

    conn =
      conn
      |> log_in_user(user, active_organization_id: basic_org.id)
      |> Plug.Conn.put_session(:active_organization_slug, basic_org.slug)

    result = live(conn, "/app/reports/advanced")
    assert {:error,
            {:redirect,
             %{
               to: "/",
               flash: %{"error" => "You don't have access to this page."}
             }}} = result
  end
end