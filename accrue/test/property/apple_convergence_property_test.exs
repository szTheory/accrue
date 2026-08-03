defmodule Accrue.Entitlements.AppleConvergencePropertyTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo
  use ExUnitProperties

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Grant, Snapshot}
  alias Accrue.Entitlements.Apple.{Client, Lineage, ReconcileWorker, Reconciliation}
  alias Accrue.Entitlements.Apple.Reconciliation.Checkpoint
  alias Accrue.Entitlements.Apple.ReconciliationWakeupWorker

  defmodule ScriptedClient do
    @behaviour Client
    defstruct statuses: [], pages: []

    def subscription_statuses(%__MODULE__{statuses: statuses}, _, _), do: {:ok, statuses}

    def transaction_history(%__MODULE__{pages: pages}, _, _, revision, _) do
      Enum.find(pages, {:ok, %{signed_transactions: [], has_more: false}}, fn {:ok, page} ->
        Map.get(page, :prior_revision) == revision
      end)
      |> then(fn {:ok, page} -> {:ok, Map.delete(page, :prior_revision)} end)
    end

    def notification_history(_, _, _), do: {:ok, %{notifications: []}}
    def set_app_account_token(_, _, _, _), do: :ok
  end

  defmodule ScriptedVerifier do
    @behaviour Accrue.Entitlements.Apple.Verifier
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}

    def verify_transaction(event, %{account_id: account_id, original_id: original_id}) do
      facts = %{
        "originalTransactionId" => original_id,
        "transactionId" => event,
        "productId" => "product_pro",
        "appAccountToken" => account_id,
        "signedDate" => 1_754_000_000_000,
        "expiresDate" => 1_800_000_000_000
      }

      {:ok,
       if(event == "revoked",
         do: Map.put(facts, "revocationDate", 1_754_000_000_001),
         else: facts
       )}
    end
  end

  setup do
    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [:analytics], products: [apple: [production: ["product_pro"]]]]]
    )

    :ok
  end

  property "queued Apple reconciliation converges across generated delivery and page permutations" do
    check all(
            order <- member_of([["active", "revoked"], ["revoked", "active"]]),
            page_split <- member_of([1, 2])
          ) do
      first = reconcile_variant(order, page_split)
      second = reconcile_variant(Enum.reverse(order), if(page_split == 1, do: 2, else: 1))

      assert first == second
    end
  end

  defp reconcile_variant(events, page_split) do
    {:ok, account} =
      Account.fetch_or_create(
        Accrue.TestRepo,
        "property",
        "apple-#{System.unique_integer([:positive])}"
      )

    lineage =
      Lineage.lock_or_insert(Accrue.TestRepo, :production, "property-original-#{account.id}")

    {:claimed, lineage} = Lineage.claim(Accrue.TestRepo, lineage, account.id, account.id)

    previous = Application.get_env(:accrue, :apple_reconciliation)

    Application.put_env(:accrue, :apple_reconciliation,
      client: %ScriptedClient{pages: pages(events, page_split)},
      admission: admission(account, lineage)
    )

    try do
      assert {:ok, _} =
               Reconciliation.enqueue(lineage.id, :production, :property, repo: Accrue.TestRepo)

      assert :ok = perform_job(ReconciliationWakeupWorker, %{})

      assert :ok =
               perform_job(ReconcileWorker, %{
                 "lineage_id" => lineage.id,
                 "environment" => "production",
                 "reason" => "property"
               })

      if page_split == 1 do
        assert :ok =
                 perform_job(ReconcileWorker, %{
                   "lineage_id" => lineage.id,
                   "environment" => "production",
                   "reason" => "continuation"
                 })
      end

      checkpoint =
        Accrue.TestRepo.get_by!(Checkpoint, lineage_id: lineage.id, environment: :production)

      grants =
        Accrue.TestRepo.all(
          from(grant in Grant,
            where: grant.account_id == ^account.id,
            select: {grant.logical_plan, not is_nil(grant.superseded_at)}
          )
        )

      snapshot =
        Snapshot.fetch(Accrue.TestRepo, account)
        |> Map.take([:revision, :active_plans, :features])

      %{
        snapshot: snapshot,
        grants: grants,
        checkpoint:
          Map.take(checkpoint, [:pending_revision, :completed_revision, :page_count, :run_state])
      }
    after
      if is_nil(previous),
        do: Application.delete_env(:accrue, :apple_reconciliation),
        else: Application.put_env(:accrue, :apple_reconciliation, previous)
    end
  end

  defp pages(events, 2),
    do: [
      {:ok,
       %{prior_revision: nil, signed_transactions: events, revision: "done", has_more: false}}
    ]

  defp pages([first, second], 1),
    do: [
      {:ok,
       %{prior_revision: nil, signed_transactions: [first], revision: "one", has_more: true}},
      {:ok,
       %{prior_revision: "one", signed_transactions: [second], revision: "done", has_more: false}}
    ]

  defp admission(account, lineage),
    do: [
      verifier: ScriptedVerifier,
      verifier_config: %{account_id: account.id, original_id: lineage.original_transaction_id},
      product_map: %{"product_pro" => :pro}
    ]
end
