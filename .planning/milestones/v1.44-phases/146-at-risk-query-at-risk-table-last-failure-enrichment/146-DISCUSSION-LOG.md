# Phase 146: At-risk query + at-risk table + last-failure enrichment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 146-at-risk-query-at-risk-table-last-failure-enrichment
**Areas discussed:** Next-step ETA source, failure_message capture path, Ledger-tiebreaker SQL strategy

---

## Next-step ETA source

| Option | Description | Selected |
|--------|-------------|----------|
| Query `oban_jobs.scheduled_at` | Precise ETA from live Oban job row. Reflects retries and backoff. Nil fallback when job is mid-execution. `Engine.Oban` already does this — pattern established. | ✓ |
| Config-cadence derivation | Compute from `dunning_campaign_started_at` + configured step offsets. Pure-ledger, zero Oban coupling. Silently wrong under retries. | |

**User's choice:** Query `oban_jobs.scheduled_at`
**Notes:** DAN-03 explicitly says "derived from active Oban job timing." Research confirmed `Engine.Oban` already queries `oban_jobs` via `from(j in Oban.Job, ...)` — coupling precedent is set. Nil-ETA fallback displays `"—"`.

---

## failure_message capture path

| Option | Description | Selected |
|--------|-------------|----------|
| `invoice_id` pointer in event + ledger join for display | Add `invoice_id` to `dunning.campaign_started` data. `at_risk_subscriptions/1` joins `invoice.payment_failed` accrue_events to surface failure context. Pre-v1.44 = `"—"`. | ✓ |
| `last_finalization_error` (wrong semantic) | Single-field, no change. Nil for payment failures by definition — silently wrong. | |

**User's choice:** `invoice_id` pointer + ledger join
**Notes:** `canonical.last_finalization_error` is for PDF finalization errors, not payment collection failures — definitionally nil on `invoice.payment_failed` events. The `invoice_id` approach: `emit_campaign_started/1` refactored to `/2` to accept `canonical`; `get(canonical, :id)` already called 2 lines after the current call site. Important planner flag: the join key must be resolved — Stripe invoice ID (from canonical) vs. Accrue Invoice UUID (from `record_event` which uses `updated.id`). Both may need to be stored or the join must go through `accrue_invoices.processor_id`.

---

## Ledger-tiebreaker SQL strategy

| Option | Description | Selected |
|--------|-------------|----------|
| SQL `NOT EXISTS` subquery | Single round-trip. Atomically consistent. Reads schema + ledger in same Postgres snapshot. Closes projection-lag race by construction. `subquery/1` already imported in `Accrue.Analytics.Dunning`. | ✓ |
| Elixir two-pass (Repo.all + in-memory filter) | Two simpler queries. Structurally reintroduces the TOCTOU race window this function exists to prevent. | |

**User's choice:** SQL `NOT EXISTS` subquery
**Notes:** Two-pass is architecturally ruled out — it makes the race condition structural. The `NOT EXISTS` is anchored on `inserted_at >= s.dunning_campaign_started_at` to prevent false exclusions from historical campaigns.

---

## Claude's Discretion

- Exact SQL shape for the oban_jobs join (LEFT JOIN in main query vs. separate enrichment pass).
- `at_risk_subscriptions/1` return map keys.
- Whether `:since`/`:until` window bounds apply to the oban_jobs join (recommendation: no — ETA is current-state, not historical).
- `current_step` indexing: 1-indexed for display (recommendation).
- Whether `days_in_campaign` uses raw SQL `NOW()` or `Accrue.Clock.utc_now()` for Fake-lane determinism (recommendation: planner should use Clock).
- Test fixture approach for projection-lag race scenario.

## Deferred Ideas

- Per-subscription drill-down (row-click → CampaignLive) → Phase 147 (DAN-05/12).
- Recovery-rate column on at-risk table → Phase 148 or post-v1.44.
- MRR-at-risk column → v1.45+ per REQUIREMENTS.
