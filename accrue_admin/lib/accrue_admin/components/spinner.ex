defmodule AccrueAdmin.Components.Spinner do
  @moduledoc """
  Accessible loading spinner display primitive for mounted admin pages.

  Non-interactive; `role="status"` and `aria-live="polite"` announce
  the loading state to screen readers. `aria-label` provides the
  accessible name (defaults to "Loading…"). The visual animation is
  handled entirely by CSS via the `.ax-spinner-track` inner element —
  no SVG or inline animation needed in the component markup.
  """

  use Phoenix.Component

  attr(:size, :string, default: "sm", values: ~w(sm md lg))
  attr(:label, :string, default: "Loading…")
  attr(:class, :string, default: nil)

  def spinner(assigns) do
    ~H"""
    <span
      class={["ax-spinner", "ax-spinner-#{@size}", @class]}
      role="status"
      aria-label={@label}
      aria-live="polite"
    >
      <span class="ax-spinner-track" aria-hidden="true"></span>
    </span>
    """
  end
end
