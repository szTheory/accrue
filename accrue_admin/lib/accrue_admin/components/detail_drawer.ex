defmodule AccrueAdmin.Components.DetailDrawer do
  @moduledoc """
  Shared detail drawer that becomes a full-screen sheet on mobile.
  """

  use Phoenix.Component

  attr(:open, :boolean, default: false)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:eyebrow, :string, default: "Details")
  attr(:close_label, :string, default: "Close")
  attr(:close_href, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(phx-click phx-target))
  slot(:actions)
  slot(:inner_block, required: true)
  slot(:footer)

  def detail_drawer(assigns) do
    ~H"""
    <section
      :if={@open}
      class={["ax-detail-drawer-shell", @class]}
      role="dialog"
      aria-modal="true"
      aria-labelledby="detail-drawer-title"
      {@rest}
    >
      <div class="ax-detail-drawer-backdrop" aria-hidden="true"></div>
      <aside class="ax-detail-drawer">
        <header class="ax-detail-drawer-header">
          <div>
            <p class="ax-eyebrow"><%= @eyebrow %></p>
            <h2 id="detail-drawer-title" class="ax-heading"><%= @title %></h2>
            <p :if={@subtitle} class="ax-body"><%= @subtitle %></p>
          </div>

          <div class="ax-detail-drawer-actions">
            <%= render_slot(@actions) %>
            <a :if={@close_href} href={@close_href} class="ax-button ax-button-ghost">
              <%= @close_label %>
            </a>
            <button :if={!@close_href} type="button" class="ax-button ax-button-ghost">
              <%= @close_label %>
            </button>
          </div>
        </header>

        <div class="ax-detail-drawer-body">
          <%= render_slot(@inner_block) %>
        </div>

        <footer :if={@footer != []} class="ax-detail-drawer-footer">
          <%= render_slot(@footer) %>
        </footer>
      </aside>
    </section>
    """
  end
end
