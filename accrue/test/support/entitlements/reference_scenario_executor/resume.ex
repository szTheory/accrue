defmodule Accrue.Entitlements.ReferenceScenarioExecutor.Resume do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Device, Offline}
  alias Accrue.Entitlements.Offline.{Challenge, Issuance, Reconnect, ReconnectAttempt}
  alias Accrue.Entitlements.ReferenceScenarioExecutor.{Read, ReconnectCache}

  def execute(repo, account, action, runtime \\ [])

  def execute(
        repo,
        account,
        %{kind: "durable_interruption", command: %{payload: payload}} = action,
        _runtime
      ) do
    :ok = Read.seed_declared_grant(repo, account, payload)
    now = datetime!(payload.clock)
    {device, device_key} = device!(repo, account, "#{payload.account_ref}-device", now)
    reconnect_opts = reconnect_opts(repo, now)

    {:ok, challenge} =
      Offline.reconnect_challenge(account, device.installation_id, reconnect_opts)

    request = reconnect_request(account, device, device_key, challenge, action.order)
    hook = String.to_existing_atom(payload.interruption_hook)

    assert_interruption!(
      Offline.reconnect(
        account,
        request,
        Keyword.put(reconnect_opts, hook, fn -> :interrupted end)
      ),
      hook
    )

    {collect(repo, account, device.id, challenge.id, "interrupted", "preserve"),
     %{
       request_ref: payload.request_ref,
       request: request,
       device_id: device.id,
       challenge_id: challenge.id,
       cache: %{revision: 0, disposition: :allow, proof: "prior"},
       reconnect_opts: reconnect_opts
     }}
  end

  def execute(
        repo,
        account,
        %{kind: "resume_delivery", command: %{payload: payload}},
        %{
          request_ref: request_ref,
          request: request,
          device_id: device_id,
          challenge_id: challenge_id
        } = runtime
      )
      when request_ref == payload.request_ref do
    {:ok, %{proof: proof}} = Offline.reconnect(account, request, runtime.reconnect_opts)
    cache = Map.fetch!(runtime, :cache)

    {replacement, next_cache} =
      verified_cache(proof, account, runtime.device_id, cache, payload.clock)

    observed = collect(repo, account, device_id, challenge_id, "resumed", replacement, proof)
    replay = Offline.reconnect(account, request, runtime.reconnect_opts)
    true = stable_replay?(replay, observed)

    {Map.put(observed, :replay, "stable"), %{runtime | cache: next_cache}}
  end

  def matches_expected?(%{kind: "durable_interruption"}, %{
        result: %{tag: "interrupted"},
        durable: %{attempt_state: "admitted", challenge_consumed: true, issuance_count: 0},
        cache: %{replacement: "preserve"}
      }),
      do: true

  def matches_expected?(%{kind: "resume_delivery"}, %{
        result: %{tag: "resumed"},
        durable: %{attempt_state: "completed", challenge_consumed: true, issuance_count: 1},
        cache: %{replacement: "replace"},
        replay: "stable"
      }),
      do: true

  def matches_expected?(_, _), do: false

  def adversarial_result(
        repo,
        account,
        %{kind: "durable_interruption", command: %{payload: payload}},
        :generic_grant
      ) do
    :ok = Read.seed_declared_grant(repo, account, payload)
    %{operation: "generic_grant", attempt_count: repo.aggregate(ReconnectAttempt, :count, :id)}
  end

  def adversarial_result(repo, _account, %{kind: "durable_interruption"}, :no_effect),
    do: %{operation: "no_effect", issuance_count: repo.aggregate(Issuance, :count, :id)}

  def adversarial_result(_repo, account, %{kind: "durable_interruption"}, :snapshot_only),
    do: %{operation: "snapshot_only", snapshot_revision: account.revision}

  def adversarial_result(_repo, _account, %{kind: "resume_delivery"}, adapter),
    do: %{operation: Atom.to_string(adapter), cache: "unverified"}

  defp collect(repo, account, device_id, challenge_id, disposition, replacement, proof \\ nil) do
    challenge = repo.get!(Challenge, challenge_id)
    attempt = repo.one!(from(item in ReconnectAttempt, where: item.challenge_id == ^challenge_id))
    device = repo.get!(Device, device_id)
    {:ok, snapshot} = Accrue.Entitlements.snapshot(account)

    %{
      result: %{
        tag: disposition,
        disposition: if(disposition == "interrupted", do: "admission_interrupted", else: "issued")
      },
      durable: %{
        attempt_id: attempt.id,
        attempt_state: Atom.to_string(attempt.state),
        attempt_token: if(is_binary(attempt.execution_token), do: "claimed", else: "none"),
        challenge_consumed: not is_nil(challenge.consumed_at),
        device_state: Atom.to_string(device.state),
        issuance_count:
          repo.aggregate(
            from(item in Issuance, where: item.account_id == ^account.id),
            :count,
            :id
          ),
        snapshot_revision: snapshot.revision
      },
      cache: %{
        prior: "allow",
        replacement: replacement,
        current: if(replacement == "replace", do: "allow", else: "allow")
      }
    }
    |> maybe_proof(proof)
  end

  defp maybe_proof(observed, nil), do: observed
  defp maybe_proof(observed, proof), do: Map.put(observed, :proof, proof)

  defp verified_cache(proof, account, device_id, cache, clock) do
    device = Accrue.TestRepo.get!(Device, device_id)
    now = datetime!(clock)

    context = %{
      issuer: "accrue.reference-scenario",
      audience: "accrue-offline-client",
      account_subject: account.id,
      installation_id: device.installation_id,
      device_thumbprint: device.key_thumbprint,
      now: DateTime.to_unix(now),
      clock_high_water: %{revision: cache.revision, iat: 0, fresh_until: 0},
      accepted_revision: cache.revision,
      accepted_disposition: cache.disposition,
      accepted_iat: 0,
      accepted_fresh_until: 0,
      public_keys: [public_key()]
    }

    {:ok, %{claims: %{revision: revision, disposition: disposition}}} =
      Offline.verify(proof, context)

    {"replace", %{revision: revision, disposition: disposition, proof: "verified"}}
  end

  defp stable_replay?({:ok, %{proof: proof}}, %{proof: proof}), do: true
  defp stable_replay?(_, _), do: false
  defp assert_interruption!({:error, :admission_interrupted}, :after_admission), do: :ok
  defp assert_interruption!({:error, :issuance_interrupted}, :after_issuance_commit), do: :ok

  defp reconnect_opts(repo, now) do
    Code.ensure_loaded!(ReconnectCache.NoDueSources)
    Code.ensure_loaded!(ReconnectCache.SigningProvider)

    [
      repo: repo,
      key_provider: ReconnectCache.SigningProvider,
      signing_key: signing_key(),
      public_key: public_key(),
      issuer: "accrue.reference-scenario",
      audience: "accrue-offline-client",
      now: now,
      source_coordinator: ReconnectCache.NoDueSources,
      authorize: &authorized?/2
    ]
  end

  defp reconnect_request(account, device, device_key, challenge, order) do
    idempotency_key = "reference-resume-#{order}"

    %Reconnect.Request{
      installation_id: device.installation_id,
      challenge_id: challenge.id,
      nonce: challenge.nonce,
      nonce_signature:
        sign(
          device_key,
          reconnect_input(
            account.id,
            device.installation_id,
            challenge.id,
            challenge.nonce,
            idempotency_key
          )
        ),
      idempotency_key: idempotency_key,
      client_revision: 0,
      client_disposition: :allow
    }
  end

  defp device!(repo, account, installation_id, now) do
    key = JOSE.JWK.generate_key({:ec, "P-256"})
    public_jwk = key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

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

    {device, key}
  end

  defp authorized?(_account, action),
    do: action in [:offline_challenge, :offline_reconnect_challenge, :offline_reconnect]

  defp datetime!(value), do: value |> DateTime.from_iso8601() |> elem(1)

  defp sign(key, input),
    do: key |> JOSE.JWK.to_key() |> elem(1) |> then(&:public_key.sign(input, :sha256, &1))

  defp reconnect_input(account, installation, challenge, nonce, key),
    do:
      ["v1.59", "reconnect", account, installation, challenge, nonce, digest(key)]
      |> Enum.map_join(&length_prefix/1)

  defp length_prefix(value),
    do: <<byte_size(value)::unsigned-big-integer-size(32), value::binary>>

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)

  defp signing_key,
    do:
      __DIR__
      |> Path.join("../../../../priv/entitlements/v1.59-offline-test-key.jwk.json")
      |> File.read!()
      |> Jason.decode!()

  defp public_key,
    do:
      signing_key()
      |> Map.take(["kty", "crv", "kid", "x", "y"])
      |> Map.merge(%{"alg" => "ES256", "use" => "sig"})
end
