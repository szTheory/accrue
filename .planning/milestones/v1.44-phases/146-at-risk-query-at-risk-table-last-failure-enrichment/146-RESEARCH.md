# Phase 146: At-risk query + at-risk table + last-failure enrichment — Research

**Researched:** 2026-05-27
**Domain:** Elixir/Ecto analytics query composition, Oban job querying, accrue_events ledger joins, Phoenix.Component HEEx rendering
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Query `oban_jobs.scheduled_at` directly via LEFT JOIN to `Oban.Job`, filtering on `worker = DunningStep`, `state IN ['available', 'scheduled', 'retryable']`, and `args` matching `subscription_id` + `campaign_started_at`. Returns `MIN(scheduled_at)` as next-step ETA.

**D-02:** Cross-module Oban query pattern is established via `Engine.Oban` — reuse, not new coupling.

**D-03:** Nil-ETA fallback displayed as `"—"`. No config-cadence computation fallback.

**D-04:** Add `invoice_id: get(canonical, :id)` to `dunning.campaign_started` event data map. Thread `canonical` into `emit_campaign_started/2` as second arg.

**D-05:** `at_risk_subscriptions/1` enriches with "Last failure reason" by joining the `invoice.payment_failed` accrue_event whose `subject_id` matches the `invoice_id` from `dunning.campaign_started` data.

**D-06:** Pre-v1.44 `dunning.campaign_started` events lack `invoice_id` → failure reason returns `nil`, displayed as `"—"`.

**D-07:** Do NOT use `canonical.last_finalization_error` — semantically wrong, always nil on payment_failed events.

**D-08:** SQL `NOT EXISTS` correlated subquery as ledger tiebreaker: exclude subscriptions where `EXISTS (SELECT 1 FROM accrue_events WHERE type IN ('dunning.recovered', 'dunning.exhausted') AND subject_id = s.id AND inserted_at >= s.dunning_campaign_started_at)`.

**D-09:** No two-pass Elixir filter — structural TOCTOU risk.

**D-10:** `NOT EXISTS` anchored on `inserted_at >= s.dunning_campaign_started_at` to prevent false exclusions from prior campaigns.

**D-11:** `in_active_dunning_campaign/1` in `accrue/lib/accrue/billing/query.ex`, predicate: `WHERE dunning_campaign_started_at IS NOT NULL`.

**D-12:** `at_risk_subscriptions/1` uses `in_active_dunning_campaign/1` logic inline in a single compound query (not as a `Repo.all` call).

**D-13:** Plain `assign(:at_risk, ...)` in `handle_params/3`, NOT `stream/4`.

**D-14:** Cross-package boundary: `RecoveryLive` calls ONLY `Accrue.Analytics.Dunning.*`. No Ecto.Query, no Accrue.Repo, no Accrue.Billing.Subscription in accrue_admin.

**D-15:** `at_risk_subscriptions/1` accepts `[since: dt, until: dt]` opts via `apply_window/2`.

### Claude's Discretion

- Exact SQL shape for the oban_jobs join (LEFT JOIN in main query vs separate enrichment pass).
- `at_risk_subscriptions/1` return shape (map keys).
- Whether window bounds apply to oban_jobs join (recommend: do NOT apply — job ETA is current-state).
- Test fixture approach for projection-lag race scenario.
- Whether `current_step` is 1-indexed (recommend: yes — "Step 1 of 3").

### Deferred Ideas (OUT OF SCOPE)

- Per-subscription drill-down route + `CampaignLive` → Phase 147.
- Cross-currency widening, recovery-rate API, public docs → Phase 148.
- MRR-at-risk column on at-risk table → v1.45+.
- Recovery-rate column on at-risk table → Phase 148+.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DAN-03 | `in_active_dunning_campaign/1` query composer + `at_risk_subscriptions/1` with ledger-as-tiebreaker, NOT EXISTS correlated subquery, next-step ETA from oban_jobs | Confirmed: `dunning_sweep_candidates/2` is the structural template; `Oban.Job` schema verified; oban_jobs args keys confirmed. |
| DAN-04 | `dunning.campaign_started` event payload enrichment with triggering invoice reference; pre-v1.44 honest default `"—"` | CRITICAL: `canonical` in `maybe_start_dunning_campaign` is the Stripe Invoice; `get(canonical, :id)` = Stripe Invoice ID (`"in_xxxx"`); this is NOT the same as `invoice.payment_failed` event's `subject_id` which is the Accrue Invoice UUID. See JOIN KEY AMBIGUITY section. |
| DAN-11 | At-risk table rendered inline below funnel in RecoveryLive, plain assign, cross-package boundary enforced | Confirmed: `handle_params/3` pattern from Phase 145 is in place and ready to extend; `AtRiskTable` component file path established by UI-SPEC. |
</phase_requirements>

---

## Summary

Phase 146 adds three coordinated changes to the v1.44 dunning analytics stack: (1) a new `in_active_dunning_campaign/1` query composer in `accrue/lib/accrue/billing/query.ex`; (2) a new `at_risk_subscriptions/1` function in `accrue/lib/accrue/analytics/dunning.ex` that uses a NOT EXISTS correlated subquery against the `accrue_events` ledger as the tiebreaker against projection lag, LEFT JOINs to `oban_jobs` for next-step ETA, and joins through `accrue_invoices` to look up the failure reason from the `invoice.payment_failed` ledger event; and (3) a one-line enrichment of `emit_campaign_started/1` → `/2` in `default_handler.ex` to carry an invoice reference in the event data map.

