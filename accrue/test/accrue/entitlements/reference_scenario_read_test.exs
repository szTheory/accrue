defmodule Accrue.Entitlements.ReferenceScenarioReadTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Read

  setup do
    previous_entitlements = Application.get_env(:accrue, :entitlements)
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

    on_exit(fn ->
      restore(:entitlements, previous_entitlements)
      restore(:rails, previous_rails)
    end)
  end

  test "web and iOS login collect a fresh canonical snapshot without writes" do
    for {scenario_id, expected_rail} <- [
          {"apple_purchase_to_web_login", :apple},
          {"stripe_purchase_to_ios_login", :stripe}
        ] do
      scenario = ReferenceScenarios.fetch!(scenario_id)
      [purchase, login] = scenario.actions
      account = account!("reference-scenario-read-#{scenario_id}")

      :ok = Read.seed_declared_grant(Accrue.TestRepo, account, purchase.command.payload)
      result = Read.execute(Accrue.TestRepo, account, login)

      assert result.result.disposition == login.kind
      assert result.snapshot.revision == 1
      assert result.snapshot.plans == [:pro]
      assert result.snapshot.sources == [expected_rail]
      assert result.durable.observation_delta == 0
      assert result.durable.grant_delta == 0
      assert result.durable.audit_delta == 0
    end
  end

  test "purchase preflight calls the production decision and records its revision-bound result" do
    scenario = ReferenceScenarios.fetch!("duplicate_purchase_prevention")
    [preflight] = scenario.actions
    account = account!("reference-scenario-read-preflight")

    result = Read.execute(Accrue.TestRepo, account, preflight)

    assert result.result == %{
             tag: "executed",
             disposition: "purchase_preflight",
             status: "block",
             reason: "equivalent_other_rail",
             target_rail: "apple",
             product_id: "product_pro"
           }

    assert result.durable.snapshot_revision == 1
    assert result.durable.observation_delta == 0
    assert result.durable.grant_delta == 0
    assert result.durable.audit_delta == 0
  end

  test "generic grant, no effect, and snapshot-only adapters cannot satisfy preflight" do
    scenario = ReferenceScenarios.fetch!("duplicate_purchase_prevention")
    [preflight] = scenario.actions

    assert {:error, :preflight_mismatch} =
             Read.adversarial_result(
               Accrue.TestRepo,
               account!("reference-scenario-read-generic"),
               preflight,
               adapter: :generic_grant
             )

    assert {:error, :preflight_mismatch} =
             Read.adversarial_result(
               Accrue.TestRepo,
               account!("reference-scenario-read-no-effect"),
               preflight,
               adapter: :no_effect
             )

    assert {:error, :preflight_mismatch} =
             Read.adversarial_result(
               Accrue.TestRepo,
               account!("reference-scenario-read-snapshot-only"),
               preflight,
               adapter: :snapshot_only
             )
  end

  test "expiry boundary rows read persisted grants at their declared frozen microseconds" do
    for {scenario_id, expected_plans} <- [
          {"expiry_immediately_before_boundary", [:pro]},
          {"expiry_at_boundary", []},
          {"expiry_immediately_after_boundary", []}
        ] do
      scenario = ReferenceScenarios.fetch!(scenario_id)
      [action] = scenario.actions
      account = account!("reference-scenario-expiry-#{scenario_id}")

      result = Read.execute(Accrue.TestRepo, account, action)

      assert result.result == %{tag: "executed", disposition: "expiry_boundary"}
      assert result.snapshot.plans == expected_plans
      assert result.snapshot.sources == if(expected_plans == [], do: [], else: [:apple])
      assert result.durable.grant_expires_at == ~U[2026-08-04 12:17:00.000001Z]
      assert result.durable.observation_delta == 0
      assert result.durable.grant_delta == 0
      assert result.durable.audit_delta == 0
    end
  end

  test "generic-grant, no-effect, and in-memory snapshot substitutions fail expiry collection" do
    scenario = ReferenceScenarios.fetch!("expiry_at_boundary")
    [action] = scenario.actions

    for adapter <- [:generic_grant, :no_effect, :in_memory_snapshot] do
      assert {:error, :expiry_mismatch} =
               Read.adversarial_result(
                 Accrue.TestRepo,
                 account!("reference-scenario-expiry-adversarial-#{adapter}"),
                 action,
                 adapter: adapter
               )
    end
  end

  test "each declared read leaf rejects a type-compatible mutation" do
    action = ReferenceScenarios.fetch!("duplicate_purchase_prevention").actions |> hd()

    observed =
      ReferenceScenarioExecutor.execute_action(
        Accrue.TestRepo,
        account!("reference-scenario-read-leaves"),
        action
      )

    Enum.each(transition_mutations(action), fn mutated ->
      assert_raise ExUnit.AssertionError, fn ->
        ReferenceScenarioExecutor.assert_transition(mutated, observed)
      end
    end)
  end

  defp transition_mutations(action) do
    [
      put_in(action.expected_transition.result.tag, "noop"),
      put_in(action.expected_transition.result.disposition, "web_login"),
      put_in(action.expected_transition.durable.state, "changed"),
      put_in(action.expected_transition.durable.observation_kind, "written"),
      put_in(action.expected_transition.durable.snapshot_revision, 99),
      put_in(action.expected_transition.cache.disposition, "replace")
    ]
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
