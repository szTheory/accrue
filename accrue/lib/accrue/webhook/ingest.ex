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
  """
  @spec run(Plug.Conn.t(), atom(), LatticeStripe.Event.t(), binary()) :: Plug.Conn.t()
  def run(conn, processor, stripe_event, raw_body) do
    processor_str = to_string(processor)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:persist, fn repo, _changes ->
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
      end)
      |> Ecto.Multi.run(:maybe_enqueue, fn _repo, %{persist: result} ->
        case result do
          {:new, row} ->
            job_changeset = DispatchWorker.new(%{webhook_event_id: row.id})
            Oban.insert(job_changeset)

          {:duplicate, _} ->
            {:ok, :skipped}
        end
      end)
      |> Ecto.Multi.run(:maybe_ledger, fn _repo, %{persist: result} ->
        case result do
          {:new, row} ->
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

          {:duplicate, _} ->
            {:ok, :skipped}
        end
      end)

    case Accrue.Repo.transaction(multi) do
      {:ok, %{persist: {:new, _}}} ->
        conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

      {:ok, %{persist: {:duplicate, _}}} ->
        conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

      {:error, _step, reason, _changes} ->
        Logger.error("Webhook ingest failed: #{inspect(reason, limit: 200)}")
        conn |> send_resp(500, Jason.encode!(%{ok: false})) |> halt()
    end
  end
end
