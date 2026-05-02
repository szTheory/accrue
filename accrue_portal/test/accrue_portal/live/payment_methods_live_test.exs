defmodule AccruePortal.PaymentMethodsLiveTest do
  use AccruePortal.ConnCase, async: false

  import AccruePortal.Fixtures

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)
    end)

    :ok
  end

  test "payment methods page renders only the current customer's cards and actions", %{conn: conn} do
    %{
      user: user,
      payment_method: payment_method,
      foreign_payment_method: foreign_payment_method
    } = dashboard_fixture!()

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/payment-methods")

    assert html =~ payment_method.card_last4
    refute html =~ foreign_payment_method.card_last4
    assert html =~ "/billing/payment-methods/new"
    assert html =~ "/billing/payment-methods/#{payment_method.id}/delete"
    refute html =~ "/billing/payment-methods/#{foreign_payment_method.id}/delete"
  end
end
