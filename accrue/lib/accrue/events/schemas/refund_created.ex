defmodule Accrue.Events.Schemas.RefundCreated do
  @moduledoc "Payload schema for `:\"refund.created\"` events (D3-66)."
  @behaviour Accrue.Events.Upcaster

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          stripe_id: String.t() | nil,
          charge_id: String.t() | nil,
          amount_minor: integer() | nil,
          currency: atom() | String.t() | nil,
          reason: atom() | String.t() | nil,
          source: atom()
        }
  defstruct [:stripe_id, :charge_id, :amount_minor, :currency, :reason, source: :api]

  @spec schema_version() :: pos_integer()
  def schema_version, do: 1

  @impl Accrue.Events.Upcaster
  def upcast(payload), do: {:ok, payload}
end
