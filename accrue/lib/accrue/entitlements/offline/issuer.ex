defmodule Accrue.Entitlements.Offline.Issuer do
  @moduledoc false
  import Ecto.Query

  alias Accrue.Entitlements.{Account, Device, Snapshot}
  alias Accrue.Entitlements.Offline.{Challenge, Issuance, Proof}

  defmodule Request do
    @enforce_keys [:account_id, :device_id, :now]
    defstruct [:account_id, :device_id, :now, :correlation_id, :denial_reason]
  end

  defmodule Result do
    @enforce_keys [:compact, :disposition, :revision, :fresh_until]
    defstruct [:compact, :disposition, :revision, :fresh_until]
  end

  # This is an identity for an admission already persisted by Reconnect, not a
  # bearer proof. The issuer always re-loads and locks the challenge before it
  # mints, so constructing this struct cannot grant issuance authority.
  defmodule Admission do
    @enforce_keys [:challenge_id, :account_id, :device_id, :installation_id, :idempotency_digest]
    defstruct [:challenge_id, :account_id, :device_id, :installation_id, :idempotency_digest]

    @opaque t :: %__MODULE__{
              challenge_id: binary(),
              account_id: binary(),
              device_id: binary(),
              installation_id: binary(),
              idempotency_digest: binary()
            }

    @doc false
    @spec from_reconnect_challenge(Challenge.t(), Device.t()) :: t()
    def from_reconnect_challenge(
          %Challenge{
            id: challenge_id,
            account_id: account_id,
            installation_id: installation_id,
            idempotency_digest: idempotency_digest
          },
          %Device{id: device_id}
        ) do
      %__MODULE__{
        challenge_id: challenge_id,
        account_id: account_id,
        device_id: device_id,
        installation_id: installation_id,
        idempotency_digest: idempotency_digest
      }
    end
  end

  @freshness_seconds 30 * 24 * 60 * 60

  # Compatibility entry point: a caller assertion is not an admission.
  @doc false
  @spec issue_after_admission(Account.t(), Request.t(), keyword()) ::
          {:error, :unauthorized}
  def issue_after_admission(_, _, _), do: {:error, :unauthorized}

  @doc false
  @spec issue_after_admission(Account.t(), Request.t(), Admission.t(), keyword()) ::
          {:ok, Result.t()} | {:error, atom()}
  def issue_after_admission(
        %Account{id: id},
        %Request{account_id: id} = request,
        %Admission{} = admission,
        opts
      )
      when is_list(opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :issue],
      %{action: :offline_issue, disposition: :admitted},
      fn ->
        case repo.transaction(fn -> issue_in_transaction(repo, request, admission, opts) end) do
          {:ok, {:ok, result}} -> {:ok, result}
          {:ok, {:error, reason}} -> {:error, reason}
          {:error, reason} when is_atom(reason) -> {:error, reason}
          _ -> {:error, :issuance_failed}
        end
      end
    )
  end

  def issue_after_admission(_, _, _, _), do: {:error, :unauthorized}

  @doc false
  @spec issue(Account.t(), Request.t(), keyword()) :: {:error, :unauthorized}
  def issue(_, _, _), do: {:error, :unauthorized}

  @doc false
  @spec issue_in_transaction(Ecto.Repo.t(), Request.t(), keyword()) :: {:error, :unauthorized}
  def issue_in_transaction(_, _, _), do: {:error, :unauthorized}

  @doc false
  @spec issue_in_transaction(Ecto.Repo.t(), Request.t(), Admission.t(), keyword()) ::
          {:ok, Result.t()} | {:error, atom()}
  def issue_in_transaction(repo, %Request{} = request, %Admission{} = admission, opts) do
    account = repo.one(from(a in Account, where: a.id == ^request.account_id, lock: "FOR UPDATE"))

    device =
      repo.one(
        from(d in Device,
          where: d.id == ^request.device_id and d.account_id == ^request.account_id,
          lock: "FOR UPDATE"
        )
      )

    with %Account{} = account <- account,
         %Device{} = device <- device,
         :ok <- consume_admission(repo, account, device, admission),
         :ok <- validate_denial_reason(request.denial_reason),
         snapshot <- Snapshot.fetch(repo, account),
         {disposition, reason} <- disposition(snapshot, device, request),
         expires_at <- expiry(snapshot, disposition),
         fresh_until <- fresh_until(request.now, expires_at),
         token_id <- Ecto.UUID.generate(),
         payload <-
           claims(
             snapshot,
             device,
             token_id,
             request.now,
             fresh_until,
             expires_at,
             disposition,
             reason,
             opts
           ),
         {:ok, compact} <- sign(payload, opts),
         {:ok, kid} <- kid(compact),
         :ok <- verify(compact, account, device, request.now, opts),
         :ok <-
           persist(
             repo,
             account,
             device,
             request,
             token_id,
             kid,
             disposition,
             fresh_until,
             expires_at
           ) do
      {:ok,
       %Result{
         compact: compact,
         disposition: disposition,
         revision: account.revision,
         fresh_until: fresh_until
       }}
    else
      nil -> repo.rollback(:not_found)
      {:error, reason} -> repo.rollback(reason)
      _ -> repo.rollback(:issuance_failed)
    end
  end

  defp consume_admission(repo, account, device, admission) do
    challenge =
      repo.one(
        from(c in Challenge,
          where: c.id == ^admission.challenge_id and c.account_id == ^account.id,
          lock: "FOR UPDATE"
        )
      )

    case challenge do
      %Challenge{
        purpose: :reconnect,
        consumed_at: %DateTime{},
        account_id: account_id,
        installation_id: installation_id,
        idempotency_digest: idempotency_digest,
        reconnect_outcome: %{"state" => "admitted"} = outcome
      }
      when account_id == admission.account_id and account_id == account.id and
             installation_id == admission.installation_id and
             installation_id == device.installation_id and device.id == admission.device_id and
             idempotency_digest == admission.idempotency_digest ->
        case repo.update(
               Challenge.changeset(challenge, %{
                 reconnect_outcome: Map.put(outcome, "state", "minting")
               })
             ) do
          {:ok, _} -> :ok
          _ -> {:error, :admission_invalid}
        end

      _ ->
        {:error, :admission_invalid}
    end
  end

  defp disposition(_, %Device{state: state}, request) when state in [:revoked, :superseded],
    do:
      {:deny,
       request.denial_reason || if(state == :revoked, do: :device_revoked, else: :superseded)}

  defp disposition(snapshot, _, _)
       when snapshot.plans == [] and snapshot.features == [] and
              map_size(snapshot.quantities) == 0,
       do: {:deny, :signed_denial}

  defp disposition(_, _, _), do: {:allow, nil}

  defp validate_denial_reason(nil), do: :ok

  defp validate_denial_reason(reason) when is_atom(reason) do
    if Proof.denial_reason?(reason), do: :ok, else: {:error, :invalid_request}
  end

  defp validate_denial_reason(_), do: {:error, :invalid_request}

  defp expiry(_, :deny), do: nil

  defp expiry(snapshot, :allow),
    do:
      snapshot.sources
      |> Enum.map(& &1.expires_at)
      |> Enum.filter(&match?(%DateTime{}, &1))
      |> Enum.min_by(&DateTime.to_unix/1, fn -> nil end)

  defp fresh_until(now, nil), do: DateTime.add(now, @freshness_seconds, :second)

  defp fresh_until(now, expires_at),
    do:
      Enum.min_by(
        [DateTime.add(now, @freshness_seconds, :second), expires_at],
        &DateTime.to_unix/1
      )

  defp claims(snapshot, device, token_id, now, fresh_until, expires_at, disposition, reason, opts) do
    value = %{
      "version" => "v1.59",
      "iss" => Keyword.get(opts, :issuer, "accrue"),
      "aud" => Keyword.get(opts, :audience, "accrue-offline-client"),
      "jti" => token_id,
      "sub" => snapshot.account_id,
      "cnf" => %{"jkt" => device.key_thumbprint},
      "revision" => snapshot.revision,
      "iat" => DateTime.to_unix(now),
      "nbf" => DateTime.to_unix(now),
      "fresh_until" => DateTime.to_unix(fresh_until),
      "exp" => if(expires_at, do: DateTime.to_unix(expires_at), else: nil),
      "disposition" => Atom.to_string(disposition),
      "plans" => Enum.map(snapshot.plans, &Atom.to_string/1),
      "features" => Enum.map(snapshot.features, &Atom.to_string/1),
      "quantities" => Map.new(snapshot.quantities, fn {k, v} -> {Atom.to_string(k), v} end)
    }

    if reason, do: Map.put(value, "denial_reason", Atom.to_string(reason)), else: value
  end

  defp sign(payload, opts) do
    provider = Keyword.get(opts, :key_provider)

    if is_atom(provider) and function_exported?(provider, :sign, 2),
      do: provider.sign(payload, opts),
      else: {:error, :config_invalid}
  end

  defp kid(compact) do
    with [header | _] <- String.split(compact, "."),
         {:ok, json} <- Base.url_decode64(header, padding: false),
         {:ok, %{"kid" => kid}} <- Jason.decode(json),
         true <- is_binary(kid) and byte_size(kid) in 1..128,
         do: {:ok, kid},
         else: (_ -> {:error, :config_invalid})
  end

  defp verify(compact, account, device, now, opts) do
    provider = Keyword.fetch!(opts, :key_provider)

    with {:ok, keys} <- provider.public_keys(opts),
         %{state: state} <-
           Proof.verify(compact, %{
             issuer: Keyword.get(opts, :issuer, "accrue"),
             audience: Keyword.get(opts, :audience, "accrue-offline-client"),
             account_subject: account.id,
             installation_id: device.installation_id,
             device_thumbprint: device.key_thumbprint,
             now: DateTime.to_unix(now),
             clock_high_water: %{revision: 0, iat: 0, fresh_until: 0},
             accepted_revision: 0,
             accepted_disposition: nil,
             accepted_iat: 0,
             accepted_fresh_until: 0,
             public_keys: keys
           }),
         true <- state in [:fresh, :denied],
         do: :ok,
         else: (_ -> {:error, :verification_failed})
  end

  defp persist(
         repo,
         account,
         device,
         request,
         token_id,
         kid,
         disposition,
         fresh_until,
         expires_at
       ) do
    issuance =
      Issuance.changeset(%Issuance{}, %{
        account_id: account.id,
        device_id: device.id,
        token_id_hash: digest(token_id),
        kid: kid,
        revision: account.revision,
        disposition: disposition,
        issued_at: request.now,
        fresh_until: fresh_until,
        expires_at: expires_at
      })

    device_changeset =
      Device.changeset(device, %{
        last_accepted_revision: max(device.last_accepted_revision, account.revision),
        last_seen_at: request.now
      })

    with {:ok, _} <- repo.insert(issuance),
         {:ok, _} <- repo.update(device_changeset) do
      :ok
    else
      {:error, changeset} -> {:error, {:persistence_failed, changeset.errors}}
      _ -> {:error, :persistence_failed}
    end
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)
end
