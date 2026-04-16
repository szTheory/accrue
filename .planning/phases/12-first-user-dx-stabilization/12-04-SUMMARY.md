---
phase: 12-first-user-dx-stabilization
plan: 04
subsystem: ui
tags: [elixir, phoenix, liveview, ecto, billing]
requires:
  - phase: 12-first-user-dx-stabilization
    provides: installer rerun safety and existing host-app billing facade coverage
provides:
  - host-facing billing state helper on `AccrueHost.Billing`
  - subscription LiveView reads routed through the generated host facade
  - host-app proof coverage for nil and subscribed billing state
affects: [phase-13-adoption-assets, phase-14-quality-hardening, examples/accrue_host]
tech-stack:
  added: []
  patterns:
    - host UI reads current billing state through the generated `MyApp.Billing` facade
    - generated host facades may hide internal Repo and schema lookups while keeping the public API Phoenix-context-shaped
key-files:
  created: []
  modified:
    - examples/accrue_host/lib/accrue_host/billing.ex
    - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
    - examples/accrue_host/test/accrue_host/billing_facade_test.exs
key-decisions:
  - "Added `billing_state_for/1` to the generated host facade so first users inspect current billing state without direct UI coupling to private Accrue tables."
  - "Kept the LiveView on `Subscription.canceled?/1` while moving all read access through `AccrueHost.Billing`, preserving the existing status-guard behavior."
patterns-established:
  - "Host-first billing reads: LiveViews call the generated billing facade for read and write operations."
  - "Facade-owned lookup helpers may query internal Accrue tables as long as the host app's public surface stays explicit and small."
requirements-completed: [DX-05]
duration: 2min
completed: 2026-04-16
---

# Phase 12 Plan 04: First-User DX Stabilization Summary

**Host-owned billing state reads now flow through `AccrueHost.Billing.billing_state_for/1`, and the subscription LiveView no longer queries private Accrue tables directly.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-16T22:02:00Z
- **Completed:** 2026-04-16T22:03:52Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added a host-facing `billing_state_for/1` helper that returns `%{customer: customer, subscription: subscription}` without auto-creating a customer row.
- Updated the host subscription LiveView to load current state through `AccrueHost.Billing` instead of direct Repo and schema queries.
- Extended host billing facade tests to prove both the nil-state and subscribed-state public boundary.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add host-facing billing state helpers to the generated facade** - `b62db4a` (feat)
2. **Task 2: Move the subscription LiveView onto the host billing facade** - `a1e426d` (feat)

**Plan metadata:** pending

## Files Created/Modified
- `examples/accrue_host/lib/accrue_host/billing.ex` - Adds `billing_state_for/1` plus private lookup helpers for current customer and newest subscription.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - Replaces direct customer/subscription queries with `Billing.billing_state_for/1`.
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` - Verifies exported facade functions and current-state reads before and after subscription creation.

## Decisions Made
- Added the read helper to the generated host facade instead of teaching the UI to query `Accrue.Billing.Customer` and `Accrue.Billing.Subscription` directly.
- Kept the existing `Subscription.canceled?/1` guard in the LiveView to preserve current UI behavior while removing the Repo-coupled fetch helpers.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The acceptance criteria listed `alias Accrue.Billing.Subscription` as removable private coupling while also requiring `Subscription.canceled?/1` to remain. The implementation followed the task text and kept the predicate-based status checks intact.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The host app now demonstrates the intended host-first API boundary for both billing writes and current-state reads.
- Later docs and adoption work can point first users at `AccrueHost.Billing` without explaining direct Accrue table access.

## Self-Check: PASSED

- Found `.planning/phases/12-first-user-dx-stabilization/12-04-SUMMARY.md`
- Found commit `b62db4a`
- Found commit `a1e426d`
