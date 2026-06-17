defmodule AccrueAdmin.Components.Tooltip do
  @moduledoc """
  CSS-driven accessible tooltip for mounted admin pages.

  Uses a `:hover` + `:focus-within` CSS reveal pattern — no JS
  required. The tooltip content is positioned via CSS at the
  `--ax-z-popover` (300) layer.

  The trigger slot wraps any keyboard-reachable element (e.g. a
  button or a focusable icon). The tooltip content is linked via
  `role="tooltip"` for screen reader announcements. Callers can
  additionally wire `aria-describedby` on the trigger to the
  tooltip content ID for explicit association.

  Example:

      <.tooltip content="Copy to clipboard" position="above">
        <button type="button" aria-label="Copy">…</button>
      </.tooltip>
  """

  use Phoenix.Component

  attr(:content, :string, required: true)
  attr(:position, :string, default: "above", values: ~w(above below))
  attr(:class, :string, default: nil)

  attr(:rest, :global, include: ~w(aria-describedby))

  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <span class={["ax-tooltip-wrapper", "ax-tooltip-#{@position}", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
      <span role="tooltip" class="ax-tooltip-content"><%= @content %></span>
    </span>
    """
  end
end
