---
phase: 226-ci-baseline-proof-semantics
plan: "10"
subsystem: ci-contract-validation
tags: [bash, jq, ci, proof-semantics, security]
requires:
  - phase: 226-09
    provides: policy-bound candidate job semantics and topology validation
provides:
  - Timestamp-authenticated staged critical-chain duration validation
  - Pair-derived root failure categories and versioned signature IDs
affects: [phase-227, ci-baseline, proof-validation]
tech-stack:
  added: []
  patterns: [shared fail-closed jq predicate after policy binding]
key-files:
  created: [".planning/phases/226-ci-baseline-proof-semantics/226-10-SUMMARY.md"]
  modified: ["scripts/ci/verify_ci_baseline_contract.sh", ".planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md"]
key-decisions:
  - "Derive chain timing and signatures only after policy-authenticating every candidate job."
  - "Compute canonical aggregates only after each eligible run passes timestamp derivation."
patterns-established:
  - "Public mutation controls use fresh --input processes and recompute any dependent candidate aggregate fields."
requirements-completed: [BASE-01]
coverage:
  - id: D1
    description: "Collector and canonical inputs authenticate staged-chain seconds from policy-bound job timestamps."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_ci_baseline_contract.sh --self-test"
        status: pass
    human_judgment: false
  - id: D2
    description: "Collector and canonical inputs derive failure category and ID from normalized job conclusions."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_ci_baseline_contract.sh --self-test"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-10
status: complete
---

# Phase 226 Plan 10: CI Baseline Proof Semantics Summary

**Policy-authenticated timestamps and normalized job conclusions now independently certify each published CI chain duration and root-failure signature.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-10T22:18:38-04:00
- **Completed:** 2026-08-10T22:21:42-04:00
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added shared fail-closed derivation of staged-chain seconds from policy-bound job timestamps for both public document modes.
- Added derived normalized failure pairs, category, affected jobs, and versioned ID checks that reject self-consistent category forgeries.
- Added CR-01/CR-02 mutation coverage and documented preservation commands for stable Phase 226/192 contracts.

## Task Commits

1. **Task 1: Authenticate one staged-chain duration through both public modes** - `916343bc`, `5b580ba6` (test → feat)
2. **Task 2: Derive failure category and certify all preserved contracts** - `df6f1935`, `ffed6a22` (test → feat)

## Files Created/Modified

- `scripts/ci/verify_ci_baseline_contract.sh` - Shared durable-fact predicate plus public negative controls.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md` - CR-01/CR-02 closure and stable-contract regression map.

## Decisions Made

- Authenticate timing from earliest selected start to latest selected completion, never candidate duration or aggregates.
- Derive `no-failure`/`failed-lane` from sorted unique normalized pairs before building the signature ID.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- RED commits: `916343bc`, `df6f1935`
- GREEN commits: `5b580ba6`, `ffed6a22`

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 227 can rely on authenticated per-run chain and signature facts; stable evidence, topology, ownership, and Phase 192 artifacts remain unchanged.

## Self-Check: PASSED

- Required modified files and all four task commits exist.
