---
phase: 113-cancellation-semantics-closure
plan: 01
subsystem: payments
tags: [cancellation, braintree, capabilities, billing, tests]
requires:
  - phase: 112-customer-update-contract-closure
    provides: customer-update support-truth pattern for runtime labels, planning mirrors, and deterministic proof
provides:
  - immediate-cancel support rows promoted to all first-party in runtime and planning mirrors
  - Braintree scheduled-end cancellation rejection with actionable next-step guidance
  - deterministic facade and adapter proof for immediate-vs-scheduled cancellation boundaries
affects: [113-02, 113-03, processor-support-matrix, billing facade semantics]
tech-stack:
  added: []
  patterns: [runtime/planning co-updates for support truth, typed unsupported lifecycle errors with next-step hints]
key-files:
  created: [.planning/phases/113-cancellation-semantics-closure/113-01-SUMMARY.md]
  modified:
    - accrue/lib/accrue/processor/capabilities.ex
    - .planning/processor-support-matrix.md
    - accrue/test/accrue/processor/capabilities_test.exs
    - accrue/lib/accrue/billing/subscription_actions.ex
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/test/accrue/billing/subscription_cancel_test.exs
    - accrue/test/accrue/processor/braintree_test.exs
key-decisions:
  - "Promote only immediate cancellation (`cancel` / `cancel_immediately`) to all first-party and keep `cancel_at_period_end` explicitly split."
  - "Reject Braintree scheduled-end cancellation payloads instead of degrading them into immediate cancellation."
patterns-established:
  - "Capability labels and `.planning/processor-support-matrix.md` move together in the same task."
  - "Unsupported Braintree lifecycle branches return typed errors with one concrete next step."
requirements-completed: [PROC-22, PROC-23]
duration: 5min
completed: 2026-05-07
---

# Phase 113 Plan 01: Cancellation Semantics Closure Summary

**Immediate cancellation is now first-party across Fake, Stripe, and Braintree, while Braintree scheduled-end cancellation stays explicitly unsupported and action-guided.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-07T10:23:30Z
- **Completed:** 2026-05-07T10:28:58Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Promoted `subscription.cancel` and `subscription.cancel_immediately` to `all first-party` in runtime labels and the planning support matrix.
- Kept `subscription.cancel_at_period_end` explicitly split so Braintree does not get overstated as supporting scheduled-end cancellation.
- Added merge-blocking proof that the public facade and Braintree adapter preserve immediate cancel support while rejecting scheduled-end and reversal branches with actionable guidance.

## Task Commits

1. **Task 1: Promote the immediate-cancel support rows and keep scheduled-end truth explicitly split** - `1c55f1e` (feat)
2. **Task 2: Lock the promoted contract behind facade and adapter proof** - `fca2dff` (fix)

## Files Created/Modified

- `accrue/lib/accrue/processor/capabilities.ex` - promotes the immediate-cancel support labels to `all first-party`
- `.planning/processor-support-matrix.md` - mirrors the same immediate-vs-scheduled cancellation truth for maintainers
- `accrue/test/accrue/processor/capabilities_test.exs` - pins the promoted rows and the preserved split row
- `accrue/lib/accrue/billing/subscription_actions.ex` - adds an actionable Braintree resume next step
- `accrue/lib/accrue/processor/braintree.ex` - rejects scheduled-end cancel payloads and returns actionable unsupported guidance
- `accrue/test/accrue/billing/subscription_cancel_test.exs` - proves facade-level immediate-vs-scheduled distinction, including Braintree rejection
- `accrue/test/accrue/processor/braintree_test.exs` - proves adapter-level immediate support and scheduled-end rejection

## Decisions Made

- Promoted only the shipped immediate-cancel rows. `cancel_at_period_end` remains intentionally staged because Braintree truth is still `false`.
- Treated silent degradation of `cancel_at_period_end` payloads into immediate cancellation as a correctness bug and fixed it in the adapter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rejected scheduled-end Braintree cancel payloads instead of silently canceling immediately**
- **Found during:** Task 2 (Lock the promoted contract behind facade and adapter proof)
- **Issue:** `Accrue.Processor.Braintree.cancel_subscription/3` accepted `cancel_at_period_end` and `cancel_at` payloads, then executed an immediate cancel instead of returning typed unsupported semantics.
- **Fix:** Extended `validate_cancel_params/1` to reject scheduled-end payloads and added adapter + facade tests for the boundary.
- **Files modified:** `accrue/lib/accrue/processor/braintree.ex`, `accrue/test/accrue/processor/braintree_test.exs`, `accrue/test/accrue/billing/subscription_cancel_test.exs`
- **Verification:** `cd accrue && mix test test/accrue/billing/subscription_cancel_test.exs test/accrue/processor/braintree_test.exs`
- **Committed in:** `fca2dff`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Required for correctness. The fix stayed inside the planned facade/adapter proof slice and did not widen scope.

## Issues Encountered

- The executor instructions referenced `gsd-sdk query` state helpers, but this environment only exposes the base `gsd-sdk` commands. Planning artifacts were updated manually.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `113-02-PLAN.md` can now align docs and touched UX to the finalized immediate-vs-scheduled cancellation contract.
- `113-03-PLAN.md` can add any remaining drift gates on top of the runtime truth established here.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/113-cancellation-semantics-closure/113-01-SUMMARY.md`
- Verified task commits exist: `1c55f1e`, `fca2dff`
