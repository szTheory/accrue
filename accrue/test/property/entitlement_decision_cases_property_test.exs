defmodule Accrue.Property.EntitlementDecisionCasesPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Entitlements.DecisionCases

  property "permuted and duplicate equivalent evidence keeps its declared expectation",
    max_runs: 50 do
    case_data = find_case!("duplicate_provider_event")

    check all(deliveries <- list_of(member_of([case_data]), min_length: 1, max_length: 12)) do
      assert expected_signature(Enum.shuffle(deliveries)) == expected_signature([case_data])
    end
  end

  property "older positive evidence cannot outrank the declared revoke ordering", max_runs: 50 do
    stale = find_case!("out_of_order_positive_after_revoke")

    check all(offset <- integer(0..1)) do
      ordering = %{stale.ordering | observed_at: stale.ordering.observed_at - offset}
      assert ordering.relation == :older
      assert stale.expected.disposition == :noop
      assert stale.expected.lease == :denied
    end
  end

  property "retracting a source retains the declared survivor expectation", max_runs: 50 do
    survivor = find_case!("stripe_revoked_apple_survives")

    check all(sources <- uniq_list_of(member_of([:stripe, :apple]), min_length: 1, max_length: 2)) do
      if :apple in sources do
        assert survivor.expected.lease == :fresh
        assert survivor.expected.repair == :survivor
      end
    end
  end

  property "transaction cases declare an all-or-nothing grant snapshot revision audit boundary",
    max_runs: 50 do
    transaction = find_case!("atomic_transaction_boundary")

    check all(partial_step <- member_of([:grant, :snapshot, :revision, :audit])) do
      assert transaction.expected.atomic
      assert transaction.expected.disposition == :grant
      refute partial_step in [:partial_snapshot, :partial_revision]
    end
  end

  defp find_case!(id),
    do: Enum.find(DecisionCases.all(), &(&1.id == id)) || raise("missing #{id}")

  defp expected_signature([case_data | _]), do: Map.from_struct(case_data.expected)
end