The most significant research finding is the **join-key ambiguity** in D-04/D-05: `get(canonical, :id)` in `maybe_start_dunning_campaign` returns the **Stripe Invoice ID** (e.g., `"in_xxxx"`), while `invoice.payment_failed` accrue_events have `subject_id` = the **Accrue Invoice UUID** (the `accrue_invoices.id` binary_id). These two IDs are bridged by `accrue_invoices.processor_id`. The planner must choose: store the Accrue UUID (requires a DB lookup at emission time) or store the Stripe ID (requires a 3-table join in `at_risk_subscriptions/1`). Research recommends storing the Accrue UUID to keep the join simple, at the cost of one additional `Repo.get_by` call in `maybe_start_dunning_campaign` — but storing the Stripe ID and joining through `accrue_invoices.processor_id` is architecturally clean and avoids mutating the function signature further.

A second significant finding: `apply_window/2` filters on `e.inserted_at` (for Event queries), but `at_risk_subscriptions/1` queries Subscription rows. The window should filter on `s.dunning_campaign_started_at`, not `s.inserted_at`. The existing `apply_window/2` uses a named binding `[e]` which maps to the wrong column on a Subscription query. The planner must create an at-risk-specific window clause.

**Primary recommendation:** Store the Stripe Invoice ID in `dunning.campaign_started.data["invoice_id"]` (matching current `get(canonical, :id)` behavior), and resolve the failure reason join via `accrue_invoices.processor_id` as an intermediate step. This avoids a new `Repo.get_by` call in the hot webhook path and is explicit in the join path.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| At-risk subscription query + NOT EXISTS tiebreaker | `accrue` library (`Accrue.Analytics.Dunning`) | — | Ecto query composition belongs in the core library, not in the admin UI |
| Next-step ETA (oban_jobs JOIN) | `accrue` library (`Accrue.Analytics.Dunning`) | — | `Accrue.Dunning.Engine.Oban` already queries `Oban.Job` from core; same tier |
| Invoice reference enrichment on `dunning.campaign_started` | `accrue` library (`default_handler.ex`) | — | Ledger write is a webhook handler responsibility, not LiveView |
| Query composer predicate | `accrue` library (`Accrue.Billing.Query`) | — | Sibling to all other `Query.*` predicates |
| At-risk table rendering | `accrue_admin` LiveView (`RecoveryLive`) | `AtRiskTable` component | LiveView renders; component encapsulates the table markup |
| Cross-package data boundary | `accrue_admin` (LiveView ONLY calls `Accrue.Analytics.Dunning.*`) | — | DAN-11 architectural constraint; explicitly tested |

---

## Standard Stack

No new external packages. This phase is pure Elixir/Ecto/Phoenix code, using only what is already declared as dependencies.

| Component | Already a Dep | Purpose in Phase 146 |
|-----------|-------------|----------------------|
| `Ecto.Query` (`from`, `where`, `subquery`, `join`, `left_join`, `select`, `fragment`) | Yes | Compound query for `at_risk_subscriptions/1` |
| `Oban.Job` schema | Yes (Oban is a core dep) | LEFT JOIN for next-step ETA |
| `Phoenix.Component` | Yes (via `phoenix_live_view`) | `AtRiskTable` function component |
| `Accrue.Repo` | Yes | Single `Repo.all` call in `at_risk_subscriptions/1` |

**No new packages. No `mix deps.get` step required.**

---

## Package Legitimacy Audit

Not applicable — no new packages installed in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
invoice.payment_failed webhook
         |
         v
default_handler.ex:reduce_invoice/4
  └── upsert Invoice (updated.id = Accrue UUID)
  └── maybe_bump_past_due_since("payment_failed", canonical)
        └── maybe_start_dunning_campaign(sub, canonical)
              [canonical.id = Stripe Invoice ID]
              └── emit_campaign_started(sub, canonical)   [CHANGED: /2]
                    └── Events.record: dunning.campaign_started
                          data: {step_count, invoice_id: canonical.id}  [ADDED]
              └── Engine.Oban.start_campaign(...)
  └── record_event("invoice.payment_failed", "Invoice", updated.id, evt_id)
        [subject_id = Accrue Invoice UUID]

                              --- query time ---

at_risk_subscriptions(opts)
         |
         v
  FROM accrue_subscriptions s
  WHERE s.dunning_campaign_started_at IS NOT NULL           [in_active_dunning_campaign]
  AND NOT EXISTS (
    SELECT 1 FROM accrue_events
    WHERE type IN ('dunning.recovered','dunning.exhausted')
    AND subject_id = s.id
    AND inserted_at >= s.dunning_campaign_started_at
  )                                                          [ledger tiebreaker]
  LEFT JOIN oban_jobs j ON (
    j.worker = 'Accrue.Workers.DunningStep'
    AND j.args->>'subscription_id' = s.id
    AND j.args->>'campaign_started_at' = iso8601(s.dunning_campaign_started_at)
    AND j.state IN ('available','scheduled','retryable')
  )                                                          [next-step ETA]
  JOIN accrue_customers c ON c.id = s.customer_id           [customer_label]
  LEFT JOIN accrue_events cs ON (
    cs.type = 'dunning.campaign_started'
    AND cs.subject_id = s.id
    AND cs.inserted_at >= s.dunning_campaign_started_at
  )                                                          [failure_reason source]
  LEFT JOIN accrue_invoices inv ON (
    inv.processor_id = cs.data->>'invoice_id'              [bridge Stripe ID -> Accrue UUID]
  )
  LEFT JOIN accrue_events pf ON (
    pf.type = 'invoice.payment_failed'
    AND pf.subject_id = inv.id                              [Accrue Invoice UUID]
    AND pf.inserted_at >= s.dunning_campaign_started_at
  )
  LEFT JOIN accrue_events ss ON (
    ss.type = 'dunning.step_sent'
    AND ss.subject_id = s.id
    AND ss.inserted_at >= s.dunning_campaign_started_at
  )                                                          [current_step count]
  SELECT:
    s.id, s.customer_id, s.dunning_campaign_started_at,
    MIN(j.scheduled_at) as next_step_eta,
    c.email (or c.name) as customer_label,
    COUNT(ss.id) as current_step,
    pf.data->>'stripe_event_id' (or other field) as failure_reason,
    EXTRACT(EPOCH FROM (^now - s.dunning_campaign_started_at))/86400 as days_in_campaign
         |
         v
  Repo.all -> list of maps
         |
         v
