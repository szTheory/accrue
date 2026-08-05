defmodule Accrue.Entitlements.ReferenceScenarioExecutor do
  @moduledoc false

  alias Accrue.Entitlements.ReferenceScenarioExecutor.DeviceKeys
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Lifecycle
  alias Accrue.Entitlements.ReferenceScenarioExecutor.OfflinePolicy
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Ordering
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Read
  alias Accrue.Entitlements.ReferenceScenarioExecutor.ReconnectCache
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Resume

  @family_by_kind %{
    "apple_verified_purchase" => Lifecycle,
    "stripe_verified_purchase" => Lifecycle,
    "grant_observation" => Lifecycle,
    "refund_observation" => Lifecycle,
    "stripe_retraction" => Lifecycle,
    "web_login" => Read,
    "ios_login" => Read,
    "purchase_preflight" => Read,
    "expiry_boundary" => Read,
    "offline_proof_stale" => OfflinePolicy,
    "offline_expansion_request" => OfflinePolicy,
    "signed_deny" => OfflinePolicy,
    "rollback_proof" => OfflinePolicy,
    "empty_evidence" => OfflinePolicy,
    "reconnect_request" => :reconnect,
    "verified_cache_replace" => :reconnect,
    "device_replace" => DeviceKeys,
    "rotated_key_proof" => DeviceKeys,
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
    do: remember_runtime(account, DeviceKeys.execute(repo, account, action))

  def execute_action(repo, account, %{kind: "rotated_key_proof"} = action),
    do: DeviceKeys.execute(repo, account, action)

  def execute_action(repo, account, %{kind: kind} = action)
      when kind in ["reconnect_request", "verified_cache_replace"] do
    runtime = runtime_for(account)
    remember_runtime(account, ReconnectCache.execute(repo, account, action, runtime))
  end

  def execute_action(repo, account, %{kind: kind} = action)
      when kind in ["durable_interruption", "resume_delivery"] do
    runtime = runtime_for(account)
    remember_runtime(account, Resume.execute(repo, account, action, runtime))
  end

  def execute_action(repo, account, %{kind: "equal_order_delivery"} = action) do
    Ordering.equal_orders(repo, account, action,
      account_owner: fn owner_id ->
        Accrue.Entitlements.Account.fetch_or_create(repo, "reference_scenario", owner_id)
        |> elem(1)
      end
    )
  end

  def execute_action(repo, account, %{kind: "repeat_delivery"} = action),
    do: Ordering.repeat(repo, account, action)

  def execute_action(repo, account, %{kind: "parallel_delivery"} = action),
    do: Ordering.parallel(repo, account.owner_id, action)

  def execute_action(_repo, _account, %{kind: kind}) do
    family_for!(kind)
    raise ArgumentError, "#{kind} requires its named family executor"
  end

  # Collectors intentionally return their own bounded facts. This check verifies
  # that a real collector produced the declared family outcome without projecting
  # fixture expectations back into the observation.
  def assert_transition(%{kind: kind, expected_transition: expected}, observed)
      when is_map(observed) do
    case family_for!(kind) do
      Lifecycle -> lifecycle_match?(kind, expected, observed)
      Read -> read_match?(kind, expected, observed)
      OfflinePolicy -> OfflinePolicy.matches_expected?(%{kind: kind}, observed)
      DeviceKeys -> DeviceKeys.matches_expected?(%{kind: kind}, observed)
      :reconnect -> reconnect_match?(kind, observed)
      :resume -> resume_match?(kind, observed)
      :ordering -> ordering_match?(kind, observed)
    end ||
      raise ExUnit.AssertionError, message: "family transition mismatch for #{kind}"

    :ok
  end

  defp remember_runtime(account, {observed, runtime}) when is_map(observed) and is_map(runtime) do
    Process.put({__MODULE__, account.id}, runtime)
    observed
  end

  defp runtime_for(account), do: Process.get({__MODULE__, account.id}, %{})

  defp lifecycle_match?(kind, _expected, observed) do
    observed.result.disposition == kind and
      observed.durable.observation_kind ==
        if(kind in ["refund_observation", "stripe_retraction"], do: "retract", else: "grant")
  end

  defp read_match?(kind, expected, observed) do
    observed.result.disposition == kind and
      (kind == "expiry_boundary" or
         (Map.get(observed.snapshot || %{}, :revision) ||
            Map.get(observed.durable || %{}, :snapshot_revision)) ==
           expected.durable.snapshot_revision)
  end

  defp reconnect_match?("reconnect_request", observed),
    do: ReconnectCache.matches_expected?(%{kind: "reconnect_request"}, observed)

  defp reconnect_match?("verified_cache_replace", observed),
    do: ReconnectCache.matches_expected?(%{kind: "verified_cache_replace"}, observed)

  defp resume_match?(kind, observed), do: Resume.matches_expected?(%{kind: kind}, observed)

  defp ordering_match?("equal_order_delivery", observed),
    do: Ordering.matches_expected?(%{kind: "equal_order_delivery"}, observed)

  defp ordering_match?("repeat_delivery", observed),
    do: Ordering.matches_expected?(%{kind: "repeat_delivery"}, observed)

  defp ordering_match?("parallel_delivery", observed),
    do: Map.get(observed, :execution) == :barrier
end
