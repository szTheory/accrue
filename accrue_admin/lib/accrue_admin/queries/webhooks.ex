defmodule AccrueAdmin.Queries.Webhooks do
  @moduledoc """
  Cursor-paginated webhook event queries for admin ops surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.Queries.Behaviour

  @time_field :received_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    WebhookEvent
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([event], desc: event.received_at, desc: event.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([event], %{
      id: event.id,
      processor: event.processor,
      processor_event_id: event.processor_event_id,
      type: event.type,
      status: event.status,
      endpoint: event.endpoint,
      livemode: event.livemode,
      received_at: event.received_at,
      processed_at: event.processed_at,
      inserted_at: event.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)

    WebhookEvent
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  @impl true
  def decode_filter(params) when is_map(params) do
    %{
      type: Behaviour.normalize_string(Map.get(params, "type") || Map.get(params, :type)),
      status: decode_status(Map.get(params, "status") || Map.get(params, :status)),
      livemode: Behaviour.parse_boolean(Map.get(params, "livemode") || Map.get(params, :livemode))
    }
    |> Behaviour.compact_filter()
  end

  @impl true
  def encode_filter(filter) when is_map(filter) do
    filter
    |> Enum.into(%{}, fn
      {:status, value} when is_atom(value) -> {"status", Atom.to_string(value)}
      {:livemode, value} when is_boolean(value) -> {"livemode", to_string(value)}
      {key, value} -> {to_string(key), value}
    end)
    |> Behaviour.compact_filter()
  end

  def detail(id) when is_binary(id) do
    Repo.get(WebhookEvent, id)
  end

  defp filter_query(query, filter) do
    Enum.reduce(filter, query, fn
      {:type, type}, query ->
        where(query, [event], event.type == ^type)

      {:status, status}, query ->
        where(query, [event], event.status == ^status)

      {:livemode, livemode}, query ->
        where(query, [event], event.livemode == ^livemode)

      {_unknown, _value}, query ->
        query
    end)
  end

  defp decode_status(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        nil

      status ->
        try do
          String.to_existing_atom(status)
        rescue
          ArgumentError -> nil
        end
    end
  end

  defp decode_status(value) when is_atom(value), do: value
  defp decode_status(_value), do: nil
end
