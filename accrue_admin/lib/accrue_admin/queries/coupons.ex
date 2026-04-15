defmodule AccrueAdmin.Queries.Coupons do
  @moduledoc """
  Cursor-paginated coupon queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing.Coupon
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    Coupon
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([coupon], desc: coupon.inserted_at, desc: coupon.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([coupon], %{
      id: coupon.id,
      processor: coupon.processor,
      processor_id: coupon.processor_id,
      name: coupon.name,
      amount_off_cents: coupon.amount_off_cents,
      amount_off_minor: coupon.amount_off_minor,
      percent_off: coupon.percent_off,
      currency: coupon.currency,
      duration: coupon.duration,
      duration_in_months: coupon.duration_in_months,
      max_redemptions: coupon.max_redemptions,
      times_redeemed: coupon.times_redeemed,
      valid: coupon.valid,
      redeem_by: coupon.redeem_by,
      inserted_at: coupon.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)

    Coupon
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  @impl true
  def decode_filter(params) when is_map(params) do
    %{
      q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
      valid: Behaviour.parse_boolean(Map.get(params, "valid") || Map.get(params, :valid))
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
          [coupon],
          ilike(coupon.name, ^pattern) or
            ilike(coupon.processor_id, ^pattern)
        )

      {:valid, valid}, query ->
        where(query, [coupon], coupon.valid == ^valid)

      {_unknown, _value}, query ->
        query
    end)
  end
end
