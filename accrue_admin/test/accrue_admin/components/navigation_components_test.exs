defmodule AccrueAdmin.NavigationComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.{Breadcrumbs, Button, FlashGroup, StatusBadge}

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
end
