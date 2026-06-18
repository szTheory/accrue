defmodule AccrueAdmin.Components.Checkbox do
  @moduledoc """
  Shared checkbox form control for mounted admin pages.

  Renders an inline `ax-field-inline` label wrapping the native
  `<input type="checkbox">`. Supports three states: unchecked,
  checked, and indeterminate. Because `indeterminate` is not a
  standard HTML attribute it must be set via a JS hook or
  `phx-hook`; this component emits `data-indeterminate` for
  the hook to pick up, and sets `aria-checked="mixed"` for
  screen readers when indeterminate is true.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:checked, :boolean, default: false)
  attr(:indeterminate, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:class, :string, default: nil)

  attr(:rest, :global, include: ~w(phx-click phx-value-id value form phx-hook))

  def checkbox(assigns) do
    ~H"""
    <label class={["ax-field", "ax-field-inline", @disabled && "ax-field-disabled", @class]}>
      <input
        type="checkbox"
        id={@id}
        name={@name}
        class="ax-checkbox"
        checked={@checked}
        disabled={@disabled}
        aria-checked={if @indeterminate, do: "mixed", else: nil}
        data-indeterminate={@indeterminate}
        {@rest}
      />
      <span class="ax-field-label"><%= @label %></span>
    </label>
    """
  end
end
