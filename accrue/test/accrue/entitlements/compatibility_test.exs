defmodule Accrue.Entitlements.CompatibilityTest do
  use Accrue.BillingCase, async: false

  import Ecto.Query

  alias Accrue.Entitlements.Compatibility
  alias Accrue.Billing.EntitlementSummary
  alias Accrue.Entitlements.{Account, Grant, Observation, Projector}
  alias Accrue.Events.Event
  alias Accrue.Entitlements.Resolver.{Canonical, LocalMap}

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "CompatibilityUser"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "compatibility_test_users" do
    end
  end

  setup do
    previous = Application.get_env(:accrue, :entitlements)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:accrue, :entitlements, previous),
        else: Application.delete_env(:accrue, :entitlements)
    end)

    :ok
  end

  test "omitted and disabled compatibility configuration select LocalMap" do
    Application.delete_env(:accrue, :entitlements)

    assert {:ok, LocalMap, %{mode: :disabled}} =
             Compatibility.authority(%TestUser{id: Ecto.UUID.generate()})

    Application.put_env(:accrue, :entitlements, multi_rail: [mode: :disabled])

    assert {:ok, LocalMap, %{mode: :disabled}} =
             Compatibility.authority(%TestUser{id: Ecto.UUID.generate()})
  end

  test "shadow and enabled modes require an explicit cohort and fail closed" do
    for mode <- [:shadow, :enabled] do
      Application.put_env(:accrue, :entitlements, multi_rail: [mode: mode])

      assert {:error, :missing_cohort} =
               Compatibility.authority(%TestUser{id: Ecto.UUID.generate()})
    end
  end

  test "clean windows are half-open and require one comparison" do
    start = ~U[2026-08-02 10:00:00Z]
    ending = ~U[2026-08-02 10:00:01Z]

    assert {:error, :invalid_clean_window} =
             Compatibility.validate_clean_window(
               started_at: start,
               ended_at: start,
               comparison_count: 1
             )

    assert {:error, :invalid_clean_window} =
             Compatibility.validate_clean_window(
               started_at: start,
               ended_at: ending,
               comparison_count: 0
             )

    assert {:error, :invalid_clean_window} =
             Compatibility.validate_clean_window(
               started_at: ending,
               ended_at: start,
               comparison_count: 1
             )

    assert {:ok, %{started_at: ^start, ended_at: ^ending, comparison_count: 1}} =
             Compatibility.validate_clean_window(
               started_at: start,
               ended_at: ending,
               comparison_count: 1
             )
  end

  test "backfill derives one durable grant from a mapped entitling Stripe subscription and repeats safely" do
    owner_id = Ecto.UUID.generate()

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [price_ids: ["price_compat_pro"]]],
      multi_rail: [mode: :disabled]
    )

    %{subscription: subscription} =
      Accrue.Test.Factory.active_subscription(%{owner_id: owner_id, price_id: "price_compat_pro"})

    {:ok, _} =
      subscription
      |> Accrue.Billing.Subscription.force_status_changeset(%{processor: "stripe"})
      |> Accrue.TestRepo.update()

    assert {:ok, %{processed: 1, inserted: 1, cursor: cursor}} =
             Compatibility.backfill(nil, limit: 1)

    assert {:ok, %{processed: 0}} = Compatibility.backfill(cursor, limit: 1)
    assert {:ok, %{processed: 1}} = Compatibility.backfill(nil, limit: 1)
    assert Accrue.TestRepo.aggregate(Account, :count, :id) == 1
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1
  end

  test "shadow compares an included account but keeps the exact LocalMap authority; excluded is LocalMap too" do
    {billable, account_id} = compatible_billable!()
    put_enabled_config(:shadow, account_id)

    assert {:ok, LocalMap, %{comparison: %{disposition: :match, blockers: []}}} =
             Compatibility.authority(billable, account_id: account_id)

    assert {:ok, LocalMap, %{authority: :local_map}} =
             Compatibility.authority(billable, account_id: Ecto.UUID.generate())
  end

  test "enabled selects Canonical only after exact clean evidence and rollback restores LocalMap without deleting evidence" do
    {billable, account_id} = compatible_billable!()
    put_enabled_config(:shadow, account_id)
    assert {:ok, %{disposition: :match}} = Compatibility.compare(billable, account_id: account_id)
    put_enabled_config(:enabled, account_id)

    assert {:ok, Canonical, %{authority: :canonical}} =
             Compatibility.authority(billable,
               account_id: account_id,
               clean_window_verified: true
             )

    before = Accrue.TestRepo.get!(Account, account_id)
    assert :ok = Compatibility.rollback(account_id: account_id)

    assert {:ok, LocalMap, %{authority: :local_map}} =
             Compatibility.authority(billable,
               account_id: account_id,
               clean_window_verified: true
             )

    assert Accrue.TestRepo.get!(Account, account_id) == before
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1
  end

  test "invalid cohorts, false and raising MFA, malformed mode, stale evidence, and parity blockers fail closed" do
    {billable, account_id} = compatible_billable!()
    start = ~U[2026-08-02 10:00:00Z]
    ending = ~U[2026-08-02 10:01:00Z]

    for bad <- [{:accounts, []}, {:bad, :shape}] do
      Application.put_env(:accrue, :entitlements, multi_rail: [mode: :shadow, cohort: bad])
      assert {:error, :invalid_config} = Compatibility.authority(billable)
    end

    for mfa <- [:always_false, :raise_mfa] do
      Application.put_env(:accrue, :entitlements,
        multi_rail: [mode: :shadow, cohort: {__MODULE__, mfa, []}]
      )

      assert {:ok, LocalMap, _} = Compatibility.authority(billable)
    end

    Application.put_env(:accrue, :entitlements, multi_rail: [mode: :unknown])
    assert {:error, :invalid_config} = Compatibility.authority(billable)

    config = %{mode: :enabled, cohort: {:accounts, ["a"]}, clean_window: nil}

    stale =
      Compatibility.clean_window_digests(config.cohort, config)
      |> Map.put(:catalog_digest, "stale")

    Application.put_env(:accrue, :entitlements,
      multi_rail: [
        mode: :enabled,
        cohort: config.cohort,
        clean_window:
          Keyword.merge(
            [started_at: start, ended_at: ending, comparison_count: 1],
            Map.to_list(stale)
          )
      ]
    )

    assert {:error, :parity_blocked} =
             Compatibility.enable(billable, account_id: "a", clean_window_verified: true)
  end

  test "all compatibility operation span families emit bounded metadata and exception events" do
    id = "compatibility-span-#{System.unique_integer([:positive])}"

    events =
      for op <- [:compare, :authority, :enable, :backfill, :rollback],
          phase <- [:start, :stop, :exception],
          do: [:accrue, :entitlements, :compatibility, op, phase]

    :telemetry.attach_many(
      id,
      events,
      fn event, _measurements, metadata, _ -> send(self(), {event, metadata}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach(id) end)

    {billable, account_id} = compatible_billable!()
    seeded = privacy_seed()
    Application.put_env(:accrue, :entitlements, multi_rail: [mode: :disabled])

    telemetry_opts =
      [account_id: account_id, actor_id: seeded.adopter_id] ++ Map.to_list(seeded)

    assert {:ok, _} = Compatibility.compare(billable, telemetry_opts)
    assert {:ok, _, _} = Compatibility.authority(billable, telemetry_opts)
    assert {:error, :not_enabled} = Compatibility.enable(billable, telemetry_opts)
    assert {:ok, _} = Compatibility.backfill(nil, [limit: 1] ++ telemetry_opts)
    assert :ok = Compatibility.rollback(telemetry_opts)

    Enum.each([:compare, :authority, :enable, :backfill, :rollback], fn operation ->
      assert_receive {[:accrue, :entitlements, :compatibility, ^operation, :start],
                      start_metadata}

      assert_receive {[:accrue, :entitlements, :compatibility, ^operation, :stop], stop_metadata}

      Enum.each([start_metadata, stop_metadata], fn metadata ->
        assert Map.keys(metadata) --
                 [
                   :revision,
                   :action,
                   :rail,
                   :environment,
                   :disposition,
                   :reason,
                   :cohort,
                   :mode,
                   :account_id,
                   :actor_id,
                   :telemetry_span_context
                 ] == []

        refute_recursive_private(metadata, seeded)
      end)

      assert_raise RuntimeError, fn ->
        if operation == :rollback,
          do: Compatibility.rollback([raise: true] ++ telemetry_opts),
          else: apply(Compatibility, operation, [billable, [raise: true] ++ telemetry_opts])
      end

      assert_receive {[:accrue, :entitlements, :compatibility, ^operation, :exception],
                      exception_metadata}

      refute_recursive_private(exception_metadata, seeded)
    end)
  end

  test "durable shadow evidence gates enablement, records privacy-safe blockers, and ignores advisory summaries" do
    {billable, account_id} = compatible_billable!()
    put_enabled_config(:shadow, account_id)

    seeded = privacy_seed()

    assert {:ok, %{disposition: :match}} =
             Compatibility.compare(billable,
               account_id: account_id,
               actor_id: seeded.adopter_id,
               provider_payload: seeded.provider_payload,
               raw_receipt: seeded.raw_receipt,
               jws: seeded.jws,
               token: seeded.token
             )

    [evidence] = Compatibility.audit_entries(account_id, action: :compare)
    assert evidence.disposition == :match
    assert evidence.blocker_count == 0
    refute_recursive_private(evidence, seeded)

    put_enabled_config(:enabled, account_id)

    assert :ok =
             Compatibility.enable(billable, account_id: account_id, actor_id: seeded.adopter_id)

    assert {:ok, Canonical, %{authority: :canonical}} =
             Compatibility.authority(billable, account_id: account_id)

    local_before = LocalMap.resolve(billable, account_id: account_id)
    canonical_before = Canonical.resolve(billable, account_id: account_id)
    parity_before = Compatibility.compare(billable, account_id: account_id)
    grants_before = canonical_bytes(account_id)
    customer = Accrue.TestRepo.get_by!(Accrue.Billing.Customer, owner_id: billable.id)
    summary = insert_conflicting_summary!(customer)

    assert LocalMap.resolve(billable, account_id: account_id) == local_before
    assert Canonical.resolve(billable, account_id: account_id) == canonical_before
    assert Compatibility.compare(billable, account_id: account_id) == parity_before
    assert canonical_bytes(account_id) == grants_before

    assert :erlang.term_to_binary(Accrue.TestRepo.get!(EntitlementSummary, summary.id)) ==
             :erlang.term_to_binary(summary)
  end

  test "unmapped blockers are stable and privacy-safe, while rollback persists only authority transition" do
    {billable, account_id} = compatible_billable!()
    put_enabled_config(:shadow, account_id)

    assert {:ok, %{blockers: [:unmapped_legacy]}} =
             Compatibility.compare(billable,
               account_id: account_id,
               forced_blockers: [:unmapped_legacy]
             )

    assert {:ok, %{blockers: [:unmapped_legacy]}} =
             Compatibility.compare(billable,
               account_id: account_id,
               forced_blockers: [:unmapped_legacy]
             )

    put_enabled_config(:enabled, account_id)
    assert {:error, :parity_blocked} = Compatibility.enable(billable, account_id: account_id)

    assert Enum.all?(
             Compatibility.audit_entries(account_id, action: :compare),
             &(&1.reason == :unmapped_legacy)
           )

    {ambiguous_billable, ambiguous_account_id} = compatible_billable!()
    put_enabled_config(:shadow, ambiguous_account_id)

    for _ <- 1..2 do
      assert {:ok, %{blockers: [:projection_ambiguous]}} =
               Compatibility.compare(ambiguous_billable,
                 account_id: ambiguous_account_id,
                 forced_blockers: [:projection_ambiguous]
               )
    end

    put_enabled_config(:enabled, ambiguous_account_id)

    assert {:error, :parity_blocked} =
             Compatibility.enable(ambiguous_billable, account_id: ambiguous_account_id)

    assert Enum.all?(
             Compatibility.audit_entries(ambiguous_account_id, action: :compare),
             &(&1.reason == :projection_ambiguous)
           )

    Enum.each(Compatibility.audit_entries(ambiguous_account_id, action: :compare), fn audit ->
      refute_recursive_private(audit, privacy_seed())
    end)

    before = canonical_bytes(account_id)
    audits_before = Compatibility.audit_entries(account_id)
    assert :ok = Compatibility.rollback(account_id: account_id, actor_id: "adopter-secret")

    assert {:ok, LocalMap, %{authority: :local_map}} =
             Compatibility.authority(billable, account_id: account_id)

    assert canonical_bytes(account_id) == before

    [rollback] = Compatibility.audit_entries(account_id, action: :rollback)
    assert rollback.disposition == :rolled_back
    refute_recursive_private(rollback, privacy_seed())

    assert Enum.take(Compatibility.audit_entries(account_id), length(audits_before)) ==
             audits_before

    observation = repair_observation!(account_id)
    assert {:noop, :no_material_change} = Projector.project(observation)
    assert Accrue.TestRepo.get!(Observation, observation.id).state == :qualified

    assert {:ok, LocalMap, %{authority: :local_map}} =
             Compatibility.authority(billable, account_id: account_id)
  end

  test "concurrent duplicate backfills converge without provider calls or legacy/advisory mutation" do
    owner_id = Ecto.UUID.generate()

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [price_ids: ["price_compat_pro"]]],
      multi_rail: [mode: :disabled]
    )

    %{subscription: subscription, customer: customer} =
      Accrue.Test.Factory.active_subscription(%{owner_id: owner_id, price_id: "price_compat_pro"})

    {:ok, _} =
      subscription
      |> Accrue.Billing.Subscription.force_status_changeset(%{processor: "stripe"})
      |> Accrue.TestRepo.update()

    summary = insert_conflicting_summary!(customer)

    before =
      :erlang.term_to_binary({
        Accrue.TestRepo.get!(Accrue.Billing.Customer, customer.id),
        Accrue.TestRepo.get!(Accrue.Billing.Subscription, subscription.id),
        Accrue.TestRepo.get!(EntitlementSummary, summary.id)
      })

    fake_counts =
      for operation <- [
            :create_customer,
            :create_subscription,
            :update_subscription,
            :list_active_entitlements
          ],
          into: %{},
          do: {operation, Accrue.Processor.Fake.call_count(operation)}

    results =
      1..2
      |> Task.async_stream(fn _ -> Compatibility.backfill(nil, limit: 1) end,
        max_concurrency: 2,
        timeout: 15_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.all?(results, &match?({:ok, _}, &1))
    assert Accrue.TestRepo.aggregate(Account, :count, :id) == 1
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1

    assert :erlang.term_to_binary(
             {Accrue.TestRepo.get!(Accrue.Billing.Customer, customer.id),
              Accrue.TestRepo.get!(Accrue.Billing.Subscription, subscription.id),
              Accrue.TestRepo.get!(EntitlementSummary, summary.id)}
           ) == before

    Enum.each(fake_counts, fn {operation, count} ->
      assert Accrue.Processor.Fake.call_count(operation) == count
    end)
  end

  def always_false(_billable), do: false
  def raise_mfa(_billable), do: raise("MFA failure")

  defp compatible_billable! do
    owner_id = Ecto.UUID.generate()

    %{subscription: subscription} =
      Accrue.Test.Factory.active_subscription(%{
        owner_id: owner_id,
        owner_type: "CompatibilityUser",
        price_id: "price_compat_pro"
      })

    billable = %TestUser{id: owner_id}
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "CompatibilityUser", owner_id)

    {:ok, _} =
      Accrue.TestRepo.insert(
        Grant.changeset(%Grant{}, %{
          account_id: account.id,
          rail: :stripe,
          environment: :production,
          provider_lineage_id: subscription.processor_id,
          provider_product_id: "price_compat_pro",
          logical_plan: "pro",
          source_item_id: "canonical-#{account.id}",
          quantity: 1,
          provider_order: 0,
          account_revision: 0,
          effective_at: subscription.current_period_start
        })
      )

    {billable, account.id}
  end

  defp put_enabled_config(mode, account_id) do
    base = %{mode: mode, cohort: {:accounts, [account_id, account_id]}, clean_window: nil}

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [], price_ids: ["price_compat_pro"]]],
      multi_rail: [mode: mode, cohort: base.cohort]
    )

    digests = Compatibility.clean_window_digests(base.cohort, base)

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [], price_ids: ["price_compat_pro"]]],
      multi_rail: [
        mode: mode,
        cohort: base.cohort,
        clean_window:
          Keyword.merge(
            [
              started_at: DateTime.add(DateTime.utc_now(), -60, :second),
              ended_at: DateTime.add(DateTime.utc_now(), 60, :second),
              comparison_count: 1
            ],
            Map.to_list(digests)
          )
      ]
    )
  end

  defp insert_conflicting_summary!(customer) do
    now = DateTime.utc_now()

    %EntitlementSummary{}
    |> EntitlementSummary.force_changeset(%{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      livemode: false,
      entitlement_count: 1,
      truncated: false,
      data: %{"entitlements" => %{"data" => [%{"lookup_key" => "conflicting-advisory-private"}]}},
      synced_at: now,
      last_stripe_event_ts: now,
      last_stripe_event_id: "advisory-conflict-#{System.unique_integer([:positive])}"
    })
    |> Accrue.TestRepo.insert!()
  end

  defp repair_observation!(account_id) do
    {:ok, observation} =
      Observation.insert_idempotently(Accrue.TestRepo, %{
        account_id: account_id,
        rail: :stripe,
        environment: :production,
        provider_event_id: "compatibility-repair-#{System.unique_integer([:positive])}",
        provider_transaction_id: "compatibility-repair-txn-#{System.unique_integer([:positive])}",
        kind: "grant",
        provider_lineage_id: "compatibility-repair-lineage",
        provider_product_id: "price_compat_pro",
        provider_order: 1,
        observed_at: DateTime.utc_now(),
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "fake_observer"},
        evidence_digest: String.duplicate("b", 64)
      })

    observation
  end

  defp canonical_bytes(account_id) do
    account = Accrue.TestRepo.get!(Account, account_id)
    grants = Accrue.TestRepo.all(from(grant in Grant, where: grant.account_id == ^account_id))

    observations =
      Accrue.TestRepo.all(
        from(observation in Observation, where: observation.account_id == ^account_id)
      )

    audits =
      Accrue.TestRepo.all(
        from(event in Event,
          where: event.subject_type == "EntitlementAccount" and event.subject_id == ^account_id
        )
      )

    :erlang.term_to_binary({account, grants, observations, audits})
  end

  defp privacy_seed do
    %{
      email: "privacy-negative@example.test",
      adopter_id: "adopter-private-identity",
      raw_receipt: "raw-receipt-private",
      jws: "compact-jws-private",
      token: "generic-token-private",
      provider_payload: %{"private_payload" => "provider-payload-private"}
    }
  end

  defp refute_recursive_private(value, seed) do
    for {key, private} <- seed do
      refute contains_key?(value, key)
      refute contains_value?(value, private)
    end
  end

  defp contains_key?(value, key) when is_map(value),
    do:
      Map.has_key?(value, key) or
        Enum.any?(Map.to_list(value), fn {_key, nested} -> contains_key?(nested, key) end)

  defp contains_key?(value, key) when is_list(value),
    do: Enum.any?(value, &contains_key?(&1, key))

  defp contains_key?(_, _), do: false

  defp contains_value?(value, private) when value == private, do: true

  defp contains_value?(value, private) when is_map(value),
    do: Enum.any?(Map.to_list(value), fn {_key, nested} -> contains_value?(nested, private) end)

  defp contains_value?(value, private) when is_list(value),
    do: Enum.any?(value, &contains_value?(&1, private))

  defp contains_value?(_, _), do: false
end
