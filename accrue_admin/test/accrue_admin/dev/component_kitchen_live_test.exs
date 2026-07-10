defmodule AccrueAdmin.ComponentKitchenLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders the shared component kitchen and floating toolbar", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    assert html =~ "Billing is currently unhealthy"
    assert html =~ "Work invoices, webhooks, and dunning from one command center."
    assert html =~ "Primary action"
    assert html =~ "Secondary action"
    assert html =~ "Billing status: Unhealthy."

    assert html =~
             "Restore health by clearing 2 open invoices, debugging 3 failed webhooks, and reviewing 1 past-due subscription."

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
    assert html =~ "View dunning funnel &amp; at-risk analytics"
    assert html =~ "Who did what, when?"
    assert html =~ "Primary support path"
    assert html =~ "Find one customer, see everything"
    assert html =~ "Receivables: open-invoice queue, $592.50"
    assert html =~ "Engineering: debug 3 failed webhooks"
    assert html =~ "View dunning funnel &amp; at-risk analytics"
    assert html =~ "Debug failed webhooks"
    assert html =~ "Audit timestamp: Jul 09, 2026 14:51 UTC"
    refute html =~ "Find one customer and open billing 360 detail"
    assert html =~ "View full audit history"
    assert html =~ "billing.contact.updated"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Review inline invoice preview below"
    assert html =~ "Billing status: Unhealthy"
    assert html =~ "Dunning funnel: 1 at-risk subscription in recovery review"
    assert html =~ "Open invoice queue preview"
    assert html =~ "2 invoices ready for inline queue review"
    assert html =~ "Failed webhook preview"
    assert html =~ "Recovery stage"
    assert html =~ "View at-risk accounts"
    assert html =~ "invoice.payment_failed"
    assert html =~ "Northstar Labs"
    assert html =~ "$420.00 open"
    assert html =~ "Billing health answer"
    assert html =~ "Invoices queue"
    refute html =~ "Work invoice queue in this billing alert"
    assert html =~ "Watch dunning funnel + at-risk"
    assert html =~ "Open invoice queue"
    assert html =~ "Who did what, when? Actor-filtered audit log"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Watch dunning funnel + at-risk"
    assert html =~ "Open invoice queue"
    assert html =~ "Customer lookup specimen"
    assert html =~ "Enter the organization slug or platform owner scope"
  end
end
