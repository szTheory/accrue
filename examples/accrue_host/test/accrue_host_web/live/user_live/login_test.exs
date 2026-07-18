defmodule AccrueHostWeb.UserLive.LoginTest do
  use AccrueHostWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "demo login funnel" do
    test "renders the persona cards and no credential forms", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Choose a demo workspace"
      assert html =~ "Enter workspace"

      for persona <- AccrueHost.DemoBrand.personas() do
        assert html =~ persona.label
        assert html =~ persona.workspace
      end

      # The email/password/magic-link controls and the copy chips are gone.
      refute html =~ "Email me a sign-in link"
      refute html =~ "login_form_password"
      refute html =~ "login_form_magic"
      refute html =~ "Create a workspace account"
      refute html =~ "copy to sign in manually"
    end

    test "each persona card is a real login POST to the session controller", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ ~s(action="/users/log-in")

      for persona <- AccrueHost.DemoBrand.personas() do
        assert html =~ ~s(value="#{persona.email}")
        assert html =~ ~s(value="#{persona.route}")
      end
    end
  end
end
