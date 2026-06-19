defmodule AccrueAdmin.Components.DetailDrawer do
  @moduledoc """
  Shared detail drawer that becomes a full-screen sheet on mobile.
  """

  use Phoenix.Component

  attr(:id, :string, default: "detail-drawer")
  attr(:open, :boolean, default: false)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:eyebrow, :string, default: "Details")
  attr(:close_label, :string, default: "Close")
  attr(:close_href, :string, default: nil)
  attr(:close_event, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(phx-click phx-target))
  slot(:actions)
  slot(:inner_block, required: true)
  slot(:footer)

  def detail_drawer(assigns) do
    assigns =
      assigns
      |> assign(:description_id, if(assigns.subtitle, do: "#{assigns.id}-description", else: nil))
      |> assign(:focus_trap_close_event, focus_trap_close_event(assigns))
      |> assign(:focus_trap_close_target, rest_value(assigns.rest, "phx-target"))
      |> assign(:focus_trap_fallback, "##{assigns.id}-title")

    ~H"""
    <section
      :if={@open}
      id={@id}
      class={["ax-detail-drawer-shell", @class]}
      data-component-group="drawer-form"
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={@description_id}
      phx-hook="FocusTrap"
      data-focus-trap-close-event={@focus_trap_close_event}
      data-focus-trap-close-target={@focus_trap_close_target}
      data-focus-trap-fallback={@focus_trap_fallback}
      phx-mounted={Phoenix.LiveView.JS.show(transition: {"ax-drawer-entering", "ax-drawer-enter-from", "ax-drawer-enter-to"}, time: 240)}
      phx-remove={Phoenix.LiveView.JS.hide(transition: {"ax-drawer-leaving", "ax-drawer-leave-from", "ax-drawer-leave-to"}, time: 140)}
    >
      <%!-- enter: --ax-dur-3 (240ms); exit: --ax-dur-exit (140ms) --%>
      <div
        class="ax-detail-drawer-backdrop"
        aria-hidden="true"
        phx-click={@focus_trap_close_event}
        phx-target={@focus_trap_close_target}
        phx-mounted={Phoenix.LiveView.JS.show(transition: {"ax-drawer-backdrop-entering", "ax-drawer-backdrop-enter-from", "ax-drawer-backdrop-enter-to"}, time: 240)}
        phx-remove={Phoenix.LiveView.JS.hide(transition: {"ax-drawer-backdrop-leaving", "ax-drawer-backdrop-leave-from", "ax-drawer-backdrop-leave-to"}, time: 140)}
      ></div>
      <aside class="ax-detail-drawer">
        <header class="ax-detail-drawer-header">
          <div>
            <p class="ax-eyebrow"><%= @eyebrow %></p>
            <h2 id={"#{@id}-title"} class="ax-heading" tabindex="-1" data-focus-trap-fallback><%= @title %></h2>
            <p :if={@subtitle} id={@description_id} class="ax-body"><%= @subtitle %></p>
          </div>

          <div class="ax-detail-drawer-actions">
            <%= render_slot(@actions) %>
            <a :if={@close_href} href={@close_href} class="ax-button ax-button-ghost">
              <%= @close_label %>
            </a>
            <button :if={!@close_href} type="button" class="ax-button ax-button-ghost" {@rest}>
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

  defp focus_trap_close_event(assigns) do
    assigns.close_event || rest_value(assigns.rest, "phx-click")
  end

  defp rest_value(rest, key) when is_map(rest) do
    Map.get(rest, key) || Map.get(rest, String.to_existing_atom(key))
  rescue
    ArgumentError -> Map.get(rest, key)
  end

  defp rest_value(_rest, _key), do: nil
end