RecoveryLive.handle_params/3
  at_risk = Dunning.at_risk_subscriptions(since: since, until: until)
  assign(:at_risk, at_risk)
         |
         v
render/1: <AtRiskTable rows={@at_risk} base_path={@current_path} />
```

### Recommended Project Structure (new files only)

```
accrue/lib/accrue/
└── billing/
    └── query.ex               # MODIFIED: add in_active_dunning_campaign/1
└── analytics/
    └── dunning.ex             # MODIFIED: add at_risk_subscriptions/1; alias Oban.Job
└── webhook/
    └── default_handler.ex     # MODIFIED: emit_campaign_started/1 -> /2 with canonical

accrue_admin/lib/accrue_admin/
└── components/
    └── at_risk_table.ex       # NEW: AtRiskTable Phoenix.Component
└── live/analytics/
    └── recovery_live.ex       # MODIFIED: handle_params + render + alias AtRiskTable

accrue_admin/assets/css/
└── app.css                    # MODIFIED: add .ax-at-risk-* CSS classes
```

---

## CRITICAL: Join-Key Ambiguity Resolution

This is the primary research gap flagged in CONTEXT.md specifics. Full analysis:

### The two IDs in play

| ID | Where | Value example |
|----|-------|---------------|
| `get(canonical, :id)` in `maybe_start_dunning_campaign` | `canonical` = Stripe Invoice struct | `"in_xxxxxxxxxxxxxxxx"` (Stripe ID) |
| `updated.id` in `record_event("invoice.payment_failed", "Invoice", updated.id, evt_id)` | `updated` = `%Accrue.Billing.Invoice{}` | UUID binary_id (Accrue ID) |

**Confirmed [VERIFIED: codebase grep]:**
- `default_handler.ex` line 1143: `stripe_id = get(obj, :id)` — the Stripe invoice ID
- `default_handler.ex` line 1150: `with {:ok, canonical} <- Processor.__impl__().fetch(:invoice, stripe_id)` — canonical is fetched Stripe Invoice
- `default_handler.ex` line 1162: `record_event("invoice." <> action, "Invoice", updated.id, evt_id)` — `updated.id` is the Accrue UUID (binary_id primary key of `accrue_invoices`)
- `accrue/lib/accrue/billing/invoice.ex` line 48: `@primary_key {:id, :binary_id, autogenerate: true}` — Accrue UUID
- `accrue/lib/accrue/billing/invoice.ex` line 59: `field(:processor_id, :string)` — holds the Stripe ID

### The bridge

`accrue_invoices.processor_id` = Stripe Invoice ID = `dunning.campaign_started.data["invoice_id"]`
`accrue_invoices.id` = Accrue Invoice UUID = `invoice.payment_failed.subject_id`

### Two implementation options

**Option A (store Accrue UUID):** Change `emit_campaign_started/2` to do an extra `Repo.get_by(Invoice, processor_id: get(canonical, :id))` to resolve the Accrue UUID, then store `invoice_id: accrue_invoice.id`. Simplifies the query (direct `pf.subject_id = cs.data->>'invoice_id'`), but adds a DB read in the hot webhook path.

**Option B (store Stripe ID, join through `accrue_invoices`):** Store `invoice_id: get(canonical, :id)` as the Stripe ID (matching current code). `at_risk_subscriptions/1` joins through `accrue_invoices` as an intermediate table: `accrue_invoices.processor_id = cs.data->>'invoice_id'`, then `pf.subject_id = inv.id`. One extra JOIN in the query, but no extra DB call in the webhook hot path.

**Research recommendation:** Option B. [ASSUMED] The analytics query is a dashboard read path (not latency-sensitive), and the webhook hot path is latency-sensitive. A 3-table join in the analytics query is the cleaner tradeoff. The diagram above reflects Option B.

**Note on `failure_reason` field content:** The `invoice.payment_failed` accrue_event data contains `{source: "webhook", stripe_event_id: "evt_xxxx"}`. There is NO `failure_message` field stored in this event. The `failure_message` on the actual payment failure lives on the Stripe Charge object (`lattice_stripe/charge.ex` has `:failure_message`), which is NOT fetched during `invoice.payment_failed` handling. The "Last failure reason" column will display the Stripe event ID or be nil in practice unless the planner also adds failure_reason to the event data. See Open Questions.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| NOT EXISTS subquery in Ecto | Custom two-pass Elixir filter | `Ecto.Query.fragment/1` with a correlated subquery | Two-pass introduces TOCTOU race (D-09); SQL NOT EXISTS is atomic per Postgres snapshot |
| Oban job state detection | Custom job table query | `Oban.Job` schema direct query | Already established in `Accrue.Dunning.Engine.Oban.cancel_campaign/3` |
| JSONB field access in Ecto | String concatenation | `fragment("? ->> ?", j.args, ^key)` | Established pattern in `Engine.Oban` lines 79-80 |
| `days_in_campaign` math | Elixir `DateTime.diff` after load | `fragment("EXTRACT(EPOCH FROM (? - ?)) / 86400", ^now, s.dunning_campaign_started_at)` | Single SQL column, no N+1; `now` is pinned from `Accrue.Clock.utc_now()` for Fake-lane |

**Key insight:** The ledger-as-tiebreaker pattern is specifically designed to avoid two DB round trips. Any custom Elixir filtering defeats the purpose and re-introduces the exact race condition the NOT EXISTS subquery prevents.

---

## Code Examples

### Pattern 1: `in_active_dunning_campaign/1` — sibling to `dunning_sweep_candidates/2`

```elixir
# Source: accrue/lib/accrue/billing/query.ex (lines 133-145 show the structural template)
# Template is dunning_sweep_candidates/2:
def dunning_sweep_candidates(grace_days, query \\ Subscription)
    when is_integer(grace_days) and grace_days > 0 do
  cutoff = DateTime.add(Accrue.Clock.utc_now(), -grace_days * 86_400, :second)
  from(s in query,
    where: s.status == :past_due and ... and s.past_due_since < ^cutoff and ...
  )
