defmodule Accrue.Events.UpcasterRegistry do
  @moduledoc """
  Chain composition for event schema-version upcasting.

  When `Accrue.Events.state_as_of/3` or `timeline_for/3` reads historical
  rows, each row may have an outdated `schema_version` for its type. This
  registry returns the ordered list of upcaster modules required to
  migrate a payload from the row's recorded version up to the current
  in-app version.

  ## Failure mode

  If the requested target version is unknown for a type, this module
  returns `{:error, {:unknown_schema_version, v}}`. It NEVER silently
  drops the row. The read path surfaces the error to the caller and
  emits `[:accrue, :ops, :events_upcast_failed]` telemetry.

  ## Registration shape

      @chains %{
        "event.type" => %{
          target_version => [Module1, Module2, ...]
        }
      }

  Most types are unregistered and resolve via the identity branch (no
  upcasters). Only when a payload shape changes do we add an entry.
  """

  alias Accrue.Events.Upcasters

  @chains %{
    "subscription.created" => %{
      1 => [],
      2 => [Upcasters.V1ToV2]
    }
  }

  @doc """
  Returns the upcaster module chain to migrate from `from` → `to`.

    * `{:ok, []}` when `from == to` (identity)
    * `{:ok, []}` when the type has no registered chains
    * `{:ok, [mod1, mod2, ...]}` when a chain is registered
    * `{:error, {:unknown_schema_version, v}}` when the target version is
      unknown for a registered type
  """
  @spec chain(String.t(), pos_integer(), pos_integer()) ::
          {:ok, [module()]} | {:error, {:unknown_schema_version, pos_integer()}}
  def chain(_type, from, to) when from == to, do: {:ok, []}

  def chain(type, _from, to) when is_binary(type) and is_integer(to) do
    case Map.fetch(@chains, type) do
      :error ->
        {:ok, []}

      {:ok, versions} ->
        case Map.fetch(versions, to) do
          {:ok, modules} -> {:ok, modules}
          :error -> {:error, {:unknown_schema_version, to}}
        end
    end
  end
end
