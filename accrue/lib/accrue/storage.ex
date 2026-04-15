defmodule Accrue.Storage do
  @moduledoc """
  Behaviour + facade for pluggable PDF / asset storage (D6-04).

  v1.0 ships `Accrue.Storage.Null` only — all three callbacks are
  no-ops: `put/3` echoes the key back, `get/1` and `delete/1` return
  `{:error, :not_configured}`. `Accrue.Storage.Filesystem` is deferred
  to v1.1. Hosts needing S3 (or any other backend) write a custom
  adapter implementing the three callbacks below and set
  `config :accrue, :storage_adapter, MyApp.Storage.S3`.

  ## Telemetry (D6-04)

  `[:accrue, :storage, :put | :get | :delete, :start | :stop | :exception]`
  is emitted via `Accrue.Telemetry.span/3` with metadata
  `%{adapter: module, key: binary, bytes: non_neg_integer}` for `put`
  (bytes omitted on get/delete). Raw binary bodies are NEVER placed in
  metadata — `:bytes` is a scalar `byte_size/1` of the payload only
  (T-06-02-02 mitigation).

  ## Key scheme

  Keys are library-derived binaries (e.g., `"invoices/<id>.pdf"`) —
  never user input in v1.0. The future `Filesystem` adapter (v1.1) MUST
  add a path-normalization guard against traversal (T-06-02-03).
  """

  @type key :: String.t()
  @type meta :: map()

  @callback put(key(), binary(), meta()) :: {:ok, key()} | {:error, term()}
  @callback get(key()) :: {:ok, binary()} | {:error, term()}
  @callback delete(key()) :: :ok | {:error, term()}

  @doc """
  Stores `binary` at `key` via the configured adapter. Returns the
  canonical key on success (may differ from the input for adapters
  that apply transforms; `Null` echoes untouched).
  """
  @spec put(key(), binary(), meta()) :: {:ok, key()} | {:error, term()}
  def put(key, binary, meta \\ %{})
      when is_binary(key) and is_binary(binary) and is_map(meta) do
    adapter = impl()
    metadata = %{adapter: adapter, key: key, bytes: byte_size(binary)}

    Accrue.Telemetry.span([:accrue, :storage, :put], metadata, fn ->
      adapter.put(key, binary, meta)
    end)
  end

  @doc """
  Fetches the binary stored at `key` via the configured adapter.
  `Null` always returns `{:error, :not_configured}`.
  """
  @spec get(key()) :: {:ok, binary()} | {:error, term()}
  def get(key) when is_binary(key) do
    adapter = impl()
    metadata = %{adapter: adapter, key: key}

    Accrue.Telemetry.span([:accrue, :storage, :get], metadata, fn ->
      adapter.get(key)
    end)
  end

  @doc """
  Deletes the binary stored at `key` via the configured adapter.
  `Null` always returns `{:error, :not_configured}`.
  """
  @spec delete(key()) :: :ok | {:error, term()}
  def delete(key) when is_binary(key) do
    adapter = impl()
    metadata = %{adapter: adapter, key: key}

    Accrue.Telemetry.span([:accrue, :storage, :delete], metadata, fn ->
      adapter.delete(key)
    end)
  end

  @doc false
  def impl, do: Application.get_env(:accrue, :storage_adapter, Accrue.Storage.Null)
end
