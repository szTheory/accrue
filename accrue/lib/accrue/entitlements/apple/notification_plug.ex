defmodule Accrue.Entitlements.Apple.NotificationPlug do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  alias Accrue.Entitlements.Apple.{Intake, Verifier}

  @default_max_body_bytes 262_144
  @retryable_reasons [
    :provider_unavailable,
    :rate_limited,
    :persistence_unavailable,
    :reconciliation_stalled
  ]

  @impl true
  def init(opts) do
    opts
    |> Keyword.put_new(:max_body_bytes, @default_max_body_bytes)
    |> Keyword.put_new(:rate_limiter, fn _conn -> :allow end)
    |> Keyword.put_new(:verifier, Accrue.Entitlements.Apple.Verifier.Production)
  end

  @impl true
  def call(conn, opts) do
    with {:ok, raw_body} <- raw_body(conn, opts),
         :allow <- Keyword.fetch!(opts, :rate_limiter).(conn),
         result <-
           Keyword.fetch!(opts, :verifier).verify_notification(
             raw_body,
             Keyword.fetch!(opts, :verifier_config)
           ) do
      acknowledge_verification(conn, result, raw_body, opts)
    else
      {:error, :too_large} -> respond(conn, 413, :rejected)
      {:deny, _retry_after_seconds} -> respond(conn, 429, :rejected)
      {:error, :invalid_payload} -> respond(conn, 400, :rejected)
      {:error, reason} when reason in @retryable_reasons -> respond(conn, 503, :retryable)
      {:error, reason} -> quarantine(conn, reason, raw_body_or_empty(conn), opts)
    end
  rescue
    _ -> respond(conn, 503, :retryable)
  end

  defp acknowledge_verification(conn, {:ok, facts}, raw_body, opts) do
    with {:ok, evidence} <- evidence_from_facts(facts, raw_body, opts),
         {:ok, outcome} <- intake(opts).(evidence) do
      acknowledge_outcome(conn, outcome.disposition)
    else
      {:error, _} -> respond(conn, 503, :retryable)
    end
  end

  defp acknowledge_verification(conn, {:error, reason}, _raw_body, _opts)
       when reason in @retryable_reasons,
       do: respond(conn, 503, :retryable)

  defp acknowledge_verification(conn, {:error, :invalid_payload}, _raw_body, _opts),
    do: respond(conn, 400, :rejected)

  defp acknowledge_verification(conn, {:error, reason}, raw_body, opts),
    do: quarantine(conn, reason, raw_body, opts)

  defp quarantine(conn, reason, raw_body, opts) do
    digest = digest(raw_body)
    config = Keyword.fetch!(opts, :verifier_config)

    case Intake.quarantine_notification(
           environment(config),
           digest,
           verifier_version(config),
           config_version(config),
           reason,
           repo: Keyword.get(opts, :repo, Accrue.Repo.repo())
         ) do
      {:ok, %{disposition: :quarantined}} -> respond(conn, 200, :quarantined)
      _ -> respond(conn, 503, :retryable)
    end
  end

  defp evidence_from_facts(
         %{notification: notification, transaction: transaction},
         raw_body,
         opts
       )
       when is_map(notification) and is_map(transaction) do
    config = Keyword.fetch!(opts, :verifier_config)
    original_id = transaction["originalTransactionId"]
    event_id = notification["notificationUUID"]

    if bounded_id?(original_id) and bounded_id?(event_id) do
      {:ok,
       %Intake.VerifiedEvidence{
         environment: environment(config),
         original_transaction_id: original_id,
         provider_event_id: event_id,
         provider_transaction_id: bounded_or_digest(transaction["transactionId"], raw_body),
         product_id: bounded_or_digest(transaction["productId"], raw_body),
         lifecycle: :grant,
         effective_at: DateTime.utc_now(),
         signed_at: DateTime.utc_now(),
         evidence_digest: digest(raw_body),
         verifier_version: verifier_version(config),
         config_version: config_version(config)
       }}
    else
      {:error, :invalid_payload}
    end
  end

  defp evidence_from_facts(_, _, _), do: {:error, :invalid_payload}

  defp intake(opts) do
    case Keyword.get(opts, :intake) do
      callback when is_function(callback, 1) ->
        callback

      nil ->
        fn evidence ->
          Intake.observe_notification(evidence,
            repo: Keyword.get(opts, :repo, Accrue.Repo.repo())
          )
        end
    end
  end

  defp acknowledge_outcome(conn, disposition)
       when disposition in [:verified, :noop, :quarantined], do: respond(conn, 200, disposition)

  defp acknowledge_outcome(conn, _), do: respond(conn, 503, :retryable)

  defp raw_body(conn, opts) do
    raw_body = raw_body_or_empty(conn)

    if byte_size(raw_body) <= Keyword.fetch!(opts, :max_body_bytes),
      do: {:ok, raw_body},
      else: {:error, :too_large}
  end

  defp raw_body_or_empty(conn) do
    case conn.assigns[:raw_body] do
      chunks when is_list(chunks) -> chunks |> Enum.reverse() |> IO.iodata_to_binary()
      binary when is_binary(binary) -> binary
      _ -> ""
    end
  end

  defp bounded_id?(value), do: is_binary(value) and byte_size(value) in 1..255

  defp bounded_or_digest(value, raw_body),
    do: if(bounded_id?(value), do: value, else: digest(raw_body))

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  defp environment(%Verifier.Config{environment: environment}), do: environment
  defp environment(%{environment: environment}), do: environment
  defp verifier_version(%Verifier.Config{verifier_version: version}), do: version
  defp verifier_version(%{verifier_version: version}), do: version
  defp config_version(%Verifier.Config{config_version: version}), do: version
  defp config_version(%{config_version: version}), do: version

  defp respond(conn, status, response_class) do
    :telemetry.execute([:accrue, :entitlements, :apple, :notification], %{count: 1}, %{
      rail: :apple,
      response_class: response_class
    })

    conn |> send_resp(status, "") |> halt()
  end
end
