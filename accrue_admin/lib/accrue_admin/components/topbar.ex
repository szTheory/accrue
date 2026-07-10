defmodule AccrueAdmin.Components.Topbar do
  @moduledoc """
  Topbar controls for mounted admin pages.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon
  alias AccrueAdmin.Components.ThemePicker

  attr(:theme, :string, default: "system")

  def topbar(assigns) do
    ~H"""
    <header class="ax-topbar">
      <a href="#main-content" class="ax-skip-link">Skip to content</a>

      <div class="ax-topbar-actions">
        <button
          id="search-trigger"
          type="button"
          class="ax-search-trigger"
          aria-label="Find one customer by name, email, or ID. Opens global customer detail search (Command or Control K)"
          data-command-palette-trigger="true"
        >
          <Icon.icon name={:search} size="sm" class="ax-search-trigger-icon" />
          <span class="ax-search-trigger-text">
            <strong>Find one customer</strong>
            <em>Name, email, or ID</em>
          </span>
          <span class="ax-search-trigger-action">Search</span>
          <kbd class="ax-kbd">⌘K</kbd>
        </button>

        <button type="button" class="ax-icon-button" data-sidebar-toggle="true">
          <Icon.icon name={:events} size="md" />
          <span class="ax-icon-label">Menu</span>
        </button>

        <ThemePicker.theme_picker theme={@theme} />
      </div>
    </header>
    """
  end
end
