defmodule Accrue.Entitlements.ReferenceScenarioDeviceKeysTest do
  use Accrue.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Device, ReferenceScenarios}
  alias Accrue.Entitlements.Offline.Challenge
  alias Accrue.Entitlements.ReferenceScenarioExecutor.DeviceKeys
  alias Accrue.Events.Event

  test "device replacement uses the public API and fresh persisted facts" do
    account = account!("device-replace")
    [action] = ReferenceScenarios.fetch!("device_replacement").actions

    observed = DeviceKeys.execute(Accrue.TestRepo, account, action)

    assert observed.result == %{
             tag: "replaced",
             disposition: "replaced",
             prior_state: "superseded",
             replacement_state: "active"
           }

    assert observed.durable.challenge_consumed
    assert observed.durable.audit_delta == 1
    assert observed.durable.snapshot_revision == 1
    assert observed.cache == %{prior: "server_reject_on_next_contact", replacement: "reconnect_required"}
    refute contains_secret?(observed)

    assert %{result: %{disposition: "already_completed"}} =
             DeviceKeys.replay(Accrue.TestRepo, account, observed.runtime)

    assert {:error, :idempotency_conflict} =
             DeviceKeys.divergent_replay(Accrue.TestRepo, account, observed.runtime)

    assert 2 == Accrue.TestRepo.aggregate(from(device in Device, where: device.account_id == ^account.id), :count, :id)
    assert 1 == Accrue.TestRepo.aggregate(from(challenge in Challenge, where: challenge.account_id == ^account.id), :count, :id)
    assert 1 == Accrue.TestRepo.aggregate(from(event in Event, where: event.subject_id == ^account.id), :count, :id)
  end

  defp account!(suffix), do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", suffix) |> elem(1)

  defp contains_secret?(value) when is_map(value),
    do:
      Enum.any?(value, fn {key, item} ->
        to_string(key) in ~w(private_jwk private_key nonce signature compact proof idempotency_key) or
          contains_secret?(item)
      end)

  defp contains_secret?(value) when is_list(value), do: Enum.any?(value, &contains_secret?/1)
  defp contains_secret?(_), do: false
end
