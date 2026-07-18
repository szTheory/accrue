defmodule AccrueHostWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use AccrueHostWeb, :html

  alias AccrueHost.DemoBrand

  embed_templates "page_html/*"

  def brand, do: DemoBrand

  def plan_price(%{unit_amount_minor: 0}), do: "Usage based"

  def plan_price(%{unit_amount_minor: cents}) when is_integer(cents) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)

    if remainder == 0 do
      "$#{dollars}"
    else
      "$#{dollars}.#{String.pad_leading(Integer.to_string(remainder), 2, "0")}"
    end
  end

  def plan_interval(%{billing_cycle: %{unit: unit, count: 1}}), do: "per #{unit}"
  def plan_interval(%{billing_cycle: %{unit: unit, count: count}}), do: "every #{count} #{unit}s"
  def plan_interval(_plan), do: "per month"

  def plan_blurb(%{summary: summary}) when is_binary(summary), do: summary
  def plan_blurb(_plan), do: "A Cadence plan for teams that track work and bill for it."

  def plan_features(%{features: features}) when is_list(features), do: features
  def plan_features(_plan), do: []
end
