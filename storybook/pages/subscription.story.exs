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

  def doc do
    "Complete subscription detail page rendered through its production LiveView owner."
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
    assigns
    |> Map.drop([:__changed__, :id])
    |> SubscriptionPageScenarios.assigns!()
    |> then(&SubscriptionLive.subscription_page/1)
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
