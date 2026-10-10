---
phase: 242-investigations-and-remaining-admin-surfaces
plan: 02
subsystem: ui
tags: [phoenix-liveview, webhooks, replay, owner-scope, oban]
requires:
  - phase: 242-01
    provides: ScopedPath return validation and webhook filter contract
provides:
  - Bulk replay bound to unique reviewed IDs with authoritative outcome accounting
  - Single delivery detail with validated contextual return and truthful enqueue state
affects: [242-07, webhook-operations, admin-investigation]
actuals:
  tokens: 9452
  tasks: 2
  commits: 2
  plan_head_before: c88f8ebdf9d3ff51f252e532396f00eaa7ddd888
  plan_head_after: a1e303a16efa0dc528de8e1a07d90897be4ea627
tech-stack:
  added: []
  patterns:
    - Test-only read seam to distinguish pre-dispatch reads from post-acceptance evidence refresh
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
key-decisions:
  - "Keep Copy.Locked unchanged and describe replay as accepted queueing, not completed processing."
  - "Rebuild contextual webhook return paths inside the active mount and owner scope."
metrics:
  duration: 8min
  completed: 2026-10-10
status: complete
requirements-completed: [JRN-05, UXC-01]
human_judgment: false
coverage:
  - id: D1
    description: Bulk replay confirmation preserves the reviewed unique delivery set and records observed queued, skipped, denied, failed, and unknown outcomes.
    requirement: JRN-05
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/webhook_replay_test.exs (25 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: Single delivery detail presents diagnostic evidence and validated scoped return; replay denial/dismissal do not act, while accepted enqueue stays distinct from unavailable follow-up evidence.
    requirement: UXC-01
    verification:
      - kind: automated_ui
        ref: "MIX_ENV=test mix test test/accrue_admin/live/webhook_live_test.exs (18 tests, 0 failures)"
        status: pass
    human_judgment: false
---

# Phase 242 Plan 02: Webhook Delivery Review Summary

**Bulk and single webhook replay now bind confirmation to current scoped delivery facts and report observed enqueue outcomes without implying processing success.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-10T12:48:50Z
- **Completed:** 2026-10-10T12:56:50Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Bulk replay review captures unique selected IDs, current owner scope and eligibility, then refuses changed selection or material-state drift. Each selected delivery receives one observed outcome and completion accounting reconciles the selected population.
- Single delivery detail shows delivery identity, current status, processor event ID, livemode, attempt count and recorded failure context before raw payload expansion. Its return link validates the supplied family destination and reapplies current owner scope; direct entry falls back to the scoped webhook list.
- Replay tests verify authoritative DLQ/domain status, dispatch jobs and audit events. Accepted enqueue remains queued when the subsequent evidence refresh fails, with explicit unavailable-state copy.

## Task Commits

1. **Task 1: Bind bulk replay to the reviewed delivery set and actual outcomes** - `a03a1ee5` (fix)
2. **Task 2: Preserve single-delivery evidence and review safety** - `a1e303a1` (feat)

**Plan metadata:** execution summary and sequential planning-state updates are committed separately.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex` - canonical reviewed selection, eligibility and actual bulk outcome reporting.
- `accrue_admin/lib/accrue_admin/copy.ex` - replay consequence and outcome descriptions.
- `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` - reviewed-set and outcome assertions.
- `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` - authoritative replay state, dispatch and audit assertions.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` - detailed delivery evidence, scoped return and unavailable reread handling.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - detail, no-action and accepted-enqueue evidence assertions.

## Decisions Made

- Kept locked copy byte-for-byte unchanged; replay copy reports an accepted queue request, not processing completion.
- Used the existing `ScopedPath.return_destination/5` contract to rebuild family-specific return paths within the active mount and owner scope. No claim is made that a structured link helper was wired by this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Treat a failed fresh pre-dispatch detail read as unavailable**
- **Found during:** Task 2 (single delivery review)
- **Issue:** A database connection failure in the fresh detail read before dispatch could escape the LiveView event instead of safely preventing replay.
- **Fix:** Convert connection read failures into an unavailable result and show that no replay was queued; retain the accepted result if only the later evidence refresh fails.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`
- **Verification:** 18 tests passed, including an injected post-acceptance read failure and authoritative job/audit checks.
- **Committed in:** `a1e303a1`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Prevents an unavailable ownership/eligibility read from crashing or dispatching and preserves truthful accepted-enqueue reporting.

## Issues Encountered

- Initial tests exposed a scope mismatch in the contextual-return fixture and a read-failure injection point that ran before dispatch. Fixtures now use an owned delivery and target the post-acceptance refresh. Final task runs are green: 25 tests and 18 tests, respectively.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 07 owns the bounded phase-wide mounted/visual inspection. This plan did not capture browser screenshots or claim responsive/keyboard inspection. Existing ScopedPath return validation was exercised, but no key-link helper wiring proof is claimed.

---
*Phase: 242-investigations-and-remaining-admin-surfaces*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Both task commits are present and are ancestors of the recorded plan head.
- All six declared modified files exist; the canonical summary is written at the required phase path.
- The plan ledger measures 2 task commits between `plan_head_before` and `plan_head_after`.
