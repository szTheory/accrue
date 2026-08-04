defmodule Accrue.Entitlements.ReferenceScenarioLifecycleTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor
  alias Accrue.Events.Event

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
      if previous, do: Application.put_env(:accrue, :entitlements, previous), else: Application.delete_env(:accrue, :entitlements)
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
    assert Accrue.TestRepo.aggregate(from(event in Event, where: event.subject_id == ^account.id), :count, :id) == 2
  end

  defp account!(owner_id), do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)
end
