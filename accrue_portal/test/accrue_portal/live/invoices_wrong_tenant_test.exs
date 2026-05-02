defmodule AccruePortal.InvoicesWrongTenantTest do
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

  test "signed-in customers cannot see foreign invoices on invoice history pages", %{conn: conn} do
    %{
      user: user,
      invoice: invoice,
      foreign_invoice: foreign_invoice
    } = dashboard_fixture!()

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/invoices")

    assert html =~ invoice.number
    refute html =~ foreign_invoice.number
    refute html =~ foreign_invoice.processor_id
  end
end
