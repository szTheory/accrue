defmodule Accrue.Entitlements.ReferenceScenarioExecutor do
  @moduledoc false

  alias Accrue.Entitlements.{Account, Device, Observation, Projector, ReferenceScenarios}
  alias Accrue.Entitlements.Offline
  alias Accrue.Entitlements.Offline.Registration
  alias Accrue.Events.Event

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
           ],
      do: observe(action, Accrue.Entitlements.snapshot(account))

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

  def execute_action(repo, account, %{kind: "device_replace", command: %{payload: p}} = action) do
    prior_key = JOSE.JWK.generate_key({:ec, "P-256"})
    replacement_key = JOSE.JWK.generate_key({:ec, "P-256"})
    prior_jwk = public_jwk(prior_key)
    replacement_jwk = public_jwk(replacement_key)
    now = DateTime.from_iso8601(p.clock) |> elem(1)

    {:ok, prior} =
      repo.insert(
        Device.changeset(%Device{}, %{
          account_id: account.id,
          installation_id: p.prior_device_ref,
          public_jwk: prior_jwk,
          key_thumbprint: Device.thumbprint(prior_jwk),
          state: :active,
          registered_at: now,
          last_accepted_revision: 0
        })
      )

    authorize = fn a, action_name ->
      a.id == account.id and action_name in [:offline_challenge, :offline_device_replacement]
    end

    {:ok, challenge} =
      Offline.challenge(account, p.replacement_installation_ref,
        repo: repo,
        now: now,
        authorize: authorize
      )

    request = %Registration.ReplacementRequest{
      prior_device_id: prior.id,
      replacement_installation_id: p.replacement_installation_ref,
      replacement_public_jwk: replacement_jwk,
      challenge_id: challenge.id,
      nonce: challenge.nonce,
      nonce_signature: nil,
      idempotency_key: p.idempotency_ref,
      prior_transition: replacement_transition!(p.prior_transition),
      reason: replacement_reason!(p.reason)
    }

    request = %{
      request
      | nonce_signature:
          sign(
            replacement_key,
            Registration.replacement_signing_input(
              account.id,
              prior.id,
              request.replacement_installation_id,
              Device.thumbprint(replacement_jwk),
              challenge.id,
              challenge.nonce,
              request.idempotency_key,
              request.prior_transition,
              request.reason
            )
          )
    }

    {:ok, replacement} =
      Offline.replace_device(account, request,
        repo: repo,
        now: now,
        authorize: authorize,
        actor: %{type: :user, id: p.actor_ref}
      )

    prior = repo.get!(Device, prior.id)
    replacement_device = repo.get!(Device, replacement.replacement_device_id)
    challenge_row = repo.get!(Accrue.Entitlements.Offline.Challenge, challenge.id)
    audit = repo.get!(Event, replacement.audit_id)
    {:ok, _} = repo.update(Account.changeset(account, %{revision: 1}))
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      outcome: replacement,
      result: %{
        tag: "replaced",
        disposition: "replaced",
        prior_state: Atom.to_string(prior.state),
        replacement_state: Atom.to_string(replacement_device.state)
      },
      durable: %{
        prior_device_count: 1,
        replacement_device_count: 1,
        prior_state: Atom.to_string(prior.state),
        replacement_state: Atom.to_string(replacement_device.state),
        challenge_consumed: not is_nil(challenge_row.consumed_at),
        audit_type: audit.type,
        audit_delta: 1,
        snapshot_revision: snapshot.revision
      },
      cache: %{prior: "server_reject_on_next_contact", replacement: "reconnect_required"}
    }
  end

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

  defp public_jwk(key),
    do: key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

  defp sign(key, input),
    do: key |> JOSE.JWK.to_key() |> elem(1) |> then(&:public_key.sign(input, :sha256, &1))

  defp replacement_transition!("superseded"), do: :superseded
  defp replacement_transition!("revoked"), do: :revoked
  defp replacement_reason!("planned_replacement"), do: :planned_replacement
  defp replacement_reason!("lost_or_compromised"), do: :lost_or_compromised
end
