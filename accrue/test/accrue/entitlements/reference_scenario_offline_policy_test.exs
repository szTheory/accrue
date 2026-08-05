defmodule Accrue.Entitlements.ReferenceScenarioOfflinePolicyTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor
  alias Accrue.Entitlements.ReferenceScenarioExecutor.OfflinePolicy

  setup do
    previous = Application.get_env(:accrue, :entitlements)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics],
          quotas: [seats: 3],
          products: [stripe: [production: ["price_pro"]], apple: [production: ["product_pro"]]]
        ]
      ]
    )

    on_exit(fn ->
      if previous,
        do: Application.put_env(:accrue, :entitlements, previous),
        else: Application.delete_env(:accrue, :entitlements)
    end)
  end

  test "stale proof executes the signed vector and keeps downloaded study available" do
    action = ReferenceScenarios.fetch!("stale_downloaded_study_continuity") |> hd_action()
    account = account!("reference-scenario-offline-stale")

    assert %{
             result: %{
               state: "stale_offline",
               reason: "revalidation_due",
               next_action: "reconnect_required",
               revision: 5
             },
             policy: %{
               action: :read_downloaded_lesson,
               allowed: true,
               reason: "allow_downloaded_study"
             },
             durable: %{write_delta: 0},
             cache: %{disposition: "preserve"}
           } =
             OfflinePolicy.execute(Accrue.TestRepo, account, action)
  end

  test "restricted expansion applies policy to the verified stale decision without expanding value" do
    action = ReferenceScenarios.fetch!("restricted_expansion") |> hd_action()
    account = account!("reference-scenario-offline-expansion")

    assert %{
             result: %{state: "stale_offline", reason: "revalidation_due"},
             policy: %{action: :download_premium, allowed: false, reason: "reconnect_required"},
             durable: %{write_delta: 0},
             cache: %{disposition: "preserve"}
           } =
             OfflinePolicy.execute(Accrue.TestRepo, account, action)
  end

  test "signed deny, rollback, and empty evidence retain distinct verifier reasons" do
    cases = [
      {"deny_tombstone", "denied", "signed_denial", :read_downloaded_lesson},
      {"clock_rollback", "invalid", "clock_rollback", :read_downloaded_lesson},
      {"empty_evidence_fails_closed", "invalid", "malformed", :read_downloaded_lesson}
    ]

    Enum.each(cases, fn {scenario_id, state, reason, action_name} ->
      action = ReferenceScenarios.fetch!(scenario_id) |> hd_action()
      account = account!("reference-scenario-offline-#{scenario_id}")

      assert %{
               result: %{state: ^state, reason: ^reason},
               policy: %{action: ^action_name, allowed: false},
               durable: %{write_delta: 0},
               cache: %{disposition: "preserve"}
             } =
               OfflinePolicy.execute(Accrue.TestRepo, account, action)
    end)
  end

  test "actual generic-grant and no-effect adapters fail every offline expectation" do
    actions =
      for scenario_id <-
            ~w(stale_downloaded_study_continuity restricted_expansion deny_tombstone clock_rollback empty_evidence_fails_closed) do
        ReferenceScenarios.fetch!(scenario_id) |> hd_action()
      end

    Enum.each(actions, fn action ->
      generic_account = account!("reference-scenario-offline-generic-#{action.kind}")
      replay_account = account!("reference-scenario-offline-replay-#{action.kind}")

      generic =
        OfflinePolicy.adversarial_result(Accrue.TestRepo, generic_account, action,
          adapter: :generic_grant
        )

      replay =
        OfflinePolicy.adversarial_result(Accrue.TestRepo, replay_account, action,
          adapter: :no_effect
        )

      refute OfflinePolicy.matches_expected?(action, generic)
      refute OfflinePolicy.matches_expected?(action, replay)
    end)
  end

  test "only empty evidence may call the verifier with an empty compact value" do
    actions =
      for scenario <- ReferenceScenarios.deterministic_scenarios(),
          action <- scenario.actions,
          ReferenceScenarios.action_family!(action.kind) |> Enum.member?("offline_vector"),
          do: action

    assert Enum.all?(actions, fn action ->
             if action.kind == "empty_evidence" do
               OfflinePolicy.compact_for(action) == ""
             else
               is_binary(OfflinePolicy.compact_for(action)) and
                 OfflinePolicy.compact_for(action) != ""
             end
           end)
  end

  test "each declared offline leaf rejects a type-compatible mutation" do
    action = ReferenceScenarios.fetch!("stale_downloaded_study_continuity") |> hd_action()

    observed =
      ReferenceScenarioExecutor.execute_action(
        Accrue.TestRepo,
        account!("reference-scenario-offline-leaves"),
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
      put_in(action.expected_transition.result.disposition, "signed_deny"),
      put_in(action.expected_transition.durable.state, "changed"),
      put_in(action.expected_transition.durable.observation_kind, "written"),
      put_in(action.expected_transition.durable.snapshot_revision, 99),
      put_in(action.expected_transition.cache.disposition, "replace")
    ]
  end

  defp hd_action(scenario), do: hd(scenario.actions)

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)
end
