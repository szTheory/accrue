---
phase: 242-investigations-and-remaining-admin-surfaces
plan: 04
subsystem: ui
tags: [phoenix-liveview, stripe-connect, fee-review, scoped-path]
requires:
  - phase: 242-01
    provides: Validated ScopedPath returns and Connect filter normalization
provides:
  - Connect account detail links return to the validated filtered list and selected lens
  - Fee reviews expose account, owner, current policy, proposed policy, default, and exact domain preview
  - Fee saves reject stale policy, retain StepUp and optimistic locking, and avoid duplicate policy writes
  - Copy distinguishes last stored Stripe observations from local fee policy
affects: [connect-account-operations, phase-242-verification]
actuals:
  tokens: 6659
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 64ebd0055ab95ee0259ec3de5343f0a4727b8980
plan_head_after: db47cdf9bc51a322706c04cb3b87896e3652c4ad
tech-stack:
  added: []
  patterns:
    - Rebuild Connect list returns through the current mount and owner scope
    - Compare local fee policy and default against the reviewed snapshot before saving
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
    - accrue_admin/lib/accrue_admin/copy/connect.ex
    - accrue_admin/test/accrue_admin/copy/connect_test.exs
key-decisions:
  - "Preserve only validated Connect filters and the current all/needs-attention lens when returning from account detail."
  - "Treat readiness, capabilities, and requirements as the last stored Stripe snapshot without claiming a report timestamp; fee overrides remain local Accrue policy."
  - "A fee save proceeds only when the scoped account, owner, current override, and default policy still match review; an identical policy is an audited-step-up no-op."
requirements-completed: [JRN-06]
coverage:
  - id: D1
    description: Connect account detail returns preserve the real q/type/readiness filters and the selected all-accounts lens.
    requirement: JRN-06
    verification:
      - kind: integration
        ref: "cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs — 23 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: Fee review and persistence use exact local policy values and the domain preview, including min/max clamps; invalid, stale, denied, repeated, and dismissed attempts do not change fee policy or create a fee-update audit row.
    requirement: JRN-06
    verification:
      - kind: integration
        ref: "cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs — 23 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: Connect Copy identifies stored snapshot timing limits, separates local policy from Stripe capabilities, and distinguishes unset, zero, and unavailable policy states.
    requirement: JRN-06
    verification:
      - kind: unit
        ref: "cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy/connect_test.exs — 4 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 8 min
completed: 2026-10-10
status: complete
human_judgment: false
---

# Phase 242 Plan 04: Connect Accounts and Fee Review Summary

**Connect account navigation preserves validated list context, while local fee reviews show exact consequences and reject stale or duplicate policy changes.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-10T13:14:00Z
- **Completed:** 2026-10-10T13:22:22Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Connect account links retain the selected lens and supported filters in a validated `return_to`; detail returns rebuild within the current mount and owner scope.
- The fee review identifies the exact account and owner, current override, proposed override or global-default consequence, configured default, and a preview computed by `Accrue.Connect.platform_fee/2`.
- Save rereads the scoped account and checks owner, Stripe account identity, current override, and default policy against the review. Material drift is rejected. Optimistic-lock races become stale-review feedback, and an already matching override does not write policy or a duplicate fee-update event.
- Stripe readiness, capabilities, requirements, and report-time absence remain separate from local fee policy. Explicit zero, unset override, and unavailable default are distinct.

## Task Commits

1. **Task 1: Preserve Connect list context and exact account review** — `1eaa768d` (`feat`)
2. **Task 2: State Connect observation and fee limits through Copy** — `7eeb4173` (`test`)
3. **Task 1: Add min/max fee clamp acceptance** — `db47cdf9` (`test`)

## Verification Results

- Task 1 command: `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs` — **23 tests, 0 failures**.
- Task 2 command: `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy/connect_test.exs` — **4 tests, 0 failures**.
- The LiveView assertions cover actual filtered row membership and decoded return filters; the fee flow checks exact persisted values, domain rounding and min/max preview clamps, StepUp success/denial/dismissal, invalid input, stale policy, and duplicate confirmation.
- The view is exercised through mounted Phoenix LiveView integration tests. No separate browser/host visual inspection was run; the phase-wide visual review is owned by Plan 242-07. No assets changed. Stripe provider state remains explicitly described as a stored observation with no tracked report timestamp.

## Decisions Made

- Rebuilt the back destination through `ScopedPath` and the current authenticated mount/scope; only the Connect query contract and lens survive.
- Kept Stripe snapshot facts separate from Accrue's locally persisted fee override and used the existing domain calculation for preview.
- Reused the account optimistic lock and StepUp boundary. Equal policy values are a no-op, and stale review does not create a fee-update audit event.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Handle optimistic-lock races after fee-review reread**
- **Found during:** Task 1
- **Issue:** A concurrent update between the fresh account read and write can raise `Ecto.StaleEntryError` after the review comparison.
- **Fix:** Convert the lock race into stale-review feedback and refresh the displayed account when it remains in scope.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/connect_account_live.ex`
- **Verification:** The focused LiveView suite passes and verifies material policy drift preserves policy and omits the fee-update event. The lock-race exception branch was not separately fault-injected.
- **Committed in:** `1eaa768d`

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Completes the planned stale-review boundary without changing the data model, dependencies, or provider behavior. The deviation ledger entry is recorded as fixed.

## Issues Encountered

None remaining.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 242-06 and Plan 242-07 remain. JRN-06 is shared with later phase work and is not marked complete in REQUIREMENTS.md until its remaining declaring plan is summarized.

## Self-Check: PASSED

- All six declared product and test files exist.
- All three task commits are ancestors of the plan tip recorded above; the measured plan commit count is three.
- Both task acceptance commands passed with nonzero test totals.
- No tracked files were deleted by the task commits.

---
*Phase: 242-investigations-and-remaining-admin-surfaces*
*Completed: 2026-10-10*