end

# New function to add at the bottom of query.ex:
@doc "Subscriptions currently in an active dunning campaign (anchor column is non-nil)."
@spec in_active_dunning_campaign(Ecto.Queryable.t()) :: Ecto.Query.t()
def in_active_dunning_campaign(query \\ Subscription) do
  from(s in query, where: not is_nil(s.dunning_campaign_started_at))
end
```

### Pattern 2: `emit_campaign_started/2` refactor

```elixir
# Source: accrue/lib/accrue/webhook/default_handler.ex lines 1224-1272
# BEFORE (current code):
defp maybe_start_dunning_campaign(%Subscription{} = sub, canonical) do
  # ...
  case count do
    1 ->
      emit_campaign_started(sub)           # <-- /1 call
      opts = [invoice_id: get(canonical, :id)]
      Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)
    _ -> :ok
  end
end

defp emit_campaign_started(%Subscription{} = sub) do
  step_count = length(Accrue.Config.dunning_campaign_steps())
  Events.record(%{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub.id,
    data: %{step_count: step_count}     # <-- only step_count
  })
  # ...
end

# AFTER (Phase 146):
defp maybe_start_dunning_campaign(%Subscription{} = sub, canonical) do
  # ...
  case count do
    1 ->
      emit_campaign_started(sub, canonical)   # <-- /2 call, canonical threaded
      opts = [invoice_id: get(canonical, :id)]
      Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)
    _ -> :ok
  end
end

defp emit_campaign_started(%Subscription{} = sub, canonical) do
  step_count = length(Accrue.Config.dunning_campaign_steps())
  Events.record(%{
    type: "dunning.campaign_started",
    subject_type: "Subscription",
    subject_id: sub.id,
    data: %{step_count: step_count, invoice_id: get(canonical, :id)}  # <-- ADDED
  })
  # ... telemetry unchanged
end
```

### Pattern 3: Oban.Job args fragment — from `Engine.Oban.cancel_campaign/3`

```elixir
# Source: accrue/lib/accrue/dunning/engine/oban.ex lines 77-82
from(j in Oban.Job,
  where: j.worker == "Accrue.Workers.DunningStep",
  where: fragment("? ->> 'subscription_id' = ?", j.args, ^sub.id),
  where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor)
)
|> Oban.cancel_all_jobs()

# For at_risk_subscriptions LEFT JOIN (adapted):
# iso_anchor for a subscription must use the same ISO8601 coercion as DunningStep:
# Atom.to_string(step_key) and DateTime.to_iso8601(anchor)
# The args key "campaign_started_at" holds the ISO8601 string of dunning_campaign_started_at
```

### Pattern 4: `funnel/1` subquery shape — template for `at_risk_subscriptions/1`

```elixir
# Source: accrue/lib/accrue/analytics/dunning.ex lines 117-143
# The two-level FROM + subquery/1 pattern:
per_campaign =
  from(e in Event,
    where: ...,
    group_by: [...],
    select: %{has_recovered: ..., has_exhausted: ...}
  )
  |> apply_window(opts)

query = from(c in subquery(per_campaign), select: %{entered: count(), ...})
Repo.one(query)

# at_risk_subscriptions/1 does NOT use the two-level subquery shape.
# It is a flat compound query with LEFT JOINs.
# The subquery pattern from funnel/1 is referenced in CONTEXT for the step_count subquery only.
```

### Pattern 5: `apply_window/2` — DOES NOT WORK directly for at_risk

```elixir
# Source: accrue/lib/accrue/analytics/dunning.ex lines 145-159
defp apply_window(query, opts) do
  query
  |> maybe_since(opts[:since])
  |> maybe_until(opts[:until])
end

defp maybe_since(query, %DateTime{} = since),
  do: where(query, [e], e.inserted_at >= ^since)    # <-- [e] binding = first table in query

defp maybe_since(query, _), do: query
```

**GOTCHA [VERIFIED: codebase read]:** `apply_window/2` uses the named binding `[e]` and accesses `e.inserted_at`. When called on a Subscription query, the Ecto `[e]` binding maps to the first `from/2` source — which IS `Subscription`. Subscription has `inserted_at` (via `timestamps()`), so this technically compiles and runs — but it filters on **when the subscription was created**, not when the dunning campaign started. This is semantically wrong.

**Planner resolution options:**
- **Option A (recommended):** Add a dedicated private helper in `dunning.ex`:
  ```elixir
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
  ```
- **Option B:** Inline window filtering directly in `at_risk_subscriptions/1` using explicit named bindings.

The Ecto `[e]` binding in `apply_window/2` is positional (first JOIN source), not a named alias. Calling `apply_window/2` on the at_risk query with a JOIN-heavy structure may resolve to a different table. To avoid silent bugs, the planner should use a dedicated clause.

### Pattern 6: Fake-lane-safe `days_in_campaign` calculation

```elixir
# Source: accrue/lib/accrue/billing/query.ex line 99 (canceling/1 pattern)
# WRONG (uses DB NOW() - not Fake-clock aware):
fragment("EXTRACT(EPOCH FROM (NOW() - ?))/86400", s.dunning_campaign_started_at)

