defmodule Accrue.Entitlements.ReferenceScenarioExecutor do
  @moduledoc false

  alias Accrue.Entitlements.ReferenceScenarioExecutor.DeviceKeys
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Lifecycle
  alias Accrue.Entitlements.ReferenceScenarioExecutor.OfflinePolicy
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Read

  @family_by_kind %{
    "apple_verified_purchase" => Lifecycle,
    "stripe_verified_purchase" => Lifecycle,
    "grant_observation" => Lifecycle,
    "refund_observation" => Lifecycle,
    "stripe_retraction" => Lifecycle,
    "web_login" => :read,
    "ios_login" => :read,
    "purchase_preflight" => :read,
    "expiry_boundary" => :read,
    "offline_proof_stale" => :offline,
    "offline_expansion_request" => :offline,
    "signed_deny" => :offline,
    "rollback_proof" => :offline,
    "empty_evidence" => :offline,
    "reconnect_request" => :reconnect,
    "verified_cache_replace" => :reconnect,
    "device_replace" => :device,
    "rotated_key_proof" => :device,
    "equal_order_delivery" => :ordering,
    "repeat_delivery" => :ordering,
    "parallel_delivery" => :ordering,
    "durable_interruption" => :resume,
    "resume_delivery" => :resume
  }

  def family_for!(kind), do: Map.fetch!(@family_by_kind, kind)

  # Fixture commands only select the family. Observations are collected by the
  # family after the production operation; expected_transition is assertion data.
  def execute_action(
        repo,
        account,
        %{kind: kind} = action
      )
      when kind in [
             "apple_verified_purchase",
             "stripe_verified_purchase",
             "grant_observation",
             "refund_observation",
             "stripe_retraction"
           ],
      do: Lifecycle.execute(repo, account, action)

  def execute_action(repo, account, %{kind: kind} = action)
      when kind in ["web_login", "ios_login", "purchase_preflight", "expiry_boundary"],
      do: Read.execute(repo, account, action)

  def execute_action(repo, account, %{kind: kind} = action)
      when kind in [
             "offline_proof_stale",
             "offline_expansion_request",
             "signed_deny",
             "rollback_proof",
             "empty_evidence"
           ],
      do: OfflinePolicy.execute(repo, account, action)

  def execute_action(repo, account, %{kind: "device_replace"} = action),
    do: DeviceKeys.execute(repo, account, action) |> elem(0)

  def execute_action(_repo, _account, %{kind: kind}) do
    family_for!(kind)
    raise ArgumentError, "#{kind} requires its named family executor"
  end

  def assert_transition(%{expected_transition: expected}, %{
        result: result,
        durable: durable,
        cache: cache
      }) do
    (expected.result == result and expected.durable == durable and expected.cache == cache) ||
      raise ExUnit.AssertionError, message: "exact transition mismatch"

    :ok
  end
end
