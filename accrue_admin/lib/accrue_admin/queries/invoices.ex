defmodule AccrueAdmin.Queries.Invoices do
  @moduledoc """
  Cursor-paginated invoice queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice}
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

    Invoice
    |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
    |> scope_query(owner_scope)
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([invoice, _customer], desc: invoice.inserted_at, desc: invoice.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([invoice, customer], %{
      id: invoice.id,
      customer_id: invoice.customer_id,
      customer_name: customer.name,
      customer_email: customer.email,
      owner_type: customer.owner_type,
      owner_id: customer.owner_id,
      automatic_tax: invoice.automatic_tax,
      automatic_tax_disabled_reason: invoice.automatic_tax_disabled_reason,
      last_finalization_error_code: invoice.last_finalization_error_code,
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
    owner_scope = Keyword.get(opts, :owner_scope)

    Invoice
    |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
    |> scope_query(owner_scope)
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  def detail(id, owner_scope) when is_binary(id) do
    Invoice
    |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
    |> scope_query(owner_scope)
    |> where([invoice, _customer], invoice.id == ^id)
    |> select([invoice, _customer], invoice)
    |> Repo.one()
    |> case do
      nil ->
        :not_found

      invoice ->
        {:ok, Repo.preload(invoice, [:customer, :subscription, :items])}
    end
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

  defp scope_query(query, nil), do: query
  defp scope_query(query, %OwnerScope{mode: :global}), do: query

  defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      query,
      [_invoice, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end
end
