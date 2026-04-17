defmodule AccrueAdmin.Queries.Webhooks do
  @moduledoc """
  Cursor-paginated webhook event queries for admin ops surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice, Subscription}
  alias Accrue.Repo
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Behaviour

  @time_field :received_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

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
    |> scope_rows(owner_scope)
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

    WebhookEvent
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.all()
    |> scope_rows(owner_scope)
    |> length()
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

  def detail(id, owner_scope) when is_binary(id) do
    case Repo.get(WebhookEvent, id) do
      nil -> :not_found
      webhook -> prove_row_scope(webhook, owner_scope)
    end
  end

  def bulk_replay_count(owner_scope, filter) when is_map(filter) do
    WebhookEvent
    |> filter_query(filter)
    |> Repo.all()
    |> scope_rows(owner_scope)
    |> Enum.count(fn webhook -> webhook.status in [:failed, :dead] end)
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

  defp scope_rows(rows, nil), do: rows
  defp scope_rows(rows, %OwnerScope{mode: :global}), do: rows

  defp scope_rows(rows, %OwnerScope{} = owner_scope) do
    rows
    |> Enum.filter(fn row ->
      match?({:ok, _webhook}, prove_row_scope(row, owner_scope))
    end)
  end

  defp prove_row_scope(%WebhookEvent{} = webhook, nil), do: {:ok, webhook}
  defp prove_row_scope(%WebhookEvent{} = webhook, %OwnerScope{mode: :global}), do: {:ok, webhook}

  defp prove_row_scope(%WebhookEvent{} = webhook, %OwnerScope{mode: :organization} = owner_scope) do
    matches = ownership_matches(webhook)
    scoped_matches = Enum.filter(matches, &(&1.owner_id == owner_scope.organization_id))
    out_of_scope_matches = Enum.reject(matches, &(&1.owner_id == owner_scope.organization_id))

    cond do
      scoped_matches != [] and out_of_scope_matches == [] ->
        {:ok, webhook}

      scoped_matches == [] and out_of_scope_matches != [] ->
        :not_found

      true ->
        {:ambiguous,
         %{
           webhook_id: webhook.id,
           owner_matches: Enum.map(matches, &Map.take(&1, [:owner_id, :source, :subject_type]))
         }}
    end
  end

  defp ownership_matches(%WebhookEvent{} = webhook) do
    ([invoice_match(webhook)] ++ [subscription_match(webhook)] ++ [customer_match(webhook)] ++
       event_matches(webhook))
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq_by(&{&1.owner_id, &1.source, &1.subject_type})
  end

  defp invoice_match(webhook) do
    object_id = payload_object_id(webhook)

    if is_binary(object_id) do
      Invoice
      |> where([invoice], invoice.processor_id == ^object_id)
      |> maybe_match_binary_id(object_id)
      |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
      |> select([_invoice, customer], %{
        owner_id: customer.owner_id,
        source: :invoice,
        subject_type: "Invoice"
      })
      |> limit(1)
      |> Repo.one()
    end
  end

  defp subscription_match(webhook) do
    object_id = payload_object_id(webhook)

    if is_binary(object_id) do
      Subscription
      |> where([subscription], subscription.processor_id == ^object_id)
      |> maybe_match_binary_id(object_id)
      |> join(:inner, [subscription], customer in Customer, on: customer.id == subscription.customer_id)
      |> select([_subscription, customer], %{
        owner_id: customer.owner_id,
        source: :subscription,
        subject_type: "Subscription"
      })
      |> limit(1)
      |> Repo.one()
    end
  end

  defp customer_match(webhook) do
    customer_ref = payload_customer_id(webhook)

    if is_binary(customer_ref) do
      Customer
      |> where([customer], customer.processor_id == ^customer_ref)
      |> maybe_match_binary_id(customer_ref)
      |> select([customer], %{
        owner_id: customer.owner_id,
        source: :customer,
        subject_type: "Customer"
      })
      |> limit(1)
      |> Repo.one()
    end
  end

  defp event_matches(webhook) do
    from(event in Event,
      where: event.caused_by_webhook_event_id == ^webhook.id,
      select: %{subject_type: event.subject_type, subject_id: event.subject_id}
    )
    |> Repo.all()
    |> Enum.map(&event_subject_match/1)
    |> Enum.reject(&is_nil/1)
  end

  defp event_subject_match(%{subject_type: "Customer", subject_id: subject_id}) do
    from(customer in Customer,
      where: customer.id == ^subject_id,
      select: %{
        owner_id: customer.owner_id,
        source: :event_subject,
        subject_type: "Customer"
      },
      limit: 1
    )
    |> Repo.one()
  end

  defp event_subject_match(%{subject_type: "Subscription", subject_id: subject_id}) do
    from(subscription in Subscription,
      join: customer in Customer,
      on: customer.id == subscription.customer_id,
      where: subscription.id == ^subject_id,
      select: %{
        owner_id: customer.owner_id,
        source: :event_subject,
        subject_type: "Subscription"
      },
      limit: 1
    )
    |> Repo.one()
  end

  defp event_subject_match(%{subject_type: "Invoice", subject_id: subject_id}) do
    from(invoice in Invoice,
      join: customer in Customer,
      on: customer.id == invoice.customer_id,
      where: invoice.id == ^subject_id,
      select: %{
        owner_id: customer.owner_id,
        source: :event_subject,
        subject_type: "Invoice"
      },
      limit: 1
    )
    |> Repo.one()
  end

  defp event_subject_match(_event), do: nil

  defp payload_object_id(%WebhookEvent{data: data}) when is_map(data) do
    nested_value(data, ["object", "id"]) || nested_value(data, ["data", "object", "id"])
  end

  defp payload_object_id(_webhook), do: nil

  defp payload_customer_id(%WebhookEvent{data: data}) when is_map(data) do
    nested_value(data, ["object", "customer"]) ||
      nested_value(data, ["data", "object", "customer"])
  end

  defp payload_customer_id(_webhook), do: nil

  defp maybe_match_binary_id(query, value) do
    case Ecto.UUID.cast(value) do
      {:ok, uuid} -> or_where(query, [row], row.id == ^uuid)
      :error -> query
    end
  end

  defp nested_value(map, [key]) when is_map(map), do: Map.get(map, key)

  defp nested_value(map, [key | rest]) when is_map(map) do
    case Map.get(map, key) do
      nested when is_map(nested) -> nested_value(nested, rest)
      _ -> nil
    end
  end
end
