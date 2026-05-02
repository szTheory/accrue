defmodule AccruePortal.AuthHookTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias AccruePortal.BraintreeMox

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :binary_id, autogenerate: false}
    schema "portal_test_users" do
    end
  end

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"user_token" => "customer-token"}) do
      %TestUser{id: "00000000-0000-0000-0000-000000000001"}
    end

    def current_user(_), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(%{id: id}), do: id
  end

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    BraintreeMox.stub_client_token("client-token")

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)
    end)

    :ok
  end

  test "ensure_customer resolves current_user and current_customer", %{conn: conn} do
    user = %TestUser{id: "00000000-0000-0000-0000-000000000001"}
    conn = Plug.Test.init_test_session(conn, %{"user_token" => "customer-token"})

    assert {:ok, _view, html} = live(conn, "/billing")
    assert html =~ "Billing portal"

    assert {:ok, %Customer{} = customer} = Billing.customer(user)
    assert customer.owner_type == "TestUser"
  end

  test "ensure_customer_no_create reuses the existing customer row" do
    user = %TestUser{id: "00000000-0000-0000-0000-000000000001"}
    assert {:ok, %Customer{} = customer} = Billing.customer(user)

    session = %{
      "user_token" => "customer-token",
      "accrue_portal" => %{"mount_path" => "/billing"}
    }

    socket = %Phoenix.LiveView.Socket{}

    assert {:cont, mounted} =
             Accrue.Portal.AuthHook.on_mount(
               :ensure_customer_no_create,
               %{},
               session,
               socket
             )

    assert mounted.assigns.current_user == user
    assert mounted.assigns.current_customer.id == customer.id
  end

  test "unauthenticated access redirects before render", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/billing"}}} = live(conn, "/billing")
  end
end
