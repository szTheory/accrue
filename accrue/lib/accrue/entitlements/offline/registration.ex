defmodule Accrue.Entitlements.Offline.Registration do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.Device
  alias Accrue.Entitlements.Offline.Challenge

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
