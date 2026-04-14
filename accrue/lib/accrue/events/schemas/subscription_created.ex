defmodule Accrue.Events.Schemas.SubscriptionCreated do
  @moduledoc "Payload schema for `:\"subscription.created\"` events (D3-66)."
  @behaviour Accrue.Events.Upcaster

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          stripe_id: String.t() | nil,
          customer_id: String.t() | nil,
          price_id: String.t() | nil,
          quantity: integer() | nil,
          trial_end: DateTime.t() | nil,
          source: atom()
        }
  defstruct [:stripe_id, :customer_id, :price_id, :quantity, :trial_end, source: :api]

  @doc "Schema version; bumped when the payload shape changes."
  @spec schema_version() :: pos_integer()
  def schema_version, do: 1

  @impl Accrue.Events.Upcaster
  def upcast(payload), do: {:ok, payload}
end
