---
phase: 234-admin-customers-subscriptions
plan: "04"
subsystem: payments
tags: [phoenix-liveview, subscription-actions, owner-scope, step-up]
requires:
  - phase: 234-03
    provides: Subscription detail hierarchy and lifecycle presentation.
  - phase: 234-07
    provides: Record-aware ScopedPath behavior preserved in the shared subscription LiveView.
provides:
  - Lifecycle and provider-aware subscription action visibility and staging.
  - Consequence copy for action, timing, quantity, proration, preview availability, and replacement creation.
  - Fresh session-derived owner scope, target, item, eligibility, and review-fingerprint checks before dispatch.
affects: [234-05, 234-06, subscription-actions, step-up]
actuals:
  tokens: 5791
  tasks: 2
  commits: 3
  plan_head_before: b7588712acfef1f1335b78e882b852f59297fff1
  plan_head_after: 26edbe7aad9fac9bea217a135556bcab5bcf0893
commits: 3
plan_head_before: b7588712acfef1f1335b78e882b852f59297fff1
plan_head_after: 26edbe7aad9fac9bea217a135556bcab5bcf0893
tech-stack:
  added: []
  patterns:
    - Action visibility and dispatch use the same local mapping over core lifecycle predicates and provider limits.
    - Delayed actions bind a canonical material review fingerprint and re-read the owner-scoped record inside the step-up continuation.
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
key-decisions:
  - "Collection unpause is offered only for paused subscriptions; cancellation resume is offered only while the subscription is currently canceling."
  - "The host session and owner-scoped local query remain authorization authority; no new Admin role or public billing eligibility API was introduced."
patterns-established:
  - "Pin actor, owner scope, target identity, supported action input, lifecycle/provider eligibility, and material reviewed facts before dispatch."
  - "Treat changed item membership or quantity as review drift while ignoring unrelated metadata changes."
requirements-completed: [ADM-04, SAFE-01]
coverage:
  - id: D1
    description: Eligible subscription actions are visible and reviewed with precise consequence and timing details.
    requirement: ADM-04
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Scope, lifecycle, and item drift after review or step-up prevents Billing dispatch, while unrelated metadata does not invalidate review.
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/step_up_test.exs"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-10-08
status: complete
---

# Phase 234 Plan 04: Subscription Action Eligibility and Fresh Review Summary

**Subscription controls now follow current provider and lifecycle eligibility, and every confirmed action is revalidated against fresh owner-scoped state.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-08T01:25:32Z
- **Completed:** 2026-10-08T01:31:26Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Hid unavailable actions for terminated, paused, non-canceling, unsupported-provider, and multi-item states; retained supported Fake and Stripe collection behavior and configured Braintree plan swaps.
- Added review copy for actual action, cancellation timing, quantity, item, proration, preview availability, and replacement creation.
- Revalidated host actor, owner scope, target, action eligibility, item membership, and material subscription facts before dispatch and again inside delayed step-up continuation.
- Added mounted tests for terminated controls, post-challenge lifecycle drift, changed item quantity, and harmless metadata updates.

## Task Commits

1. **Task 1 test: Cover lifecycle-ineligible subscription actions** — `b4de4d33` (test)
2. **Task 1 implementation: Gate subscription actions on current eligibility** — `457f481e` (feat)
3. **Task 2 regression tests: Cover reviewed action drift after step-up** — `26edbe7a` (test)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — local action eligibility, consequence copy, fresh owner-scoped revalidation, and material review fingerprints.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — lifecycle/provider controls, forged events, delayed drift, and positive step-up behavior.

## Decisions Made

- Pause and resume are separate collection/cancellation semantics. Resume is available only for a paused subscription or an active scheduled cancellation.
- A material change clears the old review and prompts a new review; unrelated metadata does not.
- The saved host session and scoped query remain the authorization boundary. The implementation makes no remote-fetch or remote/database atomicity claim.

## Deviations from Plan

### Process deviation

**1. Task 2's delayed review tests were committed after the overlapping fresh-dispatch implementation, so Task 2 has no separate RED commit.**
- **Found during:** Task 2
- **Issue:** Both tasks modify the same LiveView boundary, and the revalidation path was completed with the eligibility implementation before the delayed-drift tests were added.
- **Fix:** Added mounted lifecycle-drift, item-drift, and unrelated-metadata controls, then ran both required suites successfully.
- **Files modified:** `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`
- **Verification:** 29 tests, 0 failures across the named subscription and step-up suites.
- **Recorded in:** `.planning/WINDOWS.md` entry 17.

**2. The Phase 234 roadmap entry could not be updated by the registered progress command.**
- **Found during:** State updates
- **Issue:** `roadmap.update-plan-progress 234` returned `missing_phase_details`; the current roadmap has only an aggregate phase checklist entry and no writable per-plan progress region.
- **Resolution:** Preserved the roadmap file and recorded the updater limitation in `.planning/WINDOWS.md` entry 18. The completed plan is reflected in STATE.md, this summary, and REQUIREMENTS.md.

**Total deviations:** 2 (1 process deviation and 1 roadmap updater limitation).
**Impact on plan:** All product behaviors are implemented and verified; the roadmap progress row remains unchanged until the roadmap contains a per-plan update target.

## Issues Encountered

- The existing action hierarchy test expected Resume for an ordinary active subscription. Eligibility now follows core predicates, so the assertion was updated to expect Resume only for a paused or canceling subscription.
- `.planning/config.json` and `.planning/milestone.lock` were pre-existing user changes and were preserved.
- `roadmap.update-plan-progress 234` reported `missing_phase_details`; ROADMAP.md was left unchanged because the updater found no writable per-plan entry.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/step_up_test.exs` — **29 tests, 0 failures**.
- `git diff --check` — passed.
- Changed Elixir files passed `mix format`.

## User Setup Required

None.

## Next Phase Readiness

The subscription action path now has a consistent local eligibility map and a reviewed mutation boundary. Later customer/subscription work can rely on these controls while preserving Plan 234-07's record-aware `ScopedPath` behavior.

---
*Phase: 234-admin-customers-subscriptions*
*Completed: 2026-10-08*

## Self-Check: PASSED

- Summary, implementation, and mounted test files exist.
- Task commits `b4de4d33`, `457f481e`, and `26edbe7a` are ancestors of HEAD.
- The persisted plan ledger measures 3 task commits from `b7588712acfef1f1335b78e882b852f59297fff1` through `26edbe7aad9fac9bea217a135556bcab5bcf0893`.
