# Phase 146: At-risk query + at-risk table + last-failure enrichment - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators see the live "who is currently in dunning right now" list inline on `/billing/analytics/recovery` — each row showing customer (linked), days in campaign, current step, next-step ETA, and last failure reason — without false positives from subscriptions that just recovered but haven't propagated to the projection yet.

**Scope anchor — what ships:**
- `Accrue.Billing.Query.in_active_dunning_campaign/1` — new query composer in `accrue/lib/accrue/billing/query.ex`, sibling to `dunning_sweep_candidates/2`. Uses schema-side `dunning_campaign_started_at IS NOT NULL`.
- `Accrue.Analytics.Dunning.at_risk_subscriptions/1` — public wrapper applying the ledger-as-tiebreaker filter via SQL `NOT EXISTS` subquery (exclude subscriptions whose most recent dunning-lifecycle event is `recovered` or `exhausted`), joined to `oban_jobs` for next-step ETA.
- `dunning.campaign_started` event enrichment: add `invoice_id` field to the event data map in `default_handler.ex:emit_campaign_started/2` (pass `canonical` to resolve `get(canonical, :id)`).
- `at_risk_subscriptions/1` enriches the at-risk result with "Last failure reason" by joining the `invoice.payment_failed` ledger event for each active campaign's `invoice_id`.
- At-risk table rendered inline below the funnel in `RecoveryLive` via plain `assign/3` (not `stream/4`); window opts threaded through `handle_params/3`; cross-package boundary enforced (only `Accrue.Analytics.Dunning.*` from LiveView).
- Tests: projection-lag race scenario, ETA nil fallback, pre-v1.44 `—` default, cross-package boundary assertion.

**Out of scope (handled in later v1.44 phases):**
- Per-subscription drill-down route + `CampaignLive` (DAN-05/12) → Phase 147.
- Cross-currency widening, recovery-rate API, public docs (DAN-06/07/14/15/16) → Phase 148.

</domain>

<decisions>
## Implementation Decisions

### Next-step ETA source (DAN-03)

- **D-01:** Query `oban_jobs.scheduled_at` directly — `at_risk_subscriptions/1` joins to `oban_jobs` (via `Oban.Job` schema) filtering on `worker = DunningStep`, `state IN ['available', 'scheduled', 'retryable']`, and `args` containing `subscription_id` + `campaign_started_at` (the existing Oban uniqueness key for this worker). Returns `MIN(scheduled_at)` as the next-step ETA.
- **D-02:** The `Engine.Oban` module already does `from(j in Oban.Job, ...)` — the cross-module Oban query pattern is established in the codebase. Reusing it in `Accrue.Analytics.Dunning` is not a new coupling; it follows the existing precedent.
- **D-03:** Nil-ETA fallback: when the next job is mid-execution or not yet enqueued (e.g., the current step is running), the join returns `nil`. Display as `"—"` in the at-risk table — same honest-default treatment as pre-v1.44 failure reasons. Do NOT fall back to config-cadence computation; a nil ETA is more honest than a silently wrong one.

### failure_message enrichment (DAN-04)

