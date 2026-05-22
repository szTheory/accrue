defmodule Accrue.Property.EntitlementsFailClosedPropertyTest do
  @moduledoc """
  The load-bearing fail-closed property test for the public entitlement gate
  API (D-10), exercised through the top-level `Accrue.*` delegates (Plan 04).

  Two invariants, plus a multi-active-plan affirmative leg:

    * **never-true-on-garbage** — for ALL garbage/edge inputs (nil, arbitrary
      non-billable terms, a billable with no customer, a billable with a
      customer but no active sub, an active sub on an unmapped price_id, and a
      raising-resolver stub), every gate function fails closed:
      `Accrue.entitled?/2 == false`, `Accrue.entitlement_quantity/2 == 0`,
      `Accrue.features_for/1 == []`, `Accrue.has_active_plan?/2 == false`.
    * **true-iff-affirmative-match** — for a billable with an active
      subscription on a mapped plan whose feature set is `F`,
      `Accrue.entitled?(billable, feat) == MapSet.member?(F, feat)` for `feat`
      drawn from `F ∪ {unmapped_sentinel}`. An affirmative resolved match is
      the SOLE path to `true`.
    * **multi-active-plan (load-bearing, T-123-12b)** — ONE billable holding
      TWO active subscriptions on TWO different mapped plans answers `true`
      via the public delegate for BOTH plans (atom + price_id forms), proving
      `has_active_plan?/2` tests the resolved `active_plans` SET — not a single
      representative plan (no fail-closed-but-wrong false negative).

  Mutates the `:entitlements` app env (the raising-resolver leg swaps the
  resolver), so `async: false` with an `on_exit` restore — unlike the
  pure-math `connect` property test which is `async: true`.
  """

  use Accrue.BillingCase, async: false
  use ExUnitProperties

  alias Accrue.Test.Factory

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  # Raising resolver stub for the fail-closed-on-exception leg (D-08):
  # resolve/2 raises, and the context's try/rescue/catch must collapse every
  # public fn to its fail-closed value.
  defmodule RaisingResolver do
    @behaviour Accrue.Entitlements.Resolver
    @impl true
    def resolve(_billable, _opts), do: raise("boom")
  end

  # Two mapped plans with overlapping + distinct features and a seat cap on
  # :p1. :enterprise is intentionally NOT mapped (the unmapped-plan sentinel).
  @plans [
    p1: [features: [:reports, :export], limits: [seats: 5], price_ids: ["price_p1"]],
    p2: [features: [:export, :api], limits: [api_calls: 100], price_ids: ["price_p2"]]
  ]

  @entitlements [plans: @plans, unmapped_action: :deny]

  # Feature set F of plan :p1 (the affirmative-match plan) plus an unmapped
  # sentinel feature that must never resolve true.
  @p1_features MapSet.new([:reports, :export])
  @feature_candidates [:reports, :export, :unmapped_sentinel]

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

  # Garbage / arbitrary non-billable terms generator (RESEARCH L484-489):
  # nil + arbitrary terms + integers + strings + atoms — none of these is a
  # billable with an active mapped subscription, so every gate must fail closed.
  defp garbage_gen do
    StreamData.one_of([
      StreamData.constant(nil),
      StreamData.term(),
      StreamData.integer(),
      StreamData.string(:ascii),
      StreamData.atom(:alphanumeric)
    ])
  end

  # Asserts all four PUBLIC gate functions are fail-closed for `input`.
  defp assert_fail_closed(input) do
    assert Accrue.entitled?(input, :any_feature) == false
    assert Accrue.entitlement_quantity(input, :any_quota) == 0
    assert Accrue.features_for(input) == []
    assert Accrue.has_active_plan?(input, :any_plan) == false
  end

  # --------------------------------------------------------------------------
  # never-true-on-garbage (the load-bearing fail-closed invariant)
  # --------------------------------------------------------------------------
  describe "never-true-on-garbage (property)" do
    property "all garbage / non-billable inputs fail closed across the 4 public delegates" do
      check all(input <- garbage_gen(), max_runs: 200) do
        assert_fail_closed(input)
      end
    end
  end

  describe "never-true-on-garbage (explicit edge fixtures)" do
    test "billable with no customer row fails closed" do
      assert_fail_closed(billable_for(Ecto.UUID.generate()))
    end

    test "billable with a customer but only a canceled subscription fails closed" do
      oid = Ecto.UUID.generate()
      Factory.canceled_subscription(%{owner_id: oid, price_id: "price_p1"})

      assert_fail_closed(billable_for(oid))
    end

    test "billable with an active sub on an UNMAPPED price_id fails closed" do
      oid = Ecto.UUID.generate()
      Factory.active_subscription(%{owner_id: oid, price_id: "price_unknown"})

      assert_fail_closed(billable_for(oid))
    end

    test "raising resolver collapses every public fn to fail-closed (D-08)" do
      Application.put_env(
        :accrue,
        :entitlements,
        Keyword.put(@entitlements, :resolver, RaisingResolver)
      )

      # Even with a real billable + active sub, a raising resolver must NEVER
      # leak a paid feature for free.
      oid = Ecto.UUID.generate()
      Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      assert_fail_closed(billable_for(oid))
      # And a no-data billable too.
      assert_fail_closed(billable_for(Ecto.UUID.generate()))
    end
  end

  # --------------------------------------------------------------------------
  # true-iff-affirmative-match (an affirmative resolved match is the SOLE true)
  # --------------------------------------------------------------------------
  describe "true-iff-affirmative-match (property)" do
    property "entitled?(billable, feat) == MapSet.member?(F, feat) for feat in F + sentinel" do
      oid = Ecto.UUID.generate()
      Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})
      b = billable_for(oid)

      check all(feat <- StreamData.member_of(@feature_candidates), max_runs: 100) do
        assert Accrue.entitled?(b, feat) == MapSet.member?(@p1_features, feat)
      end
    end
  end

  # --------------------------------------------------------------------------
  # multi-active-plan affirmative leg (T-123-12b — the load-bearing proof that
  # has_active_plan?/2 tests the active_plans SET, not a single representative)
  # --------------------------------------------------------------------------
  describe "multi-active-plan affirmative leg" do
    test "has_active_plan? is true for BOTH plans (atom + price_id) on one billable" do
      oid = Ecto.UUID.generate()

      # ONE customer + first active sub on :p1 ("price_p1").
      result = Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      # SECOND active sub on :p2 ("price_p2") on the SAME customer — NOT a
      # second factory call (that would mint a fresh owner_id => a distinct
      # customer, and forcing :owner_id would hit the owner unique index).
      {:ok, _} = Accrue.Billing.subscribe(result.customer, "price_p2")

      b = billable_for(oid)

      # Both plans, both atom and price_id forms, are true via the delegate.
      assert Accrue.has_active_plan?(b, :p1)
      assert Accrue.has_active_plan?(b, :p2)
      assert Accrue.has_active_plan?(b, "price_p1")
      assert Accrue.has_active_plan?(b, "price_p2")

      # An unmapped plan is false (fail-closed, not a false positive).
      refute Accrue.has_active_plan?(b, :enterprise)

      # features_for/1 is the sorted union of :p1 and :p2 features.
      assert Accrue.features_for(b) == [:api, :export, :reports]
    end
  end
end
