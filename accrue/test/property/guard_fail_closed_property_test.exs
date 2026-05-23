defmodule Accrue.Property.GuardFailClosedPropertyTest do
  @moduledoc """
  The cross-surface fail-closed property for the shared
  `Accrue.Entitlements.Guard.check/3` decision engine (SC#4 / Phase 124).

  Where `EntitlementsFailClosedPropertyTest` proves the PUBLIC `Accrue.*`
  delegates fail closed, this test proves the GUARD ENGINE itself — the
  always-compiled seam BOTH enforcement surfaces (`Accrue.Plug.RequireEntitlement`
  and the cond-compiled `Accrue.Live.Entitlements` `on_mount` guard) call —
  denies on every input shape that cannot resolve to an affirmative match,
  identically on the `:plug` and `:live` surfaces.

  Three invariants:

    * **never-allow-on-garbage** — for ALL garbage inputs (nil, arbitrary
      non-billable terms, integers, strings, atoms) carried in as the resolved
      billable via a `billable:` fn, `Guard.check(:plug, conn, …)` and
      `Guard.check(:live, %{assigns: …}, …)` BOTH return `{:deny, _, _}` and
      NEVER `{:allow, _}`.
    * **raising-billable-fn fails closed** — a `billable:` fn that RAISES
      collapses to `nil` (the `resolve_billable/3` `rescue`/`catch → nil`
      idiom) and the Guard denies on BOTH surfaces. A raising resolver must
      never leak a paid feature for free.
    * **allow-iff-affirmative-match** — the SOLE `{:allow, _}` path is a billable
      with an active subscription on a mapped plan whose feature set contains
      the gated feature. The affirmative leg pins `:allow` to a single real path
      so a fail-OPEN regression on any untested input shape is caught.

  Mutates the `:accrue, :entitlements` app env, so `async: false` with an
  `on_exit` restore (clone of the entitlements fail-closed property scaffolding).
  """

  use Accrue.BillingCase, async: false
  use ExUnitProperties

  import Plug.Test

  alias Accrue.Entitlements.Guard
  alias Accrue.Test.Factory

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  # Two mapped plans (clone of the entitlements/guard test catalog). :enterprise
  # is intentionally NOT mapped — the unmapped sentinel. :p1 carries :reports.
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

  # Garbage / arbitrary non-billable terms generator (clone of the entitlements
  # property test): nil + arbitrary terms + integers + strings + atoms — none of
  # these resolves to a billable with an active mapped subscription, so every
  # Guard.check on either surface must deny.
  defp garbage_gen do
    StreamData.one_of([
      StreamData.constant(nil),
      StreamData.term(),
      StreamData.integer(),
      StreamData.string(:ascii),
      StreamData.atom(:alphanumeric)
    ])
  end

  # Drive the GARBAGE `input` through the Guard on BOTH surfaces and assert the
  # decision is `{:deny, _, _}` (never `{:allow, _}`).
  #
  #   * `:plug` container — a `%Plug.Conn{}` carrying `input` as the resolved
  #     billable via a `billable:` fn that returns `input`.
  #   * `:live` container — a bare `%{assigns: %{}}` map (no full socket needed;
  #     the engine reads only `container.assigns`) with the same `billable:` fn.
  defp assert_fail_closed(input) do
    billable_fn = fn _container -> input end

    plug_container = conn(:get, "/")
    live_container = %{assigns: %{}}

    assert match?(
             {:deny, _, _},
             Guard.check(:plug, plug_container, feature: :any, billable: billable_fn)
           )

    refute match?(
             {:allow, _},
             Guard.check(:plug, plug_container, feature: :any, billable: billable_fn)
           )

    assert match?(
             {:deny, _, _},
             Guard.check(:live, live_container, feature: :any, billable: billable_fn)
           )

    refute match?(
             {:allow, _},
             Guard.check(:live, live_container, feature: :any, billable: billable_fn)
           )
  end

  # --------------------------------------------------------------------------
  # never-allow-on-garbage (the load-bearing cross-surface fail-closed property)
  # --------------------------------------------------------------------------
  describe "never-allow-on-garbage (property, both surfaces)" do
    property "all garbage / non-billable inputs DENY through the Guard on :plug and :live" do
      check all(input <- garbage_gen(), max_runs: 200) do
        assert_fail_closed(input)
      end
    end
  end

  # --------------------------------------------------------------------------
  # raising-billable-fn fails closed (the resolve_billable rescue/catch -> nil)
  # --------------------------------------------------------------------------
  describe "raising billable fn fails closed (both surfaces)" do
    test "a raising billable: fn collapses to nil and DENIES on :plug and :live" do
      raising_fn = fn _container -> raise "boom" end

      plug_container = conn(:get, "/")
      live_container = %{assigns: %{}}

      assert match?(
               {:deny, _, _},
               Guard.check(:plug, plug_container, feature: :reports, billable: raising_fn)
             )

      assert match?(
               {:deny, _, _},
               Guard.check(:live, live_container, feature: :reports, billable: raising_fn)
             )
    end

    test "a raising billable: fn DENIES even with a :plan target on both surfaces" do
      raising_fn = fn _container -> raise "boom" end

      assert match?(
               {:deny, _, _},
               Guard.check(:plug, conn(:get, "/"), plan: :p1, billable: raising_fn)
             )

      assert match?(
               {:deny, _, _},
               Guard.check(:live, %{assigns: %{}}, plan: :p1, billable: raising_fn)
             )
    end
  end

  # --------------------------------------------------------------------------
  # no-active-subscription DENIES (a real billable shape with no mapped sub)
  # --------------------------------------------------------------------------
  describe "billable with no active mapped subscription fails closed (both surfaces)" do
    test "a billable with no customer row DENIES on :plug and :live" do
      no_data = billable_for(Ecto.UUID.generate())
      billable_fn = fn _ -> no_data end

      assert match?(
               {:deny, _, _},
               Guard.check(:plug, conn(:get, "/"), feature: :reports, billable: billable_fn)
             )

      assert match?(
               {:deny, _, _},
               Guard.check(:live, %{assigns: %{}}, feature: :reports, billable: billable_fn)
             )
    end

    test "a billable with an active sub on an UNMAPPED price_id DENIES on both surfaces" do
      oid = Ecto.UUID.generate()
      Factory.active_subscription(%{owner_id: oid, price_id: "price_unknown"})
      billable_fn = fn _ -> billable_for(oid) end

      assert match?(
               {:deny, _, _},
               Guard.check(:plug, conn(:get, "/"), feature: :reports, billable: billable_fn)
             )

      assert match?(
               {:deny, _, _},
               Guard.check(:live, %{assigns: %{}}, feature: :reports, billable: billable_fn)
             )
    end
  end

  # --------------------------------------------------------------------------
  # allow-iff-affirmative-match (an affirmative resolved match is the SOLE allow)
  # --------------------------------------------------------------------------
  describe "allow is reachable ONLY via an affirmative resolved match (both surfaces)" do
    test "an active sub on a mapped plan whose features contain the gated feature ALLOWS" do
      oid = Ecto.UUID.generate()
      Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})
      billable_fn = fn _ -> billable_for(oid) end

      # :p1 carries :reports -> allow on both surfaces.
      assert match?(
               {:allow, _},
               Guard.check(:plug, conn(:get, "/"), feature: :reports, billable: billable_fn)
             )

      assert match?(
               {:allow, _},
               Guard.check(:live, %{assigns: %{}}, feature: :reports, billable: billable_fn)
             )

      # The same affirmative billable, plan target -> allow on both surfaces.
      assert match?(
               {:allow, _},
               Guard.check(:plug, conn(:get, "/"), plan: :p1, billable: billable_fn)
             )

      assert match?(
               {:allow, _},
               Guard.check(:live, %{assigns: %{}}, plan: :p1, billable: billable_fn)
             )
    end

    test "the SAME affirmative billable DENIES for a feature OUTSIDE its plan (no over-allow)" do
      oid = Ecto.UUID.generate()
      Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})
      billable_fn = fn _ -> billable_for(oid) end

      # :p1 does NOT carry :api -> deny, proving allow is per-feature, not blanket.
      assert match?(
               {:deny, _, _},
               Guard.check(:plug, conn(:get, "/"), feature: :api, billable: billable_fn)
             )

      assert match?(
               {:deny, _, _},
               Guard.check(:live, %{assigns: %{}}, feature: :api, billable: billable_fn)
             )
    end
  end
end
