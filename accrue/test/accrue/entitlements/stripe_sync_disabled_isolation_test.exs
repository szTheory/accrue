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

  alias Accrue.Billing.EntitlementSummary
  alias Accrue.Entitlements.Admin
  alias Accrue.Test.Factory
  alias Accrue.TestRepo

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

  test "diagnostic_for_customer/1 reads no historical advisory row while sync is disabled" do
    oid = Ecto.UUID.generate()
    %{customer: customer} = Factory.active_subscription(%{owner_id: oid, price_id: "price_pro"})
    insert_summary!(customer, %{"entitlements" => %{"data" => [%{"lookup_key" => "historical"}]}})

    cache_queries = cache_queries_while(fn -> Admin.diagnostic_for_customer(customer) end)

    assert %{stripe_advisory: %{state: :disabled}} = Admin.diagnostic_for_customer(customer)
    assert cache_queries == []
  end

  test "enabled diagnostic performs one owner-scoped summary lookup" do
    Application.put_env(
      :accrue,
      :entitlements,
      Keyword.put(@entitlements, :stripe_native_sync, :advisory)
    )

    oid = Ecto.UUID.generate()
    %{customer: customer} = Factory.active_subscription(%{owner_id: oid, price_id: "price_pro"})

    assert %{stripe_advisory: %{state: :not_observed}} = Admin.diagnostic_for_customer(customer)

    cache_queries = cache_queries_while(fn -> Admin.diagnostic_for_customer(customer) end)

    assert length(cache_queries) == 1
    assert Enum.all?(cache_queries, &String.contains?(&1, "WHERE (a0.\"customer_id\""))
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

  test "advisory cache rows cannot alter the full local grant surface when sync is enabled" do
    Application.put_env(
      :accrue,
      :entitlements,
      Keyword.put(@entitlements, :stripe_native_sync, :advisory)
    )

    assert Accrue.Config.stripe_native_sync?()

    oid = Ecto.UUID.generate()
    %{customer: customer} = Factory.active_subscription(%{owner_id: oid, price_id: "price_pro"})
    billable = %TestUser{id: oid}

    expected = grant_surface(billable)

    assert expected == %{
             entitled_reports?: true,
             entitled_export?: true,
             entitled_contradictory?: false,
             has_pro_atom?: true,
             has_pro_price?: true,
             has_contradictory_plan?: false,
             features: [:export, :reports],
             seats: 1
           }

    TestRepo.delete_all(EntitlementSummary)
    assert_diagnostic_preserves_surface(customer, billable, expected)
    assert grant_surface(billable) == expected

    insert_summary!(customer, %{
      "entitlements" => %{"data" => []},
      "_accrue" => %{"fixture" => "empty"}
    })

    assert_diagnostic_preserves_surface(customer, billable, expected)
    assert grant_surface(billable) == expected

    TestRepo.delete_all(EntitlementSummary)

    insert_summary!(
      customer,
      %{
        "entitlements" => %{
          "data" => [
            %{
              "id" => "ent_stale",
              "object" => "entitlements.active_entitlement",
              "feature" => "feature_stale_reports",
              "lookup_key" => "not_a_feature",
              "livemode" => false
            }
          ]
        },
        "_accrue" => %{"fixture" => "stale"}
      },
      synced_at: DateTime.add(DateTime.utc_now(), -3600, :second)
    )

    assert_diagnostic_preserves_surface(customer, billable, expected)
    assert grant_surface(billable) == expected

    TestRepo.delete_all(EntitlementSummary)

    insert_summary!(customer, %{
      "entitlements" => %{
        "data" => [
          %{
            "id" => "ent_contradictory",
            "object" => "entitlements.active_entitlement",
            "feature" => "feature_contradictory",
            "lookup_key" => "not_a_feature",
            "livemode" => false
          }
        ]
      },
      "_accrue" => %{"fixture" => "fresh-contradictory"}
    })

    assert_diagnostic_preserves_surface(customer, billable, expected)
    assert grant_surface(billable) == expected
  end

  defp assert_diagnostic_preserves_surface(customer, billable, expected) do
    assert %{local: {:ok, _}, stripe_advisory: _} = Admin.diagnostic_for_customer(customer)
    assert grant_surface(billable) == expected
  end

  defp cache_queries_while(fun) do
    test_pid = self()
    handler_id = "diagnostic-cache-#{System.unique_integer([:positive])}"

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
    _ = fun.()
    drain_cache_queries([])
  end

  defp drain_cache_queries(queries) do
    receive do
      {:cache_query, sql} -> drain_cache_queries([sql | queries])
    after
      0 -> Enum.reverse(queries)
    end
  end

  defp grant_surface(billable) do
    %{
      entitled_reports?: Accrue.entitled?(billable, :reports),
      entitled_export?: Accrue.entitled?(billable, :export),
      entitled_contradictory?: Accrue.entitled?(billable, :not_a_feature),
      has_pro_atom?: Accrue.has_active_plan?(billable, :pro),
      has_pro_price?: Accrue.has_active_plan?(billable, "price_pro"),
      has_contradictory_plan?: Accrue.has_active_plan?(billable, :contradictory),
      features: Accrue.features_for(billable),
      seats: Accrue.entitlement_quantity(billable, :seats)
    }
  end

  defp insert_summary!(customer, data, opts \\ []) do
    now = Keyword.get(opts, :synced_at, DateTime.utc_now())

    %EntitlementSummary{}
    |> EntitlementSummary.force_changeset(%{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      livemode: false,
      entitlement_count: length(get_in(data, ["entitlements", "data"]) || []),
      truncated: false,
      data: data,
      synced_at: now,
      last_stripe_event_ts: now,
      last_stripe_event_id: "evt_#{System.unique_integer([:positive])}"
    })
    |> TestRepo.insert!()
  end
end
