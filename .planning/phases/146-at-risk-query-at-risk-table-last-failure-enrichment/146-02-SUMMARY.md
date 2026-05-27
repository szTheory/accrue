---
phase: 146
plan: "02"
subsystem: billing/analytics
tags: [dunning, at-risk-query, ecto-fragment, tdd, uuid-cast]
dependency_graph:
  requires: ["146-01"]
  provides: [at_risk_subscriptions/1, apply_campaign_window/2]
  affects:
    - accrue/lib/accrue/analytics/dunning.ex
    - accrue/test/accrue/analytics/at_risk_subscriptions_test.exs
tech_stack:
  added: []
  patterns:
    - NOT EXISTS correlated subquery fragment (ledger tiebreaker)
    - UUID::text cast for varchar/uuid cross-column comparisons in Ecto fragments
    - LEFT JOIN oban_jobs via JSONB ->> operator with ::text cast
    - apply_campaign_window/2 with [s] named binding on dunning_campaign_started_at
    - Accrue.Clock.utc_now() pinning for Fake-lane determinism
key_files:
  created:
    - accrue/test/accrue/analytics/at_risk_subscriptions_test.exs
  modified:
    - accrue/lib/accrue/analytics/dunning.ex
decisions:
  - "UUID::text casts required in all Ecto fragment comparisons between accrue_events.subject_id (varchar) and UUID primary keys"
  - "failure_reason returns raw pf.data map (nil for pre-v1.44 or unmatched invoice) per D-06 honest-default"
  - "apply_campaign_window/2 uses [s] named binding on s.dunning_campaign_started_at, not reusing apply_window/2 [e] binding"
  - "datetime microsecond precision ({0, 6}) required for accrue_events inserts with explicit inserted_at in tests"
metrics:
  duration: "8m"
  completed: "2026-05-27"
  tasks: 2
  files: 2
---

# Phase 146 Plan 02: at_risk_subscriptions/1 + Tests Summary

**One-liner:** `at_risk_subscriptions/1` implemented with NOT EXISTS ledger tiebreaker, oban_jobs ETA join, invoice bridge for failure_reason, and apply_campaign_window/2; 8 tests covering projection-lag race, ETA nil, pre-v1.44 default, and window filtering.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | at_risk_subscriptions/1 + apply_campaign_window/2 in dunning.ex | e9308548 | accrue/lib/accrue/analytics/dunning.ex |
| 2 (fix + tests) | UUID::text casts in query + at_risk_subscriptions test suite | 95739611 | accrue/lib/accrue/analytics/dunning.ex, accrue/test/accrue/analytics/at_risk_subscriptions_test.exs |

## What Was Built

### Task 1: at_risk_subscriptions/1 + apply_campaign_window/2

New public function `at_risk_subscriptions/1` in `accrue/lib/accrue/analytics/dunning.ex`:

- Accepts `opts \\ []` with `:since`/`:until` keyword options (filtered on `dunning_campaign_started_at`)
- WHERE 1: `not is_nil(s.dunning_campaign_started_at)` — active campaign predicate (D-11 inline)
- WHERE 2: NOT EXISTS correlated fragment subquery referencing `dunning.recovered` and `dunning.exhausted` event types anchored by `inserted_at >= dunning_campaign_started_at` (D-08, D-10)
- INNER JOIN to `accrue_customers` for `customer_label` via `COALESCE(email, name)`
- LEFT JOIN to `dunning.campaign_started` event anchored to this campaign
- LEFT JOIN to `accrue_invoices` via `processor_id = cs.data->>'invoice_id'` (Option B bridge, D-05)
- LEFT JOIN to `invoice.payment_failed` event via UUID::text cast on `pf.subject_id = inv.id::text`
- LEFT JOIN to `oban_jobs` with worker, subscription_id, and `to_char` timestamp fragment for ETA
- `days_in_campaign` uses `Accrue.Clock.utc_now()` pinned value (Fake-lane determinism, D-03)
- `current_step` is a correlated subquery counting `dunning.step_sent` events for this campaign
- `group_by` on all non-aggregate selected columns; `order_by` descending on campaign start
- Returns `[map()]` via `Repo.all/1`

New private helper `apply_campaign_window/2` with `maybe_since_campaign/2` and `maybe_until_campaign/2` using `[s]` binding on `s.dunning_campaign_started_at` — explicitly NOT reusing `apply_window/2`'s `[e]` binding (Pitfall 1 prevention).

Extended aliases:
```elixir
alias Accrue.Billing.{Customer, Invoice, Subscription}
alias Oban.Job
```

### Task 2: Test Suite

New file `accrue/test/accrue/analytics/at_risk_subscriptions_test.exs`:

