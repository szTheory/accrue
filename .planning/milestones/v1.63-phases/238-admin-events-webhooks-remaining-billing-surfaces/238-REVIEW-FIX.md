---
phase: 238-admin-events-webhooks-remaining-billing-surfaces
fixed_at: 2026-10-09T04:56:36Z
review_path: .planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-REVIEW.md
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 238: Code Review Fix Report

**Fixed at:** 2026-10-09T04:56:36Z  
**Source review:** `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-REVIEW.md`  
**Iteration:** 2

**Summary:**
- Iteration 2 findings addressed: 4 (the three post-fix review findings plus one additional replay-scope issue found during re-review)
- Fixed: 4
- Skipped: 0

## Iteration 1: Initial Fixes

### CR-01: Concurrent replay requests can queue the same webhook more than once

**Files modified:** `accrue/lib/accrue/webhooks/dlq.ex`, `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs`  
**Commit:** `8e11fcaa`  
**Status:** fixed  
**Applied fix:** Claim a replay transactionally under a row lock, conditionally update only replayable rows, and enforce active-job uniqueness by webhook event ID. Added a repeated-replay regression test.

### WR-01: An exception during one bulk row aborts the batch before outcomes are audited

**Files modified:** `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`, `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs`  
**Commit:** `43699c61`  
**Status:** fixed  
**Applied fix:** Isolate each bulk replay row so lookup or enqueue exceptions become audited failed outcomes while processing continues. Extended the mid-batch regression test with an enqueue exception.

### WR-02: Periodic polling bypasses the new recoverable read-error handling

**Files modified:** `accrue_admin/lib/accrue_admin/components/data_table.ex`, `accrue_admin/test/accrue_admin/components/data_table_test.exs`  
**Commit:** `fd245c86`  
**Status:** fixed  
**Applied fix:** Preserve existing rows and expose an alert with an explicit retry check when polling count reads fail; verify a later poll recovers.

### WR-03: Connect false-value filters classify missing provider observations as disabled

**Files modified:** `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex`, `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex`, `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs`  
**Commit:** `874b8de3`  
**Status:** fixed  
**Applied fix:** Drive Connect filters and readiness summaries from observed snapshot booleans, keep missing observations unknown, and test behavior against contradictory legacy columns.

### WR-04: Connect readiness presents old provider facts as current

**Files modified:** `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex`, `accrue_admin/lib/accrue_admin/live/connect_account_live.ex`, `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs`, `accrue_admin/test/accrue_admin/live/connect_account_live_test.exs`  
**Commit:** `0d834287`  
**Status:** fixed  
**Applied fix:** Label readiness as the last stored Stripe snapshot and explain that observation time is not tracked. Added LiveView assertions for the snapshot wording.

### WR-05: Organization-scoped replay audit events are absent from the event feed and their links fail

**Files modified:** `accrue_admin/lib/accrue_admin/queries/events.ex`, `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`  
**Commit:** `566d7959`  
**Status:** fixed  
**Applied fix:** Include replay and batch audit rows in organization event feeds only when webhook scope is proven; test allowed and denied events, mixed-scope batches, and links.

## Iteration 1 Verification

All focused checks ran in the main checkout because `workflow.use_worktrees` is `false`. The GSD reviewer completed a second standard-depth review of the original 24-file scope and confirmed the six findings were resolved with no remaining Critical or Warning findings.

- `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs` — 9 tests, 0 failures (run after CR-01 and WR-01).
- `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs` — 30 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs` — 10 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs` — 17 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` — 40 tests, 0 failures.
- `mix format` was run on the targeted Elixir files; `git diff --check` passed before each fix commit.
- The full test suite was not run.
- Iteration 2's focused regression tests and full Admin suite subsequently covered these logic fixes, so their final status is recorded as fixed without a human verification handoff.

---

_Fixed: 2026-10-09T04:41:21Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_

## Iteration 2: Post-fix Review Findings

### CR-01: Bulk replay did not atomically revalidate organization ownership

**Files modified:** `accrue/lib/accrue/webhooks/dlq.ex`, `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`, `accrue_admin/lib/accrue_admin/queries/webhooks.ex`, `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs`  
**Commit:** `16aab2eb`  
**Status:** fixed  
**Applied fix:** Added a DLQ authorization callback that runs inside the locked claim transaction. The organization proof locks the current billing and event ownership rows until the claim commits. Out-of-scope rows are skipped without recording their IDs. Added an ownership-transfer regression test between preflight and claim.

### WR-01: Unknown or missing coupon currency displayed as USD

**Files modified:** `accrue_admin/lib/accrue_admin/live/coupon_live.ex`, `accrue_admin/test/accrue_admin/live/coupon_live_test.exs`  
**Commit:** `7540ef07`  
**Status:** fixed  
**Applied fix:** Validate currency codes and display unavailable copy for unsupported, missing, or unknown currencies. Added tests for unsupported and missing values.

### WR-02: Connect query tests used stale legacy-only readiness fixtures

**Files modified:** `accrue_admin/test/accrue_admin/queries/query_modules_test.exs`  
**Commit:** `c85e2bc1`  
**Status:** fixed  
**Applied fix:** Populated Connect fixture snapshots in `data` and added assertions that missing observations match neither explicit boolean filter while remaining in the needs-attention lens.

### CR-02: Single replay also needed an atomic organization ownership check

**Files modified:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`  
**Commit:** `b2ee710b`  
**Status:** fixed  
**Applied fix:** Passed the active owner scope into the same DLQ claim authorization path for single replay. Added a deterministic ownership-transfer test after detail preflight and before claim.

## Iteration 2 Verification

All checks ran in the main checkout because `workflow.use_worktrees` is `false`.

- `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs` — 10 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/coupon_live_test.exs` — 12 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/queries/query_modules_test.exs` — 23 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs` — 15 tests, 0 failures.
- `cd accrue_admin && mix test --warnings-as-errors` — 610 tests, 0 failures.
- Targeted Elixir files were formatted, and `git diff --check` passed.
- Final standard-depth review of the original 24-file scope found no remaining Critical, Warning, or Info findings.

---

_Fixed: 2026-10-09T04:56:36Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 2_
