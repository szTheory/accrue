defmodule Accrue.Entitlements.AppleReconciliationTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, Grant, Observation, Projector}
  alias Accrue.Entitlements.Apple.{Client, Reconciliation}
  alias Accrue.Entitlements.Apple.Reconciliation.Checkpoint

  @tag :status
  test "the deterministic client preserves status authority and ascending history scripts" do
    fake =
      Client.Fake.new(
        statuses: [{:ok, [%{transaction: "status-1"}]}],
        history: [
          {:ok, %{signed_transactions: ["page-1"], revision: "r1", has_more: true}},
          {:ok, %{signed_transactions: ["page-2"], revision: "r2", has_more: false}}
        ]
      )

    assert {:ok, [%{transaction: "status-1"}]} =
             Client.subscription_statuses(fake, "lineage", :production)

    assert {:ok, %{revision: "r1", has_more: true}} =
             Client.transaction_history(fake, "lineage", %{sort: :ascending}, nil)

    assert {:ok, %{revision: "r2", has_more: false}} =
             Client.transaction_history(fake, "lineage", %{sort: :ascending}, "r1")
  end

  @tag :status
  test "cadence is bounded and preserves a known provider bound during an outage" do
    now = ~U[2026-08-03 12:00:00Z]

    assert Reconciliation.due(%{next_due_at: nil}, now)
    refute Reconciliation.due(%{next_due_at: DateTime.add(now, 1, :second)}, now)

    assert Reconciliation.retry_after({:error, {:rate_limited, 120}}, 1, now) ==
             DateTime.add(now, 120, :second)

    assert Reconciliation.retry_after({:error, :provider_unavailable}, 20, now) ==
             DateTime.add(now, 21_600, :second)
  end

  @tag :status
  test "filter fingerprints are stable and reject drift" do
    filters = %{product_types: ["AUTO_RENEWABLE"], sort: :ascending}

    assert Reconciliation.query_fingerprint(filters) ==
             Reconciliation.query_fingerprint(%{
               sort: :ascending,
               product_types: ["AUTO_RENEWABLE"]
             })

    refute Reconciliation.query_fingerprint(filters) ==
             Reconciliation.query_fingerprint(%{
               sort: :descending,
               product_types: ["AUTO_RENEWABLE"]
             })
  end

  test "history advances the completed revision only after the final ascending page" do
    fake =
      Client.Fake.new(
        statuses: [{:ok, []}],
        history: [
          {:ok, %{signed_transactions: ["page-1"], revision: "r1", has_more: true}},
          {:ok, %{signed_transactions: ["page-2"], revision: "r2", has_more: false}}
        ]
      )

    lineage_id = Ecto.UUID.generate()
    now = ~U[2026-08-03 12:00:00Z]
    args = %{lineage_id: lineage_id, environment: :production}

    assert {:ok, %Checkpoint{pending_revision: "r1", completed_revision: nil, page_count: 1}} =
             Reconciliation.run(args, repo: Accrue.TestRepo, client: fake, now: now)

    assert {:ok, %Checkpoint{pending_revision: nil, completed_revision: "r2", page_count: 0}} =
             Reconciliation.run(args, repo: Accrue.TestRepo, client: fake, now: now)
  end

  test "complete Apple order keeps delayed positive evidence behind terminal evidence" do
    account = account!("apple-order-terminal")
    signed_at = ~U[2026-08-03 12:00:00.000000Z]
    effective_at = ~U[2026-08-03 13:00:00.000000Z]

    active =
      apple_observation!(account,
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("a", 64)
      )

    assert {:noop, :no_material_change} = Projector.project(active)

    refund =
      apple_observation!(account,
        lifecycle: :refunded,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("b", 64)
      )

    assert {:noop, :no_material_change} = Projector.project(refund)

    delayed_active =
      apple_observation!(account,
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("a", 64)
      )

    assert {:noop, :stale} = Projector.project(delayed_active)
    assert [] == current_grants(account.id)
  end

  test "Apple ordering is deterministic per scope while Stripe retains numeric ordering" do
    account = account!("apple-order-scopes")
    signed_at = ~U[2026-08-03 12:00:00.000000Z]
    effective_at = ~U[2026-08-03 13:00:00.000000Z]

    production =
      apple_observation!(account,
        environment: :production,
        lineage: "lineage-production",
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("c", 64)
      )

    sandbox =
      apple_observation!(account,
        environment: :sandbox,
        lineage: "lineage-sandbox",
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("d", 64)
      )

    assert {:noop, :no_material_change} = Projector.project(production)
    assert {:noop, :no_material_change} = Projector.project(sandbox)

    stripe_low = stripe_observation!(account, 1)
    stripe_high = stripe_observation!(account, 2)
    assert {:noop, :no_material_change} = Projector.project(stripe_low)
    assert {:noop, :no_material_change} = Projector.project(stripe_high)
    assert {:noop, :stale} = Projector.project(stripe_low)
  end

  test "lifecycle normalization preserves only verified provider bounds" do
    signed_at = ~U[2026-08-03 12:00:00.000000Z]
    effective_at = ~U[2026-08-03 13:00:00.000000Z]
    expiry = DateTime.add(effective_at, 30, :day)
    grace_expiry = DateTime.add(expiry, 3, :day)

    assert %{kind: "active", expires_at: ^expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :active,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "renewal_disabled", expires_at: ^expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :renewal_disabled,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "grace", expires_at: ^grace_expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :grace,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               grace_expires_at: grace_expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "grace", expires_at: nil} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :grace,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "billing_retry", expires_at: ^expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :billing_retry,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: grace_expiry,
               last_verified_expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    for lifecycle <- [:expired, :refunded, :revoked] do
      assert %{kind: kind, expires_at: nil} =
               Reconciliation.normalize_lifecycle(%{
                 lifecycle: lifecycle,
                 signed_at: signed_at,
                 effective_at: effective_at,
                 expires_at: expiry,
                 evidence_digest: String.duplicate("f", 64)
               })

      assert kind == Atom.to_string(lifecycle)
    end
  end

  defp account!(owner_id) do
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "test", owner_id)
    account
  end

  defp apple_observation!(account, opts) do
    lifecycle = Keyword.fetch!(opts, :lifecycle)
    environment = Keyword.get(opts, :environment, :production)
    lineage = Keyword.get(opts, :lineage, "lineage-apple")
    signed_at = Keyword.fetch!(opts, :signed_at)
    effective_at = Keyword.fetch!(opts, :effective_at)
    digest = Keyword.fetch!(opts, :digest)

    normalized =
      Reconciliation.normalize_lifecycle(%{
        lifecycle: lifecycle,
        signed_at: signed_at,
        effective_at: effective_at,
        expires_at: DateTime.add(effective_at, 30, :day),
        evidence_digest: digest
      })

    {:ok, observation} =
      Observation.insert_idempotently(Accrue.TestRepo, %{
        account_id: account.id,
        rail: :apple,
        environment: environment,
        provider_event_id: "apple-#{environment}-#{lineage}-#{lifecycle}-#{digest}",
        provider_transaction_id: "transaction-#{digest}",
        kind: normalized.kind,
        provider_lineage_id: lineage,
        provider_product_id: "product_pro",
        provider_order: 1,
        provider_order_key: normalized.provider_order_key,
        observed_at: effective_at,
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "apple_server"},
        evidence_digest: digest
      })

    observation
  end

  defp stripe_observation!(account, order) do
    {:ok, observation} =
      Observation.insert_idempotently(Accrue.TestRepo, %{
        account_id: account.id,
        rail: :stripe,
        environment: :production,
        provider_event_id: "stripe-#{order}",
        provider_transaction_id: "stripe-transaction-#{order}",
        kind: "grant",
        provider_lineage_id: "stripe-lineage",
        provider_product_id: "price_pro",
        provider_order: order,
        observed_at: ~U[2026-08-03 12:00:00.000000Z],
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "fake_observer"},
        evidence_digest: String.duplicate("e", 64)
      })

    observation
  end

  defp current_grants(account_id) do
    Accrue.TestRepo.all(
      from(grant in Grant, where: grant.account_id == ^account_id and is_nil(grant.superseded_at))
    )
  end
end
