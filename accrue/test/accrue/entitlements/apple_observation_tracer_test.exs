defmodule Accrue.Entitlements.AppleObservationTracerTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Grant, Observation}
  alias Accrue.Entitlements.Apple.Intake

  setup do
    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics],
          quotas: [seats: 3],
          products: [apple: [production: ["product_pro"]]]
        ]
      ]
    )

    {:ok, account: account!("apple-owner"), other_account: account!("other-apple-owner")}
  end

  test "purchase context returns only the opaque entitlement account token", %{account: account} do
    token = account.id

    assert %{app_account_token: ^token, environment: :production, bundle_id: bundle_id} =
             Accrue.Entitlements.apple_purchase_context(account)

    assert is_binary(bundle_id)
  end

  test "verified Apple evidence binds, projects, and then becomes a duplicate noop", %{account: account} do
    evidence = verified_evidence(account)

    assert {:ok, %Intake.Outcome{disposition: :verified, snapshot: snapshot, revision: 1}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)

    assert snapshot.revision == 1
    assert count(:accrue_entitlement_apple_lineages) == 1
    assert count(:accrue_entitlement_apple_intakes) == 1
    assert count(Observation) == 1
    assert count(Grant) == 1
    assert count(:accrue_entitlement_apple_reconciliation_wakeups) == 1

    assert {:ok, %Intake.Outcome{disposition: :noop, reason: :duplicate, revision: nil}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)

    assert Accrue.TestRepo.get!(Account, account.id).revision == 1
    assert count(Grant) == 1
  end

  test "unbound verified evidence is durable but cannot grant", %{account: account} do
    evidence = %{verified_evidence(account) | app_account_token: nil, provider_event_id: "evt-unbound"}

    assert {:ok, %Intake.Outcome{disposition: :quarantined, reason: :verified_unbound}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)

    assert count(:accrue_entitlement_apple_lineages) == 1
    assert count(:accrue_entitlement_apple_intakes) == 1
    assert count(Observation) == 0
    assert count(Grant) == 0
    assert Accrue.TestRepo.get!(Account, account.id).revision == 0
  end

  test "conflicting lineage ownership remains private and non-granting", %{
    account: account,
    other_account: other_account
  } do
    assert {:ok, _} = Accrue.Entitlements.observe_apple_evidence(account, verified_evidence(account))

    conflicting =
      %{verified_evidence(other_account) | provider_event_id: "evt-conflict", provider_transaction_id: "txn-conflict"}

    assert {:ok, %Intake.Outcome{disposition: :quarantined, reason: :ownership_conflict} = outcome} =
             Accrue.Entitlements.observe_apple_evidence(other_account, conflicting)

    refute inspect(outcome) =~ account.id
    assert count(Observation) == 1
    assert count(Grant) == 1
    assert Accrue.TestRepo.get!(other_account.id).revision == 0
  end

  test "a callback failure rolls all in-transaction writes back", %{account: account} do
    evidence = verified_evidence(account)

    assert {:error, :injected_failure} =
             Accrue.Entitlements.Apple.Intake.observe(account, evidence,
               repo: Accrue.TestRepo,
               after_write: fn -> raise "injected_failure" end
             )

    assert count(:accrue_entitlement_apple_lineages) == 0
    assert count(:accrue_entitlement_apple_intakes) == 0
    assert count(Observation) == 0
    assert count(Grant) == 0
    assert count(:accrue_entitlement_apple_reconciliation_wakeups) == 0

    assert {:ok, %Intake.Outcome{revision: 1}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)
  end

  defp account!(owner_id) do
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "test", owner_id)
    account
  end

  defp verified_evidence(account) do
    %Intake.VerifiedEvidence{
      environment: :production,
      original_transaction_id: "orig-apple-1",
      app_account_token: account.id,
      provider_event_id: "evt-apple-1",
      provider_transaction_id: "txn-apple-1",
      product_id: "product_pro",
      logical_plan: :pro,
      lifecycle: :grant,
      effective_at: ~U[2026-08-03 12:00:00.000000Z],
      expires_at: nil,
      signed_at: ~U[2026-08-03 12:00:00.000000Z],
      evidence_digest: String.duplicate("a", 64),
      verifier_version: "fake-v1",
      config_version: "v1"
    }
  end

  defp count(table) when is_atom(table) do
    %{rows: [[count]]} =
      Ecto.Adapters.SQL.query!(
        Accrue.TestRepo,
        "SELECT count(*) FROM billing.#{table}",
        []
      )

    count
  end

  defp count(schema), do: Accrue.TestRepo.aggregate(schema, :count, :id)
end
