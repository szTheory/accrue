---
phase: 241-billing-operator-journeys
plan: "05"
subsystem: billing-ui
tags: [phoenix-liveview, subscription-actions, review, exact-money]

requires:
  - phase: 240
    provides: Subscription action ownership, scope checks, step-up and overlay patterns
  - phase: 241-03
    provides: Validated subscription return context and current owner scope
provides:
  - Self-contained, evidence-limited review facts for every eligible subscription action
  - Clear Resume subscription and Back to subscription copy
  - Explicit pending confirmation disabled/loading treatment and route safety assertions
affects: [241-06, 241-07]

actuals:
  tokens: 9745
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 0a9f52cf0898b5ce1ca6ce04966411b07f4261c5
plan_head_after: 55833ee6d1f3ccf15642e92ec6485d0743ebb825

tech-stack:
  added: []
  patterns:
    - Subscription reviews show exact record identity, owner context, current lifecycle state and selected target together.
    - Unobserved subscription charges and unavailable previews stay explicitly unavailable without estimate or zero defaults.
    - Existing owner-scope, capability, fingerprint, step-up, duplicate and evidence-specific outcome checks remain in SubscriptionLive.

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
    - examples/accrue_host/e2e/generated/copy_strings.json

key-decisions:
  - "Keep action review, validation, eligibility, fresh owner checks, step-up and dispatch inside SubscriptionLive."
  - "Do not present current subscription charge amounts unless supported evidence supplies them; invoice preview remains a separate confirmed preview."
  - "Use Back to subscription for review dismissal, which never means canceling the subscription."

requirements-completed: [JRN-04]

coverage:
  - id: D1
    description: All ten eligible subscription actions show self-contained target, identity, owner, current state, consequence and supported evidence limits.
    requirement: JRN-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#each eligible subscription action review identifies its target and current evidence
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#resume review has an explicit action name and missing money is not estimated
        status: pass
    human_judgment: false
  - id: D2
    description: Dismissal, correction, stale actor/owner/state, unsupported action, repeated confirmation and uncertain outcomes retain current owner safeguards and do not falsely claim settlement.
    requirement: JRN-04
    verification:
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#back from a staged cancellation dismisses the review without dispatch
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#confirmation rejects a changed actor and owner after review
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#correcting a staged quantity dispatches only the final reviewed intent
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#possibly submitted timeout stays uncertain and offers only scoped evidence
        status: pass
      - kind: integration
        ref: accrue_admin/test/accrue_admin/live/subscription_live_test.exs#repeated non-destructive confirmation after completion does not dispatch twice
        status: pass
    human_judgment: false

duration: 8 min
completed: 2026-10-10
status: complete
---

# Phase 241 Plan 05: Subscription Action Reviews Summary

**Subscription action reviews now identify the exact customer, owner, subscription, current state and requested change while keeping unknown money and unsupported previews unavailable.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-10T01:43:00Z
- **Completed:** 2026-10-10T01:51:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a self-contained review facts block for subscription identity, customer ID, customer owner and active scope, current lifecycle, current price, requested price/quantity and selected item ID.
- Kept absent charge amounts and unsupported preview values explicitly unavailable; supported plan previews continue to show exact minor-unit amount and currency.
- Renamed the standalone resume action and review dismissal copy to clearly distinguish domain action from returning to the subscription.
- Disabled confirmation during step-up and active submission while preserving an action-specific loading label.
- Added route-owner coverage for all ten eligible actions, correction, dismissal, stale actor/owner/state, repeated dispatch, unsupported actions and uncertain provider outcomes.

## Task Commits

1. **Task 1: Compose all eligible subscription reviews at their owner** - `3d52396c` (feat)
2. **Task 2: Retain subscription confirmation safety and evidence results** - `55833ee6`; staged-navigation acceptance `3ee303c6`.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - Renders full review facts and explicit unavailable-preview messaging; retains current owner validation and action-specific safety checks.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - Covers every eligible review variant, action correction, dismissal, stale/repeat and unknown-result controls.
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` and `accrue_admin/lib/accrue_admin/copy.ex` - Clarifies Resume subscription and Back to subscription copy.
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` and `examples/accrue_host/e2e/generated/copy_strings.json` - Keeps the browser copy fixture allowlist synchronized with the new labels.

## Decisions Made

- Action eligibility, review fingerprint, actor/scope/target revalidation, step-up, dispatch and result interpretation remain owned by SubscriptionLive.
- Charge amounts not present in the projection remain unavailable; a supported upcoming-invoice preview is shown separately and is not represented as settled billing.
- Review dismissal says Back to subscription and does not label the subscription action as canceled.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Keep confirmation visibly locked while step-up or submission is pending**
- **Found during:** Task 1
- **Issue:** The route rejected repeat confirmation in its handler, but the review confirm button did not expose a disabled/loading state during step-up or submission.
- **Fix:** Bound the confirmation buttons to dispatch state and added an action-named `phx-disable-with` label.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex`, `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`
- **Verification:** Subscription LiveView suite passed (38 tests, 0 failures).
- **Committed in:** `3d52396c`

**2. [Rule 3 - Blocking issue] Synchronize the generated browser copy fixture**
- **Found during:** Task 1
- **Issue:** The new Resume and Back labels would otherwise fail copy-export parity and leave the browser fixture stale.
- **Fix:** Added Back to subscription to the existing export allowlist and regenerated the checked-in fixture with `mix accrue_admin.export_copy_strings`.
- **Files modified:** `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/copy/subscription.ex`, `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`, `examples/accrue_host/e2e/generated/copy_strings.json`
- **Verification:** Export generated 123 strings; the focused subscription suite passed (38 tests, 0 failures).
- **Committed in:** `3d52396c`

**Total deviations:** 2 auto-fixed (Rule 2: 1; Rule 3: 1). **Impact:** Filled busy-state safety and kept copy contracts synchronized without adding dependencies or changing action ownership.

## Issues Encountered

- Two initial assertions were over-specific: the page renders its event copy through the assigned result and its portal content is not addressable through that LiveViewTest selector. Assertions were aligned to the owner’s observable output; no production guard was weakened.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 241-05 is complete. JRN-04 remains shared with Plans 241-06 and 241-07; global requirement bookkeeping remains pending those owners.
- Plan 241-07 owns the real browser Escape/focus, held-busy patch/reconnect, narrow-layout and served-asset checks.

---
*Phase: 241-billing-operator-journeys*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary and key source/test files exist; both task commits are ancestors of HEAD.
- Plan evaluation scope resolved both task commits on this branch.
- Focused owner suite: 38 tests, 0 failures; generated copy export completed with 123 strings.
- Coverage entries record executable integration checks with `human_judgment: false`.
