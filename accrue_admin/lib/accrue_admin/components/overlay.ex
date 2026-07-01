defmodule AccrueAdmin.Components.Overlay do
  @moduledoc """
  Canonical overlay substrate for admin modals, drawers, and popovers.

  The component owns the shared portal, focus, close, and presentation markup.
  Domain-specific actions stay in the calling LiveView or wrapper component.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:presentation, :atom, default: :modal)
  attr(:title, :string, required: true)
  attr(:title_id, :string, default: nil)
  attr(:subtitle, :string, default: nil)
  attr(:description_id, :string, default: nil)
  attr(:close_label, :string, default: "Close")
  attr(:close_event, :string, default: nil)
  attr(:close_target, :string, default: nil)
  attr(:initial_focus, :string, default: nil)
  attr(:component_group, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(phx-click phx-target))

  slot(:actions)
  slot(:inner_block, required: true)
  slot(:footer)

  def overlay(assigns) do
    assigns =
      assigns
      |> assign(:presentation_name, presentation_name(assigns.presentation))
      |> assign(:portal_id, "#{assigns.id}-portal")
      |> assign(:resolved_title_id, assigns.title_id || "#{assigns.id}-title")
      |> assign(:resolved_description_id, description_id(assigns))
      |> assign(:focus_trap_close_event, focus_trap_close_event(assigns))
      |> assign(:focus_trap_close_target, focus_trap_close_target(assigns))
      |> assign(:focus_trap_fallback, "##{assigns.title_id || "#{assigns.id}-title"}")
      |> assign(:role, role_for(assigns.presentation))
      |> assign(:aria_modal, aria_modal_for(assigns.presentation))
      |> assign(:scroll_lock, scroll_lock?(assigns.presentation))
      |> assign(:shell_class, shell_class(assigns.presentation, assigns.class))
      |> assign(:backdrop_class, backdrop_class(assigns.presentation))
      |> assign(:panel_class, panel_class(assigns.presentation))
      |> assign(:panel_tag, panel_tag(assigns.presentation))
      |> assign(:header_class, header_class(assigns.presentation))
      |> assign(:actions_class, actions_class(assigns.presentation))
      |> assign(:body_class, body_class(assigns.presentation))
      |> assign(:footer_class, footer_class(assigns.presentation))
      |> assign(:show_backdrop, backdrop?(assigns.presentation))

    ~H"""
    <.portal :if={@open} id={@portal_id} target="#ax-overlay-root">
      <section
        id={@id}
        class={@shell_class}
        data-ax-overlay-shell
        data-component-group={@component_group}
        data-presentation={@presentation_name}
        data-scroll-lock={@scroll_lock}
        phx-hook="Overlay"
        data-focus-trap-close-event={@focus_trap_close_event}
        data-focus-trap-close-target={@focus_trap_close_target}
        data-focus-trap-fallback={@focus_trap_fallback}
        data-focus-trap-initial={@initial_focus}
        phx-mounted={mounted_transition(@presentation)}
        phx-remove={remove_transition(@presentation)}
      >
        <div
          :if={@show_backdrop}
          class={@backdrop_class}
          data-ax-overlay-backdrop
          aria-hidden="true"
          phx-click={@focus_trap_close_event}
          phx-target={@focus_trap_close_target}
        >
        </div>

        <.dynamic_tag
          tag_name={@panel_tag}
          class={@panel_class}
          data-ax-overlay-panel
          data-presentation={@presentation_name}
          role={@role}
          aria-modal={@aria_modal}
          aria-labelledby={@resolved_title_id}
          aria-describedby={@resolved_description_id}
        >
          <header class={@header_class}>
            <div>
              <h2 id={@resolved_title_id} class="ax-heading" tabindex="-1" data-focus-trap-fallback>
                <%= @title %>
              </h2>
              <p :if={@subtitle} id={@resolved_description_id} class="ax-body"><%= @subtitle %></p>
            </div>

            <div :if={@actions != [] || close_label?(@close_label)} class={@actions_class}>
              <%= render_slot(@actions) %>
              <button
                :if={close_label?(@close_label)}
                type="button"
                class="ax-button ax-button-ghost"
                phx-click={@focus_trap_close_event}
                phx-target={@focus_trap_close_target}
              >
                <%= @close_label %>
              </button>
            </div>
          </header>

          <div class={@body_class}>
            <%= render_slot(@inner_block) %>
          </div>

          <footer :if={@footer != []} class={@footer_class}>
            <%= render_slot(@footer) %>
          </footer>
        </.dynamic_tag>
      </section>
    </.portal>
    """
  end

  defp presentation_name(presentation),
    do: presentation |> normalize_presentation() |> Atom.to_string()

  defp description_id(%{description_id: description_id}) when is_binary(description_id),
    do: description_id

  defp description_id(%{subtitle: subtitle, id: id}) when is_binary(subtitle),
    do: "#{id}-description"

  defp description_id(_assigns), do: nil

  defp normalize_presentation(presentation) when presentation in [:modal, :drawer, :popover],
    do: presentation

  defp normalize_presentation(_presentation), do: :modal

  defp role_for(:popover), do: "menu"
  defp role_for(_presentation), do: "dialog"

  defp aria_modal_for(:popover), do: nil
  defp aria_modal_for(_presentation), do: "true"

  defp scroll_lock?(:popover), do: nil
  defp scroll_lock?(_presentation), do: true

  defp backdrop?(:popover), do: false
  defp backdrop?(_presentation), do: true

  defp shell_class(:drawer, extra_class),
    do: ["ax-overlay-shell", "ax-detail-drawer-shell", extra_class]

  defp shell_class(:modal, extra_class),
    do: ["ax-overlay-shell", "ax-step-up-modal-shell", extra_class]

  defp shell_class(:popover, extra_class),
    do: ["ax-overlay-shell", "ax-overlay-popover-shell", extra_class]

  defp shell_class(_presentation, extra_class), do: shell_class(:modal, extra_class)

  defp backdrop_class(:drawer), do: "ax-detail-drawer-backdrop"
  defp backdrop_class(:modal), do: "ax-step-up-modal-backdrop"
  defp backdrop_class(_presentation), do: "ax-overlay-backdrop"

  defp panel_class(:drawer), do: ["ax-overlay-panel", "ax-detail-drawer"]
  defp panel_class(:modal), do: ["ax-overlay-panel", "ax-card", "ax-step-up-modal"]
  defp panel_class(:popover), do: ["ax-overlay-panel", "ax-dropdown-panel"]
  defp panel_class(_presentation), do: panel_class(:modal)

  defp panel_tag(:drawer), do: "aside"
  defp panel_tag(:modal), do: "article"
  defp panel_tag(_presentation), do: "div"

  defp header_class(:drawer), do: "ax-detail-drawer-header"
  defp header_class(:modal), do: "ax-page-header"
  defp header_class(_presentation), do: "ax-overlay-popover-header"

  defp actions_class(:drawer), do: "ax-detail-drawer-actions"
  defp actions_class(:modal), do: "ax-step-up-modal-actions"
  defp actions_class(_presentation), do: "ax-overlay-popover-actions"

  defp body_class(:drawer), do: "ax-detail-drawer-body"
  defp body_class(:modal), do: "ax-step-up-modal-body"
  defp body_class(_presentation), do: "ax-overlay-popover-body"

  defp footer_class(:drawer), do: "ax-detail-drawer-footer"
  defp footer_class(:modal), do: "ax-step-up-modal-actions"
  defp footer_class(_presentation), do: "ax-overlay-popover-footer"

  defp close_label?(label) when is_binary(label), do: String.trim(label) != ""
  defp close_label?(_label), do: false

  defp mounted_transition(:drawer) do
    Phoenix.LiveView.JS.show(
      transition: {"ax-drawer-entering", "ax-drawer-enter-from", "ax-drawer-enter-to"},
      time: 240
    )
  end

  defp mounted_transition(_presentation), do: Phoenix.LiveView.JS.push_focus()

  defp remove_transition(:drawer) do
    Phoenix.LiveView.JS.hide(
      transition: {"ax-drawer-leaving", "ax-drawer-leave-from", "ax-drawer-leave-to"},
      time: 140
    )
  end

  defp remove_transition(_presentation), do: Phoenix.LiveView.JS.pop_focus()

  defp focus_trap_close_event(assigns),
    do: assigns.close_event || rest_value(assigns.rest, "phx-click")

  defp focus_trap_close_target(assigns) do
    assigns.close_target || rest_value(assigns.rest, "phx-target")
  end

  defp rest_value(rest, key) when is_map(rest) do
    Map.get(rest, key) || Map.get(rest, String.to_existing_atom(key))
  rescue
    ArgumentError -> Map.get(rest, key)
  end

  defp rest_value(_rest, _key), do: nil
end
