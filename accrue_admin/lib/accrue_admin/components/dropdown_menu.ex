defmodule AccrueAdmin.Components.DropdownMenu do
  @moduledoc """
  Accessible dropdown menu using native disclosure semantics.
  """

  use Phoenix.Component

  attr(:label, :string, required: true)
  attr(:items, :list, default: [])

  def dropdown_menu(assigns) do
    ~H"""
    <details class="ax-dropdown" data-component-group="toolbar-search-filter-sort">
      <summary class="ax-button ax-button-secondary ax-dropdown-trigger">
        <span><%= @label %></span>
        <span aria-hidden="true">▾</span>
      </summary>

      <div class="ax-dropdown-panel" aria-label={@label}>
        <a
          :for={item <- @items}
          href={item[:href] || "#"}
          class={["ax-dropdown-item", item[:danger] && "ax-dropdown-item-danger"]}
        >
          <span class="ax-dropdown-item-label"><%= item[:label] %></span>
          <span :if={item[:description]} class="ax-dropdown-item-description"><%= item[:description] %></span>
        </a>
      </div>
    </details>
    """
  end
end
