---
phase: 198-propagate-detail-analytics
plan: "07"
subsystem: ui
tags: [phoenix-liveview, spec-detail, step-up, webhooks, connect, exunit]

# Dependency graph
requires:
  - phase: 198-02
    provides: "SPEC-DETAIL primitives and propagation contract"
  - phase: 198-06
    provides: "Read-only ledger DETAIL migration patterns"
provides:
  - "Connect account detail page migrated to SPEC-DETAIL with drawer-hosted platform fee override"
  - "Webhook detail page migrated to SPEC-DETAIL with drawer-hosted replay"
  - "StepUp-gated sensitive Connect override and Webhook replay tests"
affects: [phase-198, admin-detail-pages, connect, webhooks, sensitive-admin-actions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phoenix LiveView DETAIL pages with summary rows, action band, drills, related strip, and lazy Activity/Raw payload sections"
    - "DetailDrawer intent gates plus StepUp.require_fresh for sensitive admin mutations"

key-files:
  created:
    - .planning/phases/198-propagate-detail-analytics/198-07-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - accrue_admin/lib/accrue_admin/copy/connect.ex
    - accrue_admin/lib/accrue_admin/copy/locked.ex
    - accrue_admin/lib/accrue_admin/copy.ex

key-decisions:
  - "Kept Connect platform fee override and Webhook replay in DetailDrawer flows with server-owned pending action state."
  - "Required StepUp.require_fresh for both sensitive saves because the plan recorded no lower-risk exception."
  - "Rendered webhook raw payload only through the lazy Raw payload section while keeping summary/drill state visible."

patterns-established:
  - "Operational detail pages expose one summary list, one related strip, lazy Activity/Raw payload markers, and action buttons only after eligibility checks."
  - "Non-replayable webhook rows use precise state copy instead of disabled replay controls."

requirements-completed: [PRP-02]

# Metrics
duration: 34min
completed: 2026-06-29
status: complete
---

# Phase 198 Plan 07: Connect and Webhook Detail Summary

**Connect account and webhook operational detail pages now use SPEC-DETAIL summary/drill/lazy structure while preserving StepUp-gated sensitive actions.**

## Performance

- **Duration:** 34 min
- **Started:** 2026-06-29T01:30:25Z
- **Completed:** 2026-06-29T02:04:01Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Migrated `ConnectAccountLive` to summary rows, operational drills, related resources, lazy Activity/Raw payload sections, and a drawer-hosted platform fee override.
- Migrated `WebhookLive` to summary rows, replay eligibility/lifecycle/ledger drills, related resources, lazy Activity/Raw payload sections, and a drawer-hosted replay confirmation.
- Preserved server-side owner-scope rechecks, action eligibility checks, audit recording, and StepUp for platform fee override and webhook replay.

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert ConnectAccountLive and drawer-host the override**
   - `685da0a1` test: add failing connect detail assertions
   - `900ca656` feat: convert connect account detail
2. **Task 2: Convert WebhookLive and drawer-host replay**
   - `6d62f2f3` test: add failing webhook detail assertions
   - `6d538f90` feat: convert webhook detail
3. **Task 3: Verify combined operational detail behavior**
   - `7eb742a9` test: verify combined detail behavior

**Plan metadata:** pending docs commit

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` - SPEC-DETAIL Connect page with summary rows, drawer override, lazy Activity/Raw payload, StepUp save, and server-side scope recheck.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` - SPEC-DETAIL Webhook page with summary rows, drawer replay, lazy Activity/Raw payload, StepUp replay, and server-side eligibility recheck.
- `accrue_admin/test/accrue_admin/live/connect_account_live_test.exs` - Connect DETAIL, drawer intent, and StepUp assertions.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - Webhook DETAIL, non-replayable copy, drawer replay, lazy raw/activity, and StepUp assertions.
- `accrue_admin/lib/accrue_admin/copy/connect.ex` - Connect detail, override, action band, and lazy-section copy.
- `accrue_admin/lib/accrue_admin/copy/locked.ex` - Webhook replay drawer, StepUp, and non-replayable state copy.
- `accrue_admin/lib/accrue_admin/copy.ex` - Shared copy delegates for Connect and Webhook detail strings.
- `.planning/phases/198-propagate-detail-analytics/198-07-SUMMARY.md` - Plan closeout summary.

## Decisions Made

- Used the existing `DetailDrawer` and `StepUpAuthModal` primitives instead of introducing a generic DETAIL DSL or schema.
- Kept Connect/Webhook action state server-owned with `:drawer_action_type`, `:pending_override`, and `:pending_replay` assigns.
- Updated old webhook forensic/KPI assertions to the lazy SPEC-DETAIL contract rather than reintroducing eager raw payload or KPI markup.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/connect_account_live_test.exs --max-failures 5` - passed, 5 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs --max-failures 5` - passed, 11 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/live/connect_account_live_test.exs test/accrue_admin/live/webhook_live_test.exs --max-failures 8` - passed, 16 tests, 0 failures.
- `rg -n "StepUp\\.require_fresh" accrue_admin/lib/accrue_admin/live/connect_account_live.ex accrue_admin/lib/accrue_admin/live/webhook_live.ex` - found both sensitive paths.

## Deviations from Plan

None - plan executed within the stated scope.

## Issues Encountered

- Webhook tests still asserted old KPI/eager forensic payload behavior after the LiveView migrated to SPEC-DETAIL. Resolved by updating those tests to assert the lazy Raw payload and Activity contract.

## Known Stubs

None. Stub scan found only hidden StepUp test input defaults (`value=""`) and a non-empty list guard; neither is a UI data stub.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Connect Account and Webhook DETAIL migrations are complete for PRP-02. Later Phase 198 work can continue propagating SPEC-DETAIL to remaining pages without changing the sensitive action gating model.

## Self-Check: PASSED

- Summary file exists.
- All key created/modified files exist.
- Task commits found: `685da0a1`, `900ca656`, `6d62f2f3`, `6d538f90`, `7eb742a9`.

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-29*
