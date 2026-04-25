defmodule Accrue.Events.Upcasters.V1ToV2 do
  @moduledoc """
  Example upcaster from `schema_version: 1` to `schema_version: 2`.

  Real upcasters implement actual field migrations — renames,
  defaults, denormalization. This module ships an identity transform
  with a `_schema_version` stamp so the registry can be exercised in
  tests without forcing an arbitrary payload-shape change in any
  production event type.
  """

  @behaviour Accrue.Events.Upcaster

  @impl Accrue.Events.Upcaster
  def upcast(payload) when is_map(payload) do
    {:ok, Map.put(payload, "_schema_version", 2)}
  end
end
