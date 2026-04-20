defmodule AccrueAdmin.ChargesLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Charge, Customer, Refund, Subscription}
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

    customer = insert_customer(%{name: "Charge Customer", email: "charge-list@example.com"})
    subscription = insert_subscription(customer)

    charge =
      insert_charge(customer, subscription, %{
        processor_id: "ch_open",
        status: "succeeded",
        amount_cents: 5_000,
        stripe_fee_amount_minor: 125,
        fees_settled_at: DateTime.utc_now()
      })

    insert_refund(charge, %{
      stripe_id: "re_existing",
      amount_minor: 2_500,
      currency: "usd",
      status: :succeeded
    })

    {:ok, charge: charge}
  end

  test "filters charge rows and renders fee summaries", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/charges?fees_settled=true")

    assert html =~ "Payment and refund review"
    assert html =~ "Succeeded"
    assert html =~ "/billing/charges/"
    assert html =~ "ax-chip ax-label"
    refute html =~ "ax-text-12"
  end

  test "renders Copy-backed empty index when search excludes all charges", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/charges?q=___accrue_empty_fixture___")

    assert html =~ Copy.charges_index_empty_title()
    assert html =~ Copy.charges_index_empty_copy()
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Subscription{}
    |> Subscription.changeset(defaults)
    |> TestRepo.insert!()
  end

  defp insert_charge(customer, subscription, attrs) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      processor: "stripe",
      currency: "usd",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Charge{}
    |> Charge.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_refund(charge, attrs) do
    defaults = %{
      charge_id: charge.id,
      amount_minor: 1_000,
      currency: "usd",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Refund{}
    |> Refund.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end
end
