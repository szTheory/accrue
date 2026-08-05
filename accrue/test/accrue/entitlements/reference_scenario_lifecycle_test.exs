defmodule Accrue.Entitlements.ReferenceScenarioLifecycleTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor
  alias Accrue.Events.Event

  defmodule FakeVerifier do
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
    def verify_transaction(signed, _) when is_binary(signed), do: Jason.decode(signed)
  end

  setup do
    previous = Application.get_env(:accrue, :entitlements)
    previous_apple = Application.get_env(:accrue, :apple_reconciliation)
    previous_rails = Application.get_env(:accrue, :rails)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics],
          quotas: [seats: 3],
          products: [stripe: [production: ["price_pro"]], apple: [production: ["product_pro"]]]
        ]
      ]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production],
      apple: [environments: [:production], default_environment: :production]
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

    on_exit(fn ->
      if previous,
        do: Application.put_env(:accrue, :entitlements, previous),
        else: Application.delete_env(:accrue, :entitlements)

      if previous_apple,
        do: Application.put_env(:accrue, :apple_reconciliation, previous_apple),
        else: Application.delete_env(:accrue, :apple_reconciliation)

      if previous_rails,
        do: Application.put_env(:accrue, :rails, previous_rails),
        else: Application.delete_env(:accrue, :rails)
    end)
  end

  test "refund revocation executes grant then refund and collects durable production facts" do
    account = account!("reference-scenario-refund")
    scenario = ReferenceScenarios.fetch!("refund_revocation")

    [grant, refund] = scenario.actions

    assert %{result: %{disposition: "grant_observation"}, durable: grant_durable} =
             ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, account, grant)

    assert grant_durable.observation_kind == "grant"

    assert %{result: %{disposition: "refund_observation"}, durable: durable, cache: cache} =
             ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, account, refund)

    assert durable.observation_kind == "retract"
    assert durable.plan_count == 0
    assert durable.source_count == 0
    assert durable.audit_delta == 1
    assert cache.disposition == "replace"

    assert Accrue.TestRepo.aggregate(
             from(event in Event, where: event.subject_id == ^account.id),
             :count,
             :id
           ) == 2
  end

  test "every lifecycle command is dispatched to the lifecycle family and collected after its write" do
    actions =
      for scenario <- ReferenceScenarios.deterministic_scenarios(),
          action <- scenario.actions,
          ReferenceScenarioExecutor.family_for!(action.kind) ==
            Accrue.Entitlements.ReferenceScenarioExecutor.Lifecycle,
          do: {scenario, action}

    assert length(actions) == 7

    Enum.each(actions, fn {scenario, action} ->
      account = account!("reference-scenario-lifecycle-#{scenario.id}")
      observed = ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, account, action)

      assert observed.result.disposition == action.kind
      assert observed.durable.observation_count >= 1
      assert is_integer(observed.durable.snapshot_revision)
    end)
  end

  test "every deterministic command has one named closed payload inventory" do
    for scenario <- ReferenceScenarios.deterministic_scenarios(), action <- scenario.actions do
      assert action.command.payload |> Map.keys() |> Enum.sort() ==
               action.kind
               |> ReferenceScenarios.action_family!()
               |> Enum.map(&String.to_atom/1)
               |> Enum.sort()
    end
  end

  test "the strict contract rejects universal, cross-family, secret, null, and extra payload fields" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")
    [action | rest] = scenario.actions

    for {field, value} <- [
          {:offline_vector, "valid_allow"},
          {:offline_action, :read_downloaded_lesson},
          {:secret, "receipt-not-allowed"},
          {:provider_event_id, nil},
          {:unexpected, "no"}
        ] do
      invalid = %{
        scenario
        | actions: [
            %{
              action
              | command: %{
                  action.command
                  | payload: Map.put(action.command.payload, field, value)
                }
            }
            | rest
          ]
      }

      refute ReferenceScenarios.valid?(invalid)
    end
  end

  test "actual generic-grant and no-effect substitutions cannot satisfy a refund collection" do
    scenario = ReferenceScenarios.fetch!("refund_revocation")
    [grant, refund] = scenario.actions

    generic_account = account!("reference-scenario-refund-generic")
    generic_refund = %{refund | kind: "grant_observation"}
    _ = ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, generic_account, grant)

    generic =
      ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, generic_account, generic_refund)

    assert generic.durable.plan_count == 1
    assert generic.durable.source_count == 1
    assert generic.cache.disposition == "preserve"

    replay_account = account!("reference-scenario-refund-replay")
    _ = ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, replay_account, grant)
    _ = ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, replay_account, refund)

    replay_refund = %{
      refund
      | command: %{
          refund.command
          | payload: %{
              refund.command.payload
              | provider_event_id: "reference_refund_revocation_refund_replay_event",
                provider_transaction_id: "reference_refund_revocation_refund_replay_transaction",
                provider_order: 1
            }
        }
    }

    replay =
      ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, replay_account, replay_refund)

    assert replay.result.projection == "stale"
    assert replay.durable.audit_delta == 0
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)
end
