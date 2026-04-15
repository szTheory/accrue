defmodule Accrue.Storage.Null do
  @moduledoc """
  No-op `Accrue.Storage` adapter — the v1.0 default (D6-04).

  - `put/3` echoes the key back untouched; no filesystem or network I/O.
  - `get/1` returns `{:error, :not_configured}`.
  - `delete/1` returns `{:error, :not_configured}`.

  Hosts enable real storage by swapping `:storage_adapter` to a custom
  module implementing `Accrue.Storage`. `Accrue.Storage.Filesystem`
  lands in v1.1.
  """

  @behaviour Accrue.Storage

  @impl true
  def put(key, _binary, _meta) when is_binary(key), do: {:ok, key}

  @impl true
  def get(key) when is_binary(key), do: {:error, :not_configured}

  @impl true
  def delete(key) when is_binary(key), do: {:error, :not_configured}
end
