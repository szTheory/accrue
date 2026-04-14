defmodule Accrue.Events.Upcaster do
  @moduledoc """
  Upcaster behaviour for event `schema_version` evolution (D3-69).

  Phase 3 ships every event at `schema_version: 1` with identity
  upcasters. This module establishes the contract for future breaking
  changes — when a payload shape changes, the new schema module will
  ship with a real `upcast/1` that maps the old payload into the new
  shape so historical rows remain queryable on the read path.

  ## Contract

    * `upcast/1` takes a raw `data` map as stored in the
      `accrue_events.data` jsonb column.
    * Returns `{:ok, upcasted_map}` on success or `{:error, term()}`
      when the payload is malformed beyond recovery.

  ## Why a behaviour, not a protocol

  Events are stored by string type (e.g. `"subscription.created"`) and
  `schema_version` integer — there is no struct in flight when the read
  path needs to upcast, so a protocol wouldn't dispatch. The registry
  lookup in `Accrue.Events.Schemas.for/1` returns the module, and the
  read path calls `mod.upcast(data)` directly.
  """

  @callback upcast(map()) :: {:ok, map()} | {:error, term()}
end
