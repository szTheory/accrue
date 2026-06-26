defmodule AccrueAdmin.Storybook.Components.Overlay do
  @moduledoc """
  Storybook coverage for the canonical Phase 195 overlay primitive.
  """

  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias AccrueAdmin.Components.Overlay
  alias PhoenixStorybook.Stories.Variation

  def function, do: &__MODULE__.overlay_story/1

  def variations do
    if Code.ensure_loaded?(AccrueAdmin.Components.Overlay) do
      [
        %Variation{
          id: :drawer_desktop,
          description: "Drawer - desktop right edge",
          attributes: %{
            story_id: "drawer-desktop",
            title: "Change plan",
            subtitle: "Right-docked drawer with body-level portal target.",
            presentation: :drawer,
            frame: :desktop
          }
        },
        %Variation{
          id: :drawer_mobile,
          description: "Drawer - mobile bottom sheet",
          attributes: %{
            story_id: "drawer-mobile",
            title: "Pause collection",
            subtitle: "Mobile bottom-sheet geometry using the same drawer presentation.",
            presentation: :drawer,
            frame: :mobile
          }
        },
        %Variation{
          id: :modal_shell,
          description: "Modal shell",
          attributes: %{
            story_id: "modal-shell",
            title: "Confirm your identity",
            subtitle: "Modal presentation for step-up confirmation.",
            presentation: :modal,
            frame: :desktop
          }
        },
        %Variation{
          id: :popover_shell,
          description: "Popover shell",
          attributes: %{
            story_id: "popover-shell",
            title: "More actions",
            subtitle: "Non-modal popover shell without backdrop or scroll lock.",
            presentation: :popover,
            frame: :desktop
          }
        },
        %Variation{
          id: :reduced_motion,
          description: "Reduced motion mode",
          attributes: %{
            story_id: "reduced-motion",
            title: "Reduced motion drawer",
            subtitle: "Uses the same component while the surrounding story marks reduced motion.",
            presentation: :drawer,
            frame: :desktop,
            reduced_motion: true
          }
        }
      ]
    else
      []
    end
  end

  def overlay_story(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:story_id, fn -> "overlay" end)
      |> Phoenix.Component.assign_new(:title, fn -> "Overlay" end)
      |> Phoenix.Component.assign_new(:subtitle, fn -> nil end)
      |> Phoenix.Component.assign_new(:presentation, fn -> :drawer end)
      |> Phoenix.Component.assign_new(:frame, fn -> :desktop end)
      |> Phoenix.Component.assign_new(:reduced_motion, fn -> false end)
      |> Phoenix.Component.assign(
        :overlay_id,
        "storybook-overlay-#{assigns[:story_id] || "overlay"}"
      )

    ~H"""
    <div
      class={["ax-stack-md", story_frame_class(@frame)]}
      data-story-overlay-state={@story_id}
      data-reduced-motion={@reduced_motion}
    >
      <div id="ax-overlay-root"></div>

      <section id="accrue-admin-shell" class="ax-card ax-stack-md">
        <p class="ax-eyebrow">Background page</p>
        <h3 class="ax-heading">Subscription detail context</h3>
        <p class="ax-body">
          The overlay renders through the real `Overlay.overlay/1` component and targets the
          body-level root used by the admin shell.
        </p>
      </section>

      <Overlay.overlay
        id={@overlay_id}
        open={true}
        presentation={@presentation}
        title={@title}
        subtitle={@subtitle}
        close_event="storybook_overlay_close"
        initial_focus={"##{@overlay_id}-primary"}
        component_group={component_group(@presentation)}
      >
        <section class="ax-stack-md">
          <p class="ax-body">
            Synthetic subscription data keeps this story safe while proving the Phase 195 overlay
            shell, panel, backdrop, focus, and presentation attributes.
          </p>
          <label class="ax-label" for={"#{@overlay_id}-field"}>Reference</label>
          <input id={"#{@overlay_id}-field"} class="ax-input" value="sub_storybook_phase195" />
        </section>

        <:footer>
          <button id={"#{@overlay_id}-primary"} type="button" class="ax-button ax-button-primary">
            Continue
          </button>
          <button type="button" class="ax-button ax-button-ghost">Cancel</button>
        </:footer>
      </Overlay.overlay>
    </div>
    """
  end

  defp story_frame_class(:mobile), do: "ax-story-mobile-frame"
  defp story_frame_class(_frame), do: "ax-story-desktop-frame"

  defp component_group(:popover), do: "detail-action-menu"
  defp component_group(:modal), do: "modal-confirm"
  defp component_group(_presentation), do: "drawer-form"
end
