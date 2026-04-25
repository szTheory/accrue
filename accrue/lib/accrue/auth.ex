defmodule Accrue.Auth do
  @moduledoc """
  Behaviour + facade for host-app auth integration.

  Accrue does NOT own authentication. The host application (using Sigra,
  `phx.gen.auth`, Ueberauth, or any custom solution) implements this
  behaviour and wires it via `config :accrue, :auth_adapter, MyApp.Auth`.
  `Accrue.Admin` and any callers that need `current_user` reach through
  this facade.

  ## Default adapter (`Accrue.Auth.Default`)

  A dev-permissive default (`Accrue.Auth.Default`) returns a stubbed
  `%{id: "dev"}` in `:dev` / `:test` and **refuses to boot** in `:prod`.
  `Accrue.Auth.Default.boot_check!/0` is called from
  `Accrue.Application.start/2` so production deploys can never run with
  no auth in place.

  ## Contract

  - `current_user/1` — lookup the user from a `%Plug.Conn{}` or any
    arbitrary map. Returns the user struct/map or `nil`.
  - `require_admin_plug/0` — returns a plug function that raises on
    non-admins. Admin UI mounts this at the router level.
  - `user_schema/0` — returns the host's user Ecto schema module (or
    `nil` if not applicable). Used by the admin UI for joins / previews.
  - `log_audit/2` — emit an audit record for a user action. Default is
    a no-op; hosts may persist or forward to a SIEM.
  - `actor_id/1` — extract the canonical actor id string from a user
    struct/map. Used by `Accrue.Events.record/1` when auto-stamping
    actor context.
  - `step_up_challenge/2` — optional destructive-action challenge hook
    for admin step-up flows.
  - `verify_step_up/3` — optional destructive-action verification hook
    paired with `step_up_challenge/2`.
  """

  @type conn :: Plug.Conn.t() | map()
  @type user :: map() | struct()

  @callback current_user(conn()) :: user() | nil
  @callback require_admin_plug() :: (conn(), keyword() -> conn())
  @callback user_schema() :: module() | nil
  @callback log_audit(user(), map()) :: :ok
  @callback actor_id(user()) :: String.t() | nil
  @callback step_up_challenge(user(), map()) :: map()
  @callback verify_step_up(user(), map(), map()) :: :ok | {:error, term()}

  @optional_callbacks step_up_challenge: 2, verify_step_up: 3

  @doc "Delegates to the configured adapter's `current_user/1`."
  @spec current_user(conn()) :: user() | nil
  def current_user(conn), do: impl().current_user(conn)

  @doc "Delegates to the configured adapter's `require_admin_plug/0`."
  @spec require_admin_plug() :: (conn(), keyword() -> conn())
  def require_admin_plug, do: impl().require_admin_plug()

  @doc "Delegates to the configured adapter's `user_schema/0`."
  @spec user_schema() :: module() | nil
  def user_schema, do: impl().user_schema()

  @doc "Delegates to the configured adapter's `log_audit/2`."
  @spec log_audit(user(), map()) :: :ok
  def log_audit(user, event), do: impl().log_audit(user, event)

  @doc "Delegates to the configured adapter's `actor_id/1`."
  @spec actor_id(user()) :: String.t() | nil
  def actor_id(user), do: impl().actor_id(user)

  @doc """
  Returns whether `user` should be treated as an admin.

  Adapters may expose a dedicated `admin?/1` helper; otherwise Accrue
  falls back to conservative host-shape heuristics (`role`, `is_admin`,
  `admin`).
  """
  @spec admin?(user() | nil) :: boolean()
  def admin?(nil), do: false

  def admin?(user) when is_map(user) do
    adapter = impl()

    cond do
      function_exported?(adapter, :admin?, 1) ->
        adapter.admin?(user)

      true ->
        admin_fallback?(user)
    end
  end

  def admin?(_), do: false

  @doc "Delegates to the configured adapter's optional `step_up_challenge/2`."
  @spec step_up_challenge(user(), map()) :: map()
  def step_up_challenge(user, action), do: step_up_adapter().step_up_challenge(user, action)

  @doc "Delegates to the configured adapter's optional `verify_step_up/3`."
  @spec verify_step_up(user(), map(), map()) :: :ok | {:error, term()}
  def verify_step_up(user, params, action),
    do: step_up_adapter().verify_step_up(user, params, action)

  @doc false
  def impl, do: Application.get_env(:accrue, :auth_adapter, Accrue.Auth.Default)

  defp step_up_adapter do
    adapter = impl()

    if function_exported?(adapter, :step_up_challenge, 2) and
         function_exported?(adapter, :verify_step_up, 3) do
      adapter
    else
      Accrue.Auth.Default
    end
  end

  defp admin_fallback?(user) do
    role = Map.get(user, :role) || Map.get(user, "role")
    is_admin = Map.get(user, :is_admin) || Map.get(user, "is_admin")
    admin = Map.get(user, :admin) || Map.get(user, "admin")

    role in [:admin, "admin"] or is_admin in [true, "true"] or admin in [true, "true"]
  end
end
