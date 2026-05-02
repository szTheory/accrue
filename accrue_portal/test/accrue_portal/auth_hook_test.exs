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

  setup do
    BraintreeMox.stub_client_token("client-token")
    :ok
  end

  test "ensure_customer resolves current_user and current_customer", %{conn: conn} do
    user = %TestUser{id: Ecto.UUID.generate()}
    conn = sign_in_customer(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing")
    assert html =~ "Subscriptions"

    assert {:ok, %Customer{} = customer} = Billing.customer(user)
    assert customer.owner_type == "TestUser"
  end

  test "ensure_customer_no_create reuses the existing customer row" do
    user = %TestUser{id: Ecto.UUID.generate()}
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
