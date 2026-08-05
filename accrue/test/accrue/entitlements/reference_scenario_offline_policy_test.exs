defmodule Accrue.Entitlements.ReferenceScenarioOfflinePolicyTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, ReferenceScenarios}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.OfflinePolicy

  test "stale proof executes the signed vector and keeps downloaded study available" do
    action = ReferenceScenarios.fetch!("stale_downloaded_study_continuity") |> hd_action()
    account = account!("reference-scenario-offline-stale")

    assert %{result: %{state: "stale_offline", reason: "revalidation_due", next_action: "reconnect_required", revision: 5}, policy: %{action: :read_downloaded_lesson, allowed: true, reason: "allow_downloaded_study"}, durable: %{write_delta: 0}, cache: %{disposition: "preserve"}} =
             OfflinePolicy.execute(Accrue.TestRepo, account, action)
  end

  test "restricted expansion applies policy to the verified stale decision without expanding value" do
    action = ReferenceScenarios.fetch!("restricted_expansion") |> hd_action()
    account = account!("reference-scenario-offline-expansion")

    assert %{result: %{state: "stale_offline", reason: "revalidation_due"}, policy: %{action: :download_premium, allowed: false, reason: "reconnect_required"}, durable: %{write_delta: 0}, cache: %{disposition: "preserve"}} =
             OfflinePolicy.execute(Accrue.TestRepo, account, action)
  end

  defp hd_action(scenario), do: hd(scenario.actions)

  defp account!(owner_id),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", owner_id) |> elem(1)
end
