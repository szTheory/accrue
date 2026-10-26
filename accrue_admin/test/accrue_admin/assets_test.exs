defmodule AccrueAdmin.AssetsTest do
  use AccrueAdmin.ConnCase, async: true

  import Plug.Conn

  test "hashes reflect committed bundle contents" do
    brand = File.read!(Application.app_dir(:accrue, "priv/static/brand.css"))
    css = File.read!(Application.app_dir(:accrue_admin, "priv/static/accrue_admin.css"))
    js = File.read!(Application.app_dir(:accrue_admin, "priv/static/accrue_admin.js"))

    assert AccrueAdmin.Assets.brand_hash() == md5(brand)
    assert AccrueAdmin.Assets.css_hash() == md5(css)
    assert AccrueAdmin.Assets.js_hash() == md5(js)
  end

  test "serves css from the mounted package route" do
    conn =
      :get
      |> build_conn(AccrueAdmin.Assets.hashed_path(:css, "/billing"))
      |> Plug.Test.init_test_session(%{})
      |> AccrueAdmin.TestRouter.call([])

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["public, max-age=31536000, immutable"]
    assert get_resp_header(conn, "content-type") == ["text/css; charset=utf-8"]

    assert conn.resp_body ==
             File.read!(Application.app_dir(:accrue_admin, "priv/static/accrue_admin.css"))
  end

  test "serves js from the mounted package route" do
    conn =
      :get
      |> build_conn(AccrueAdmin.Assets.hashed_path(:js, "/billing"))
      |> Plug.Test.init_test_session(%{})
      |> AccrueAdmin.TestRouter.call([])

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/javascript; charset=utf-8"]

    assert conn.resp_body ==
             File.read!(Application.app_dir(:accrue_admin, "priv/static/accrue_admin.js"))
  end

  test "serves self-hosted fonts from the mounted package routes" do
    for {path, filename} <- [
          {"/billing/assets/geist-sans-vf.woff2", "geist-sans-vf.woff2"},
          {"/billing/assets/geist-mono-vf.woff2", "geist-mono-vf.woff2"}
        ] do
      conn =
        :get
        |> build_conn(path)
        |> Plug.Test.init_test_session(%{})
        |> AccrueAdmin.TestRouter.call([])

      expected = File.read!(Application.app_dir(:accrue_admin, "priv/static/fonts/#{filename}"))

      assert conn.status == 200
      assert get_resp_header(conn, "cache-control") == ["public, max-age=31536000, immutable"]
      assert get_resp_header(conn, "content-type") == ["font/woff2; charset=utf-8"]
      assert conn.resp_body == expected
    end
  end

  defp md5(body) do
    :md5
    |> :crypto.hash(body)
    |> Base.encode16(case: :lower)
  end
end
