defmodule Accrue.Entitlements.ProjectionPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Entitlements.{Grant, Snapshot}

  @now ~U[2026-08-02 12:00:00.000000Z]
  @catalog %{
    "pro-stripe" => %{plan: :pro, features: [:analytics, :exports], quotas: %{seats: 1}},
    "pro-apple" => %{plan: :pro, features: [:exports, :priority_support], quotas: %{seats: 2}}
  }

  property "permuting live grants preserves deterministic collections and authorization signature" do
    check all(quantities <- list_of(integer(1..1_000_000), min_length: 1, max_length: 5)) do
      grants = grants_for(quantities)
      expected = snapshot(grants)

      Enum.each(permutations(grants), fn candidate ->
        actual = snapshot(candidate)
        assert public_view(actual) == public_view(expected)

        assert Snapshot.authorization_signature(actual) ==
                 Snapshot.authorization_signature(expected)
      end)
    end
  end

  property "duplicate logical grants merge feature unions and exact positive integer maxima" do
    check all(
            stripe_quantity <- integer(1..9_223_372_036_854_775_807),
            apple_quantity <- integer(1..9_223_372_036_854_775_807)
          ) do
      grants = [grant(:stripe, stripe_quantity), grant(:apple, apple_quantity)]
      expected_quantity = max(stripe_quantity, apple_quantity)

      snapshot = snapshot(grants ++ grants)

      assert snapshot.plans == [:pro]
      assert snapshot.features == [:analytics, :exports, :priority_support]
      assert snapshot.quantities == %{seats: expected_quantity}

      assert Snapshot.authorization_signature(snapshot) ==
               Snapshot.authorization_signature(snapshot(grants))
    end
  end

  property "authorization signature ignores incidental grant metadata and logical duplicates" do
    check all(
            quantity <- integer(1..1_000_000),
            correlation <- string(:alphanumeric, min_length: 1, max_length: 32)
          ) do
      original = grant(:stripe, quantity)

      enriched = %{
        original
        | id: Ecto.UUID.generate(),
          source_item_id: "source-#{correlation}",
          provider_lineage_id: "lineage-#{correlation}",
          source_observation_id: Ecto.UUID.generate()
      }

      assert Snapshot.authorization_signature(snapshot([original])) ==
               Snapshot.authorization_signature(snapshot([enriched, original]))
    end
  end

  test "cutoffs include effective-at and exclude expiry-at with microsecond adjacency" do
    effective_at = @now
    expiry_at = DateTime.add(@now, 2, :microsecond)
    grant = %{grant(:stripe, 3) | effective_at: effective_at, expires_at: expiry_at}

    assert snapshot([grant], DateTime.add(effective_at, -1, :microsecond)).plans == []
    assert snapshot([grant], effective_at).plans == [:pro]
    assert snapshot([grant], DateTime.add(expiry_at, -1, :microsecond)).plans == [:pro]
    assert snapshot([grant], expiry_at).plans == []
    assert snapshot([grant], DateTime.add(expiry_at, 1, :microsecond)).plans == []
  end

  test "empty and expired grant sets produce a valid empty snapshot" do
    expired = %{grant(:stripe, 3) | expires_at: @now}

    for grants <- [[], [expired]] do
      snapshot = snapshot(grants)
      assert snapshot.plans == []
      assert snapshot.features == []
      assert snapshot.quantities == %{}
      assert snapshot.sources == []
    end
  end

  defp grants_for(quantities) do
    quantities
    |> Enum.with_index()
    |> Enum.map(fn {quantity, index} ->
      rail = if rem(index, 2) == 0, do: :stripe, else: :apple
      grant(rail, quantity, "lineage-#{index}")
    end)
  end

  defp permutations(grants), do: permutations_of(grants)
  defp permutations_of([]), do: [[]]

  defp permutations_of(values) do
    for value <- values,
        rest <- permutations_of(List.delete(values, value)),
        do: [value | rest]
  end

  defp snapshot(grants, now \\ @now) do
    Snapshot.from_grants(grants,
      account_id: "account-opaque",
      revision: 7,
      now: now,
      catalog: @catalog
    )
  end

  defp public_view(snapshot) do
    Map.take(snapshot, [:account_id, :revision, :plans, :features, :quantities, :sources])
  end

  defp grant(rail, quantity, lineage \\ nil) do
    %Grant{
      rail: rail,
      environment: :production,
      provider_lineage_id: lineage || "#{rail}-lineage",
      provider_product_id: if(rail == :stripe, do: "pro-stripe", else: "pro-apple"),
      source_item_id: "#{rail}-source",
      quantity: quantity,
      effective_at: @now,
      expires_at: nil,
      superseded_at: nil
    }
  end
end

