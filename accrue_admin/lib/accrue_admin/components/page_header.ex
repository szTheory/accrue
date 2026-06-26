defmodule AccrueAdmin.Components.PageHeader do
  @moduledoc """
  Shared page-orientation header for admin pages.

  `PageHeader` owns the breadcrumb/title/header chrome and bounded slots for
  caller-owned page controls. Resource state, filters, query params, tables,
  flashes, and shell layout stay with the caller.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Breadcrumbs

  attr(:breadcrumbs, :list, required: true)
  attr(:title, :string, required: true)
  attr(:heading_id, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:component_group, :string, default: "page-header-actions-breadcrumbs")
  attr(:rest, :global)

  slot(:description)
  slot(:stat_strip)
  slot(:actions)
  slot(:filter_toolbar)

  def page_header(assigns) do
    ~H"""
    <header
      class={["ax-page-header", @class]}
      data-ax-page-header
      data-component-group={@component_group}
      {@rest}
    >
      <div class="ax-page-header-main">
        <Breadcrumbs.breadcrumbs items={@breadcrumbs} />
        <div class="ax-page-header-title-row">
          <div class="ax-page-header-title-copy">
            <h1 id={@heading_id} class="ax-display" data-ax-page-title><%= @title %></h1>
            <div :if={@description != []} class="ax-page-copy">
              <%= render_slot(@description) %>
            </div>
          </div>
          <div :if={@actions != []} class="ax-page-header-actions" data-ax-page-actions>
            <%= render_slot(@actions) %>
          </div>
        </div>
      </div>

      <div :if={@stat_strip != []} class="ax-page-header-stat-strip">
        <%= render_slot(@stat_strip) %>
      </div>

      <div :if={@filter_toolbar != []} class="ax-page-header-filter-toolbar" data-ax-page-filter-toolbar>
        <%= render_slot(@filter_toolbar) %>
      </div>
    </header>
    """
  end
end
