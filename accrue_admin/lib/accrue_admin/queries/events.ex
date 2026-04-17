defmodule AccrueAdmin.Queries.Events do
  @moduledoc """
  Cursor-paginated activity feed queries for the append-only event ledger.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Events.Event
  alias Accrue.Repo
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

    Event
    |> scope_query(owner_scope)
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
    owner_scope = Keyword.get(opts, :owner_scope)

    Event
    |> scope_query(owner_scope)
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

  defp scope_query(query, nil), do: query
  defp scope_query(query, %OwnerScope{mode: :global}), do: query

  defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      query,
      [event],
      fragment(
        """
        EXISTS (
          SELECT 1
          FROM accrue_customers customers
          WHERE ? = 'Customer'
            AND customers.id = ?
            AND customers.owner_type = 'Organization'
            AND customers.owner_id = ?
        )
        OR EXISTS (
          SELECT 1
          FROM accrue_subscriptions subscriptions
          JOIN accrue_customers customers ON customers.id = subscriptions.customer_id
          WHERE ? = 'Subscription'
            AND subscriptions.id = ?
            AND customers.owner_type = 'Organization'
            AND customers.owner_id = ?
        )
        OR EXISTS (
          SELECT 1
          FROM accrue_invoices invoices
          JOIN accrue_customers customers ON customers.id = invoices.customer_id
          WHERE ? = 'Invoice'
            AND invoices.id = ?
            AND customers.owner_type = 'Organization'
            AND customers.owner_id = ?
        )
        """,
        event.subject_type,
        event.subject_id,
        ^organization_id,
        event.subject_type,
        event.subject_id,
        ^organization_id,
        event.subject_type,
        event.subject_id,
        ^organization_id
      )
    )
  end
end
