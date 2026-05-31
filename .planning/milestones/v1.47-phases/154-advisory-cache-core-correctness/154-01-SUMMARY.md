---
phase: 154-advisory-cache-core-correctness
plan: 01
subsystem: payments
tags: [entitlements, webhook, ecto, postgres, concurrency, telemetry]

requires:
  - phase: 153-close-v1-46-audit-trail-verification-md-for-phase-151-roadma
    provides: v1.46 closure and clean v1.47 starting point
provides:
  - Advisory entitlement cache upsert uses a DB-level monotonic watermark guard without Ecto optimistic locking
  - NULL incoming event watermarks can update existing summary rows instead of silently no-oping
  - DB-level stale writes return {:ok, :stale}, emit result: :unchanged telemetry, and skip ledger writes
  - Entitlement summary rows carry the webhook processor arg and preserve prior livemode when the payload omits livemode
affects: [phase-155, entitlement-summary-cache, webhook-default-handler]

tech-stack:
  added: []
  patterns: [ecto-upsert-conflict-query, db-level-stale-branch, telemetry-unchanged-on-stale]

key-files:
  created:
    - .planning/phases/154-advisory-cache-core-correctness/154-01-SUMMARY.md
  modified:
    - accrue/lib/accrue/billing/entitlement_summary.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs
    - accrue/test/accrue/webhook/wr05_concurrency_test.exs

key-decisions:
  - "Use an Ecto conflict query for ON CONFLICT DO UPDATE ... WHERE instead of relying on an ignored on_conflict_where option."
  - "Treat equal timestamp entitlement summary writes as DB-level stale writes: they pass the pre-check but do not replace the row."
  - "Keep the lock_version column in the schema, but remove it from webhook-path casting and remove optimistic_lock from force_changeset/2."

patterns-established:
  - "Entitlement summary stale writes return {:ok, :stale} and emit result: :unchanged telemetry before any ledger write."
  - "Webhook advisory cache fields should derive from the event processor arg and previous row state, not global processor config."

requirements-completed: [ADV-01, ADV-02, ADV-03, ADV-04, POL-01, POL-02]

duration: 20min
completed: 2026-05-31
---

# Phase 154 Plan 01: Advisory Cache Core Correctness Summary

**Advisory entitlement cache writes now use a DB-level monotonic upsert guard with stale handling, accurate processor attribution, and livemode carry-forward.**

## Performance

- **Duration:** 20 min resumed recovery session
- **Started:** 2026-05-31T13:38:00Z
- **Completed:** 2026-05-31T13:57:42Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Removed `optimistic_lock(:lock_version)` from `EntitlementSummary.force_changeset/2` and excluded `lock_version` from the webhook cast fields.
- Replaced the entitlement summary upsert with an Ecto conflict query that generates a NULL-safe `ON CONFLICT DO UPDATE ... WHERE` watermark guard.
- Added the stale branch so DB-rejected writes return `{:ok, :stale}`, emit `result: :unchanged`, and do not call `maybe_record_summary_event/3`.
- Threaded the webhook `processor` arg into `write_entitlement_summary/9` and preserved prior `livemode` when the event object omits the key.
- Reconciled the existing equal-timestamp test with the new DB-gate contract: equal timestamps pass the pre-check, then return stale at the atomic upsert.

## Task Commits

1. **Task 1 and Task 2 recovery: tests plus production fixes** - `443f3035` (`fix(154-01): correct advisory cache write path`)

## Files Created/Modified

- `accrue/lib/accrue/billing/entitlement_summary.ex` - Removes OCC from the webhook-path changeset while keeping the schema column.
- `accrue/lib/accrue/webhook/default_handler.ex` - Adds processor threading, livemode carry-forward, NULL-safe conflict update, and stale telemetry handling.
- `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` - Covers equal timestamp stale behavior and Phase 154 advisory-cache regressions.
- `accrue/test/accrue/webhook/wr05_concurrency_test.exs` - Contains the explicit `Sandbox.allow/3` concurrent delivery coverage required by ADV-04.

## Decisions Made

- Equal timestamp writes are now treated as stale at the DB gate. This preserves monotonicity and prevents duplicate same-watermark writes from replacing the row or writing another ledger event.
- The upsert guard lives inside the `on_conflict:` query because the previous separate `on_conflict_where` path was not generating the intended guarded update.
- `lock_version` remains in the database schema for compatibility, but the advisory cache write path no longer participates in optimistic locking.

## Deviations from Plan

### Auto-fixed Issues

**1. Legacy equal-timestamp test expectation updated**
- **Found during:** Targeted verification
- **Issue:** The existing tie test expected equal timestamps to update the row, conflicting with ADV-03's DB-level stale requirement.
- **Fix:** Updated the test to assert `{:ok, :stale}` and verify the original row watermark remains unchanged.
- **Files modified:** `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs`
- **Verification:** Targeted phase tests and full suite pass.
- **Committed in:** `443f3035`

---

**Total deviations:** 1 auto-fixed test expectation update.
**Impact on plan:** Aligns the older contract with the phase's monotonic DB-gate behavior.

## Issues Encountered

- Terminal crash left production edits without a summary. Recovery inspected the worktree, completed verification, committed the scoped code/test changes, and created this summary.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd accrue && mix compile --warnings-as-errors` - passed
- `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs --seed 0` - 17 tests, 0 failures
- `cd accrue && mix test --seed 0` - 58 properties, 1640 tests, 0 failures, 11 excluded

## Next Phase Readiness

Phase 154 is complete. Phase 155 can build on the corrected advisory cache write path and add fixture/telemetry polish without carrying the OCC, NULL watermark, stale branch, processor, or livemode correctness risks forward.

---
*Phase: 154-advisory-cache-core-correctness*
*Completed: 2026-05-31*
