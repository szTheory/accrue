defmodule AccrueAdmin.DevRoutesProdLikeRouter do
  use Phoenix.Router

  import AccrueAdmin.Router

  accrue_admin("/ops", session_keys: [:admin_token], allow_live_reload: false)
end

defmodule AccrueAdmin.DevRoutesTest do
  use AccrueAdmin.LiveCase, async: false

  setup do
    prior = Application.get_env(:accrue, :processor)
    on_exit(fn -> Application.put_env(:accrue, :processor, prior) end)
    :ok
  end

  test "non-prod router exposes all dev routes" do
    paths = AccrueAdmin.TestRouter.__routes__() |> Enum.map(& &1.path)

    assert "/billing/dev/clock" in paths
    assert "/billing/dev/email-preview" in paths
    assert "/billing/dev/webhook-fixtures" in paths
    assert "/billing/dev/components" in paths
    assert "/billing/dev/fake-inspect" in paths
  end

  test "prod-like router omits dev routes at compile time" do
    prod_paths = AccrueAdmin.DevRoutesProdLikeRouter.__routes__() |> Enum.map(& &1.path)

    refute Enum.any?(prod_paths, &String.starts_with?(&1, "/ops/dev/"))
  end

  test "dev pages refuse to render their tooling when the configured processor is not fake", %{
    conn: conn
  } do
    Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/clock")
    assert html =~ "Dev tools require `Accrue.Processor.Fake`"
    refute html =~ "Advance 1 hour"
  end
end
