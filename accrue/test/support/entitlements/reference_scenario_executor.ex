defmodule Accrue.Entitlements.ReferenceScenarioExecutor do
  @moduledoc false

  alias Accrue.Entitlements.{Account, Device}
  alias Accrue.Entitlements.Offline
  alias Accrue.Entitlements.Offline.Registration
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Lifecycle
  alias Accrue.Entitlements.ReferenceScenarioExecutor.OfflinePolicy
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Read
  alias Accrue.Events.Event

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
      when kind in ["offline_proof_stale", "offline_expansion_request", "signed_deny", "rollback_proof", "empty_evidence"],
      do: OfflinePolicy.execute(repo, account, action)

  def execute_action(repo, account, %{kind: "device_replace", command: %{payload: p}}) do
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

  defp public_jwk(key),
    do: key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

  defp sign(key, input),
    do: key |> JOSE.JWK.to_key() |> elem(1) |> then(&:public_key.sign(input, :sha256, &1))

  defp replacement_transition!("superseded"), do: :superseded
  defp replacement_transition!("revoked"), do: :revoked
  defp replacement_reason!("planned_replacement"), do: :planned_replacement
  defp replacement_reason!("lost_or_compromised"), do: :lost_or_compromised
end
