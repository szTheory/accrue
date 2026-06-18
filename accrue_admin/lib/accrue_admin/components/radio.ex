defmodule AccrueAdmin.Components.Radio do
  @moduledoc """
  Shared radio button form control for mounted admin pages.

  Renders an inline `ax-field-inline` label wrapping a native
  `<input type="radio">`. Group all radio buttons under the same
  `name` to form a radio group; only one can be selected at a time.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:checked, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  attr(:rest, :global, include: ~w(phx-click phx-value-id form phx-hook))

  def radio(assigns) do
    ~H"""
    <label class={["ax-field", "ax-field-inline", @disabled && "ax-field-disabled"]}>
      <input
        type="radio"
        id={@id}
        name={@name}
        value={@value}
        class="ax-radio"
        checked={@checked}
        disabled={@disabled}
        {@rest}
      />
      <span class="ax-field-label"><%= @label %></span>
    </label>
    """
  end
end
