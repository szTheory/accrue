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
      },
      %Attr{
        id: :collection_state,
        type: :atom,
        default: :one_row,
        values: [
          :new_host_empty,
          :filtered_empty,
          :queue_empty,
          :one_row,
          :multiple_rows,
          :page_boundary,
          :loading,
          :unavailable,
          :partial_cursor_error,
          :incomplete_projection
        ],
        doc: "Production collection states backed by the connected DataTable."
      }
    ]
  end

  def layout, do: :one_column

  # Each state owns a LiveComponent subtree with source-derived DOM IDs.
  # Isolating variations keeps those real IDs unique while preserving the connected preview.
  def container, do: :iframe

  def variations do
    [
      %Variation{
        id: :new_host_empty,
        description: "New-host first-run empty collection.",
        attributes: %{collection_state: :new_host_empty}
      },
      %Variation{
        id: :filtered_empty,
        description: "Filtered collection with no matching source rows.",
        attributes: %{collection_state: :filtered_empty}
      },
      %Variation{
        id: :queue_empty,
        description: "Empty production risk queue with its view-all recovery.",
        attributes: %{collection_state: :queue_empty}
      },
      %Variation{
        id: :one_row,
        description: "One launch-derived subscription row in the production collection.",
        attributes: %{scenario: :launch, collection_state: :one_row},
        note:
          "Connected PhoenixStorybook 1.2 LiveComponent; production collection renderer; validated Cadence launch facts; presentation-only proof."
      },
      %Variation{
        id: :multiple_rows,
        description: "Multiple source-derived subscriptions in production order.",
        attributes: %{collection_state: :multiple_rows}
      },
      %Variation{
        id: :page_boundary,
        description: "A real one-row page with the production cursor continuation.",
        attributes: %{collection_state: :page_boundary}
      },
      %Variation{
        id: :loading,
        description: "The existing settled loading-skeleton fixture.",
        attributes: %{collection_state: :loading}
      },
      %Variation{
        id: :unavailable,
        description: "Initial list read failure with production recovery.",
        attributes: %{collection_state: :unavailable}
      },
      %Variation{
        id: :partial_cursor_error,
        description: "A next-page read failure with retained rows and retry.",
        attributes: %{collection_state: :partial_cursor_error}
      },
      %Variation{
        id: :incomplete_projection,
        description: "A source projection with unavailable amount evidence.",
        attributes: %{collection_state: :incomplete_projection}
      }
    ]
  end
end
