defmodule Accrue.Entitlements.Offline.Reconnect do
  @moduledoc false
  import Ecto.Query
  alias Accrue.Entitlements.{Account, Device}
  alias Accrue.Entitlements.Offline.{Challenge, Issuer, SourceCoordinator}

  defmodule Request do
    @enforce_keys [:installation_id, :challenge_id, :nonce, :nonce_signature, :idempotency_key]
    defstruct [
      :installation_id,
      :challenge_id,
      :nonce,
      :nonce_signature,
      :idempotency_key,
      :client_revision,
      :client_disposition,
      :client_issued_at
    ]
  end

  defmodule Outcome do
    @enforce_keys [:disposition, :reason, :next_action, :due_source_count]
    defstruct [
      :disposition,
      :reason,
      :next_action,
      :retry_after,
      :proof,
      :revision,
      :due_source_count
    ]
  end

  @spec reconnect(Account.t(), Request.t(), keyword()) :: {:ok, Outcome.t()} | {:error, atom()}
  def reconnect(%Account{} = account, %Request{} = request, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with true <- authorized?(opts, account),
         {:ok, device} <- consume_pop(account, request, now, opts),
         {:ok, statuses} <- due_statuses(account, now, opts),
         {:ok, refreshed} <- refresh_due(account, statuses, now, opts),
         {:ok, outcome} <- settle(account, device, request, refreshed, now, opts) do
      {:ok, outcome}
    else
      false -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  def reconnect(_, _, _), do: {:error, :invalid_request}

  defp due_statuses(account, now, opts) do
    coordinator = Keyword.get(opts, :source_coordinator)

    with true <- is_atom(coordinator) and function_exported?(coordinator, :due_sources, 3),
         {:ok, statuses} <- coordinator.due_sources(account, now, opts),
         :ok <- SourceCoordinator.validate(statuses),
         do: {:ok, statuses},
         else: (_ -> {:error, :source_unavailable})
  end

  defp refresh_due(account, statuses, now, opts) do
    coordinator = Keyword.fetch!(opts, :source_coordinator)

    statuses
    |> Enum.reduce_while({:ok, []}, fn status, {:ok, accepted} ->
      result =
        if status.due, do: coordinator.refresh(account, status, now, opts), else: {:ok, status}

      case result do
        {:ok, %SourceCoordinator.SourceStatus{} = refreshed} ->
          {:cont, {:ok, [refreshed | accepted]}}

        _ ->
          {:halt, {:error, :source_unavailable}}
      end
    end)
    |> case do
      {:ok, refreshed} ->
        refreshed = Enum.reverse(refreshed)

        if SourceCoordinator.validate(refreshed) == :ok,
          do: {:ok, refreshed},
          else: {:error, :source_unavailable}

      error ->
        error
    end
  end

  defp settle(account, device, _request, statuses, now, opts) do
    due = Enum.filter(statuses, & &1.due)
    unresolved = Enum.reject(due, &(&1.state == :resolved))

    Enum.each(unresolved, fn status ->
      Keyword.fetch!(opts, :source_coordinator).enqueue_repair(account, status, now, opts)
    end)

    if unresolved == [] do
      issuer = %Issuer.Request{account_id: account.id, device_id: device.id, now: now}

      case Issuer.issue(account, issuer, opts) do
        {:ok, result} ->
          {:ok,
           %Outcome{
             disposition: :issued,
             reason: :ok,
             next_action: :none,
             proof: result.compact,
             revision: result.revision,
             due_source_count: length(due)
           }}

        {:error, reason} ->
          {:error, reason}
      end
    else
      state =
        if Enum.any?(unresolved, &(&1.state == :needs_repair)), do: :needs_repair, else: :pending

      retry =
        unresolved
        |> Enum.map(& &1.retry_after)
        |> Enum.filter(&is_integer/1)
        |> Enum.min(fn -> nil end)

      {:ok,
       %Outcome{
         disposition: state,
         reason: state,
         next_action: :reconnect_required,
         retry_after: retry,
         due_source_count: length(due)
       }}
    end
  end

  defp consume_pop(account, request, now, opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

    result =
      repo.transaction(fn ->
        device =
          repo.one(
            from(d in Device,
              where:
                d.account_id == ^account.id and d.installation_id == ^request.installation_id,
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

        with %Device{state: :active} = device <- device,
             %Challenge{purpose: :reconnect, consumed_at: nil} = challenge <- challenge,
             true <-
               challenge.installation_id == request.installation_id and
                 challenge.nonce_digest == digest(request.nonce) and
                 DateTime.compare(challenge.expires_at, now) == :gt,
             true <- valid_signature?(account, device, challenge, request),
             {:ok, _} <-
               repo.update(
                 Challenge.changeset(challenge, %{
                   consumed_at: now,
                   idempotency_digest: digest(request.idempotency_key)
                 })
               ) do
          {:ok, device}
        else
          _ -> repo.rollback(:challenge_invalid)
        end
      end)

    case result do
      {:ok, {:ok, device}} -> {:ok, device}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :challenge_invalid}
    end
  end

  defp valid_signature?(account, device, challenge, request) do
    {_, key} = JOSE.JWK.from(device.public_jwk) |> JOSE.JWK.to_public_key()

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
      key
    )
  rescue
    _ -> false
  end

  defp authorized?(opts, account) do
    case Keyword.get(opts, :authorize) do
      callback when is_function(callback, 2) -> callback.(account, :offline_reconnect) == true
      _ -> false
    end
  end

  defp signing_input(account, installation, challenge, nonce, key),
    do:
      ["v1.59", "reconnect", account, installation, challenge, nonce, digest(key)]
      |> Enum.map_join(fn v -> <<byte_size(v)::unsigned-big-integer-size(32), v::binary>> end)

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)
end
