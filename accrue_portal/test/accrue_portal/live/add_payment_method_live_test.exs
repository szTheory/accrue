defmodule AccruePortal.AddPaymentMethodLiveTest do
  use AccruePortal.ConnCase, async: false

  alias AccruePortal.BraintreeMox
  alias AccruePortal.Copy

  import AccruePortal.Fixtures

  defmodule ErrorClientTokenGenerator do
    def generate(_params), do: {:error, :offline}
  end

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    previous_generator = Application.get_env(:accrue, :braintree_client_token_generator)

    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)
    BraintreeMox.stub_client_token("portal-client-token")

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)

      if previous_generator do
        Application.put_env(:accrue, :braintree_client_token_generator, previous_generator)
      else
        Application.delete_env(:accrue, :braintree_client_token_generator)
      end
    end)

    :ok
  end

  test "add payment method page renders the hosted-fields form for the signed-in customer", %{
    conn: conn
  } do
    %{user: user} = subscription_bundle_fixture!()
    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/payment-methods/new")

    assert html =~ ~s(data-portal-hosted-fields="payment-method")
    assert html =~ ~s(data-client-token="portal-client-token")
    assert html =~ ~s(action="/billing/payment-methods")
    assert html =~ ~s(data-braintree-field="number")
    assert html =~ ~s(data-braintree-field="expirationDate")
    assert html =~ ~s(data-braintree-field="cvv")
  end

  test "add payment method page fails closed when the client token cannot be generated", %{
    conn: conn
  } do
    %{user: user} = subscription_bundle_fixture!()
    conn = sign_in_conn(conn, user)

    Application.put_env(
      :accrue,
      :braintree_client_token_generator,
      ErrorClientTokenGenerator
    )

    assert {:ok, _view, html} = live(conn, "/billing/payment-methods/new")

    assert html =~ Copy.checkout_missing_nonce_error()
    refute html =~ ~s(data-portal-hosted-fields="payment-method")
  end
end
