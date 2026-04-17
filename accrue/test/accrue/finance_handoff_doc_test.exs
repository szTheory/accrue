defmodule Accrue.FinanceHandoffDocTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @guide Path.expand("../../guides/finance-handoff.md", __DIR__)

  test "finance handoff guide stays aligned with FIN-01/FIN-02 contract phrases" do
    assert File.exists?(@guide)
    body = File.read!(@guide)

    for needle <- [
          "Stripe Revenue Recognition",
          "Sigma",
          "Data Pipeline",
          "wrong-audience finance exports",
          "does **not** implement GAAP",
          "FIN-02",
          "accrue_events"
        ] do
      assert String.contains?(body, needle),
             "expected finance-handoff.md to contain #{inspect(needle)}"
    end
  end
end
