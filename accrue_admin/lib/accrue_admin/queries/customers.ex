defmodule AccrueAdmin.Queries.Customers do
  @moduledoc """
  Cursor-paginated customer list queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing.Customer
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

    Customer
    |> scope_query(owner_scope)
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([customer], desc: customer.inserted_at, desc: customer.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([customer], %{
      id: customer.id,
      owner_type: customer.owner_type,
      owner_id: customer.owner_id,
      processor: customer.processor,
      processor_id: customer.processor_id,
      name: customer.name,
      email: customer.email,
      preferred_locale: customer.preferred_locale,
      preferred_timezone: customer.preferred_timezone,
      default_payment_method_id: customer.default_payment_method_id,
      inserted_at: customer.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

    Customer
    |> scope_query(owner_scope)
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  def detail(id, owner_scope) when is_binary(id) do
    Customer
    |> scope_query(owner_scope)
    |> where([customer], customer.id == ^id)
    |> Repo.one()
    |> case do
      nil -> :not_found
      customer -> {:ok, customer}
    end
  end

  @impl true
  def decode_filter(params) when is_map(params) do
    %{
      q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
      owner_type:
        Behaviour.normalize_string(Map.get(params, "owner_type") || Map.get(params, :owner_type)),
      has_default_payment_method:
        Behaviour.parse_boolean(
          Map.get(params, "has_default_payment_method") ||
            Map.get(params, :has_default_payment_method)
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
          [customer],
          ilike(customer.email, ^pattern) or
            ilike(customer.name, ^pattern) or
            ilike(customer.owner_id, ^pattern) or
            ilike(customer.processor_id, ^pattern)
        )

      {:owner_type, owner_type}, query ->
        where(query, [customer], customer.owner_type == ^owner_type)

      {:has_default_payment_method, true}, query ->
        where(query, [customer], not is_nil(customer.default_payment_method_id))

      {:has_default_payment_method, false}, query ->
        where(query, [customer], is_nil(customer.default_payment_method_id))

      {_unknown, _value}, query ->
        query
    end)
  end

  defp scope_query(query, nil), do: query
  defp scope_query(query, %OwnerScope{mode: :global}), do: query

  defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      query,
      [customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end
end
