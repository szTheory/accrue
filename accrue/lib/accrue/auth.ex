defmodule Accrue.Auth do
  @moduledoc """
  Behaviour + facade for host-app auth integration (AUTH-01, AUTH-02).

  Accrue does NOT own authentication. The host application (using Sigra,
  `phx.gen.auth`, Ueberauth, or any custom solution) implements this
  behaviour and wires it via `config :accrue, :auth_adapter, MyApp.Auth`.
  `Accrue.Admin` (Phase 7) and any callers that need `current_user` reach
  through this facade.

  ## Default adapter (`Accrue.Auth.Default`)

  Phase 1 ships a dev-permissive default (`Accrue.Auth.Default`) that
  returns a stubbed `%{id: "dev"}` in `:dev` / `:test` and **refuses to
  boot** in `:prod` (D-40). Plan 06 will call
  `Accrue.Auth.Default.boot_check!/0` from `Accrue.Application.start/2`
  so production deploys can never run with no auth in place.

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
  """

  @type conn :: Plug.Conn.t() | map()
  @type user :: map() | struct()

  @callback current_user(conn()) :: user() | nil
  @callback require_admin_plug() :: (conn(), keyword() -> conn())
  @callback user_schema() :: module() | nil
  @callback log_audit(user(), map()) :: :ok
  @callback actor_id(user()) :: String.t() | nil

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

  @doc false
  def impl, do: Application.get_env(:accrue, :auth_adapter, Accrue.Auth.Default)
end
