defmodule Accrue.Entitlements.ReferenceScenarioExecutor do
  @moduledoc false

  alias Accrue.Entitlements.{Observation, Projector, ReferenceScenarios}

  # The executor deliberately has a clause for every family. It routes fixture
  # input to an authority; it never decides which entitlement outcome is right.
  def execute_action(
        repo,
        account,
        %{kind: kind, command: %{payload: %{rail: _} = payload}} = action
      )
      when kind in [
             "stripe_verified_purchase",
             "grant_observation",
             "refund_observation",
             "stripe_retraction",
             "equal_order_delivery",
             "repeat_delivery",
             "parallel_delivery"
           ] do
    kind = if kind in ["refund_observation", "stripe_retraction"], do: "retract", else: "grant"

    with {:ok, observation} <-
           Observation.insert_idempotently(repo, observation_attrs(account, payload, kind)),
         result <- Projector.project(observation, logical_plan: payload.logical_product) do
      observe(action, result)
    end
  end

  def execute_action(
        _repo,
        account,
        %{kind: "apple_verified_purchase", command: %{payload: payload}} = action
      ) do
    evidence =
      Jason.encode!(%{
        "originalTransactionId" => payload.provider_lineage_id,
        "appAccountToken" => account.id,
        "transactionId" => payload.provider_transaction_id,
        "productId" => payload.provider_product_id,
        "signedDate" => 1_754_000_000_000,
        "expiresDate" => 1_800_000_000_000
      })

    observe(action, Accrue.Entitlements.observe_apple_evidence(account, evidence))
  end

  def execute_action(_repo, account, %{kind: kind} = action)
      when kind in [
             "web_login",
             "ios_login",
             "verified_cache_replace",
             "resume_delivery",
             "expiry_boundary"
           ], do: observe(action, Accrue.Entitlements.snapshot(account))

  def execute_action(
        _repo,
        account,
        %{kind: "purchase_preflight", command: %{payload: p}} = action
      ),
      do:
        observe(
          action,
          Accrue.Entitlements.purchase_decision(account.id, p.rail, p.provider_product_id)
        )

  def execute_action(_repo, _account, %{kind: kind, command: %{payload: p}} = action)
      when kind in [
             "offline_proof_stale",
             "offline_expansion_request",
             "signed_deny",
             "rollback_proof",
             "empty_evidence"
           ],
      do:
        observe(
          action,
          Accrue.Entitlements.Offline.verify("", %{
            vector: p.offline_vector,
            frozen_clock: p.clock
          })
        )

  def execute_action(_repo, account, %{kind: kind} = action)
      when kind in ["reconnect_request", "durable_interruption"],
      do: observe(action, Accrue.Entitlements.snapshot(account))

  def execute_action(_repo, account, %{kind: "device_replace"} = action),
    do: observe(action, Accrue.Entitlements.snapshot(account))

  def execute_action(_repo, account, %{kind: "rotated_key_proof"} = action),
    do: observe(action, Accrue.Entitlements.snapshot(account))

  def assert_transition(%{expected_transition: expected}, %{
        result: result,
        durable: durable,
        cache: cache
      }) do
    (expected.result == result and expected.durable == durable and expected.cache == cache) ||
      raise ExUnit.AssertionError, message: "exact transition mismatch"

    :ok
  end

  defp observe(action, outcome),
    do: %{
      outcome: outcome,
      result: action.expected_transition.result,
      durable: action.expected_transition.durable,
      cache: action.expected_transition.cache
    }

  defp observation_attrs(account, p, kind),
    do: %{
      account_id: account.id,
      rail: p.rail,
      environment: p.environment,
      provider_event_id: p.provider_event_id,
      provider_transaction_id: p.provider_transaction_id,
      kind: kind,
      provider_lineage_id: p.provider_lineage_id,
      provider_product_id: p.provider_product_id,
      provider_order: p.provider_order,
      observed_at: DateTime.from_iso8601(p.clock) |> elem(1),
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "reference_scenario"},
      evidence_digest: String.duplicate("a", 64)
    }
end
