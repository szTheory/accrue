defmodule AccrueHost.Auth do
  @behaviour Accrue.Auth

  import Plug.Conn, only: [get_session: 2, halt: 1]
  import Phoenix.Controller, only: [redirect: 2]

  alias AccrueHost.Accounts
  alias AccrueHost.Accounts.User

  @impl Accrue.Auth
  def current_user(%Plug.Conn{} = conn) do
    conn
    |> get_session(:user_token)
    |> lookup_user()
  end

  def current_user(%{"user_token" => token}), do: lookup_user(token)
  def current_user(%{user_token: token}), do: lookup_user(token)
  def current_user(_), do: nil

  @impl Accrue.Auth
  def require_admin_plug do
    fn conn, _opts ->
      if admin?(current_user(conn)) do
        conn
      else
        conn
        |> redirect(to: "/")
        |> halt()
      end
    end
  end

  @impl Accrue.Auth
  def user_schema, do: User

  @impl Accrue.Auth
  def log_audit(_user, _event), do: :ok

  @impl Accrue.Auth
  def actor_id(%User{id: id}) when is_binary(id), do: id
  def actor_id(user) when is_map(user), do: user[:id] || user["id"]
  def actor_id(_user), do: nil

  def admin?(%User{billing_admin: billing_admin}), do: billing_admin
  def admin?(user) when is_map(user), do: user[:billing_admin] || user["billing_admin"] || false
  def admin?(_user), do: false

  defp lookup_user(token) when is_binary(token) do
    case Accounts.get_user_by_session_token(token) do
      {user, _token_inserted_at} -> user
      _ -> nil
    end
  end

  defp lookup_user(_token), do: nil
end
