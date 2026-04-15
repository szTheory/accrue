defmodule AccrueAdmin.EmailPreviewLiveTest do
  use AccrueAdmin.LiveCase, async: false

  test "renders fixture-backed preview data and switches fixtures", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/dev/email-preview")

    assert html =~ "Preview deterministic Accrue email assigns"
    assert html =~ "Receipt"
    assert html =~ "Thanks for your payment"

    html =
      view
      |> element("form")
      |> render_change(%{"fixture" => "payment_failed"})

    assert html =~ "Payment failed"
    assert html =~ "Action required"
  end
end
