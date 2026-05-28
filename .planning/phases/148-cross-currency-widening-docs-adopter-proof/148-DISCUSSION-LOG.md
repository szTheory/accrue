# Phase 148: Cross-currency widening + recovery-rate API + public docs + adopter-proof - Discussion Log

## Gray Areas & Architectural Decisions

### 1. `recovered_vs_lost_mrr/1` Cross-Currency Ecto Query
**Context:** DAN-07 requires breaking the return shape from `%{recovered_cents: N, lost_cents: N}` to `%{recovered: [%{currency: "usd", cents: N}, ...], lost: [...]}`. 
**Recommendation (One-Shot):**
Update the Ecto query to group by both `e.type` AND the `currency` extracted from the JSONB `data` field.
```elixir
group_by: [e.type, fragment("?->>'currency'", e.data)],
select: {
  e.type,
  fragment("?->>'currency'", e.data),
  sum(
    fragment(
      "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
      e.data,
      e.data
    )
  )
}
```
Then, `Enum.reduce` the result set into the `%{recovered: [], lost: []}` shape.
*Pros:* Idiomatic Ecto, pushes all aggregation to Postgres, scales perfectly with the `data->>'currency'` access pattern.
*Impact on Adopters:* Single-currency users (the vast majority) just get a 1-item list, which maps elegantly over UI comprehensions.

### 2. `recovery_rate/1` Implementation
**Context:** DAN-06 requires a public API returning `%{rate: 0.0..1.0 | nil, recovered: N, total_concluded: N}`.
**Recommendation (One-Shot):**
Delegate internally to `Accrue.Analytics.Dunning.funnel/1`. The `funnel/1` query already implements the complex, critical logic for DISTINCT `(subject_id, campaign_anchor)` tuples. Re-implementing a count query just for `recovery_rate/1` risks drifting from the funnel's numbers (Pitfall #1).
```elixir
def recovery_rate(opts \\ []) do
  %{recovered: rec, exhausted: exh} = funnel(opts)
  total = rec + exh
  rate = if total > 0, do: rec / total, else: nil
  %{rate: rate, recovered: rec, total_concluded: total}
end
```
*Pros:* Guaranteed mathematical consistency with the funnel; zero duplicated Ecto logic; fast enough for the dashboard since both share the same bounds.

### 3. "Showing data since" UI Badge Placement
**Context:** DAN-14 dictates the cutoff-date semantics need a "Showing data since YYYY-MM-DD" UI badge explanation.
**Recommendation (One-Shot):**
Add a pill/badge component to `RecoveryLive`'s header, next to the `WindowSelector`. It will display `Showing data since <first_event_date>` or just link to the new `guides/analytics.md`. A simple `Accrue.Events.earliest_dunning_event_date()` query can fetch the bounding date, or it can be a static documentation badge if the date is dynamic. Given the Phase 144 note ("UI badge ships with the guide"), placing an informative badge in the `RecoveryLive` template that links directly to the `guides/analytics.md` provides the best adopter UX.

### 4. Admin UI Multi-Currency KPI Grid
**Context:** We need one pair of KPI cards per currency without breaking the layout.
**Recommendation (One-Shot):**
In `RecoveryLive`, compute a list of currencies present in the `recovered_vs_lost_mrr` result. Use a `for currency <- @currencies` comprehension to render the Recovered and Exhausted KPI cards. For the 99% of single-currency adopters, they will see exactly what they saw before. For multi-currency, the grid naturally wraps (e.g., USD Recovered, USD Exhausted, EUR Recovered, EUR Exhausted).

## Resolution
These recommendations fulfill the Phase 148 Success Criteria perfectly while maintaining the library's design principles (Postgres as the aggregation engine, strict tuple counting, clean UI). 

Proceeding to Plan Phase.