defmodule Accrue.Entitlements.ProjectorPropertyTest do
  use Accrue.RepoCase, async: false
  use ExUnitProperties
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Entitlements.{Account, Grant, Observation, Projector}

  setup do
    original = {
      Application.get_env(:accrue, :entitlements),
      Application.get_env(:accrue, :rails),
      Application.get_env(:accrue, :default_rail)
    }

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics, :exports],
          limits: [seats: 3],
          products: [stripe: [production: ["price_pro"]], apple: [production: ["product_pro"]]]
        ]
      ]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production],
      apple: [environments: [:production], default_environment: :production]
    )

    Application.put_env(:accrue, :default_rail, :stripe)

    on_exit(fn ->
      {entitlements, rails, default_rail} = original
      restore_env(:entitlements, entitlements)
      restore_env(:rails, rails)
      restore_env(:default_rail, default_rail)
    end)

    :ok
  end

  defp restore_env(key, nil), do: Application.delete_env(:accrue, key)
  defp restore_env(key, value), do: Application.put_env(:accrue, key, value)

  property "repeated identical qualified evidence is idempotent in PostgreSQL" do
    check all(order <- integer(1..1_000_000)) do
      suffix = Ecto.UUID.generate()
      account = account!("property-owner-#{suffix}")
      observation = observation!(account, :stripe, "lineage-#{suffix}", order)
      seed_current_grant!(observation)

      try do
        assert {:noop, :stale} = Projector.project(observation)
        assert {:noop, :stale} = Projector.project(observation)
        assert {:ok, current} = Accrue.Entitlements.snapshot(account)

        assert current.revision == 0
        assert grant_count(account.id) == 1
      after
        cleanup_account(Accrue.TestRepo, account.id)
      end
    end
  end

  test "parallel identical observations serialize to one current grant and revision" do
    {account, observation} =
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Accrue.TestRepo, fn ->
        suffix = Ecto.UUID.generate()
        account = account!("concurrent-owner-#{suffix}")
        observation = observation!(account, :stripe, "concurrent-lineage-#{suffix}", 1)
        seed_current_grant!(observation)
        {account, observation}
      end)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Accrue.TestRepo, fn ->
        cleanup_account(Accrue.TestRepo, account.id)
      end)
    end)

    results =
      run_unboxed_concurrently([
        fn -> Projector.project(observation) end,
        fn -> Projector.project(observation) end
      ])

    assert results == [{:noop, :stale}, {:noop, :stale}]

    Ecto.Adapters.SQL.Sandbox.unboxed_run(Accrue.TestRepo, fn ->
      assert {:ok, snapshot} = Accrue.Entitlements.snapshot(account)
      assert snapshot.revision == 0
      assert grant_count(account.id) == 1
    end)
  end

  test "the Phase-215 survivor case preserves an equivalent authorization revision" do
    case_data =
      Accrue.Entitlements.DecisionCases.all()
      |> Enum.find(&(&1.id == "stripe_revoked_apple_survives"))

    account = account!("survivor-owner-#{Ecto.UUID.generate()}")

    try do
      stripe = observation!(account, :stripe, "stripe-survivor", 1)
      apple = observation!(account, :apple, "apple-survivor", 1)
      seed_current_grant!(stripe)
      seed_current_grant!(apple)

      before = Accrue.TestRepo.get!(Account, account.id)

      assert {:noop, :no_material_change} =
               Projector.project(observation!(account, :stripe, "stripe-survivor", 2, "retract"))

      assert {:ok, snapshot} = Accrue.Entitlements.snapshot(account)
      assert snapshot.plans == [:pro]
      assert snapshot.revision - before.revision == case_data.expected.revision_delta
      assert case_data.expected.reason == "entitlement_stripe_revoked_apple_survives"
    after
      cleanup_account(Accrue.TestRepo, account.id)
    end
  end

  defp account!(owner_id) do
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "property", owner_id)
    account
  end

  defp observation!(account, rail, lineage, order, kind \\ "grant") do
    {:ok, observation} =
      Observation.insert_idempotently(Accrue.TestRepo, %{
        account_id: account.id,
        rail: rail,
        environment: :production,
        provider_event_id: "evt-#{lineage}-#{order}",
        provider_transaction_id: "txn-#{lineage}-#{order}",
        kind: kind,
        provider_lineage_id: lineage,
        provider_product_id: if(rail == :stripe, do: "price_pro", else: "product_pro"),
        provider_order: order,
        observed_at: ~U[2026-08-02 12:00:00.000000Z],
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "fake_observer"},
        evidence_digest: String.duplicate("a", 64)
      })

    observation
  end

  defp seed_current_grant!(observation) do
    Accrue.TestRepo.insert!(
      Grant.changeset(%Grant{}, %{
        account_id: observation.account_id,
        source_observation_id: observation.id,
        rail: observation.rail,
        environment: observation.environment,
        provider_lineage_id: observation.provider_lineage_id,
        provider_product_id: observation.provider_product_id,
        source_item_id: observation.provider_transaction_id || observation.provider_event_id,
        quantity: 1,
        provider_order: observation.provider_order,
        account_revision: 0,
        effective_at: observation.observed_at
      })
    )
  end

  defp grant_count(account_id) do
    Accrue.TestRepo.aggregate(
      Ecto.Query.where(Grant, [grant], grant.account_id == ^account_id),
      :count,
      :id
    )
  end

  defp cleanup_account(repo, account_id) do
    repo.delete_all(Ecto.Query.where(Grant, [grant], grant.account_id == ^account_id))

    repo.delete_all(
      Ecto.Query.where(Observation, [observation], observation.account_id == ^account_id)
    )

    repo.delete_all(Ecto.Query.where(Account, [account], account.id == ^account_id))
  end

  defp run_unboxed_concurrently(funs) do
    parent = self()
    ref = make_ref()

    tasks =
      Enum.map(funs, fn fun ->
        Task.async(fn ->
          Ecto.Adapters.SQL.Sandbox.unboxed_run(Accrue.TestRepo, fn ->
            send(parent, {ref, :ready, self()})

            receive do
              {^ref, :run} -> fun.()
            end
          end)
        end)
      end)

    for _ <- funs, do: assert_receive({^ref, :ready, _pid}, 5_000)
    Enum.each(tasks, &send(&1.pid, {ref, :run}))
    Task.await_many(tasks, 10_000)
  end
end
