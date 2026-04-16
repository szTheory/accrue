defmodule Accrue.Webhook.Ingest do
  @moduledoc """
  Transactional webhook event persistence and Oban job dispatch (D2-24).

  All three writes (webhook_event row, Oban job, accrue_events ledger entry)
  succeed atomically or none do. Duplicate POSTs are idempotent via the
  `UNIQUE(processor, processor_event_id)` constraint with `on_conflict: :nothing`.

  ## Transaction shape

      Ecto.Multi
      |> run(:persist, ...)           # check-then-insert with on_conflict guard
      |> run(:maybe_enqueue, ...)     # Oban job only for new events
      |> run(:maybe_ledger, ...)      # accrue_events only for new events

  Duplicate detection uses an explicit SELECT-then-INSERT pattern inside a
  single `Multi.run` step. The `on_conflict: :nothing` guard on the INSERT
  handles the race condition where a concurrent request inserts between
  SELECT and INSERT. With binary_id autogenerate, Ecto generates UUIDs
  client-side, so the Pitfall 2 approach (`id: nil` on conflict) does not
  work -- the struct always has an id regardless of conflict.
  """

  alias Accrue.Webhook.{WebhookEvent, DispatchWorker}
  alias Accrue.Events

  import Plug.Conn

  require Logger

  @doc """
  Runs the transactional ingest pipeline for a verified webhook event.

  Called by `Accrue.Webhook.Plug` after signature verification succeeds.
  Returns the `Plug.Conn` with a 200 (success or duplicate) or 500 (failure).

  ## Endpoint

  Phase 5 (05-01, D5-01): the optional `endpoint` argument is persisted on
  the `accrue_webhook_events` row so `Accrue.Webhook.DispatchWorker` can
  branch on it and route `:connect`-scoped events to
  `Accrue.Webhook.ConnectHandler`. Accepts either the atom `:connect` (which
  persists as `:connect`) or any other value (persists as `:default`) so
  existing Phase 2-4 multi-endpoint configs using names like `:primary` or
  `:unconfigured` continue to land in the default lane without needing a
  schema migration per endpoint name.
  """
  @spec run(Plug.Conn.t(), atom(), LatticeStripe.Event.t(), binary(), atom() | nil) ::
          Plug.Conn.t()
  def run(conn, processor, stripe_event, raw_body, endpoint \\ nil) do
    processor_str = to_string(processor)
    endpoint_atom = normalize_endpoint(endpoint)

    result =
      Accrue.Repo.transact(fn repo ->
        case persist_event(repo, processor_str, stripe_event, raw_body, endpoint_atom) do
          {:ok, {:duplicate, _} = duplicate} ->
            {:ok, duplicate}

          {:ok, {:new, row} = persisted} ->
            with {:ok, _job} <- repo.insert(DispatchWorker.new(%{webhook_event_id: row.id})),
                 {:ok, _event} <- record_received_event(processor_str, stripe_event, row) do
              {:ok, persisted}
            else
              {:error, reason} -> {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end
      end)

    case result do
      {:ok, {:new, _}} ->
        conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

      {:ok, {:duplicate, _}} ->
        conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

      {:error, reason} ->
        Logger.error("Webhook ingest failed: #{inspect(reason, limit: 200)}")
        conn |> send_resp(500, Jason.encode!(%{ok: false})) |> halt()
    end
  end

  defp persist_event(repo, processor_str, stripe_event, raw_body, endpoint_atom) do
    # Check for existing event first (dedup via UNIQUE constraint).
    # With binary_id autogenerate, on_conflict: :nothing + returning: true
    # returns the changeset struct (not nil id) because Ecto generates
    # the UUID client-side. So we use an explicit check-then-insert pattern.
    import Ecto.Query

    existing =
      repo.one(
        from(w in WebhookEvent,
          where: w.processor == ^processor_str and w.processor_event_id == ^stripe_event.id,
          limit: 1
        )
      )

    case existing do
      %WebhookEvent{} ->
        {:ok, {:duplicate, existing}}

      nil ->
        changeset =
          WebhookEvent.ingest_changeset(%{
            processor: processor_str,
            processor_event_id: stripe_event.id,
            type: stripe_event.type,
            livemode: stripe_event.livemode,
            status: :received,
            endpoint: endpoint_atom,
            raw_body: raw_body,
            received_at: DateTime.utc_now(),
            data: Map.from_struct(stripe_event)
          })

        case repo.insert(changeset,
               on_conflict: :nothing,
               conflict_target: [:processor, :processor_event_id]
             ) do
          {:ok, row} -> {:ok, {:new, row}}
          {:error, _} = err -> err
        end
    end
  end

  defp record_received_event(processor_str, stripe_event, %WebhookEvent{} = row) do
    Events.record(%{
      type: "webhook.received",
      subject_type: "WebhookEvent",
      subject_id: to_string(row.id),
      actor_type: "webhook",
      data: %{
        processor: processor_str,
        event_id: stripe_event.id,
        event_type: stripe_event.type
      }
    })
  end

  # D5-01: Only `:connect` maps to the Connect-scoped endpoint lane; every
  # other endpoint name (`nil`, `:primary`, `:default`, `:unconfigured`,
  # custom names) persists as `:default`. Keeps the schema enum minimal
  # and preserves Phase 2-4 single-endpoint semantics for callers that
  # still use `run/4`.
  @spec normalize_endpoint(atom() | nil) :: :default | :connect
  defp normalize_endpoint(:connect), do: :connect
  defp normalize_endpoint(_), do: :default
end
