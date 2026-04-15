defmodule Accrue.Auth.Mock do
  @moduledoc """
  Process-local `Accrue.Auth` adapter for host test suites.

  This module is intentionally not wired as a default adapter. Host tests
  may configure it explicitly when they need a named, async-safe auth seam.
  """

  @behaviour Accrue.Auth

  @user_key {__MODULE__, :current_user}

  @doc "Stores the mock current user in the calling process."
  @spec put_current_user(Accrue.Auth.user()) :: :ok
  def put_current_user(user) do
    ensure_test_env!()
    Process.put(@user_key, user)
    :ok
  end

  @doc "Clears the mock current user from the calling process."
  @spec clear_current_user() :: :ok
  def clear_current_user do
    Process.delete(@user_key)
    :ok
  end

  @impl Accrue.Auth
  def current_user(conn) do
    ensure_test_env!()

    case Process.get(@user_key, :missing) do
      :missing -> conn_user(conn)
      user -> user
    end
  end

  @impl Accrue.Auth
  def require_admin_plug do
    fn conn, _opts ->
      ensure_test_env!()

      if Accrue.Auth.admin?(current_user(conn)) do
        conn
      else
        raise Accrue.ConfigError,
          key: :auth_adapter,
          message: "Accrue.Auth.Mock rejected non-admin test user."
      end
    end
  end

  @impl Accrue.Auth
  def user_schema do
    ensure_test_env!()
    nil
  end

  @impl Accrue.Auth
  def log_audit(user, event) do
    ensure_test_env!()
    send(self(), {:accrue_auth_audit, user, event})
    :ok
  end

  @impl Accrue.Auth
  def actor_id(user) do
    ensure_test_env!()

    case read_key(user, :id, "id") do
      nil -> nil
      id -> to_string(id)
    end
  end

  @impl Accrue.Auth
  def step_up_challenge(user, action) do
    ensure_test_env!()
    %{kind: :mock, action: action, user_id: actor_id(user)}
  end

  @impl Accrue.Auth
  def verify_step_up(_user, _params, _action) do
    ensure_test_env!()
    :ok
  end

  defp conn_user(%Plug.Conn{assigns: assigns}), do: Map.get(assigns, :current_user)
  defp conn_user(%{assigns: assigns}) when is_map(assigns), do: Map.get(assigns, :current_user)

  defp conn_user(conn) when is_map(conn),
    do: Map.get(conn, :current_user) || Map.get(conn, "current_user")

  defp conn_user(_conn), do: nil

  defp read_key(map, atom_key, string_key) when is_map(map) do
    Map.get(map, atom_key) || Map.get(map, string_key)
  end

  defp read_key(_value, _atom_key, _string_key), do: nil

  defp ensure_test_env! do
    if Application.get_env(:accrue, :env, Mix.env()) == :prod do
      raise Accrue.ConfigError,
        key: :auth_adapter,
        message: "Accrue.Auth.Mock is test-only; configure a real :auth_adapter for production."
    end

    :ok
  end
end
