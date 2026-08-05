defmodule Accrue.Entitlements.ReferenceScenarioDeviceKeysTest do
  use Accrue.RepoCase, async: false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Device, ReferenceScenarioExecutor, ReferenceScenarios}
  alias Accrue.Entitlements.Offline.{Challenge, Issuance}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.DeviceKeys
  alias Accrue.Events.Event

  test "device replacement uses the public API and fresh persisted facts" do
    account = account!("device-replace")
    [action] = ReferenceScenarios.fetch!("device_replacement").actions

    {observed, runtime} = DeviceKeys.execute(Accrue.TestRepo, account, action)

    assert observed.result == %{
             tag: "replaced",
             disposition: "replaced",
             prior_state: "superseded",
             replacement_state: "active"
           }

    assert observed.durable.challenge_consumed
    assert observed.durable.audit_delta == 1
    assert observed.durable.snapshot_revision == 1

    assert observed.cache == %{
             prior: "server_reject_on_next_contact",
             replacement: "reconnect_required"
           }

    refute contains_secret?(observed)

    assert %{result: %{disposition: "already_completed"}} =
             DeviceKeys.replay(Accrue.TestRepo, account, runtime)

    assert {:error, divergent_reason} =
             DeviceKeys.divergent_replay(Accrue.TestRepo, account, runtime)

    assert divergent_reason in [:idempotency_conflict, :challenge_consumed]

    assert 2 ==
             Accrue.TestRepo.aggregate(
               from(device in Device, where: device.account_id == ^account.id),
               :count,
               :id
             )

    assert 1 ==
             Accrue.TestRepo.aggregate(
               from(challenge in Challenge, where: challenge.account_id == ^account.id),
               :count,
               :id
             )

    assert 1 ==
             Accrue.TestRepo.aggregate(
               from(event in Event, where: event.subject_id == ^account.id),
               :count,
               :id
             )
  end

  test "issued retention keeps the old public kid until its finite horizon then retires it" do
    account = account!("key-retention")
    [action] = ReferenceScenarios.fetch!("key_rotation").actions

    observed = DeviceKeys.execute(Accrue.TestRepo, account, action)

    assert observed.result == %{tag: "executed", disposition: "rotated_key_proof"}
    assert observed.durable.retirement_requirement == "required"
    assert observed.cache.public_kids == ["reference-next-key", "reference-old-key"]
    assert observed.after_retention.cache.public_kids == ["reference-next-key"]

    assert 1 ==
             Accrue.TestRepo.aggregate(
               from(issuance in Issuance, where: issuance.account_id == ^account.id),
               :count,
               :id
             )

    refute contains_secret?(observed)
  end

  test "every device replacement declaration leaf is load-bearing" do
    account = account!("device-replace-mutation")
    [action] = ReferenceScenarios.fetch!("device_replacement").actions
    {observed, _runtime} = DeviceKeys.execute(Accrue.TestRepo, account, action)

    for {section, leaf} <- [
          {:result, :prior_state},
          {:durable, :challenge_consumed},
          {:cache, :replacement}
        ] do
      mutated = mutate_expected(action, section, leaf)

      assert_raise ExUnit.AssertionError, ~r/family transition mismatch/, fn ->
        ReferenceScenarioExecutor.assert_transition(mutated, observed)
      end
    end
  end

  test "real generic, no-effect, registration, and snapshot substitutes fail device/key matching" do
    device_action = ReferenceScenarios.fetch!("device_replacement").actions |> hd()
    key_action = ReferenceScenarios.fetch!("key_rotation").actions |> hd()

    Enum.each([:generic_grant, :no_effect, :registration_only, :snapshot_only], fn adapter ->
      account = account!("adversarial-device-#{adapter}")

      refute DeviceKeys.matches_expected?(
               device_action,
               DeviceKeys.adversarial_result(Accrue.TestRepo, account, device_action,
                 adapter: adapter
               )
             )

      refute DeviceKeys.matches_expected?(
               key_action,
               DeviceKeys.adversarial_result(Accrue.TestRepo, account, key_action,
                 adapter: adapter
               )
             )
    end)
  end

  defp account!(suffix),
    do: Account.fetch_or_create(Accrue.TestRepo, "reference_scenario", suffix) |> elem(1)

  defp mutate_expected(action, section, leaf) do
    expected = action.expected_transition
    value = Map.fetch!(Map.fetch!(expected, section), leaf)

    replacement =
      cond do
        is_boolean(value) -> not value
        is_integer(value) -> value + 1
        true -> "not-#{value}"
      end

    %{
      action
      | expected_transition: Map.update!(expected, section, &Map.put(&1, leaf, replacement))
    }
  end

  defp contains_secret?(%_{}), do: false

  defp contains_secret?(value) when is_map(value),
    do:
      Enum.any?(value, fn {key, item} ->
        to_string(key) in ~w(private_jwk private_key nonce signature compact proof idempotency_key) or
          contains_secret?(item)
      end)

  defp contains_secret?(value) when is_list(value), do: Enum.any?(value, &contains_secret?/1)
  defp contains_secret?(_), do: false
end
