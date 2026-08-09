defmodule Accrue.Property.EntitlementDecisionCasesPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Entitlements.DecisionCaseContractConsumer
  alias Accrue.Entitlements.DecisionCases
  alias Accrue.Entitlements.DecisionCases.{PriorState, Ordering}

  property "permuted duplicate deliveries converge to one computed transition", _context do
    case_data = find_case!("duplicate_provider_event")

    check all(count <- integer(1..12), max_runs: 50) do
      deliveries = List.duplicate(case_data.ordering, count) |> Enum.shuffle()

      assert accepted!(case_data, case_data.evidence, case_data.prior, deliveries) ==
               accepted!(case_data, case_data.evidence, case_data.prior, [case_data.ordering])
    end
  end

  property "older generated evidence cannot restore an allow snapshot after a denied prior",
           _context do
    case_data = find_case!("out_of_order_positive_after_revoke")
    %PriorState{} = canonical_prior = case_data.prior
    %Ordering{} = canonical_ordering = case_data.ordering

    check all(revision <- integer(0..100), offset <- integer(0..1_000), max_runs: 50) do
      prior = %PriorState{canonical_prior | revision: revision, snapshot: %{}}

      ordering = %Ordering{
        canonical_ordering
        | observed_at: canonical_ordering.observed_at - offset
      }

      result = accepted!(case_data, case_data.evidence, prior, [ordering])

      assert result.snapshot == %{}
      assert result.revision >= revision
      assert result.disposition == :noop
    end
  end

  property "generated source sets retain a surviving live rail after the other rail retracts",
           _context do
    case_data = find_case!("stripe_revoked_apple_survives")
    %PriorState{} = canonical_prior = case_data.prior

    check all(sources <- member_of([[:apple], [:stripe, :apple]]), max_runs: 50) do
      prior = %PriorState{canonical_prior | sources: sources}
      result = accepted!(case_data, case_data.evidence, prior, [case_data.ordering])

      assert :apple in result.sources
      refute :stripe in result.sources
      assert result.snapshot == case_data.expected.snapshot
    end
  end

  property "generated revisions emit only a complete atomic result", _context do
    case_data = find_case!("atomic_transaction_boundary")
    %PriorState{} = canonical_prior = case_data.prior

    check all(revision <- integer(0..100), max_runs: 50) do
      prior = %PriorState{canonical_prior | revision: revision}
      result = accepted!(case_data, case_data.evidence, prior, [case_data.ordering])

      assert result.revision == revision + case_data.expected.revision_delta
      assert result.atomic

      assert Map.keys(result) |> Enum.sort() ==
               [
                 :atomic,
                 :continuity,
                 :disposition,
                 :lease,
                 :reason,
                 :repair,
                 :revision,
                 :snapshot,
                 :sources
               ]
    end
  end

  property "invalid generated evidence, bindings, and prior state are rejected before transition",
           _context do
    case_data = find_case!("apple_verified_grant")

    check all(
            invalid <- member_of([:unknown_binding, :unverified_payload, :invalid_prior]),
            max_runs: 50
          ) do
      {evidence, prior} = invalid_input(case_data, invalid)

      assert {:error, _reason} =
               DecisionCaseContractConsumer.consume(case_data, evidence, prior, [
                 case_data.ordering
               ])
    end
  end

  defp invalid_input(case_data, :unknown_binding),
    do: {put_in(case_data.evidence.account_binding, :unknown_binding), case_data.prior}

  defp invalid_input(case_data, :unverified_payload),
    do: {put_in(case_data.evidence.kind, :unverified_payload), case_data.prior}

  defp invalid_input(case_data, :invalid_prior) do
    %PriorState{} = prior = case_data.prior
    {case_data.evidence, %PriorState{prior | revision: -1}}
  end

  defp accepted!(case_data, evidence, prior, deliveries) do
    assert {:ok, result} =
             DecisionCaseContractConsumer.consume(case_data, evidence, prior, deliveries)

    result
  end

  defp find_case!(id),
    do: Enum.find(DecisionCases.all(), &(&1.id == id)) || raise("missing #{id}")
end
