defmodule Accrue.Entitlements.ReferenceScenarioExecutor.ReconnectCache do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Device, Offline, Snapshot}

  alias Accrue.Entitlements.Offline.{
    Challenge,
    Issuance,
    Reconnect,
    ReconnectAttempt,
    Registration
  }

  alias Accrue.Entitlements.ReferenceScenarioExecutor.Read

  defmodule SigningProvider do
    @behaviour Accrue.Entitlements.Offline.KeyProvider

    @impl true
    def sign(payload, opts) do
      key = Keyword.fetch!(opts, :signing_key)
      header = %{"alg" => "ES256", "typ" => "accrue-entitlement-proof+jwt", "kid" => key["kid"]}

      {:ok,
       key
       |> JOSE.JWK.from()
       |> JOSE.JWS.sign(Jason.encode!(payload), header)
       |> JOSE.JWS.compact()
       |> elem(1)}
    end

    @impl true
    def public_keys(opts), do: {:ok, [Keyword.fetch!(opts, :public_key)]}
  end

  defmodule NoDueSources do
    @behaviour Accrue.Entitlements.Offline.SourceCoordinator
    def due_sources(_, _, _), do: {:ok, []}
    def refresh(_, status, _, _), do: {:ok, status}
    def enqueue_repair(_, _, _, _), do: :ok
  end

  def execute(repo, account, action, runtime), do: execute(repo, account, action, runtime, [])

  def execute(
        repo,
        account,
        %{kind: "reconnect_request", command: %{payload: payload}} = action,
        runtime,
        _opts
      ) do
    :ok = Read.seed_declared_grant(repo, account, payload)
    now = datetime!(payload.clock)
    {device, device_key} = device!(repo, account, "#{payload.account_ref}-device", now)
    Code.ensure_loaded!(NoDueSources)
    Code.ensure_loaded!(SigningProvider)
    issuer_opts = issuer_opts(repo, now)
    reconnect_opts = issuer_opts ++ [source_coordinator: NoDueSources, authorize: &authorized?/2]

    {:ok, challenge} =
      Offline.reconnect_challenge(account, device.installation_id, reconnect_opts)

    idempotency_key = "reference-reconnect-#{action.order}"

    request = %Reconnect.Request{
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

    {:ok, %{disposition: :issued, proof: proof}} =
      Offline.reconnect(account, request, reconnect_opts)

    challenge_row = repo.get!(Challenge, challenge.id)
    attempt = repo.one!(from(item in ReconnectAttempt, where: item.challenge_id == ^challenge.id))

    issuance =
      repo.one!(
        from(item in Issuance,
          where: item.account_id == ^account.id and item.device_id == ^device.id
        )
      )

    {:ok, snapshot} = Accrue.Entitlements.snapshot(account, now: now)

    observed = %{
      result: %{tag: "executed", disposition: "reconnect_request"},
      durable: %{
        challenge_consumed: not is_nil(challenge_row.consumed_at),
        attempt_state: Atom.to_string(attempt.state),
        issuance_count:
          repo.aggregate(
            from(item in Issuance, where: item.account_id == ^account.id),
            :count,
            :id
          ),
        issuance_revision: issuance.revision,
        issuance_disposition: Atom.to_string(issuance.disposition),
        snapshot_revision: snapshot.revision
      },
      cache: %{prior: "allow", replacement: "pending", current: "allow"}
    }

    observed =
      Map.put(observed, :declared_transition, %{
        result: observed.result,
        durable: %{
          state: "unchanged",
          observation_kind: "none",
          snapshot_revision: snapshot.revision
        },
        cache: %{disposition: "replace"}
      })

    next_runtime = %{
      proofs: Map.put(Map.get(runtime, :proofs, %{}), action.order, proof),
      device: device,
      cache: %{revision: 0, disposition: :allow, proof: "prior"}
    }

    {observed, next_runtime}
  end

  def execute(
        _repo,
        account,
        %{kind: "verified_cache_replace", order: order} = action,
        runtime,
        opts
      ) do
    proof =
      runtime
      |> Map.fetch!(:proofs)
      |> Map.fetch!(order - 1)
      |> maybe_tamper(Keyword.get(opts, :tamper_proof, false))

    cache = Map.fetch!(runtime, :cache)
    device = Map.fetch!(runtime, :device)
    now = datetime!(action.command.payload.clock)

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

    {replacement, next_cache, result} =
      case Offline.verify(proof, context) do
        {:ok, %{state: state, claims: %{revision: revision, disposition: disposition}}}
        when state in [:fresh, :stale_offline] ->
          {"replace", %{revision: revision, disposition: disposition, proof: "verified"},
           %{tag: "executed", disposition: "verified_cache_replace"}}

        _ ->
          {"preserve", cache,
           %{
             tag: "executed",
             disposition: "verified_cache_replace",
             reason: "verification_failed"
           }}
      end

    observed =
      %{
        result: result,
        durable: %{snapshot_revision: account.revision},
        cache: %{
          prior: Atom.to_string(cache.disposition),
          replacement: replacement,
          current: Atom.to_string(next_cache.disposition)
        }
      }

    {Map.put(observed, :declared_transition, %{
       result: %{tag: "executed", disposition: "verified_cache_replace"},
       durable: %{
         state: "unchanged",
         observation_kind: "none",
         snapshot_revision: account.revision
       },
       cache: %{disposition: replacement}
     }), %{runtime | cache: next_cache}}
  end

  def adversarial_result(
        repo,
        account,
        %{kind: "reconnect_request", command: %{payload: payload}},
        adapter: :generic_grant
      ) do
    :ok = Read.seed_declared_grant(repo, account, payload)
    %{operation: "generic_grant", issuance_count: repo.aggregate(Issuance, :count, :id)}
  end

  def adversarial_result(repo, account, %{kind: "reconnect_request"}, adapter: :no_effect) do
    {:ok, _snapshot} = Accrue.Entitlements.snapshot(account)
    %{operation: "no_effect", attempt_count: repo.aggregate(ReconnectAttempt, :count, :id)}
  end

  def adversarial_result(_repo, account, %{kind: "reconnect_request"}, adapter: :snapshot_only) do
    _snapshot = Snapshot.from_grants([], account_id: account.id, revision: 0)
    %{operation: "snapshot_only"}
  end

  def adversarial_result(repo, account, %{kind: "reconnect_request"}, adapter: :registration_only) do
    now = ~U[2026-08-04 12:05:00Z]
    key = JOSE.JWK.generate_key({:ec, "P-256"})
    public_jwk = public_jwk(key)
    installation_id = "registration-only-#{System.unique_integer([:positive])}"
    opts = [repo: repo, now: now, authorize: &authorized?/2]
    {:ok, challenge} = Offline.challenge(account, installation_id, opts)
    idempotency_key = "registration-only"

    request = %Registration.Request{
      installation_id: installation_id,
      device_public_jwk: public_jwk,
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
            idempotency_key
          )
        ),
      idempotency_key: idempotency_key
    }

    {:ok, _} = Offline.register_device(account, request, opts)
    %{operation: "register_device", issuance_count: repo.aggregate(Issuance, :count, :id)}
  end

  def adversarial_result(_repo, _account, %{kind: "verified_cache_replace"}, adapter: adapter),
    do: %{operation: Atom.to_string(adapter), cache: "unverified"}

  def matches_expected?(%{kind: "reconnect_request"}, %{
        result: %{disposition: "reconnect_request"},
        durable: %{challenge_consumed: true, attempt_state: "completed", issuance_count: 1}
      }),
      do: true

  def matches_expected?(%{kind: "verified_cache_replace"}, %{
        result: %{disposition: "verified_cache_replace"},
        cache: %{replacement: "replace"}
      }),
      do: true

  def matches_expected?(_, _), do: false

  defp device!(repo, account, installation_id, now) do
    key = JOSE.JWK.generate_key({:ec, "P-256"})
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

    {device, key}
  end

  defp issuer_opts(repo, now),
    do: [
      repo: repo,
      key_provider: SigningProvider,
      signing_key: signing_key(),
      public_key: public_key(),
      issuer: "accrue.reference-scenario",
      audience: "accrue-offline-client",
      now: now
    ]

  defp authorized?(_account, action),
    do:
      action in [
        :offline_challenge,
        :offline_reconnect_challenge,
        :offline_reconnect,
        :offline_registration
      ]

  defp maybe_tamper(proof, true), do: proof <> "x"
  defp maybe_tamper(proof, false), do: proof
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

  defp public_jwk(key),
    do: key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])
end
