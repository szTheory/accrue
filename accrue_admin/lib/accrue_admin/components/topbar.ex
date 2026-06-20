defmodule AccrueAdmin.Components.Topbar do
  @moduledoc """
  Topbar controls for mounted admin pages.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon
  alias AccrueAdmin.Components.ThemePicker

  attr(:brand, :map, required: true)
  attr(:page_title, :string, required: true)
  attr(:theme, :string, default: "system")

  def topbar(assigns) do
    ~H"""
    <header class="ax-topbar">
      <div class="ax-topbar-copy">
        <a href="#main-content" class="ax-skip-link">Skip to content</a>
        <p class="ax-eyebrow"><%= @brand.app_name %></p>
        <h1 class="ax-heading"><%= @page_title %></h1>
      </div>

      <div class="ax-topbar-actions">
        <button
          id="search-trigger"
          type="button"
          class="ax-search-trigger"
          aria-label="Search (Command or Control K)"
          data-command-palette-trigger="true"
        >
          <Icon.icon name={:search} size="sm" class="ax-search-trigger-icon" />
          <span class="ax-search-trigger-text">Search customers, invoices… ⌘K</span>
          <kbd class="ax-kbd">⌘K</kbd>
        </button>

        <button type="button" class="ax-icon-button" data-sidebar-toggle="true">
          <Icon.icon name={:events} size="md" />
          <span class="ax-icon-label">Menu</span>
        </button>

        <ThemePicker.theme_picker theme={@theme} />

        <div class="ax-topbar-brand-chip">
          <span class="ax-label">Brand</span>
          <span class="ax-topbar-brand-name"><%= @brand.app_name %></span>
        </div>
      </div>
    </header>
    """
  end
end
