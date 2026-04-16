defmodule AccrueAdmin.RouterTest do
  use AccrueAdmin.ConnCase, async: true

  defmodule ProdLikeRouter do
    use Phoenix.Router

    import AccrueAdmin.Router

    accrue_admin("/ops", session_keys: [:admin_token], allow_live_reload: false)
  end

  test "mount macro emits isolated asset routes and live session routes" do
    paths =
      AccrueAdmin.TestRouter.__routes__()
      |> Enum.map(& &1.path)

    assert "/billing/assets/css-#{AccrueAdmin.Assets.css_hash()}" in paths
    assert "/billing/assets/js-#{AccrueAdmin.Assets.js_hash()}" in paths
    assert "/billing/assets/brand-#{AccrueAdmin.Assets.brand_hash()}" in paths
    assert "/billing" in paths
    assert "/billing/dev/clock" in paths
    assert "/billing/dev/email-preview" in paths
    assert "/billing/dev/webhook-fixtures" in paths
    assert "/billing/dev/components" in paths
    assert "/billing/dev/fake-inspect" in paths
  end

  test "session callback only forwards explicit host session keys" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "admin_token" => "token-123",
        "ignored" => "secret"
      })

    session =
      conn
      |> AccrueAdmin.CSPPlug.call([])
      |> AccrueAdmin.BrandPlug.call([])
      |> AccrueAdmin.Router.__session__([:admin_token], "/billing")

    assert session["admin_token"] == "token-123"
    refute Map.has_key?(session, "ignored")

    assert session["accrue_admin"]["brand_css_path"] ==
             AccrueAdmin.Assets.hashed_path(:brand, "/billing")

    assert session["accrue_admin"]["assets_css_path"] ==
             AccrueAdmin.Assets.hashed_path(:css, "/billing")

    assert session["accrue_admin"]["assets_js_path"] ==
             AccrueAdmin.Assets.hashed_path(:js, "/billing")

    assert session["accrue_admin"]["mount_path"] == "/billing"
    assert session["accrue_admin"]["theme"] == "system"
  end

  test "prod-like compilation omits dev routes" do
    prod_paths = Enum.map(ProdLikeRouter.__routes__(), & &1.path)
    refute "/ops/dev/clock" in prod_paths
    assert "/ops" in prod_paths
  end

  test "mounted asset routes resolve without host static configuration" do
    conn =
      :get
      |> build_conn("/billing/assets/css-#{AccrueAdmin.Assets.css_hash()}")
      |> Plug.Test.init_test_session(%{})
      |> AccrueAdmin.TestRouter.call([])

    assert conn.status == 200
  end
end
