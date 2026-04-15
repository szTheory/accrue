defmodule AccrueAdmin.Components.Sidebar do
  @moduledoc """
  Sidebar navigation for the admin shell.
  """

  use Phoenix.Component

  attr(:brand, :map, required: true)
  attr(:current_path, :string, required: true)
  attr(:items, :list, required: true)

  def sidebar(assigns) do
    ~H"""
    <aside class="ax-sidebar" aria-label="Admin navigation">
      <div class="ax-sidebar-brand">
        <%= if @brand.logo_url do %>
          <img src={@brand.logo_url} alt={@brand.app_name} class="ax-sidebar-logo" />
        <% else %>
          <span class="ax-sidebar-mark" aria-hidden="true">AX</span>
        <% end %>

        <div>
          <p class="ax-label">Accrue Admin</p>
          <p class="ax-sidebar-name"><%= @brand.app_name %></p>
        </div>
      </div>

      <nav class="ax-sidebar-nav">
        <a :for={item <- @items} href={item.href} class={nav_class(item, @current_path)}>
          <span class="ax-sidebar-link-label"><%= item.label %></span>
          <span class="ax-sidebar-link-meta"><%= item.eyebrow %></span>
        </a>
      </nav>
    </aside>
    """
  end

  defp nav_class(item, current_path) do
    if item.href == current_path do
      "ax-sidebar-link ax-sidebar-link-active"
    else
      "ax-sidebar-link"
    end
  end
end
