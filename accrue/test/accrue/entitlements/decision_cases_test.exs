defmodule Accrue.Entitlements.DecisionCasesTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.DecisionCases

  test "the canonical corpus has sorted unique stable IDs and one version" do
    cases = DecisionCases.all()
    ids = Enum.map(cases, & &1.id)

    assert length(cases) > 0
    assert ids == Enum.sort(ids)
    assert length(ids) == length(Enum.uniq(ids))
    assert Enum.all?(cases, &(&1.contract_version == DecisionCases.version()))
  end

  test "every case has the closed D-07 schema and a bounded privacy-safe reason" do
    assert Enum.all?(DecisionCases.all(), &DecisionCases.valid?/1)

    assert Enum.all?(DecisionCases.all(), fn case_data ->
             case_data.expected.reason =~ ~r/^entitlement_[a-z0-9_]{3,80}$/
           end)
  end

  test "the corpus covers required rail, ordering, survivor, and continuity cases" do
    ids = DecisionCases.all() |> Enum.map(& &1.id) |> MapSet.new()

    for id <- [
          "apple_token_mismatch",
          "duplicate_provider_event",
          "out_of_order_positive_after_revoke",
          "stripe_revoked_apple_survives",
          "all_grants_revoked",
          "purchase_eligibility_ambiguous",
          "stale_offline_continuity",
          "reconnect_positive_replacement",
          "reconnect_denied_tombstone",
          "atomic_transaction_boundary"
        ] do
      assert MapSet.member?(ids, id), "missing #{id}"
    end
  end

  test "malformed closed values fail validation" do
    [first | _] = DecisionCases.all()

    refute DecisionCases.valid?(put_in(first.evidence.rail, :google))
    refute DecisionCases.valid?(put_in(first.evidence.environment, :staging))
    refute DecisionCases.valid?(put_in(first.ordering.relation, :future))
    refute DecisionCases.valid?(put_in(first.expected.disposition, :maybe))
  end
end
