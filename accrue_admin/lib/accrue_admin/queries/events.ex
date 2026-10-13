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
  alias AccrueAdmin.Queries.Webhooks

  @time_field :inserted_at
  @webhook_subject_types ["WebhookEvent", "WebhookBatch"]
  @customers_table Accrue.Migration.qualified_table(:accrue_customers)
  @subscriptions_table Accrue.Migration.qualified_table(:accrue_subscriptions)
  @invoices_table Accrue.Migration.qualified_table(:accrue_invoices)
  @charges_table Accrue.Migration.qualified_table(:accrue_charges)
  @organization_scope_sql """
  EXISTS (
    SELECT 1
    FROM #{@customers_table} customers
    WHERE ? = 'Customer'
      AND customers.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  OR EXISTS (
    SELECT 1
    FROM #{@subscriptions_table} subscriptions
    JOIN #{@customers_table} customers ON customers.id = subscriptions.customer_id
    WHERE ? = 'Subscription'
      AND subscriptions.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  OR EXISTS (
    SELECT 1
    FROM #{@invoices_table} invoices
    JOIN #{@customers_table} customers ON customers.id = invoices.customer_id
    WHERE ? = 'Invoice'
      AND invoices.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  OR EXISTS (
    SELECT 1
    FROM #{@charges_table} charges
    JOIN #{@customers_table} customers ON customers.id = charges.customer_id
    WHERE ? = 'Charge'
      AND charges.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  """

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

    query =
      Event
      |> filter_query(filter)
      |> Behaviour.apply_cursor(@time_field, cursor)
      |> order_by([event], desc: event.inserted_at, desc: event.id)

    case owner_scope do
      %OwnerScope{mode: :organization} = scope ->
        query
        |> organization_page(scope, limit)
        |> Behaviour.paginate(limit, @time_field)

      _global_or_unscoped ->
        query
        |> scope_query(owner_scope)
        |> limit(^Enum.max([limit + 1, 2]))
        |> select_event_rows()
        |> Repo.all()
        |> Enum.map(&Map.delete(&1, :data))
        |> Behaviour.paginate(limit, @time_field)
    end
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

    query = Event |> filter_query(filter) |> Behaviour.count_newer(@time_field, cursor)

    case owner_scope do
      %OwnerScope{mode: :organization} = scope ->
        scoped_count = query |> scope_query(scope) |> Repo.aggregate(:count)

        webhook_count =
          query
          |> where([event], event.subject_type in ^@webhook_subject_types)
          |> select_event_rows()
          |> Repo.all()
          |> Enum.count(&webhook_event_in_scope?(&1, scope))

        scoped_count + webhook_count

      _global_or_unscoped ->
        query |> scope_query(owner_scope) |> Repo.aggregate(:count)
    end
  end

  def scoped_base_query(owner_scope) do
    Event
    |> scope_query(owner_scope)
  end

  def detail(id, owner_scope) when is_binary(id) do
    case Integer.parse(id) do
      {event_id, ""} -> detail(event_id, owner_scope)
      _ -> :not_found
    end
  end

  def detail(id, owner_scope) when is_integer(id) do
    case Event |> scope_query(owner_scope) |> where([event], event.id == ^id) |> Repo.one() do
      nil -> webhook_event_detail(id, owner_scope)
      event -> {:ok, event}
    end
  end

  defp webhook_event_detail(id, %OwnerScope{mode: :organization} = scope) do
    event =
      from(event in Event,
        where: event.id == ^id and event.subject_type in ^@webhook_subject_types
      )
      |> Repo.one()

    if event && webhook_event_in_scope?(event, scope), do: {:ok, event}, else: :not_found
  end

  defp webhook_event_detail(_id, _owner_scope), do: :not_found

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
        where(
          query,
          [event],
          event.caused_by_webhook_event_id == ^webhook_event_id or
            (event.subject_type == "WebhookEvent" and event.subject_id == ^webhook_event_id)
        )

      {_unknown, _value}, query ->
        query
    end)
  end

  defp organization_page(query, scope, limit) do
    scoped_rows =
      query
      |> scope_query(scope)
      |> limit(^Enum.max([limit + 1, 2]))
      |> select_event_rows()
      |> Repo.all()

    webhook_rows =
      query
      |> where([event], event.subject_type in ^@webhook_subject_types)
      |> select_event_rows()
      |> Repo.all()
      |> Enum.filter(&webhook_event_in_scope?(&1, scope))

    (scoped_rows ++ webhook_rows)
    |> Enum.sort(&newer_event?/2)
    |> Enum.take(Enum.max([limit + 1, 2]))
    |> Enum.map(&Map.delete(&1, :data))
  end

  defp select_event_rows(query) do
    select(query, [event], %{
      id: event.id,
      type: event.type,
      actor_type: event.actor_type,
      actor_id: event.actor_id,
      subject_type: event.subject_type,
      subject_id: event.subject_id,
      caused_by_event_id: event.caused_by_event_id,
      caused_by_webhook_event_id: event.caused_by_webhook_event_id,
      inserted_at: event.inserted_at,
      data: event.data
    })
  end

  defp webhook_event_in_scope?(%{subject_type: "WebhookEvent", subject_id: id}, scope)
       when is_binary(id) do
    match?({:ok, _webhook}, Webhooks.detail(id, scope))
  end

  defp webhook_event_in_scope?(%{subject_type: "WebhookBatch", data: %{"ids" => ids}}, scope)
       when is_list(ids) and ids != [] do
    Enum.all?(ids, fn id -> match?({:ok, _webhook}, Webhooks.detail(id, scope)) end)
  end

  defp webhook_event_in_scope?(_event, _scope), do: false

  defp newer_event?(left, right) do
    case DateTime.compare(left.inserted_at, right.inserted_at) do
      :gt -> true
      :lt -> false
      :eq -> left.id > right.id
    end
  end

  defp scope_query(query, nil), do: query
  defp scope_query(query, %OwnerScope{mode: :global}), do: query

  defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      query,
      [event],
      fragment(
        @organization_scope_sql,
        event.subject_type,
        event.subject_id,
        ^organization_id,
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
