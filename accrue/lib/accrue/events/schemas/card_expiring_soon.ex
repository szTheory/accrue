defmodule Accrue.Events.Schemas.CardExpiringSoon do
  @moduledoc "Payload schema for `:\"card.expiring_soon\"` events (D3-66)."
  @behaviour Accrue.Events.Upcaster

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          payment_method_id: String.t() | nil,
          threshold: integer() | nil,
          days_until_expiry: integer() | nil,
          is_default_pm: boolean() | nil,
          source: atom()
        }
  defstruct [:payment_method_id, :threshold, :days_until_expiry, :is_default_pm, source: :api]

  @spec schema_version() :: pos_integer()
  def schema_version, do: 1

  @impl Accrue.Events.Upcaster
  def upcast(payload), do: {:ok, payload}
end
