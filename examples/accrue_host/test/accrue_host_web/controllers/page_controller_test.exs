defmodule AccrueHostWeb.PageControllerTest do
  use AccrueHostWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "Local billing demo command center"
    assert html =~ "/admin/customers"
    assert html =~ "/admin/analytics/recovery"
    assert html =~ "/app/billing"
    assert html =~ "/billing/payment-methods"
    assert html =~ "/dev/mailbox"
    assert html =~ "Anonymous users and non-admin customer accounts"
    assert html =~ "Seeded credentials are shown on this page in local dev"
  end
end
