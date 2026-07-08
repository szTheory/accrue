defmodule AccrueAdmin.Components.AppShellTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.AppShell

  test "topbar renders configured admin brand name" do
    html =
      render_component(
        fn assigns ->
          assigns = assigns

          ~H"""
          <AppShell.app_shell
            brand={%{app_name: "Accrue Admin", logo_url: nil}}
            current_path="/billing"
            mount_path="/billing"
            page_title="Dashboard"
            theme="system"
            active_organization_name={nil}
          >
            <p class="ax-body">Inner</p>
          </AppShell.app_shell>
          """
        end,
        %{}
      )

    # The brand app_name is now honored as the sidebar brand-lockup accessible
    # name (white-label correct) rather than in a topbar brand chip.
    assert html =~ ~s(aria-label="Accrue Admin")
    assert html =~ "<title>Accrue Admin</title>"
    # The redundant topbar brand chip and topbar page-title (ax-heading) are gone.
    refute html =~ "ax-topbar-brand-chip"
    refute html =~ ~s(<h1 class="ax-heading">)
    refute html =~ "Internal billing operations"
  end

  test "renders Active organization banner when name assign is present" do
    html =
      render_component(
        fn assigns ->
          assigns = assigns

          ~H"""
          <AppShell.app_shell
            brand={%{app_name: "Accrue", logo_url: nil}}
            current_path="/billing/customers?org=acme-corp"
            mount_path="/billing"
            page_title="Customers"
            theme="system"
            active_organization_name="Acme Corp"
          >
            <p class="ax-body">Inner</p>
          </AppShell.app_shell>
          """
        end,
        %{}
      )

    assert html =~ "Active organization"
    assert html =~ "Acme Corp"
  end

  test "renders Phase 191 connection status and stale action contract" do
    html =
      render_component(
        fn assigns ->
          assigns = assigns

          ~H"""
          <AppShell.app_shell
            brand={%{app_name: "Accrue", logo_url: nil}}
            current_path="/billing"
            mount_path="/billing"
            page_title="Dashboard"
            theme="system"
            active_organization_name={nil}
          >
            <button class="ax-button ax-button-primary" phx-click="refund_charge">
              Refund charge
            </button>
          </AppShell.app_shell>
          """
        end,
        %{}
      )

    assert html =~ ~s(id="accrue-admin-shell")
    assert html =~ ~s(phx-hook="ConnectionState")
    assert html =~ ~s(data-connection-state="connected")
    assert html =~ ~s(data-stale-disable-selector=)
    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-live="polite")
    assert html =~ "Connection lost. Reconnecting before actions can run."
    assert html =~ "Connection restored. Review the current state before running an action."
  end

  test "sidebar renders journey group headings and promoted recovery link" do
    html =
      render_component(
        fn assigns ->
          assigns = assigns

          ~H"""
          <AppShell.app_shell
            brand={%{app_name: "Accrue", logo_url: nil}}
            current_path="/billing"
            mount_path="/billing"
            page_title="Dashboard"
            theme="system"
            active_organization_name={nil}
          >
            <p class="ax-body">Inner</p>
          </AppShell.app_shell>
          """
        end,
        %{}
      )

    assert html =~ "Billing"
    assert html =~ "Recovery"
    assert html =~ "Audit"
    assert html =~ "Developer"
    assert html =~ ~s(href="/billing/analytics/recovery")
    assert html =~ "Payments"
  end

  test "sidebar marks only the current journey item active" do
    html =
      render_component(
        fn assigns ->
          assigns = assigns

          ~H"""
          <AppShell.app_shell
            brand={%{app_name: "Accrue", logo_url: nil}}
            current_path="/billing/webhooks/evt_123"
            mount_path="/billing"
            page_title="Webhook"
            theme="system"
            active_organization_name={nil}
          >
            <p class="ax-body">Inner</p>
          </AppShell.app_shell>
          """
        end,
        %{}
      )

    # Live-nav links render data-phx-link attrs between href and class, so match
    # each independently rather than asserting href/class adjacency.
    assert html =~
             ~r/href="\/billing\/webhooks"[^>]*class="ax-sidebar-link ax-sidebar-link-active"/

    refute html =~
             ~r/href="\/billing"[^>]*class="ax-sidebar-link ax-sidebar-link-active"/
  end

  test "sidebar customers link preserves org query from current_path" do
    html =
      render_component(
        fn assigns ->
          assigns = assigns

          ~H"""
          <AppShell.app_shell
            brand={%{app_name: "Accrue", logo_url: nil}}
            current_path="/billing/subscriptions?org=acme-corp"
            mount_path="/billing"
            page_title="Subscriptions"
            theme="system"
            active_organization_name={nil}
          >
            <p class="ax-body">Inner</p>
          </AppShell.app_shell>
          """
        end,
        %{}
      )

    assert html =~ ~s(href="/billing/customers?org=acme-corp")
  end
end
