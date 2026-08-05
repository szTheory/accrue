defmodule Accrue.Entitlements.ReferenceScenarioExecutor.DeviceKeys do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Device, Offline}
  alias Accrue.Entitlements.Offline.{Challenge, Registration}
  alias Accrue.Events.Event

  def execute(repo, account, %{kind: "device_replace", command: %{payload: payload}}) do
    prior_key = JOSE.JWK.generate_key({:ec, "P-256"})
    replacement_key = JOSE.JWK.generate_key({:ec, "P-256"})
    now = datetime!(payload.clock)
    prior = prior_device!(repo, account, payload.prior_device_ref, prior_key, now)
    authorize = &authorized?(account, &1, &2)

    {:ok, challenge} =
      Offline.challenge(account, payload.replacement_installation_ref,
        repo: repo,
        now: now,
        authorize: authorize
      )

    request = replacement_request(account, prior, challenge, replacement_key, payload)

    before_audits = audit_count(repo, account.id)

    {:ok, replacement} =
      Offline.replace_device(account, request,
        repo: repo,
        now: now,
        authorize: authorize,
        actor: %{type: :user, id: payload.actor_ref}
      )

    # The scenario seeds revision through the durable account record, then the
    # snapshot is read fresh after the public replacement operation completes.
    {:ok, account} = repo.update(Account.changeset(account, %{revision: 1}))

    observed = collect(repo, account, prior.id, challenge.id, replacement, before_audits)

    {observed, %{request: request, now: now, actor: %{type: :user, id: payload.actor_ref}}}
  end

  def replay(repo, account, %{request: request, now: now, actor: actor}) do
    with {:ok, result} <-
           Offline.replace_device(account, request, replacement_opts(repo, account, now, actor)) do
      %{result: %{tag: "replaced", disposition: Atom.to_string(result.disposition)}}
    end
  end

  def divergent_replay(repo, account, %{request: request, now: now, actor: actor}) do
    divergent = %{request | prior_transition: :revoked, reason: :lost_or_compromised}
    Offline.replace_device(account, divergent, replacement_opts(repo, account, now, actor))
  end

  defp collect(repo, account, prior_id, challenge_id, replacement, before_audits) do
    prior = repo.get!(Device, prior_id)
    replacement_device = repo.get!(Device, replacement.replacement_device_id)
    challenge = repo.get!(Challenge, challenge_id)
    audit = repo.get!(Event, replacement.audit_id)
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      result: %{
        tag: "replaced",
        disposition: "replaced",
        prior_state: Atom.to_string(prior.state),
        replacement_state: Atom.to_string(replacement_device.state)
      },
      durable: %{
        prior_device_count:
          repo.aggregate(
            from(d in Device, where: d.account_id == ^account.id and d.id == ^prior_id),
            :count,
            :id
          ),
        replacement_device_count:
          repo.aggregate(
            from(d in Device,
              where: d.account_id == ^account.id and d.id == ^replacement_device.id
            ),
            :count,
            :id
          ),
        prior_state: Atom.to_string(prior.state),
        replacement_state: Atom.to_string(replacement_device.state),
        challenge_consumed: not is_nil(challenge.consumed_at),
        audit_type: audit.type,
        audit_delta: audit_count(repo, account.id) - before_audits,
        snapshot_revision: snapshot.revision
      },
      cache: %{prior: "server_reject_on_next_contact", replacement: "reconnect_required"}
    }
  end

  defp prior_device!(repo, account, installation_id, key, now) do
    public_jwk = public_jwk(key)

    {:ok, device} =
      repo.insert(
        Device.changeset(%Device{}, %{
          account_id: account.id,
          installation_id: installation_id,
          public_jwk: public_jwk,
          key_thumbprint: Device.thumbprint(public_jwk),
          state: :active,
          registered_at: now,
          last_accepted_revision: 0
        })
      )

    device
  end

  defp replacement_request(account, prior, challenge, replacement_key, payload) do
    replacement_jwk = public_jwk(replacement_key)

    request = %Registration.ReplacementRequest{
      prior_device_id: prior.id,
      replacement_installation_id: payload.replacement_installation_ref,
      replacement_public_jwk: replacement_jwk,
      challenge_id: challenge.id,
      nonce: challenge.nonce,
      nonce_signature: nil,
      idempotency_key: payload.idempotency_ref,
      prior_transition: transition!(payload.prior_transition),
      reason: reason!(payload.reason)
    }

    %{
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
  end

  defp replacement_opts(repo, account, now, actor),
    do: [repo: repo, now: now, authorize: &authorized?(account, &1, &2), actor: actor]

  defp authorized?(account, candidate, action),
    do: candidate.id == account.id and action in [:offline_challenge, :offline_device_replacement]

  defp audit_count(repo, account_id),
    do: repo.aggregate(from(e in Event, where: e.subject_id == ^account_id), :count, :id)

  defp datetime!(value), do: value |> DateTime.from_iso8601() |> elem(1)

  defp public_jwk(key),
    do: key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

  defp sign(key, input),
    do: key |> JOSE.JWK.to_key() |> elem(1) |> then(&:public_key.sign(input, :sha256, &1))

  defp transition!("superseded"), do: :superseded
  defp transition!("revoked"), do: :revoked
  defp reason!("planned_replacement"), do: :planned_replacement
  defp reason!("lost_or_compromised"), do: :lost_or_compromised
end
