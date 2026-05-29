---
phase: 146-at-risk-query-at-risk-table-last-failure-enrichment
verified: 2026-05-27T21:15:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 1
overrides:
  - test: "SC #3 — Last Failure Reason column shows — for all campaigns"
    accepted_by: owner
    rationale: "failure_message not stored in invoice.payment_failed ledger event data (D-07: no additional Stripe API calls in v1.44). Wiring infrastructure is correct; enrichment tracked as post-v1.44 work."
    date: "2026-05-27"
human_verification:
  - test: "Confirm SC #3 design-limitation acceptance: post-v1.44 failure_message"
    expected: "The 'Last Failure Reason' column shows a human-readable failure reason for post-v1.44 campaigns, OR developer confirms the '—' fallback is acceptable because the Stripe ledger event data does not contain failure_message without an additional API call"
    why_human: "format_failure/1 extracts failure_code/failure_message keys from pf.data, but the invoice.payment_failed ledger event only stores %{source: webhook, stripe_event_id: evt_xxx}. Neither failure_code nor failure_message exists in that map. The column will always render '—' for all campaigns including post-v1.44 ones. ROADMAP SC #3 says 'surface the triggering invoice failure_message' — this is technically not done. The design decision (D-06, RESEARCH.md Open Question 1) acknowledges the limitation but the SC wording implies otherwise. Human confirmation needed on whether to accept this as the v1.44 behavior or treat it as a gap."
---

# Phase 146: At-risk query + at-risk table + last-failure enrichment — Verification Report

**Phase Goal:** Operators see the live "who is currently in dunning right now" list inline on `/billing/analytics/recovery` — each row showing customer, days in campaign, current step, next-step ETA, and last-failure reason — without false positives from subscriptions that just recovered but haven't propagated to the projection yet.
**Verified:** 2026-05-27T21:15:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | Operator visits `/billing/analytics/recovery` and sees an "At Risk Subscriptions" table inline below the funnel with columns: customer (linked), days-in-campaign, current step, next-step ETA, last failure reason | ✓ VERIFIED | `at_risk_table.ex` renders all 5 column headers; wired into `recovery_live.ex` render; 12 tests pass including `html =~ "At-Risk Subscriptions"` |
| SC2 | A subscription with a `dunning.recovered` event written but `dunning_campaign_started_at` not yet nilled does NOT appear in the at-risk list (projection-lag race) | ✓ VERIFIED | `at_risk_subscriptions/1` uses NOT EXISTS correlated fragment subquery (`accrue_events WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = s.id::text AND inserted_at >= s.dunning_campaign_started_at`). Two projection-lag tests pass (recovered + exhausted variants). |
| SC3 | Post-v1.44 active campaigns surface the triggering invoice's `failure_message` in "Last failure reason"; pre-v1.44 campaigns show "—" | ? UNCERTAIN | Infrastructure is in place: `dunning.campaign_started` now carries `invoice_id`, and `at_risk_subscriptions/1` uses a correlated subquery to join `invoice.payment_failed` events. However, `invoice.payment_failed` ledger events only store `%{"source" => "webhook", "stripe_event_id" => "evt_xxx"}` — no `failure_code` or `failure_message` key. `format_failure/1` extracts those keys but they are absent; the column renders "—" for ALL campaigns including post-v1.44. D-06 / RESEARCH.md accept this as v1.44 design limitation, but ROADMAP SC wording implies the failure message is surfaced. |
| SC4 | LiveView calls ONLY `Accrue.Analytics.Dunning.*` — no `Ecto.Query` import, no `Accrue.Repo`, no `Accrue.Billing.Subscription` alias | ✓ VERIFIED | `recovery_live.ex` checked — none of those appear. Static assertion test in `recovery_live_test.exs` passes and refutes all three. |

