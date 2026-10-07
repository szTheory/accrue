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

  test "rendered default and delete forms carry a context pin accepted by their POSTs", %{
    conn: conn
  } do
    %{
      user: user,
      customer: customer,
      payment_method: default_method,
      foreign_payment_method: foreign_method
    } = dashboard_fixture!()

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
    assert {:ok, _view, html} = live_payment_methods(conn)

    pins = Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)
    assert length(pins) >= 2
    [pin] = pins |> Enum.map(&hd/1) |> Enum.uniq()

    default_calls_before = Accrue.Processor.Fake.call_count(:set_default_payment_method)

    default_response =
      post(conn, "/billing/payment-methods/#{other_method.id}/default", %{
        "context_pin" => pin
      })

    assert redirected_to(default_response) == "/billing/payment-methods"

    assert Accrue.Processor.Fake.call_count(:set_default_payment_method) ==
             default_calls_before + 1

    assert TestRepo.get!(Accrue.Billing.Customer, customer.id).default_payment_method_id ==
             other_method.id

    detach_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    foreign_response =
      post(conn, "/billing/payment-methods/#{foreign_method.id}/delete", %{"context_pin" => pin})

    assert foreign_response.status == 404
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == detach_calls_before

    delete_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    delete_response =
      post(conn, "/billing/payment-methods/#{default_method.id}/delete", %{
        "context_pin" => pin
      })

    assert redirected_to(delete_response) == "/billing/payment-methods"
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == delete_calls_before + 1
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, default_method.id)
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, other_method.id)
  end

  test "missing and forged pins block payment method writes", %{conn: conn} do
    %{user: user, customer: customer, payment_method: payment_method} = dashboard_fixture!()
    conn = sign_in_conn(conn, user)
    detach_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    response = post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{})
    assert redirected_to(response) == "/billing/blocked"
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, payment_method.id)
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == detach_calls_before

    response =
      post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{
        "context_pin" => "forged-pin"
      })

    assert redirected_to(response) == "/billing/blocked"
    assert TestRepo.get(Accrue.Billing.Customer, customer.id)
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, payment_method.id)
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == detach_calls_before
  end

  defp live_payment_methods(conn) do
    case live(conn, "/billing/payment-methods") do
      {:ok, _view, _html} = success -> success
      {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
    end
  end
end
