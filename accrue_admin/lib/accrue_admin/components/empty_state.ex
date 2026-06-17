defmodule AccrueAdmin.Components.EmptyState do
  @moduledoc """
  Non-interactive empty-state hero container for mounted admin pages.

  Displays a centered icon, title, and body copy. An optional
  `actions` slot renders a CTA (e.g. a `<.button>` component) inside
  the hero — the wrapper itself carries NO interactive affordances
  (`tabindex`, `role="button"`, `phx-click`, `:hover` cursor change).

  CMP-03 contract: this element must have `cursor: default` (not
  `pointer`) and no role implying interactivity. Only the element
  inside `actions` slot is interactive.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon

  attr(:icon, :atom, required: true)
  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:class, :string, default: nil)

  slot(:actions)

  def empty_state(assigns) do
    ~H"""
    <div class={["ax-empty", @class]}>
      <Icon.icon name={@icon} size="lg" class="ax-empty-icon ax-empty-icon-muted" />
      <p class="ax-type-title ax-empty-title"><%= @title %></p>
      <p class="ax-type-body-sm ax-muted ax-empty-copy"><%= @body %></p>
      <div :if={@actions != []} class="ax-empty-actions">
        <%= render_slot(@actions) %>
      </div>
    </div>
    """
  end
end
