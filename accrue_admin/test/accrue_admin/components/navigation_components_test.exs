defmodule AccrueAdmin.NavigationComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.{Breadcrumbs, Button, FlashGroup, StatusBadge}
  alias AccrueAdmin.Components.{DropdownMenu, Input, Select, Tabs}

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
    test "renders accessible text actions instead of icon-only affordances" do
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
      assert html =~ ~s(role="menu")
      assert html =~ "Invoice actions"
      assert html =~ "Preview the live invoice PDF"
      assert html =~ "ax-dropdown-item-danger"
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
  end
end
