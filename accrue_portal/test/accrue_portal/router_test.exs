defmodule AccruePortal.RouterTest do
  use ExUnit.Case, async: true

  defmodule ProdLikeRouter do
    use Phoenix.Router

    import Accrue.Portal.Router

    accrue_portal("/ops", session_keys: [:user_token])
  end

  test "mount macro emits asset routes and one live_session sibling shell" do
    routes = AccruePortal.TestRouter.__routes__()
    paths = Enum.map(routes, & &1.path)

    assert "/billing/assets/css-#{AccruePortal.Assets.css_hash()}" in paths
    assert "/billing/assets/js-#{AccruePortal.Assets.js_hash()}" in paths
    assert "/billing/assets/brand-#{AccruePortal.Assets.brand_hash()}" in paths
    assert "/billing" in paths
    assert "/billing/subscriptions" in paths
    assert "/billing/payment-methods" in paths
    assert "/billing/payment-methods/new" in paths
    assert "/billing/invoices" in paths
    assert "/billing/checkout/:token" in paths

    live_routes =
      Enum.filter(routes, fn route ->
        route.plug == Phoenix.LiveView.Plug
      end)

    live_sessions =
      live_routes
      |> Enum.map(& &1.metadata[:phoenix_live_view])
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn {_view, _action, _opts, live_session} -> live_session.name end)
      |> Enum.uniq()

    assert length(live_routes) == 7
    assert length(live_sessions) == 1
  end

  test "session callback only forwards explicit host session keys" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{
        "user_token" => "token-123",
        "ignored" => "secret"
      })

    session =
      conn
      |> Accrue.Portal.CSPPlug.call([])
      |> Accrue.Portal.BrandPlug.call([])
      |> Accrue.Portal.Router.__session__([:user_token], "/billing")

    assert session["user_token"] == "token-123"
    refute Map.has_key?(session, "ignored")
    assert session["accrue_portal"]["mount_path"] == "/billing"
    assert session["accrue_portal"]["login_path"] == "/"
    assert session["accrue_portal"]["theme"] == "system"
    assert session["accrue_portal"]["theme_locked"] == false
  end

  test "locked theme policy forces the mode server-side and marks the session locked" do
    previous = Application.get_env(:accrue, :branding)

    Application.put_env(:accrue, :branding,
      from_email: "billing@example.test",
      support_email: "support@example.test",
      theme: :dark
    )

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:accrue, :branding)
      else
        Application.put_env(:accrue, :branding, previous)
      end
    end)

    session =
      Phoenix.ConnTest.build_conn()
      # A conflicting cookie must be ignored when the policy locks the mode.
      |> Plug.Test.put_req_cookie("accrue_theme", "light")
      |> Plug.Test.init_test_session(%{"user_token" => "token-123"})
      |> Accrue.Portal.CSPPlug.call([])
      |> Accrue.Portal.BrandPlug.call([])
      |> Accrue.Portal.Router.__session__([:user_token], "/billing")

    assert session["accrue_portal"]["theme"] == "dark"
    assert session["accrue_portal"]["theme_locked"] == true
  end

  test "session callback includes configured login path" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{"user_token" => "token-123"})

    session =
      conn
      |> Accrue.Portal.CSPPlug.call([])
      |> Accrue.Portal.BrandPlug.call([])
      |> Accrue.Portal.Router.__session__([:user_token], "/billing", "/users/log-in")

    assert session["accrue_portal"]["login_path"] == "/users/log-in"
  end

  test "prod-like compilation keeps the portal shell mounted" do
    prod_paths = Enum.map(ProdLikeRouter.__routes__(), & &1.path)

    assert "/ops" in prod_paths
    assert "/ops/subscriptions" in prod_paths
  end
end
