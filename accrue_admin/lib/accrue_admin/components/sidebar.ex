defmodule AccrueAdmin.Components.Sidebar do
  @moduledoc """
  Sidebar navigation for the admin shell.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon

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
          <span class="ax-sidebar-mark" aria-hidden="true">A</span>
        <% end %>

        <div>
          <p class="ax-sidebar-name"><%= @brand.app_name %></p>
          <p class="ax-sidebar-brand-sub">Accrue Admin</p>
        </div>
      </div>

      <nav class="ax-sidebar-nav">
        <section :for={{group, items} <- grouped_items(@items)} class="ax-sidebar-nav-group">
          <p :if={group} class="ax-sidebar-group-label"><%= group %></p>
          <a :for={item <- items} href={item.href} class={nav_class(item, @current_path)}>
            <Icon.icon name={item.icon} size="sm" class="ax-sidebar-link-icon" />
            <span class="ax-sidebar-link-label"><%= item.label %></span>
          </a>
        </section>
      </nav>
    </aside>
    """
  end

  # Preserve group order and keep `nil` groups (e.g. Home) so they render without a label.
  defp grouped_items(items) do
    items
    |> Enum.chunk_by(&Map.get(&1, :group))
    |> Enum.map(fn [first | _] = group_items -> {Map.get(first, :group), group_items} end)
  end

  defp nav_class(item, current_path) do
    current_path_root = current_path |> URI.parse() |> Map.get(:path) |> Kernel.||("")
    item_root = item.href |> URI.parse() |> Map.get(:path) |> Kernel.||("")

    active? =
      if item.label == "Home" do
        current_path_root == item_root
      else
        current_path_root == item_root or String.starts_with?(current_path_root, item_root <> "/")
      end

    if active? do
      "ax-sidebar-link ax-sidebar-link-active"
    else
      "ax-sidebar-link"
    end
  end
end
