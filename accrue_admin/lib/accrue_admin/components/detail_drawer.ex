defmodule AccrueAdmin.Components.DetailDrawer do
  @moduledoc """
  Shared detail drawer that becomes a full-screen sheet on mobile.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Overlay

  attr(:id, :string, default: "detail-drawer")
  attr(:open, :boolean, default: false)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:eyebrow, :string, default: "Details")
  attr(:close_label, :string, default: "Close")
  attr(:close_href, :string, default: nil)
  attr(:close_event, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(phx-click phx-target))
  slot(:actions)
  slot(:inner_block, required: true)
  slot(:footer)

  def detail_drawer(assigns) do
    assigns =
      assigns
      |> assign(:focus_trap_close_event, focus_trap_close_event(assigns))
      |> assign(:focus_trap_close_target, rest_value(assigns.rest, "phx-target"))

    ~H"""
    <Overlay.overlay
      id={@id}
      open={@open}
      presentation={:drawer}
      title={@title}
      subtitle={@subtitle}
      close_label={drawer_close_label(@close_href, @close_label)}
      close_event={@focus_trap_close_event}
      close_target={@focus_trap_close_target}
      component_group="drawer-form"
      class={@class}
    >
      <:actions>
        <%= render_slot(@actions) %>
        <a :if={@close_href} href={@close_href} class="ax-button ax-button-ghost">
          <%= @close_label %>
        </a>
      </:actions>

      <%= render_slot(@inner_block) %>

      <:footer :if={@footer != []}>
        <%= render_slot(@footer) %>
      </:footer>
    </Overlay.overlay>
    """
  end

  defp drawer_close_label(nil, close_label), do: close_label
  defp drawer_close_label("", close_label), do: close_label
  defp drawer_close_label(_close_href, _close_label), do: ""

  defp focus_trap_close_event(assigns) do
    assigns.close_event || rest_value(assigns.rest, "phx-click")
  end

  defp rest_value(rest, key) when is_map(rest) do
    Map.get(rest, key) || Map.get(rest, String.to_existing_atom(key))
  rescue
    ArgumentError -> Map.get(rest, key)
  end

  defp rest_value(_rest, _key), do: nil
end
