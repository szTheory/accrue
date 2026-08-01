defmodule Accrue.Entitlements.Source do
  @moduledoc """
  Closed, inspection-only entitlement-source contract.

  This boundary describes which rail owns an entitlement operation. It never
  delegates to `Accrue.Processor` and it does not perform billing mutations.
  """

  alias Accrue.Entitlements.Source.Outcome

  @capabilities [:observation, :control, :restore, :reconciliation, :management, :offline]
  @states [
    :supported,
    :externally_managed,
    :host_owned,
    :deferred,
    :unavailable,
    :feasibility_blocked
  ]

  @type capability ::
          :observation | :control | :restore | :reconciliation | :management | :offline
  @type state ::
          :supported
          | :externally_managed
          | :host_owned
          | :deferred
          | :unavailable
          | :feasibility_blocked
  @type source :: :stripe | :apple | :host_fake

  @callback outcome(capability()) :: {:ok, Outcome.t()} | {:error, Exception.t()}

  @spec capabilities() :: [capability()]
  def capabilities, do: @capabilities

  @spec states() :: [state()]
  def states, do: @states
end
