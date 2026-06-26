defmodule AccrueAdmin.Components.DropdownMenu do
  @moduledoc """
  Accessible dropdown menu using native disclosure semantics.

  `dropdown_menu/1` is link-shaped navigation. `action_menu/1` is the Phase 195
  detail-page action disclosure: it stays non-modal and only triggers LiveView
  events that may open the canonical drawer or StepUp modal elsewhere.
  """

  use Phoenix.Component

  attr(:label, :string, required: true)
  attr(:items, :list, default: [])

  def dropdown_menu(assigns) do
    ~H"""
    <details
      class="ax-dropdown"
      data-component-group="toolbar-search-filter-sort"
      data-phase191-focus="dropdown"
    >
      <summary class="ax-button ax-button-secondary ax-dropdown-trigger" data-phase191-focus="dropdown-trigger">
        <span><%= @label %></span>
        <span aria-hidden="true">▾</span>
      </summary>

      <div
        class="ax-dropdown-panel"
        aria-label={@label}
        data-phase191-focus="dropdown-panel"
        data-floating-panel="dropdown"
      >
        <a
          :for={item <- @items}
          href={item[:href] || "#"}
          class={["ax-dropdown-item", item[:danger] && "ax-dropdown-item-danger"]}
          data-phase191-focus="dropdown-item"
        >
          <span class="ax-dropdown-item-label"><%= item[:label] %></span>
          <span :if={item[:description]} class="ax-dropdown-item-description"><%= item[:description] %></span>
        </a>
      </div>
    </details>
    """
  end

  attr(:label, :string, required: true)
  attr(:groups, :list, default: [])
  attr(:id, :string, default: nil)

  def action_menu(assigns) do
    ~H"""
    <details
      id={@id}
      class="ax-dropdown ax-action-menu"
      data-component-group="detail-action-menu"
      data-ax-action-overflow-menu
      data-phase191-focus="dropdown"
    >
      <summary
        class="ax-button ax-button-secondary ax-dropdown-trigger ax-action-menu-trigger"
        aria-haspopup="menu"
        data-phase191-focus="dropdown-trigger"
      >
        <span><%= @label %></span>
        <span aria-hidden="true">▾</span>
      </summary>

      <div
        class="ax-dropdown-panel ax-action-menu-panel"
        role="menu"
        aria-label={@label}
        data-phase191-focus="dropdown-panel"
        data-floating-panel="dropdown"
      >
        <div
          :for={{group, index} <- Enum.with_index(@groups)}
          class={[
            "ax-action-menu-group",
            index > 0 && "ax-action-menu-group-separated",
            group_danger?(group) && "ax-action-menu-group-danger"
          ]}
          role="group"
          aria-label={group_label(group)}
        >
          <p :if={group_label(group)} class="ax-action-menu-group-label" role="presentation">
            <%= group_label(group) %>
          </p>

          <button
            :for={item <- group_items(group)}
            type="button"
            role="menuitem"
            class={[
              "ax-dropdown-item",
              "ax-action-menu-item",
              item_danger?(item) && "ax-dropdown-item-danger"
            ]}
            phx-click={item_event(item)}
            phx-target={item_target(item)}
            phx-value-action_type={item_value(item)}
            data-phase191-focus="dropdown-item"
          >
            <span class="ax-dropdown-item-label">
              <span><%= item_label(item) %></span>
              <span :if={item_hidden_context(item)} class="ax-visually-hidden"><%= " " <> item_hidden_context(item) %></span>
            </span>
            <span :if={item_description(item)} class="ax-dropdown-item-description">
              <%= item_description(item) %>
            </span>
          </button>
        </div>
      </div>
    </details>
    """
  end

  defp group_items(group), do: get_value(group, :items) || []
  defp group_label(group), do: get_value(group, :label)
  defp group_danger?(group), do: Enum.any?(group_items(group), &item_danger?/1)

  defp item_label(item), do: get_value(item, :label)
  defp item_event(item), do: get_value(item, :event)
  defp item_target(item), do: get_value(item, :target)
  defp item_value(item), do: get_value(item, :value)
  defp item_description(item), do: get_value(item, :description)

  defp item_hidden_context(item) do
    get_value(item, :hidden_context) || get_value(item, :action_context) ||
      get_value(item, :context)
  end

  defp item_danger?(item), do: get_value(item, :danger?) || get_value(item, :danger)

  defp get_value(map, key), do: Map.get(map, key) || Map.get(map, to_string(key))
end
