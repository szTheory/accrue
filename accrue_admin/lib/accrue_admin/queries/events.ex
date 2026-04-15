defmodule AccrueAdmin.Queries.Events do
  @moduledoc """
  Cursor-paginated activity feed queries for the append-only event ledger.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Events.Event
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    Event
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([event], desc: event.inserted_at, desc: event.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([event], %{
      id: event.id,
      type: event.type,
      actor_type: event.actor_type,
      actor_id: event.actor_id,
      subject_type: event.subject_type,
      subject_id: event.subject_id,
      caused_by_event_id: event.caused_by_event_id,
      caused_by_webhook_event_id: event.caused_by_webhook_event_id,
      inserted_at: event.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)

    Event
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  @impl true
  def decode_filter(params) when is_map(params) do
    %{
      q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
      type: Behaviour.normalize_string(Map.get(params, "type") || Map.get(params, :type)),
      actor_type:
        Behaviour.normalize_string(Map.get(params, "actor_type") || Map.get(params, :actor_type)),
      subject_type:
        Behaviour.normalize_string(
          Map.get(params, "subject_type") || Map.get(params, :subject_type)
        ),
      source_webhook_event_id:
        Behaviour.normalize_string(
          Map.get(params, "source_webhook_event_id") ||
            Map.get(params, :source_webhook_event_id)
        )
    }
    |> Behaviour.compact_filter()
  end

  @impl true
  def encode_filter(filter) when is_map(filter) do
    filter
    |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
    |> Behaviour.compact_filter()
  end

  defp filter_query(query, filter) do
    Enum.reduce(filter, query, fn
      {:q, term}, query ->
        pattern = "%#{term}%"

        where(
          query,
          [event],
          ilike(event.type, ^pattern) or
            ilike(event.subject_id, ^pattern) or
            ilike(event.actor_id, ^pattern)
        )

      {:type, type}, query ->
        where(query, [event], event.type == ^type)

      {:actor_type, actor_type}, query ->
        where(query, [event], event.actor_type == ^actor_type)

      {:subject_type, subject_type}, query ->
        where(query, [event], event.subject_type == ^subject_type)

      {:source_webhook_event_id, webhook_event_id}, query ->
        where(query, [event], event.caused_by_webhook_event_id == ^webhook_event_id)

      {_unknown, _value}, query ->
        query
    end)
  end
end
