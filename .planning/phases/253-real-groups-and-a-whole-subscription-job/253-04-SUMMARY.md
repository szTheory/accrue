---
phase: 253-real-groups-and-a-whole-subscription-job
plan: "04"
subsystem: billing
tags: [subscriptions, liveview, authorization, step-up, scoped-path]

# Dependency graph
requires:
  - phase: 253-02
    provides: Production subscription list and scoped row navigation
  - phase: 253-03
    provides: Settled subscription detail and action review presentation
provides:
  - A mounted list-to-detail cancellation journey with exact dispatch, persistence, audit, and return assertions
  - Adversarial coverage for stale authority, dismissed continuations, step-up, and untrusted return origins
affects: [subscriptions, phase-253-05]

# Measured from the persisted plan ledger at summary authoring time.
commits: 3
plan_head_before: 78823d73395a69091dfedef757ee8b8d044c3dc9
plan_head_after: 85ad12c1290f5210469277fc9c63de8a2bcfae70

# Actuals (#2632), same chars/4 scale as the estimate.
actuals:
  tokens: 8229
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Snapshot Processor.Fake calls, TestRepo state, and Events around every denied or dismissed action
    - Exercise real LiveView routes and rendered links as journey evidence

key-files:
  created:
    - accrue_admin/test/accrue_admin/live/subscription_journey_test.exs
  modified:
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex

key-decisions:
  - Reuse the existing LiveView routes, Auth adapter seam, Processor.Fake, TestRepo, and event ledger; static story snapshots are not execution evidence.
  - Preserve the authenticated active organization in the missing-detail denial redirect when the initial static mount has no query params.

requirements-completed: [SBK-06, UXQ-03]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: The operator follows the rendered scoped list link, reviews cancel_now, dismisses review and step-up without effects, dispatches once, and returns with filters.
    requirement: SBK-06
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscription_journey_test.exs#scoped list to reviewed cancellation returns with filters after two inert dismissals; full command: mix test test/accrue_admin/live/subscription_journey_test.exs test/accrue_admin/live/subscription_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Changed actor, owner, lifecycle, processor target, invalid or expired step-up, reload, and dismissal controls do not authorize unintended effects.
    requirement: SBK-06
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscription_live_test.exs#authority, stale-review, step-up, and no-replay controls; full mounted suite: 46 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: Untrusted return origins retain only allowed scoped filters, and markup-like customer/subscription evidence renders escaped while remaining complete text.
    requirement: UXQ-03
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscription_live_test.exs#untrusted return origins preserve only allowed filters inside current organization scope; active lifecycle remains active when price and period observations are unavailable"
        status: pass
    human_judgment: false

# Metrics
duration: 22min
completed: 2026-10-27
status: complete
---

# Phase 253 Plan 04: Real Subscription Job Verification Summary

**A real scoped subscription journey now proves inert dismissal, one authorized cancellation, truthful audit/state, and a validated return path.**

## Performance

- **Duration:** 22m 8s
- **Started:** 2026-10-27T18:27:46Z
- **Completed:** 2026-10-27T18:49:54Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added a production-mounted list-to-detail cancellation journey that follows the rendered row link, preserves filters and scope, proves both dismissals have zero effects, authorizes one exact-target dispatch, and returns through the rendered link.
- Strengthened action controls with exact `Processor.Fake` call snapshots, persisted state, domain events, and admin audit assertions for stale reviews, invalid step-up, reload, dismissal, and provider rejection.
- Covered hostile return origins, encoded scoped filters, and escaped long markup-like subscription/customer evidence.

## Task Commits

1. **Task 1: Complete the scoped list, review, dismissal, confirmation and return journey** - `b05ee2128` (`test`)
2. **Task 2: Reject stale authority and unsafe returns while preserving truthful recovery** - `da91d1317` (`test`)

## Files Created/Modified

- `accrue_admin/test/accrue_admin/live/subscription_journey_test.exs` - End-to-end mounted operator job and exact-effect checks.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - Authority, return-origin, escaping, and recovery assertions.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - Keeps an authorized active organization on the missing-detail denial path.

## Decisions Made

- Kept action policy and dispatch ownership in `SubscriptionLive`; tests use its existing route and adapter seams.
- Session organization data may scope a denial redirect only when the current admin is a platform admin or belongs to that organization. The redirect never trusts an origin supplied by the URL.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve authorized organization scope on an initial missing-detail redirect**
- **Found during:** Task 2
- **Issue:** Phoenix's initial static mount supplied the subscription ID without query params, so the missing-record denial fell back to the global subscriptions path despite an authorized active organization in the session.
- **Fix:** Use the session's active organization slug for this denial only after confirming platform-admin status or organization membership; assert the scoped destination and denial copy.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex`, `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`
- **Verification:** Full disposable admin suite, 46 tests, 0 failures.
- **Committed in:** `85ad12c12`

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Restored the planned scoped denial behavior without changing action policy or trusting a return origin.

## Issues Encountered

None remaining.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 253-05 can build on executable route, authority, side-effect, and return-path evidence. The full mounted journey/detail suite passed in the disposable admin test lane.

---
*Phase: 253-real-groups-and-a-whole-subscription-job*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `b05ee2128`, `da91d1317`, and the Rule 1 fix `85ad12c12` are ancestors of HEAD.
- Coverage metadata contains passing executable verification entries with `human_judgment: false`.
