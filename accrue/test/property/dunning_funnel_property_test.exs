defmodule Accrue.Property.DunningFunnelPropertyTest do
  @moduledoc """
  Canonical DAN-01 invariant property test for `Accrue.Analytics.Dunning.funnel/1`.

  Generates random sequences of `(subject_id, type, anchor)` triples drawn from
  a small pool of subjects, the four lifecycle event types, and random anchor
  strings — then inserts each as an `accrue_events` row and asserts:

      recovered + exhausted + active <= entered

  This holds because the three filter predicates in `funnel/1`'s outer query
  are mutually exclusive (`has_recovered`, `has_exhausted AND NOT has_recovered`,
  `NOT has_recovered AND NOT has_exhausted`). The strict inequality applies
  only when a tuple flags BOTH recovered AND exhausted, in which case it
  counts toward `recovered` only and the sum falls strictly under `entered`.

  Per RESEARCH.md OQ#4: the legacy bucket (events without `campaign_anchor`)
  folds active-without-anchor and pre-snapshot-recovered subjects into the
  same `(subject_id, '__legacy__')` tuple. The invariant still holds because
  the filter predicates remain mutually exclusive within each tuple.
  """

  use Accrue.RepoCase, async: false
  use ExUnitProperties

  alias Accrue.Analytics.Dunning

  @types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]

  defp event_gen do
    StreamData.tuple(
      {StreamData.member_of(~w[sub_a sub_b sub_c]),
       StreamData.member_of(@types),
       StreamData.string(:alphanumeric, min_length: 1, max_length: 16)}
    )
  end

  defp campaign_sequence_gen do
    StreamData.list_of(event_gen(), min_length: 0, max_length: 30)
  end

  property "recovered + exhausted + active <= entered across generated event sequences" do
    check all(events <- campaign_sequence_gen()) do
      # Note: `accrue_events` is append-only — a Postgres BEFORE UPDATE OR DELETE
      # trigger raises SQLSTATE '45A01' for any DELETE attempt
      # (`priv/repo/migrations/20260411000001_create_accrue_events.exs`). The
      # sandbox transaction rolls back the entire test at test-exit; iterations
      # within a single property accumulate, but the invariant
      # `recovered + exhausted + active <= entered` is preserved under monotone
      # event additions because the three filter predicates in funnel/1 are
      # mutually exclusive within every `(subject_id, campaign_anchor)` tuple.
      # We make subject IDs and anchors unique-per-iteration so accumulated
      # events from prior iterations don't pollute the assertion's funnel result.
      iteration_tag = System.unique_integer([:positive])

      Enum.each(events, fn {subject_id, type, anchor} ->
        Accrue.Repo.insert!(%Accrue.Events.Event{
          type: type,
          subject_type: "Subscription",
          subject_id: "#{subject_id}_#{iteration_tag}",
          actor_type: "system",
          schema_version: 1,
          data: %{"campaign_anchor" => "#{anchor}_#{iteration_tag}"}
        })
      end)

      result = Dunning.funnel()

      assert result.recovered + result.exhausted + result.active <= result.entered
    end
  end
end
