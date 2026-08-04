defmodule Accrue.Entitlements.Offline.Registration do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.Device
  alias Accrue.Entitlements.Account
  alias Accrue.Entitlements.Offline.Challenge
  alias Accrue.Events.Event

  defmodule Request do
    @enforce_keys [
      :installation_id,
      :device_public_jwk,
      :challenge_id,
      :nonce,
      :nonce_signature,
      :idempotency_key
    ]
    defstruct [
      :installation_id,
      :device_public_jwk,
      :challenge_id,
      :nonce,
      :nonce_signature,
      :idempotency_key
    ]
  end

  defmodule Result do
    @enforce_keys [:installation_id, :key_thumbprint, :state]
    defstruct [:installation_id, :key_thumbprint, :state]
  end

  defmodule ReplacementRequest do
    @enforce_keys [
      :prior_device_id,
      :replacement_installation_id,
      :replacement_public_jwk,
      :challenge_id,
      :nonce,
      :nonce_signature,
      :idempotency_key,
      :prior_transition,
      :reason
    ]
    defstruct @enforce_keys
    @type t :: %__MODULE__{}
  end

  defmodule ReplacementResult do
    @enforce_keys [
      :prior_device_id,
      :prior_installation_id,
      :prior_state,
      :replacement_device_id,
      :replacement_installation_id,
      :replacement_key_thumbprint,
      :replacement_state,
      :disposition,
      :audit_id
    ]
    defstruct @enforce_keys
    @type t :: %__MODULE__{}
  end

  @protocol_version "v1.59"
  @max_idempotency_bytes 255

  @spec register(Accrue.Entitlements.Account.t(), Request.t(), keyword()) ::
          {:ok, Result.t()} | {:error, atom()}
  def register(account, request, opts \\ [])

  def register(%Accrue.Entitlements.Account{} = account, %Request{} = request, opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :register_device],
      %{action: :register_device, outcome: :requested},
      fn -> do_register(account, request, opts) end
    )
  end

  def register(_, _, _), do: {:error, :invalid_request}

  @spec replace(Accrue.Entitlements.Account.t(), ReplacementRequest.t(), keyword()) ::
          {:ok, ReplacementResult.t()} | {:error, atom()}
  def replace(%Accrue.Entitlements.Account{} = account, %ReplacementRequest{} = request, opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :replace_device],
      %{action: :offline_device_replacement, outcome: :requested},
      fn -> do_replace(account, request, opts) end
    )
  end

  def replace(_, _, _), do: {:error, :invalid_request}

  @doc false
  def signing_input(account_id, installation_id, challenge_id, nonce, idempotency_key) do
    [
      @protocol_version,
      "registration",
      account_id,
      installation_id,
      challenge_id,
      nonce,
      digest(idempotency_key)
    ]
    |> Enum.map_join(&length_prefix/1)
  end

  @doc false
  def replacement_signing_input(
        account_id,
        prior_device_id,
        replacement_installation_id,
        replacement_key_thumbprint,
        challenge_id,
        nonce,
        idempotency_key,
        prior_transition,
        reason
      ) do
    [
      @protocol_version,
      "device_replacement",
      account_id,
      prior_device_id,
      replacement_installation_id,
      replacement_key_thumbprint,
      challenge_id,
      nonce,
      digest(idempotency_key),
      Atom.to_string(prior_transition),
      Atom.to_string(reason)
    ]
    |> Enum.map_join(&length_prefix/1)
  end

  defp do_register(account, request, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with true <- authorized?(opts, account, :offline_registration),
         :ok <- valid_request(request),
         {:ok, result} <- transact_registration(repo, account, request, now) do
      {:ok, result}
    else
      false -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_replace(account, request, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with true <- authorized?(opts, account, :offline_device_replacement),
         :ok <- valid_replacement_request(request),
         {:ok, actor} <- valid_actor(Keyword.get(opts, :actor)),
         {:ok, result} <- transact_replacement(repo, account, request, actor, now) do
      {:ok, result}
    else
      false -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp transact_replacement(repo, account, request, actor, now) do
    case repo.transaction(fn -> replace_in_transaction(repo, account, request, actor, now) end) do
      {:ok, {:ok, result}} -> {:ok, result}
      {:ok, {:error, reason}} -> {:error, reason}
      {:error, reason} -> {:error, normalize_error(reason)}
    end
  end

  defp replace_in_transaction(repo, account, request, actor, now) do
    locked_account = repo.one(from(a in Account, where: a.id == ^account.id, lock: "FOR UPDATE"))

    prior =
      repo.one(
        from(d in Device,
          where: d.id == ^request.prior_device_id and d.account_id == ^account.id,
          lock: "FOR UPDATE"
        )
      )

    challenge =
      repo.one(
        from(c in Challenge,
          where: c.id == ^request.challenge_id and c.account_id == ^account.id,
          lock: "FOR UPDATE"
        )
      )

    with %Account{} <- locked_account,
         %Device{} = prior <- prior,
         %Challenge{} = challenge <- challenge,
         {:ok, replay} <- replacement_replay(repo, account, prior, challenge, request),
         :not_replayed <- replay,
         :ok <- active_prior?(prior),
         :ok <- replacement_challenge_matches?(challenge, request, now),
         :ok <- verify_replacement_signature(account, challenge, request),
         {:ok, result} <- commit_replacement(repo, account, prior, challenge, request, actor, now) do
      {:ok, result}
    else
      nil -> {:error, :account_not_found}
      :not_replayed -> {:error, :replacement_failed}
      {:replay, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  defp replacement_replay(_repo, _account, _prior, %Challenge{consumed_at: nil}, _request),
    do: {:ok, :not_replayed}

  defp replacement_replay(repo, account, prior, challenge, request) do
    if challenge.idempotency_digest == replacement_digest(request) do
      case repo.get_by(Event, idempotency_key: audit_idempotency_key(request)) do
        %Event{subject_id: subject_id, id: audit_id} when subject_id == account.id ->
          replacement =
            repo.get_by(Device,
              account_id: account.id,
              installation_id: request.replacement_installation_id
            )

          if replay_matches?(prior, replacement, request),
            do:
              {:ok,
               {:replay, replacement_result(prior, replacement, :already_completed, audit_id)}},
            else: {:error, :idempotency_conflict}

        _ ->
          {:error, :idempotency_conflict}
      end
    else
      {:error, :challenge_consumed}
    end
  end

  defp active_prior?(%Device{state: :active}), do: :ok
  defp active_prior?(_), do: {:error, :prior_device_not_active}

  defp replacement_challenge_matches?(challenge, request, now) do
    cond do
      challenge.purpose != :registration ->
        {:error, :challenge_invalid}

      challenge.installation_id != request.replacement_installation_id ->
        {:error, :challenge_invalid}

      challenge.nonce_digest != digest(request.nonce) ->
        {:error, :challenge_invalid}

      DateTime.compare(challenge.expires_at, now) != :gt ->
        {:error, :challenge_expired}

      true ->
        :ok
    end
  end

  defp verify_replacement_signature(account, challenge, request) do
    with thumbprint when is_binary(thumbprint) and thumbprint != "" <-
           Device.thumbprint(request.replacement_public_jwk),
         {_, public_key} <-
           JOSE.JWK.from(request.replacement_public_jwk) |> JOSE.JWK.to_public_key(),
         true <-
           :public_key.verify(
             replacement_signing_input(
               account.id,
               request.prior_device_id,
               request.replacement_installation_id,
               thumbprint,
               challenge.id,
               request.nonce,
               request.idempotency_key,
               request.prior_transition,
               request.reason
             ),
             :sha256,
             request.nonce_signature,
             public_key
           ) do
      :ok
    else
      _ -> {:error, :signature_invalid}
    end
  rescue
    _ -> {:error, :signature_invalid}
  end

  defp commit_replacement(repo, account, prior, challenge, request, actor, now) do
    with {:ok, _} <-
           repo.update(
             Device.changeset(prior, prior_transition_attrs(request.prior_transition, now))
           ),
         {:ok, replacement} <-
           repo.insert(
             Device.changeset(%Device{}, %{
               account_id: account.id,
               installation_id: request.replacement_installation_id,
               public_jwk: request.replacement_public_jwk,
               key_thumbprint: Device.thumbprint(request.replacement_public_jwk),
               state: :active,
               registered_at: now,
               last_seen_at: now,
               last_accepted_revision: 0
             })
           ),
         {:ok, _} <-
           repo.update(
             Challenge.changeset(challenge, %{
               consumed_at: now,
               idempotency_digest: replacement_digest(request)
             })
           ),
         {:ok, audit} <-
           repo.insert(
             Event.changeset(replacement_audit_attrs(account, prior, replacement, request, actor))
           ) do
      {:ok,
       replacement_result(
         prior_transitioned(prior, request.prior_transition, now),
         replacement,
         :replaced,
         audit.id
       )}
    else
      {:error, changeset} -> repo.rollback(normalize_error(changeset))
    end
  end

  defp valid_replacement_request(request) do
    cond do
      not (is_binary(request.prior_device_id) and is_binary(request.replacement_installation_id) and
             is_binary(request.challenge_id) and is_binary(request.nonce) and
             is_binary(request.nonce_signature) and is_binary(request.idempotency_key) and
             byte_size(request.idempotency_key) <= @max_idempotency_bytes and
               is_map(request.replacement_public_jwk)) ->
        {:error, :invalid_request}

      request.prior_device_id == request.replacement_installation_id ->
        {:error, :invalid_request}

      request.prior_transition == :superseded and request.reason == :planned_replacement ->
        :ok

      request.prior_transition == :revoked and request.reason == :lost_or_compromised ->
        :ok

      true ->
        {:error, :invalid_transition}
    end
  end

  defp valid_actor(%{type: type, id: id})
       when type in [:user, :admin] and is_binary(id) and byte_size(id) in 1..255,
       do: {:ok, %{type: type, id: id}}

  defp valid_actor(_), do: {:error, :invalid_actor}

  defp prior_transition_attrs(:superseded, now), do: %{state: :superseded, superseded_at: now}
  defp prior_transition_attrs(:revoked, now), do: %{state: :revoked, revoked_at: now}

  defp prior_transitioned(prior, :superseded, now),
    do: %{prior | state: :superseded, superseded_at: now}

  defp prior_transitioned(prior, :revoked, now), do: %{prior | state: :revoked, revoked_at: now}

  defp replay_matches?(prior, %Device{} = replacement, request) do
    prior.state == request.prior_transition and
      replacement.public_jwk == request.replacement_public_jwk and
      replacement.state == :active
  end

  defp replay_matches?(_, _, _), do: false

  defp replacement_result(prior, replacement, disposition, audit_id) do
    %ReplacementResult{
      prior_device_id: prior.id,
      prior_installation_id: prior.installation_id,
      prior_state: prior.state,
      replacement_device_id: replacement.id,
      replacement_installation_id: replacement.installation_id,
      replacement_key_thumbprint: replacement.key_thumbprint,
      replacement_state: replacement.state,
      disposition: disposition,
      audit_id: audit_id
    }
  end

  defp replacement_audit_attrs(account, prior, replacement, request, actor) do
    %{
      type: "entitlements.offline.device_replaced",
      subject_type: "EntitlementAccount",
      subject_id: account.id,
      actor_type: Atom.to_string(actor.type),
      actor_id: actor.id,
      idempotency_key: audit_idempotency_key(request),
      data: %{
        "action" => "offline_device_replacement",
        "reason" => Atom.to_string(request.reason),
        "prior_transition" => Atom.to_string(request.prior_transition),
        "prior_device_hash" => digest(prior.id),
        "replacement_device_hash" => digest(replacement.id),
        "operation_digest" => replacement_digest(request)
      }
    }
  end

  defp replacement_digest(request) do
    [
      @protocol_version,
      "device_replacement",
      request.prior_device_id,
      request.replacement_installation_id,
      Device.thumbprint(request.replacement_public_jwk),
      request.challenge_id,
      digest(request.nonce),
      digest(request.idempotency_key),
      Atom.to_string(request.prior_transition),
      Atom.to_string(request.reason)
    ]
    |> Enum.map_join(&length_prefix/1)
    |> digest()
  end

  defp audit_idempotency_key(request),
    do: "offline-device-replace:" <> replacement_digest(request)

  defp transact_registration(repo, account, request, now) do
    case repo.transaction(fn -> register_in_transaction(repo, account, request, now) end) do
      {:ok, {:ok, result}} -> {:ok, result}
      {:ok, {:error, reason}} -> {:error, reason}
      {:error, reason} -> {:error, normalize_error(reason)}
    end
  end

  defp register_in_transaction(repo, account, request, now) do
    challenge =
      repo.one(
        from(c in Challenge,
          where: c.id == ^request.challenge_id and c.account_id == ^account.id,
          lock: "FOR UPDATE"
        )
      )

    with %Challenge{} = challenge <- challenge,
         :ok <- challenge_matches?(challenge, request, now),
         :ok <- verify_signature(account, challenge, request),
         {:ok, result} <- consume_or_replay(repo, account, challenge, request, now) do
      {:ok, result}
    else
      nil -> {:error, :challenge_invalid}
      {:error, reason} -> {:error, reason}
    end
  end

  defp challenge_matches?(challenge, request, now) do
    cond do
      challenge.purpose != :registration ->
        {:error, :challenge_invalid}

      challenge.installation_id != request.installation_id ->
        {:error, :challenge_invalid}

      not is_binary(request.nonce_signature) ->
        {:error, :signature_invalid}

      not is_binary(request.idempotency_key) or
          byte_size(request.idempotency_key) > @max_idempotency_bytes ->
        {:error, :invalid_request}

      challenge.nonce_digest != digest(request.nonce) ->
        {:error, :challenge_invalid}

      DateTime.compare(challenge.expires_at, now) != :gt ->
        {:error, :challenge_expired}

      true ->
        :ok
    end
  end

  defp verify_signature(account, challenge, request) do
    with thumbprint when is_binary(thumbprint) and thumbprint != "" <-
           Device.thumbprint(request.device_public_jwk),
         {_, public_key} <- JOSE.JWK.from(request.device_public_jwk) |> JOSE.JWK.to_public_key(),
         true <-
           :public_key.verify(
             signing_input(
               account.id,
               request.installation_id,
               challenge.id,
               request.nonce,
               request.idempotency_key
             ),
             :sha256,
             request.nonce_signature,
             public_key
           ) do
      :ok
    else
      _ -> {:error, :signature_invalid}
    end
  rescue
    _ -> {:error, :signature_invalid}
  end

  defp consume_or_replay(
         repo,
         account,
         %Challenge{consumed_at: %DateTime{}} = challenge,
         request,
         _now
       ) do
    if challenge.idempotency_digest == digest(request.idempotency_key) do
      case repo.get_by(Device, account_id: account.id, installation_id: request.installation_id) do
        %Device{public_jwk: public_jwk, state: :active} = device
        when public_jwk == request.device_public_jwk ->
          {:ok, result(device)}

        _ ->
          {:error, :idempotency_conflict}
      end
    else
      {:error, :challenge_consumed}
    end
  end

  defp consume_or_replay(repo, account, challenge, request, now) do
    with {:ok, _challenge} <-
           repo.update(
             Challenge.changeset(challenge, %{
               consumed_at: now,
               idempotency_digest: digest(request.idempotency_key)
             })
           ),
         {:ok, device} <-
           repo.insert(
             Device.changeset(%Device{}, %{
               account_id: account.id,
               installation_id: request.installation_id,
               public_jwk: request.device_public_jwk,
               key_thumbprint: Device.thumbprint(request.device_public_jwk),
               state: :active,
               registered_at: now,
               last_seen_at: now,
               last_accepted_revision: 0
             })
           ) do
      {:ok, result(device)}
    else
      {:error, changeset} -> repo.rollback(normalize_error(changeset))
    end
  end

  defp valid_request(request) do
    if is_binary(request.installation_id) and is_binary(request.challenge_id) and
         is_binary(request.nonce) and is_map(request.device_public_jwk),
       do: :ok,
       else: {:error, :invalid_request}
  end

  defp authorized?(opts, account, action) do
    case Keyword.get(opts, :authorize) do
      callback when is_function(callback, 2) -> callback.(account, action) == true
      _ -> false
    end
  end

  defp result(device),
    do: %Result{
      installation_id: device.installation_id,
      key_thumbprint: device.key_thumbprint,
      state: device.state
    }

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)

  defp length_prefix(value),
    do: <<byte_size(value)::unsigned-big-integer-size(32), value::binary>>

  defp normalize_error(%Ecto.Changeset{}), do: :invalid_request
  defp normalize_error(reason) when is_atom(reason), do: reason
  defp normalize_error(_), do: :registration_failed
end