- **D-04:** Add `invoice_id: get(canonical, :id)` to the `dunning.campaign_started` event `data` map. Thread `canonical` into `emit_campaign_started/2` as a second arg (currently called as `emit_campaign_started(sub)` — becomes `emit_campaign_started(sub, canonical)`). `get(canonical, :id)` is already called 2 lines after the `emit_campaign_started(sub)` call in `maybe_start_dunning_campaign/2`, so this is a natural refactor.
- **D-05:** `at_risk_subscriptions/1` enriches the at-risk result with "Last failure reason" by looking up the `invoice.payment_failed` accrue_event whose `subject_id` matches the `invoice_id` captured in `dunning.campaign_started` data. The `invoice.payment_failed` event is recorded in the same webhook handler path (seconds after `dunning.campaign_started` via `record_event("invoice.payment_failed", ...)`), so it will exist in the ledger.
- **D-06:** Pre-v1.44 `dunning.campaign_started` events lack the `invoice_id` key → `at_risk_subscriptions/1` returns `nil` for the failure reason, displayed as `"—"` in the table. No backfill — ledger is immutable (SQLSTATE 45A01). Consistent with the honest-default pattern established in DAN-04.
- **D-07:** Do NOT use `canonical.last_finalization_error` — it is `nil` on every `invoice.payment_failed` event by definition (it's for PDF finalization failures, not payment collection failures). Would silently poison the ledger with a semantically wrong, always-nil field.

### Ledger-tiebreaker SQL strategy (DAN-03, success criterion 2)

- **D-08:** Use a SQL `NOT EXISTS` correlated subquery as the tiebreaker: exclude subscriptions from the at-risk result where `EXISTS (SELECT 1 FROM accrue_events WHERE type IN ('dunning.recovered', 'dunning.exhausted') AND subject_id = s.id AND inserted_at >= s.dunning_campaign_started_at)`. Reads schema column and ledger in the same Postgres snapshot — closes the projection-lag race by construction.
- **D-09:** Do NOT use Elixir two-pass (schema query → in-memory filter). Two `Repo.all/1` calls structurally reintroduce the TOCTOU window this function exists to prevent — a recovered event written between pass-1 and pass-2 reproduces the exact bug. Ruled out architecturally.
- **D-10:** The `NOT EXISTS` subquery is anchored on `inserted_at >= s.dunning_campaign_started_at` to exclude terminal events from prior campaigns (a subscription that recovered in campaign 1, then failed again in campaign 2, should appear in the at-risk list for campaign 2). This prevents false exclusions from historical terminal events.

### Accrue.Billing.Query.in_active_dunning_campaign/1 (DAN-03)

- **D-11:** New function in `accrue/lib/accrue/billing/query.ex`, sibling to `dunning_sweep_candidates/2`. Single predicate: `WHERE dunning_campaign_started_at IS NOT NULL`. Returns an `Ecto.Query` composed over `Subscription`. Used as the schema-side input to `at_risk_subscriptions/1` (the tiebreaker then operates on the result).
- **D-12:** `at_risk_subscriptions/1` does NOT call `in_active_dunning_campaign/1` as a function — it uses its logic inline (or refactors it in) to produce a single compound query that can be window-filtered via `apply_window/2`. The function is a composable building block, not a `Repo.all` call.

### RecoveryLive table rendering (DAN-11)

- **D-13:** Plain `assign(:at_risk, ...)` in `handle_params/3` — NOT `stream/4`. Static page data; refreshes on window change via `handle_params`. No streaming complexity needed for an analytics table.
- **D-14:** Cross-package boundary: `RecoveryLive` calls ONLY `Accrue.Analytics.Dunning.at_risk_subscriptions/1`. No `Ecto.Query` import, no `Accrue.Repo` call, no `Accrue.Billing.Subscription` alias in `accrue_admin`. This is explicitly tested per DAN-11 success criterion 4.
- **D-15:** Window opts threading: `at_risk_subscriptions/1` accepts `[since: dt, until: dt]` opts via the same `apply_window/2` helper already in `Accrue.Analytics.Dunning`. `RecoveryLive.handle_params/3` passes the already-derived `since`/`until` from `window_bounds/1` (Phase 145 D-03 pattern).

### Claude's Discretion

- Exact SQL shape for the oban_jobs join: whether it's a `LEFT JOIN` in the main query or a separate enrichment pass per subject. Planner picks the cleanest Ecto expression given the full query shape (schema + NOT EXISTS + oban JOIN + step_count subquery + failure_reason subquery).
- `at_risk_subscriptions/1` return shape: planner picks the map keys (e.g., `%{subscription_id:, customer_id:, days_in_campaign:, current_step:, next_step_eta:, failure_reason:}`). Must be consistent with what RecoveryLive template needs.
- Whether to pass `:since`/`:until` bounds into the oban_jobs join (only jobs for the active window) or query all active jobs regardless of window. Recommend: window bounds do NOT apply to oban_jobs — the job's scheduled_at reflects current-state ETA, not a historical window.
- Test fixture approach for the projection-lag race scenario: insert a `dunning.recovered` event for a subscription whose `dunning_campaign_started_at` IS NOT NULL and assert it does NOT appear in the result.
- Whether `current_step` is 1-indexed or 0-indexed in the at-risk table display. Recommend 1-indexed ("Step 1 of 3") — matches how humans count steps.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope + requirements
- `.planning/REQUIREMENTS.md` §"Public API & Core Math (DAN)" DAN-03 — at-risk query API shape, ledger-as-tiebreaker, next-step ETA requirement, failure reason spec
- `.planning/REQUIREMENTS.md` §"Public API & Core Math (DAN)" DAN-04 — failure_message enrichment: `dunning.campaign_started` payload, `failure_message` field, pre-v1.44 honest default
- `.planning/REQUIREMENTS.md` §"Admin UI Recovery Dashboard (DAN)" DAN-11 — at-risk table rendering, plain assign, cross-package boundary, column spec
- `.planning/ROADMAP.md` §"Phase 146" — goal + 4 success criteria

### Phase 145 foundation (DO NOT regress)
- `.planning/phases/145-time-window-url-plumbing-window-selector/145-CONTEXT.md` — D-01 through D-09: `handle_params/3` as single data-loading entry point, `parse_window/1`, `window_bounds/1`, `apply_window/2` pattern, `@window` assign. Phase 146 extends `handle_params/3` with `at_risk_subscriptions/1` call alongside existing Dunning calls.

### Live code touchpoints
- `accrue/lib/accrue/billing/query.ex` — sibling module for `in_active_dunning_campaign/1`; see `dunning_sweep_candidates/2` (lines 129–143) as the closest structural analog
- `accrue/lib/accrue/analytics/dunning.ex` — `apply_window/2` (lines at bottom); `funnel/1` for `subquery/1` + inner GROUP BY pattern to replicate in `at_risk_subscriptions/1`; import block (`import Ecto.Query, only: [from: 2, subquery: 1, where: 3]`) — extend to add `join`, `left_join` as needed
- `accrue/lib/accrue/webhook/default_handler.ex` lines ~1256–1270 — `emit_campaign_started/1` to refactor to `/2` with `canonical`; `maybe_start_dunning_campaign/2` — canonical is already in scope, `get(canonical, :id)` called 2 lines after `emit_campaign_started(sub)` at line 1236
- `accrue/lib/accrue/dunning/engine/oban.ex` — established pattern for `from(j in Oban.Job, ...)` queries; use as the template for the oban_jobs join in `at_risk_subscriptions/1`
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — current `handle_params/3` (adds `at_risk` assign alongside existing assigns); current `render/1` (adds `<AtRiskTable ...>` or inline table below `<FunnelChart ...>`)
- `accrue_admin/lib/accrue_admin/components/` — existing component directory for any new `AtRiskTable` or `CustomerLink` component

### Tests
- `accrue/test/accrue/analytics/dunning_test.exs` — add `at_risk_subscriptions/1` tests: projection-lag race scenario (recovered event + non-nil schema column → NOT in result), pre-v1.44 `—` default (no invoice_id in event), ETA nil fallback (no pending Oban job)
- `accrue/test/accrue/billing/query_test.exs` — add `in_active_dunning_campaign/1` test
- `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` and dunning campaign start tests — extend `emit_campaign_started` tests to assert `data["invoice_id"]` is present when `canonical` carries an ID
- `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` — add: at-risk table renders, window change refreshes at-risk list, cross-package boundary assertion (no Ecto.Query / Repo / Subscription alias in RecoveryLive)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Billing.Query.dunning_sweep_candidates/2` — structural template for `in_active_dunning_campaign/1`: same `def foo(query \\ Subscription)` signature, same `from(s in query, where: ...)` pattern
- `Accrue.Analytics.Dunning.funnel/1` — the `subquery/1` over inner GROUP BY shape that `at_risk_subscriptions/1` will extend (possibly as a lateral join or separate subquery for step count)
- `Accrue.Analytics.Dunning.apply_window/2` + `maybe_since/2` + `maybe_until/2` — unchanged; `at_risk_subscriptions/1` passes window opts through the same path
- `Accrue.Dunning.Engine.Oban` — `from(j in Oban.Job, ...)` query pattern; use as the exact template for the oban_jobs LEFT JOIN in `at_risk_subscriptions/1` (uniqueness key shape: `args->>'subscription_id'` + `args->>'campaign_started_at'`)
- `accrue_admin/lib/accrue_admin/components/tabs.ex` — `<a>` + aria-current pattern; `AccrueAdmin.Components.WindowSelector` — both pattern references for any row-link rendering in the at-risk table
- `get(canonical, :id)` call already at `maybe_start_dunning_campaign/2` line 1237 — trivially extracted upward to pass into `emit_campaign_started/2`

### Established Patterns
- `handle_params/3` as single data-loading entry point (Phase 145 D-01): add `at_risk = Dunning.at_risk_subscriptions(since: since, until: until)` → `assign(:at_risk, at_risk)` alongside existing Dunning calls
- Cross-package boundary: `accrue_admin` LiveViews call ONLY `Accrue.Analytics.Dunning.*` for analytics data. No `Ecto.Query`, no `Accrue.Repo`, no `Accrue.Billing.*` aliases in `accrue_admin`. Enforced by test assertion per DAN-11.
- Honest-default `"—"` pattern: pre-v1.44 campaigns, nil ETA when job mid-execution. Same treatment as Phase 144's JSONB safe-cast (contribute 0 rather than crash).
- `oban_jobs` LEFT JOIN: since we want at-risk subscriptions even when the next job's ETA is nil, use LEFT JOIN to `oban_jobs` — subscriptions with no pending Oban job appear with `next_step_eta: nil`.
- `dunning.campaign_started` event `data` map additions: `invoice_id` follows the same key-addition pattern as the Phase 144 `campaign_anchor` retrofit (no schema change — `data` is jsonb, open-shape map).

### Integration Points
- `default_handler.ex:emit_campaign_started/2`: add `canonical` arg, inject `invoice_id: get(canonical, :id)` into the `data` map passed to `Events.record/1`
- `accrue/lib/accrue/analytics/dunning.ex`: add `at_risk_subscriptions/1` alongside `funnel/1` and `recovered_vs_lost_mrr/1`; add `Oban.Job` alias; extend import to include any additional Ecto query functions needed
- `accrue/lib/accrue/billing/query.ex`: add `in_active_dunning_campaign/1` composer
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`: extend `handle_params/3` + `render/1` to add at-risk table below `<FunnelChart ...>`

</code_context>

<specifics>
## Specific Ideas

- **NOT EXISTS anchor on `dunning_campaign_started_at`**: `NOT EXISTS (SELECT 1 FROM accrue_events WHERE type IN ('dunning.recovered', 'dunning.exhausted') AND subject_id = s.id AND inserted_at >= s.dunning_campaign_started_at)` — the `inserted_at >= dunning_campaign_started_at` bound is essential to prevent false exclusions from historical campaigns.
- **Oban job uniqueness key for the query**: `DunningStep` jobs are keyed `[:subscription_id, :step_key, :campaign_started_at]` (per `DunningStep` module doc). The oban_jobs join filters on `args->>'subscription_id' = s.id` AND `state IN ['available', 'scheduled', 'retryable']`; `MIN(scheduled_at)` gives the next-step ETA.
- **`invoice_id` in event data**: stored as the Stripe invoice ID string (e.g., `"in_xxxx"`), which is the Accrue `accrue_invoices.processor_id`. The ledger join in `at_risk_subscriptions/1` matches on `accrue_events.subject_id` (which records Accrue UUID) — the planner must resolve whether the join key is the Stripe ID or the Accrue Invoice UUID. Check `record_event("invoice.payment_failed", "Invoice", updated.id, evt_id)` — `updated.id` is the Accrue UUID. The canonical has the Stripe ID. Both might need to be stored or the join must go through `accrue_invoices.processor_id`. **Planner flag: verify the join key shape and store the correct ID.**
- **`current_step`**: computed as `COUNT(accrue_events WHERE type = 'dunning.step_sent' AND subject_id = s.id AND inserted_at >= s.dunning_campaign_started_at)`. 1-indexed for display ("Step 2 of 3" means 2 steps sent so far — the planner should verify whether "current step" means "last completed step" or "next step to be sent").
- **`days_in_campaign`**: computed as `EXTRACT(EPOCH FROM (NOW() - s.dunning_campaign_started_at)) / 86400` cast to integer. Accrue.Clock pattern may need to be followed for Fake-lane determinism — planner should use `Accrue.Clock.utc_now()` as the reference point, not `NOW()` in raw SQL, if Fake-lane correctness is required.

</specifics>

<deferred>
## Deferred Ideas

- Per-subscription drill-down (row-click → CampaignLive) → Phase 147 (DAN-05/12). The at-risk table rows will need a row-click affordance that links to the Phase 147 route — planner may stub the link href but the route doesn't exist until Phase 147.
- Recovery-rate column on the at-risk table (e.g., per-campaign recovery probability) → Phase 148 or post-v1.44.
- MRR-at-risk column (DAN-03 notes: "extracting calculate_mrr_cents/1 to a shared module would be required for an MRR-at-risk column") — explicitly deferred to v1.45+ per REQUIREMENTS.

</deferred>

---

*Phase: 146-at-risk-query-at-risk-table-last-failure-enrichment*
*Context gathered: 2026-05-27*
