defmodule AccrueAdmin.Storybook.Components.SubscriptionDetail do
  @moduledoc """
  Subscription summary, facts, and eligible actions rendered by the production owner.

  Every variation is a static render of deterministic scenario facts. It does not
  establish mounted authorization, provider completion, persistence, or action success.
  """

  use PhoenixStorybook.Story, :component

  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.SubscriptionScenarios
  alias PhoenixStorybook.Stories.Variation

  def function, do: &__MODULE__.subscription_detail_story/1

  def variations do
    [
      variation(:active, :active, "Active Cadence subscription"),
      variation(
        :scheduled_cancellation,
        :scheduled_cancellation,
        "Scheduled cancellation with a supported resume action"
      ),
      variation(
        :incomplete_evidence,
        :incomplete_evidence,
        "Active subscription with incomplete billing projections"
      ),
      variation(:populated, :populated, "Populated compatibility ID"),
      variation(:braintree_pruned, :braintree_pruned, "Braintree action-pruned compatibility ID"),
      variation(:dunning_active, :dunning_active, "Dunning-active compatibility ID")
    ]
  end

  def subscription_detail_story(assigns) do
    assigns
    |> Map.drop([:__changed__, :id])
    |> SubscriptionScenarios.assigns!()
    |> then(&SubscriptionLive.subscription_area/1)
  end

  defp variation(id, scenario, description) do
    attributes = SubscriptionScenarios.attributes(scenario)

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
