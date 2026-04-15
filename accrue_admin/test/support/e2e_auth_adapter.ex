defmodule AccrueAdmin.E2E.AuthAdapter do
  @moduledoc false

  @behaviour Accrue.Auth

  @impl Accrue.Auth
  def current_user(%{"admin_token" => "admin"}), do: %{id: "e2e_admin", role: :admin}
  def current_user(_session), do: nil

  @impl Accrue.Auth
  def require_admin_plug, do: fn conn, _opts -> conn end

  @impl Accrue.Auth
  def user_schema, do: nil

  @impl Accrue.Auth
  def log_audit(_user, _event), do: :ok

  @impl Accrue.Auth
  def actor_id(user), do: user[:id]

  @impl Accrue.Auth
  def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify operator action"}

  @impl Accrue.Auth
  def verify_step_up(_user, %{"code" => "123456"}, _action), do: :ok
  def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
end
