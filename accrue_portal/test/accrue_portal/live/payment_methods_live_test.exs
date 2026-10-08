defmodule AccruePortal.PaymentMethodsLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.Customer
  alias AccruePortal.Copy
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    previous_reader = Application.get_env(:accrue_portal, :payment_method_reader)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)

      if previous_reader do
        Application.put_env(:accrue_portal, :payment_method_reader, previous_reader)
      else
        Application.delete_env(:accrue_portal, :payment_method_reader)
      end
    end)

    :ok
  end

  test "Fake and Stripe declare their implemented payment-method operations" do
    for processor <- [Accrue.Processor.Fake, Accrue.Processor.Stripe] do
      capabilities = processor.capabilities()

      assert capabilities.payment_method.create
      assert capabilities.payment_method.list
      assert capabilities.payment_method.update
      assert capabilities.payment_method.delete
      assert capabilities.payment_method.set_default
    end
  end

  test "payment methods page renders only the current customer's cards and actions", %{conn: conn} do
    %{
      user: user,
      customer: customer,
      payment_method: payment_method,
      foreign_payment_method: foreign_payment_method
    } = dashboard_fixture!()

    another_payment_method =
      payment_method_fixture!(customer, %{
        processor_id: "pm_payment_methods_second",
        card_brand: "mastercard",
        card_last4: "5555",
        card_exp_month: 11,
        card_exp_year: 2031,
        exp_month: 11,
        exp_year: 2031
      })

    TestRepo.update!(
      Customer.changeset(customer, %{default_payment_method_id: payment_method.id})
    )

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/payment-methods")

    assert html =~ payment_method.card_last4
    assert html =~ another_payment_method.card_last4
    refute html =~ foreign_payment_method.card_last4
    assert html =~ "Billing for"
    assert html =~ "/billing/payment-methods/new"
    assert html =~ "/billing/payment-methods/#{another_payment_method.id}/delete"
    refute html =~ "/billing/payment-methods/#{payment_method.id}/delete"
    assert html =~ "data-confirm=\""
    assert html =~ another_payment_method.card_last4
    assert html =~ "Future payments that need this saved card may require another card."
    assert html =~ "Set another card as default before removing this one."
    refute html =~ "/billing/payment-methods/#{foreign_payment_method.id}/delete"
    assert html =~ ~s(aria-label="Breadcrumb")
    assert html =~ "Account"
  end

  test "failed payment method reads render unavailable instead of an empty list", %{conn: conn} do
    %{user: user} = dashboard_fixture!()
    conn = sign_in_conn(conn, user)

    Application.put_env(:accrue_portal, :payment_method_reader, fn _customer ->
      {:error, :offline}
    end)

    assert {:ok, _view, html} = live(conn, "/billing/payment-methods")

    assert html =~ "Payment methods are temporarily unavailable. Try again in a moment."
    refute html =~ Copy.payment_methods_empty_title()
  end

  test "successful empty card reads show the empty state", %{conn: conn} do
    %{user: user} = subscription_bundle_fixture!()
    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/payment-methods")

    assert html =~ Copy.payment_methods_empty_title()
    assert html =~ "Add a card to subscribe to plans or update an existing subscription"
  end

  test "add card is hidden when the selected processor differs from the configured provider", %{
    conn: conn
  } do
    %{user: user, customer: customer, payment_method: payment_method} = dashboard_fixture!()

    TestRepo.update!(Customer.changeset(customer, %{processor: "stripe"}))
    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/payment-methods")

    assert html =~ Copy.payment_methods_unsupported_title()
    assert html =~ "Saved payment method management isn"
    assert html =~ "available for this billing provider."
    refute html =~ ~s(href="/billing/payment-methods/new?)

    [_, encoded_pin] = Regex.run(~r{href="/billing\?context_pin=([^"]+)"}, html)
    pin = URI.decode_www_form(encoded_pin)
    detach_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    response =
      post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{
        "context_pin" => pin
      })

    assert redirected_to(response) == "/billing/blocked"
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == detach_calls_before

    assert %Accrue.Billing.PaymentMethod{} =
             TestRepo.get(Accrue.Billing.PaymentMethod, payment_method.id)

  end
end
