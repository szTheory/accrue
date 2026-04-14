defmodule Accrue.Events.Schemas.SubscriptionPlanSwapped do
  @moduledoc "Payload schema for `:\"subscription.plan_swapped\"` events (D3-66)."
  @behaviour Accrue.Events.Upcaster

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          stripe_id: String.t() | nil,
          old_price_id: String.t() | nil,
          new_price_id: String.t() | nil,
          proration: atom() | String.t() | nil,
          source: atom()
        }
  defstruct [:stripe_id, :old_price_id, :new_price_id, :proration, source: :api]

  @spec schema_version() :: pos_integer()
  def schema_version, do: 1

  @impl Accrue.Events.Upcaster
  def upcast(payload), do: {:ok, payload}
end