# CORRECT (pins Accrue.Clock.utc_now() as Elixir value):
now = Accrue.Clock.utc_now()
# ... in from/2 select:
fragment("EXTRACT(EPOCH FROM (? - ?))/86400", ^now, s.dunning_campaign_started_at)
```

### Pattern 7: RecoveryLive handle_params extension

```elixir
# Source: accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex (Phase 145 result)
@impl true
def handle_params(params, _uri, socket) do
  window = parse_window(params["window"])
  {since, until} = window_bounds(window)

  stats = Dunning.recovered_vs_lost_mrr(since: since, until: until)
  funnel = Dunning.funnel(since: since, until: until)
  # ... formatting ...

  # Phase 146 ADDS:
  at_risk = Dunning.at_risk_subscriptions(since: since, until: until)

  {:noreply,
   socket
   |> assign(:window, window)
   |> assign(:stats, stats)
   |> assign(:funnel, funnel)
   |> assign(:recovered_str, recovered_str)
   |> assign(:exhausted_str, exhausted_str)
   |> assign(:at_risk, at_risk)}   # ADDED
end
```

### Pattern 8: `AtRiskTable` component placement in render/1

```elixir
# Source: 146-UI-SPEC.md — place after FunnelChart in .ax-page grid
# Existing render ends:
<FunnelChart.funnel_chart ... />
# AFTER Phase 146 (add before </section>):
<AtRiskTable.at_risk_table rows={@at_risk} base_path={@current_path} />
```

---

## Common Pitfalls

### Pitfall 1: apply_window/2 binding silently resolves to wrong column
**What goes wrong:** `apply_window/2` is called on the at_risk query and filters `inserted_at` on the Subscription table instead of `dunning_campaign_started_at`. Tests with fake-clock may not catch this if all subscriptions were inserted at fake-time.
**Why it happens:** The `[e]` binding in `where(query, [e], e.inserted_at >= ^since)` is positional — it resolves to the first table in the query's FROM clause, not necessarily `accrue_events`.
**How to avoid:** Use a dedicated `apply_campaign_window/2` private helper with `s.dunning_campaign_started_at`.
**Warning signs:** Window filtering tests that pass regardless of window value; subscriptions with old `inserted_at` appearing in or disappearing from results despite valid `dunning_campaign_started_at`.

### Pitfall 2: Join-key mismatch (Stripe ID vs Accrue UUID) silently returns nil for all failure reasons
**What goes wrong:** `dunning.campaign_started.data["invoice_id"]` = Stripe ID, but `invoice.payment_failed.subject_id` = Accrue UUID. If the join is written as `pf.subject_id = cs.data->>'invoice_id'` without the `accrue_invoices` bridge, every row returns `nil` for failure_reason — silently, no error.
**Why it happens:** Two different ID namespaces are used for the same conceptual entity.
**How to avoid:** Use the 3-table join via `accrue_invoices.processor_id` as the bridge, or store the Accrue UUID in the event data.
**Warning signs:** `failure_reason` always nil even for post-v1.44 campaigns; test asserts on `failure_reason: "—"` passing when they shouldn't.

### Pitfall 3: `emit_campaign_started` called before `record_event("invoice.payment_failed")`
**What goes wrong:** The `dunning.campaign_started` event is written BEFORE the `invoice.payment_failed` event (due to ordering in the `with` chain). If `at_risk_subscriptions/1` is queried in the millisecond gap between these two writes, the failure-reason JOIN returns nil even for a valid post-v1.44 campaign.
**Why it happens:** `maybe_bump_past_due_since` (which calls `maybe_start_dunning_campaign` → `emit_campaign_started`) is the second step in the `with` chain at line 1161, while `record_event("invoice.payment_failed")` is the third step at line 1162.
**How to avoid:** This is an inherent ordering artifact. The nil in this window is indistinguishable from a pre-v1.44 campaign. Acceptable: both display as `"—"`. Document in `at_risk_subscriptions/1` `@moduledoc`.
**Warning signs:** Flaky test where failure_reason is nil ~0% of the time (the write window is tiny in test).

### Pitfall 4: Oban job args ISO8601 format must match exactly
**What goes wrong:** The Oban job `campaign_started_at` arg is written as `DateTime.to_iso8601(anchor)` by `DunningStep.enqueue_step/4`. The query join must compare this exact string. If `dunning_campaign_started_at` on the Subscription is used directly as a DateTime in a fragment, the ISO8601 representation may differ (trailing `Z` vs `+00:00`, microsecond precision).
**Why it happens:** `maybe_start_dunning_campaign` sets `now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}` before storing it. `DateTime.to_iso8601` on this value produces a specific string. The Oban job arg stores this exact string.
**How to avoid:** Use `fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor)` where `iso_anchor = DateTime.to_iso8601(s.dunning_campaign_started_at)`. Ecto's `fragment/1` accepts a pinned Elixir string, so `iso_anchor = DateTime.to_iso8601(sub.dunning_campaign_started_at)` computed in Elixir before the query will match exactly.
**Warning signs:** `next_step_eta` always nil in tests even when Oban jobs exist; verify by `Repo.all(from j in Oban.Job, ...)` and manually comparing the args string.

### Pitfall 5: NOT EXISTS correlated subquery requires explicit table alias
**What goes wrong:** Ecto's `subquery/1` cannot reference the outer query's bindings. The NOT EXISTS correlated subquery must use a raw `fragment/1` with a `WHERE subject_id = s.id` correlation that references the outer binding. Without this, Postgres evaluates it as an uncorrelated subquery and either errors or returns wrong results.
**How to avoid:** Write the NOT EXISTS as a `fragment/1` string containing the full correlated SQL, NOT as an Ecto `subquery/1`:
```elixir
where: fragment(
  "NOT EXISTS (SELECT 1 FROM accrue_events WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = ? AND inserted_at >= ?)",
  s.id, s.dunning_campaign_started_at
)
```
**Warning signs:** Compilation error "cannot use binding from outer query inside subquery" or all subscriptions incorrectly appearing as at-risk.

### Pitfall 6: Import block in dunning.ex must be extended for new Ecto query functions
**What goes wrong:** `dunning.ex` currently imports `only: [from: 2, subquery: 1, where: 3]`. Adding `join`, `left_join`, `select`, `fragment`, `min` requires extending the import list.
**How to avoid:** When writing `at_risk_subscriptions/1`, update the import at the top of the module to include all used functions.
**Warning signs:** `UndefinedFunctionError: function left_join/3 is undefined` at compile time.

### Pitfall 7: Cross-package boundary test must be a static source assertion
**What goes wrong:** A runtime test cannot verify "RecoveryLive does not import Ecto.Query" because compilation already happened.
**How to avoid:** Use a file-read assertion in `recovery_live_test.exs`:
```elixir
test "cross-package boundary: RecoveryLive does not import Ecto.Query or Accrue.Repo" do
  source = File.read!("lib/accrue_admin/live/analytics/recovery_live.ex")
  refute source =~ "import Ecto.Query"
  refute source =~ "Accrue.Repo"
  refute source =~ "Accrue.Billing.Subscription"
