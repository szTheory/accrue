defmodule AccrueAdmin.ComponentKitchenLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders the shared component kitchen and floating toolbar", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    assert html =~ "Primitive and form components"
    assert html =~ "Primary action"
    assert html =~ "Secondary action"
    assert html =~ "Dev tools"
    assert html =~ "Test webhook fixtures"
    assert html =~ "/billing/dev/fake-inspect"
    assert html =~ "Command palette motion specimen"
    assert html =~ "ax-command-palette"
    assert html =~ "Billing health and recovery drawer specimen"
    assert html =~ "Unhealthy: $592.50 open above $0.00 target"
    assert html =~ "Billing health summary"
    assert html =~ "Open billing health summary"
    assert html =~ "Open dunning funnel"
    assert html =~ "Find customer record"
    assert html =~ "Who did what, when?"
    assert html =~ "Debug webhook deliveries"
    assert html =~ "Work open invoices"
    assert html =~ "Enter the organization slug or platform owner scope"
  end
end
