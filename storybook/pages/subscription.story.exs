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

  def function, do: &__MODULE__.subscription_page_story/1

  def variations do
    [
      variation(:active, "Active subscription with supported actions"),
      variation(:scheduled_cancellation, "Cancellation scheduled for the current period end"),
      variation(:incomplete_evidence, "Active subscription with honest incomplete projections")
    ]
  end

  def subscription_page_story(assigns) do
    assigns
    |> Map.drop([:__changed__, :id])
    |> SubscriptionPageScenarios.assigns!()
    |> then(&SubscriptionLive.subscription_page/1)
  end

  defp variation(scenario, description) do
    attributes = SubscriptionPageScenarios.attributes(scenario)

    %Variation{
      id: scenario,
      description: description,
      attributes: attributes,
      note:
        [:actor, :job, :input_source, :production_renderer, :proof_lane]
        |> Enum.map_join("; ", &Map.fetch!(attributes, &1))
        |> Kernel.<>(".")
    }
  end
end
