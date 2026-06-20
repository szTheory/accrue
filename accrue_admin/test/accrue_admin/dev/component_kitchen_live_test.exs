defmodule AccrueAdmin.ComponentKitchenLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders the shared component kitchen and floating toolbar", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    assert html =~ "Primitive and form components"
    assert html =~ "Primary action"
    assert html =~ "Secondary action"
    assert html =~ "Dev tools"
    assert html =~ "/billing/dev/fake-inspect"
    assert html =~ "Command palette motion specimen"
    assert html =~ "ax-command-palette"
  end
end
