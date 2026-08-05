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

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)

  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
