defmodule Accrue.Entitlements.ReferenceScenarioResumeTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Resume

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

    %{scenario: ReferenceScenarios.fetch!("interrupted_resume")}
  end

  test "durable interruption is a signed reconnect with a persisted resumable boundary", %{
    scenario: scenario
  } do
    [interruption | _] = scenario.actions
    account = account!("reference-scenario-resume-interruption")

    {observed, _runtime} = Resume.execute(Accrue.TestRepo, account, interruption, %{})

    assert observed.result == %{tag: "interrupted", disposition: "admission_interrupted"}
    assert observed.durable.attempt_state == "admitted"
    assert observed.durable.challenge_consumed
    assert observed.durable.issuance_count == 0
    assert observed.cache == %{prior: "allow", replacement: "preserve", current: "allow"}
  end

  test "same-request replay resumes one authority, replaces the complete cache, and rejects substitutes",
       %{
         scenario: scenario
       } do
    [interruption, resume] = scenario.actions
    account = account!("reference-scenario-resume-delivery")

    {first, runtime} = Resume.execute(Accrue.TestRepo, account, interruption, %{})
    {second, _runtime} = Resume.execute(Accrue.TestRepo, account, resume, runtime)

    assert first.durable.attempt_id == second.durable.attempt_id
    assert first.durable.challenge_id == second.durable.challenge_id
    assert second.result == %{tag: "resumed", disposition: "issued"}
    assert second.durable.attempt_state == "completed"
    assert second.durable.challenge_consumed
    assert second.durable.issuance_count == 1
    assert second.durable.issuance_revision == 1
    assert second.durable.issuance_disposition == "allow"
    assert second.cache == %{prior: "allow", replacement: "replace", current: "allow"}
    assert second.replay == "stable"
    refute contains_secret?(second)
    assert Resume.matches_expected?(resume, second)

    Enum.each([:generic_grant, :no_effect, :snapshot_only], fn adapter ->
      fresh_account = account!("reference-scenario-resume-substitute-#{adapter}")

      refute Resume.matches_expected?(
               interruption,
               Resume.adversarial_result(Accrue.TestRepo, fresh_account, interruption, adapter)
             )

      refute Resume.matches_expected?(
               resume,
               Resume.adversarial_result(Accrue.TestRepo, fresh_account, resume, adapter)
             )
    end)
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

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
