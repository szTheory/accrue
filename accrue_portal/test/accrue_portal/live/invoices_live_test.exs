defmodule AccruePortal.InvoicesLiveTest do
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

  test "invoices page renders only the current customer's invoice history", %{conn: conn} do
    %{user: user, customer: customer, subscription: subscription} = subscription_bundle_fixture!()

    current_invoice =
      invoice_fixture!(customer, subscription, %{
        number: "INV-CURRENT-PORTAL",
        hosted_url: "https://billing.example.test/invoices/current"
      })

    %{customer: foreign_customer, subscription: foreign_subscription} =
      subscription_bundle_fixture!()

    foreign_invoice =
      invoice_fixture!(foreign_customer, foreign_subscription, %{
        number: "INV-FOREIGN-PORTAL",
        hosted_url: "https://billing.example.test/invoices/foreign"
      })

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/invoices")

    assert html =~ current_invoice.number
    assert html =~ current_invoice.hosted_url
    refute html =~ foreign_invoice.number
    refute html =~ foreign_invoice.hosted_url
  end
end
