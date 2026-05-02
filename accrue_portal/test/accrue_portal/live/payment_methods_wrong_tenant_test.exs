defmodule AccruePortal.PaymentMethodsWrongTenantTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.PaymentMethod
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)
    end)

    :ok
  end

  test "wrong-tenant payment method mutations fail closed with not-found", %{conn: conn} do
    %{
      user: user,
      foreign_payment_method: foreign_payment_method
    } = dashboard_fixture!()

    response =
      conn
      |> sign_in_conn(user)
      |> post("/billing/payment-methods/#{foreign_payment_method.id}/default")

    assert response.status == 404

    response =
      conn
      |> sign_in_conn(user)
      |> post("/billing/payment-methods/#{foreign_payment_method.id}/delete")

    assert response.status == 404

    assert %PaymentMethod{} = TestRepo.get!(PaymentMethod, foreign_payment_method.id)
  end
end
