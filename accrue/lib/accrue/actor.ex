defmodule Accrue.Actor do
  @moduledoc """
  Process-dictionary-backed actor context for the Events ledger (D-15).

  Callers upstream of `Accrue.Events.record/1` set the current actor via
  `put_current/1` or scope a block with `with_actor/2`. `Events.record/1`
  reads `current/0` and stamps each event with the actor metadata.

  The actor type is a fixed enum: `:user | :system | :webhook | :oban | :admin`.
  Unknown atoms raise `ArgumentError` at put time so typos fail loud.

  `Accrue.Plug.PutActor` (Phase 2) and the Oban worker middleware wire this
  automatically; library callers can also manage it themselves with
  `with_actor/2`.
  """

  @actor_types [:user, :system, :webhook, :oban, :admin]

  @type actor_type :: :user | :system | :webhook | :oban | :admin
  @type t :: %{type: actor_type(), id: String.t() | nil}

  @doc """
  Stores an actor in the process dictionary. Raises `ArgumentError` on
  unknown actor type.
  """
  @spec put_current(t() | nil) :: :ok
  def put_current(nil) do
    Process.delete(__MODULE__)
    :ok
  end

  def put_current(%{type: type} = actor) when type in @actor_types do
    Process.put(__MODULE__, actor)
    :ok
  end

  def put_current(%{type: type}) do
    raise ArgumentError,
          "invalid actor type #{inspect(type)}; expected one of #{inspect(@actor_types)}"
  end

  def put_current(other) do
    raise ArgumentError,
          "Accrue.Actor.put_current/1 expects a map with :type; got #{inspect(other)}"
  end

  @doc """
  Reads the current actor from the process dictionary. Returns `nil` when
  unset.
  """
  @spec current() :: t() | nil
  def current, do: Process.get(__MODULE__)

  @doc """
  Runs `fun` with `actor` as the current actor, restoring the prior
  value (or clearing it) in an `after` block.
  """
  @spec with_actor(t(), (-> any())) :: any()
  def with_actor(actor, fun) when is_function(fun, 0) do
    prior = current()
    put_current(actor)

    try do
      fun.()
    after
      put_current(prior)
    end
  end

  # ---------------------------------------------------------------------------
  # Operation ID (D2-12 — idempotency seed for outbound Stripe calls)
  # ---------------------------------------------------------------------------

  @doc """
  Returns the current operation ID from the process dictionary, or `nil`
  if unset. Used by `Accrue.Processor.Stripe` as the seed for
  deterministic idempotency keys (D2-12).
  """
  @spec current_operation_id() :: String.t() | nil
  def current_operation_id do
    Process.get(:accrue_operation_id)
  end

  @doc """
  Stores an operation ID in the process dictionary. Oban middleware and
  webhook plug set this automatically so downstream processor calls
  produce deterministic idempotency keys.
  """
  @spec put_operation_id(String.t() | nil) :: :ok
  def put_operation_id(nil) do
    Process.delete(:accrue_operation_id)
    :ok
  end

  def put_operation_id(id) when is_binary(id) do
    Process.put(:accrue_operation_id, id)
    :ok
  end

  @doc """
  Raising variant of `current_operation_id/0`.

  Behaviour depends on `:idempotency_mode` (D3-63):

    * `:strict` — raises `Accrue.ConfigError` with a message pointing at
      `Accrue.Plug.PutOperationId` or the `:operation_id` call option.
    * Any other value (default `:warn`) — generates a random UUID via
      `Ecto.UUID.generate/0`, logs a `Logger.warning/1`, and returns it.
      The generated value is NOT written back to the process dict so
      the warning fires on every call until the caller wires a real ID.
  """
  @spec current_operation_id!() :: String.t()
  def current_operation_id! do
    case Process.get(:accrue_operation_id) do
      nil ->
        case Accrue.Config.get!(:idempotency_mode) do
          :strict ->
            raise Accrue.ConfigError,
              key: :idempotency_mode,
              message:
                "no operation_id in process dict; wire Accrue.Plug.PutOperationId or pass opts[:operation_id]"

          _ ->
            id = Ecto.UUID.generate()
            require Logger

            Logger.warning(
              "accrue: no operation_id — generated random #{id}; " <>
                "wire Accrue.Plug.PutOperationId for deterministic idempotency keys"
            )

            id
        end

      id ->
        id
    end
  end

  @doc """
  Returns the fixed actor-type enum. Useful for downstream validation.
  """
  @spec types() :: [actor_type()]
  def types, do: @actor_types
end
