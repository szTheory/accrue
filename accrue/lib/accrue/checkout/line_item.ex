defmodule Accrue.Checkout.LineItem do
  @moduledoc """
  Helpers for constructing Stripe Checkout `line_items` array entries
  (CHKT-03).

  Line items are plain string-keyed maps in the shape Stripe Checkout
  expects. Two constructors are provided:

    * `from_price/2` — by-reference to a catalog price
    * `from_price_data/1` — inline `price_data` for ad-hoc pricing

  Host apps SHOULD prefer `from_price/2` whenever possible — catalog
  prices are the audit-trail-friendly path.
  """

  @doc """
  Builds a line item referencing a catalog price by id.

  ## Examples

      iex> Accrue.Checkout.LineItem.from_price("price_basic_monthly", 1)
      %{"price" => "price_basic_monthly", "quantity" => 1}
  """
  @spec from_price(String.t(), pos_integer()) :: map()
  def from_price(price_id, quantity \\ 1)
      when is_binary(price_id) and is_integer(quantity) and quantity >= 1 do
    %{"price" => price_id, "quantity" => quantity}
  end

  @doc """
  Builds a line item from an inline `price_data` map. The `:quantity`
  key is hoisted to the top level (Stripe expects it outside
  `price_data`); the rest is forwarded into the `price_data` payload
  as string-keyed entries.

  ## Examples

      Accrue.Checkout.LineItem.from_price_data(%{
        currency: "usd",
        unit_amount: 1500,
        product_data: %{name: "One-off"},
        quantity: 2
      })
  """
  @spec from_price_data(map() | keyword()) :: map()
  def from_price_data(params) when is_list(params), do: from_price_data(Map.new(params))

  def from_price_data(params) when is_map(params) do
    {quantity, rest} = Map.pop(params, :quantity, 1)
    {string_quantity, rest} = Map.pop(rest, "quantity", quantity)

    %{
      "price_data" => stringify(rest),
      "quantity" => string_quantity
    }
  end

  defp stringify(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_value(v)}
      {k, v} -> {k, stringify_value(v)}
    end)
  end

  defp stringify_value(v) when is_map(v), do: stringify(v)
  defp stringify_value(v), do: v
end
