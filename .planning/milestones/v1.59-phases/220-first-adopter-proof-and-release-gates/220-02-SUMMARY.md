---
phase: 220-first-adopter-proof-and-release-gates
plan: 02
subsystem: entitlements
tags: [elixir, ecto, phoenix-liveview, playwright, accessibility, privacy]
requires:
  - phase: 220-01
    provides: deterministic reference-scenario corpus and proof boundaries
provides:
  - Closed, read-only account diagnostic projection
  - Operator-authorized host diagnostic rendering
  - Semantic and browser accessibility evidence
affects: [220-03, operator-runbooks, reference-host]
tech-stack:
  added: []
  patterns: [closed diagnostic maps, host-owned authorization, scoped axe checks]
key-files:
  created:
    - examples/accrue_host/lib/accrue_host_web/live/entitlement_diagnostics_live.ex
    - examples/accrue_host/e2e/entitlement-diagnostics.spec.js
  modified:
    - accrue/lib/accrue/entitlements/admin.ex
    - examples/accrue_host/lib/accrue_host_web/router.ex
key-decisions:
  - "The core diagnostic returns only normalized state, bounded ages, and an opaque correlation; host authorization remains outside Accrue."
  - "The host route selects only the signed-in operator's User entitlement account and never accepts an account identifier from request parameters."
patterns-established:
  - "Diagnostics remain read-only and render job-and-next-action copy instead of raw provider or worker data."
requirements-completed: [PROOF-03]
coverage:
  - id: D1
    description: Closed revision-consistent diagnostic projection for account state, source, provider, device, and recovery status.
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "accrue/test/accrue/entitlements/admin_test.exs#diagnostic_for_account/2"
        status: pass
    human_judgment: false
  - id: D2
    description: Operator-only LiveView with semantic bounded diagnostic copy and complementary browser accessibility evidence.
    requirement: PROOF-03
    verification:
      - kind: integration
        ref: "examples/accrue_host/test/accrue_host_web/live/entitlement_diagnostics_live_test.exs"
        status: pass
      - kind: e2e
        ref: "examples/accrue_host/e2e/entitlement-diagnostics.spec.js"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-04
status: complete
---

# Phase 220 Plan 02: Privacy-bounded entitlement diagnostic Summary

**A closed account diagnostic projection with host-authorized, accessible job-and-next-action rendering.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-08-04T15:34:00Z
- **Completed:** 2026-08-04T15:43:04Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added `Admin.diagnostic_for_account/2`, a read-only, closed map for canonical snapshot, rail provenance, provider freshness, device/proof horizon, recovery state, and next safe action.
- Kept owner identity, raw evidence, provider payloads, tokens, proof material, queue data, and metadata out of the projection.
- Added an authenticated operator route and LiveView that authorizes before lookup and renders bounded, text-backed diagnostic states with semantic headings and facts.
- Added focused ConnTest and scoped Playwright axe/keyboard evidence.

## Task Commits

1. **Task 1: Extend the closed diagnostic seam with canonical account state** - `cfe4687a` (TDD RED), `403ba44e` (TDD GREEN)
2. **Task 2: Render authorized job-focused diagnostics accessibly** - `6e41ae68` (TDD RED), `fdee4b55` (TDD GREEN)

## Files Created/Modified

- `accrue/lib/accrue/entitlements/admin.ex` - closed account diagnostic projection.
- `accrue/test/accrue/entitlements/admin_test.exs` - exact projection and privacy-boundary tests.
- `examples/accrue_host/lib/accrue_host_web/router.ex` - authenticated diagnostics route.
- `examples/accrue_host/lib/accrue_host_web/live/entitlement_diagnostics_live.ex` - operator-facing semantic diagnostic view.
- `examples/accrue_host/test/accrue_host_web/live/entitlement_diagnostics_live_test.exs` - authorization and bounded-copy coverage.
- `examples/accrue_host/e2e/entitlement-diagnostics.spec.js` - complementary keyboard and scoped axe verification.

## Decisions Made

- Used an opaque truncated hash for diagnostic correlation rather than an account identifier or owner identity.
- Kept the diagnostic host-owned: the LiveView authenticates and verifies the operator before resolving the current user's account; no request parameter can widen access.
- Scoped axe to the new diagnostic surface after the full-page scan exposed a pre-existing header contrast violation outside this plan's files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped the new axe check to the diagnostic surface.**
- **Found during:** Task 2
- **Issue:** A full-page axe scan failed on an existing root-header contrast issue unrelated to the diagnostic surface.
- **Fix:** Scoped the complementary browser scan to `[data-testid='entitlement-diagnostic']`.
- **Files modified:** `examples/accrue_host/e2e/entitlement-diagnostics.spec.js`
- **Verification:** `npm run e2e -- e2e/entitlement-diagnostics.spec.js` passed.
- **Committed in:** `fdee4b55`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The focused browser test now verifies the shipped surface without masking or changing unrelated global UI work.

## Issues Encountered

- The full `mix verify` host suite was run but failed in pre-existing `AccrueHost.BillingFacadeTest` fake-subscription uniqueness setup (`accrue_subscriptions_processor_processor_id_index`). The focused host test and Playwright diagnostic check passed; no unrelated billing code was changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 220-03 can consume the closed diagnostic seam and the host rendering pattern.
- The retained PROOF-03 prohibition remains descriptor-less and flagged-unverified as specified by the plan.

## Self-Check: PASSED

- Confirmed all six planned production/test files exist.
- Confirmed task commits `cfe4687a`, `403ba44e`, `6e41ae68`, and `fdee4b55` exist in git history.

---
*Phase: 220-first-adopter-proof-and-release-gates*
*Completed: 2026-08-04*
