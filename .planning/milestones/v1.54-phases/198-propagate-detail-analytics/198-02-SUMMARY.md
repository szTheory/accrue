---
phase: 198-propagate-detail-analytics
plan: "02"
subsystem: testing
tags: [phoenix-liveview, exunit, admin-ui, detail-contracts, step-up]

# Dependency graph
requires:
  - phase: 193-dashboard
    provides: Pattern lock and selector conventions for admin detail pages
  - phase: 198-propagate-detail-analytics
    provides: Wave 0 browser contract context and detail-page migration intent
provides:
  - Customer-360 peer navigation and lazy detail LiveView contracts
  - Invoice and charge action drawer, StepUp, summary, related strip, and lazy-section contracts
  - Webhook replay and connect platform-fee override drawer and StepUp contracts
affects: [phase-198-runtime-rewrites, phase-199-overlays, phase-200-final-signoff]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - RED LiveView contract tests before runtime detail migrations
    - Test-local data-ax selector helpers for detail contract counts

key-files:
  created: []
  modified:
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs

key-decisions:
  - "Plan 198-02 intentionally ships RED LiveView contract tests only; runtime migrations remain in later Phase 198 plans."
  - "High-risk action contracts assert intent-opened drawers and StepUp challenge behavior instead of visible initial forms."
  - "Customer-360 peer navigation is locked to Subscriptions, Invoices, and Payments, with payments and charges URLs resolving to Payments."

patterns-established:
  - "Detail contract tests assert one h1, one summary list, one related strip, and lazy Activity/Raw data markers per page."
  - "Sensitive action tests assert a visible intent trigger, hidden initial form, drawer form after intent, and StepUp challenge on submit."

requirements-completed: [PRP-02]

# Metrics
duration: 10m
completed: 2026-06-28
status: complete
---

# Phase 198 Plan 02: High-Risk Detail Contracts Summary

**RED LiveView contracts for Customer, Invoice, Charge, Connect account, and Webhook detail pages before runtime rewrites**

## Performance

- **Duration:** 10m
- **Started:** 2026-06-28T23:20:52Z
- **Completed:** 2026-06-28T23:30:43Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Replaced Customer-360 tab assumptions with contract coverage for the locked peer navigation policy, summary/related/lazy detail structure, and hidden initial payment-method action forms.
- Added invoice and charge contract tests for summary-first detail layout, capped action bands, overflow/danger action behavior, drawer-only sensitive forms, and StepUp requirements.
- Added webhook and connect account contract tests for replay and platform-fee override intent flows, non-replayable state copy, drawer visibility, StepUp gating, summary rows, related strips, and lazy bottom sections.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock Customer-360 peer navigation and lazy detail contract** - `e844b870` (test)
2. **Task 2: Lock invoice and charge action drawer contracts** - `01256a53` (test)
3. **Task 3: Lock webhook and connect action drawer contracts** - `8af81398` (test)

**Plan metadata:** pending closeout commit

## Files Created/Modified

- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` - Customer peer navigation, summary/related/lazy markers, primary action cap, and hidden payment-method action form contracts.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` - Invoice summary/action/overflow/StepUp/related/lazy contracts.
- `accrue_admin/test/accrue_admin/live/charge_live_test.exs` - Charge refund primary action, hidden initial form, drawer, StepUp, summary/related/lazy contracts.
- `accrue_admin/test/accrue_admin/live/connect_account_live_test.exs` - Connect platform-fee override primary action, hidden initial form, drawer, StepUp, summary/related/lazy contracts.
- `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` - Webhook replay eligibility, no disabled replay-looking control for non-replayable rows, drawer, StepUp, summary/related/lazy contracts.

## Decisions Made

- Kept the plan as a contract-only RED test pass. Runtime migrations are intentionally left for later Phase 198 plans.
- Used test-local selector/count helpers instead of introducing a runtime detail manifest.
- Treated missing detail selectors and drawer/StepUp behavior as expected conformance failures when the test harness compiled and fixtures loaded successfully.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The verification commands currently fail for expected runtime conformance gaps that later implementation plans are meant to close:

- `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs --max-failures 5` exits 2 with 9 tests and 1 expected failure: Customer detail has no `data-ax-summary-list` yet.
- `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs --max-failures 6` exits 2 with 18 tests and 4 expected failures: invoice/charge summary selectors and primary action/drawer contracts are not implemented yet.
- `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/connect_account_live_test.exs --max-failures 6` exits 2 with 15 tests and 6 expected failures before the max-failures limit: webhook/connect summary selectors, primary action/drawer contracts, replay eligibility controls, and hidden initial override form behavior are not implemented yet.

No setup, fixture, dependency, or compile blockers were encountered.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None found in files created or modified by this plan.

## Next Phase Readiness

Later Phase 198 runtime migration plans can now turn these high-risk contracts green without expanding scope into Phase 199/200 overlay or final sign-off work. The expected failures identify the missing runtime surfaces: `data-ax-summary-list`, `data-ax-action-band`, `data-ax-primary-action`, `data-ax-action-overflow-menu`, `data-ax-related-resources`, `data-ax-lazy-activity`, `data-ax-lazy-json`, and `data-ax-action-drawer-form`.

## Self-Check: PASSED

- Found summary file and all five modified test files.
- Found task commits `e844b870`, `01256a53`, and `8af81398`.
- No unexpected tracked file deletions were detected in task commits.

---
*Phase: 198-propagate-detail-analytics*
*Completed: 2026-06-28*
