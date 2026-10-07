defmodule AccruePortal.ContextPostTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.PaymentMethod
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)

    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, previous_auth) end)
    :ok
  end

  test "rendered default and delete forms carry a context pin accepted by their POSTs", %{conn: conn} do
    %{user: user, customer: customer, payment_method: default_method} = dashboard_fixture!()

    other_method =
      payment_method_fixture!(customer, %{
        processor_id: "pm_context_pin_other",
        card_brand: "visa",
        card_last4: "1111",
        card_exp_month: 12,
        card_exp_year: 2031,
        exp_month: 12,
        exp_year: 2031
      })

    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live(conn, "/billing/payment-methods")

    pins = Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)
    assert length(pins) == 2
    [default_pin, delete_pin] = Enum.map(pins, &hd/1)

    default_response =
      post(conn, "/billing/payment-methods/#{other_method.id}/default", %{
        "context_pin" => default_pin
      })

    assert redirected_to(default_response) == "/billing/payment-methods"
    assert TestRepo.get!(Accrue.Billing.Customer, customer.id).default_payment_method_id == other_method.id

    delete_response =
      post(conn, "/billing/payment-methods/#{other_method.id}/delete", %{
        "context_pin" => delete_pin
      })

    assert redirected_to(delete_response) == "/billing/payment-methods"
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, default_method.id)
    assert is_nil(TestRepo.get(PaymentMethod, other_method.id))
  end

  test "missing and forged pins block payment method writes", %{conn: conn} do
    %{user: user, customer: customer, payment_method: payment_method} = dashboard_fixture!()
    conn = sign_in_conn(conn, user)

    response = post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{})
    assert redirected_to(response) == "/billing/blocked"
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, payment_method.id)

    response =
      post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{
        "context_pin" => "forged-pin"
      })

    assert redirected_to(response) == "/billing/blocked"
    assert TestRepo.get(Accrue.Billing.Customer, customer.id)
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, payment_method.id)
  end
end
