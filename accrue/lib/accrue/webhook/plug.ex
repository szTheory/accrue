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

    :telemetry.span([:accrue, :webhook, :receive], %{processor: processor}, fn ->
      result = do_call(conn, processor)
      {result, %{processor: processor}}
    end)
  rescue
    e in Accrue.SignatureError ->
      Logger.warning("Webhook signature verification failed: #{e.reason}")

      conn
      |> send_resp(400, Jason.encode!(%{error: "signature_verification_failed"}))
      |> halt()
  end

  defp do_call(conn, processor) do
    raw_body = flatten_raw_body(conn)
    sig_header = get_req_header(conn, "stripe-signature") |> List.first()

    unless sig_header do
      raise Accrue.SignatureError, reason: "missing stripe-signature header"
    end

    secrets = Accrue.Config.webhook_signing_secrets(processor)
    stripe_event = Signature.verify!(raw_body, sig_header, secrets)

    # Transactional persist + Oban enqueue (D2-24, Plan 04).
    # Event projection happens inside DispatchWorker from the persisted row.
    Accrue.Webhook.Ingest.run(conn, processor, stripe_event, raw_body)
  end

  @doc false
  def flatten_raw_body(conn) do
    case conn.assigns[:raw_body] do
      nil -> ""
      chunks when is_list(chunks) -> chunks |> Enum.reverse() |> IO.iodata_to_binary()
      binary when is_binary(binary) -> binary
    end
  end
end
