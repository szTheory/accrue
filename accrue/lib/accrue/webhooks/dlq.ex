defmodule Accrue.Webhooks.DLQ do
  @moduledoc """
  Dead-letter queue replay and retention for webhook events (WH-08 / D4-04).

  Replay inserts a fresh Oban dispatch job. Oban's own `retry_job/2`
  refuses jobs in `:discarded`/`:cancelled` states, and dead-lettered
  webhook events correspond to exactly those — so the only correct path
  is to insert a brand-new job whose args reference the existing
  `WebhookEvent` row by id.

  ## Public API

    * `requeue/1` — single dead-lettered row → fresh dispatch job
    * `requeue_where/2` — bulk replay with batch + stagger + dry-run + max-rows cap
    * `list/2` — paginated browse for ops tooling
    * `count/1` — accurate count for confirm prompts
    * `prune/1` — delete `:dead` rows older than N days
    * `prune_succeeded/1` — delete `:succeeded` rows older than N days

  Each public function ships in dual bang/tuple form per the D-05
  convention.

  ## Replay-death-loop prevention

  When a replayed event re-enters the dispatch worker and the processor
  fetch returns `{:error, :not_found}` (e.g., the underlying upstream
  resource has been deleted since the original failure), the worker
  treats it as terminal-skip — status becomes `:replayed`, no
  re-dead-letter — so a single bad row cannot loop forever.
  """

  import Ecto.Query

  alias Accrue.Config
  alias Accrue.Events
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent

  @type filter ::
          [
            type: String.t() | [String.t()],
            since: DateTime.t(),
            until: DateTime.t(),
            livemode: boolean()
          ]

  @type replay_opts ::
          [
            batch_size: pos_integer(),
            stagger_ms: non_neg_integer(),
            dry_run: boolean(),
            force: boolean()
          ]

  @type replay_error ::
          :not_found
          | :already_replayed
          | :not_dead_lettered
          | :replay_too_large
          | term()

  # --- requeue/1 --------------------------------------------------------

  @spec requeue(Ecto.UUID.t()) ::
          {:ok, WebhookEvent.t()} | {:error, replay_error()}
  def requeue(id) when is_binary(id) do
    case do_requeue(id) do
      {:ok, _} = ok ->
        :telemetry.execute(
          [:accrue, :ops, :webhook_dlq, :replay],
          %{count: 1},
          %{event_id: id, actor: :replay}
        )

        ok

      {:error, _} = err ->
        err
    end
  end

  @spec requeue!(Ecto.UUID.t()) :: WebhookEvent.t()
  def requeue!(id), do: unwrap!(requeue(id))

  defp do_requeue(id) do
    case fetch_replayable(id) do
      {:ok, row} -> commit_requeue(row)
      {:error, _} = err -> err
    end
  end

  defp fetch_replayable(id) do
    case Repo.get(WebhookEvent, id) do
      nil -> {:error, :not_found}
      %WebhookEvent{status: :replayed} -> {:error, :already_replayed}
      %WebhookEvent{status: status} = row when status in [:dead, :failed] -> {:ok, row}
      %WebhookEvent{} -> {:error, :not_dead_lettered}
    end
  end

  defp commit_requeue(%WebhookEvent{} = row) do
    Repo.transact(fn ->
      with {:ok, updated} <-
             row
             |> WebhookEvent.status_changeset(:received)
             |> Repo.update(),
           {:ok, _job} <-
             Oban.insert(
               Accrue.Webhook.DispatchWorker.new(%{"webhook_event_id" => updated.id})
             ),
           {:ok, _ev} <-
             Events.record(%{
               type: "webhook.replay_requested",
               subject_type: "WebhookEvent",
               subject_id: updated.id,
               actor_type: "admin",
               data: %{
                 "original_processor_event_id" => row.processor_event_id,
                 "original_status" => Atom.to_string(row.status)
               },
               idempotency_key: "replay:" <> row.processor_event_id
             }) do
        {:ok, updated}
      end
    end)
  end

  # --- requeue_where/2 --------------------------------------------------

  @spec requeue_where(filter(), replay_opts()) ::
          {:ok, map()} | {:error, :replay_too_large | term()}
  def requeue_where(filter, opts \\ []) when is_list(filter) and is_list(opts) do
    batch_size = Keyword.get(opts, :batch_size, Config.dlq_replay_batch_size())
    stagger_ms = Keyword.get(opts, :stagger_ms, Config.dlq_replay_stagger_ms())
    dry_run? = Keyword.get(opts, :dry_run, false)
    force? = Keyword.get(opts, :force, false)
    max_rows = Config.dlq_replay_max_rows()

    base_query =
      filter
      |> build_query()
      |> where([w], w.status in [:dead, :failed])

    total = Repo.aggregate(base_query, :count, :id)

    cond do
      total > max_rows and not force? ->
        {:error, :replay_too_large}

      dry_run? ->
        {:ok, %{requeued: 0, skipped: 0, would_requeue: total}}

      true ->
        bulk_requeue(base_query, batch_size, stagger_ms)
    end
  end

  @spec requeue_where!(filter(), replay_opts()) :: %{
          requeued: non_neg_integer(),
          skipped: non_neg_integer()
        }
  def requeue_where!(filter, opts \\ []), do: unwrap!(requeue_where(filter, opts))

  defp bulk_requeue(query, batch_size, stagger_ms) do
    rows = Repo.all(query)

    {requeued, skipped} =
      rows
      |> Stream.chunk_every(batch_size)
      |> Enum.reduce({0, 0}, fn chunk, {req, skip} ->
        {chunk_req, chunk_skip} =
          Enum.reduce(chunk, {0, 0}, fn row, {r, s} ->
            case requeue(row.id) do
              {:ok, _} -> {r + 1, s}
              {:error, _} -> {r, s + 1}
            end
          end)

        if stagger_ms > 0, do: Process.sleep(stagger_ms)
        {req + chunk_req, skip + chunk_skip}
      end)

    {:ok, %{requeued: requeued, skipped: skipped}}
  end

  # --- list/2 + count/1 -------------------------------------------------

  @spec list(filter(), keyword()) :: [WebhookEvent.t()]
  def list(filter, opts \\ []) when is_list(filter) and is_list(opts) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    filter
    |> build_query()
    |> order_by([w], desc: w.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @spec count(filter()) :: non_neg_integer()
  def count(filter) when is_list(filter) do
    filter
    |> build_query()
    |> Repo.aggregate(:count, :id)
  end

  # --- prune/1 + prune_succeeded/1 --------------------------------------

  @spec prune(pos_integer() | :infinity) :: {:ok, non_neg_integer()}
  def prune(:infinity), do: {:ok, 0}

  def prune(days) when is_integer(days) and days > 0 do
    cutoff = DateTime.add(DateTime.utc_now(), -days * 86_400, :second)

    {count, _} =
      from(w in WebhookEvent,
        where: w.status == :dead and w.inserted_at < ^cutoff
      )
      |> Repo.repo().delete_all()

    {:ok, count}
  end

  @spec prune_succeeded(pos_integer() | :infinity) :: {:ok, non_neg_integer()}
  def prune_succeeded(:infinity), do: {:ok, 0}

  def prune_succeeded(days) when is_integer(days) and days > 0 do
    cutoff = DateTime.add(DateTime.utc_now(), -days * 86_400, :second)

    {count, _} =
      from(w in WebhookEvent,
        where: w.status == :succeeded and w.inserted_at < ^cutoff
      )
      |> Repo.repo().delete_all()

    {:ok, count}
  end

  # --- private ----------------------------------------------------------

  defp build_query(filter) do
    Enum.reduce(filter, from(w in WebhookEvent), fn
      {:type, types}, q when is_list(types) ->
        where(q, [w], w.type in ^types)

      {:type, t}, q when is_binary(t) ->
        where(q, [w], w.type == ^t)

      {:since, %DateTime{} = ts}, q ->
        where(q, [w], w.inserted_at >= ^ts)

      {:until, %DateTime{} = ts}, q ->
        where(q, [w], w.inserted_at <= ^ts)

      {:livemode, lm}, q when is_boolean(lm) ->
        where(q, [w], w.livemode == ^lm)

      {:status, s}, q when is_atom(s) ->
        where(q, [w], w.status == ^s)
    end)
  end

  defp unwrap!({:ok, value}), do: value
  defp unwrap!({:error, reason}), do: raise("Accrue.Webhooks.DLQ failed: #{inspect(reason)}")
end
