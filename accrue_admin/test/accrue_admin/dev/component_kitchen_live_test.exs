defmodule AccrueAdmin.ComponentKitchenLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders the shared component kitchen and floating toolbar", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    assert html =~ "Primitive and form components"
    assert html =~ "Primary action"
    assert html =~ "Secondary action"
    assert html =~ "Dev tools"
    assert html =~ "Dev-only webhook fixtures"
    assert html =~ "/billing/dev/fake-inspect"
    assert html =~ "Command palette motion specimen"
    assert html =~ "ax-command-palette"
    assert html =~ "Billing health and recovery drawer specimen"
    assert html =~ "No - billing is not healthy right now"
    assert html =~ "$592.50 open above $0.00 target"
    assert html =~ "Billing health summary"
    assert html =~ "Open billing health summary"
    assert html =~ "Open dunning funnel"
    assert html =~ "Find one customer and open billing 360 detail"
    assert html =~ "Who did what, when? Audit trail"
    assert html =~ "Debug webhook deliveries"
    assert html =~ "Work open invoices"
    assert html =~ "Enter the organization slug or platform owner scope"
  end
end
