defmodule Accrue.Analytics.Dunning do
  @moduledoc """
  Analytics context for Dunning.

  Provides MRR-based recovery vs lost metrics without adding new database
  tables, querying directly against the `accrue_events` ledger via Ecto JSONB
  aggregations.

  For details on cutoff-date semantics, performance thresholds (such as adding
  expression indexes at ~100k events), and open-shape map contracts, refer
  to the [Analytics Guide](guides/analytics.md).
  """

  import Ecto.Query, only: [from: 2, subquery: 1, where: 3]

  alias Accrue.Billing.{Customer, Invoice, PaymentMethod, Subscription}
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Oban.Job

  @recovered_type "dunning.recovered"
  @exhausted_type "dunning.exhausted"
  @events_table Accrue.Migration.qualified_table(:accrue_events)
  @invoices_table Accrue.Migration.qualified_table(:accrue_invoices)
  @terminal_exists_sql "NOT EXISTS (SELECT 1 FROM #{@events_table} WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = ?::text AND inserted_at >= ?)"
  @step_count_sql "(SELECT COUNT(*) FROM #{@events_table} WHERE type = 'dunning.step_sent' AND subject_id = ?::text AND inserted_at >= ?)"
  @failure_reason_sql """
  (SELECT e.data FROM #{@events_table} e
     JOIN #{@invoices_table} i ON i.id::text = e.subject_id
     JOIN #{@events_table} cs ON cs.type = 'dunning.campaign_started'
                          AND cs.subject_id = ?::text
                          AND cs.data->>'invoice_id' = i.processor_id
   WHERE e.type = 'invoice.payment_failed'
     AND e.inserted_at >= ?
   ORDER BY e.inserted_at DESC
   LIMIT 1)
  """

  @dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]

  @doc """
  Folds the `accrue_events` ledger into lists of recovered and lost MRR,
  grouped by currency.

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
      %{
        recovered: [%{currency: "usd", cents: 12000}],
        lost: [%{currency: "usd", cents: 3000}]
      }

  """
  @doc since: "1.3.0"
  @spec recovered_vs_lost_mrr(keyword()) :: %{
          recovered: [%{currency: String.t(), cents: non_neg_integer()}],
          lost: [%{currency: String.t(), cents: non_neg_integer()}]
        }
  def recovered_vs_lost_mrr(opts \\ []) when is_list(opts) do
    query =
      from(e in Event,
        where: e.type in [@recovered_type, @exhausted_type],
        group_by: [e.type, fragment("?->>'currency'", e.data)],
        select:
          {e.type, fragment("?->>'currency'", e.data),
           sum(
             fragment(
               "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
               e.data,
               e.data
             )
           )}
      )
      |> apply_window(opts)

    Repo.all(query)
    |> Enum.reduce(%{recovered: [], lost: []}, fn {type, currency, cents}, acc ->
      entry = %{currency: currency || "usd", cents: cents || 0}

      case type do
        @recovered_type -> Map.update!(acc, :recovered, &[entry | &1])
        @exhausted_type -> Map.update!(acc, :lost, &[entry | &1])
        _ -> acc
      end
    end)
  end

  @doc """
  Computes the arithmetic recovery rate from the dunning funnel.

  Calculates the rate as `recovered / (recovered + exhausted)`.
  Returns `%{rate: 0.0..1.0 | nil, recovered: N, total_concluded: N}`.
  If `total_concluded` is 0, `rate` is `nil` to prevent division by zero.

  ## Options

    * `:since` — `%DateTime{}` lower bound (inclusive on `inserted_at`).
    * `:until` — `%DateTime{}` upper bound (inclusive on `inserted_at`).

  """
  @doc since: "1.3.0"
  @spec recovery_rate(keyword()) :: %{
          rate: float() | nil,
          recovered: non_neg_integer(),
          total_concluded: non_neg_integer()
        }
  def recovery_rate(opts \\ []) when is_list(opts) do
    stats = funnel(opts)
    total = stats.recovered + stats.exhausted

    rate = if total > 0, do: stats.recovered / total, else: nil

    %{
      rate: rate,
      recovered: stats.recovered,
      total_concluded: total
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

  """
  @doc since: "1.3.0"
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

  """
  @doc since: "1.3.0"
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
        where: fragment(@terminal_exists_sql, s.id, s.dunning_campaign_started_at),
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
          current_step: fragment(@step_count_sql, s.id, s.dunning_campaign_started_at),
          next_step_eta: min(j.scheduled_at),
          failure_reason: fragment(@failure_reason_sql, s.id, s.dunning_campaign_started_at)
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
  @doc since: "1.3.0"
  @spec campaign_timeline(String.t(), keyword()) :: [Event.t()]
  def campaign_timeline(subscription_id, opts \\ [])
      when is_binary(subscription_id) and is_list(opts) do
    Accrue.Events.timeline_for("Subscription", subscription_id, opts)
    |> Enum.filter(&String.starts_with?(&1.type, "dunning."))
  end

  @doc """
  Returns dunning events for a subscription grouped into campaign arcs.
  """
  @doc since: "1.3.0"
  @spec campaign_timeline_grouped(String.t(), keyword()) :: [{String.t() | nil, [Event.t()]}]
  def campaign_timeline_grouped(subscription_id, opts \\ [])
      when is_binary(subscription_id) and is_list(opts) do
    campaign_timeline(subscription_id, opts)
    |> group_into_arcs()
  end

  defp group_into_arcs([]), do: []

  defp group_into_arcs(events) do
    {arcs, current} =
      Enum.reduce(events, {[], nil}, fn event, {arcs, current} ->
        if event.type == "dunning.campaign_started" do
          arcs = if current, do: [current | arcs], else: arcs
          {arcs, {event.data["campaign_anchor"], [event]}}
        else
          case current do
            nil -> {arcs, {nil, [event]}}
            {anchor, evts} -> {arcs, {anchor, [event | evts]}}
          end
        end
      end)

    arcs = if current, do: [current | arcs], else: arcs

    arcs
    |> Enum.reverse()
    |> Enum.map(fn {anchor, evts} -> {anchor, Enum.reverse(evts)} end)
  end

  @doc """
  Returns a map of invoices for a given subscription, keyed by Stripe processor_id.
  """
  @doc since: "1.3.0"
  @spec invoices_for_campaign(String.t(), keyword()) :: %{String.t() => map()}
  def invoices_for_campaign(subscription_id, opts \\ [])
      when is_binary(subscription_id) and is_list(opts) do
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
