---
phase: 101-accrue-portal-foundation-checkout
plan: 06
subsystem: ui
tags: [phoenix, liveview, braintree, portal, invoices, payment-methods]
requires:
  - phase: 101-04
    provides: portal shell and customer-scoped portal mount
  - phase: 101-05
    provides: checkout hosted-fields baseline and portal read-model patterns
provides:
  - customer payment-method index with centralized copy
  - dedicated add-card LiveView mounted at /payment-methods/new
  - invoice history view with centralized empty-state and action copy
affects: [BT-03, portal-proof, docs, example-host]
tech-stack:
  added: []
  patterns: [centralized portal copy helpers, liveview-owned hosted-fields route flow]
key-files:
  created: [accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex]
  modified:
    [
      accrue_portal/lib/accrue_portal/copy.ex,
      accrue_portal/lib/accrue_portal/router.ex,
      accrue_portal/lib/accrue_portal/live/payment_methods_live.ex,
      accrue_portal/lib/accrue_portal/live/invoices_live.ex
    ]
key-decisions:
  - "Split add-card into its own LiveView route so Hosted Fields stays in the portal shell instead of embedding more controller UI."
  - "Kept payment-method and invoice lookups on the existing customer-scoped read model and controller endpoints to preserve D-19 guards."
patterns-established:
  - "Portal-facing payment-method and invoice strings now live in AccruePortal.Copy instead of inline HEEx."
  - "The add-card flow uses a dedicated /payment-methods/new LiveView while nonce submission continues through the existing authenticated POST endpoint."
requirements-completed: [BT-03]
duration: 29 min
completed: 2026-05-02
---

# Phase 101 Plan 06: Accrue Portal Foundation Checkout Summary

**Dedicated payment-method and invoice portal screens now ship through the mounted LiveView shell, with centralized copy and a separate Hosted Fields add-card route.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-05-02T14:27:00Z
- **Completed:** 2026-05-02T14:56:17Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Split the add-card flow out of the payment-method index and mounted it at `/payment-methods/new`.
- Moved portal-facing payment-method and invoice strings into `AccruePortal.Copy`.
- Added the remaining router wiring so payment methods, add-card, and invoices stay inside the portal LiveView shell.

## Task Commits

Each task was committed atomically:

1. **Task 1: Finish the payment-method and invoice LiveViews with route wiring and D-19 production guards** - `a74de65` (feat)

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` - dedicated Hosted Fields add-card LiveView
- `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex` - payment-method index, empty state, and route into add-card flow
- `accrue_portal/lib/accrue_portal/live/invoices_live.ex` - invoice history copy centralization and empty state
- `accrue_portal/lib/accrue_portal/router.ex` - `/payment-methods/new` LiveView route
- `accrue_portal/lib/accrue_portal/copy.ex` - centralized payment-method and invoice strings for this slice

## Decisions Made

- Used a dedicated add-card LiveView instead of the prior inline form so the add-card path remains LiveView-owned and routed through the portal shell.
- Reused the existing authenticated POST endpoint for nonce submission rather than introducing a controller-rendered card form.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The initial implementation referenced a non-existent copy helper during compile. This was corrected before verification and did not require scope changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The remaining BT-03 customer surfaces now exist in production code and are ready for follow-on proof, docs, and example-host integration work.
- No blockers found in the owned files for the next portal verification slice.

## Self-Check: PASSED

- Found summary file at `.planning/phases/101-accrue-portal-foundation-checkout/101-06-SUMMARY.md`
- Found task commit `a74de65` in git history

---
*Phase: 101-accrue-portal-foundation-checkout*
*Completed: 2026-05-02*