**Score:** 3/4 truths verified (SC3 uncertain)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue/lib/accrue/webhook/default_handler.ex` | `emit_campaign_started/2` with `invoice_id: get(canonical, :id)` in data map | ✓ VERIFIED | Line 1256: `defp emit_campaign_started(%Subscription{} = sub, canonical)`. Line 1263: `data: %{step_count: step_count, invoice_id: get(canonical, :id)}`. Call site line 1236: `emit_campaign_started(sub, canonical)`. |
| `accrue/lib/accrue/billing/query.ex` | `in_active_dunning_campaign/1` composable query predicate | ✓ VERIFIED | Lines 147-151: `@doc`, `@spec`, `def in_active_dunning_campaign(query \\ Subscription)` with `from(s in query, where: not is_nil(s.dunning_campaign_started_at))`. Placed after `dunning_sweep_candidates/2`. |
| `accrue/lib/accrue/analytics/dunning.ex` | `at_risk_subscriptions/1` + `apply_campaign_window/2` | ✓ VERIFIED | Full implementation present lines 147-280. `@spec at_risk_subscriptions(keyword()) :: [map()]`, `@since "1.4.0"`. `apply_campaign_window/2` uses `[s]` binding on `s.dunning_campaign_started_at`. |
| `accrue/test/accrue/analytics/at_risk_subscriptions_test.exs` | 5 scenarios (projection-lag race x2, happy path x2, ETA nil, pre-v1.44 default, window filter x2) | ✓ VERIFIED | File exists, 8 tests in 5 describe blocks, all pass. `use Accrue.BillingCase, async: false` + `use Oban.Testing, repo: Accrue.TestRepo`. |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | `AccrueAdmin.Components.AtRiskTable` Phoenix.Component | ✓ VERIFIED | `defmodule AccrueAdmin.Components.AtRiskTable`, `use Phoenix.Component`, `attr :rows, :list, required: true`, `attr :base_path, :string, default: "/billing"`. All 5 column headers present. Empty state `data-role="empty-state"` with "No active dunning campaigns". |
| `accrue_admin/assets/css/app.css` | `ax-at-risk-*` CSS classes | ✓ VERIFIED | `.ax-at-risk-table`, `.ax-at-risk-header`, `.ax-at-risk-grid` all present at lines 1278-1313. |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | `at_risk_subscriptions` call + `@at_risk` assign + AtRiskTable render | ✓ VERIFIED | Line 22: `at_risk = Dunning.at_risk_subscriptions(since: since, until: until)`. Line 40: `|> assign(:at_risk, at_risk)`. Line 7: `AtRiskTable` in alias. Line 89: `<AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `default_handler.ex:maybe_start_dunning_campaign/2` | `emit_campaign_started/2` | `emit_campaign_started(sub, canonical)` | ✓ WIRED | Line 1236 confirmed. |
| `dunning.campaign_started data` | `accrue_invoices.processor_id` | `invoice_id: get(canonical, :id)` in data map | ✓ WIRED | Line 1263 confirmed. Bridge to invoices is established by storing the Stripe invoice ID. |
| `at_risk_subscriptions/1` | `accrue_events` | NOT EXISTS correlated subquery for dunning.recovered/dunning.exhausted | ✓ WIRED | Lines 197-201: `fragment("NOT EXISTS (SELECT 1 FROM accrue_events WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = ?::text AND inserted_at >= ?)", s.id, s.dunning_campaign_started_at)` |
| `at_risk_subscriptions/1` | `oban_jobs` | LEFT JOIN Oban.Job on worker + subscription_id + campaign_started_at | ✓ WIRED | Lines 186-194: LEFT JOIN to `j in Job` with worker `"Accrue.Workers.DunningStep"` and fragment args-based join + state filter. |
| `at_risk_subscriptions/1` | `accrue_invoices` (via correlated subquery) | Scalar subquery joining accrue_events → accrue_invoices via `cs.data->>'invoice_id' = i.processor_id` | ✓ WIRED | Lines 228-242: correlated subquery `JOIN accrue_invoices i ON i.id::text = e.subject_id JOIN accrue_events cs ON cs.data->>'invoice_id' = i.processor_id`. |
| `RecoveryLive.handle_params/3` | `Accrue.Analytics.Dunning.at_risk_subscriptions/1` | `Dunning.at_risk_subscriptions(since: since, until: until)` | ✓ WIRED | Line 22 of recovery_live.ex confirmed. |
| `RecoveryLive.render/1` | `AtRiskTable.at_risk_table` | `rows={@at_risk}` | ✓ WIRED | Line 89 of recovery_live.ex confirmed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `at_risk_subscriptions/1` | `[map()]` from `Repo.all(query)` | Postgres query joining accrue_subscriptions, accrue_customers, oban_jobs, correlated subqueries on accrue_events | Yes — DB query with real joins | ✓ FLOWING |
| `RecoveryLive` `@at_risk` | `at_risk` assign | `Dunning.at_risk_subscriptions(since: since, until: until)` called in handle_params/3 | Yes — calls real DB query function | ✓ FLOWING |
| `AtRiskTable` `rows` | `@at_risk` from parent | `assign(:at_risk, at_risk)` in socket chain | Yes — flows from handle_params DB result | ✓ FLOWING |
| `failure_reason` display | `format_failure(row.failure_reason)` | `pf.data` from correlated `invoice.payment_failed` event subquery | CAVEAT: data exists when matched invoice found, but `failure_code`/`failure_message` keys absent — always renders "—" | ⚠️ PARTIAL |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Plan 01 tests (16 tests) | `cd accrue && mix test test/accrue/webhook/dunning_campaign_start_test.exs test/accrue/billing/query_test.exs --seed 0` | 16 tests, 0 failures | ✓ PASS |
| Plan 02 tests (16 tests) | `cd accrue && mix test test/accrue/analytics/at_risk_subscriptions_test.exs test/accrue/analytics/dunning_test.exs --seed 0` | 16 tests, 0 failures | ✓ PASS |
| Plan 03 tests (12 tests) | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` | 12 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DAN-03 | 146-01, 146-02 | `in_active_dunning_campaign/1` query composer + `at_risk_subscriptions/1` with ledger-tiebreaker, next-step ETA, days_in_campaign, current_step | ✓ SATISFIED | `query.ex` has `in_active_dunning_campaign/1`; `dunning.ex` has `at_risk_subscriptions/1` with NOT EXISTS tiebreaker, oban_jobs ETA join, correlated step count, days_in_campaign |
| DAN-04 | 146-01, 146-02 | `dunning.campaign_started` payload enriched with `invoice_id`; last failure reason from `invoice.payment_failed` event; pre-v1.44 shows "—" | ⚠️ PARTIAL | `invoice_id` stored correctly. Pre-v1.44 shows "—" (nil failure_reason). Post-v1.44 infrastructure exists (joins `invoice.payment_failed` events) but `failure_code`/`failure_message` absent from event data — effectively also shows "—". Accepted design limitation per D-06, but ROADMAP SC #3 implies actual failure message is surfaced. |
| DAN-11 | 146-03 | At-risk subscriptions table on dashboard; plain `assign/3`; 5 columns with customer link; cross-package boundary | ✓ SATISFIED | `AtRiskTable` component exists with all columns; `RecoveryLive` uses plain `assign(:at_risk, ...)` not stream; cross-package boundary enforced and tested; 3 DAN-11 tests pass |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | 55 | Customer drill-down href resolves to 404 until Phase 147 | ℹ️ Info | Forward-reference stub, documented in 146-03-SUMMARY. Phase 147 closes the route. Operator-only UI, non-sensitive UUID. |

No `TBD`, `FIXME`, or `XXX` markers found in phase-modified files. No unreferenced debt markers.

### Human Verification Required

#### 1. SC #3 Failure Message Display — Design Limitation Acceptance

**Test:** Review the `format_failure/1` function in `at_risk_table.ex` and the `invoice.payment_failed` event data structure recorded by `default_handler.ex:record_event/5`. Confirm whether "—" in the Last Failure Reason column for post-v1.44 campaigns is acceptable as the v1.44 behavior.

**Expected per ROADMAP SC #3:** Post-v1.44 campaigns surface the triggering invoice's `failure_message` in the Last Failure Reason column.

**Actual behavior:** `invoice.payment_failed` ledger events store `%{"source" => "webhook", "stripe_event_id" => "evt_xxx"}` only. `format_failure/1` looks for `failure_code` or `failure_message` keys, neither of which exists. The column renders "—" for all campaigns, including post-v1.44 ones.

**Why human:** The implementation correctly connects all the data wiring (invoice_id stored in campaign_started, bridge to invoice.payment_failed via processor_id), but the underlying Stripe failure message is not persisted to the ledger at event-record time (it would require a `Stripe.PaymentIntent.retrieve` or `Stripe.Charge.retrieve` API call at webhook processing time). CONTEXT D-07 explicitly rules out `canonical.last_finalization_error`. RESEARCH.md Open Question 1 accepted this gap. The question is whether the project owner accepts "—" for post-v1.44 campaigns as a v1.44 design decision, or whether this is a blocker requiring the failure reason to actually be surfaced.

**If accepted as design:** Add an override in this VERIFICATION.md frontmatter:
```yaml
overrides:
  - must_have: "Post-v1.44 active campaigns surface the triggering invoice's failure_message in the Last failure reason column"
    reason: "invoice.payment_failed ledger events do not store failure_message/failure_code without an additional Stripe API call (ruled out per D-07, RESEARCH.md Open Question 1). The column shows — for all campaigns in v1.44; the Phase 148 or later phase can add Stripe Charge enrichment. Infrastructure (invoice_id stored, bridge wired) is complete."
    accepted_by: "jon"
    accepted_at: "ISO timestamp"
```

### Gaps Summary

No hard blockers were found. All three test suites pass (44 total tests, 0 failures). The single human item is an uncertainty about whether ROADMAP SC #3 is considered met given the data limitation: `failure_message` is not available in the Stripe ledger event data without a separate API call, so the "Last Failure Reason" column always renders "—" even for post-v1.44 campaigns.

The implementation is complete, correct, and passing. The question is one of ROADMAP success criterion interpretation, not implementation quality.

**Code review post-fix status:** The review commit (142f21ba) resolved all critical and warning issues: CR-01 (GROUP BY duplication fixed with scalar subquery), CR-02 (format_failure now extracts failure_code/failure_message instead of stripe_event_id), WR-01 (active_window_label test helper fixed), WR-02 (cs left join Cartesian product risk resolved by the scalar subquery approach), WR-03 (current_step == 0 renders "Pending" not "Step 0").

---

_Verified: 2026-05-27T21:15:00Z_
_Verifier: Claude (gsd-verifier)_
