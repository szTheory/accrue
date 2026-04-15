defmodule AccrueAdmin.Queries.Invoices do
  @moduledoc """
  Cursor-paginated invoice queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    Invoice
    |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([invoice, _customer], desc: invoice.inserted_at, desc: invoice.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([invoice, customer], %{
      id: invoice.id,
      customer_id: invoice.customer_id,
      customer_name: customer.name,
      customer_email: customer.email,
      subscription_id: invoice.subscription_id,
      processor_id: invoice.processor_id,
      number: invoice.number,
      status: invoice.status,
      currency: invoice.currency,
      total_minor: invoice.total_minor,
      amount_due_minor: invoice.amount_due_minor,
      amount_paid_minor: invoice.amount_paid_minor,
      amount_remaining_minor: invoice.amount_remaining_minor,
      collection_method: invoice.collection_method,
      due_date: invoice.due_date,
      finalized_at: invoice.finalized_at,
      inserted_at: invoice.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)

    Invoice
    |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  @impl true
  def decode_filter(params) when is_map(params) do
    %{
      q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
      status: Behaviour.normalize_string(Map.get(params, "status") || Map.get(params, :status)),
      customer_id:
        Behaviour.normalize_string(
          Map.get(params, "customer_id") || Map.get(params, :customer_id)
        ),
      collection_method:
        Behaviour.normalize_string(
          Map.get(params, "collection_method") || Map.get(params, :collection_method)
        )
    }
    |> Behaviour.compact_filter()
  end

  @impl true
  def encode_filter(filter) when is_map(filter), do: Behaviour.compact_filter(filter)

  defp filter_query(query, filter) do
    Enum.reduce(filter, query, fn
      {:q, term}, query ->
        pattern = "%#{term}%"

        where(
          query,
          [invoice, customer],
          ilike(invoice.number, ^pattern) or
            ilike(invoice.processor_id, ^pattern) or
            ilike(customer.email, ^pattern) or
            ilike(customer.name, ^pattern)
        )

      {:status, status}, query ->
        where(query, [invoice, _customer], invoice.status == ^String.to_existing_atom(status))

      {:customer_id, customer_id}, query ->
        where(query, [invoice, _customer], invoice.customer_id == ^customer_id)

      {:collection_method, collection_method}, query ->
        where(query, [invoice, _customer], invoice.collection_method == ^collection_method)

      {_unknown, _value}, query ->
        query
    end)
  rescue
    ArgumentError -> query
  end
end
