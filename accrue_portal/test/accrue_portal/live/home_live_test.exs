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
      subscription: subscription,
      foreign_subscription: foreign_subscription
    } = dashboard_fixture!()

    conn = sign_in_conn(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing")

    assert html =~ subscription.processor_id
    refute html =~ foreign_subscription.processor_id
    assert Regex.scan(~r/<p class="portal-metric">1<\/p>/, html) |> length() == 3
  end
end
