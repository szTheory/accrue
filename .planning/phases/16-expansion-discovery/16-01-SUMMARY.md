---
phase: 16-expansion-discovery
plan: 01
subsystem: testing
tags: [planning, docs-contract, stripe, sigra, validation]
requires:
  - phase: 15-trust-hardening
    provides: checked-in review artifact shape and direct file-read docs contract pattern
provides:
  - canonical ranked expansion recommendation artifact
  - ExUnit docs contract for the Phase 16 recommendation
  - validation map aligned to the artifact and docs contract
affects: [phase-16-plan-02, roadmap, requirements, state]
tech-stack:
  added: []
  patterns: [checked-in recommendation artifact, ExUnit file-read docs contract, grep-aligned validation map]
key-files:
  created:
    - .planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md
    - accrue/test/accrue/docs/expansion_discovery_test.exs
    - .planning/phases/16-expansion-discovery/16-01-SUMMARY.md
  modified:
    - .planning/phases/16-expansion-discovery/16-VALIDATION.md
key-decisions:
  - "Keep Stripe Tax as the only Next milestone candidate and leave org billing plus revenue/export in Backlog."
  - "Preserve the Stripe-first, host-owned boundary by treating official second processor work as a Planted seed around the custom processor seam."
patterns-established:
  - "Decision artifacts follow the Phase 15 checked-in review structure with explicit verification runs and sign-off."
  - "Phase-level recommendation docs get a narrow ExUnit contract that reads the artifact directly and locks required vocabulary."
requirements-completed: [DISC-01, DISC-02, DISC-03, DISC-04, DISC-05]
duration: 9min
completed: 2026-04-17
---

# Phase 16 Plan 01: Expansion Discovery Summary

**Ranked Phase 16 expansion decisions with a checked-in recommendation artifact, ExUnit docs contract, and artifact-first validation map**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-17T14:16:00Z
- **Completed:** 2026-04-17T14:25:06Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` as the canonical Phase 16 decision artifact with ranked outcomes for Stripe Tax, organization billing, revenue/export, and second-processor work.
- Added `accrue/test/accrue/docs/expansion_discovery_test.exs` as a narrow ExUnit contract that fails if the required ranking, migration, architecture, or security phrases disappear.
- Updated `.planning/phases/16-expansion-discovery/16-VALIDATION.md` so its commands and requirement rows point at the real artifact and docs test instead of unresolved Wave 0 setup.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: add failing docs contract for the expansion recommendation artifact** - `f714fa0` (`test`)
2. **Task 1 GREEN: write the canonical expansion recommendation artifact** - `4e2a9ab` (`feat`)
3. **Task 2: align the Phase 16 validation contract with the recommendation artifact** - `0305d15` (`docs`)

Plan metadata: pending final docs commit

## Files Created/Modified

- `.planning/phases/16-expansion-discovery/16-EXPANSION-RECOMMENDATION.md` - Canonical ranked recommendation with migration-path notes, assumptions, open questions, and security boundary checks.
- `accrue/test/accrue/docs/expansion_discovery_test.exs` - ExUnit file-read contract for the recommendation artifact.
- `.planning/phases/16-expansion-discovery/16-VALIDATION.md` - Verification map and quick-run commands aligned to the new artifact and docs test.
- `.planning/phases/16-expansion-discovery/16-01-SUMMARY.md` - Execution summary for Plan 16-01.

## Decisions Made

- Kept Stripe Tax support as the sole `Next milestone` recommendation because it deepens the existing Stripe-first surface without changing the billing API, schema, or processor abstraction.
- Left organization / multi-tenant billing and Revenue Recognition / exports as `Backlog` items because both need clearer host-owned authorization and consumer prerequisites.
- Treated official second processor adapter work as a `Planted seed` and explicitly preserved the current `custom processor` seam to avoid weakening the Stripe-first contract.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The RED-phase ExUnit contract failed immediately because `16-EXPANSION-RECOMMENDATION.md` did not exist yet. That was the expected TDD gate and was resolved by writing the artifact in the next commit.

## TDD Gate Compliance

- RED gate commit present: `f714fa0`
- GREEN gate commit present: `4e2a9ab`
- REFACTOR gate: not needed

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 16-02 can now verify the recommendation artifact as the single source of ranking truth and persist the ranking outcome in planning records.
- The requirement language for DISC-01 through DISC-05 is now enforced by checked-in docs evidence rather than spread across research notes.

## Self-Check: PASSED

- Verified created and modified files exist on disk.
- Verified task commits `f714fa0`, `4e2a9ab`, and `0305d15` exist in git history.

---
*Phase: 16-expansion-discovery*
*Completed: 2026-04-17*
