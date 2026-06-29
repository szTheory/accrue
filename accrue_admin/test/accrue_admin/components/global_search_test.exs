defmodule AccrueAdmin.Components.GlobalSearchTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.GlobalSearch

  describe "path/2 nil-guard (regression: WR-03 fix)" do
    test "renders without crashing when mount_path is nil (pre-update/2 state)" do
      # GlobalSearch.mount/1 initialises mount_path to nil.  The template calls
      # path(@mount_path, ...) four times in the @query == "" branch, so a
      # render triggered before update/2 delivers mount_path used to raise
      # ArgumentError.  This test verifies the component renders cleanly with
      # mount_path: nil and produces "#" hrefs rather than crashing.
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: nil,
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      # Component must render without raising
      assert html =~ "Jump to"

      # All four shortcut links should fall back to "#"
      assert html =~ ~s(data-path="#")
      assert html =~ ~s(href="#")
    end

    test "builds correct paths when mount_path is set" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      assert html =~ ~s(data-path="/billing/customers")
      assert html =~ ~s(href="/billing/customers")
      assert html =~ ~s(data-path="/billing/invoices?status=open")
      assert html =~ ~s(data-path="/billing/analytics/recovery")
      assert html =~ ~s(data-path="/billing/webhooks?status=dead")
    end
  end

  describe "command palette group contract" do
    test "renders modal-layer dialog markup with active-result styling proof" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      css = File.read!("assets/css/app.css")

      assert html =~ ~s(data-component-group="toolbar-search-filter-sort")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-label="Global search")
      assert css =~ ".ax-command-palette-wrapper"
      assert css =~ "z-index: var(--ax-z-modal)"
      assert css =~ ".ax-command-palette-item.ax-active"
      assert css =~ "var(--ax-interactive-selected)"
    end

    test "does not expose modal dialog semantics while closed" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: false,
          loading: false
        })

      assert html =~ ~s(data-component-group="toolbar-search-filter-sort")
      refute html =~ ~s(role="dialog")
      refute html =~ ~s(aria-modal="true")
      refute html =~ "Jump to"
    end

    test "renders command rows as native pointer-activatable links" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      assert html =~
               ~s(<a class="ax-command-palette-item" href="/billing/customers" data-path="/billing/customers")

      assert html =~
               ~s(<a class="ax-command-palette-item" href="/billing/invoices?status=open" data-path="/billing/invoices?status=open")
    end

    test "Phase 199 command palette declares Overlay-backed or overlay-equivalent source markers" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      overlay_backed? =
        html =~ ~s(data-phx-portal="#ax-overlay-root") and html =~ ~s(phx-hook="Overlay")

      named_wrapper? =
        html =~ ~s(data-ax-command-palette-shell) and
          html =~ ~s(data-ax-command-palette-backdrop) and
          html =~ ~s(data-ax-command-palette-panel) and
          html =~ ~s(data-focus-trap-close-event="close") and
          html =~ ~s(data-focus-trap-close-target) and
          html =~ ~s(data-focus-trap-initial) and
          html =~ ~s(data-focus-trap-fallback)

      assert overlay_backed? or named_wrapper?,
             "command palette must either use Overlay or declare equivalent focus/portal markers"
    end

    test "Phase 199 no-results copy names the billing search domain" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "missing-acme",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      refute html =~ "No results found"
      assert html =~ ~s(No billing records match "missing-acme")
    end
  end
end
