defmodule Accrue.Entitlements.ReferenceScenarioConformanceTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, ReferenceScenarios, ReferenceScenarioExecutor}
  alias Accrue.Entitlements.Offline.Issuance

  defmodule FakeVerifier do
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
    def verify_transaction(signed, _) when is_binary(signed), do: Jason.decode(signed)
  end

  setup do
    prior =
      for key <- [:entitlements, :apple_reconciliation, :rails],
          into: %{},
          do: {key, Application.get_env(:accrue, key)}

    on_exit(fn -> Enum.each(prior, fn {key, value} -> restore(key, value) end) end)

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
  end

  @tag :special_dispatch
  test "every deterministic corpus action reaches its declared executor in declared order" do
    expected_rows = deterministic_rows()

    observed_rows =
      for scenario <- ReferenceScenarios.deterministic_scenarios(),
          action <- scenario.actions do
        account =
          if action.kind == "parallel_delivery",
            do: %{owner_id: "aggregate-#{scenario.id}"},
            else: account!("aggregate-#{scenario.id}")

        # Key-retention is global by design, so each scenario starts its public
        # key calculation with only the issuer rows it provisions itself.
        if action.kind == "rotated_key_proof", do: Accrue.TestRepo.delete_all(Issuance)

        observed = ReferenceScenarioExecutor.execute_action(Accrue.TestRepo, account, action)
        assert :ok = ReferenceScenarioExecutor.assert_transition(action, observed)
        {scenario.id, action.order, action.kind}
      end

    assert observed_rows == expected_rows
    assert length(observed_rows) == 27
    assert Enum.uniq(observed_rows) == observed_rows
  end

  @tag :action_contract
  test "generic grant and no-effect controls fail every declared action transition" do
    for scenario <- ReferenceScenarios.deterministic_scenarios(), action <- scenario.actions do
      account =
        if action.kind == "parallel_delivery",
          do: %{owner_id: "fallback-#{scenario.id}-#{action.order}"},
          else: account!("fallback-#{scenario.id}-#{action.order}")

      for adapter <- [:generic_grant, :no_effect] do
        observed =
          ReferenceScenarioExecutor.adversarial_action(Accrue.TestRepo, account, action, adapter)

        assert_raise ExUnit.AssertionError, fn ->
          ReferenceScenarioExecutor.assert_transition(action, observed)
        end
      end
    end
  end

  @tag :special_dispatch
  test "aggregate proof retains closed production-only action routing" do
    source = File.read!(__ENV__.file)

    refute source =~ ~r/defp\s+dispatch_fixture_/

    assert ReferenceScenarios.deterministic_scenarios()
           |> Enum.flat_map(& &1.actions)
           |> Enum.map(&ReferenceScenarioExecutor.family_for!(&1.kind))
           |> Enum.all?(& &1)
  end

  test "fixture execution modules never read expected transitions" do
    for path <-
          Path.wildcard(
            Path.expand("../../support/entitlements/reference_scenario_executor/**/*.ex", __DIR__)
          ) do
      refute File.read!(path) =~ "expected_transition", path
    end
  end

  defp deterministic_rows do
    for scenario <- ReferenceScenarios.deterministic_scenarios(),
        action <- scenario.actions,
        do: {scenario.id, action.order, action.kind}
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
