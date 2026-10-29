defmodule AccrueAdmin.E2EPlugIsolationTest do
  @moduledoc """
  Phase 254 D-13: a pure-story review lane must be physically unable to reset or
  seed shared mounted fixtures. `AccrueAdmin.E2E.Plug.refuse_in_review_lane/2`
  answers every reset, seed and phase240 mutator route variant with 403 when the
  stored identity lane is `admin-review`, while the `admin-test` lane keeps its
  200 routes and the identity-less legacy port-4017 server stays permissive.

  The route list is read from the plug's own source so a newly added mutator
  route is covered without editing this file.
  """

  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.Customer
  alias AccrueAdmin.E2E.Plug, as: E2EPlug
  alias AccrueAdmin.TestRepo

  @plug_source Path.expand("../support/e2e_plug.ex", __DIR__)
  @identity_key :phase252_e2e_identity

  setup do
    previous_identity = Application.get_env(:accrue_admin, @identity_key)
    previous_entitlements = Application.get_env(:accrue, :entitlements)

    on_exit(fn ->
      restore_env(:accrue_admin, @identity_key, previous_identity)
      restore_env(:accrue, :entitlements, previous_entitlements)
    end)

    :ok
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)

  defp put_lane(lane) do
    Application.put_env(:accrue_admin, @identity_key, %{
      nonce: "phase254-isolation-nonce",
      database: "accrue_admin_test1234567890",
      role: "postgres",
      address: "127.0.0.1",
      port: 4_999,
      partition: "1234567890",
      lane: lane,
      pid: 1,
      ready: true
    })
  end

  defp post_route(path) do
    Plug.Test.conn(:post, path)
    |> E2EPlug.call([])
  end

  # Every `post "<path>"` declared in the plug, in both the forwarded (/reset)
  # and the direct (/__e2e__/reset) spelling, deduplicated and sorted.
  defp declared_post_paths do
    Regex.scan(~r/^\s*post "([^"]+)"/m, File.read!(@plug_source))
    |> Enum.map(fn [_, path] -> path end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # The forwarded spelling a Phoenix `forward "/__e2e__"` hands the plug is the
  # path with the prefix removed; both spellings must be refused.
  defp route_variants(paths) do
    paths
    |> Enum.flat_map(fn path ->
      stripped = String.replace_prefix(path, "/__e2e__", "")
      [stripped, "/__e2e__" <> stripped]
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp customer_count, do: TestRepo.aggregate(Customer, :count, :id)

  defp insert_marker! do
    {:ok, customer} =
      %Customer{}
      |> Ecto.Changeset.change(%{
        owner_type: "phase254-isolation",
        owner_id: "marker_#{System.unique_integer([:positive])}",
        processor: "stripe",
        processor_id: "cus_phase254_marker_#{System.unique_integer([:positive])}",
        name: "Phase 254 isolation marker",
        metadata: %{"phase254" => "marker"}
      })
      |> TestRepo.insert()

    customer
  end

  describe "route enumeration (positive control)" do
    test "the route list read from the plug source is non-empty and includes known mutators" do
      declared = declared_post_paths()

      for known <- [
            "/reset",
            "/__e2e__/reset",
            "/seed/edge-states",
            "/__e2e__/seed/edge-states",
            "/seed/phase241-review-matrix",
            "/phase240/hold-subscription-cancel",
            "/phase240/release-action"
          ] do
        assert known in declared, "expected #{known} in the plug's declared POST routes"
      end

      assert length(declared) >= 20
      assert length(route_variants(declared)) >= length(declared)
    end
  end

  describe "admin-review lane" do
    test "every reset, seed and phase240 mutator route variant answers 403 and leaves data unchanged" do
      marker = insert_marker!()
      before_count = customer_count()
      before_row = TestRepo.get!(Customer, marker.id)

      put_lane("admin-review")

      variants = route_variants(declared_post_paths())
      assert variants != []

      for path <- variants do
        conn = post_route(path)

        assert conn.status == 403,
               "expected 403 from POST #{path} in the admin-review lane, got #{conn.status}"

        assert conn.resp_body =~ "admin-review",
               "the refusal body for POST #{path} must name the lane"
      end

      assert customer_count() == before_count
      assert TestRepo.get!(Customer, marker.id) == before_row
    end

    test "read-only routes are not refused" do
      put_lane("admin-review")

      conn = Plug.Test.conn(:get, "/counts") |> E2EPlug.call([])
      assert conn.status == 200

      conn = Plug.Test.conn(:get, "/phase240/action-status?token=nope") |> E2EPlug.call([])
      assert conn.status == 404
    end
  end

  describe "admin-test lane (positive control)" do
    test "POST /__e2e__/reset still returns 200" do
      put_lane("admin-test")

      conn = post_route("/__e2e__/reset")
      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"ok" => true}
    end

    test "POST /__e2e__/seed/edge-states still returns 200" do
      put_lane("admin-test")

      conn = post_route("/__e2e__/seed/edge-states")
      assert conn.status == 200
    end
  end

  describe "identity-less legacy server (D-14 control)" do
    test "POST /__e2e__/seed/edge-states returns 200 with no identity configured" do
      Application.delete_env(:accrue_admin, @identity_key)

      conn = post_route("/__e2e__/seed/edge-states")
      assert conn.status == 200
    end
  end
end
