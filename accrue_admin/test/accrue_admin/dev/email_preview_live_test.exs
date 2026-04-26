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

  test "every fixture in Fixtures.all/0 selects and renders its declared subject and preview",
       %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, initial_html} = live(conn, "/billing/dev/email-preview")

    fixtures = Accrue.Emails.Fixtures.all()

    humanize = fn key ->
      key |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
    end

    for key <- Map.keys(fixtures) do
      label = humanize.(key)
      assert initial_html =~ label, "fixture #{key} missing from dropdown options"
    end

    for {key, fixture} <- fixtures do
      html =
        view
        |> element("form")
        |> render_change(%{"fixture" => Atom.to_string(key)})

      assert html =~ fixture.subject,
             "preview for #{key} did not surface its declared subject"

      assert html =~ fixture.preview,
             "preview for #{key} did not surface its preview text"
    end
  end
end
