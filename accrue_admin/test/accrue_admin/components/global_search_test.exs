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
      assert html =~ ~s(data-path="/billing/invoices?status=open")
      assert html =~ ~s(data-path="/billing/analytics/recovery")
      assert html =~ ~s(data-path="/billing/webhooks?status=dead")
    end
  end
end
