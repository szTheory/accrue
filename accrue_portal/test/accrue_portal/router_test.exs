defmodule AccruePortal.RouterTest do
  use AccruePortal.ConnCase, async: true

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
    assert "/billing/invoices" in paths
    assert "/billing/checkout/:token" in paths

    live_routes =
      Enum.filter(routes, fn route ->
        match?({Phoenix.LiveView.Plug, :call}, route.plug)
      end)

    live_sessions =
      live_routes
      |> Enum.map(& &1.private[:phoenix_live_view])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    assert length(live_sessions) == 1
  end

  test "session callback only forwards explicit host session keys" do
    conn =
      build_conn()
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
    assert session["accrue_portal"]["theme"] == "system"
  end

  test "prod-like compilation keeps the portal shell mounted" do
    prod_paths = Enum.map(ProdLikeRouter.__routes__(), & &1.path)

    assert "/ops" in prod_paths
    assert "/ops/subscriptions" in prod_paths
  end
end
