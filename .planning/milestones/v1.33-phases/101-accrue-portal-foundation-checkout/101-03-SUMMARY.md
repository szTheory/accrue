---
phase: 101-accrue-portal-foundation-checkout
plan: 03
subsystem: payments
tags: [braintree, checkout, billing-portal, facade, phoenix, telemetry]
requires:
  - phase: 101-01
    provides: local checkout session persistence and portal config plumbing
provides:
  - Braintree local checkout and billing-portal regression coverage
  - adapter fallback semantics when the local portal is unavailable
  - public facade docs that distinguish Stripe-hosted and Braintree-local routing
affects: [101-04, 101-05, BT-02, processor-capabilities]
tech-stack:
  added: []
  patterns: [adapter-only portal fallback, local portal raw payload markers, facade docs for processor-specific hosted routing]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/processor/braintree.ex
    - accrue/lib/accrue/billing.ex
    - accrue/test/accrue/processor/braintree_local_portal_test.exs
    - accrue/test/accrue/billing/checkout_session_facade_test.exs
    - accrue/test/accrue/billing/billing_portal_session_facade_test.exs
key-decisions:
  - "Kept the unsupported local-portal fallback entirely inside the Braintree adapter so the public facade remains processor-agnostic."
  - "Preserved existing checkout and billing-portal struct semantics by enriching the Braintree raw payload metadata instead of changing Stripe projection behavior."
patterns-established:
  - "Braintree local-portal regressions assert mounted URL shape, redirect passthrough, and operation_id reuse through the public billing facade."
  - "Local portal availability is treated as configuration truth via `portal_base_url`, with an adapter-level `:unsupported_by_gateway` fallback when absent."
requirements-completed: [BT-02]
duration: 9min
completed: 2026-05-02
---

# Phase 101 Plan 03: Braintree Local Portal Contract Summary

**Braintree checkout and billing-portal flows now advertise first-party local portal semantics, preserve the unsupported fallback when the portal is unavailable, and document the unchanged Stripe-hosted path on the public billing facade**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-02T02:04:00Z
- **Completed:** 2026-05-02T02:13:03Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added RED/GREEN regression coverage for mounted Braintree checkout and billing-portal URLs, redirect passthrough fields, and `operation_id` reuse.
- Fixed the Braintree adapter so billing-portal creation returns `:unsupported_by_gateway` when the local portal is not configured instead of surfacing a broken config/provisioning path.
- Updated `Accrue.Billing` docstrings to explain that Stripe remains hosted upstream while Braintree routes through the host-mounted local portal.

## Task Commits

Each task was committed atomically:

1. **Task 1: Flip the Braintree adapter and capability labels to the first-party local-portal contract** - `9d3984a` (test), `b6791f9` (feat)
2. **Task 2: Update facade documentation and regression tests around the Braintree local-portal path** - `670fdf1` (docs)

## Files Created/Modified
- `accrue/lib/accrue/processor/braintree.ex` - adapter fallback branch and local portal payload metadata
- `accrue/lib/accrue/billing.ex` - public facade docs for Stripe-hosted versus Braintree-local routing
- `accrue/test/accrue/processor/braintree_local_portal_test.exs` - adapter regressions for mounted URLs, redirect passthrough, and unavailable-portal fallback
- `accrue/test/accrue/billing/checkout_session_facade_test.exs` - facade regression for mounted Braintree checkout URL shape and `operation_id` reuse
- `accrue/test/accrue/billing/billing_portal_session_facade_test.exs` - facade regression for mounted Braintree portal URLs and unsupported fallback

## Decisions Made

- Kept the local-portal availability fallback behind `Accrue.Processor.__impl__/0` dispatch instead of branching in `Accrue.Billing`.
- Used the Braintree raw payload `data` map to expose local-session markers without changing how Stripe-backed `Checkout.Session` and `BillingPortal.Session` structs are projected.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced the stale `mix test -x` verifier invocation**
- **Found during:** Task 1 (TDD verification)
- **Issue:** The plan's verification command used `-x`, which this Mix version no longer accepts.
- **Fix:** Ran the same scoped test suite with `--trace` for execution-time verification.
- **Files modified:** None
- **Verification:** Scoped ExUnit suites passed under `--trace`
- **Committed in:** None

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification changed only at the command-flag level. Functional scope stayed aligned with the plan.

## Issues Encountered

- The adapter already contained most of the local-portal implementation in `HEAD`, but the unavailable-portal branch still raised a config/provisioning error instead of preserving the locked fallback. The regression suite now guards that branch directly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The Braintree adapter and facade now tell the same story about local hosted checkout and billing-portal support.
- Later portal plans can rely on the mounted/unmounted semantics and raw payload markers without reopening the facade contract.

## Self-Check: PASSED

---
*Phase: 101-accrue-portal-foundation-checkout*
*Completed: 2026-05-02*
