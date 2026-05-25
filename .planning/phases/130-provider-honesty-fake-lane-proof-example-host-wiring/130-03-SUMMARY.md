---
phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
plan: "03"
subsystem: dunning-journey-test
tags: [dunning, fake-lane, full-journey, default-handler, capabilities, tdd, dun-10]
dependency_graph:
  requires: ["130-01"]
  provides: [dunning-full-journey-proof, fake-lane-merge-gate, d09-label-mirror-code-side]
  affects:
    - accrue/test/accrue/dunning/dunning_full_journey_test.exs
tech_stack:
  added: []
  patterns: [real-entry-point-test, clock-advance-drain, telemetry-assert, ledger-assert, label-mirror-test]
key_files:
  created:
    - accrue/test/accrue/dunning/dunning_full_journey_test.exs
  modified: []
decisions:
  - "Oban.drain_queue with_scheduled: true required for chained DunningStep future jobs (A1 confirmed — drain without with_scheduled would not execute the day-5 and day-12 scheduled steps)"
  - "Clock.advance/2 signature is advance(duration, opts) — not advance/1; opts can be [] to use the default Fake processor"
  - "fire_payment_succeeded/1 fires customer.subscription.updated with status: active (NOT invoice.paid) — recovery path runs through reduce_subscription → maybe_finalize_dunning_campaign, not the invoice reducer"
  - "Fake.stub(:update_subscription, ...) required for sweeper test — subscription not registered in Fake's in-memory store when seeded directly via DB insert"
  - "sub_reloaded = Repo.reload!(sub) required before updating past_due_since in exhaustion test — fire_payment_failed increments lock_version causing StaleEntryError"
metrics:
  duration: 7min
  completed_date: "2026-05-25"
  tasks: 2
  files: 1
---

# Phase 130 Plan 03: Fake-Lane Full-Journey Proof Through DefaultHandler Summary

Deterministic Fake-lane full-journey test proving the entire dunning journey (start → step progression → cancel-on-recovery → exhaustion) driven through the real `Accrue.Webhook.DefaultHandler` entry point, with Phase-129 observable contract assertions at each stage and D-09 Capabilities label-mirror assertions. Untagged (merge-blocking default suite).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Scaffold full-journey test (header, setup, helpers, label mirror) | 00be396d | dunning_full_journey_test.exs |
| 2 | Implement four-stage journey through DefaultHandler with observable-contract assertions | 00be396d | dunning_full_journey_test.exs |

(Tasks 1 and 2 were committed atomically — the scaffold + full implementation is a single coherent file with 553 lines.)

## Key Decisions

**1. A1 confirmed: `with_scheduled: true` required for drain**

`Oban.drain_queue(queue: :accrue_dunning)` by default only drains jobs in `available` state. The DunningStep worker chains the next step with `schedule_in: N_seconds`, leaving it in `scheduled` state. After `Clock.advance`, `drain_queue(with_scheduled: true)` promotes scheduled jobs to available and executes them. This is the critical pattern for the journey's progression stages.

**2. Recovery path is `customer.subscription.updated`, not `invoice.paid`**

The `dunning.recovered` ledger event + telemetry are emitted by `maybe_finalize_dunning_campaign/2` inside `reduce_subscription`. This is only called from the `customer.subscription.updated` handler path. `invoice.paid` goes through `reduce_invoice` which handles the invoice row, not the subscription dunning state. `fire_payment_succeeded/1` fires `customer.subscription.updated` with status: active.

**3. Fake.stub(:update_subscription) needed for sweeper tests**

The subscription is seeded directly into the DB via `Repo.insert` without registering it in the Fake processor's in-memory store. `DunningSweeper.sweep()` calls `Processor.update_subscription(processor_id, ...)` which the Fake would return `{:error, resource_missing}` for, causing `sweep_one` to return `false` and `sweep/0` to return `{:ok, 0}`. Stubbing is the correct pattern for this scenario.

**4. `Clock.advance([days: N], [])` not `Clock.advance([days: N])`**

`Accrue.Test.Clock.advance/1` does not exist — the function is `advance/2`. The first clause matches `(duration, opts)` when both args are present and duration is binary/integer/list. Passing `[]` as opts uses the default Fake processor.

## Real-Path Findings (D-10)

No wiring bugs found on the real entry path. The dunning feature is fully wired through `DefaultHandler.handle/1`:

