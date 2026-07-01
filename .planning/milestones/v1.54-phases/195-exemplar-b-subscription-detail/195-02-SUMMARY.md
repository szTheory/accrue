---
phase: 195-exemplar-b-subscription-detail
plan: "02"
subsystem: accrue_admin-testing
tags: [tdd-red, liveview, subscription-detail, action-hierarchy, copy-fixture, step-up]

requires:
  - phase: 195-01
    provides: overlay/action-hosting RED harness and Phase 195 e2e script
  - phase: 193-research-re-baseline-pattern-lock
    provides: SPEC-DETAIL contract and D-01b action relabel requirements
provides:
  - LiveView RED coverage for Subscription detail six-band structure
  - LiveView RED coverage for action hierarchy and provider gating
  - LiveView RED coverage for drawer-hosted safe and destructive actions preserving StepUp and audit linkage
  - Copy fixture anti-drift coverage for D-01b action relabels
affects: [195-03, 195-06, 195-07, 195-08, 199]

tech-stack:
  added: []
  patterns:
    - "RED-only Wave 0 LiveView coverage: tests fail on missing planned Phase 195 hooks and copy, not syntax or setup"
    - "Selector contracts use data-ax-* attributes for six-band detail layout and drawer-hosted action flows"
    - "Copy relabel assertions bind server Copy functions to the exported browser fixture"

key-files:
  created: []
  modified:
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs

key-decisions:
  - "Plan 195-02 intentionally remains RED-only; implementation is owned by later Phase 195 plans."
  - "EXE-02 and IXN-01 are addressed with validation coverage here, but underlying implementation requirements remain pending."

patterns-established:
  - "Subscription detail page shape is specified by summary, action, related-resource, lazy-activity, lazy-json, and drill-section selectors."
  - "Safe and destructive action flows must be initiated from the Phase 195 action hierarchy and continue inside the overlay drawer host."
  - "D-01b action relabels must route through Copy and be present in generated browser fixture JSON."

requirements-completed: []
requirements-addressed: [EXE-02, IXN-01]

duration: 9m 50s
completed: 2026-06-26
status: complete
---

# Phase 195 Plan 02: Subscription Detail LiveView RED Coverage Summary

**LiveView RED coverage for Subscription detail six-band structure, action hierarchy, drawer StepUp flow, and copy-fixture relabels.**

## Performance

- **Duration:** 9m 50s
- **Started:** 2026-06-26T08:20:41Z
- **Completed:** 2026-06-26T08:30:31Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Replaced old Subscription detail page-shape assertions with RED coverage for six required bands: summary list, action band, related resources, lazy activity, lazy raw JSON, and drill sections.
- Added action hierarchy RED coverage for at most two primary actions, grouped overflow actions, danger action demotion, Braintree provider gating, and provider-honest absent-action behavior.
- Reworked safe and destructive action tests to require drawer-hosted forms, preserving `confirm_action`, StepUp escalation, source-event audit linkage, and final cancellation behavior.
- Added Copy and generated fixture assertions for the D-01b action relabels: `Change plan`, `Cancel renewal`, `Cancel immediately`, and `Comp this subscription`.
- Moved dunning assertions from a standalone state card to the planned summary/drill-section surface.

## Task Commits

1. **Task 1: Replace detail page-shape assertions with six-band selectors** - `7a3021f8` (test)
2. **Task 2: Add action hierarchy and provider-gating RED coverage** - `9185b550` (test)
3. **Task 3: Add drawer StepUp and copy fixture RED coverage** - `c1286046` (test)

## Files Created/Modified

- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - Adds Phase 195 RED LiveView assertions for six-band detail layout, action hierarchy, provider gating, drawer-hosted action flows, StepUp/audit preservation, dunning drill placement, and Copy fixture relabel parity.

## Verification Results

- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` after Task 1 - RED as expected: 14 tests, 2 failures on missing `Billing & items` and `data-ax-summary-list`.
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` after Task 2 - RED as expected: 14 tests, 4 failures on missing six-band hooks and action selector hooks.
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` after Task 3/final - RED as expected: 14 tests, 11 failures on missing six-band hooks, drawer/menu selectors, dunning drill hooks, and relabeled copy fixture values.
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs:242` - PASS: owner-scope denial detail lookup still rejects out-of-scope rows.

## Decisions Made

- No production implementation was added in this plan because its objective is Wave 0 RED validation.
- `REQUIREMENTS.md` remains pending for `EXE-02` and `IXN-01`; this plan addresses them with validation coverage but does not complete the underlying implementation requirements.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The LiveView test runs continue to print a pre-existing PhoenixStorybook `RegistryStory.variations_for/1` warning from `storybook/components/button.story.exs`; it does not block the intended RED assertions.

## Known Stubs

None. The failing references are intentional RED contracts for later implementation plans, not shipped stubs.

## Threat Flags

None. This plan modified tests only; it introduced no production routes, endpoints, auth paths, file-access paths, schema changes, or runtime network surface.

## TDD Gate Compliance

Advisory: this plan has `type: tdd` but is explicitly a Wave 0 RED validation plan. RED `test(195-02)` commits exist; a GREEN `feat(195-02)` commit is intentionally absent because implementation is split into later Phase 195 plans.

## User Setup Required

None - no external service configuration required.

## Self-Check

- [x] `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` exists.
- [x] `.planning/phases/195-exemplar-b-subscription-detail/195-02-SUMMARY.md` exists.
- [x] Task commit `7a3021f8` exists.
- [x] Task commit `9185b550` exists.
- [x] Task commit `c1286046` exists.
- [x] No generated runtime artifacts were left untracked by the test runs, except the pre-existing ignored `.planning/research/.cache/` directory.

## Self-Check: PASSED

## Next Phase Readiness

Later Phase 195 implementation plans can green these LiveView contracts by rendering the six-band detail structure, replacing page-level action forms with drawer-hosted action flows, exporting relabeled Copy strings to the browser fixture, and moving dunning status into the planned drill section.

---
*Phase: 195-exemplar-b-subscription-detail*
*Completed: 2026-06-26*
