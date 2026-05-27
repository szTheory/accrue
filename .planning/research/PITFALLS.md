# PITFALLS — v1.44 Recovered-Revenue Dashboard Completion

**Domain:** Adding a funnel/drill-down/time-filter analytics dashboard on top of Phase 143's MRR-snapshotting event-ledger foundation.
**Researched:** 2026-05-27
**Confidence:** HIGH — every pitfall below is grounded in actual source files (`Accrue.Analytics.Dunning`, `Accrue.Webhook.DefaultHandler`, `Accrue.Events.Event`, the immutable-ledger migration, Phase 143-VERIFICATION). Where industry-pattern advice is cited, it is marked LOW/MEDIUM.

**Scope discipline:** these are pitfalls *specific to extending Phase 143 into a funnel+drill-down dashboard on Accrue's event-ledger SSOT architecture*. Generic "test edge cases" or "validate inputs" advice is intentionally excluded. Each pitfall has: warning signs, prevention, the v1.44 phase that should own it, and a concrete falsifiable check (test name, assertion, doc clause, or ADR).

**Anchor decisions inherited from Phase 143 (do not relitigate):**
- MRR is snapshotted at emission time into `data.mrr_value_cents` + `data.currency` on `dunning.recovered` and `dunning.exhausted`.
- `accrue_events` is immutable (Postgres `BEFORE UPDATE/DELETE` trigger raises `SQLSTATE '45A01'`). **Backfill cannot rewrite history — it can only append new compensating events.**
- The only composite index on `accrue_events` today is `(type, inserted_at)` (per `20260414130500_add_events_type_inserted_at_index.exs`); there is **no GIN index on `data` or expression index on `data->>'mrr_value_cents'`**.
- Phase 143 has **no test asserting `data["mrr_value_cents"]` at the DefaultHandler emission boundary** (called out in 143-VERIFICATION "Notes"). That gap propagates risk to v1.44.
- Dunning state is encoded by **two columns on `accrue_subscriptions`** (`dunning_campaign_started_at` is the live anchor; `dunning_sweep_attempted_at` records sweep activity) plus the lifecycle status. There is **no `Accrue.Dunning.Campaign` schema/table** — the module of that name is a *pure step resolver*, not a record. (`Accrue.Dunning.Campaign` in source is 104 LOC, all `defp pending_step?` math.) Any phase plan that references a campaign table is wrong.

---

## Critical Pitfalls (correctness-class — would make the dashboard *wrong* in production)

### Pitfall 1: Funnel double-counting a single dunning episode across stages

**What goes wrong:**
A naive funnel renders "Entered → Recovered → Exhausted" by counting events of each type independently:

```elixir
# WRONG — double-counts
%{
  entered:   count(type == "dunning.campaign_started"),
  recovered: count(type == "dunning.recovered"),
  exhausted: count(type == "dunning.exhausted")
}
```

This counts every event row, but a **single subscription can enter dunning multiple times** (recovers, fails again, recovers again). Worse, a single dunning *episode* emits BOTH `dunning.campaign_started` AND `dunning.recovered` — both are real, both pass `WHERE type IN (...)`. The funnel rendering "entered: 100, recovered: 80, exhausted: 30" leaks: 80 + 30 = 110 > 100. Operator looks at it, can't reconcile, loses trust in the dashboard within minutes.

**Why it happens in Accrue specifically:**
- The ledger is a **flat append-only log**, not a state machine view. There is no episode_id linking `campaign_started → recovered/exhausted` natively (verified: no such field in event schema).
- The reducer in `default_handler.ex:855-921` already proves that the same `subscription_id` cycles through dunning multiple times (the anchor is nilled on recovery and re-set on the next `past_due`).
- `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` today sums *event-level* MRR cents, not distinct-subscription totals — and that's *correct for the MRR KPI* (total dollars recovered) but **wrong for a funnel where the denominator must be unique entrants**.

**How to avoid (canonical de-dup approach):**

1. **Lock funnel attribution to the campaign anchor, identified by `(subject_id, dunning_campaign_started_at)`.** Every campaign has a unique anchor timestamp; once cleared (recovery) or re-set (re-entry), it's a new episode. Snapshot the anchor onto the recovered/exhausted events:

   ```elixir
   # In maybe_emit_dunning_exhaustion/2 and maybe_finalize_dunning_campaign/2
   Events.record(%{
     ...
     data: %{
       ...,
       campaign_anchor: DateTime.to_iso8601(row.dunning_campaign_started_at)
     }
   })
   ```

   This is a **Phase 143 forward-fix** — the anchor is already in scope at both emission sites (verified `default_handler.ex:867,890`).

2. **Funnel query counts DISTINCT `(subject_id, campaign_anchor)` tuples per stage**, not raw event rows. Invariant: `recovered_count + exhausted_count <= entered_count` always holds; any pre-aggregation row where it doesn't is a regression.

3. **The Hero MRR KPI stays as event-sum** (correct — counting dollars, not episodes). The funnel viz uses distinct-episode counts. These are *two different counts* with *two different denominators* and must be documented as such in the module doc.

