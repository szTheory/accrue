defmodule Accrue.Entitlements.AppleIntakeTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, Observation}
  alias Accrue.Entitlements.Apple.Intake

  setup do
    {:ok, account: account!("intake-owner")}
  end

  test "unmapped and unbound evidence remain durable and non-granting", %{account: account} do
    unmapped = evidence(account.id, "evt-unmapped", nil)

    assert {:ok,
            %Intake.Outcome{
              disposition: :quarantined,
              reason: :unmapped_product,
              next_action: :map_product
            }} = Intake.observe(account, unmapped)

    unbound = evidence(nil, "evt-unbound", :pro)

    assert {:ok, %Intake.Outcome{reason: :verified_unbound, next_action: :repair_lineage}} =
             Intake.observe(account, unbound)

    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 0
  end

  test "retry exhaustion is durable and terminal", %{account: account} do
    evidence = evidence(account.id, "evt-retry", :pro)
    assert {:ok, _} = Intake.observe(account, evidence)

    intake = Accrue.TestRepo.get_by!(Intake, provider_event_id: "evt-retry")

    {:ok, _} =
      Accrue.TestRepo.update(
        Ecto.Changeset.change(intake,
          reason: "provider_unavailable",
          disposition: "retryable",
          attempts: 11
        )
      )

    assert {:ok,
            %Intake.Outcome{reason: :needs_repair, next_action: :contact_support, revision: 12}} =
             Intake.retry(account, "evt-retry")

    assert {:ok, %Intake.Outcome{reason: :needs_repair}} = Intake.retry(account, "evt-retry")
  end

  defp account!(owner_id) do
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "test", owner_id)
    account
  end

  defp evidence(token, event_id, logical_plan) do
    %Intake.VerifiedEvidence{
      environment: :production,
      original_transaction_id: "orig-#{event_id}",
      app_account_token: token,
      provider_event_id: event_id,
      provider_transaction_id: "txn-#{event_id}",
      product_id: "product_pro",
      logical_plan: logical_plan,
      lifecycle: :grant,
      effective_at: ~U[2026-08-03 12:00:00.000000Z],
      expires_at: ~U[2027-01-15 08:00:00.000000Z],
      signed_at: ~U[2026-08-03 12:00:00.000000Z],
      evidence_digest: String.duplicate("b", 64),
      verifier_version: "fake-v1",
      config_version: "v1"
    }
  end
end
