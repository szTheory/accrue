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
    assert html =~ "Billing health and recovery drawer"
    assert html =~ "Billing needs attention now"
    assert html =~ "$592.50 open exposure; target $0.00"
    assert html =~ "Billing health verdict"
    assert html =~ "ax-dev-group-drawer-primary-actions"
    assert html =~ "Watch dunning funnel analytics and at-risk customers"
    assert html =~ "Find customer"
    refute html =~ "Find one customer and open billing 360 detail"
    assert html =~ "Open actor audit history"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Open failed-webhook queue"
    assert html =~ "Open invoice queue view for 2 open invoices"
    assert html =~ "Enter the organization slug or platform owner scope"
  end
end
