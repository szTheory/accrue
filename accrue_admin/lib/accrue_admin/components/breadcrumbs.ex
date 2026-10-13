defmodule AccrueAdmin.Components.Breadcrumbs do
  @moduledoc """
  Page-header breadcrumb trail for mounted admin pages.
  """

  use Phoenix.Component

  attr(:items, :list, required: true)
  attr(:group, :string, default: nil)

  def breadcrumbs(assigns) do
    items = normalize_items(assigns.items)
    items = if assigns.group && items != [], do: [%{label: assigns.group} | items], else: items
    assigns = assign(assigns, :items, items)

    ~H"""
    <nav class="ax-breadcrumbs" aria-label="Breadcrumb">
      <ol class="ax-breadcrumbs-list">
        <li :for={{item, index} <- Enum.with_index(@items)} class="ax-breadcrumbs-item">
          <a :if={item[:href]} href={item[:href]} class="ax-breadcrumbs-link" title={item[:label]}>
            <%= item[:label] %>
          </a>
          <span
            :if={!item[:href]}
            class={if(index == length(@items) - 1, do: "ax-breadcrumbs-current", else: "ax-breadcrumbs-group")}
            aria-current={if(index == length(@items) - 1, do: "page", else: nil)}
            title={item[:label]}
          >
            <%= item[:label] %>
          </span>
          <span :if={index < length(@items) - 1} class="ax-breadcrumbs-separator" aria-hidden="true">
            /
          </span>
        </li>
      </ol>
    </nav>
    """
  end

  defp normalize_items(items) do
    labeled_items =
      Enum.filter(items, fn
        %{label: label} when is_binary(label) -> String.trim(label) != ""
        _item -> false
      end)

    current_item = List.last(labeled_items)

    parents =
      labeled_items
      |> Enum.drop(-1)
      |> Enum.filter(fn item -> valid_href?(item[:href]) end)

    case current_item do
      nil -> parents
      item -> parents ++ [Map.delete(item, :href)]
    end
  end

  defp valid_href?(href), do: is_binary(href) and String.trim(href) != ""
end
