defmodule AccrueAdmin.ComponentKitchenLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders the shared component kitchen and floating toolbar", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    assert html =~ "Billing health command center"
    assert html =~ "Check billing health first"
    assert html =~ "Primary action"
    assert html =~ "Secondary action"
    assert html =~ "Billing Health: Unhealthy"
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
    assert html =~ "Find customer record"
    refute html =~ "Find one customer and open billing 360 detail"
    assert html =~ "View full audit history"
    assert html =~ "billing.contact.updated"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Open invoice queue view for 2 open invoices"
    assert html =~ "Critical: 2 open invoices"
    assert html =~ "Billing health snapshot"
    assert html =~ "2 open, $592.50 over target"
    assert html =~ "Work invoice queue in this billing alert"
    assert html =~ "Dunning funnel and at-risk analytics available"
    assert html =~ "Work invoice queue"
    assert html =~ "Open actor-filtered event log"
    assert html =~ "Open full webhook debugging workflow"
    assert html =~ "Watch dunning funnel + at-risk"
    assert html =~ "Open invoice queue view"
    assert html =~ "Customer lookup specimen"
    assert html =~ "Enter the organization slug or platform owner scope"
  end
end
