defmodule Accrue.Entitlements.AppleLineageTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Entitlements.{Account, Observation}
  alias Accrue.Entitlements.Apple.Intake

  setup do
    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [:analytics], products: [apple: [production: ["product_pro"]]]]]
    )

    {:ok, account: account!("repair-owner")}
  end

  test "authorized repair binds a durable unbound lineage exactly once", %{account: account} do
    unbound = evidence(nil, "evt-unbound", "txn-unbound")
    assert {:ok, %Intake.Outcome{reason: :verified_unbound}} = Accrue.Entitlements.observe_apple_evidence(account, unbound)

    lineage_id = lineage_id()
    repaired = evidence(account.id, "evt-repaired", "txn-repaired")

    assert {:ok, %Intake.Outcome{disposition: :verified, revision: 1}} =
             Accrue.Entitlements.repair_apple_lineage(account, lineage_id,
               authorize: fn ^account, :repair_apple_lineage -> true end,
               reverify: fn ^lineage_id -> {:ok, repaired} end,
               actor_id: "operator"
             )

    assert %{account_id: account_id, binding_state: :bound} = Accrue.TestRepo.get!(Accrue.Entitlements.Apple.Lineage, lineage_id)
    assert account_id == account.id
    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 1

    assert {:ok, %Intake.Outcome{disposition: :noop, reason: :duplicate}} =
             Accrue.Entitlements.repair_apple_lineage(account, lineage_id,
               authorize: fn _, _ -> true end,
               reverify: fn -> {:ok, repaired} end
             )
  end

  test "missing authorization does not invoke provider repair or mutate state", %{account: account} do
    assert {:error, :unauthorized} =
             Accrue.Entitlements.repair_apple_lineage(account, Ecto.UUID.generate(),
               authorize: fn _, _ -> false end,
               reverify: fn -> flunk("provider must not run") end
             )
  end

  defp account!(owner_id) do
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "test", owner_id)
    account
  end

  defp lineage_id do
    %{rows: [[id]]} = Ecto.Adapters.SQL.query!(Accrue.TestRepo, "SELECT id FROM billing.accrue_entitlement_apple_lineages", [])
    {:ok, id} = Ecto.UUID.load(id)
    id
  end

  defp evidence(token, event_id, transaction_id) do
    %Intake.VerifiedEvidence{
      environment: :production,
      original_transaction_id: "orig-repair",
      app_account_token: token,
      provider_event_id: event_id,
      provider_transaction_id: transaction_id,
      product_id: "product_pro",
      logical_plan: :pro,
      lifecycle: :grant,
      effective_at: ~U[2026-08-03 12:00:00.000000Z],
      signed_at: ~U[2026-08-03 12:00:00.000000Z],
      evidence_digest: String.duplicate("a", 64),
      verifier_version: "fake-v1",
      config_version: "v1"
    }
  end
end
