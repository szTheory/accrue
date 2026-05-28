defmodule Accrue.Analytics.Dunning do
  @moduledoc """
  Analytics context for Dunning.

  Provides MRR-based recovery vs lost metrics without adding new database
  tables, querying directly against the `accrue_events` ledger via Ecto JSONB
  aggregations.
  """

  import Ecto.Query, only: [from: 2, left_join: 3, subquery: 1, where: 3]

  alias Accrue.Billing.{Customer, Invoice, PaymentMethod, Subscription}
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Oban.Job

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

  @doc """
  Returns subscriptions currently in an active dunning campaign, enriched
  with next-step ETA and last-failure reason.

  Window opts (`:since`, `:until`) filter by `dunning_campaign_started_at`.
  Uses a NOT EXISTS ledger tiebreaker to exclude subscriptions that have
  recovered even when the schema anchor column hasn't been cleared yet
  (projection-lag race). Pre-v1.44 campaigns without `invoice_id` in
  `campaign_started` data return `nil` for `failure_reason`.

  ## Return shape

  Each map contains:
  - `:subscription_id` — Accrue UUID
  - `:customer_id` — Accrue UUID
  - `:customer_label` — customer email (or name, or nil)
  - `:days_in_campaign` — integer days since campaign start (truncated)
  - `:current_step` — count of `dunning.step_sent` events for this campaign
  - `:next_step_eta` — `DateTime.t()` or nil when no pending Oban job
  - `:failure_reason` — data map from the most-recent `invoice.payment_failed` event
    for this subscription's campaign, or nil when no matched invoice or payment failure
    event exists (pre-v1.44 campaigns without `invoice_id` in `campaign_started` data
    also return nil)

  ## Options

    * `:since` — `%DateTime{}` lower bound (inclusive on `dunning_campaign_started_at`)
    * `:until` — `%DateTime{}` upper bound (inclusive on `dunning_campaign_started_at`)

  @since "1.4.0"
  """
  @spec at_risk_subscriptions(keyword()) :: [map()]
  def at_risk_subscriptions(opts \\ []) when is_list(opts) do
    now = Accrue.Clock.utc_now()

    query =
      from(s in Subscription,
        join: c in Customer,
        on: c.id == s.customer_id,
        left_join: j in Job,
        on:
          j.worker == "Accrue.Workers.DunningStep" and
            fragment("? ->> 'subscription_id' = ?::text", j.args, s.id) and
            fragment(
              "? ->> 'campaign_started_at' = to_char(?, 'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"')",
              j.args,
              s.dunning_campaign_started_at
            ) and j.state in ["available", "scheduled", "retryable"],
        where: not is_nil(s.dunning_campaign_started_at),
        where:
          fragment(
            "NOT EXISTS (SELECT 1 FROM accrue_events WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = ?::text AND inserted_at >= ?)",
            s.id,
            s.dunning_campaign_started_at
          ),
        group_by: [
          s.id,
          s.customer_id,
          c.email,
          c.name,
          s.dunning_campaign_started_at
        ],
        order_by: [desc: s.dunning_campaign_started_at],
        select: %{
          subscription_id: s.id,
          customer_id: s.customer_id,
          customer_label: fragment("COALESCE(?, ?)", c.email, c.name),
          days_in_campaign:
            fragment(
              "EXTRACT(EPOCH FROM (? - ?))::integer / 86400",
              ^now,
              s.dunning_campaign_started_at
            ),
          current_step:
            fragment(
              "(SELECT COUNT(*) FROM accrue_events WHERE type = 'dunning.step_sent' AND subject_id = ?::text AND inserted_at >= ?)",
              s.id,
              s.dunning_campaign_started_at
            ),
          next_step_eta: min(j.scheduled_at),
          failure_reason:
            fragment(
              """
              (SELECT e.data FROM accrue_events e
                 JOIN accrue_invoices i ON i.id::text = e.subject_id
                 JOIN accrue_events cs ON cs.type = 'dunning.campaign_started'
                                      AND cs.subject_id = ?::text
                                      AND cs.data->>'invoice_id' = i.processor_id
               WHERE e.type = 'invoice.payment_failed'
                 AND e.inserted_at >= ?
               ORDER BY e.inserted_at DESC
               LIMIT 1)
              """,
              s.id,
              s.dunning_campaign_started_at
            )
        }
      )
      |> apply_campaign_window(opts)

    Repo.all(query)
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

  defp apply_campaign_window(query, opts) do
    query
    |> maybe_since_campaign(opts[:since])
    |> maybe_until_campaign(opts[:until])
  end

  defp maybe_since_campaign(query, %DateTime{} = since),
    do: where(query, [s], s.dunning_campaign_started_at >= ^since)

  defp maybe_since_campaign(query, _), do: query

  defp maybe_until_campaign(query, %DateTime{} = until),
    do: where(query, [s], s.dunning_campaign_started_at <= ^until)

  defp maybe_until_campaign(query, _), do: query

  @doc """
  Returns all dunning events for a subscription in chronological order.
  """
  @since "1.4.0"
  @spec campaign_timeline(String.t(), keyword()) :: [Event.t()]
  def campaign_timeline(subscription_id, opts \\ []) when is_binary(subscription_id) and is_list(opts) do
    Accrue.Events.timeline_for("Subscription", subscription_id, opts)
    |> Enum.filter(&String.starts_with?(&1.type, "dunning."))
  end

  @doc """
  Returns dunning events for a subscription grouped into campaign arcs.
  """
  @since "1.4.0"
  @spec campaign_timeline_grouped(String.t(), keyword()) :: [{String.t() | nil, [Event.t()]}]
  def campaign_timeline_grouped(subscription_id, opts \\ []) when is_binary(subscription_id) and is_list(opts) do
    campaign_timeline(subscription_id, opts)
    |> group_into_arcs()
  end

  defp group_into_arcs([]), do: []
  defp group_into_arcs(events) do
    Enum.reduce(events, [], fn event, acc ->
      if event.type == "dunning.campaign_started" do
        acc ++ [{event.data["campaign_anchor"], [event]}]
      else
        case acc do
          [] ->
            [{nil, [event]}]

          _ ->
            {anchor, arc_events} = List.last(acc)
            List.replace_at(acc, -1, {anchor, arc_events ++ [event]})
        end
      end
    end)
  end

  @doc """
  Returns a map of invoices for a given subscription, keyed by Stripe processor_id.
  """
  @since "1.4.0"
  @spec invoices_for_campaign(String.t(), keyword()) :: %{String.t() => map()}
  def invoices_for_campaign(subscription_id, opts \\ []) when is_binary(subscription_id) and is_list(opts) do
    from(i in Invoice,
      join: c in Customer,
      on: c.id == i.customer_id,
      left_join: pm in PaymentMethod,
      on: pm.id == c.default_payment_method_id,
      where: i.subscription_id == type(^subscription_id, :binary_id),
      where: not is_nil(i.processor_id),
      select: %{
        processor_id: i.processor_id,
        status: i.status,
        amount_due_cents: i.amount_due_minor,
        card_last4: pm.card_last4,
        card_brand: pm.card_brand
      }
    )
    |> Repo.all()
    |> Map.new(fn row -> {row.processor_id, Map.delete(row, :processor_id)} end)
  end
end