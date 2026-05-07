defmodule AccrueHost.Billing.Plans do
  @moduledoc """
  Deterministic Fake-backed plan definitions for the host billing UI.
  """

  @ids %{basic: "price_basic", pro: "price_pro"}
  @labels %{basic: "Basic", pro: "Pro"}
  @amounts %{basic: 1_500, pro: 3_000}

  def ids, do: @ids

  def all do
    [
      %{
        key: :basic,
        id: @ids.basic,
        label: @labels.basic,
        unit_amount_minor: @amounts.basic,
        currency: "USD",
        billing_cycle: %{unit: :month, count: 1}
      },
      %{
        key: :pro,
        id: @ids.pro,
        label: @labels.pro,
        unit_amount_minor: @amounts.pro,
        currency: "USD",
        billing_cycle: %{unit: :month, count: 1}
      }
    ]
  end

  def get(price_id) when is_binary(price_id) do
    Enum.find(all(), &(&1.id == price_id))
  end
end
