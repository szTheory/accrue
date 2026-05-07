---
phase: 110-lifecycle-semantics-self-serve-clarity
plan: 02
subsystem: ui-copy
tags: [billing, lifecycle, portal, admin, example-host, copy]
requires:
  - phase: 110-lifecycle-semantics-self-serve-clarity
    provides: lifecycle semantics SSOT and aligned adjacent docs
provides:
  - portal, admin, and example-host surfaces now render lifecycle meaning via shared predicate-safe wording
  - customer and operator copy now distinguishes cancel-renewal from immediate cancel with explicit access timing
  - provider-aware helper text stays honest about Braintree divergence and unsupported pause/resume semantics
affects: [phase-110, portal-ui, admin-ui, example-host, lifecycle-copy]
tech-stack:
  added: []
  patterns: [copy helpers derive from predicates, package-local copy seams reused, access timing stated explicitly]
key-files:
  created: [.planning/milestones/v1.35-phases/110-lifecycle-semantics-self-serve-clarity/110-02-SUMMARY.md]
  modified: [accrue_portal/lib/accrue_portal/copy.ex, accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_portal/lib/accrue_portal/live/subscriptions_live.ex, accrue_admin/lib/accrue_admin/copy/subscription.ex, accrue_admin/lib/accrue_admin/copy.ex, accrue_admin/lib/accrue_admin/live/subscription_live.ex, examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex, accrue_portal/mix.lock, examples/accrue_host/mix.lock]
key-decisions:
  - "Touched UI surfaces should render lifecycle meaning from canonical predicates and helper functions rather than raw status strings."
  - "Immediate cancel remains an explicit exceptional operator or hard-stop path, while default self-serve wording focuses on canceling renewal and paid-through access."
patterns-established:
  - "When lifecycle copy changes in portal or admin surfaces, helper functions should be updated first and then consumed by the LiveViews."
requirements-completed: [LIF-02]
duration: 1 wave
completed: 2026-05-06
---

# Phase 110 Plan 02: Lifecycle UI Copy Summary

**The touched portal, admin, and example-host surfaces now explain lifecycle state and timing in provider-honest language.**

## Performance

- **Completed:** 2026-05-06
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added shared lifecycle copy helpers to `AccruePortal.Copy` for labels, summaries, and access timing.
- Updated the portal detail and list LiveViews to render lifecycle meaning from predicates instead of exposing raw `subscription.status` as user-facing truth.
- Shifted portal wording to `Cancel renewal`, explicit end-of-period timing, and convergence-safe copy about access timing.
- Added admin lifecycle guidance helpers and delegates so operator-facing screens can distinguish `Cancel now` from `Cancel at period end`.
- Updated admin copy to stay provider-honest about Braintree divergence and unsupported pause/resume/reactivation semantics.
- Updated the example host copy so its customer-facing cancellation text is clearly a hard-stop path rather than ambiguous generic cancel wording.

## Verification

- Portal copy verifier passed: `rg -n "cancel renewal|end at period end|access ends|canceling|paused|past due|ended" accrue_portal/lib/accrue_portal/copy.ex accrue_portal/lib/accrue_portal/live/subscription_live.ex accrue_portal/lib/accrue_portal/live/subscriptions_live.ex && ! rg -n "<span>\\{@subscription.status\\}</span>|Status\\}: \\{subscription.status\\}" accrue_portal/lib/accrue_portal/live/subscription_live.ex accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`
- Admin and host copy verifier passed: `rg -n "Cancel now|Cancel at period end|cancel renewal|access ends|Braintree|pause|resume|ended|canceling|past due" accrue_admin/lib/accrue_admin/copy/subscription.ex accrue_admin/lib/accrue_admin/live/subscription_live.ex examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`
- Admin targeted suite passed: `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs`
- Portal targeted suite passed after dependency restore: `cd accrue_portal && mix deps.get && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs`

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/copy.ex` - lifecycle label, summary, and access-timing helpers
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` - lifecycle summary and cancel-renewal wording on the detail view
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` - shared lifecycle meaning on list surfaces
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` - operator-facing lifecycle and provider guidance helpers
- `accrue_admin/lib/accrue_admin/copy.ex` - delegates for the new subscription copy helpers
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - provider-aware confirm and lifecycle guidance
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - explicit hard-stop cancellation wording and supporting assigns
- `accrue_portal/mix.lock` - restored portal package dependencies
- `examples/accrue_host/mix.lock` - restored example-host package dependencies

## Issues Encountered

- `accrue_portal` and `examples/accrue_host` were missing the `rendro` dependency locally, so `mix deps.get` had to run before verification.
- Admin tests initially exposed missing top-level delegates for the new copy helpers; that was fixed in `accrue_admin/lib/accrue_admin/copy.ex`.

## Self-Check: PASSED

- Verified the portal and admin targeted suites passed after the copy changes.
- Confirmed the example host renders the new hard-stop cancellation copy without missing assigns.