**Prevention check (concrete):**
- **Test:** `Accrue.Analytics.DunningTest` — seed 1 subscription with 3 cycles (entered → recovered → entered → exhausted → entered → still-active) and assert `funnel().entered == 3 && funnel().recovered == 1 && funnel().exhausted == 1 && funnel().active == 1`.
- **Property test (`stream_data`):** for any seeded ledger, `recovered + exhausted + active <= entered`. Hard invariant.
- **ADR:** "Funnel denominator is distinct `(subject_id, campaign_anchor)` tuples. MRR KPI denominator is event-row sum. These are distinct on purpose."

**Owning phase:** v1.44 funnel-viz phase (the first one that introduces multi-stage rendering). Must precede the at-risk drill-down phase because at-risk count is also part of the funnel.

---

### Pitfall 2: Stale dunning state — "at-risk" customers who already paid

**What goes wrong:**
The "At-Risk Subscriptions" drill-down table renders subscriptions whose `dunning_campaign_started_at IS NOT NULL` (anchor still set) AS "currently in dunning, at risk." But there is a real window where Stripe has marked the invoice paid yet Accrue's projection hasn't caught up:

1. Customer's retry succeeds at Stripe.
2. Stripe enqueues `invoice.payment_succeeded` and `customer.subscription.updated` webhooks.
3. Webhook hits Accrue, plug verifies + persists raw → 200 OK fast path → Oban enqueues the dispatch worker.
4. Oban worker runs, reducer fires, anchor nilled.
5. **Between step 2 and step 4** — could be 100ms, could be 10s if `accrue_webhooks` queue is saturated — the dashboard shows the customer as "at risk" while Stripe shows them as paid.

This is exactly the "Crucial Footgun" pattern called out in the v1.44 assessment for Candidate B notifications. It applies equally to **visual displays** — an operator looking at the dashboard and contacting a customer to "save the account" creates a bad customer experience.

**Why it happens in Accrue specifically:**
- The path is verify → persist → enqueue → 200 (per CLAUDE.md performance budget). The dispatch is **async by design** — the projection write does not block the webhook response.
- `Accrue.Billing.Subscription.dunning_campaign_active?/1` (line 270) is a pure local-projection check — it has no notion of "Stripe says paid but we haven't projected yet."
- The MRR snapshotting is fine (it happens at projection time, so the recovered/exhausted events carry correct values). The lag is purely in the *live* at-risk display.

**How to avoid:**

1. **Make the at-risk query honest about being a projection, not a live view.** Surface the projection age:

   ```elixir
   def at_risk_subscriptions(opts \\ []) do
     # Returns {subs, stale_after: %DateTime{}} where stale_after is
     # the oldest webhook timestamp Accrue has not yet caught up to.
     ...
   end
   ```

   In the LiveView, show "Last reconciled: 30s ago. Some entries may be stale." This is the Stripe Dashboard's own pattern (LOW confidence — based on Stripe's "Eventually consistent" disclaimer on their analytics tabs).

2. **For the drill-down per-customer view, refresh from `Accrue.Billing.Subscription` at click-time.** Don't rely on the row from the cached query. This is the analog of Candidate B's "fetch live invoice status inside `perform/1`."

3. **Document the convergence window prominently.** "At Risk" is a *projection*, not a *live Stripe call*. If an operator needs real-time truth, they go to Stripe.

4. **Defer "true live" at-risk to v1.45+** by piggybacking on the notification convergence work (assessment Candidate B). Don't try to solve eventual-consistency in v1.44.

**Prevention check (concrete):**
- **Test:** `AccrueAdmin.Live.Analytics.RecoveryLiveTest` — seed an event-ledger where `dunning.recovered` has been recorded but `dunning_campaign_started_at` is still non-nil (the impossible-but-tested race). Assert the at-risk list **excludes** subscriptions whose **most recent** dunning-lifecycle event is `recovered`/`exhausted`. (Belt-and-suspenders: use the ledger as the tiebreaker, not the projection column.)
- **Doc clause** in `Accrue.Analytics.Dunning` moduledoc: "`at_risk_subscriptions/1` reflects local projection state. If a customer just paid at Stripe and the corresponding webhook has not yet been processed, they may briefly appear here. For real-time status, query Stripe directly."

**Owning phase:** v1.44 at-risk drill-down phase. Must include the "ledger-trumps-projection" tiebreaker on day one — it's a five-line change and removes a whole class of regression.

---

### Pitfall 3: Legacy events have no `mrr_value_cents` — backfill on an immutable ledger

**What goes wrong:**
Before Phase 143 (~2026-05-27), all `dunning.recovered` and `dunning.exhausted` events in production were emitted WITHOUT `mrr_value_cents`. The aggregation `sum(fragment("(?->>'mrr_value_cents')::integer", e.data))` on Postgres treats `NULL ::integer` as `NULL`, and `sum(NULL, NULL, 5000)` returns `5000` — Postgres `sum` *skips* nulls. So the dashboard **silently undercounts** historical recovered revenue. A SaaS that has been on Accrue for months will see "MRR Recovered: $4,200" when the truth is "$12,400 (only the last 8 days have data)."

