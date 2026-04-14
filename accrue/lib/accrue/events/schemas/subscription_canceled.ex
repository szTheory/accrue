defmodule Accrue.Events.Schemas.SubscriptionCanceled do
  @moduledoc "Payload schema for `:\"subscription.canceled\"` events (D3-66)."
  @behaviour Accrue.Events.Upcaster

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          stripe_id: String.t() | nil,
          mode: atom() | String.t() | nil,
          invoice_now: boolean() | nil,
          source: atom()
        }
  defstruct [:stripe_id, :mode, :invoice_now, source: :api]

  @spec schema_version() :: pos_integer()
  def schema_version, do: 1

  @impl Accrue.Events.Upcaster
  def upcast(payload), do: {:ok, payload}
end
