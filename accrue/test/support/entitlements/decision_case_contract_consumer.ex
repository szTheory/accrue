defmodule Accrue.Entitlements.DecisionCaseContractConsumer do
  @moduledoc false

  # This module is compiled from test/support only. It is a conformance consumer
  # for the canonical data contract, not a production entitlement projector or
  # a policy source: callers pass the case they want interpreted.

  alias Accrue.Entitlements.DecisionCases
  alias Accrue.Entitlements.DecisionCases.{DecisionCase, Ordering}

  @type result :: %{
          atomic: boolean(),
          continuity: atom(),
          disposition: atom(),
          lease: atom(),
          reason: String.t(),
          repair: atom(),
          revision: non_neg_integer(),
          snapshot: map(),
          sources: [atom()]
        }

  @spec consume(DecisionCase.t(), term(), term(), [term()]) :: {:ok, result()} | {:error, atom()}
  def consume(%DecisionCase{} = case_data, evidence, prior, deliveries)
      when is_list(deliveries) do
    cond do
      not DecisionCases.valid?(case_data) ->
        {:error, :invalid_case}

      not DecisionCases.valid?(%{case_data | evidence: evidence, prior: prior}) ->
        {:error, :invalid_input}

      evidence != case_data.evidence ->
        {:error, :evidence_mismatch}

      not valid_deliveries?(case_data, deliveries) ->
        {:error, :delivery_mismatch}

      true ->
        {:ok, transition(case_data, prior)}
    end
  end

  def consume(_, _, _, _), do: {:error, :invalid_input}

  defp valid_deliveries?(_case_data, []), do: false

  defp valid_deliveries?(case_data, deliveries) do
    Enum.all?(deliveries, fn
      %Ordering{} = ordering ->
        ordering.relation == case_data.ordering.relation and
          DecisionCases.valid?(%{case_data | ordering: ordering})

      _ ->
        false
    end)
  end

  defp transition(case_data, prior) do
    expected = case_data.expected
    disposition = expected.disposition

    %{
      atomic: expected.atomic,
      continuity: expected.continuity,
      disposition: disposition,
      lease: expected.lease,
      reason: expected.reason,
      repair: expected.repair,
      revision: prior.revision + expected.revision_delta,
      snapshot: snapshot_for(disposition, expected.snapshot, prior.snapshot),
      sources: sources_for(disposition, prior.sources, case_data.evidence.rail)
    }
  end

  defp snapshot_for(disposition, _expected, prior) when disposition in [:noop, :preserve],
    do: prior

  defp snapshot_for(_disposition, expected, _prior), do: expected

  defp sources_for(disposition, sources, rail) when disposition in [:retract, :no_grant],
    do: List.delete(sources, rail)

  defp sources_for(_disposition, sources, _rail), do: sources
end
