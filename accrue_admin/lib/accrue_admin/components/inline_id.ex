defmodule AccrueAdmin.Components.InlineId do
  @moduledoc """
  Display span for short IDs, Stripe IDs, and event IDs.

  Applies overflow truncation per the CMP-02 overflow contract:
  `overflow: hidden; text-overflow: ellipsis; white-space: nowrap`
  constrained to a CSS `max-width` (default 16ch). The `title`
  attribute provides full-text access on hover/focus for assistive
  technology and mouse users.

  The `@max_width` attr is a structural constraint (not a design
  override) and is exempt from the CMP-05 inline-style guard, which
  targets ax-button/ax-field/ax-input/ax-select/ax-status-badge/
  ax-money/ax-json. The ax-inline-id class is not in that list.
  """

  use Phoenix.Component

  attr(:id_value, :string, required: true)
  attr(:max_width, :string, default: "16ch")
  attr(:class, :string, default: nil)

  attr(:rest, :global)

  def inline_id(assigns) do
    ~H"""
    <%!-- max-width is a structural constraint from @max_width attr (computed prop, not a design override). Exempt from the CMP-05 inline-style guard, which targets ax-button/ax-field/ax-input/ax-select/ax-status-badge/ax-money/ax-json — ax-inline-id is not in that list. --%>
    <code
      class={["ax-inline-id", @class]}
      style={"max-width: #{@max_width};"}
      title={@id_value}
      {@rest}
    ><%= @id_value %></code>
    """
  end
end
