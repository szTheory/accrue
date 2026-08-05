---
phase: 218-apple-observation-and-repair
plan: 06
subsystem: entitlements
tags: [apple, entitlements, projector, lifecycle, postgres]
requires:
  - phase: 218-05
    provides: durable Apple reconciliation checkpoints and verified history intake
provides:
  - Complete fixed-width Apple provider ordering keys persisted with observations and grants
  - Verified rail-neutral Apple lifecycle bounds projected source-locally
affects: [apple-intake, entitlement-projector, reconciliation]
tech-stack:
  added: []
  patterns: [scoped Apple lifecycle high-water ordering, verified-bound normalization]
key-files:
  created: [accrue/priv/repo/migrations/20260803032000_add_apple_ordering_to_entitlement_records.exs]
  modified: [accrue/lib/accrue/entitlements/projector.ex, accrue/lib/accrue/entitlements/apple/reconciliation.ex]
key-decisions:
  - "Apple compares a complete fixed-width key only within rail, environment, lineage, and product; Stripe keeps integer ordering."
  - "Grace and billing-retry access are bounded exclusively by their respective verified provider expiry facts."
patterns-established:
  - "Use qualified Apple observations as a terminal high-water mark after source-local retraction."
requirements-completed: [AAPL-04]
coverage:
  - id: D1
    description: Complete Apple ordering prevents delayed positive evidence from replacing terminal lifecycle facts.
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/apple_reconciliation_test.exs#complete Apple order keeps delayed positive evidence behind terminal evidence
        status: pass
    human_judgment: false
  - id: D2
    description: Verified Apple lifecycle facts retain only their permitted expiry bounds.
    requirement: AAPL-04
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/apple_reconciliation_test.exs#lifecycle normalization preserves only verified provider bounds
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 06: Apple Observation and Repair Summary

**Complete scoped Apple lifecycle ordering with durable bounds that prevents delayed evidence from resurrecting retracted access.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-03T14:42:00Z
- **Completed:** 2026-08-03T14:46:56Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Added bounded `provider_order_key` and effective expiry persistence for observations and grants.
- Projected Apple using `signed_epoch_us:effective_epoch_us:lifecycle_precedence:evidence_digest_prefix`, scoped by rail, environment, lineage, and product.
- Normalized active, renewal-disabled, grace, billing-retry, expiry, refund, and revocation facts without changing Stripe enum or gateway behavior.

## Task Commits

1. **Task 1: Persist and compare the complete Apple ordering key** - `b67de44f` (RED), `c269958c` (GREEN)
2. **Task 2: Normalize lifecycle bounds through the existing Projector** - `dea07efe` (RED), `b730b96c` (GREEN)

## Files Created/Modified

- `accrue/priv/repo/migrations/20260803032000_add_apple_ordering_to_entitlement_records.exs` - Adds bounded order-key and normalized expiry columns.
- `accrue/lib/accrue/entitlements/observation.ex` - Persists bounded source ordering and expiry facts.
- `accrue/lib/accrue/entitlements/grant.ex` - Retains winning Apple ordering provenance.
- `accrue/lib/accrue/entitlements/projector.ex` - Applies scoped Apple complete-key ordering and terminal high-water protection.
- `accrue/lib/accrue/entitlements/apple/reconciliation.ex` - Normalizes lifecycle kinds, bounds, and canonical ordering keys.
- `accrue/lib/accrue/entitlements/apple/intake.ex` - Sends verified normalized Apple facts through the existing projector.
- `accrue/test/accrue/entitlements/apple_reconciliation_test.exs` - Covers terminal precedence, scope isolation, Stripe compatibility, and verified bounds.

## Decisions Made

- Apple terminal observations remain in the qualified observation history as the source-local high-water mark after a grant is retracted.
- Grace does not use regular subscription expiry as a substitute; billing retry does not use a newer unverified expiry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical correctness] Wire verified intake through lifecycle normalization**
- **Found during:** Task 1
- **Issue:** Apple intake emitted a constant numeric ordering value, so the new durable key would not reach the projector.
- **Fix:** Normalized verified intake evidence before constructing the observation and persisted its key and bound.
- **Files modified:** `accrue/lib/accrue/entitlements/apple/intake.ex`
- **Verification:** Apple reconciliation, projector, and projection-property suites passed.
- **Committed in:** `c269958c`

**Total deviations:** 1 auto-fixed (Rule 2)

## Issues Encountered

- The full `mix test` run reported 13 failures from unrelated, pre-existing unstaged decision-case and entitlement configuration changes. Details are recorded in `deferred-items.md`; focused phase suites pass.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Self-Check: PASSED

- All seven implementation artifacts exist.
- Task commits `b67de44f`, `c269958c`, `dea07efe`, and `b730b96c` exist in git history.

## Next Phase Readiness

Apple reconciliation now has deterministic lifecycle facts ready for subsequent admission and repair flows.
