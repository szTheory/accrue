defmodule AccrueAdmin.Components.AppShellTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.AppShell

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
