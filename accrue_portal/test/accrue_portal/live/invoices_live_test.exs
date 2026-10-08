defmodule AccruePortal.InvoicesLiveTest do
  use AccruePortal.ConnCase, async: false

  import AccruePortal.Fixtures

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    previous_invoice_reader = Application.get_env(:accrue_portal, :invoice_reader)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)
    Application.delete_env(:accrue_portal, :invoice_reader)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)

      if is_nil(previous_invoice_reader) do
        Application.delete_env(:accrue_portal, :invoice_reader)
      else
        Application.put_env(:accrue_portal, :invoice_reader, previous_invoice_reader)
      end
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

    assert html =~ customer.email
    assert html =~ current_invoice.number
    assert html =~ current_invoice.hosted_url
    assert html =~ "Showing up to 20 recent invoices."
    refute html =~ foreign_invoice.number
    refute html =~ foreign_invoice.hosted_url
  end

  test "successful empty invoice reads show the approved empty state without retention promises",
       %{
         conn: conn
       } do
    %{user: user} = subscription_bundle_fixture!()
    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/invoices")

    assert html =~ "No invoices yet"
    assert html =~ "When your first invoice is issued, it will appear here."
    assert html =~ "Check back after an invoice is issued."
    refute html =~ "7 years"
  end

  test "failed invoice reads are announced as unavailable instead of appearing empty", %{
    conn: conn
  } do
    %{user: user} = subscription_bundle_fixture!()

    Application.put_env(:accrue_portal, :invoice_reader, fn _customer ->
      {:error, :database_unavailable}
    end)

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/invoices")

    assert html =~ "role=\"alert\""
    assert html =~ "Invoices are temporarily unavailable. Try again in a moment."
    assert html =~ "Try again"
    refute html =~ "No invoices yet"
  end

  test "invoices without a hosted URL do not render an open action", %{conn: conn} do
    %{user: user, customer: customer, subscription: subscription} = subscription_bundle_fixture!()
    invoice = invoice_fixture!(customer, subscription, %{number: "INV-WITHOUT-HOSTED-URL"})

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/invoices")

    assert html =~ invoice.number
    refute html =~ "Open invoice"
  end
end
