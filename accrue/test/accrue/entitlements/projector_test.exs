defmodule Accrue.Entitlements.ProjectorTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Entitlements.{Account, Grant, Observation, Projector}
  alias Accrue.Events.Event

  setup do
    original = Application.get_env(:accrue, :entitlements)
    original_rails = Application.get_env(:accrue, :rails)
    original_default_rail = Application.get_env(:accrue, :default_rail)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics, :exports],
          quotas: [seats: 3],
          products: [
            stripe: [production: ["price_pro"]],
            apple: [production: ["product_pro"]]
          ]
        ]
      ]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production],
      apple: [environments: [:production], default_environment: :production]
    )

    Application.put_env(:accrue, :default_rail, :stripe)

    on_exit(fn ->
      restore_env(:entitlements, original)
      restore_env(:rails, original_rails)
      restore_env(:default_rail, original_default_rail)
    end)

    {:ok, account: account!("projector-owner")}
  end

  defp restore_env(key, nil), do: Application.delete_env(:accrue, key)
  defp restore_env(key, value), do: Application.put_env(:accrue, key, value)

  test "projects qualified cross-rail observations through SQL state, audit, Oban, and public snapshot",
       %{account: account} do
    assert {:ok, stripe} = Projector.project(observation!(account, :stripe, "stripe-1", 1))
    assert stripe.revision == 1

    assert {:ok, snapshot} = Accrue.Entitlements.snapshot(account)
    assert snapshot.plans == [:pro]
    assert snapshot.features == [:analytics, :exports]
    assert snapshot.quantities == %{seats: 3}
    assert Enum.map(snapshot.sources, & &1.rail) == [:stripe]

    assert_enqueued(
      worker: Projector.FollowUpWorker,
      args: %{"account_id" => account.id, "revision" => 1}
    )

    assert {:noop, :no_material_change} =
             Projector.project(observation!(account, :apple, "apple-1", 1))

    assert {:ok, merged} = Accrue.Entitlements.snapshot(account)
    assert merged.revision == 1
    assert Enum.map(merged.sources, & &1.rail) == [:apple, :stripe]
    assert count_events(account.id) == 1
  end

  test "retracts one lineage without removing its surviving rail", %{account: account} do
    assert {:ok, _} = Projector.project(observation!(account, :stripe, "stripe-1", 1))

    assert {:noop, :no_material_change} =
             Projector.project(observation!(account, :apple, "apple-1", 1))

    assert {:noop, :no_material_change} =
             Projector.project(observation!(account, :stripe, "stripe-1", 2, "retract"))

    assert {:ok, retracted} = Accrue.Entitlements.snapshot(account)
    assert retracted.revision == 1
    assert Enum.map(retracted.sources, & &1.rail) == [:apple]
    assert retracted.plans == [:pro]
    assert count_grants(account.id) == 2
    assert count_events(account.id) == 1
  end

  test "duplicate, stale, quarantined, and unmapped observations are no-ops", %{account: account} do
    observation = observation!(account, :stripe, "stripe-1", 3)
    assert {:ok, _} = Projector.project(observation)
    assert {:noop, :stale} = Projector.project(observation)
    assert {:noop, :not_qualified} = Projector.project(%{observation | state: :quarantined})

    unmapped = observation!(account, :apple, "apple-unmapped", 1, "grant", "unknown-product")
    assert {:noop, :no_material_change} = Projector.project(unmapped)
    assert Accrue.TestRepo.get!(Account, account.id).revision == 1
    assert count_events(account.id) == 1
  end

  test "the public read does not provision a missing account", %{account: account} do
    assert {:ok, _} = Accrue.Entitlements.snapshot(account)
    assert {:error, :not_found} = Accrue.Entitlements.snapshot(Ecto.UUID.generate())
    assert Accrue.TestRepo.get!(Account, account.id).id == account.id
  end

  test "projector start and stop telemetry carry only boundary-safe metadata", %{account: account} do
    handler = {__MODULE__, make_ref()}
    parent = self()

    events =
      Enum.map([:start, :stop, :exception], &[:accrue, :entitlements, :projector, :project, &1])

    :ok =
      :telemetry.attach_many(
        handler,
        events,
        fn event, _, metadata, _ -> send(parent, {:projection_span, event, metadata}) end,
        nil
      )

    try do
      assert {:ok, _} =
               Projector.project(observation!(account, :stripe, "stripe-1", 1),
                 actor_id: "person@example.test"
               )

      assert_receive {:projection_span, _event, metadata}

      assert Map.keys(metadata)
             |> Enum.all?(
               &(&1 in [
                   :revision,
                   :action,
                   :rail,
                   :environment,
                   :disposition,
                   :reason,
                   :account_id,
                   :actor_id,
                   :telemetry_span_context
                 ])
             )

      refute inspect(metadata) =~ "person@example.test"
    after
      :telemetry.detach(handler)
    end
  end

  defp account!(owner_id) do
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "test", owner_id)
    account
  end

  defp observation!(account, rail, lineage, order, kind \\ "grant", product \\ nil) do
    product = product || if(rail == :stripe, do: "price_pro", else: "product_pro")

    {:ok, observation} =
      Observation.insert_idempotently(Accrue.TestRepo, %{
        account_id: account.id,
        rail: rail,
        environment: :production,
        provider_event_id: "evt-#{rail}-#{lineage}-#{order}-#{kind}",
        provider_transaction_id: "txn-#{rail}-#{lineage}-#{order}-#{kind}",
        kind: kind,
        provider_lineage_id: lineage,
        provider_product_id: product,
        provider_order: order,
        observed_at: ~U[2026-08-02 12:00:00.000000Z],
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "fake_observer"},
        evidence_digest: String.duplicate("a", 64)
      })

    observation
  end

  defp count_grants(account_id) do
    Accrue.TestRepo.aggregate(
      from(grant in Grant, where: grant.account_id == ^account_id),
      :count,
      :id
    )
  end

  defp count_events(account_id) do
    Accrue.TestRepo.aggregate(
      from(event in Event, where: event.subject_id == ^account_id),
      :count,
      :id
    )
  end
end
