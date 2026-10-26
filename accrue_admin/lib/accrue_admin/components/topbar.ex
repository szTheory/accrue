defmodule AccrueAdmin.Components.Topbar do
  @moduledoc """
  Topbar controls for mounted admin pages.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon
  alias AccrueAdmin.Components.ThemePicker

  attr(:theme, :string, default: "system")
  attr(:theme_forced, :boolean, default: false)

  def topbar(assigns) do
    ~H"""
    <header class="ax-topbar">
      <a href="#main-content" class="ax-skip-link">Skip to content</a>

      <div class="ax-topbar-actions">
        <div class="ax-time-preference">
          <label for="admin-time-preference">Time display</label>
          <div class="ax-time-preference-control">
            <select id="admin-time-preference" data-time-preference aria-label="Timestamp display timezone">
              <option value="local">Local</option>
              <option value="utc">UTC</option>
            </select>
            <Icon.icon name={:chevron_down} size="sm" />
          </div>
        </div>

        <button
          id="search-trigger"
          type="button"
          class="ax-search-trigger"
          aria-label="Search billing: customers, invoices, and subscriptions (Command or Control K)"
          data-command-palette-trigger="true"
        >
          <Icon.icon name={:search} size="sm" class="ax-search-trigger-icon" />
          <span class="ax-search-trigger-text">Search billing</span>
          <kbd class="ax-kbd">⌘K</kbd>
        </button>

        <button type="button" class="ax-icon-button" data-sidebar-toggle="true">
          <Icon.icon name={:events} size="md" />
          <span class="ax-icon-label">Menu</span>
        </button>

        <p :if={@theme_forced} class="ax-label" role="status" data-role="admin-theme-forced">
          <%= String.capitalize(@theme) %> theme set by host
        </p>
        <ThemePicker.theme_picker :if={!@theme_forced} theme={@theme} />
      </div>
    </header>
    """
  end
end
