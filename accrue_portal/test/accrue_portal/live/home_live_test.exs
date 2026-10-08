defmodule AccruePortal.HomeLiveTest do
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

  test "home renders only the current customer's dashboard data", %{conn: conn} do
    %{
      user: user,
      customer: customer,
      subscription: subscription,
      foreign_subscription: foreign_subscription
    } = dashboard_fixture!()

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing")

    assert html =~ "Account overview"
    assert html =~ ~s(<span class="portal-billable-name">#{customer.email}</span>)
    assert html =~ subscription.processor_id
    refute html =~ foreign_subscription.processor_id
    assert Regex.scan(~r/<p class="portal-metric">\s*1\s*<\/p>/, html) |> length() == 3
    assert html =~ "Recent invoices (up to 20)"
    assert html =~ "Up to 20 recent invoices are shown."
  end

  test "home presents successful empty collections as zero and keeps the empty state actionable",
       %{
         conn: conn
       } do
    %{user: user} = dashboard_fixture!()
    previous = set_dashboard_readers(fn _ -> [] end, fn _ -> [] end, fn _ -> [] end)
    on_exit(fn -> restore_dashboard_readers(previous) end)

    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live(conn, "/billing")
    assert Regex.scan(~r/<p class="portal-metric">\s*0\s*<\/p>/, html) |> length() == 3
    assert html =~ "You don&#39;t have a subscription yet."
    assert html =~ ~s(href="/billing/subscriptions?context_pin=)
    refute html =~ "Unavailable"
  end

  test "home shows unavailable dashboard reads instead of zero counts", %{conn: conn} do
    %{user: user} = dashboard_fixture!()

    previous =
      set_dashboard_readers(
        fn _ -> {:error, :database_unavailable} end,
        fn _ -> {:error, :processor_unavailable} end,
        fn _ -> {:error, :database_unavailable} end
      )

    on_exit(fn -> restore_dashboard_readers(previous) end)

    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live(conn, "/billing")

    assert Regex.scan(
             ~r/class="portal-metric portal-metric-unavailable" role="status">\s*Unavailable\s*<\/p>/,
             html
           )
           |> length() == 3

    assert html =~ "Subscriptions unavailable"
    assert html =~ "Billing data is unavailable. Try again later."
    refute html =~ ~r/<p class="portal-metric">\s*0\s*<\/p>/
    refute html =~ "You don't have a subscription yet."
  end

  defp set_dashboard_readers(subscription_reader, payment_method_reader, invoice_reader) do
    previous = %{
      subscription: Application.get_env(:accrue_portal, :subscription_reader),
      payment_method: Application.get_env(:accrue_portal, :payment_method_reader),
      invoice: Application.get_env(:accrue_portal, :invoice_reader)
    }

    Application.put_env(:accrue_portal, :subscription_reader, subscription_reader)
    Application.put_env(:accrue_portal, :payment_method_reader, payment_method_reader)
    Application.put_env(:accrue_portal, :invoice_reader, invoice_reader)
    previous
  end

  defp restore_dashboard_readers(previous) do
    restore_reader(:subscription_reader, previous.subscription)
    restore_reader(:payment_method_reader, previous.payment_method)
    restore_reader(:invoice_reader, previous.invoice)
  end

  defp restore_reader(key, nil), do: Application.delete_env(:accrue_portal, key)
  defp restore_reader(key, value), do: Application.put_env(:accrue_portal, key, value)
end
