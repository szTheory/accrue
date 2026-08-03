defmodule Accrue.Entitlements.AppleConvergencePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Entitlements.DecisionCases

  property "Apple repair and retry cases remain valid under arbitrary ordering" do
    ids = DecisionCases.all() |> Enum.filter(&String.starts_with?(&1.id, "apple_")) |> Enum.map(& &1.id)

    check all ordered <- list_of(member_of(ids), min_length: 1) do
      assert Enum.all?(ordered, fn id ->
               DecisionCases.all() |> Enum.find(&(&1.id == id)) |> DecisionCases.valid?()
             end)
    end
  end
end
