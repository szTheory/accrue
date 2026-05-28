# Analytics and Dunning Recovery

Accrue's `Accrue.Analytics.Dunning` module surfaces MRR recovery metrics directly from the immutable `accrue_events` ledger using Ecto JSONB aggregations. This approach avoids maintaining separate roll-up tables and ensures metrics exactly match the raw events.

## Public API Surface and Open-Shape Contracts

The core analytics APIs return flat maps and lists of maps. These are **open-shape contracts**: Accrue guarantees the documented keys will be present, but may add new keys in minor updates.

### `recovered_vs_lost_mrr/1`

Folds the ledger into lists of recovered and lost MRR, grouped by currency.

```elixir
%{
  recovered: [%{currency: "usd", cents: 12000}, %{currency: "jpy", cents: 50000}],
  lost: [%{currency: "usd", cents: 3000}]
}
```

### `funnel/1`

Returns a three-stage dunning funnel computed by collapsing `(subject_id, campaign_anchor)` tuples.

```elixir
%{
  entered: 15,
  recovered: 8,
  exhausted: 2,
  active: 5
}
```

### `recovery_rate/1`

Calculates the arithmetic recovery rate as `recovered / (recovered + exhausted)`.

```elixir
%{
  rate: 0.8,
  recovered: 8,
  total_concluded: 10
}
```

## Window Semantics

Analytics queries support `:since` and `:until` options for time-bounding.
- These windows operate on **outcome-timestamp attribution** (the `inserted_at` of the `dunning.recovered` or `dunning.exhausted` event).
- All window bounds must be provided in **UTC** as `%DateTime{}`.

## Per-Currency Contract

Accrue aggregates MRR exactly as denominated in the event ledger. **No FX conversion** is performed. If your application processes multiple currencies, you will receive separate KPI buckets for each currency.

## Cutoff-Date Semantics

Pre-Phase-144 legacy dunning events lacked a `campaign_anchor` in their JSON payload. The `funnel/1` query collapses these legacy events using a `"__legacy__"` sentinel, which means `entered` may be under-counted if a subject cycled through multiple legacy campaigns. 
Because `accrue_events` is strictly immutable (SQLSTATE 45A01), these records cannot be backfilled. The Admin UI renders a **"Showing data since YYYY-MM-DD"** badge to clarify when structurally-complete analytics began tracking.

## Performance Guide

By default, analytics queries use Postgres sequential scans over `accrue_events`. This is fast enough for typical SaaS applications. However, once you cross **100k events** (or need faster dashboard renders), you should add a JSONB expression index to maintain dashboard performance:

```sql
CREATE INDEX idx_accrue_events_mrr 
ON accrue_events ((CAST(data->>'mrr_value_cents' AS integer))) 
WHERE type IN ('dunning.recovered', 'dunning.exhausted');
```

## Admin-Auth Limitations and Escape Hatch

The LiveView dashboard at `/billing/analytics/recovery` requires your `Accrue.Auth` adapter to provide admin authentication. If you want to embed these KPIs directly into your own host application (e.g., a merchant-facing dashboard where merchants see their own metrics), you can call the `Accrue.Analytics.Dunning` functions directly and bypass the admin UI entirely.