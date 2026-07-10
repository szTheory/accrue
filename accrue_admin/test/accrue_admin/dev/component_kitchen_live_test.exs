defmodule AccrueAdmin.ComponentKitchenLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders the shared component kitchen and floating toolbar", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    assert html =~ "Billing health command center"
    assert html =~ "Find one customer is the primary support path"
    assert html =~ "Primary action"
    assert html =~ "Secondary action"
    assert html =~ "Billing status"
    assert html =~ "Unhealthy"
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
    assert html =~ "Watch dunning funnel + at-risk analytics"
    assert html =~ "Watch dunning funnel + at-risk"
    assert html =~ "Who did what, when?"
    assert html =~ "Find one customer"
    assert html =~ "Work invoice queue: 2 invoices, $592.50 exposure"
    assert html =~ "Webhooks to Events"
    refute html =~ "Find one customer and open billing 360 detail"
    assert html =~ "View full audit history"
    assert html =~ "billing.contact.updated"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Work invoice queue: 2 open invoices"
    assert html =~ "Billing status: Unhealthy"
    assert html =~ "Open invoice queue preview"
    assert html =~ "Northstar Labs"
    assert html =~ "$420.00 open"
    assert html =~ "Billing health answer"
    assert html =~ "Invoices queue: work receivables"
    refute html =~ "Work invoice queue in this billing alert"
    assert html =~ "Dunning funnel"
    assert html =~ "Open invoice queue"
    assert html =~ "Who did what, when? Actor-filtered audit log"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Watch dunning funnel + at-risk"
    assert html =~ "Work invoice queue"
    assert html =~ "Customer lookup specimen"
    assert html =~ "Enter the organization slug or platform owner scope"
  end
end
