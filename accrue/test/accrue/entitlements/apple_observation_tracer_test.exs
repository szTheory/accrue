defmodule Accrue.Entitlements.AppleObservationTracerTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  Code.require_file("../../fixtures/apple/server_evidence.exs", __DIR__)

  alias Accrue.Entitlements.{Account, Grant, Observation}
  alias Accrue.Entitlements.Apple.Intake
  alias Accrue.Entitlements.Apple.Verifier.{Config, Production}
  alias Accrue.Test.AppleServerEvidence, as: Evidence

  defmodule FakeVerifier do
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
    def verify_transaction(signed, _) when is_binary(signed), do: Jason.decode(signed)
  end

  setup do
    previous_entitlements = Application.get_env(:accrue, :entitlements)
    previous_reconciliation = Application.get_env(:accrue, :apple_reconciliation)

    on_exit(fn ->
      restore_env(:entitlements, previous_entitlements)
      restore_env(:apple_reconciliation, previous_reconciliation)
    end)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics],
          limits: [seats: 3],
          products: [apple: [production: ["product_pro"]]]
        ]
      ]
    )

    Application.put_env(:accrue, :apple_reconciliation,
      admission: [
        verifier: FakeVerifier,
        verifier_config: :test,
        product_map: %{"product_pro" => :pro},
        verifier_version: "fake-v1",
        config_version: "test-v1"
      ]
    )

    {:ok, account: account!("apple-owner"), other_account: account!("other-apple-owner")}
  end

  defp restore_env(key, nil), do: Application.delete_env(:accrue, key)
  defp restore_env(key, value), do: Application.put_env(:accrue, key, value)

  test "purchase context returns only the opaque entitlement account token", %{account: account} do
    token = account.id

    assert %{app_account_token: ^token, environment: :production, bundle_id: bundle_id} =
             Accrue.Entitlements.apple_purchase_context(account)

    assert is_binary(bundle_id)
  end

  test "verified Apple evidence binds, projects, and then becomes a duplicate noop", %{
    account: account
  } do
    evidence = signed_evidence(account)

    assert {:ok, %Intake.Outcome{disposition: :verified, snapshot: snapshot, revision: 1}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)

    assert snapshot.revision == 1
    assert count(:accrue_entitlement_apple_lineages) == 1
    assert count(:accrue_entitlement_apple_intakes) == 1
    assert count(Observation) == 1
    assert count(Grant) == 1
    assert count(:accrue_entitlement_apple_reconciliation_wakeups) == 1

    expected_expiry = ~U[2027-01-15 08:00:00.000000Z]

    assert Accrue.TestRepo.one!(from(observation in Observation, select: observation.expires_at)) ==
             expected_expiry

    assert Accrue.TestRepo.one!(from(grant in Grant, select: grant.expires_at)) == expected_expiry

    assert {:ok, %Intake.Outcome{disposition: :noop, reason: :duplicate, revision: nil}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)

    assert Accrue.TestRepo.get!(Account, account.id).revision == 1
    assert count(Grant) == 1
  end

  test "missing or invalid active expiry is rejected before durable writes", %{account: account} do
    for expires_date <- [nil, "not-a-timestamp", -9_999_999_999_999_999] do
      before = durable_counts(account)

      assert {:error, :invalid_payload} =
               Accrue.Entitlements.observe_apple_evidence(
                 account,
                 signed_evidence(account, %{
                   "transactionId" => "txn-invalid-expiry-#{inspect(expires_date)}",
                   "expiresDate" => expires_date
                 })
               )

      assert durable_counts(account) == before
    end
  end

  test "Production purpose variants cannot create durable entitlement effects", %{
    account: account
  } do
    Application.put_env(:accrue, :apple_reconciliation,
      admission: [
        verifier: Production,
        verifier_config: %Config{
          roots: [Evidence.production_root()],
          bundle_id: "com.accrue.test",
          environment: :production,
          app_apple_id: 42,
          verification_time: nil,
          verifier_version: "apple-v1",
          config_version: "test-v1"
        },
        product_map: %{"product_pro" => :pro},
        verifier_version: "apple-v1",
        config_version: "test-v1"
      ]
    )

    assert {:ok, %Intake.Outcome{disposition: :verified, revision: 1}} =
             Accrue.Entitlements.observe_apple_evidence(
               account,
               Evidence.production_transaction(%{"appAccountToken" => account.id})
             )

    before = durable_counts(account)

    for kind <- [
          :wrong_leaf_purpose,
          :missing_leaf_purpose,
          :wrong_intermediate_purpose,
          :missing_intermediate_purpose,
          :ca_leaf,
          :missing_digital_signature,
          :ca_signing_only
        ] do
      assert {:error, :invalid_certificate_purpose} =
               Accrue.Entitlements.observe_apple_evidence(
                 account,
                 Evidence.hostile_transaction(kind)
               )

      assert durable_counts(account) == before
    end
  end

  test "unbound verified evidence is durable but cannot grant", %{account: account} do
    evidence =
      signed_evidence(account, %{"appAccountToken" => nil, "transactionId" => "txn-unbound"})

    assert {:ok, %Intake.Outcome{disposition: :quarantined, reason: :verified_unbound}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)

    assert count(:accrue_entitlement_apple_lineages) == 1
    assert count(:accrue_entitlement_apple_intakes) == 1
    assert count(Observation) == 0
    assert count(Grant) == 0
    assert Accrue.TestRepo.get!(Account, account.id).revision == 0
  end

  test "caller-created verified evidence is closed before durable writes", %{account: account} do
    assert {:error, :invalid_input} =
             Accrue.Entitlements.observe_apple_evidence(account, verified_evidence(account))

    assert count(:accrue_entitlement_apple_lineages) == 0
    assert count(Observation) == 0
    assert count(Grant) == 0
  end

  test "conflicting lineage ownership remains private and non-granting", %{
    account: account,
    other_account: other_account
  } do
    assert {:ok, _} =
             Accrue.Entitlements.observe_apple_evidence(account, signed_evidence(account))

    conflicting = signed_evidence(other_account, %{"transactionId" => "txn-conflict"})

    assert {:ok,
            %Intake.Outcome{disposition: :quarantined, reason: :ownership_conflict} = outcome} =
             Accrue.Entitlements.observe_apple_evidence(other_account, conflicting)

    refute inspect(outcome) =~ account.id
    assert count(Observation) == 1
    assert count(Grant) == 1
    assert Accrue.TestRepo.get!(Account, other_account.id).revision == 0
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
             Accrue.Entitlements.observe_apple_evidence(account, signed_evidence(account))
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
      expires_at: ~U[2027-01-15 08:00:00.000000Z],
      signed_at: ~U[2026-08-03 12:00:00.000000Z],
      evidence_digest: String.duplicate("a", 64),
      verifier_version: "fake-v1",
      config_version: "v1"
    }
  end

  defp signed_evidence(account, overrides \\ %{}) do
    %{
      "originalTransactionId" => "orig-apple-1",
      "appAccountToken" => account.id,
      "transactionId" => "txn-apple-1",
      "productId" => "product_pro",
      "signedDate" => 1_754_000_000_000,
      "expiresDate" => 1_800_000_000_000
    }
    |> Map.merge(overrides)
    |> Jason.encode!()
  end

  defp count(table)
       when table in [
              :accrue_entitlement_apple_lineages,
              :accrue_entitlement_apple_intakes,
              :accrue_entitlement_apple_reconciliation_wakeups
            ] do
    %{rows: [[count]]} =
      Ecto.Adapters.SQL.query!(
        Accrue.TestRepo,
        "SELECT count(*) FROM billing.#{table}",
        []
      )

    count
  end

  defp count(schema), do: Accrue.TestRepo.aggregate(schema, :count, :id)

  defp durable_counts(account) do
    %{
      lineages: count(:accrue_entitlement_apple_lineages),
      intakes: count(:accrue_entitlement_apple_intakes),
      observations: count(Observation),
      grants: count(Grant),
      wakeups: count(:accrue_entitlement_apple_reconciliation_wakeups),
      revision: Accrue.TestRepo.get!(Account, account.id).revision
    }
  end
end
