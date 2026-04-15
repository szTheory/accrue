defmodule Accrue.Events do
  @moduledoc """
  Append-only event ledger API (D-13, D-14, D-15, D-16).

  Every state mutation in Phase 2+ emits a corresponding row in
  `accrue_events` in the SAME transaction as the mutation. This module
  provides two entry points:

    * `record/1` — for use inside `Accrue.Repo.transact/1` blocks.
    * `record_multi/3` — for use inside `Ecto.Multi` pipelines.

  Both paths go through the same `Accrue.Events.Event.changeset/1`, and
  both honor the idempotency guarantee: a duplicate `idempotency_key`
  collapses to the existing row via `on_conflict: :nothing` plus a
  manual fetch fallback, so webhook replays are no-ops.

  ## Actor + trace_id auto-capture

  `record/1` reads `Accrue.Actor.current/0` and
  `Accrue.Telemetry.current_trace_id/0` from the process dictionary so
  upstream plugs (`Accrue.Plug.PutActor`, Phase 2) and Oban worker
  middleware can stamp events without the call site passing anything
  explicitly. Callers override either by passing `:actor` / `:trace_id`
  in the attrs map.

  ## Security

  > ⚠️ The `data` jsonb column is **not** automatically sanitized.
  > Callers MUST NOT put payment-method PII or secrets into `data`. A
  > redactor may land in Phase 6; Phase 1 deliberately accepts this
  > risk (T-EVT-03) and documents it here.

  Immutability is enforced at the Postgres layer by a
  `BEFORE UPDATE OR DELETE` trigger raising SQLSTATE `45A01`. This
  module translates the resulting `Postgrex.Error` into
  `Accrue.EventLedgerImmutableError` via pattern-match on the
  `pg_code` field — **never** by parsing the error message string (D-11).
  """

  alias Accrue.Actor
  alias Accrue.Events.Event
  alias Accrue.Events.UpcasterRegistry
  alias Accrue.Telemetry

  import Ecto.Query

  @type attrs :: %{
          optional(:type) => String.t(),
          optional(:subject_type) => String.t(),
          optional(:subject_id) => String.t(),
          optional(:schema_version) => integer(),
          optional(:actor) => Accrue.Actor.t() | nil,
          optional(:actor_type) => String.t() | atom(),
          optional(:actor_id) => String.t() | nil,
          optional(:data) => map(),
          optional(:trace_id) => String.t() | nil,
          optional(:idempotency_key) => String.t() | nil
        }

  @doc """
  Records a single event, returning `{:ok, %Event{}}` on success or
  propagating the underlying error on failure.

  Immutability violations (attempting to insert a row whose primary key
  collides with an existing row that the trigger then rejects on
  internal retry) are translated to `Accrue.EventLedgerImmutableError`
  via the Postgrex SQLSTATE `45A01` pattern-match — this is mostly
  defensive; `record/1` itself never updates or deletes. The stronger
  guarantee is that `Accrue.Repo.update/2` on an `Event` raises this
  error, which is what the immutability test asserts.

  ### Examples

      iex> Accrue.Events.record(%{
      ...>   type: "subscription.created",
      ...>   subject_type: "Subscription",
      ...>   subject_id: "sub_123"
      ...> })
      {:ok, %Accrue.Events.Event{type: "subscription.created", ...}}
  """
  @spec record(attrs()) :: {:ok, Event.t()} | {:error, term()}
  def record(attrs) when is_map(attrs) do
    normalized = normalize(attrs)
    changeset = Event.changeset(normalized)

    do_insert(changeset, normalized)
  rescue
    err in Postgrex.Error ->
      reraise_if_immutable(err, __STACKTRACE__)
  end

  @doc """
  Appends an event insert to an `Ecto.Multi` pipeline. Downstream plans
  (Phase 2 billing context) use this to commit a state mutation and its
  event record in the same transaction.

  ### Examples

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:subscription, subscription_changeset)
      |> Accrue.Events.record_multi(:event, %{
        type: "subscription.created",
        subject_type: "Subscription",
        subject_id: "sub_123"
      })
      |> Accrue.Repo.transact()
  """
  @spec record_multi(Ecto.Multi.t(), atom(), attrs()) :: Ecto.Multi.t()
  def record_multi(multi, name, attrs) when is_atom(name) and is_map(attrs) do
    normalized = normalize(attrs)
    changeset = Event.changeset(normalized)

    Ecto.Multi.insert(multi, name, changeset, insert_opts(normalized))
  end

  # Build insert opts. When an idempotency_key is present we use the
  # partial-unique-index conflict target via an unsafe fragment (the
  # index is `UNIQUE (idempotency_key) WHERE idempotency_key IS NOT NULL`
  # — Postgres requires the fragment to include the WHERE clause).
  defp insert_opts(%{idempotency_key: key}) when is_binary(key) do
    [
      on_conflict: :nothing,
      conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
      returning: true
    ]
  end

  defp insert_opts(_), do: [returning: true]

  # --- internals --------------------------------------------------------

  # Normalizes a caller-supplied attrs map: merges in actor context,
  # trace_id, default schema_version, default data. Caller-provided
  # values always win over process-dict defaults.
  @spec normalize(map()) :: map()
  defp normalize(attrs) do
    attrs
    |> Map.new()
    |> put_actor()
    |> put_trace_id()
    |> Map.put_new(:schema_version, 1)
    |> Map.put_new(:data, %{})
  end

  defp put_actor(attrs) do
    cond do
      Map.has_key?(attrs, :actor_type) ->
        attrs

      actor = Map.get(attrs, :actor) ->
        attrs
        |> Map.delete(:actor)
        |> Map.put(:actor_type, to_string(actor.type))
        |> Map.put(:actor_id, Map.get(actor, :id))

      current = Actor.current() ->
        attrs
        |> Map.put(:actor_type, to_string(current.type))
        |> Map.put(:actor_id, Map.get(current, :id))

      true ->
        attrs
        |> Map.put(:actor_type, "system")
        |> Map.put_new(:actor_id, nil)
    end
  end

  defp put_trace_id(attrs) do
    case Map.get(attrs, :trace_id) do
      nil -> Map.put(attrs, :trace_id, Telemetry.current_trace_id())
      _ -> attrs
    end
  end

  defp do_insert(changeset, %{idempotency_key: key} = attrs) when is_binary(key) do
    case Accrue.Repo.insert(changeset, insert_opts(attrs)) do
      {:ok, %Event{id: nil}} ->
        # Conflict no-op path — fetch the existing row by idempotency key.
        fetch_by_idempotency_key(key)

      {:ok, %Event{} = event} ->
        {:ok, event}

      {:error, _} = err ->
        err
    end
  end

  defp do_insert(changeset, attrs) do
    Accrue.Repo.insert(changeset, insert_opts(attrs))
  end

  defp fetch_by_idempotency_key(key) do
    query = from e in Event, where: e.idempotency_key == ^key, limit: 1

    case Accrue.Repo.one(query) do
      nil -> {:error, :idempotency_lookup_failed}
      event -> {:ok, event}
    end
  end

  # Per Pitfall #2 (01-RESEARCH.md): Postgrex 0.22 surfaces unknown
  # SQLSTATE codes on the `pg_code` key of the postgres error map, with
  # `code` set to `nil`. Our trigger raises `45A01` → we pattern-match
  # on `pg_code: "45A01"`. NEVER on message string (D-11).
  defp reraise_if_immutable(%Postgrex.Error{postgres: %{pg_code: "45A01"} = pg}, stacktrace) do
    reraise Accrue.EventLedgerImmutableError,
            [message: pg[:message], pg_code: "45A01"],
            stacktrace
  end

  defp reraise_if_immutable(%Postgrex.Error{postgres: %{code: :accrue_event_immutable} = pg}, stacktrace) do
    reraise Accrue.EventLedgerImmutableError,
            [message: pg[:message], pg_code: "45A01"],
            stacktrace
  end

  defp reraise_if_immutable(%Postgrex.Error{} = err, stacktrace) do
    reraise err, stacktrace
  end

  # --- Query API (EVT-06 / EVT-10 / Plan 04-06) -------------------------

  @doc """
  Returns events scoped to a single subject, ordered by `inserted_at`
  ascending. Each row is routed through the upcaster chain to the
  current schema version before returning (Pitfall 10).

  ## Options

    * `:limit` — max rows to return (default `1_000`)
  """
  @spec timeline_for(String.t(), String.t(), keyword()) :: [Event.t()]
  def timeline_for(subject_type, subject_id, opts \\ [])
      when is_binary(subject_type) and is_binary(subject_id) and is_list(opts) do
    limit = Keyword.get(opts, :limit, 1_000)

    from(e in Event,
      where: e.subject_type == ^subject_type and e.subject_id == ^subject_id,
      order_by: [asc: e.inserted_at, asc: e.id],
      limit: ^limit
    )
    |> Accrue.Repo.all()
    |> Enum.map(&upcast_to_current/1)
  end

  @doc """
  Reconstructs the projected `state` map for a subject as of a past
  timestamp by folding all events with `inserted_at <= ts`.

  Returns a map with `:state`, `:event_count`, and `:last_event_at`.

  Each row is routed through the upcaster chain BEFORE folding (Pitfall 10).
  """
  @spec state_as_of(String.t(), String.t(), DateTime.t()) :: %{
          state: map(),
          event_count: non_neg_integer(),
          last_event_at: DateTime.t() | nil
        }
  def state_as_of(subject_type, subject_id, %DateTime{} = ts)
      when is_binary(subject_type) and is_binary(subject_id) do
    events =
      from(e in Event,
        where:
          e.subject_type == ^subject_type and e.subject_id == ^subject_id and
            e.inserted_at <= ^ts,
        order_by: [asc: e.inserted_at, asc: e.id]
      )
      |> Accrue.Repo.all()
      |> Enum.map(&upcast_to_current/1)

    {state, last_at} =
      Enum.reduce(events, {%{}, nil}, fn e, {acc, _} ->
        {Map.merge(acc, e.data || %{}), e.inserted_at}
      end)

    %{state: state, event_count: length(events), last_event_at: last_at}
  end

  @doc """
  Buckets events by date_trunc'd `inserted_at` for the given filter.

  Returns a list of `{bucket_datetime, count}` tuples ordered by bucket.

  ## Filters

    * `:type` — single string or list of strings
    * `:since` / `:until` — DateTime bounds
    * `:subject_type` — string

  ## Bucket sizes

    * `:day`, `:week`, `:month`
  """
  @spec bucket_by(keyword(), :day | :week | :month) :: [{DateTime.t(), non_neg_integer()}]
  def bucket_by(filter, bucket) when is_list(filter) and bucket in [:day, :week, :month] do
    base = bucket_query(filter)

    case bucket do
      :day ->
        from(e in base,
          group_by: fragment("date_trunc('day', ?)", e.inserted_at),
          order_by: fragment("date_trunc('day', ?)", e.inserted_at),
          select: {fragment("date_trunc('day', ?)", e.inserted_at), count(e.id)}
        )

      :week ->
        from(e in base,
          group_by: fragment("date_trunc('week', ?)", e.inserted_at),
          order_by: fragment("date_trunc('week', ?)", e.inserted_at),
          select: {fragment("date_trunc('week', ?)", e.inserted_at), count(e.id)}
        )

      :month ->
        from(e in base,
          group_by: fragment("date_trunc('month', ?)", e.inserted_at),
          order_by: fragment("date_trunc('month', ?)", e.inserted_at),
          select: {fragment("date_trunc('month', ?)", e.inserted_at), count(e.id)}
        )
    end
    |> Accrue.Repo.all()
  end

  defp bucket_query(filter) do
    Enum.reduce(filter, from(e in Event), fn
      {:type, types}, q when is_list(types) -> where(q, [e], e.type in ^types)
      {:type, t}, q when is_binary(t) -> where(q, [e], e.type == ^t)
      {:subject_type, st}, q when is_binary(st) -> where(q, [e], e.subject_type == ^st)
      {:since, %DateTime{} = ts}, q -> where(q, [e], e.inserted_at >= ^ts)
      {:until, %DateTime{} = ts}, q -> where(q, [e], e.inserted_at <= ^ts)
    end)
  end

  defp upcast_to_current(%Event{} = event) do
    current = current_schema_version(event.type)
    from = event.schema_version || 1

    case UpcasterRegistry.chain(event.type, from, current) do
      {:ok, modules} ->
        data =
          Enum.reduce(modules, event.data || %{}, fn mod, acc ->
            case mod.upcast(acc) do
              {:ok, upcasted} -> upcasted
              {:error, reason} -> raise "upcaster #{inspect(mod)} failed: #{inspect(reason)}"
            end
          end)

        %{event | data: data, schema_version: current}

      {:error, {:unknown_schema_version, v}} ->
        :telemetry.execute(
          [:accrue, :ops, :events_upcast_failed],
          %{count: 1},
          %{event_id: event.id, type: event.type, schema_version: v}
        )

        raise ArgumentError,
              "unknown schema_version #{inspect(v)} for event type #{inspect(event.type)}"
    end
  end

  # Returns the current in-app schema version for an event type. Phase 3
  # ships everything at version 1; future schemas can return 2+ as their
  # payloads evolve. Defaults to 1 for unknown types.
  defp current_schema_version(_type), do: 1
end
