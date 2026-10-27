defmodule AccrueAdmin.Storybook.Groups.SubscriptionsCollection do
  @moduledoc """
  The production subscription collection with a connected DataTable LiveComponent.

  The collection query is a deterministic development adapter over validated Cadence
  subscription facts. The routed billing page continues to use the scoped Repo query.
  """

  use PhoenixStorybook.Story, :live_component

  alias AccrueAdmin.Storybook.SubscriptionCollection
  alias PhoenixStorybook.Stories.{Attr, Variation}

  def component, do: SubscriptionCollection

  def attributes do
    [
      %Attr{
        id: :scenario,
        type: :atom,
        default: :launch,
        values: [:launch, :growing_team],
        doc: "Validated source facts for the collection preview."
      }
    ]
  end

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :one_row,
        description: "One launch-derived subscription row in the production collection.",
        attributes: %{scenario: :launch},
        note:
          "Connected PhoenixStorybook 1.2 LiveComponent; production collection renderer; validated Cadence launch facts; presentation-only proof."
      }
    ]
  end
end
