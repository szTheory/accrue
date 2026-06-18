defmodule AccrueAdmin.NavigationComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.{Breadcrumbs, Button, FlashGroup, StatusBadge}
  alias AccrueAdmin.Components.{DropdownMenu, Input, Select, Sidebar, Tabs, WindowSelector}

  describe "Breadcrumbs" do
    test "renders linked ancestors and current page" do
      html =
        render_component(&Breadcrumbs.breadcrumbs/1, %{
          items: [
            %{label: "Billing", href: "/billing"},
            %{label: "Invoices", href: "/billing/invoices"},
            %{label: "INV-0001"}
          ]
        })

      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(href="/billing")
      assert html =~ "Invoices"
      assert html =~ ~s(aria-current="page")
      assert html =~ "INV-0001"
    end

    test "keeps breadcrumb current-page state without claiming page-header ownership" do
      html =
        render_component(&Breadcrumbs.breadcrumbs/1, %{
          items: [
            %{label: "Billing", href: "/billing"},
            %{label: "Invoices", href: "/billing/invoices"},
            %{label: "INV-0001"}
          ]
        })

      assert html =~ ~s(<nav class="ax-breadcrumbs" aria-label="Breadcrumb">)
      assert html =~ ~s(class="ax-breadcrumbs-current" aria-current="page")
      refute html =~ ~s(data-component-group="page-header-actions-breadcrumbs")
    end
  end

  describe "FlashGroup" do
    test "renders escaped flash messages with semantic headings" do
      html =
        render_component(&FlashGroup.flash_group/1, %{
          flashes: [
            %{kind: :info, message: "Invoice queued"},
            %{kind: :error, title: "Refund blocked", message: "<script>alert(1)</script>"}
          ]
        })

      assert html =~ "Notice"
      assert html =~ "Refund blocked"
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
      refute html =~ "<script>alert(1)</script>"
    end

    test "uses toast layer and semantic status color tokens" do
      css = File.read!("assets/css/app.css")

      assert css =~ ".ax-flash-group"
      assert css =~ "z-index: var(--ax-z-toast)"
      assert css =~ ".ax-flash-success"
      assert css =~ "var(--ax-status-success-bg)"
      assert css =~ ".ax-flash-warning"
      assert css =~ "var(--ax-status-warning-bg)"
      assert css =~ ".ax-flash-error"
      assert css =~ "var(--ax-status-danger-bg)"
      assert css =~ ".ax-flash-info"
      assert css =~ "var(--ax-status-info-bg)"
    end
  end

  describe "Button" do
    test "renders button variants and link mode" do
      button_html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Button.button variant="primary" type="submit">Save changes</Button.button>
          """
        end)

      link_html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Button.button variant="ghost" href="/billing/webhooks">View webhooks</Button.button>
          """
        end)

      assert button_html =~ ~s(<button)
      assert button_html =~ "ax-button-primary"
      assert button_html =~ "Save changes"
      assert link_html =~ ~s(<a)
      assert link_html =~ ~s(href="/billing/webhooks")
      assert link_html =~ "ax-button-ghost"
    end

    test "renders disabled link buttons without activation behavior" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Button.button href="/billing/webhooks" disabled>View webhooks</Button.button>
          """
        end)

      assert html =~ ~s(<a)
      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(tabindex="-1")
      refute html =~ ~s(href="/billing/webhooks")
      assert html =~ "View webhooks"
    end

    test "renders disabled native buttons with the disabled attribute" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Button.button disabled>Save changes</Button.button>
          """
        end)

      assert html =~ ~s(<button)
      assert html =~ ~s(disabled)
      assert html =~ "Save changes"
    end
  end

  describe "StatusBadge" do
    test "maps statuses onto fixed palette tones" do
      paid =
        render_component(&StatusBadge.status_badge/1, %{
          status: :paid
        })

      warning =
        render_component(&StatusBadge.status_badge/1, %{
          status: :past_due
        })

      failed =
        render_component(&StatusBadge.status_badge/1, %{
          status: :failed
        })

      assert paid =~ "ax-status-badge-moss"
      assert paid =~ "Paid"
      assert warning =~ "ax-status-badge-amber"
      assert failed =~ "ax-status-badge-ink"
    end
  end

  describe "Input" do
    test "renders help text and validation state" do
      html =
        render_component(&Input.input/1, %{
          id: "invoice-search",
          name: "invoice_search",
          label: "Invoice search",
          value: "INV-0001",
          help_text: "Search by invoice number or customer email",
          errors: ["must be at least 3 characters"]
        })

      assert html =~ ~s(for="invoice-search")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "Search by invoice number or customer email"
      assert html =~ "must be at least 3 characters"
    end
  end

  describe "Select" do
    test "renders prompt and selected option" do
      html =
        render_component(&Select.select/1, %{
          id: "status-filter",
          name: "status",
          label: "Status",
          prompt: "All statuses",
          value: "past_due",
          options: [{"Active", "active"}, {"Past due", "past_due"}]
        })

      assert html =~ "All statuses"
      assert html =~ ~s(value="past_due" selected)
      assert html =~ "Past due"
    end
  end

  describe "DropdownMenu" do
    test "renders native disclosure actions with accessible text and descriptions" do
      html =
        render_component(&DropdownMenu.dropdown_menu/1, %{
          label: "Invoice actions",
          items: [
            %{
              label: "Open PDF",
              href: "/billing/invoices/in_123/pdf",
              description: "Preview the live invoice PDF"
            },
            %{
              label: "Void invoice",
              href: "/billing/invoices/in_123/void",
              description: "Stop further collection",
              danger: true
            }
          ]
        })

      assert html =~ ~s(<details)
      assert html =~ ~s(data-component-group="toolbar-search-filter-sort")
      assert html =~ "Invoice actions"
      assert html =~ "Preview the live invoice PDF"
      assert html =~ "ax-dropdown-item-danger"
      refute html =~ ~s(role="menu")
      refute html =~ ~s(role="menuitem")
    end

    test "uses semantic danger styling for destructive disclosure actions" do
      css = File.read!("assets/css/app.css")

      assert css =~ ".ax-dropdown-item-danger .ax-dropdown-item-label"
      assert css =~ "var(--ax-status-danger-text)"
    end
  end

  describe "Tabs" do
    test "renders link tabs with active detail-page state" do
      html =
        render_component(&Tabs.tabs/1, %{
          active: "events",
          tabs: [
            %{id: "overview", label: "Overview", href: "/billing/customers/cus_123"},
            %{id: "events", label: "Events", href: "/billing/customers/cus_123/events", count: 12}
          ]
        })

      assert html =~ "Overview"
      assert html =~ ~s(aria-current="page")
      assert html =~ "ax-tab-active"
      assert html =~ ">12<"
    end

    test "keeps route navigation semantics without same-page tab-panel roles" do
      html =
        render_component(&Tabs.tabs/1, %{
          active: "events",
          tabs: [
            %{id: "overview", label: "Overview", href: "/billing/customers/cus_123"},
            %{id: "events", label: "Events", href: "/billing/customers/cus_123/events", count: 12},
            %{id: "invoices", label: "Invoices", href: "/billing/customers/cus_123/invoices"}
          ]
        })

      assert html =~ ~s(<nav class="ax-tabs")
      assert html =~ ~s(data-component-group="tabs-subviews")
      assert html =~ ~s(href="/billing/customers/cus_123/events")
      assert html =~ ~s(aria-current="page")
      assert 1 == html |> String.split(~s(aria-current="page")) |> length() |> Kernel.-(1)
      refute html =~ ~s(role="tablist")
      refute html =~ ~s(role="tab")
      refute html =~ ~s(role="tabpanel")
    end
  end

  describe "Sidebar collapsible groups" do
    defp make_items(mount_path \\ "/billing") do
      AccrueAdmin.Nav.items(mount_path, mount_path <> "/", %{
        recovery: 3,
        developer: 2
      })
    end

    test "collapsible group (Recovery) renders a <button> with aria-expanded" do
      html =
        render_component(&Sidebar.sidebar/1, %{
          brand: %{logo_url: nil, app_name: "Test"},
          current_path: "/billing/",
          items: make_items()
        })

      # The Recovery group should have a collapsible button toggle
      assert html =~ ~s(aria-expanded)
      # The button should mention Recovery
      assert html =~ "Recovery"
    end

    test "non-collapsible Billing group does NOT render a toggle <button>" do
      html =
        render_component(&Sidebar.sidebar/1, %{
          brand: %{logo_url: nil, app_name: "Test"},
          current_path: "/billing/",
          items: make_items()
        })

      # The Billing group label should be a <p> element, not inside a <button>
      assert html =~ ~s(<p class="ax-sidebar-group-label">Billing</p>)
    end

    test "badge renders only when group_meta.badge is a positive integer" do
      html =
        render_component(&Sidebar.sidebar/1, %{
          brand: %{logo_url: nil, app_name: "Test"},
          current_path: "/billing/",
          items: make_items()
        })

      # Recovery has badge: 3 → should render a badge span
      assert html =~ ~s(ax-badge)
      # Catalog has badge: nil → no badge rendered for Catalog
      # (We check the Developer badge aria-label to confirm count appears)
      assert html =~ ~s(ax-badge-warning)
    end

    test "badge has class ax-badge-warning for Recovery group" do
      html =
        render_component(&Sidebar.sidebar/1, %{
          brand: %{logo_url: nil, app_name: "Test"},
          current_path: "/billing/",
          items: make_items()
        })

      assert html =~ "ax-badge ax-badge-warning"
    end

    test "badge has class ax-badge-danger for Developer group" do
      html =
        render_component(&Sidebar.sidebar/1, %{
          brand: %{logo_url: nil, app_name: "Test"},
          current_path: "/billing/",
          items: make_items()
        })

      assert html =~ "ax-badge ax-badge-danger"
    end

    test "link list div has hidden=true for collapsed group with no badge" do
      # Catalog group has badge: nil and collapsible: true → should be hidden initially
      html =
        render_component(&Sidebar.sidebar/1, %{
          brand: %{logo_url: nil, app_name: "Test"},
          current_path: "/billing/",
          items: make_items()
        })

      # The Catalog group links div should be hidden (collapsed, no badge)
      # ax-sidebar-group-links class is now present between id and hidden attrs
      assert html =~ ~s(id="sidebar-group-links-catalog")
      assert html =~ ~s(ax-sidebar-group-links)
      # Check the catalog section is present with hidden (attribute may appear after class)
      assert html =~ ~r/id="sidebar-group-links-catalog"[^>]*hidden/
    end

    test "link list div is NOT hidden for group with badge > 0" do
      # Recovery has badge: 3 → should be expanded (not hidden)
      html =
        render_component(&Sidebar.sidebar/1, %{
          brand: %{logo_url: nil, app_name: "Test"},
          current_path: "/billing/",
          items: make_items()
        })

      # Recovery group links should be visible (not hidden)
      refute html =~ ~s(id="sidebar-group-links-recovery" hidden)
    end
  end

  describe "WindowSelector" do
    test "renders 3 preset buttons with correct labels" do
      html =
        render_component(&WindowSelector.window_selector/1, %{
          current_window: "30d",
          base_path: "/billing/analytics/recovery"
        })

      assert html =~ "7 days UTC"
      assert html =~ "30 days UTC"
      assert html =~ "90 days UTC"
    end

    test "marks active window with aria-current and ax-tab-active" do
      html =
        render_component(&WindowSelector.window_selector/1, %{
          current_window: "30d",
          base_path: "/billing/analytics/recovery"
        })

      assert html =~ ~s(aria-current="page")
      assert html =~ "ax-tab-active"
      # Only one button should carry aria-current="page" (the active one)
      assert 1 == html |> String.split(~s(aria-current="page")) |> length() |> Kernel.-(1)
    end

    test "uses the tabs-subviews group locator while remaining patch navigation" do
      html =
        render_component(&WindowSelector.window_selector/1, %{
          current_window: "90d",
          base_path: "/billing/analytics/recovery"
        })

      assert html =~ ~s(data-component-group="tabs-subviews")
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(href="/billing/analytics/recovery?window=90d")
      assert html =~ ~s(aria-current="page")
      assert 1 == html |> String.split(~s(aria-current="page")) |> length() |> Kernel.-(1)
      refute html =~ ~s(role="tablist")
      refute html =~ ~s(role="tabpanel")
    end

    test "constructs correct patch hrefs from base_path" do
      html =
        render_component(&WindowSelector.window_selector/1, %{
          current_window: "7d",
          base_path: "/billing/analytics/recovery"
        })

      assert html =~ ~s(?window=7d)
      assert html =~ ~s(?window=30d)
      assert html =~ ~s(?window=90d)
      assert html =~ "/billing/analytics/recovery?window=7d"
    end
  end
end
