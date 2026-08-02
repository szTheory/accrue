---
phase: 216-additive-rail-and-persistence-foundation
plan: 02
subsystem: payments
tags: [elixir, nimble-options, entitlement-rails, stripe, apple, configuration]
requires:
  - phase: 216-01
    provides: additive rail accessors and initial qualified-catalog tracer
provides:
  - Legacy-compatible controllable default-rail validation
  - Deterministic rail/environment/product catalog normalization
  - Qualified collision diagnostics for explicit multi-rail aliases
affects: [216-03, 216-04, 217-canonical-projection]
tech-stack:
  added: []
  patterns: [raw legacy configuration remains isolated from explicit multi-rail normalization]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/config.ex
    - accrue/test/accrue/config_entitlements_test.exs
key-decisions:
  - "Host-fake is controllable only in deterministic test/proof configuration; Stripe remains the sole production gateway rail."
  - "Explicit multi-rail price aliases are checked by full qualified tuples, while legacy raw price_ids retain their existing LocalMap guard."
patterns-established:
  - "Additive configuration reads remain pure: validators never write normalized values back into application env."
requirements-completed: [RAIL-01, RAIL-02]
coverage:
  - id: D1
    description: Legacy alias and explicit default-rail contract
    requirement: RAIL-01
    verification:
      - kind: unit
        ref: accrue/test/accrue/config_entitlements_test.exs#rail registration and legacy default aliasing
        status: pass
    human_judgment: false
  - id: D2
    description: Qualified catalog normalization, collisions, and deterministic reads
    requirement: RAIL-02
    verification:
      - kind: unit
        ref: accrue/test/accrue/config_entitlements_test.exs#qualified product catalog normalization
        status: pass
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/local_map_test.exs"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-02
status: complete
---

# Phase 216 Plan 02: Additive Registration and Qualified Catalog Summary

**Rail-qualified catalog normalization now preserves processor-only hosts while making explicit Stripe/Apple mappings collision-safe and deterministic.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-02T15:39:00Z
- **Completed:** 2026-08-02T15:42:36Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Preserved legacy processor and `price_ids` validation/read behavior when no additive rail keys are configured.
- Enforced registered controllable defaults with exact processor-alias agreement, while retaining host-fake only for deterministic test/proof configuration.
- Normalized nested product IDs by `{rail, environment, product_id}` and report explicit alias collisions with their complete tuple.
- Added coverage for empty, singleton, duplicate, reordered, repeated, and concurrent configuration reads without application-env mutation.

## Task Commits

1. **Task 1: Complete rail registration and legacy default alias semantics** - `5a1ccff7` (test), `f82b6f5d` (feat)
2. **Task 2: Complete qualified catalog normalization and collision semantics** - `1672fd8f` (test), `c1ea1108` (feat)

## Files Created/Modified

- `accrue/lib/accrue/config.ex` - Validates test/proof host-fake rails and routes explicit alias collisions through qualified tuple reporting.
- `accrue/test/accrue/config_entitlements_test.exs` - Covers legacy compatibility, invalid defaults, catalog equality, tuple collisions, and concurrent purity.

## Decisions Made

- Host-fake may be a controllable default only under the existing test/proof seam; it cannot become a production rail.
- Raw `price_ids` retain their legacy collision guard only for processor-only hosts. Explicit multi-rail aliases use the complete qualified tuple as their identity and error surface.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The existing qualified reducer already covered most of the requested catalog matrix. One gap remained: same raw aliases in explicit multi-rail configuration were rejected by the legacy guard without their rail/environment tuple. The implementation now defers explicit configurations to the qualified reducer.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 216 Plan 03 can persist observations, grants, and devices against the stable rail/environment identities established here. The plan's RAIL-02 fallback classification remains unresolved and explicitly flagged in `216-02-PLAN.md`; no additional hidden boundary was inferred.

## Self-Check: PASSED

- Confirmed both modified production/test files exist.
- Confirmed all four RED/GREEN task commits exist in git history.

---
*Phase: 216-additive-rail-and-persistence-foundation*
*Completed: 2026-08-02*
