---
phase: 198-propagate-detail-analytics
plan: "01"
subsystem: testing
tags: [playwright, e2e, billing, detail-pages, analytics, phase198]

requires:
  - phase: 191
    provides: Shared Playwright flow helpers for focus containment, pointer targets, theme setup, and horizontal clipping checks.
  - phase: 194
    provides: Admin billing navigation and seeded route coverage.
  - phase: 195
    provides: Billing detail and analytics route fixtures used by the Phase 198 contract.
  - phase: 197
    provides: Propagation patterns and scope boundaries for billing UI follow-up phases.
provides:
  - Phase 198 Playwright DETAIL and analytics propagation browser contract.
  - Phase 198 npm script for running the dedicated browser contract.
  - Red-gate verification evidence for missing detail markers, analytics markers, and representative drawer flows.
affects: [phase198, phase199, phase200, billing-e2e, admin-billing]

tech-stack:
  added: []
  patterns:
    - Explicit Playwright target matrices for billing detail and analytics pages.
    - Test-only invariant helpers local to the Phase 198 spec.
    - Desktop-only representative drawer flow checks paired with mobile structural coverage.

key-files:
  created:
    - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
  modified:
    - accrue_admin/package.json
    - .planning/phases/198-propagate-detail-analytics/198-01-SUMMARY.md

key-decisions:
  - "The Phase 198 contract uses explicit page target matrices and existing seeded fixtures rather than adding generic DetailPage or AnalyticsPage runtime abstractions."
  - "Recovery analytics assertions use Phase 198-specific hero, work queue, and supporting funnel markers rather than inheriting dashboard zone-order checks."
  - "Representative drawer and step-up probes are desktop-only while mobile still receives structural detail and analytics route checks."

patterns-established:
  - "Phase browser contracts should stay local to their phase when the plan only defines coverage and should avoid runtime abstractions."
  - "Dedicated phase npm scripts should call a single Playwright spec with deterministic timeout and worker settings."

requirements-completed: [PRP-02]

duration: 10m 39s
completed: 2026-06-28
status: complete
---

# Phase 198 Plan 01: Browser Contract Summary

**Phase 198 Playwright contract for billing detail pages, recovery analytics, campaign analytics, and representative drawer propagation flows**

## Performance

- **Duration:** 10m 39s
- **Started:** 2026-06-28T23:05:25Z
- **Completed:** 2026-06-28T23:16:04Z
- **Tasks:** 3
- **Files modified:** 2 implementation files plus planning closeout metadata

## Accomplishments

- Created `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` with explicit target coverage for all eight billing detail routes plus recovery and campaign analytics routes.
- Added assertions for summary lists, related resources, lazy bottom sections, analytics order, horizontal clipping, focus containment, top pointer targets, and representative drawer or step-up interactions.
- Added the dedicated `e2e:phase198` script without changing dependencies.
- Ran the Phase 198 browser red gate and confirmed failures are page conformance gaps, not missing files, package script errors, route seed failures, or import failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Phase 198 Playwright contract spec** - `8fc205d7` (test)
2. **Task 2: Add Phase 198 npm script** - `4f6729b2` (chore)
3. **Task 3: Execute Phase 198 browser red gate** - `7e2aed39` (test)

**Plan metadata:** committed after summary and state closeout.

## Files Created/Modified

- `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` - Phase 198 Playwright browser contract for billing detail and analytics propagation.
- `accrue_admin/package.json` - Added the `e2e:phase198` script pointing at the Phase 198 Playwright spec.
- `.planning/phases/198-propagate-detail-analytics/198-01-SUMMARY.md` - Execution summary and verification record.

## Decisions Made

- Used explicit route matrices and seeded fixture keys for the contract so implementation plans get concrete failure output per target route.
- Kept helper functions test-local to avoid introducing generic `DetailPage` or `AnalyticsPage` abstractions outside the plan scope.
- Scoped analytics checks to Phase 198 requirements only: Recovery hero, work queue, supporting funnel, CampaignTimeline visibility, and shared detail invariants.
- Scoped drawer and step-up checks to representative desktop flows while preserving mobile coverage for page-level invariants.

## Verification Results

- `cd accrue_admin && node --check e2e/admin-spec-detail-phase198.spec.js` - passed.
- `cd accrue_admin && node -e "..."` exact `e2e:phase198` script check - passed.
- Required route matrix scan - passed for customers, invoices, payments, coupons, promotion codes, connect accounts, webhooks, events, recovery analytics, and campaign analytics.
- Required marker scan - passed for `data-ax-summary-list`, `data-ax-related-resources`, `data-ax-lazy-activity`, `data-ax-lazy-json`, `data-ax-recovery-hero`, `data-ax-recovery-work-queue`, `data-ax-recovery-supporting-funnel`, drawer flow checks, horizontal clipping checks, and CampaignTimeline coverage.
- Forbidden scope scan - passed with no `DetailPage`, `AnalyticsPage`, transformed ancestor, FOUC, reduced-motion, Storybook, Phase 199, Phase 200, or final scorecard references.
- Stub scan - passed with no TODO, FIXME, placeholder, coming soon, not available, empty hardcoded UI collections, null, or empty string stubs in modified implementation files.
- `cd accrue_admin && npm run e2e:phase198` - intentionally red for the Wave 0 contract: 25 failed, 5 skipped. The run booted the app, seeded authenticated routes, and reached target pages. Failures are expected conformance gaps:
  - `[data-ax-summary-list]` is missing on all eight detail pages across desktop and mobile.
  - `[data-ax-recovery-hero]` is missing on Recovery analytics across desktop and mobile.
  - `[data-ax-summary-list]` is missing on Campaign analytics across desktop and mobile.
  - Desktop representative drawer or step-up flows are not yet satisfied for invoice, charge, webhook, connect account, and customer payment method targets.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The Phase 198 Playwright run is intentionally red because this plan defines the browser contract before the runtime pages are updated. No harness, package, import, dependency, seed, or authentication issue blocked execution.

## Auth Gates

None.

## Known Stubs

None.

## Threat Flags

None. This plan added a test-only Playwright spec and npm script; it did not add network endpoints, auth paths, file access patterns, schema changes, or runtime trust-boundary surface.

## TDD Gate Compliance

Task-level TDD red-gate coverage is present via `8fc205d7` and `7e2aed39`. This plan intentionally ships the failing browser contract only; later Phase 198 implementation plans are responsible for driving it green.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The Phase 198 contract is ready for implementation plans to propagate summary, related-resource, lazy-bottom, analytics, and representative drawer behavior into the runtime pages. The expected red browser failures identify the first selectors and flows those plans need to satisfy.

## Self-Check: PASSED

- Found `accrue_admin/e2e/admin-spec-detail-phase198.spec.js`.
- Found `accrue_admin/package.json`.
- Found `.planning/phases/198-propagate-detail-analytics/198-01-SUMMARY.md`.
- Found task commits `8fc205d7`, `4f6729b2`, and `7e2aed39`.

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-28*
