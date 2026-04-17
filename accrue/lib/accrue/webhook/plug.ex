defmodule Accrue.Webhook.Plug do
  @moduledoc """
  Core webhook ingestion plug (D2-26).

  Processes incoming webhook requests by:

  1. Extracting the raw body from `conn.assigns[:raw_body]` (populated
     by `Accrue.Webhook.CachingBodyReader` in the pipeline)
  2. Verifying the `Stripe-Signature` header via `Accrue.Webhook.Signature`
  3. Projecting the verified event into `%Accrue.Webhook.Event{}`
  4. Storing the verified event and raw body in `conn.private` for
     downstream processing

  Signature failures raise `Accrue.SignatureError`, rescued to HTTP 400.

  ## Transactional pipeline

  After verification, `Accrue.Webhook.Ingest.run/4` atomically persists the
  webhook event, enqueues an Oban dispatch job, and records an accrue_events
  ledger entry -- all in a single `Ecto.Multi` transaction (D2-24).
  """

  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Accrue.Webhook.Signature

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    processor = Keyword.fetch!(opts, :processor)
    endpoint = Keyword.get(opts, :endpoint)

    :telemetry.span(
      [:accrue, :webhook, :receive],
      %{processor: processor, endpoint: endpoint},
      fn ->
        result = do_call(conn, processor, endpoint)
        {result, %{processor: processor, endpoint: endpoint}}
      end
    )
  rescue
    e in Accrue.SignatureError ->
      Logger.warning("Webhook signature verification failed: #{e.reason}")

      conn
      |> send_resp(400, Jason.encode!(%{error: "signature_verification_failed"}))
      |> halt()

    e in Accrue.ConfigError ->
      Logger.error("Webhook setup error:\n" <> Exception.message(e))

      conn
      |> send_resp(500, Jason.encode!(%{error: "internal_server_error"}))
      |> halt()
  end

  defp do_call(conn, processor, endpoint) do
    raw_body = flatten_raw_body(conn)
    sig_header = get_req_header(conn, "stripe-signature") |> List.first()

    unless sig_header do
      raise Accrue.SignatureError, reason: "missing stripe-signature header"
    end

    secrets = resolve_secrets!(endpoint, processor)
    stripe_event = Signature.verify!(raw_body, sig_header, secrets)

    # Transactional persist + Oban enqueue (D2-24, Plan 04).
    # Event projection happens inside DispatchWorker from the persisted row.
    # D5-01: thread `endpoint` through so DispatchWorker can branch on it.
    Accrue.Webhook.Ingest.run(conn, processor, stripe_event, raw_body, endpoint)
  end

  # Endpoint-aware secret resolution (WH-13).
  #
  # Multi-endpoint mode: when `endpoint:` is passed via the plug init opts,
  # look up `[:webhook_endpoints, endpoint, :secret]` from `Accrue.Config`.
  # If the endpoint is missing, raise `Accrue.SignatureError` (rescued to 400)
  # — fail closed, never bypass verification (T-04-06-01).
  #
  # Legacy mode (Phase 2 callers): when no `endpoint:` is set, fall back to
  # `Accrue.Config.webhook_signing_secrets/1` keyed by processor atom.
  defp resolve_secrets!(nil, processor), do: Accrue.Config.webhook_signing_secrets(processor)

  defp resolve_secrets!(endpoint, _processor) when is_atom(endpoint) do
    endpoints = Accrue.Config.webhook_endpoints()

    case Keyword.get(endpoints, endpoint) do
      nil ->
        raise Accrue.SignatureError,
          reason: "no webhook_endpoints config for endpoint #{inspect(endpoint)}"

      cfg when is_list(cfg) ->
        case Keyword.fetch(cfg, :secret) do
          {:ok, secret} when is_binary(secret) and secret != "" ->
            secret

          {:ok, secrets} when is_list(secrets) and secrets != [] ->
            secrets

          _ ->
            raise Accrue.SignatureError,
              reason: "no :secret in webhook_endpoints[#{inspect(endpoint)}]"
        end
    end
  end

  @doc false
  def flatten_raw_body(conn) do
    case conn.assigns[:raw_body] do
      nil ->
        diagnostic =
          Accrue.SetupDiagnostic.webhook_raw_body(
            details:
              "Expected conn.assigns[:raw_body]; configure body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}"
          )

        raise Accrue.ConfigError, key: :webhook_signing_secrets, diagnostic: diagnostic

      chunks when is_list(chunks) ->
        chunks |> Enum.reverse() |> IO.iodata_to_binary()

      binary when is_binary(binary) ->
        binary
    end
  end
end
