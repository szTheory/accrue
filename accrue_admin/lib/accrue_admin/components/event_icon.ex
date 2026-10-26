defmodule AccrueAdmin.Components.EventIcon do
  @moduledoc "Decorative billing-event family icon; the adjacent text carries the meaning."

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon
  alias AccrueAdmin.EventPresentation

  attr(:type, :any, required: true)
  attr(:size, :string, default: "sm", values: ~w(sm md lg))

  def event_icon(assigns) do
    assigns = assign(assigns, :presentation, EventPresentation.for(assigns.type))

    ~H"""
    <Icon.icon
      name={@presentation.icon}
      size={@size}
      class={["ax-event-icon", "ax-event-icon-#{@presentation.tone}"]}
      data-event-family={@presentation.family}
    />
    """
  end
end