- `invoice.payment_failed` → `reduce_invoice` → `maybe_bump_past_due_since` → `maybe_start_dunning_campaign` → sets anchor + enqueues day-0 DunningStep + emits `dunning.campaign_started`
- `DunningStep.perform` (drain) → delivers email + `dunning.step_sent` → chains next step
- `customer.subscription.updated` (active) → `reduce_subscription` → `maybe_finalize_dunning_campaign` → clears anchor + emits `dunning.recovered` + post-commit bulk cancel
- `DunningSweeper.sweep/0` + `customer.subscription.updated` (unpaid) → `maybe_emit_dunning_exhaustion` + `maybe_finalize_dunning_campaign` → emits `dunning.exhausted` + clears anchor

## Test Structure

The file provides 7 tests:

1. **Label mirror test** (D-09): asserts all 6 `provider_support_label/2` dunning.* values and 2 public `support_label/1` values against the doc literals from Plan 01.

2. **Full progression test** (Stages 1+2): `invoice.payment_failed` → campaign start → drain day-0 → advance 5d + drain day-5 → advance 7d + drain day-12.

3. **Cancel-on-recovery test** (Stage 3): start campaign → fire recovery (`customer.subscription.updated` active) → assert anchor nil, no remaining jobs, `dunning.recovered`.

4. **Exhaustion main test** (Stage 4): run all steps → `DunningSweeper.sweep/0` → fire `customer.subscription.updated` (unpaid) → assert `dunning.exhausted`, anchor cleared.

5. **No recovered-on-exhaustion test**: terminal edge does NOT emit `dunning.recovered`.

6-7. **Integrity tests**: confirm `fire_payment_failed` goes through DefaultHandler (past_due_since set), and nil next_payment_attempt is handled gracefully.

## Deviations from Plan

**1. [Rule 1 - Bug] Clock.advance/1 does not exist**
- **Found during:** Task 1
- **Issue:** `Clock.advance([days: 5])` is undefined — the function is `advance/2`, with `advance(duration, opts)` as the single-arg dispatch form (which only matches when called with 2 args).
- **Fix:** Changed all calls to `Clock.advance([days: N], [])`.
- **Files modified:** accrue/test/accrue/dunning/dunning_full_journey_test.exs
- **Commit:** 00be396d

**2. [Rule 1 - Bug] Ecto.StaleEntryError in exhaustion test**
- **Found during:** Task 2
- **Issue:** `fire_payment_failed` increments `lock_version` on the subscription row (via `maybe_bump_attempt` + optimistic lock). Using the stale `sub` struct from setup then calling `Repo.update` in the exhaustion test triggered `Ecto.StaleEntryError`.
- **Fix:** Added `sub_reloaded = Repo.reload!(sub)` before the `past_due_since` update.
- **Files modified:** accrue/test/accrue/dunning/dunning_full_journey_test.exs
- **Commit:** 00be396d

**3. [Rule 2 - Missing functionality] Fake.stub needed for sweeper**
- **Found during:** Task 2
- **Issue:** Subscription seeded directly into DB is not registered in Fake's in-memory store. `DunningSweeper.sweep()` calls `Processor.update_subscription` which the Fake returns `{:error, resource_missing}` for, causing `sweep/0` to return `{:ok, 0}` instead of `{:ok, 1}`.
- **Fix:** Added `Fake.stub(:update_subscription, fn _id, _params, _opts -> {:ok, %{status: "unpaid"}} end)` before each sweeper call in the exhaustion tests.
- **Files modified:** accrue/test/accrue/dunning/dunning_full_journey_test.exs
- **Commit:** 00be396d

## Known Stubs

None. The test drives the real production path end-to-end with no stubs of Accrue's own code.

## Threat Surface Scan

Test-only change. No new network endpoints, auth paths, file access patterns, or schema changes. T-130-03 (false-green test) mitigated: all stages driven through `DefaultHandler.handle/1` (4 call sites in actual test code, grep-verified).

## Self-Check: PASSED

- `accrue/test/accrue/dunning/dunning_full_journey_test.exs` — exists (553 lines, > min_lines: 120)
- Contains `DefaultHandler.handle` — 4 actual code call sites (> 2 requirement)
- Contains `fire_payment_failed`, `fire_payment_succeeded`, `attach_telemetry`, `ledger_events`, `stub_invoice_fetch` — all present
- Contains label-mirror test with all 6 `provider_support_label/2` assertions — present
- No `@tag :slow`, `@tag :live_stripe`, `@tag :compile_matrix` in test code — only in `@moduledoc` comment
- No `Process.sleep` in test code — only in `@moduledoc` comment
- Task commit 00be396d — verified in git log
- `mix test accrue/test/accrue/dunning/dunning_full_journey_test.exs --seed 0` → 7 tests, 0 failures
- `mix test accrue/test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` → 6 tests, 0 failures (no regression)
