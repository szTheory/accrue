---
phase: 113-cancellation-semantics-closure
plan: 02
subsystem: payments
tags: [cancellation, docs, portal, admin, braintree, copy]
requires:
  - phase: 113-cancellation-semantics-closure
    provides: promoted immediate-vs-scheduled cancellation support truth from Plan 01
provides:
  - provider-honest cancellation docs that treat Braintree immediate cancel as first-party and softer non-renewal as host-owned
  - mounted portal branching that stops assuming scheduled-end parity for Braintree subscriptions
  - admin and example-host copy aligned to the same immediate-vs-scheduled contract boundary
affects: [113-03, lifecycle docs, portal copy, admin operator guidance, example host proof]
tech-stack:
  added: []
  patterns: [provider-aware LiveView branching, shared lifecycle vocabulary across docs and UI]
key-files:
  created: [.planning/phases/113-cancellation-semantics-closure/113-02-SUMMARY.md]
  modified:
    - accrue/guides/braintree-local-portal.md
    - accrue/guides/lifecycle_semantics.md
    - accrue/guides/portal_configuration_checklist.md
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/lib/accrue_portal/live/subscription_live.ex
    - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
    - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
key-decisions:
  - "Treat Braintree `cancel/2` as the supported first-party path in docs and mounted copy, while keeping softer end-of-term policy explicitly host-owned."
  - "Branch mounted portal cancellations by processor instead of pretending `cancel_at_period_end/2` is generic parity behavior."
patterns-established:
  - "Docs and mounted surfaces reuse one cancellation glossary: `Cancel now` for immediate hard-stop, `Cancel renewal` / `Cancel at period end` only where scheduled-end semantics are real."
  - "Provider-aware UI branching lives in shared copy helpers and narrow LiveView guards instead of expanding the public billing API."
requirements-completed: [PROC-22, PROC-23]
duration: 9min
completed: 2026-05-07
---

# Phase 113 Plan 02: Cancellation Semantics Closure Summary

**Docs, portal flows, admin guidance, and the example host now describe the same provider-honest cancellation contract: Braintree supports immediate cancel first-party, while softer end-of-term policy remains host-owned.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-07T10:32:00Z
- **Completed:** 2026-05-07T10:41:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Rewrote the lifecycle, Braintree portal, and Stripe portal checklist guides so they share one explicit vocabulary for immediate hard-stop versus scheduled-end cancellation.
- Updated mounted portal detail and list flows to branch by processor, using `Billing.cancel/2` for Braintree instead of unconditionally calling `Billing.cancel_at_period_end/2`.
- Tightened admin and example-host copy so operators and adopters see the same boundary: `Cancel now` is the supported Braintree path; scheduled-end, reversal, pause, and unpause semantics remain host-owned or unsupported.

## Task Commits

1. **Task 1: Rewrite the cancellation docs around the promoted immediate-vs-scheduled contract** - `c2b0569` (docs)
2. **Task 2: Gate mounted customer flows and align operator/reference wording to the same contract boundary** - `d20fdc1` (fix)

## Files Created/Modified

- `accrue/guides/lifecycle_semantics.md` - promotes Braintree `cancel/2` to supported first-party guidance and keeps the immediate-vs-scheduled glossary explicit
- `accrue/guides/braintree-local-portal.md` - replaces scheduled-end parity teaching with immediate-cancel support plus a host-owned non-renewal seam
- `accrue/guides/portal_configuration_checklist.md` - sharpens the Stripe-only scope of hosted scheduled-end cancellation guidance
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` - updates Braintree operator guidance to reflect immediate support and scheduled-end/pause/resume limits
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - narrows confirmation copy so processor limits stay explicit at action time
- `accrue_portal/lib/accrue_portal/copy.ex` - adds provider-aware cancellation copy for Braintree immediate-cancel behavior
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` - branches mounted detail cancellation by processor
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` - branches mounted list cancellation by processor
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - keeps the hard-stop example explicit and labels softer Braintree policy as host-owned

## Decisions Made

- Preserved the Plan 01 contract rather than widening runtime scope: Braintree keeps first-party immediate cancellation only, while scheduled-end and reversible semantics remain outside generic parity.
- Solved the portal mismatch with provider-aware branching at existing UI seams instead of adding new billing facade APIs.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The executor protocol references `gsd-sdk query ...` state helpers, but this workspace’s `gsd-sdk` binary only exposes `run`, `auto`, and `init`. Planning artifacts were updated manually.

## User Setup Required

None.

## Next Phase Readiness

- `113-03-PLAN.md` can focus on proof and drift gates with the docs and mounted surfaces now aligned to the Plan 01 runtime contract.
- The remaining gap is merge-blocking coverage for the provider-aware copy and branching introduced here.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/113-cancellation-semantics-closure/113-02-SUMMARY.md`
- Verified task commits exist: `c2b0569`, `d20fdc1`