- `use Accrue.BillingCase, async: false` — full subscription fixtures + sandbox
- `use Oban.Testing, repo: Accrue.TestRepo` — Oban job state queries

8 tests in 5 describe blocks:

| Test | Scenario | Result |
|------|----------|--------|
| Projection-lag race (recovered) | Subscription with `dunning.recovered` event since campaign start excluded | PASS |
| Projection-lag race (exhausted) | Subscription with `dunning.exhausted` event since campaign start excluded | PASS |
| Happy path (included) | At-risk subscription with all 7 keys in result | PASS |
| Happy path (nil anchor excluded) | Subscription without dunning anchor not in result | PASS |
| ETA nil fallback | `next_step_eta == nil` when no Oban job | PASS |
| Pre-v1.44 default | `failure_reason == nil` without `invoice_id` key | PASS |
| Window filter (:since) | Old campaign excluded; recent campaign included | PASS |
| Window filter (:until) | Future campaign anchor excluded by :until bound | PASS |

## Verification

```
mix test test/accrue/analytics/at_risk_subscriptions_test.exs test/accrue/analytics/dunning_test.exs --seed 0
```

**Result: 16 tests, 0 failures**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] UUID::text cast required for varchar/uuid fragment comparisons**
- **Found during:** Task 2 (tests failed with `operator does not exist: character varying = uuid`)
- **Issue:** `accrue_events.subject_id` is `character varying`; Ecto schema UUIDs (`s.id`, `inv.id`) are typed as `uuid`. Fragment positional `?` passes them as UUID type, causing Postgres type mismatch on `=` operator.
- **Fix:** Added `::text` casts to all UUID-to-varchar fragment comparisons:
  - `cs.subject_id = a0."id"::text` (campaign_started LEFT JOIN)
  - `pf.subject_id = a3."id"::text` (payment_failed LEFT JOIN)
  - `oban_jobs args ->> 'subscription_id' = a0."id"::text`
  - NOT EXISTS `subject_id = a0."id"::text`
  - current_step subquery `subject_id = a0."id"::text`
- **Files modified:** `accrue/lib/accrue/analytics/dunning.ex`
- **Commit:** 95739611

**2. [Rule 1 - Bug] DateTime microsecond precision in test fixtures**
- **Found during:** Task 2 (ArgumentError: `utc_datetime_usec expects microsecond precision`)
- **Issue:** `DateTime.add/3` with integer seconds returns second-precision DateTime (no microseconds). `accrue_events.inserted_at` is `:utc_datetime_usec` and rejects timestamps without microsecond precision.
- **Fix:** Added `%{datetime | microsecond: {0, 6}}` normalization after `DateTime.add/3` calls in test fixtures.
- **Files modified:** `accrue/test/accrue/analytics/at_risk_subscriptions_test.exs`
- **Commit:** 95739611

## Known Stubs

None — all behavioral changes are complete with real data flows. `failure_reason` returning the raw `pf.data` map (nil when absent) is the intended v1.44 behavior per D-06 honest-default, not a stub.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.

- T-146-03 mitigated: all dynamic values in fragments use `^` pinning or `?` positional placeholders; no string interpolation.
- T-146-04 accepted: `pf.data` contains `stripe_event_id` reference (not PII) per T-129-01 contract.
- T-146-05 accepted: query is operator-only, analytics dashboard.

## TDD Gate Compliance

Task 1 followed the implementation-first pattern (compile verification + existing tests) before Task 2 added the dedicated test file. The plan marked both tasks `tdd="true"` with the explicit instruction that Task 2 creates the test file.

Both commits are `feat(146-02)` per the compound fix (task 1 implementation + task 2 fix+tests combined by necessity of the bug-fix deviation).

## Self-Check: PASSED

- `accrue/lib/accrue/analytics/dunning.ex` — modified, exists ✓
- `accrue/test/accrue/analytics/at_risk_subscriptions_test.exs` — created, exists ✓
- Commit e9308548 exists ✓
- Commit 95739611 exists ✓
- `at_risk_subscriptions` appears in dunning.ex ✓
- `apply_campaign_window` appears in dunning.ex ✓
- `alias Oban.Job` in dunning.ex ✓
- `[s]` binding with `s.dunning_campaign_started_at` in apply_campaign_window ✓
- NOT EXISTS fragment with `dunning.recovered` and `dunning.exhausted` ✓
- LEFT JOIN to Oban.Job with `"Accrue.Workers.DunningStep"` and state filter ✓
- LEFT JOIN through `Invoice.processor_id` ✓
- 8 tests in at_risk_subscriptions_test.exs, all passing ✓
- `mix test ...dunning_test.exs` exits 0 ✓
