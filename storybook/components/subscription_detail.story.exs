defmodule AccrueAdmin.Storybook.Components.SubscriptionDetail do
  @moduledoc """
  Storybook coverage for the Phase 195 Subscription detail exemplar shape.
  """

  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias AccrueAdmin.Components.Detail
  alias AccrueAdmin.Components.DropdownMenu
  alias AccrueAdmin.Components.RelatedResources
  alias AccrueAdmin.Components.StatusBadge
  alias PhoenixStorybook.Stories.Variation

  def function, do: &__MODULE__.subscription_detail_story/1

  def variations do
    if Code.ensure_loaded?(AccrueAdmin.Components.Detail) and
         Code.ensure_loaded?(AccrueAdmin.Components.DropdownMenu) do
      [
        %Variation{
          id: :populated,
          description: "Populated Subscription detail exemplar",
          attributes: %{state: :populated}
        },
        %Variation{
          id: :braintree_pruned,
          description: "Braintree-pruned action set",
          attributes: %{state: :braintree_pruned}
        },
        %Variation{
          id: :dunning_active,
          description: "Dunning-active with recovery drill open",
          attributes: %{state: :dunning_active}
        }
      ]
    else
      []
    end
  end

  def subscription_detail_story(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:state, fn -> :populated end)
      |> Phoenix.Component.assign(:summary_rows, summary_rows(assigns[:state] || :populated))
      |> Phoenix.Component.assign(:action_groups, action_groups(assigns[:state] || :populated))
      |> Phoenix.Component.assign(:related_items, related_items())

    ~H"""
    <section class="ax-page ax-stack-xl" data-story-subscription-detail={@state}>
      <Detail.summary_card eyebrow="Subscription detail" title="sub_storybook_phase195">
        <:status><StatusBadge.status_badge status={status_for(@state)} /></:status>
        <:facts>
          <span>Acme Research</span>
          <span>period ends Jul 26, 2026 00:00 UTC</span>
          <span><%= lifecycle_text(@state) %></span>
        </:facts>
      </Detail.summary_card>

      <Detail.summary_list rows={@summary_rows} />

      <section class="ax-card ax-detail-action-band" data-ax-action-band>
        <header class="ax-page-header">
          <div>
            <p class="ax-eyebrow">Actions</p>
            <h3 class="ax-heading">Subscription actions</h3>
          </div>
          <div class="ax-page-actions">
            <button
              type="button"
              class="ax-button ax-button-primary"
              data-ax-primary-action
            >
              Change plan
            </button>
            <button
              :if={@state != :braintree_pruned}
              type="button"
              class="ax-button ax-button-secondary"
              data-ax-primary-action
            >
              Cancel renewal
            </button>
            <DropdownMenu.action_menu
              id={"storybook-subscription-actions-#{@state}"}
              label="More actions"
              groups={@action_groups}
            />
          </div>
        </header>
      </section>

      <section class="ax-stack-xl" aria-label="Subscription details">
        <details
          class="ax-detail-section"
          data-ax-drill-section="billing-items"
          open={@state != :dunning_active}
        >
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Billing & items</span>
          </summary>
          <Detail.detail_field_list fields={billing_fields(@state)} />
        </details>

        <details
          class="ax-detail-section"
          data-ax-drill-section="dunning-recovery"
          open={@state == :dunning_active}
        >
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Dunning & recovery</span>
          </summary>
          <p class="ax-body"><%= dunning_copy(@state) %></p>
        </details>

        <details class="ax-detail-section" data-ax-drill-section="tax-compliance">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Tax & compliance</span>
          </summary>
          <Detail.detail_field_list
            fields={[
              %{label: "Ownership", value: "Customer taxable"},
              %{label: "Tax health", value: "Ready"},
              %{label: "Automatic tax", value: "On"}
            ]}
          />
        </details>
      </section>

      <div data-ax-related-resources>
        <RelatedResources.related_resources items={@related_items} />
      </div>

      <details class="ax-detail-section" data-ax-lazy-activity>
        <summary class="ax-detail-section-head">
          <span class="ax-detail-section-title">Activity</span>
        </summary>
        <p class="ax-body">Open this section to load subscription activity.</p>
      </details>

      <details class="ax-detail-section" data-ax-lazy-json>
        <summary class="ax-detail-section-head">
          <span class="ax-detail-section-title">Raw JSON</span>
        </summary>
        <p class="ax-body">Open this section to load the escaped subscription payload.</p>
      </details>
    </section>
    """
  end

  defp status_for(:dunning_active), do: :past_due
  defp status_for(_state), do: :active

  defp lifecycle_text(:dunning_active), do: "Past due and in recovery."

  defp lifecycle_text(:braintree_pruned),
    do: "Active on Braintree; Stripe-only item actions are hidden."

  defp lifecycle_text(_state), do: "Active and renewing."

  defp summary_rows(:dunning_active) do
    summary_rows(:populated) ++
      [
        %{
          label: "Dunning",
          value: "In recovery",
          action_label: "View",
          action_context: "recovery for subscription sub_storybook_phase195",
          action_event: "load_activity",
          action_value: "dunning"
        }
      ]
  end

  defp summary_rows(state) do
    [
      %{label: "Lifecycle state", value: lifecycle_text(state)},
      %{
        label: "Customer",
        value: "Acme Research",
        action_label: "View",
        action_context: "customer for subscription sub_storybook_phase195",
        action_href: "/billing/customers/cus_storybook_phase195"
      },
      summary_plan_row(state),
      %{label: "Current period", value: "Jun 26, 2026 - Jul 26, 2026"},
      summary_renewal_row(state),
      %{label: "Amount (MRR)", value: "$420.00"},
      summary_quantity_row(state)
    ]
  end

  defp summary_plan_row(:braintree_pruned), do: %{label: "Plan / price", value: "braintree_team"}

  defp summary_plan_row(_state) do
    %{
      label: "Plan / price",
      value: "pro_monthly_2026",
      action_label: "Change",
      action_context: "plan for subscription sub_storybook_phase195",
      action_event: "open_action_drawer",
      action_value: "swap_plan"
    }
  end

  defp summary_renewal_row(:braintree_pruned),
    do: %{label: "Renews / ends", value: "Renews Jul 26, 2026"}

  defp summary_renewal_row(_state) do
    %{
      label: "Renews / ends",
      value: "Renews Jul 26, 2026",
      action_label: "Change",
      action_context: "renewal for subscription sub_storybook_phase195",
      action_event: "open_action_drawer",
      action_value: "cancel_at_period_end"
    }
  end

  defp summary_quantity_row(:braintree_pruned), do: %{label: "Seats / quantity", value: "12"}

  defp summary_quantity_row(_state) do
    %{
      label: "Seats / quantity",
      value: "12",
      action_label: "Change",
      action_context: "quantity for subscription sub_storybook_phase195",
      action_event: "open_action_drawer",
      action_value: "update_quantity"
    }
  end

  defp action_groups(:braintree_pruned) do
    [
      %{
        label: "Danger zone",
        items: [action_item("Comp this subscription", "comp_subscription", danger?: true)]
      }
    ]
  end

  defp action_groups(_state) do
    [
      %{
        label: "Edit billing",
        items: [
          action_item("Update quantity", "update_quantity"),
          action_item("Add item", "add_item"),
          action_item("Remove item", "remove_item")
        ]
      },
      %{
        label: "Collection",
        items: [
          action_item("Pause collection", "pause"),
          action_item("Resume", "resume")
        ]
      },
      %{
        label: "Danger zone",
        items: [
          action_item("Cancel immediately", "cancel_now", danger?: true),
          action_item("Comp this subscription", "comp_subscription", danger?: true)
        ]
      }
    ]
  end

  defp action_item(label, value, opts \\ []) do
    %{
      label: label,
      event: "open_action_drawer",
      value: value,
      hidden_context: "for subscription sub_storybook_phase195",
      danger?: Keyword.get(opts, :danger?, false)
    }
  end

  defp billing_fields(:braintree_pruned) do
    [
      %{label: "Processor", value: "Braintree"},
      %{label: "Plan / price", value: "braintree_team"},
      %{label: "Quantity", value: "12"}
    ]
  end

  defp billing_fields(_state) do
    [
      %{label: "Processor", value: "Stripe"},
      %{label: "Plan / price", value: "pro_monthly_2026"},
      %{label: "Quantity", value: "12"}
    ]
  end

  defp dunning_copy(:dunning_active),
    do: "Recovery is active. Next reminder is scheduled from the dunning campaign anchor."

  defp dunning_copy(_state),
    do:
      "This subscription has not entered recovery. Billing and item details remain available above."

  defp related_items do
    [
      %{
        icon: :users,
        label: "Customer",
        value: "Acme Research",
        href: "/billing/customers/cus_storybook_phase195"
      },
      %{
        icon: :invoices,
        label: "Invoices",
        value: "3 recent invoices",
        href: "/billing/invoices"
      },
      %{icon: :events, label: "Events", value: "Subscription timeline", href: "/billing/events"}
    ]
  end
end
