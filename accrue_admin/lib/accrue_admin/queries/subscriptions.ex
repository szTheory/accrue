defmodule AccrueAdmin.Queries.Subscriptions do
  @moduledoc """
  Cursor-paginated subscription queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    Subscription
    |> join(:inner, [subscription], customer in Customer,
      on: customer.id == subscription.customer_id
    )
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([subscription, _customer], desc: subscription.inserted_at, desc: subscription.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([subscription, customer], %{
      id: subscription.id,
      customer_id: subscription.customer_id,
      customer_name: customer.name,
      customer_email: customer.email,
      processor_id: subscription.processor_id,
      status: subscription.status,
      cancel_at_period_end: subscription.cancel_at_period_end,
      current_period_end: subscription.current_period_end,
      trial_end: subscription.trial_end,
      ended_at: subscription.ended_at,
      inserted_at: subscription.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)

    Subscription
    |> join(:inner, [subscription], customer in Customer,
      on: customer.id == subscription.customer_id
    )
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
          [subscription, customer],
          ilike(customer.email, ^pattern) or
            ilike(customer.name, ^pattern) or
            ilike(subscription.processor_id, ^pattern)
        )

      {:status, status}, query ->
        filter_status(query, status)

      {:customer_id, customer_id}, query ->
        where(query, [subscription, _customer], subscription.customer_id == ^customer_id)

      {_unknown, _value}, query ->
        query
    end)
  end

  defp filter_status(query, "active"), do: Billing.Query.active(query)
  defp filter_status(query, "trialing"), do: Billing.Query.trialing(query)
  defp filter_status(query, "canceling"), do: Billing.Query.canceling(query)
  defp filter_status(query, "canceled"), do: Billing.Query.canceled(query)
  defp filter_status(query, "past_due"), do: Billing.Query.past_due(query)
  defp filter_status(query, "paused"), do: Billing.Query.paused(query)

  defp filter_status(query, status) do
    where(
      query,
      [subscription, _customer],
      subscription.status == ^String.to_existing_atom(status)
    )
  rescue
    ArgumentError -> query
  end
end
