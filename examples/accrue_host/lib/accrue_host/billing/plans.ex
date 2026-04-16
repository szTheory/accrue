defmodule AccrueHost.Billing.Plans do
  @moduledoc """
  Deterministic Fake-backed plan definitions for the host billing UI.
  """

  @ids %{basic: "price_basic", pro: "price_pro"}
  @labels %{basic: "Basic", pro: "Pro"}

  def ids, do: @ids

  def all do
    [
      %{key: :basic, id: @ids.basic, label: @labels.basic},
      %{key: :pro, id: @ids.pro, label: @labels.pro}
    ]
  end
end
