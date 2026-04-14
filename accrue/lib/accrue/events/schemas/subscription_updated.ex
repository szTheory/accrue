defmodule Accrue.Events.Schemas.SubscriptionUpdated do
  @moduledoc "Payload schema for `:\"subscription.updated\"` events (D3-66)."
  @behaviour Accrue.Events.Upcaster

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          stripe_id: String.t() | nil,
          status: atom() | String.t() | nil,
          source: atom()
        }
  defstruct [:stripe_id, :status, source: :api]

  @spec schema_version() :: pos_integer()
  def schema_version, do: 1

  @impl Accrue.Events.Upcaster
  def upcast(payload), do: {:ok, payload}
end
