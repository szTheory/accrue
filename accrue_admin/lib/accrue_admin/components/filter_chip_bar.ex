defmodule AccrueAdmin.Components.FilterChipBar do
  @moduledoc """
  Shared chip-style filter state for URL-synced admin list pages.
  """

  use Phoenix.Component

  attr(:items, :list, required: true)
  attr(:label, :string, default: "Active filters")
  attr(:empty_label, :string, default: "No filters applied")
  attr(:class, :string, default: nil)

  def filter_chip_bar(assigns) do
    assigns =
      assigns
      |> assign(:active_items, Enum.filter(assigns.items, &chip_active?/1))
      |> assign(:has_items, Enum.any?(assigns.items, &chip_active?/1))

    ~H"""
    <section class={["ax-filter-chip-bar", @class]} aria-label={@label}>
      <header class="ax-filter-chip-header">
        <p class="ax-eyebrow">Filters</p>
        <p class="ax-body"><%= @label %></p>
      </header>

      <div :if={@has_items} class="ax-filter-chip-list">
        <.chip :for={item <- @active_items} item={item} />
      </div>

      <p :if={!@has_items} class="ax-body ax-filter-chip-empty"><%= @empty_label %></p>
    </section>
    """
  end

  attr(:item, :map, required: true)

  defp chip(assigns) do
    assigns =
      assigns
      |> assign(:tone, chip_tone(assigns.item))
      |> assign(:label_text, chip_label(assigns.item))
      |> assign(:value_text, chip_value(assigns.item))

    ~H"""
    <span class={["ax-filter-chip", "ax-filter-chip-" <> @tone]} data-filter={Map.get(@item, :id)}>
      <span class="ax-filter-chip-label"><%= @label_text %></span>
      <span :if={@value_text} class="ax-filter-chip-value"><%= @value_text %></span>
      <a
        :if={Map.get(@item, :remove_href)}
        href={Map.get(@item, :remove_href)}
        class="ax-filter-chip-action"
        aria-label={"Remove #{chip_accessible_label(@item)} filter"}
      >
        Clear
      </a>
    </span>
    """
  end

  defp chip_active?(item), do: Map.get(item, :active, true)

  defp chip_tone(item) do
    case Map.get(item, :tone) do
      tone when tone in ["moss", "cobalt", "amber", "slate", "ink"] -> tone
      tone when tone in [:moss, :cobalt, :amber, :slate, :ink] -> Atom.to_string(tone)
      _ -> "cobalt"
    end
  end

  defp chip_label(item), do: Map.get(item, :label) || humanize(Map.get(item, :id)) || "Filter"
  defp chip_value(item), do: present_value(Map.get(item, :value))

  defp chip_accessible_label(item) do
    [chip_label(item), chip_value(item)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp present_value(nil), do: nil
  defp present_value(""), do: nil
  defp present_value(value) when is_binary(value), do: value
  defp present_value(value) when is_atom(value), do: humanize(value)
  defp present_value(%Date{} = value), do: Date.to_iso8601(value)
  defp present_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp present_value(value), do: to_string(value)

  defp humanize(nil), do: nil
  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
