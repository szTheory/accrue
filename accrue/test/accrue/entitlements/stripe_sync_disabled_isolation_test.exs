defmodule Accrue.Entitlements.StripeSyncDisabledIsolationTest do
  @moduledoc """
  Phase 127 (ENT-10) — gate-path isolation (disabled mode).

  Proves the off-by-default isolation invariant (D-04 layer 3): with
  `stripe_native_sync: :disabled` (the default), an `Accrue.entitled?/2`
  call on the always-on gate path issues **zero** SQL queries against the
  `accrue_entitlement_summaries` cache table, and the entitlements surface
  answers **byte-for-byte as after Phase 126** (local mapping canonical, no
  Stripe dependency on the gate path).

  The static-grep companion gate
  `scripts/ci/verify_entitlement_sync_isolation.sh` is the compile-time twin
  of this runtime proof.

  Ecto emits query telemetry under the repo's otp-app-derived prefix; for
  the host-canonical `Accrue.Repo` that is `[:accrue, :repo, :query]`. In
  this test suite the repo is `Accrue.TestRepo`, whose prefix is
  `[:accrue, :test_repo, :query]` — we attach to the real test-suite event
  but assert against the same canonical contract.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Test.Factory

  # Host-canonical Ecto query telemetry event (what `Accrue.Repo` emits).
  @canonical_repo_query_event [:accrue, :repo, :query]
  # The actual event the test-suite repo (Accrue.TestRepo) emits.
  @test_repo_query_event [:accrue, :test_repo, :query]
  @cache_table "accrue_entitlement_summaries"

  @plans [
    pro: [features: [:reports, :export], limits: [seats: 5], price_ids: ["price_pro"]]
  ]
  @entitlements [plans: @plans, unmapped_action: :deny, stripe_native_sync: :disabled]

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

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  test "entitled?/2 issues zero queries against the cache table with sync :disabled" do
    refute Accrue.Config.stripe_native_sync?()

    oid = Ecto.UUID.generate()
    Factory.active_subscription(%{owner_id: oid, price_id: "price_pro"})
    billable = %TestUser{id: oid}

    test_pid = self()
    handler_id = "ent-isolation-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      [@test_repo_query_event, @canonical_repo_query_event],
      fn _event, _meas, meta, _ ->
        sql = Map.get(meta, :query, "")
        if is_binary(sql) and String.contains?(sql, @cache_table) do
          send(test_pid, {:cache_query, sql})
        end
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    # The affirmative gate decision must come from local mapping only.
    assert Accrue.entitled?(billable, :reports)

    refute_received {:cache_query, _},
                    "entitled?/2 must NOT query #{@cache_table} when sync is :disabled"
  end

  test "surface parity: entitled?/features_for match the Phase-126 local-resolution fixture" do
    oid = Ecto.UUID.generate()
    Factory.active_subscription(%{owner_id: oid, price_id: "price_pro"})
    billable = %TestUser{id: oid}

    # The Phase-126 contract: local plan->feature mapping is canonical.
    # With sync :disabled the surface is byte-for-byte that contract.
    assert Accrue.entitled?(billable, :reports)
    assert Accrue.entitled?(billable, :export)
    refute Accrue.entitled?(billable, :not_a_feature)
    assert Accrue.has_active_plan?(billable, :pro)
    assert Accrue.has_active_plan?(billable, "price_pro")
    assert Accrue.features_for(billable) == [:export, :reports]
    # Canonical Phase-126 SSOT: quantities[quota_key] = min(cap, item.quantity)
    # (see local_map.ex merge_plan/5 + local_map_test.exs:73). The factory
    # subscription has the default item quantity 1, so the :seats cap of 5
    # resolves to min(5, 1) == 1 — NOT the bare configured cap.
    assert Accrue.entitlement_quantity(billable, :seats) == 1
  end
end
