defmodule AccrueAdmin.CustomersLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, PaymentMethod}
  alias Accrue.Test.Factory
  alias AccrueAdmin.TestRepo

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

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

    %{customer: customer} =
      Factory.customer(%{owner_type: "Team", owner_id: "team_001", email: "captain@example.com"})

    %{customer: other_customer} =
      Factory.customer(%{owner_type: "User", owner_id: "user_002", email: "other@example.com"})

    payment_method =
      TestRepo.insert!(
        PaymentMethod.changeset(%PaymentMethod{}, %{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "pm_team_default",
          type: "card",
          card_brand: "visa",
          card_last4: "4242",
          exp_month: 12,
          exp_year: 2030
        })
      )

    customer
    |> Customer.changeset(%{
      default_payment_method_id: payment_method.id,
      name: "Captain Customer"
    })
    |> TestRepo.update!()

    other_customer
    |> Customer.changeset(%{name: "Other Customer"})
    |> TestRepo.update!()

    :ok
  end

  test "filters customer rows through the shared query layer", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(
               conn,
               "/billing/customers?q=Captain&owner_type=Team&has_default_payment_method=true"
             )

    assert html =~ "Searchable customer projections"
    assert html =~ "Captain Customer"
    assert html =~ "On file"
    assert html =~ "Billing signals"
    assert html =~ "Off"
    refute html =~ "Other Customer"
    assert html =~ "/billing/customers/"
  end
end
