defmodule Accrue.Entitlements.Source.Outcome do
  @moduledoc "A bounded, host-facing result for one source/capability pair."

  @enforce_keys [:source, :capability, :state, :guidance]
  defstruct [:source, :capability, :state, :guidance]

  @type t :: %__MODULE__{
          source: Accrue.Entitlements.Source.source(),
          capability: Accrue.Entitlements.Source.capability(),
          state: Accrue.Entitlements.Source.state(),
          guidance: %{
            required(:key) => atom(),
            required(:text) => String.t(),
            required(:action_label) => String.t(),
            optional(:url) => String.t()
          }
        }
end

defmodule Accrue.Entitlements.Source.CapabilityError do
  @moduledoc "Typed, bounded error for unavailable source capabilities or bad registry input."

  @enforce_keys [:source, :capability, :code, :next_action]
  defstruct [:source, :capability, :code, :next_action]

  @type t :: %__MODULE__{
          source: atom() | nil,
          capability: atom() | nil,
          code: atom(),
          next_action: atom()
        }
end
