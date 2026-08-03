defmodule Accrue.Entitlements.CompatibilityTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Entitlements.Compatibility
  alias Accrue.Entitlements.{Account, Grant}
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
    billable = %TestUser{id: Ecto.UUID.generate()}
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

    assert {:error, :clean_window_blocked} =
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

    billable = %TestUser{id: Ecto.UUID.generate()}
    Application.put_env(:accrue, :entitlements, multi_rail: [mode: :disabled])
    assert {:ok, _} = Compatibility.compare(billable)
    assert {:ok, _, _} = Compatibility.authority(billable)
    assert {:error, :not_enabled} = Compatibility.enable(billable)
    assert {:ok, _} = Compatibility.backfill(nil, limit: 1)
    assert :ok = Compatibility.rollback()

    Enum.each([:compare, :authority, :enable, :backfill, :rollback], fn operation ->
      assert_receive {[:accrue, :entitlements, :compatibility, ^operation, :start], metadata}

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

      assert_raise RuntimeError, fn ->
        if operation == :rollback,
          do: Compatibility.rollback(raise: true),
          else: apply(Compatibility, operation, [billable, [raise: true]])
      end

      assert_receive {[:accrue, :entitlements, :compatibility, ^operation, :exception], _}
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
              started_at: ~U[2026-08-02 10:00:00Z],
              ended_at: ~U[2026-08-02 10:01:00Z],
              comparison_count: 1
            ],
            Map.to_list(digests)
          )
      ]
    )
  end
end
