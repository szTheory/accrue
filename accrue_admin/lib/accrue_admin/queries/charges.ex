defmodule AccrueAdmin.Queries.Charges do
  @moduledoc """
  Cursor-paginated charge queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing.{Charge, Customer}
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    Charge
    |> join(:inner, [charge], customer in Customer, on: customer.id == charge.customer_id)
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([charge, _customer], desc: charge.inserted_at, desc: charge.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([charge, customer], %{
      id: charge.id,
      customer_id: charge.customer_id,
      customer_name: customer.name,
      customer_email: customer.email,
      owner_type: customer.owner_type,
      owner_id: customer.owner_id,
      subscription_id: charge.subscription_id,
      payment_method_id: charge.payment_method_id,
      processor_id: charge.processor_id,
      status: charge.status,
      currency: charge.currency,
      amount_cents: charge.amount_cents,
      stripe_fee_amount_minor: charge.stripe_fee_amount_minor,
      stripe_fee_currency: charge.stripe_fee_currency,
      fees_settled_at: charge.fees_settled_at,
      inserted_at: charge.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)

    Charge
    |> join(:inner, [charge], customer in Customer, on: customer.id == charge.customer_id)
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
      fees_settled:
        Behaviour.parse_boolean(Map.get(params, "fees_settled") || Map.get(params, :fees_settled))
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
          [charge, customer],
          ilike(charge.processor_id, ^pattern) or
            ilike(customer.email, ^pattern) or
            ilike(customer.name, ^pattern)
        )

      {:status, status}, query ->
        where(query, [charge, _customer], charge.status == ^status)

      {:customer_id, customer_id}, query ->
        where(query, [charge, _customer], charge.customer_id == ^customer_id)

      {:fees_settled, true}, query ->
        where(query, [charge, _customer], not is_nil(charge.fees_settled_at))

      {:fees_settled, false}, query ->
        where(query, [charge, _customer], is_nil(charge.fees_settled_at))

      {_unknown, _value}, query ->
        query
    end)
  end
end
