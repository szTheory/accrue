defmodule AccrueAdmin.Components.Topbar do
  @moduledoc """
  Topbar controls for mounted admin pages.
  """

  use Phoenix.Component

  attr(:brand, :map, required: true)
  attr(:page_title, :string, required: true)
  attr(:theme, :string, default: "system")

  def topbar(assigns) do
    ~H"""
    <header class="ax-topbar">
      <div class="ax-topbar-copy">
        <a href="#main-content" class="ax-skip-link">Skip to content</a>
        <p class="ax-eyebrow">Internal billing operations</p>
        <h1 class="ax-heading"><%= @page_title %></h1>
      </div>

      <div class="ax-topbar-actions">
        <button type="button" class="ax-icon-button" data-sidebar-toggle="true">
          <span class="ax-icon-label">Menu</span>
        </button>

        <div class="ax-theme-toggle" role="group" aria-label="Color theme">
          <button type="button" class={theme_button_class(@theme, "light")} data-theme-target="light">
            Light
          </button>
          <button type="button" class={theme_button_class(@theme, "dark")} data-theme-target="dark">
            Dark
          </button>
          <button type="button" class={theme_button_class(@theme, "system")} data-theme-target="system">
            System
          </button>
        </div>

        <div class="ax-topbar-brand-chip">
          <span class="ax-label">Brand</span>
          <span class="ax-topbar-brand-name"><%= @brand.app_name %></span>
        </div>
      </div>
    </header>
    """
  end

  defp theme_button_class(current_theme, button_theme) do
    if current_theme == button_theme do
      "ax-theme-button ax-theme-button-active"
    else
      "ax-theme-button"
    end
  end
end
