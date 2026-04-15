defmodule AccrueAdmin.AuthHookTest do
  use AccrueAdmin.LiveCase, async: false

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(%{"admin_token" => "staff"}), do: %{id: "staff_1", role: :support}
    def current_user(_), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)
    :ok
  end

  test "admin sessions mount the billing page", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing")
    assert html =~ "Local billing projections at a glance"
  end

  test "non-admin sessions are redirected before render", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "staff")

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/billing")
  end
end