Worse: **the events table is immutable** (Postgres `BEFORE UPDATE/DELETE` trigger raises `SQLSTATE '45A01'` per `20260411000001_create_accrue_events.exs:55-61`). You **cannot** "go back and fill in `mrr_value_cents` on the old rows." Any well-meaning ops engineer who tries will get a hard SQL error — and rightly so, because tamper-evidence is the point.

**Why it happens in Accrue specifically:**
- The ledger immutability is a design *feature* (D-09, tamper-evidence). It's not a bug to work around — it's a constraint to design within.
- Postgres' `NULL`-skipping `sum` is well-defined SQL but counter-intuitive to anyone who hasn't burned themselves on it.
- The 143 verification explicitly flagged "the field's presence is established by reading the production code" — meaning legacy rows have no field and the test suite does not cover them.

**How to avoid:**

There are three legitimate options. Choose ONE and document the choice via ADR:

1. **Cutoff-date label (RECOMMENDED for v1.44, lowest cost, most honest).** The dashboard renders a UI badge: "Showing data since 2026-05-27 — earlier dunning events do not include MRR snapshots." `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` accepts (and defaults to) `since: snapshot_floor()` where `snapshot_floor/0` returns a hardcoded cutoff date (the v1.44 release date) read from `Application.compile_env/2`. The window of incomplete data is excluded from the count by default; an operator who wants the full ledger can pass `since: ~U[2020-01-01 00:00:00Z]` and see the partial total with the badge "(partial: pre-snapshot events excluded)."

   **Cost:** ~20 LOC + a config key + one doc paragraph. **Risk:** zero — the cutoff is honest and operator-overridable. **Tradeoff:** small operators with no pre-v1.44 dunning history see no change. Large operators get one sentence of "we started measuring this on X."

2. **Compensating-event backfill (LARGER LIFT, deferred).** Write a Mix task `mix accrue.analytics.backfill_dunning_mrr` that scans pre-cutoff `dunning.recovered/exhausted` events, re-derives MRR by joining the *current* `accrue_subscriptions` row, and **appends** new events of type `dunning.recovered.backfilled` / `dunning.exhausted.backfilled` with `mrr_value_cents` and a `caused_by_event_id` pointer to the original. The aggregation widens its `type in (...)` clause. This is **honest because it preserves immutability** — old events remain unchanged; new compensating events stand alongside.

   **Cost:** ~150 LOC + 1 migration (none — append-only) + 2 new event types + aggregation widening + 30-min documentation. **Risk:** MRR re-derived from current subscription state is *not* the historical MRR (the subscription may have swapped plans since). Documented as upper-bound estimate. **Tradeoff:** ~1 week of work to do honestly; better fits v1.45. **Defer.**

3. **Hand-rolled SQL backfill (REJECT).** Some teams will be tempted to disable the immutability trigger, `UPDATE accrue_events SET data = jsonb_set(data, '{mrr_value_cents}', ...)`, then re-enable. **Reject in PITFALLS as anti-pattern.** It defeats tamper-evidence (D-09). It is not idempotent under multi-environment ops. It will be copy-pasted into adopter runbooks by junior engineers. The trigger exists precisely to prevent this.

**Prevention check (concrete):**
- **Test:** `Accrue.Analytics.DunningTest` — seed 3 events with `mrr_value_cents` and 2 events WITHOUT (`data: %{}`). Assert `recovered_vs_lost_mrr()` sums only the 3 events' values; assert the response includes `missing_snapshot_count: 2`. (Add this field to the return type — a 3-line change.)
- **Test:** the snapshot floor default works — calling `recovered_vs_lost_mrr()` with no opts uses the configured `:dunning_mrr_snapshot_floor` and excludes any event with `inserted_at < floor`. Override with explicit `since:` returns the full count.
- **ADR:** `ADR-v144-001-backfill-strategy.md` — document choice (cutoff-date), reject hand-rolled SQL, note backfill task is v1.45 deferred work.
- **Doc clause** in `Accrue.Analytics.Dunning` moduledoc: explain `since:` default, point operators at the override.

