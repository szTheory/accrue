defmodule Accrue.Analytics.Dunning do
  @moduledoc """
  Analytics context for Dunning.

  Provides MRR-based recovery vs lost metrics without adding new database
  tables, querying directly against the `accrue_events` ledger via Ecto JSONB
  aggregations.
  """

  import Ecto.Query, only: [from: 2, subquery: 1, where: 3]

  alias Accrue.Events.Event
  alias Accrue.Repo

  @recovered_type "dunning.recovered"
  @exhausted_type "dunning.exhausted"

  @dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]

  @doc """
  Folds the `accrue_events` ledger into a flat
  `%{recovered_cents: n, lost_cents: n}` map answering the merchant question
  "how much MRR did dunning recover vs. lose to terminal action?"

  This adds NO new table: it groups by the two confirmed-transition lifecycle
  ledger types written by the campaign:

    * `recovered` = sum of `mrr_value_cents` from `dunning.recovered`
    * `lost`      = sum of `mrr_value_cents` from `dunning.exhausted`

  ## Options

    * `:since` — `%DateTime{}` lower bound (inclusive), inclusive on
      `inserted_at >= since`.
    * `:until` — `%DateTime{}` upper bound (inclusive), `inserted_at <= until`.

  ## Examples

      iex> Accrue.Analytics.Dunning.recovered_vs_lost_mrr()
      %{recovered_cents: 12000, lost_cents: 3000}
  """
  @spec recovered_vs_lost_mrr(keyword()) :: %{recovered_cents: non_neg_integer(), lost_cents: non_neg_integer()}
  def recovered_vs_lost_mrr(opts \\ []) when is_list(opts) do
    query =
      from(e in Event,
        where: e.type in [@recovered_type, @exhausted_type],
        group_by: e.type,
        select:
          {e.type,
           sum(
             fragment(
               "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
               e.data,
               e.data
             )
           )}
      )
      |> apply_window(opts)

    results = Repo.all(query) |> Map.new()

    %{
      recovered_cents: Map.get(results, @recovered_type) || 0,
      lost_cents: Map.get(results, @exhausted_type) || 0
    }
  end

  @doc """
  Three-stage dunning funnel computed from the `accrue_events` ledger.

  Returns a flat map of DISTINCT-`(subject_id, campaign_anchor)`-tuple counts:

      %{entered: N, recovered: N, exhausted: N, active: N}

  Counts DISTINCT `(subject_id, campaign_anchor)` tuples per stage so that a
  subscription cycling dunning multiple times in the window is NOT
  double-counted on any single stage. The three filter predicates are
  mutually exclusive, which guarantees the invariant
  `recovered + exhausted + active <= entered`. (Strictly less when a tuple
  flags BOTH recovered AND exhausted — physically impossible by construction
  but defensively handled.)

  Pre-Phase-144 events without `campaign_anchor` fall through under a
  per-subject sentinel `"__legacy__"` — "earliest known single-row stage
  attribution". This UNDER-counts `entered` if a subject cycled multiple
  legacy campaigns. Backfill is architecturally impossible: the
  `accrue_events` immutability trigger rejects updates (SQLSTATE 45A01).
  Documented cutoff label in `guides/analytics.md` lands with Phase 148.

  Runs as a SINGLE Ecto query — one `Repo.one/1` call wrapping a `subquery/1`.
  No concurrent task per stage; the Postgres planner converts the two-level
  GROUP BY into one HashAggregate over the inner subquery.

  ## Options

    * `:since` — `%DateTime{}` lower bound (inclusive on `inserted_at`).
    * `:until` — `%DateTime{}` upper bound (inclusive on `inserted_at`).

  Window-bounding is applied to the inner subquery so events are excluded
  BEFORE the `(subject_id, campaign_anchor)` grouping.

  ## Examples

      # One subject cycles dunning 3 times in the window:
      # anchor_1 → recovered, anchor_2 → exhausted, anchor_3 → still active.
      iex> Accrue.Analytics.Dunning.funnel()
      %{entered: 3, recovered: 1, exhausted: 1, active: 1}

  @since "1.4.0"
  """
  @spec funnel(keyword()) :: %{
          entered: non_neg_integer(),
          recovered: non_neg_integer(),
          exhausted: non_neg_integer(),
          active: non_neg_integer()
        }
  def funnel(opts \\ []) when is_list(opts) do
    per_campaign =
      from(e in Event,
        where: e.type in ^@dunning_lifecycle_types,
        group_by: [
          e.subject_id,
          fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", e.data)
        ],
        select: %{
          has_recovered: fragment("bool_or(? = 'dunning.recovered')", e.type),
          has_exhausted: fragment("bool_or(? = 'dunning.exhausted')", e.type)
        }
      )
      |> apply_window(opts)

    query =
      from(c in subquery(per_campaign),
        select: %{
          entered: count(),
          recovered: filter(count(), c.has_recovered),
          exhausted: filter(count(), c.has_exhausted and not c.has_recovered),
          active: filter(count(), not c.has_recovered and not c.has_exhausted)
        }
      )

    Repo.one(query) || %{entered: 0, recovered: 0, exhausted: 0, active: 0}
  end

  defp apply_window(query, opts) do
    query
    |> maybe_since(opts[:since])
    |> maybe_until(opts[:until])
  end

  defp maybe_since(query, %DateTime{} = since),
    do: where(query, [e], e.inserted_at >= ^since)

  defp maybe_since(query, _), do: query

  defp maybe_until(query, %DateTime{} = until),
    do: where(query, [e], e.inserted_at <= ^until)

  defp maybe_until(query, _), do: query
end