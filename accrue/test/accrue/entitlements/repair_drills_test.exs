defmodule Accrue.Entitlements.RepairDrillsTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, Admin, Repair}
  alias Accrue.Events.Event

  @actor %{type: :admin, id: "operator-220"}

  setup do
    {:ok, account} = Account.fetch_or_create(TestRepo, "test", "owner-220-repair")
    %{account: account}
  end

  test "named reconciliation repairs are authorized, bounded, audited, and idempotent", %{account: account} do
    opts = repair_opts("repair-220-missed")
    target = %{lineage_id: "lineage-220", environment: :production}

    assert {:ok, %{action: :retry_missed_notification, disposition: :queued, audit_id: audit_id}} =
             Repair.retry_missed_notification(account, target, opts)

    assert is_integer(audit_id)
    assert {:ok, %{disposition: :already_completed, audit_id: ^audit_id}} =
             Repair.retry_missed_notification(account, target, opts)

    assert 1 ==
             TestRepo.aggregate(
               from(event in Event,
                 where: event.subject_id == ^account.id and event.type == "entitlements.repair.retry_missed_notification"
               ),
               :count
             )
  end

  test "dry runs and review-only incidents do not mutate ownership or finance", %{account: account} do
    assert {:ok, %{disposition: :dry_run, current_revision: 0}} =
             Repair.recover_history_cursor(
               account,
               %{lineage_id: "lineage-220", environment: :sandbox},
               repair_opts("repair-220-cursor", dry_run: true)
             )

    assert {:ok, %{disposition: :needs_review, action: :review_ownership_conflict}} =
             Repair.review_ownership_conflict(
               account,
               %{correlation: "conflict-220"},
               repair_opts("repair-220-conflict")
             )

    assert {:ok, %{disposition: :escalated, action: :escalate_duplicate_charge}} =
             Repair.escalate_duplicate_charge(
               account,
               %{correlation: "charge-220"},
               repair_opts("repair-220-charge")
             )
  end

  test "outage, device, key, and backlog repairs retain bounded outcomes and converge through diagnostics", %{account: account} do
    for {action, target, operation_id} <- [
          {:retry_provider_check, %{lineage_id: "lineage-220", environment: :production}, "repair-220-outage"},
          {:drain_reconciliation_backlog, %{limit: 2}, "repair-220-backlog"},
          {:replace_revoked_device, %{device_id: "device-220"}, "repair-220-device"},
          {:rotate_signing_keys, %{key_set: "offline-proof"}, "repair-220-keys"}
        ] do
      assert {:ok, %{action: ^action, audit_id: audit_id, current_revision: 0}} =
               apply(Repair, action, [account, target, repair_opts(operation_id)])

      assert is_integer(audit_id)
    end

    assert {:ok, diagnostic} = Admin.diagnostic_for_account(account, repo: TestRepo)
    assert diagnostic.snapshot.revision == 0
  end

  test "an unauthorized or malformed request cannot reach the effect callback", %{account: account} do
    effect = fn _target -> send(self(), :effect_called); {:ok, :queued} end

    assert {:error, :unauthorized} =
             Repair.retry_missed_notification(
               account,
               %{lineage_id: "lineage-220", environment: :production},
               repair_opts("repair-220-noauth", authorize: fn _, _ -> false end, effect: effect)
             )

    refute_received :effect_called

    assert {:error, :invalid_target} =
             Repair.retry_missed_notification(account, %{lineage_id: "", environment: :production}, repair_opts("repair-220-invalid", effect: effect))

    refute_received :effect_called
  end

  defp repair_opts(operation_id, overrides \\ []) do
    [
      repo: TestRepo,
      actor: @actor,
      reason: "Recover the bounded entitlement state",
      operation_id: operation_id,
      authorize: fn _account, actor -> actor == @actor end,
      enqueue: fn _lineage_id, _environment, _reason, _opts -> {:ok, :queued} end,
      effect: fn _target -> {:ok, :queued} end
    ]
    |> Keyword.merge(overrides)
  end
end