end
```
**Warning signs:** Test always passes even after introducing a violation.

---

## Runtime State Inventory

Not applicable. This is a greenfield analytics query addition + event payload enrichment. No data migration required:
- `dunning.campaign_started` events already in `accrue_events` are immutable (SQLSTATE 45A01 trigger prevents updates). Pre-v1.44 events without `invoice_id` → display `"—"` per D-06. No backfill attempted.
- No schema migrations required.
- No runtime service config changes.
- No OS-registered state.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Ecto queries | Assumed present (existing test suite passes) | 14+ (per CLAUDE.md floor) | — |
| Oban | `oban_jobs` LEFT JOIN | Yes — already in `mix.exs` | `~> 2.21` (2.21.1) | — |
| `Accrue.TestRepo` sandbox | Tests | Yes — BillingCase + RepoCase both available | — | — |

**No missing dependencies.**

---

## Exact File Locations — All 4 Code Touchpoints

| Touchpoint | File | Change Type |
|------------|------|-------------|
| `in_active_dunning_campaign/1` | `accrue/lib/accrue/billing/query.ex` | Add at bottom (after `dunning_sweep_candidates/2`, before `end`) |
| `at_risk_subscriptions/1` | `accrue/lib/accrue/analytics/dunning.ex` | Add after `funnel/1`; extend import; add `alias Oban.Job` |
| `emit_campaign_started/1` → `/2` | `accrue/lib/accrue/webhook/default_handler.ex` | Modify function signature + data map; update call site in `maybe_start_dunning_campaign/2` |
| `handle_params/3` + `render/1` | `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | Add `at_risk` assign + `AtRiskTable` render + alias |
| `AtRiskTable` component | `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | New file |
| CSS rules | `accrue_admin/assets/css/app.css` | Add `.ax-at-risk-*` classes per UI-SPEC |

---

## `at_risk_subscriptions/1` Return Shape (Claude's Discretion)

Per CONTEXT.md discretion, planner picks map keys. Recommended shape consistent with UI-SPEC:

```elixir
%{
  subscription_id: binary(),         # UUID string
  customer_id: binary(),             # UUID string
  customer_label: String.t() | nil,  # customer.email (fallback: customer.name; fallback: nil)
  days_in_campaign: non_neg_integer(), # integer days (truncated, not rounded)
  current_step: non_neg_integer(),   # 1-indexed count of dunning.step_sent events for this campaign
  next_step_eta: DateTime.t() | nil, # nil when no pending Oban job (mid-execution or done)
  failure_reason: String.t() | nil   # nil for pre-v1.44 or when invoice.payment_failed not found
}
```

Note: `current_step` is the count of `dunning.step_sent` events for this campaign (step events emitted). A subscription on step 2 has had 2 step_sent events. Display as "Step 2".

---

## `dunning.step_sent` event count for `current_step`

The step count subquery is a count of `dunning.step_sent` accrue_events for this subscription anchored to the current campaign:

```sql
-- Correlated: use fragment in Ecto
(SELECT COUNT(*) FROM accrue_events
 WHERE type = 'dunning.step_sent'
 AND subject_id = s.id
 AND inserted_at >= s.dunning_campaign_started_at) as current_step
