defmodule Accrue.Plug.RequireEntitlementTest do
  @moduledoc """
  Unit coverage for the `Accrue.Plug.RequireEntitlement` controller guard (SC#1):

    * `init/1` validate-and-raise — exactly one of `:feature` / `:plan`, raising
      `ArgumentError` on both / neither / wrong-type (T-124-08: a misconfigured
      plug can never register with ambiguous intent).
    * `call/2` delegate-to-engine — entitled billable passes through unhalted;
      an unentitled / nil billable halts with a content-negotiated opaque 403.
    * deny overrides — `status:` override, per-guard `on_deny: {:redirect, _}`
      override, and config-global `on_deny` / `billable` precedence.
    * opacity (D-10) — the deny body NEVER echoes the gated feature / plan name.

  Mutates `:accrue, :entitlements` (sets the `:plans` catalog + global `billable`
  / `on_deny`), so `async: false` with an `on_exit` restore — mirrors the
  guard + fail-closed property test scaffolding.
  """

  use Accrue.BillingCase, async: false

  import Plug.Test
  import Plug.Conn, only: [put_req_header: 3, get_resp_header: 2]

  alias Accrue.Plug.RequireEntitlement
  alias Accrue.Test.Factory

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  # Two mapped plans (clone of the guard / property test catalog). :enterprise
  # is NOT mapped — the unmapped-billable sentinel for the fail-closed legs.
  @plans [
    p1: [features: [:reports, :export], limits: [seats: 5], price_ids: ["price_p1"]],
    p2: [features: [:export, :api], limits: [api_calls: 100], price_ids: ["price_p2"]]
  ]

  @entitlements [plans: @plans, unmapped_action: :deny]

  setup do
    prev = Application.get_env(:accrue, :entitlements)
    Application.put_env(:accrue, :entitlements, @entitlements)

    on_exit(fn ->
      if prev do
        Application.put_env(:accrue, :entitlements, prev)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    :ok
  end

  defp billable_for(owner_id), do: %TestUser{id: owner_id}

  # An entitled billable: a real customer + active sub on the mapped :p1 plan
  # whose feature set contains :reports.
  defp entitled_billable do
    oid = Ecto.UUID.generate()
    Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})
    billable_for(oid)
  end

  defp put_env(key, value) do
    Application.put_env(:accrue, :entitlements, Keyword.put(@entitlements, key, value))
  end

  # --------------------------------------------------------------------------
  # init/1 validate-and-raise (T-124-08)
  # --------------------------------------------------------------------------
  describe "init/1" do
    test "accepts a single :feature atom and returns opts" do
      assert RequireEntitlement.init(feature: :api_access) == [feature: :api_access]
    end

    test "accepts a single :plan atom and returns opts" do
      assert RequireEntitlement.init(plan: :pro) == [plan: :pro]
    end

    test "accepts a :plan String.t() and returns opts" do
      assert RequireEntitlement.init(plan: "price_pro") == [plan: "price_pro"]
    end

    test "preserves trailing opts (billable / on_deny / status) on the valid leg" do
      fun = fn _ -> nil end
      opts = RequireEntitlement.init(feature: :x, billable: fun, status: 402)
      assert Keyword.fetch!(opts, :feature) == :x
      assert Keyword.fetch!(opts, :status) == 402
      assert is_function(Keyword.fetch!(opts, :billable), 1)
    end

    test "raises ArgumentError when BOTH :feature and :plan are present" do
      assert_raise ArgumentError, ~r/exactly one of/, fn ->
        RequireEntitlement.init(feature: :x, plan: :y)
      end
    end

    test "raises ArgumentError when NEITHER :feature nor :plan is present" do
      assert_raise ArgumentError, ~r/requires/, fn ->
        RequireEntitlement.init([])
      end
    end

    test "raises ArgumentError when :feature is not an atom" do
      assert_raise ArgumentError, ~r/requires/, fn ->
        RequireEntitlement.init(feature: "notatom")
      end
    end

    test "raises ArgumentError when :plan is neither atom nor String" do
      assert_raise ArgumentError, ~r/requires/, fn ->
        RequireEntitlement.init(plan: 42)
      end
    end
  end

  # --------------------------------------------------------------------------
  # call/2 allow / deny delegation
  # --------------------------------------------------------------------------
  describe "call/2 allow" do
    test "an entitled billable passes through unhalted" do
      b = entitled_billable()
      opts = RequireEntitlement.init(feature: :reports, billable: fn _ -> b end)
      conn = RequireEntitlement.call(conn(:get, "/"), opts)

      assert conn.halted == false
      assert is_nil(conn.status)
    end
  end

  describe "call/2 deny" do
    test "an unentitled (nil) billable halts with an opaque JSON 403, halted" do
      opts = RequireEntitlement.init(feature: :reports, billable: fn _ -> nil end)

      conn =
        conn(:get, "/")
        |> put_req_header("accept", "application/json")
        |> RequireEntitlement.call(opts)

      assert conn.status == 403
      assert conn.halted == true
      assert conn.resp_body == ~s({"error":"forbidden"})
      # Opacity (D-10): the gated feature name is NEVER in the wire body.
      refute conn.resp_body =~ "reports"
    end

    test "no JSON accept header yields plain-text Forbidden, halted" do
      opts = RequireEntitlement.init(feature: :reports, billable: fn _ -> nil end)
      conn = RequireEntitlement.call(conn(:get, "/"), opts)

      assert conn.status == 403
      assert conn.halted == true
      assert conn.resp_body == "Forbidden"
      refute conn.resp_body =~ "reports"
    end

    test "a no-data (unmapped) billable also denies, halted" do
      no_data = billable_for(Ecto.UUID.generate())
      opts = RequireEntitlement.init(plan: :p1, billable: fn _ -> no_data end)
      conn = RequireEntitlement.call(conn(:get, "/"), opts)

      assert conn.status == 403
      assert conn.halted == true
      refute conn.resp_body =~ "p1"
    end
  end

  # --------------------------------------------------------------------------
  # deny overrides (Task 2 legs)
  # --------------------------------------------------------------------------
  describe "call/2 deny overrides" do
    test "status: 402 makes the deny status 402" do
      opts = RequireEntitlement.init(feature: :reports, billable: fn _ -> nil end, status: 402)

      conn =
        conn(:get, "/")
        |> put_req_header("accept", "application/json")
        |> RequireEntitlement.call(opts)

      assert conn.status == 402
      assert conn.halted == true
      assert conn.resp_body == ~s({"error":"forbidden"})
    end

    test "per-guard on_deny: {:redirect, path} makes the deny a 302 to that path, halted" do
      opts =
        RequireEntitlement.init(
          feature: :reports,
          billable: fn _ -> nil end,
          on_deny: {:redirect, "/pricing"}
        )

      conn = RequireEntitlement.call(conn(:get, "/"), opts)

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/pricing"]
      assert conn.halted == true
      # Opacity holds on the redirect path too — no feature leak in the body.
      refute conn.resp_body =~ "reports"
    end

    test "config-global on_deny is honored when no per-guard override is given" do
      put_env(:on_deny, {:redirect, "/upgrade"})
      opts = RequireEntitlement.init(feature: :reports, billable: fn _ -> nil end)
      conn = RequireEntitlement.call(conn(:get, "/"), opts)

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/upgrade"]
      assert conn.halted == true
    end

    test "config-global billable is honored when no per-guard billable is given (allow)" do
      good = entitled_billable()
      put_env(:billable, fn _ -> good end)
      opts = RequireEntitlement.init(feature: :reports)
      conn = RequireEntitlement.call(conn(:get, "/"), opts)

      assert conn.halted == false
      assert is_nil(conn.status)
    end
  end
end
