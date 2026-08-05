defmodule Accrue.Entitlements.ReferenceScenarioReconnectTest do
  use Accrue.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, ReferenceScenarioExecutor, ReferenceScenarios}
  alias Accrue.Entitlements.Offline.{Challenge, Issuance, ReconnectAttempt}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.ReconnectCache

  setup do
    previous = Application.get_env(:accrue, :entitlements)
    previous_rails = Application.get_env(:accrue, :rails)

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [:offline_study], products: [stripe: [production: ["price_pro"]]]]]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production]
    )

    on_exit(fn ->
      restore(:entitlements, previous)
      restore(:rails, previous_rails)
    end)

    %{scenario: ReferenceScenarios.fetch!("offline_reconnect")}
  end

  test "reconnect and verified cache replacement are one signed, bounded flow", %{
    scenario: scenario
  } do
    [reconnect, cache_replace] = scenario.actions
    account = account!("reference-scenario-reconnect")

    {first, runtime} = ReconnectCache.execute(Accrue.TestRepo, account, reconnect, %{})

    assert first.result == %{tag: "executed", disposition: "reconnect_request"}
    assert first.durable.challenge_consumed
    assert first.durable.attempt_state == "completed"
    assert first.durable.issuance_count == 1
    assert first.durable.issuance_disposition == "allow"
    assert first.durable.snapshot_revision == 1
    refute contains_secret?(first)

    assert 1 == Accrue.TestRepo.aggregate(from(_ in Challenge), :count)
    assert 1 == Accrue.TestRepo.aggregate(from(_ in ReconnectAttempt), :count)
    assert 1 == Accrue.TestRepo.aggregate(from(_ in Issuance), :count)

    {second, _runtime} = ReconnectCache.execute(Accrue.TestRepo, account, cache_replace, runtime)

    assert second.result == %{tag: "executed", disposition: "verified_cache_replace"}
    assert second.cache == %{prior: "allow", replacement: "replace", current: "allow"}
    refute contains_secret?(second)
  end

  test "failed proof verification preserves the complete prior cache tuple", %{scenario: scenario} do
    [reconnect, cache_replace] = scenario.actions
    account = account!("reference-scenario-reconnect-preserve")
    {_first, runtime} = ReconnectCache.execute(Accrue.TestRepo, account, reconnect, %{})

    {observed, _runtime} =
      ReconnectCache.execute(Accrue.TestRepo, account, cache_replace, runtime, tamper_proof: true)

    assert observed.cache == %{prior: "allow", replacement: "preserve", current: "allow"}
    assert observed.result.reason == "verification_failed"
  end

  test "declared reconnect leaves are load-bearing after the signed operation", %{scenario: scenario} do
    [reconnect, cache_replace] = scenario.actions
    account = account!("reference-scenario-reconnect-mutation")
    {first, runtime} = ReconnectCache.execute(Accrue.TestRepo, account, reconnect, %{})
    {second, _runtime} = ReconnectCache.execute(Accrue.TestRepo, account, cache_replace, runtime)

    for {action, observed, path} <- [
          {reconnect, first, [:durable, :snapshot_revision]},
          {cache_replace, second, [:cache, :disposition]}
        ] do
      mutated = mutate_expected(action, path)

      assert_raise ExUnit.AssertionError, ~r/family transition mismatch/, fn ->
        ReferenceScenarioExecutor.assert_transition(mutated, observed)
      end
    end
  end

  test "generic, replay, snapshot, and registration substitutes cannot satisfy reconnect actions",
       %{
         scenario: scenario
       } do
    [reconnect, cache_replace] = scenario.actions

    Enum.each([:generic_grant, :no_effect, :snapshot_only, :registration_only], fn adapter ->
      account = account!("reference-scenario-reconnect-#{adapter}")

      refute ReconnectCache.matches_expected?(
               reconnect,
               ReconnectCache.adversarial_result(Accrue.TestRepo, account, reconnect,
                 adapter: adapter
               )
             )

      refute ReconnectCache.matches_expected?(
               cache_replace,
               ReconnectCache.adversarial_result(Accrue.TestRepo, account, cache_replace,
                 adapter: adapter
               )
             )
    end)
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

  defp mutate_expected(action, [section, leaf]) do
    expected = action.expected_transition
    value = Map.fetch!(Map.fetch!(expected, section), leaf)
    replacement = if is_integer(value), do: value + 1, else: "preserve"

    %{action | expected_transition: Map.update!(expected, section, &Map.put(&1, leaf, replacement))}
  end

  defp contains_secret?(value) when is_map(value),
    do:
      Enum.any?(value, fn {key, item} ->
        to_string(key) in ~w(proof nonce signature private_key idempotency_key) or
          contains_secret?(item)
      end)

  defp contains_secret?(value) when is_list(value), do: Enum.any?(value, &contains_secret?/1)
  defp contains_secret?(_), do: false

  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
