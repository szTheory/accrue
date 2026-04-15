defmodule AccrueAdmin.Queries.PromotionCodes do
  @moduledoc """
  Cursor-paginated promotion code queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    PromotionCode
    |> join(:left, [promotion_code], coupon in Coupon, on: coupon.id == promotion_code.coupon_id)
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([promotion_code, _coupon],
      desc: promotion_code.inserted_at,
      desc: promotion_code.id
    )
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([promotion_code, coupon], %{
      id: promotion_code.id,
      coupon_id: promotion_code.coupon_id,
      coupon_name: coupon.name,
      processor_id: promotion_code.processor_id,
      code: promotion_code.code,
      active: promotion_code.active,
      max_redemptions: promotion_code.max_redemptions,
      times_redeemed: promotion_code.times_redeemed,
      expires_at: promotion_code.expires_at,
      inserted_at: promotion_code.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)

    PromotionCode
    |> join(:left, [promotion_code], coupon in Coupon, on: coupon.id == promotion_code.coupon_id)
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  @impl true
  def decode_filter(params) when is_map(params) do
    %{
      q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
      active: Behaviour.parse_boolean(Map.get(params, "active") || Map.get(params, :active)),
      coupon_id:
        Behaviour.normalize_string(Map.get(params, "coupon_id") || Map.get(params, :coupon_id))
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
          [promotion_code, coupon],
          ilike(promotion_code.code, ^pattern) or
            ilike(promotion_code.processor_id, ^pattern) or
            ilike(coupon.name, ^pattern)
        )

      {:active, active}, query ->
        where(query, [promotion_code, _coupon], promotion_code.active == ^active)

      {:coupon_id, coupon_id}, query ->
        where(query, [promotion_code, _coupon], promotion_code.coupon_id == ^coupon_id)

      {_unknown, _value}, query ->
        query
    end)
  end
end
