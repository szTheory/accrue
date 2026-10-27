defmodule AccrueAdmin.Storybook.Pages.Subscription do
  @moduledoc """
  Whole subscription detail page rendered by SubscriptionLive's production component.

  Variations carry deterministic story facts only. They do not establish mounted
  authorization, persistence, action dispatch, or provider completion.
  """

  use PhoenixStorybook.Story, :page

  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.SubscriptionPageScenarios
  alias PhoenixStorybook.Stories.Variation

  @page_states %{
    active: {:active, :canonical},
    scheduled_cancellation: {:scheduled_cancellation, :canonical},
    incomplete_evidence: {:incomplete_evidence, :canonical},
    review_cancel_now: {:active, :review_cancel_now},
    awaiting_step_up: {:active, :awaiting_step_up},
    dispatching: {:active, :dispatching},
    result_confirmed: {:active, :result_confirmed},
    result_pending: {:active, :result_pending},
    result_failed: {:active, :result_failed}
  }

  def doc do
    "Complete subscription detail page rendered through its production LiveView owner."
  end

  # PhoenixStorybook page stories select their supported presentations through
  # navigation tabs. The `variation_id` query parameter is only read for
  # component/live_component stories by PhoenixStorybook 1.2.
  def navigation do
    [
      {:active, "Active"},
      {:scheduled_cancellation, "Scheduled cancellation"},
      {:incomplete_evidence, "Incomplete evidence"},
      {:review_cancel_now, "Cancel review"},
      {:awaiting_step_up, "Step-up review"},
      {:dispatching, "Dispatching"},
      {:result_confirmed, "Confirmed result"},
      {:result_pending, "Pending result"},
      {:result_failed, "Failed result"}
    ]
  end

  def variations do
    [
      variation(:active, :active, :canonical, "Active subscription with supported actions"),
      variation(
        :scheduled_cancellation,
        :scheduled_cancellation,
        :canonical,
        "Cancellation scheduled for the current period end"
      ),
      variation(
        :incomplete_evidence,
        :incomplete_evidence,
        :canonical,
        "Active subscription with honest incomplete projections"
      ),
      variation(
        :review_cancel_now,
        :active,
        :review_cancel_now,
        "Cancel-now review using current production copy and facts"
      ),
      variation(
        :awaiting_step_up,
        :active,
        :awaiting_step_up,
        "Cancel-now review waiting for the production step-up challenge"
      ),
      variation(:dispatching, :active, :dispatching, "Cancel-now confirmation while dispatching"),
      variation(:result_confirmed, :active, :result_confirmed, "Confirmed action result state"),
      variation(:result_pending, :active, :result_pending, "Pending result remains unconfirmed"),
      variation(:result_failed, :active, :result_failed, "Definitive provider rejection result")
    ]
  end

  def render(assigns) do
    page_attributes =
      case Map.get(assigns, :tab) do
        nil when is_map_key(assigns, :scenario) ->
          Map.drop(assigns, [:__changed__, :id])

        nil ->
          SubscriptionPageScenarios.attributes(:active, :canonical)

        tab ->
          {scenario, snapshot} = page_state_for_tab!(tab)
          SubscriptionPageScenarios.attributes(scenario, snapshot)
      end

    html =
      Phoenix.LiveViewTest.__render_component__(
        AccrueAdmin.Endpoint,
        &SubscriptionLive.subscription_page/1,
        SubscriptionPageScenarios.assigns!(page_attributes),
        []
      )

    Phoenix.HTML.raw(html <> ~s(<div id="ax-overlay-root"></div>))
  end

  defp page_state_for_tab!(tab) do
    Enum.find_value(@page_states, fn
      {^tab, state} -> state
      {id, state} -> if to_string(id) == to_string(tab), do: state
    end) || raise ArgumentError, "unsupported subscription page navigation tab: #{inspect(tab)}"
  end

  def function, do: &__MODULE__.render/1

  defp variation(id, scenario, snapshot, description) do
    attributes = SubscriptionPageScenarios.attributes(scenario, snapshot)

    %Variation{
      id: id,
      description: description,
      attributes: attributes,
      note:
        [:actor, :job, :input_source, :production_renderer, :proof_lane]
        |> Enum.map_join("; ", &Map.fetch!(attributes, &1))
        |> Kernel.<>(".")
    }
  end
end
