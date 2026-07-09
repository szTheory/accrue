defmodule AccrueAdmin.ComponentKitchenLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders the shared component kitchen and floating toolbar", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    assert html =~ "Billing health dashboard"
    assert html =~ "Monitor open invoice exposure"
    assert html =~ "Primary action"
    assert html =~ "Secondary action"
    assert html =~ "Billing health: invoice queue first"
    assert html =~ "More billing actions"
    assert html =~ "View dunning funnel and at-risk"
    assert html =~ "Dashboard"
    assert html =~ "Dev-only webhook fixtures"
    assert html =~ "/billing/dev/fake-inspect"
    assert html =~ "Command palette motion specimen"
    assert html =~ "ax-command-palette"
    assert html =~ "Billing health and recovery drawer"
    assert html =~ "Billing needs attention now"
    assert html =~ "$592.50 open exposure; target $0.00"
    assert html =~ "Billing health verdict"
    assert html =~ "ax-dev-group-drawer-primary-actions"
    assert html =~ "Open dunning funnel and at-risk analytics"
    assert html =~ "Watch dunning + at-risk"
    assert html =~ "Who did what, when?"
    assert html =~ "Find customer"
    refute html =~ "Find one customer and open billing 360 detail"
    assert html =~ "View full audit history"
    assert html =~ "billing.contact.updated"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Open invoice queue view for 2 open invoices"
    assert html =~ "Open invoice exposure target: $0.00."
    assert html =~ "Open open-invoice queue first"
    assert html =~ "Open open-invoice queue to zero"
    assert html =~ "Open production audit log"
    assert html =~ "Debug failed webhook deliveries"
    assert html =~ "Open invoice queue view"
    assert html =~ "Find one customer - see everything"
    assert html =~ "Search customer records"
    assert html =~ "Enter the organization slug or platform owner scope"
  end
end
