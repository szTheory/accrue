defmodule AccruePortal.CSPPlugTest do
  use AccruePortal.ConnCase, async: true

  import Plug.Conn

  test "emits the D-22 Braintree allowlist and threads the nonce" do
    conn = Accrue.Portal.CSPPlug.call(build_conn(), [])
    [policy] = Plug.Conn.get_resp_header(conn, "content-security-policy")
    nonce = conn.assigns.accrue_portal_csp_nonce

    assert is_binary(nonce)
    assert byte_size(nonce) > 10

    assert policy =~ "default-src 'self'"
    assert policy =~ "connect-src 'self' https://api.braintreegateway.com"
    assert policy =~ "https://client-analytics.braintreegateway.com"
    assert policy =~ "https://payments.braintree-api.com"
    assert policy =~ "frame-src 'self' https://assets.braintreegateway.com"
    assert policy =~ "script-src 'self' 'nonce-#{nonce}' https://js.braintreegateway.com"
    assert conn.private[:accrue_portal_csp_nonce] == nonce
  end

  test "serves package assets with exact mounted responses" do
    assets = [
      {AccruePortal.Assets.hashed_path(:brand, "/billing"), "text/css; charset=utf-8",
       Application.app_dir(:accrue, "priv/static/brand.css")},
      {AccruePortal.Assets.hashed_path(:css, "/billing"), "text/css; charset=utf-8",
       Application.app_dir(:accrue_portal, "priv/static/accrue_portal.css")},
      {AccruePortal.Assets.hashed_path(:js, "/billing"), "application/javascript; charset=utf-8",
       Application.app_dir(:accrue_portal, "priv/static/accrue_portal.js")},
      {"/billing/assets/phoenix-#{AccruePortal.Assets.phoenix_hash()}",
       "application/javascript; charset=utf-8",
       Application.app_dir(:phoenix, "priv/static/phoenix.min.js")},
      {"/billing/assets/live-view-#{AccruePortal.Assets.live_view_hash()}",
       "application/javascript; charset=utf-8",
       Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.min.js")}
    ]

    for {path, content_type, source} <- assets do
      conn = Plug.Test.conn(:get, path) |> AccruePortal.TestRouter.call([])

      assert conn.status == 200
      assert get_resp_header(conn, "cache-control") == ["public, max-age=31536000, immutable"]
      assert get_resp_header(conn, "content-type") == [content_type]
      assert conn.resp_body == File.read!(source)
    end
  end
end
