defmodule AccrueAdmin.CustomersLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, PaymentMethod}
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
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

    # New find-and-open surface: plain heading + description, no projections jargon.
    assert html =~ Copy.customers_index_heading()
    assert html =~ Copy.customers_index_description()
    refute html =~ "Searchable customer projections"

    assert html =~ ~s(<caption)
    assert html =~ Copy.customers_index_table_caption()
    assert html =~ "Captain Customer"

    # Payment-method column relabelled and softened (no raw pm id leaked into the list).
    assert html =~ "Payment method"
    assert html =~ "On file"
    refute html =~ "pm_team_default"

    # Billing-signals column dropped from the list (always-Off, belongs on detail).
    refute html =~ "Billing signals"

    # Owner-types KPI dropped; the two clean KPIs remain.
    refute html =~ "Distinct host billable types"

    # owner_type filter renders from the derived distinct types. With <= 3 seeded
    # owner types it is a segmented toggle (radiogroup), not a free-text input or select.
    assert html =~ ~s(name="owner_type")
    assert html =~ ~s(class="ax-segmented")

    # Copyable ID chip rendered via the registered Clipboard hook.
    assert html =~ "ax-id-badge"
    assert html =~ ~s(phx-hook="Clipboard")

    refute html =~ "Other Customer"
    assert html =~ "/billing/customers/"
  end

  test "renders Copy-backed empty index when search excludes all customers", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers?q=___accrue_empty_fixture___")

    assert html =~ "No customers for this organization yet"
    assert html =~ Copy.customers_index_empty_copy()
  end
end