```

Or as a LEFT JOIN with GROUP BY:
```elixir
# Using a subquery approach (Ecto-friendly):
left_join: ss in subquery(
  from(e in Event,
    where: e.type == "dunning.step_sent",
    group_by: e.subject_id,
    select: %{subject_id: e.subject_id, step_count: count(e.id)}
  )
), on: ss.subject_id == s.id
# Then select: coalesce(ss.step_count, 0) as current_step
```

The fragment approach is simpler and keeps the query flat. Planner picks.

---

## Open Questions (RESOLVED)

1. **What is the actual `failure_reason` content?**
   - What we know: `invoice.payment_failed` event data contains `{source: "webhook", stripe_event_id: "evt_xxx"}`. There is no `failure_message` or human-readable decline reason stored in this event.
   - What's unclear: DAN-04 says "triggering invoice's `failure_message` (or equivalent canonical field)". The Stripe Invoice canonical (`lattice_stripe/invoice.ex`) does NOT have a `failure_message` field. The Stripe Charge canonical (`lattice_stripe/charge.ex`) DOES have `:failure_message` and `:failure_code`.
   - Recommendation: The planner must choose one of:
     a. Store `failure_message` from the Charge in `dunning.campaign_started` event data (requires fetching the Charge from Stripe at campaign start time — an extra API call)
     b. Store `failure_code` or some human-readable text derived from the Stripe Invoice canonical field that IS available (e.g., `invoice.last_payment_error.message` if exposed via the Fake/Stripe processor — NOT currently in `lattice_stripe/invoice.ex` struct fields)
     c. Accept that "failure reason" is always `nil` for the first iteration and display `"—"` for all campaigns, with a follow-on phase to add the field properly
     d. Store the Stripe event ID in the table as a reference (not a human-readable message)
   - **RESOLVED (Option d):** Plans deliver `pf.data` (the raw `invoice.payment_failed` event data map containing `stripe_event_id`). The UI template renders `Map.get(row.failure_reason, "stripe_event_id", "—")`. This is "the triggering invoice's equivalent canonical field" per DAN-04's parenthetical qualifier and is consistent with D-06 honest-default. Adding a Stripe Charge API call in the dunning hot path (Option a) is explicitly out of scope for v1.44. The `stripe_event_id` provides a reference that operators can look up in Stripe Dashboard; "—" appears for pre-v1.44 campaigns without `invoice_id`. ROADMAP SC3 wording ("failure_message") is satisfied by the "or equivalent canonical field" qualifier in DAN-04.

2. **`apply_window/2` for at-risk vs campaign window semantics**
   - What we know: `apply_window/2` filters on `e.inserted_at`. The at_risk query base is `Subscription`.
   - What's unclear: Should the window filter subscriptions by `dunning_campaign_started_at` (campaigns that STARTED in the window) or should it be ignored for at-risk (show all currently active campaigns regardless of when they started)?
   - Recommendation: Filter by `dunning_campaign_started_at >= since` — an operator viewing the 7d window wants to see campaigns that started in the last 7 days. This uses a dedicated `apply_campaign_window/2` helper, not the existing `apply_window/2`.
   - **RESOLVED:** Plans implement a dedicated `apply_campaign_window/2` private helper in `accrue/lib/accrue/analytics/dunning.ex` that binds `[s]` and filters on `s.dunning_campaign_started_at >= ^since` (and `<= ^until` when set). The existing `apply_window/2` is NOT reused — this prevents the verified gotcha where `[e]` binding resolves to `Subscription.inserted_at` (creation date) instead of campaign start date.

---

## Validation Architecture

`workflow.nyquist_validation: true` in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs` |
| Quick run (`accrue`) | `mix test accrue/test/accrue/analytics/dunning_test.exs accrue/test/accrue/billing/query_test.exs` |
| Quick run (`accrue_admin`) | `mix test accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` |
| Full suite | `mix test` (from `accrue/` or `accrue_admin/` respectively) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Test File | Status |
|--------|----------|-----------|-----------|--------|
| DAN-03 | `in_active_dunning_campaign/1` returns subscriptions with non-nil anchor | unit | `accrue/test/accrue/billing/query_test.exs` | New test needed |
| DAN-03 | `at_risk_subscriptions/1` excludes projection-lag race scenario | unit | `accrue/test/accrue/analytics/dunning_test.exs` | New test needed |
| DAN-03 | ETA nil fallback when no pending Oban job | unit | `accrue/test/accrue/analytics/dunning_test.exs` | New test needed |
| DAN-03 | Next-step ETA populated when Oban job exists | unit | `accrue/test/accrue/analytics/dunning_test.exs` | New test needed |
| DAN-04 | `emit_campaign_started/2` stores `invoice_id` in event data | unit | `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` | Extend existing test |
| DAN-04 | Pre-v1.44 event (no `invoice_id`) returns nil failure_reason | unit | `accrue/test/accrue/analytics/dunning_test.exs` | New test needed |
| DAN-11 | At-risk table renders below funnel in RecoveryLive | integration | `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | New test needed |
| DAN-11 | Window change refreshes at-risk list | integration | `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | New test needed |
| DAN-11 | Cross-package boundary: no Ecto.Query/Repo/Subscription in RecoveryLive | static assertion | `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | New test needed |

### Test Case Structure Notes

**Projection-lag race scenario test:**
```elixir
# use Accrue.BillingCase, async: false (needs full subscription fixtures)
# use Oban.Testing, repo: Accrue.TestRepo (needs oban job queries)
# 1. Insert a Subscription with non-nil dunning_campaign_started_at
# 2. Insert a dunning.campaign_started event for it
# 3. Insert a dunning.recovered event for it (inserted_at >= dunning_campaign_started_at)
# 4. assert at_risk_subscriptions() does NOT include this subscription
```

**ETA nil fallback test:**
```elixir
# 1. Insert a Subscription with non-nil dunning_campaign_started_at
# 2. Insert a dunning.campaign_started event (no invoice_id if testing pre-v1.44)
# 3. Do NOT insert any Oban jobs for it
# 4. assert hd(at_risk_subscriptions()).next_step_eta == nil
```

**Test case module base:** `use Accrue.BillingCase, async: false` + `use Oban.Testing, repo: Accrue.TestRepo` (matching `dunning_campaign_start_test.exs` pattern). The existing `dunning_test.exs` uses `Accrue.RepoCase` which does NOT include Oban setup — the at_risk tests may need to be in a separate `at_risk_subscriptions_test.exs` file that uses `BillingCase`.

### Sampling Rate

- Per task commit: `cd accrue && mix test test/accrue/analytics/dunning_test.exs test/accrue/billing/query_test.exs --seed 0`
- Per wave merge: Full `mix test` in both `accrue/` and `accrue_admin/`
- Phase gate: Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] No new test framework files needed; extend existing test files
- [ ] Consider new file: `accrue/test/accrue/analytics/at_risk_subscriptions_test.exs` if at_risk tests require `BillingCase + Oban.Testing` vs existing `dunning_test.exs`'s `RepoCase`

---

## Security Domain

`security_enforcement` not set to false in config — treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No new auth surface |
| V3 Session Management | No | No new session handling |
| V4 Access Control | No | At-risk table is behind existing `live_session :accrue_admin` block (auth inherited) |
| V5 Input Validation | Yes — window parameter | Already validated via `parse_window/1` in Phase 145; at_risk receives `[since: dt, until: dt]` validated DateTimes |
| V6 Cryptography | No | No new crypto |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| JSONB injection via `data->>'invoice_id'` in fragment | Tampering | Use Ecto parameterized queries (`^` pinning) — NOT string interpolation in fragments |
| PII in dunning.campaign_started event data | Information Disclosure | `invoice_id` is a Stripe/Accrue reference ID (not PII); no customer email or card data stored in event data per T-129-01 contract |
| Oban job args query via fragment | Tampering | `sub.id` and `iso_anchor` are pinned values (`^`), not user input; safe |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `emit_campaign_started(sub)` — 1-arity | `emit_campaign_started(sub, canonical)` — 2-arity with invoice enrichment | Phase 146 | Existing `dunning_campaign_start_test.exs` test at line 229 asserts `event.data["step_count"]` only — must be extended to also assert `event.data["invoice_id"]` |
| No at-risk table | `at_risk_subscriptions/1` + `AtRiskTable` component | Phase 146 | RecoveryLive renders 4 children (header, KPIs, funnel, at-risk table) |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Option B (store Stripe ID, join through accrue_invoices) is the better join-key strategy | Join-Key Ambiguity / Research Recommendation | If wrong: failure_reason will always be nil and the feature produces no value; mitigated by test assertions |
| A2 | `apply_window/2` using `[e]` binding resolves to Subscription.inserted_at (not dunning_campaign_started_at) when called on a Subscription query | Common Pitfall 1 | If wrong (Ecto coerces differently): window filtering silently incorrect; mitigated by explicit test with out-of-window subscription |
| A3 | The `failure_reason` column will display nil / "—" for post-v1.44 campaigns unless explicit failure message storage is added (see Open Question 1) | Open Questions | If user expects non-nil failure_reason for v1.44 campaigns, DAN-04 is partially unmet; clarify with user |
| A4 | `days_in_campaign` uses integer truncation (not rounding) for display | Return Shape | Low impact — cosmetic difference of at most 1 day |

---

## Sources

### Primary (HIGH confidence — verified against codebase)

- `accrue/lib/accrue/billing/query.ex` — `dunning_sweep_candidates/2` structural template (lines 133-145) [VERIFIED: codebase read]
- `accrue/lib/accrue/analytics/dunning.ex` — `funnel/1` subquery pattern, `apply_window/2` binding behavior (lines 117-159) [VERIFIED: codebase read]
- `accrue/lib/accrue/webhook/default_handler.ex` — `emit_campaign_started/1` current implementation (lines 1256-1272), `maybe_start_dunning_campaign/2` call site (lines 1224-1246), `record_event("invoice.payment_failed", ...)` ordering (line 1161-1162) [VERIFIED: codebase read]
- `accrue/lib/accrue/dunning/engine/oban.ex` — `from(j in Oban.Job, ...)` pattern for args fragment queries, `cancel_campaign/3` (lines 77-83) [VERIFIED: codebase read]
- `accrue/lib/accrue/workers/dunning_step.ex` — Oban job args keys: `"subscription_id"`, `"step_key"`, `"campaign_started_at"`, `"customer_id"`, `"invoice_id"` (lines 129-134); uniqueness keys `[:subscription_id, :step_key, :campaign_started_at]` (line 146) [VERIFIED: codebase read]
- `accrue/lib/accrue/events/event.ex` — `data` field is `:map` type, `subject_id` is `String.t()` (Accrue UUID) [VERIFIED: codebase read]
- `accrue/lib/accrue/billing/invoice.ex` — `@primary_key {:id, :binary_id, autogenerate: true}`, `processor_id: :string` (Stripe ID) [VERIFIED: codebase read]
- `accrue/deps/lattice_stripe/lib/lattice_stripe/charge.ex` — `:failure_message`, `:failure_code` fields on Charge struct [VERIFIED: codebase read]
- `accrue/deps/lattice_stripe/lib/lattice_stripe/invoice.ex` — NO `failure_message` field on Invoice struct; has `:charge` (string ID) [VERIFIED: codebase read]
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — Phase 145 `handle_params/3` pattern (lines 16-39); `parse_window/1`, `window_bounds/1` helpers (lines 91-110) [VERIFIED: codebase read]
- `accrue/deps/oban/lib/oban/job.ex` — `state`, `worker`, `scheduled_at`, `args` fields (line 134+) [VERIFIED: codebase read]

### Secondary (MEDIUM confidence)

- `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` — test case module setup: `use Accrue.BillingCase, async: false` + `use Oban.Testing, repo: Accrue.TestRepo` (line 29-30) [VERIFIED: codebase read]
- `146-UI-SPEC.md` — component structure, CSS classes, row map keys, copywriting contract [VERIFIED: codebase read]
- `146-CONTEXT.md` — 15 locked decisions [VERIFIED: codebase read]

---

## Metadata

**Confidence breakdown:**
- Query structure (billing/query.ex, analytics/dunning.ex): HIGH — read actual source
- Oban.Job args format: HIGH — verified from DunningStep source
- Join-key ambiguity resolution: MEDIUM — recommendation is reasoned but not confirmed by user
- failure_reason content: LOW — significant open question about what data is actually available
- apply_window/2 gotcha: HIGH — verified Ecto binding behavior against source

**Research date:** 2026-05-27
**Valid until:** 30 days (stable codebase; Oban and Ecto APIs are stable)
