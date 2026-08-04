defmodule Accrue.Entitlements.Offline.Issuer do
  @moduledoc false
  import Ecto.Query

  alias Accrue.Entitlements.{Account, Device, Snapshot}
  alias Accrue.Entitlements.Offline.{Issuance, Proof}

  defmodule Request do
    @enforce_keys [:account_id, :device_id, :now]
    defstruct [:account_id, :device_id, :now, :correlation_id, :denial_reason]
  end

  defmodule Result do
    @enforce_keys [:compact, :disposition, :revision, :fresh_until]
    defstruct [:compact, :disposition, :revision, :fresh_until]
  end

  @freshness_seconds 30 * 24 * 60 * 60

  def issue(%Account{id: id}, %Request{account_id: id} = request, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    case repo.transaction(fn -> issue_in_transaction(repo, request, opts) end) do
      {:ok, {:ok, result}} -> {:ok, result}
      {:ok, {:error, reason}} -> {:error, reason}
      {:error, reason} when is_atom(reason) -> {:error, reason}
      _ -> {:error, :issuance_failed}
    end
  end

  def issue(_, _, _), do: {:error, :invalid_request}

  def issue_in_transaction(repo, %Request{} = request, opts) do
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

  defp disposition(_, %Device{state: :revoked}, request),
    do: {:deny, request.denial_reason || :device_revoked}

  defp disposition(snapshot, _, _)
       when snapshot.plans == [] and snapshot.features == [] and
              map_size(snapshot.quantities) == 0,
       do: {:deny, :signed_denial}

  defp disposition(_, _, _), do: {:allow, nil}

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
         %{"kid" => kid} <- Jason.decode!(json),
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
