defmodule AccrueAdmin.Components.Toggle do
  @moduledoc """
  Accessible toggle switch (ARIA switch role) for mounted admin pages.

  Uses `role="switch"` and `aria-checked` per the ARIA Authoring
  Practices Guide (APG). Keyboard users can activate via Space or
  Enter. An optional hidden `<input type="hidden">` can emit the
  boolean form value when wired (see `hidden_name` attr).

  The `<button role="switch">` approach is preferred over a native
  checkbox because it provides cleaner visual separation between
  the toggle track/thumb and the label affordance.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:on, :boolean, default: false)
  attr(:disabled, :boolean, default: false)

  attr(:rest, :global, include: ~w(phx-click phx-value-id form phx-hook))

  def toggle(assigns) do
    ~H"""
    <label class={["ax-field", "ax-field-inline", @disabled && "ax-field-disabled"]}>
      <button
        type="button"
        id={@id}
        class="ax-toggle"
        role="switch"
        aria-checked={if @on, do: "true", else: "false"}
        aria-labelledby={@id <> "-label"}
        disabled={@disabled}
        {@rest}
      >
        <span class="ax-toggle-track">
          <span class="ax-toggle-thumb" />
        </span>
      </button>
      <input type="hidden" name={@name} value={if @on, do: "true", else: "false"} />
      <span id={@id <> "-label"} class="ax-field-label"><%= @label %></span>
    </label>
    """
  end
end
