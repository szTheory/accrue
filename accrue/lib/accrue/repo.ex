defmodule Accrue.Repo do
  @moduledoc """
  Thin facade over the host-configured `Ecto.Repo`.

  Accrue does not ship a Repo of its own (D-10 — the host application
  owns the Repo lifecycle). Every Accrue context module that needs to
  talk to Postgres routes through this facade, which resolves the real
  Repo via `Application.get_env(:accrue, :repo)` at **call time**.

  Runtime resolution (not compile-time) is deliberate: tests inject
  `Accrue.TestRepo` through `config/test.exs`, and host apps inject
  their own Repo through `config :accrue, :repo, MyApp.Repo` without
  ever recompiling Accrue.

  This module intentionally only re-exports the Repo callbacks Accrue
  itself uses. If you need a lower-level Repo operation, call the host
  Repo directly.
  """

  @doc """
  Delegates to `c:Ecto.Repo.transact/2`. Accepts either a zero-arity
  function (preferred) or a one-arity function that receives the Repo
  module.
  """
  @spec transact((-> any()) | (module() -> any()), keyword()) ::
          {:ok, any()} | {:error, any()}
  def transact(fun, opts \\ []) when is_function(fun), do: repo().transact(fun, opts)

  @doc """
  Delegates to `c:Ecto.Repo.insert/2`. Pass-through.
  """
  @spec insert(Ecto.Changeset.t() | struct(), keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def insert(changeset_or_struct, opts \\ []),
    do: repo().insert(changeset_or_struct, opts)

  @doc """
  Delegates to `c:Ecto.Repo.all/2`. Pass-through.
  """
  @spec all(Ecto.Queryable.t(), keyword()) :: [any()]
  def all(queryable, opts \\ []), do: repo().all(queryable, opts)

  @doc """
  Delegates to `c:Ecto.Repo.one/2`. Pass-through.
  """
  @spec one(Ecto.Queryable.t(), keyword()) :: any() | nil
  def one(queryable, opts \\ []), do: repo().one(queryable, opts)

  @doc """
  Delegates to `c:Ecto.Repo.update/2` with Postgrex SQLSTATE `45A01`
  translation. Attempts to update an `Accrue.Events.Event` will raise
  `Accrue.EventLedgerImmutableError` rather than the raw `Postgrex.Error`.

  Used only by tests and Plan 06 boot-check paths; normal Accrue code
  MUST NOT call `update` on an `Event` — the trigger will reject it.
  """
  @spec update(Ecto.Changeset.t(), keyword()) ::
          {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def update(changeset, opts \\ []) do
    repo().update(changeset, opts)
  rescue
    err in Postgrex.Error ->
      case err do
        %Postgrex.Error{postgres: %{pg_code: "45A01"} = pg} ->
          reraise Accrue.EventLedgerImmutableError,
                  [message: pg[:message], operation: :update, pg_code: "45A01"],
                  __STACKTRACE__

        %Postgrex.Error{postgres: %{code: :accrue_event_immutable} = pg} ->
          reraise Accrue.EventLedgerImmutableError,
                  [message: pg[:message], operation: :update, pg_code: "45A01"],
                  __STACKTRACE__

        _ ->
          reraise err, __STACKTRACE__
      end
  end

  @doc """
  Delegates to `c:Ecto.Repo.transaction/2`. Accepts an `Ecto.Multi` or
  a function. Used by `Accrue.Billing` for multi-step atomic writes.
  """
  @spec transaction(Ecto.Multi.t() | (-> any()), keyword()) ::
          {:ok, any()} | {:error, any()}
  def transaction(multi_or_fun, opts \\ []),
    do: repo().transaction(multi_or_fun, opts)

  @doc """
  Returns the configured host Repo module. Raises `Accrue.ConfigError`
  when `:repo` is not configured (prevents runtime `UndefinedFunctionError`
  with confusing stacktraces).
  """
  @spec repo() :: module()
  def repo do
    case Application.get_env(:accrue, :repo) do
      nil ->
        raise Accrue.ConfigError,
          key: :repo,
          message:
            "config :accrue, :repo, MyApp.Repo is required — Accrue does not ship a Repo (D-10)"

      mod when is_atom(mod) ->
        mod
    end
  end
end
