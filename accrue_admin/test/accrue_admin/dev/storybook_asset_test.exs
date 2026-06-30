defmodule AccrueAdmin.Dev.StorybookAssetTest do
  @moduledoc false

  use AccrueAdmin.ConnCase, async: true

  import Plug.Conn

  defmodule ProdLikeRouter do
    use Phoenix.Router

    import AccrueAdmin.Router

    accrue_admin("/ops", session_keys: [:admin_token], allow_live_reload: false)
  end

  test "serves committed storybook css and js bundles from the storybook asset paths" do
    assert_storybook_asset(
      :storybook_css,
      "text/css; charset=utf-8",
      "priv/static/storybook.css"
    )

    assert_storybook_asset(
      :storybook_js,
      "application/javascript; charset=utf-8",
      "priv/static/storybook.js"
    )
  end

  test "storybook asset routes are dev-only and omitted from prod-like routers" do
    dev_paths = AccrueAdmin.TestRouter.__routes__() |> Enum.map(& &1.path)
    prod_paths = ProdLikeRouter.__routes__() |> Enum.map(& &1.path)

    assert AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook") in dev_paths
    assert AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook") in dev_paths

    refute Enum.any?(prod_paths, &String.contains?(&1, "/dev/storybook"))
  end

  test "phoenix_storybook remains scoped to dev and test in the package dependency list" do
    mix_source =
      Path.expand("../../../mix.exs", __DIR__)
      |> File.read!()

    assert mix_source =~ ~s({:phoenix_storybook, "~> 1.2", only: [:dev, :test]})
  end

  test "example host keeps admin dev routes disabled in its package mount" do
    router_source =
      repo_root()
      |> Path.join("examples/accrue_host/lib/accrue_host_web/router.ex")
      |> File.read!()

    assert router_source =~ "allow_live_reload: false"
    refute router_source =~ "live_storybook"
    refute router_source =~ "/dev/storybook"
  end

  defp assert_storybook_asset(kind, expected_content_type, static_path) do
    path = AccrueAdmin.Assets.hashed_path(kind, "/dev/storybook")

    conn =
      :get
      |> build_conn(path)
      |> Plug.Test.init_test_session(%{})
      |> AccrueAdmin.TestRouter.call([])

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["public, max-age=31536000, immutable"]
    assert get_resp_header(conn, "content-type") == [expected_content_type]

    assert conn.resp_body ==
             File.read!(Application.app_dir(:accrue_admin, static_path))
  end

  defp repo_root do
    Path.expand("../../../../", __DIR__)
  end
end
