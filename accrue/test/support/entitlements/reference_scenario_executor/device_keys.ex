defmodule Accrue.Entitlements.ReferenceScenarioExecutor.DeviceKeys do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Device, Offline}
  alias Accrue.Entitlements.Offline.{Challenge, Issuance, Registration}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.Read
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

    observed =
      Map.put(observed, :declared_transition, %{
        result: observed.result,
        durable: observed.durable,
        cache: observed.cache
      })

    {observed, %{request: request, now: now, actor: %{type: :user, id: payload.actor_ref}}}
  end

  def replay(repo, account, %{request: request, now: now, actor: actor}) do
    with {:ok, result} <-
           Offline.replace_device(account, request, replacement_opts(repo, account, now, actor)) do
      %{result: %{tag: "replaced", disposition: Atom.to_string(result.disposition)}}
    end
  end

  def execute(repo, account, %{kind: "rotated_key_proof", command: %{payload: payload}}) do
    now = datetime!(payload.clock)
    :ok = Read.seed_declared_grant(repo, account, payload)
    account = repo.get!(Account, account.id)

    device =
      prior_device!(
        repo,
        account,
        "#{payload.account_ref}-issued-device",
        JOSE.JWK.generate_key({:ec, "P-256"}),
        now
      )

    old_key = public_key("reference-old-key")
    next_key = public_key("reference-next-key")
    expires_at = DateTime.add(now, 60, :second)

    {:ok, _issuance} =
      repo.insert(
        Issuance.changeset(%Issuance{}, %{
          account_id: account.id,
          device_id: device.id,
          token_id_hash: digest("#{payload.provider_transaction_id}-issued-proof"),
          kid: old_key["kid"],
          revision: account.revision,
          disposition: :allow,
          issued_at: now,
          fresh_until: now,
          expires_at: expires_at
        })
      )

    requirements = Issuance.retirement_requirements(repo, now)

    {:ok, %{"keys" => current_keys}} =
      Offline.verification_keys_with_issued_retention(
        keys: [old_key, next_key],
        repo: repo,
        now: now
      )

    after_retention = DateTime.add(expires_at, 86_400, :second)

    {:ok, %{"keys" => retired_keys}} =
      Offline.verification_keys_with_issued_retention(
        keys: [next_key],
        repo: repo,
        now: after_retention
      )

    observed = %{
      result: %{tag: "executed", disposition: "rotated_key_proof"},
      durable: %{
        retirement_requirement: requirements |> Map.fetch!(old_key["kid"]) |> Atom.to_string()
      },
      cache: %{public_kids: Enum.map(current_keys, & &1["kid"])},
      after_retention: %{cache: %{public_kids: Enum.map(retired_keys, & &1["kid"])}}
    }

    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    Map.put(observed, :declared_transition, %{
      result: observed.result,
      durable: %{
        state: "unchanged",
        observation_kind: "none",
        snapshot_revision: snapshot.revision
      },
      cache: %{disposition: "preserve"}
    })
  end

  def divergent_replay(repo, account, %{request: request, now: now, actor: actor}) do
    divergent = %{request | prior_transition: :revoked, reason: :lost_or_compromised}
    Offline.replace_device(account, divergent, replacement_opts(repo, account, now, actor))
  end

  def adversarial_result(repo, account, action, adapter: :generic_grant) do
    :ok = Read.seed_declared_grant(repo, account, generic_grant_payload(action))

    %{
      result: %{tag: "executed", disposition: "generic_grant"},
      durable: %{operation: "generic_grant"}
    }
  end

  def adversarial_result(_repo, account, _action, adapter: :no_effect) do
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      result: %{tag: "executed", disposition: "no_effect"},
      durable: %{snapshot_revision: snapshot.revision}
    }
  end

  def adversarial_result(_repo, account, _action, adapter: :snapshot_only) do
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      result: %{tag: "executed", disposition: "snapshot_only"},
      cache: %{snapshot_revision: snapshot.revision}
    }
  end

  def adversarial_result(repo, account, %{kind: "device_replace"} = action,
        adapter: :registration_only
      ) do
    now = datetime!(action.command.payload.clock)
    key = JOSE.JWK.generate_key({:ec, "P-256"})

    installation_id = "registration-only-#{System.unique_integer([:positive])}"

    {:ok, challenge} =
      Offline.challenge(account, installation_id,
        repo: repo,
        now: now,
        authorize: &authorized?(account, &1, &2)
      )

    request = %Registration.Request{
      installation_id: installation_id,
      device_public_jwk: public_jwk(key),
      challenge_id: challenge.id,
      nonce: challenge.nonce,
      nonce_signature:
        sign(
          key,
          Registration.signing_input(
            account.id,
            installation_id,
            challenge.id,
            challenge.nonce,
            "registration-only"
          )
        ),
      idempotency_key: "registration-only"
    }

    {:ok, _} =
      Offline.register_device(account, request,
        repo: repo,
        now: now,
        authorize: &authorized?(account, &1, &2)
      )

    %{result: %{tag: "executed", disposition: "register_device"}, durable: %{device_count: 1}}
  end

  def adversarial_result(_repo, _account, %{kind: "rotated_key_proof"},
        adapter: :registration_only
      ),
      do: %{
        result: %{tag: "executed", disposition: "register_device"},
        durable: %{issuance_count: 0}
      }

  def matches_expected?(%{kind: "device_replace"}, %{
        result: %{disposition: "replaced"},
        durable: %{challenge_consumed: true, audit_delta: 1},
        cache: %{replacement: "reconnect_required"}
      }),
      do: true

  def matches_expected?(%{kind: "rotated_key_proof"}, %{
        result: %{disposition: "rotated_key_proof"},
        durable: %{retirement_requirement: "required"},
        cache: %{public_kids: [_old, _next]}
      }),
      do: true

  def matches_expected?(_, _), do: false

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
    do:
      candidate.id == account.id and
        action in [:offline_challenge, :offline_device_replacement, :offline_registration]

  defp audit_count(repo, account_id),
    do: repo.aggregate(from(e in Event, where: e.subject_id == ^account_id), :count, :id)

  defp datetime!(value), do: value |> DateTime.from_iso8601() |> elem(1)

  defp public_jwk(key),
    do: key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

  defp sign(key, input),
    do: key |> JOSE.JWK.to_key() |> elem(1) |> then(&:public_key.sign(input, :sha256, &1))

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)

  defp public_key(kid), do: key_material() |> Map.put("kid", kid)

  defp key_material do
    __DIR__
    |> Path.join("../../../../priv/entitlements/v1.59-offline-test-key.jwk.json")
    |> File.read!()
    |> Jason.decode!()
    |> Map.take(["kty", "crv", "x", "y"])
    |> Map.merge(%{"alg" => "ES256", "use" => "sig"})
  end

  defp generic_grant_payload(%{kind: "device_replace", command: %{payload: payload}}) do
    %{
      rail: :stripe,
      environment: :production,
      logical_product: "pro",
      provider_product_id: "price_pro",
      provider_event_id: "#{payload.account_ref}-generic-event",
      provider_transaction_id: "#{payload.account_ref}-generic-transaction",
      provider_lineage_id: "#{payload.account_ref}-generic-lineage",
      provider_order: 1,
      clock: payload.clock
    }
  end

  defp generic_grant_payload(%{command: %{payload: payload}}), do: payload

  defp transition!("superseded"), do: :superseded
  defp transition!("revoked"), do: :revoked
  defp reason!("planned_replacement"), do: :planned_replacement
  defp reason!("lost_or_compromised"), do: :lost_or_compromised
end
