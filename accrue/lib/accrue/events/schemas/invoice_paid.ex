defmodule Accrue.Events.Schemas.InvoicePaid do
  @moduledoc "Payload schema for `:\"invoice.paid\"` events (D3-66)."
  @behaviour Accrue.Events.Upcaster

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          stripe_id: String.t() | nil,
          amount_paid_minor: integer() | nil,
          currency: atom() | String.t() | nil,
          source: atom()
        }
  defstruct [:stripe_id, :amount_paid_minor, :currency, source: :api]

  @spec schema_version() :: pos_integer()
  def schema_version, do: 1

  @impl Accrue.Events.Upcaster
  def upcast(payload), do: {:ok, payload}
end
