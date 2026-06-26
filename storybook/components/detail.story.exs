defmodule AccrueAdmin.Storybook.Components.Detail do
  @moduledoc """
  Storybook coverage for Phase 195 detail summary-list rows.
  """

  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias AccrueAdmin.Components.Detail
  alias PhoenixStorybook.Stories.Variation

  def function, do: &__MODULE__.summary_list_story/1

  def variations do
    if Code.ensure_loaded?(AccrueAdmin.Components.Detail) do
      [
        %Variation{
          id: :read_only,
          description: "Read-only summary rows",
          attributes: %{state: :read_only}
        },
        %Variation{
          id: :change_actions,
          description: "Rows with Change actions",
          attributes: %{state: :change_actions}
        },
        %Variation{
          id: :view_actions,
          description: "Rows with View actions",
          attributes: %{state: :view_actions}
        },
        %Variation{
          id: :long_labels,
          description: "Long labels and values",
          attributes: %{state: :long_labels}
        }
      ]
    else
      []
    end
  end

  def summary_list_story(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:state, fn -> :read_only end)
      |> Phoenix.Component.assign(:rows, rows(assigns[:state] || :read_only))

    ~H"""
    <section class="ax-card ax-stack-md">
      <div>
        <p class="ax-eyebrow">Summary list</p>
        <h3 class="ax-heading">Subscription facts</h3>
      </div>

      <Detail.summary_list rows={@rows} />
    </section>
    """
  end

  defp rows(:change_actions) do
    [
      %{label: "Status", value: "Active - renewing"},
      action_row("Plan / price", "pro_monthly_2026", "Change", "plan", "swap_plan"),
      action_row("Seats / quantity", "12", "Change", "quantity", "update_quantity"),
      action_row(
        "Renews / ends",
        "Renews Jul 26, 2026",
        "Change",
        "renewal",
        "cancel_at_period_end"
      )
    ]
  end

  defp rows(:view_actions) do
    [
      %{label: "Customer", value: "Acme Research"},
      %{
        label: "Dunning",
        value: "In recovery",
        action_label: "View",
        action_context: "recovery for subscription sub_storybook_phase195",
        action_event: "load_activity",
        action_value: "dunning"
      },
      %{
        label: "Customer account",
        value: "billing@acme.example",
        action_label: "View",
        action_context: "customer for subscription sub_storybook_phase195",
        action_href: "/billing/customers/cus_storybook_phase195"
      }
    ]
  end

  defp rows(:long_labels) do
    [
      %{
        label: "Customer",
        value: "Northeast Regional Platform Operations And Compliance Working Group"
      },
      %{
        label: "Plan / price",
        value: "enterprise_usage_and_seat_blended_price_with_a_very_long_identifier_2026"
      },
      action_row(
        "Renews / ends",
        "Renews Dec 31, 2026 23:59 UTC",
        "Change",
        "renewal",
        "cancel_at_period_end"
      )
    ]
  end

  defp rows(_state) do
    [
      %{label: "Lifecycle state", value: "Active - renewing"},
      %{label: "Customer", value: "Acme Research"},
      %{label: "Current period", value: "Jun 26, 2026 - Jul 26, 2026"},
      %{label: "Amount (MRR)", value: "$420.00"}
    ]
  end

  defp action_row(label, value, action_label, context, action_value) do
    %{
      label: label,
      value: value,
      action_label: action_label,
      action_context: "#{context} for subscription sub_storybook_phase195",
      action_event: "open_action_drawer",
      action_value: action_value
    }
  end
end
