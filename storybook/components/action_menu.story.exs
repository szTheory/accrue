defmodule AccrueAdmin.Storybook.Components.ActionMenu do
  @moduledoc """
  Storybook coverage for the Phase 195 action-menu primitive.
  """

  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias AccrueAdmin.Components.DropdownMenu
  alias Phoenix.LiveView.JS
  alias PhoenixStorybook.Stories.Variation

  def function, do: &__MODULE__.action_menu_story/1

  def variations do
    if Code.ensure_loaded?(AccrueAdmin.Components.DropdownMenu) do
      [
        %Variation{
          id: :default,
          description: "Default closed action menu",
          attributes: %{story_id: "default", state: :default, groups: full_groups()}
        },
        %Variation{
          id: :open,
          description: "Open menu panel",
          attributes: %{story_id: "open", state: :open, groups: full_groups()}
        },
        %Variation{
          id: :danger,
          description: "Danger zone separated last",
          attributes: %{story_id: "danger", state: :open, groups: danger_groups()}
        },
        %Variation{
          id: :provider_pruned,
          description: "Provider-pruned Braintree action set",
          attributes: %{
            story_id: "provider-pruned",
            state: :open,
            groups: provider_pruned_groups()
          }
        },
        %Variation{
          id: :focus,
          description: "Keyboard focus on trigger",
          attributes: %{story_id: "focus", state: :focus, groups: full_groups()}
        }
      ]
    else
      []
    end
  end

  def action_menu_story(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:story_id, fn -> "action-menu" end)
      |> Phoenix.Component.assign_new(:state, fn -> :default end)
      |> Phoenix.Component.assign_new(:groups, fn -> full_groups() end)
      |> Phoenix.Component.assign(
        :menu_id,
        "storybook-action-menu-#{assigns[:story_id] || "default"}"
      )

    ~H"""
    <section class="ax-card ax-stack-md" phx-mounted={mounted_state(@state, @menu_id)}>
      <div>
        <p class="ax-eyebrow">Subscription actions</p>
        <h3 class="ax-heading">Action menu</h3>
        <p class="ax-body">
          The menu is rendered by `DropdownMenu.action_menu/1`; Storybook only seeds synthetic
          action groups and, for open/focus states, sets native disclosure state in the sandbox.
        </p>
      </div>

      <DropdownMenu.action_menu id={@menu_id} label="More actions" groups={@groups} />
    </section>
    """
  end

  defp mounted_state(:open, id), do: JS.set_attribute({"open", ""}, to: "##{id}")

  defp mounted_state(:focus, id) do
    JS.set_attribute({"open", ""}, to: "##{id}")
    |> JS.focus(to: "##{id} summary")
  end

  defp mounted_state(_state, _id), do: %JS{}

  defp full_groups do
    [
      %{
        label: "Edit billing",
        items: [
          action_item("Update quantity", "update_quantity", "Adjust seats"),
          action_item("Add item", "add_item", "Attach another price"),
          action_item("Remove item", "remove_item", "Remove a metered item")
        ]
      },
      %{
        label: "Collection",
        items: [
          action_item("Pause collection", "pause", "Pause invoice collection"),
          action_item("Resume", "resume", "Resume normal billing")
        ]
      },
      %{
        label: "Danger zone",
        items: [
          action_item("Cancel immediately", "cancel_now", "Ends service now", danger?: true),
          action_item("Comp this subscription", "comp_subscription", "Creates a replacement",
            danger?: true
          )
        ]
      }
    ]
  end

  defp danger_groups do
    [
      %{
        label: "Danger zone",
        items: [
          action_item("Cancel immediately", "cancel_now", "Ends service now", danger?: true),
          action_item("Comp this subscription", "comp_subscription", "Creates a replacement",
            danger?: true
          )
        ]
      }
    ]
  end

  defp provider_pruned_groups do
    [
      %{
        label: "Danger zone",
        items: [
          action_item("Cancel immediately", "cancel_now", "Stripe-only path hidden in this story",
            danger?: true
          )
        ]
      }
    ]
  end

  defp action_item(label, value, description, opts \\ []) do
    %{
      label: label,
      event: "open_action_drawer",
      value: value,
      description: description,
      hidden_context: "for subscription sub_storybook_phase195",
      danger?: Keyword.get(opts, :danger?, false)
    }
  end
end