**Owning phase:** v1.44 backfill/cutoff phase (or fold into the funnel-viz phase — it's a configuration concern, not a feature concern). Must land **before** any operator-facing copy is finalized.

---

### Pitfall 4: Cross-currency summation produces meaningless totals

**What goes wrong:**
The Phase 143 implementation stores `currency` per event but the aggregation collapses across all currencies:

```sql
SELECT type, sum((data->>'mrr_value_cents')::integer) FROM accrue_events GROUP BY type
```

If the SaaS has USD, EUR, and GBP customers, this sums **cents-of-different-currencies into one integer**. The KPI card shows `"$157.42"` for `recovered_cents: 15742` — but that 15742 is actually `(USD 8000 + EUR 5000 + GBP 2742)` cents-of-different-things. The dollar sign is a lie.

**Why it happens in Accrue specifically:**
- The currency *is* snapshotted on each event (verified `default_handler.ex:783,881`), so the data is correct — it's the *query* that's wrong.
- The current `recovered_vs_lost_mrr/1` signature returns a single `{:recovered_cents, :lost_cents}` map with no currency field — there's no place to put a per-currency breakdown.
- Most Phoenix SaaS apps in 2026 are single-currency, so the bug rarely *fires* in test, but does fire for real EU/UK adopters.

**How to avoid:**

1. **Group by currency in the aggregation.** Return shape becomes `%{recovered: [%{currency: "usd", cents: 12000}, %{currency: "eur", cents: 4500}], lost: [...]}`. The default LiveView KPI card renders per-currency rows; if only one currency exists, it renders as a single row (no UI regression for single-currency adopters).

2. **For the funnel viz and at-risk table:** add a currency filter (defaults to "all" — sum-of-counts is fine for counts of subscriptions; only the *money* values need currency grouping). At-risk rows show their per-row currency.

3. **DO NOT attempt FX conversion.** Accrue is not an FX library; converting at query-time requires a rate source, snapshot semantics for the rate (which date's rate?), and a whole class of tests. Show per-currency. Document: "If you need a unified-currency view, convert at the BI tier."

**Prevention check (concrete):**
- **Test:** `Accrue.Analytics.DunningTest` — seed events in `"usd"`, `"eur"`, `"gbp"` and assert the return has three currency entries with correct per-currency sums. Property test: `Enum.sum(per_currency_cents) == old_collapsed_sum` (i.e., the new shape is no less inclusive).
- **LiveView test:** assert that a 3-currency seed renders 3 KPI rows (one per currency) and that single-currency seed renders 1 row.
- **Doc clause:** "`recovered_vs_lost_mrr/1` returns per-currency lists. Accrue does not perform FX conversion."

**Owning phase:** v1.44 public-API/docs phase (the one that finalizes `Accrue.Analytics.Dunning`'s shape — this is the last chance to widen the return type without a breaking change). MUST land before "1.4.0 publish" or it locks in the wrong API.

---

## Moderate Pitfalls (would degrade UX or perf, but not corrupt data)

### Pitfall 5: JSONB cast errors on malformed events

**What goes wrong:**
`fragment("(?->>'mrr_value_cents')::integer", e.data)` raises `Postgrex.Error` if any single row's `data->>'mrr_value_cents'` is not castable to integer (e.g., `"50.00"` instead of `5000`, or a stray `"unknown"` from a future bug, or — common — a snapshot from a partial backfill that wrote a string). One bad row breaks the **entire dashboard mount**.

**Why it happens in Accrue specifically:**
- The MRR calc in `default_handler.ex:1896-1923` is integer-only (all `div(amount * quantity, ...)`), so production-emitted values are always integers. **But**: the schema column is `jsonb`, accepting anything; future event sources (admin manual entry, backfill scripts, replays from old DBs) could inject strings.
- One row poisons the entire `Repo.all/1` — there's no partial-fail.

**How to avoid:**

Replace the bare cast with a `CASE` that filters non-numeric values:

```elixir
fragment(
  "CASE WHEN jsonb_typeof(?->'mrr_value_cents') = 'number' " <>
    "THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
  e.data, e.data
)
```

This treats any non-number (string, null, missing) as `0`, and emits a `:telemetry` warning when a non-number is encountered for an operator to investigate.

**Prevention check (concrete):**
- **Test:** seed an event with `data: %{"mrr_value_cents" => "5000"}` (string-as-number). The aggregation runs without raising and skips that row. Telemetry `[:accrue, :analytics, :dunning, :malformed_event]` fires once.
- **Doc clause:** "Events with non-numeric `mrr_value_cents` are skipped silently with a telemetry warning."

**Owning phase:** v1.44 funnel-viz phase (any phase that touches the aggregation query). One-line change at low cost.

---

### Pitfall 6: LiveView socket memory blow-up on the at-risk table

**What goes wrong:**
The at-risk drill-down table assigns the full list of at-risk subscriptions to the socket (`assign(socket, :at_risk, subs)`). With 500+ at-risk customers × auto-refresh every 10s × time-window filter requerying the list × each customer struct carrying ~2KB of nested Stripe data → ~1MB resident per socket × 50 concurrent operator sessions = 50MB+ of BEAM heap, plus full re-renders pushing 500-row DOM diffs over the wire.

**Why it happens in Accrue specifically:**
- LiveView 1.1 (our pinned version) ships `Phoenix.LiveView.stream/4`, which exists *specifically* for this — but the Phase 143 LiveView at `recovery_live.ex` uses plain `assign/3` for stats. Easy to copy that pattern into the drill-down. (`stream/4` is the correct abstraction, not `assign/3`, for collections that are appended/inserted.)
- The auto-refresh temptation: a `Process.send_after(self(), :refresh, 10_000)` loop is one line, looks innocent, but compounds the memory issue.

**How to avoid:**

1. **At-risk table uses `Phoenix.LiveView.stream/4`**, not `assign/3`. Each row is a stream member; replacements happen by `stream_insert/4` keyed on subscription_id. Memory is freed on row removal.

2. **Paginate by default (50 per page)**, with explicit "Show all" override. The default `at_risk_subscriptions/1` function takes `limit:` and `offset:` opts.

3. **No auto-refresh in v1.44.** The operator hits the "Refresh" button if they want fresh data. Auto-refresh is a v1.45 concern coupled with PubSub-from-webhook (live updates pushed by the dispatcher), which is a separate design.

4. **Defer to streams + pagination, not virtual scrolling.** Virtual scrolling LiveView libs (e.g., `live_view_native_virtual_list`) are heavyweight and not justified at 500-row scale.

**Prevention check (concrete):**
- **Test:** `AccrueAdmin.Live.Analytics.RecoveryLiveTest` — seed 200 at-risk subscriptions, assert that only 50 are rendered by default and pagination controls exist.
- **Assertion in the LiveView module:** `use Phoenix.LiveView` followed by `stream(socket, :at_risk, [])` in mount; assert at code-review time that the at-risk table uses `<.row :for={{id, sub} <- @streams.at_risk} id={id}>` not `<.row :for={sub <- @at_risk}>`.
- **ADR:** "Auto-refresh deferred to v1.45 with PubSub-from-dispatcher."

**Owning phase:** v1.44 at-risk drill-down phase. The streams choice is foundational — switching from `assign/3` to `stream/4` after the fact requires re-testing every interaction.

---

### Pitfall 7: Time-window math: timezone, DST, and rolling-vs-calendar confusion

**What goes wrong:**
Three distinct subpitfalls, all in one bucket because they share a prevention:

(a) **Server-time vs operator-local.** `inserted_at` is stored as UTC (per `Accrue.Events.Event` schema: `:utc_datetime_usec`). The dashboard's "Last 30 days" filter computes `since: DateTime.utc_now() |> DateTime.add(-30, :day)`. An operator in PST viewing the dashboard at 11pm on May 31 sees "May" data ending at "May 31 23:59 UTC" = "May 31 16:59 PST" — the last 7 hours of their day are missing. They reload at midnight, see the same thing, lose trust.

(b) **DST transitions.** A 7-day rolling window crossing a DST boundary is 7×24×3600 seconds in UTC but the operator may experience it as "7 days minus 1 hour" or "7 days plus 1 hour." Math is correct (we use UTC throughout) but the *operator's mental model* is "last week's data" which is locally biased.

(c) **Rolling vs calendar.** "Last 30 days" (rolling: now-30d to now) is NOT the same as "May" (calendar). Baremetrics defaults to rolling; Stripe Dashboard defaults to calendar. Operators routinely confuse the two ("but my chart says $4k recovered in May, why does the email summary say $3.7k?").

**Why it happens in Accrue specifically:**
- `accrue_events.inserted_at` is `:utc_datetime_usec`. Good — there's no ambiguity at the storage layer.
- Phase 143's `recovered_vs_lost_mrr/1` accepts arbitrary `since:`/`until:` `DateTime{}` values, so the API is correct. The bug is **in the UI** where the rolling/calendar choice and timezone is made.
- LiveView has no notion of the connecting browser's timezone unless explicitly fetched (`Phoenix.LiveView.JS` push or `Intl.DateTimeFormat().resolvedOptions().timeZone`).

**How to avoid:**

1. **Display all times in UTC, labeled "UTC".** Don't try to localize. The dashboard is operator-facing, not customer-facing — operators understand UTC. (Baremetrics: localized. Stripe: UTC labeled. We pick Stripe's pattern — less surface area, no timezone library, no DST bugs.)

2. **Default window is calendar-current-month**, with explicit "Last 7d" / "Last 30d" / "Custom range" buttons. Both modes are clearly labeled ("May 2026 (UTC)" vs "Last 30 days (UTC)").

3. **DST is moot** because we never present local time. UTC has no DST.

4. **"Spanning" subscriptions** (entered dunning before window, recovered inside) — the funnel attributes by **the event timestamp**, not the campaign start. An event `dunning.recovered` at 2026-05-15 is part of the May funnel regardless of when its campaign started. This is the same convention Stripe uses for refunds and chargebacks. Document explicitly: "Counts reflect the time the *outcome event* was recorded, not the time the campaign started."

**Prevention check (concrete):**
- **Test:** seed a `dunning.recovered` event with `inserted_at: ~U[2026-05-31 23:59:00Z]`. Assert that the May calendar window includes it, the June calendar window does not.
- **Test:** seed two events 7 days 1 hour apart; assert the 7-day rolling window contains exactly one.
- **UI assertion:** "UTC" label appears next to every time-range selector. Snapshot test catches removal.
- **Doc clause:** "All times in UTC. Spanning campaigns are attributed by the outcome event's timestamp."

**Owning phase:** v1.44 time-window filter phase. Set the convention on day one; do not let it drift across follow-on phases.

---

### Pitfall 8: Operator misinterpretation of "Recovered MRR"

**What goes wrong:**
Operators read "Recovered MRR: $14,200" and think "$14,200 hit our bank account this month." Truth: `dunning.recovered` fires when the campaign *concludes successfully* (subscription transitions back to active/paid). The MRR snapshotted is the **monthly contract value** — a customer on a $100/yr plan contributes ~$8.33 to MRR but has only one invoice of $100 cleared in the month. Conversely a customer on a 3-month $300 plan contributes ~$100/mo MRR. The number is *correct as MRR* but *misleading as cashflow*.

Also: a recovered $50/mo customer might still churn next month — "Recovered MRR" is a measure of dunning's success at THIS recovery, not annualized retained revenue.

Also: "Lost MRR" carries negative framing. The v1.44 assessment Lesson from Baremetrics is "Frame positively — say 'Recovered Revenue', not 'Failed Payments'." Applies symmetrically: don't say "Lost MRR" — call it "Exhausted MRR" (the dunning campaign was *exhausted* — neutral, accurate) or "Unrecovered MRR" (also accurate, less framing-laden than "Lost").

**Why it happens in Accrue specifically:**
- The Phase 143 LiveView renders the KPI as `"Lost MRR"` (143-VERIFICATION confirms: `<KpiCard ... label="Lost MRR">`).
- The MRR value is correctly snapshotted at recovery time, but the *label* is the wrong word.

**How to avoid:**

1. **Rename "Lost MRR" → "Exhausted MRR"** in the LiveView. Tiny copy change, big trust signal.

2. **Add a tooltip / "What's this?" affordance on the KPI cards:**
   - Recovered MRR: "Sum of MRR for subscriptions that re-activated after entering dunning. This is monthly recurring value — actual cash collected may differ if the plan is yearly or has prorations."
   - Exhausted MRR: "Sum of MRR for subscriptions that did not recover and were marked unpaid or canceled."

3. **Do NOT add "Annualized Recovered MRR" as a second KPI in v1.44.** It compounds confusion. If demand emerges, add it in v1.45 with a documented `* 12` and an explicit "annualized" tag.

4. **Do NOT show "Money in the Bank" — that's a different question** (it's settled-invoice cashflow, owned by `Accrue.Billing.Invoice` queries, not the dunning analytics).

**Prevention check (concrete):**
- **LiveView snapshot test:** assert the rendered HTML contains `"Exhausted MRR"`, NOT `"Lost MRR"`.
- **Doc clause:** define "Recovered MRR" and "Exhausted MRR" in the guide with a concrete worked example: customer on $50/mo enters dunning, recovers → contributes $50 to Recovered MRR. Customer on $600/yr enters dunning, exhausts → contributes $50 to Exhausted MRR (`$600 / 12`).
- **Tooltip presence asserted in test.**

**Owning phase:** v1.44 funnel-viz phase or whichever phase finalizes operator-facing copy. Should be done in the same PR as ANY copy work — single source of truth for terminology.

---

### Pitfall 9: Public-API guarantees over-commit on event shape and query signature

**What goes wrong:**
Phase 143's `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` is becoming part of the *public Accrue API* in v1.44. Once it ships in 1.4.0 on Hex, the return shape and event-field reliance are **stability commitments** under semver. Mistakes that lock in:

- Return type `%{recovered_cents: int, lost_cents: int}` — single-currency assumption baked in (see Pitfall 4). Changing to per-currency in 1.5 is a breaking change.
- Reading `data["mrr_value_cents"]` — implies that field is part of the *public event schema*. Future event-shape changes (e.g., switching to `data["mrr_minor_units"]` to match `Decimal` conventions, or breaking out `mrr_value_cents_by_item`) become breaking changes for adopters who wrote their own analytics on top.
- Performance characteristics: if the dashboard works at 10k events on a customer's DB, they'll write blog posts saying "Accrue analytics scales to 10k events." If it doesn't work at 1M events, that's *our* commitment.

**Why it happens in Accrue specifically:**
- Accrue is post-1.0 (1.2.0 published per gitStatus). The community now treats public modules as covered by semver.
- The "no new tables" constraint means the event ledger itself is the schema; widening the funnel API later may require schema-version bumps on the events.

**How to avoid:**

1. **Widen `recovered_vs_lost_mrr/1` return shape NOW to per-currency** (per Pitfall 4). One-time cost; locked-in benefit.

2. **Document the public-API contract explicitly:**
   - `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` IS public; signature is stable across 1.x.
   - The shape of `data` on `dunning.recovered`/`dunning.exhausted` events is *internal* — the analytics module is the public interface. Adopters who query the events table directly are off-roading.
   - Document this distinction in the moduledoc *and* in `guides/upgrade.md`.

3. **Add a `schema_version` semantic to dunning events.** The events already carry a `schema_version` integer column (per `Accrue.Events.Event`). Phase 143 sets it implicitly to 1. v1.44 should *explicitly* set `schema_version: 1` on emission and document the migration story for v2 events ("read both; aggregate over union; document migration in CHANGELOG").

4. **Performance commitment: state it as an SLO with an `EXPLAIN`-backed receipt, not a marketing promise.** "Tested with up to 100,000 `dunning.*` events on Postgres 14 with the composite `(type, inserted_at)` index. Query time <250ms p95. At higher volumes consider an expression index — see [Pitfall 11]."

**Prevention check (concrete):**
- **Documentation:** `Accrue.Analytics.Dunning` moduledoc names every function as `@spec` + "public/private" status + semver commitment.
- **CHANGELOG entry** for 1.4.0 includes "stable since 1.4.0" markers on the analytics functions.
- **`mix.exs`** package documentation lists `Accrue.Analytics.Dunning` in the official ExDoc groups.

**Owning phase:** v1.44 public-API/docs phase. MUST happen before publish.

---

## Minor Pitfalls (paper cuts, but each removes a real DX wart)

### Pitfall 10: Adopter-proof seeds produce flaky, time-dependent tests

**What goes wrong:**
Seeding realistic dunning data in `examples/accrue_host` requires events with `inserted_at` timestamps that exercise "last 7 days", "last 30 days", and "last year" buckets. The naive seed (`DateTime.utc_now() |> DateTime.add(-3, :day)`) produces tests that pass today and fail in 90 days when the seed is "outside" the test's assumed window.

**How to avoid:**

1. Use `Accrue.Clock` (the project's mockable clock) in all seed scripts. Tests freeze the clock; seeds use absolute dates relative to the frozen clock.
2. Document the seed pattern: "All seed timestamps are relative to `Accrue.Clock.utc_now()` at seed-script invocation time, not to wall-clock `DateTime.utc_now()`."
3. Adopter-proof tests assert *relative* counts ("3 in last 7d, 5 in last 30d") rather than absolute dollar values that drift.

**Prevention check:** the host `mix accrue.seed.dunning_demo` task runs successfully and produces a dashboard that renders ≥ 1 recovered, ≥ 1 exhausted, ≥ 1 at-risk in the last 30 days, no flakes across 100 successive invocations.

**Owning phase:** v1.44 adopter-proof phase (the one that updates `examples/accrue_host`).

---

### Pitfall 11: No expression index on `(data->>'mrr_value_cents')::integer` — perf cliff at scale

**What goes wrong:**
The current `(type, inserted_at)` composite index lets the dunning aggregation filter rows fast, but the `sum((data->>'mrr_value_cents')::integer)` is computed per-row in memory. At 100k+ `dunning.*` events, the aggregation goes from ~50ms to ~2s. The dashboard mount blocks the LiveView for 2s. Operator sees a frozen page.

**Why it happens in Accrue specifically:**
- No expression index on `data` exists in the migration set (verified — only `(subject_type, subject_id, inserted_at)` and `(type, inserted_at)`).
- Postgres GIN indexes on `jsonb` cover containment queries, NOT aggregations. The right index is a *btree expression index*: `CREATE INDEX ... ON accrue_events ((data->>'mrr_value_cents')) WHERE type IN (...)`.

**How to avoid:**

1. **DO NOT add the expression index in v1.44.** Document the threshold ("at >100k `dunning.*` events, add an expression index — see guide") and ship a migration *template* in `priv/accrue/templates/migrations/` for the adopter to run if they hit it.
2. Reason: the index has write-cost on every event insert; most adopters have <1k dunning events lifetime and don't need it. Premature optimization for the rare adopter is a cost on every adopter.
3. **DO add a guide section** in `accrue/guides/analytics.md`: "Performance: when to add the dunning MRR expression index." With actual `EXPLAIN ANALYZE` excerpts demonstrating the with/without difference.

**Prevention check:**
- Performance test (in a perf-tagged suite, not default `mix test`): seed 50k events, assert aggregation < 500ms.
- Guide section exists and is cross-linked from the `Accrue.Analytics.Dunning` moduledoc.

**Owning phase:** v1.44 public-API/docs phase. Pure documentation, no code change.

---

### Pitfall 12: Permission scope assumes single admin role

**What goes wrong:**
The Phase 143 route is nested inside `live_session :accrue_admin` (verified `router.ex:75-77`), gated by `AccrueAdmin.AuthHook` `:ensure_admin`. Any admin can view recovered-revenue data. A SaaS with "billing-readonly" support staff (who should see at-risk customers but not, e.g., issue refunds) has to grant them full admin to see the dashboard.

**Why it happens in Accrue specifically:**
- `accrue_admin` ships a binary admin/not-admin auth model (verified `auth_hook.ex:11`). There is no role granularity.
- This is consistent with the rest of `accrue_admin` — adding a role just for analytics would create inconsistent surface area.

**How to avoid:**

1. **For v1.44: do nothing.** Binary admin gate is consistent with the rest of the package and is the right call at this stage. Defer role-granularity to a future "operator roles" milestone (not on the v1.44-v1.46 roadmap).
2. **Document the limitation explicitly:** "Recovered-revenue analytics inherit the standard admin auth. Granular billing-readonly roles are not yet supported; if you need this, gate the route in your host app's pipeline."
3. **Provide an escape hatch in the guide:** show how to wrap the route in the host app's own pipeline to add a role check before falling through to Accrue's admin hook. This is a 10-line host-app code sample.

**Prevention check:** doc section exists; escape-hatch code sample is `mix test`-verified by a host-app integration test.

**Owning phase:** v1.44 public-API/docs phase. No code change in Accrue.

---

### Pitfall 13: `subject_id` is `:string`, not `:binary_id` — joining to `accrue_subscriptions` is ergonomic-soft

**What goes wrong:**
The at-risk drill-down wants to join from event-derived subject_ids to subscription rows for display ("show the customer name, plan, MRR"). `Accrue.Events.Event` defines `subject_id: :string` (verified line 42 of `event.ex`); `Accrue.Billing.Subscription.id` is `:binary_id` (UUID). The join works (UUIDs are strings in jsonb-friendly form) but type-mismatches in Ecto `join: e in Event, on: e.subject_id == s.id` will need a `type/2` cast or a fragment cast. Easy to get wrong.

**How to avoid:**

1. Provide a helper in `Accrue.Analytics.Dunning`:
   ```elixir
   def at_risk_with_subscriptions(opts \\ []) do
     # Encapsulates the cast; returns enriched rows.
   end
   ```
2. Document the cast in a guide and link from the moduledoc.

**Prevention check:** a `mix test` that seeds events + subscriptions and joins them through the helper without `Ecto.Query.CastError`.

**Owning phase:** v1.44 at-risk drill-down phase.

---

## Phase-to-Pitfall Map (gsd-roadmapper consumption)

| v1.44 Phase (proposed) | Pitfalls owned | Concrete must-do |
|------------------------|----------------|------------------|
| **Funnel viz** | #1, #5, #8 | DISTINCT (subject_id, campaign_anchor) test; CASE-in-fragment; rename "Lost" → "Exhausted"; Anchor snapshot retrofit to DefaultHandler |
| **At-risk drill-down** | #2, #6, #13 | Ledger-trumps-projection tiebreaker; `Phoenix.LiveView.stream/4` + pagination; `at_risk_with_subscriptions/1` helper |
| **Time-window filters** | #7 | UTC-only labels; default calendar-current-month; explicit "outcome timestamp" attribution |
| **Backfill / cutoff** | #3 | Cutoff-date label approach (option 1); `:dunning_mrr_snapshot_floor` config; ADR-v144-001 |
| **Public API & docs** | #4, #9, #11, #12 | Per-currency return shape; explicit semver markers; perf threshold guide; admin-role limitation doc |
| **Adopter-proof** | #10 | `Accrue.Clock`-based seeds; relative-count assertions; demo task |

## Pitfalls Deferred to v1.45+ (gsd-roadmapper: do not put these in v1.44)

| Deferred pitfall | Reason | When |
|------------------|--------|------|
| Compensating-event backfill (Pitfall 3, option 2) | Larger lift; v1.44 cutoff-date label is honest interim | v1.45 if adopter demand |
| Auto-refresh via PubSub-from-dispatcher (Pitfall 6) | Coupled to notification convergence work | v1.45 with multi-channel dunning |
| Granular operator roles (Pitfall 12) | Cross-cutting; not analytics-specific | Future "operator roles" milestone |
| FX conversion (Pitfall 4) | Out of scope — Accrue is not an FX library | Never (this is a downstream BI concern) |
| Annualized Recovered MRR KPI (Pitfall 8) | Compounds operator confusion; defer to adopter demand | v1.45+ behind a flag |

## What I Could Not Verify (HONEST GAPS)

1. **Baremetrics / Stripe Dashboard exact framing** — the recommendation to label "UTC" comes from my reading of how Stripe Dashboard *currently* displays times (LOW confidence, training-data based). Worth confirming with a screenshot capture before locking the UI convention.
2. **Postgres expression-index threshold** — the "100k events" threshold is a rule-of-thumb, not benchmarked on Accrue's schema specifically. The benchmark should be run on a representative adopter DB (or on the demo host) to anchor the guide section's numbers.
3. **LiveView 1.1 `stream/4` performance ceiling** — assumed to be "thousands of rows OK." If a real adopter has 50k+ at-risk subscriptions (probably means their dunning campaign is broken, but possible), pagination alone may not suffice. Out of scope for v1.44.
4. **Whether `mix phx.routes` will work in v1.44** — the 143-VERIFICATION flagged that `accrue_admin/router.ex` is a macro builder. If v1.44 verification plans use that command, they'll hit the same wall.

## Sources

- `/Users/jon/projects/accrue/.planning/phases/143/143-RESEARCH.md` — HIGH (codebase-grounded, this milestone's foundation)
- `/Users/jon/projects/accrue/.planning/phases/143/143-VERIFICATION.md` — HIGH (verified test outcomes + known gaps)
- `/Users/jon/projects/accrue/accrue/lib/accrue/analytics/dunning.ex` — HIGH (current query shape)
- `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex` (lines 770-921, 1896-1923) — HIGH (MRR calculation, emission sites, anchor handling)
- `/Users/jon/projects/accrue/accrue/lib/accrue/dunning/campaign.ex` — HIGH (confirmed pure resolver, no schema)
- `/Users/jon/projects/accrue/accrue/lib/accrue/events/event.ex` — HIGH (subject_id is `:string`, data is `:map`)
- `/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs` — HIGH (immutability trigger)
- `/Users/jon/projects/accrue/accrue/priv/repo/migrations/20260414130500_add_events_type_inserted_at_index.exs` — HIGH (current indexes)
- `/Users/jon/projects/accrue/.planning/threads/v1.44-NEXT-STEP-ASSESSMENT.md` — HIGH (the "Crucial Footgun" pattern explicitly applies)
- Postgres `NULL`-in-`sum` semantics — HIGH (Postgres docs, longstanding behavior)
- LiveView `stream/4` recommendation — MEDIUM (Phoenix LiveView 1.1 docs, common pattern)
- Baremetrics / Stripe UI conventions — LOW (training-data based; verify with screenshots before locking copy)
