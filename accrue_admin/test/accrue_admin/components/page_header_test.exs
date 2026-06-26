defmodule AccrueAdmin.Components.PageHeaderTest do
  use ExUnit.Case, async: true
  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.PageHeader

  describe "page_header/1" do
    test "renders breadcrumbs, required title, semantic markers, and exactly one h1" do
      html =
        render_component(&PageHeader.page_header/1, %{
          breadcrumbs: [
            %{label: "Dashboard", href: "/billing"},
            %{label: "Subscriptions"}
          ],
          title: "Subscriptions"
        })

      assert html =~ ~s(data-ax-page-header)
      assert html =~ ~s(data-component-group="page-header-actions-breadcrumbs")
      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(href="/billing")
      assert html =~ ~s(aria-current="page")
      assert html =~ ~s(data-ax-page-title)
      assert html =~ ~s(class="ax-display")
      assert html =~ "Subscriptions"
      assert Regex.scan(~r/<h1(?:\s|>)/, html) |> length() == 1
    end

    test "renders optional heading id, class, rest attrs, and bounded caller-owned slots" do
      html =
        render_component(fn assigns ->
          assigns =
            assign(assigns,
              breadcrumbs: [
                %{label: "Dashboard", href: "/billing"},
                %{label: "Subscriptions"}
              ]
            )

          ~H"""
          <PageHeader.page_header
            breadcrumbs={@breadcrumbs}
            title="Subscriptions"
            heading_id="subscriptions-title"
            class="custom-page-header-class"
            data-page-contract="phase-196"
          >
            <:description>
              <p class="ax-body">At-risk subscriptions first, with every subscription one click away.</p>
            </:description>
            <:stat_strip>
              <dl aria-label="Subscription summary">
                <div><dt>At risk</dt><dd>2</dd></div>
              </dl>
            </:stat_strip>
            <:actions>
              <a href="/billing/subscriptions?view=all" class="ax-button ax-button-secondary">View all subscriptions</a>
            </:actions>
            <:filter_toolbar>
              <form phx-change="data_table_filter" phx-submit="data_table_filter">
                <input name="q" value="northwind" />
              </form>
            </:filter_toolbar>
          </PageHeader.page_header>
          """
        end)

      assert html =~ ~s(id="subscriptions-title")
      assert html =~ "custom-page-header-class"
      assert html =~ ~s(data-page-contract="phase-196")
      assert html =~ "At-risk subscriptions first"
      assert html =~ "Subscription summary"
      assert html =~ ~s(data-ax-page-actions)
      assert html =~ "View all subscriptions"
      assert html =~ ~s(data-ax-page-filter-toolbar)
      assert html =~ ~s(phx-change="data_table_filter")
      assert html =~ ~s(phx-submit="data_table_filter")
    end

    test "does not own resource, filter, table, app-shell, flash, or pagination behavior" do
      source = File.read!("lib/accrue_admin/components/page_header.ex")

      refute source =~ "use Phoenix.LiveComponent"
      refute source =~ "AccrueAdmin.DataTableNav"
      refute source =~ "AccrueAdmin.Components.DataTable"
      refute source =~ "AccrueAdmin.Components.AppShell"
      refute source =~ "AccrueAdmin.Components.FlashGroup"
      refute source =~ "handle_params"
      refute source =~ "handle_event"
      refute source =~ "push_patch"
      refute source =~ "pagination"
      refute source =~ "query_module"
      refute source =~ "filter_params"
    end
  end
end
