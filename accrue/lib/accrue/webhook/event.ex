defmodule Accrue.Webhook.Event do
  @moduledoc """
  Lean event struct passed to webhook handlers (D2-29).

  Deliberately does NOT include the raw Stripe object -- handlers
  call `Accrue.Processor.retrieve_*(event.object_id)` for canonical state.
  This forces WH-10 compliance (re-fetch current state) by shape.

  The `type` field is kept as a `String.t()` in the struct. Conversion
  to atom for pattern-matching dispatch happens at the handler call site
  in Plan 04, using `String.to_existing_atom/1` with a bounded allow-list.
  """

  defstruct [:type, :object_id, :livemode, :created_at, :processor_event_id, :processor]

  @type t :: %__MODULE__{
          type: String.t(),
          object_id: String.t() | nil,
          livemode: boolean(),
          created_at: DateTime.t() | nil,
          processor_event_id: String.t(),
          processor: atom()
        }

  @doc """
  Projects a `%LatticeStripe.Event{}` struct into an `%Accrue.Webhook.Event{}`.

  Extracts the object ID from `data["object"]["id"]` (string keys, as
  returned by `LatticeStripe.Event.from_map/1`).
  """
  @spec from_stripe(LatticeStripe.Event.t(), atom()) :: t()
  def from_stripe(%LatticeStripe.Event{} = stripe_event, processor) do
    object_id =
      case stripe_event.data do
        %{"object" => %{"id" => id}} -> id
        _ -> nil
      end

    created_at =
      case stripe_event.created do
        ts when is_integer(ts) -> DateTime.from_unix!(ts)
        _ -> nil
      end

    %__MODULE__{
      type: stripe_event.type,
      object_id: object_id,
      livemode: stripe_event.livemode,
      created_at: created_at,
      processor_event_id: stripe_event.id,
      processor: processor
    }
  end
end
