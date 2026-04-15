defmodule AccrueAdmin.Components.Button do
  @moduledoc """
  Shared button primitive for admin actions and links.
  """

  use Phoenix.Component

  attr(:variant, :string, default: "primary")
  attr(:type, :string, default: "button")
  attr(:href, :string, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(method name value form phx-click phx-submit phx-value-id aria-label))
  slot(:inner_block, required: true)

  def button(assigns) do
    classes = ["ax-button", button_variant_class(assigns.variant), assigns.class]
    assigns = assign(assigns, :classes, classes)

    ~H"""
    <a :if={@href} href={@href} class={@classes} aria-disabled={if(@disabled, do: "true", else: nil)} {@rest}>
      <%= render_slot(@inner_block) %>
    </a>
    <button :if={!@href} type={@type} class={@classes} disabled={@disabled} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_variant_class("secondary"), do: "ax-button-secondary"
  defp button_variant_class("ghost"), do: "ax-button-ghost"
  defp button_variant_class("danger"), do: "ax-button-danger"
  defp button_variant_class(_variant), do: "ax-button-primary"
end
