---
phase: 226-ci-baseline-proof-semantics
plan: "07"
subsystem: ci-contract-testing
tags: [bash, jq, ci, privacy, schema-validation]
requires:
  - phase: 226-06
    provides: Corrected canonical CI baseline evidence and prior regression contracts.
provides:
  - Exact recursive canonical key/type boundary enforced through the public CI validator.
  - Canonical privacy mutation suite covering secret-like, raw-payload, and query-URL content.
affects: [phase-227-critical-path-optimization, ci-baseline-evidence]
tech-stack:
  added: []
  patterns: [fixed-document recursive type tree, public-CLI adversarial mutation matrix]
key-files:
  created: []
  modified:
    - scripts/ci/verify_ci_baseline_contract.sh
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
key-decisions:
  - "Validate canonical copies only through the public --input discriminator."
  - "Use the checked-in fixed cohort's recursive type/key tree to close every durable object and array boundary."
requirements-completed: [BASE-01]
coverage:
  - id: D1
    description: Exact canonical schema and recursive privacy validation for the durable three-run baseline.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh --self-test
        status: pass
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Phase 226 and Phase 192 stable CI contracts remain preserved.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_phase192_ci_contract.sh
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-10
status: complete
---

# Phase 226 Plan 07: Canonical Privacy Boundary Summary

**The durable three-run CI baseline now rejects unknown fields, type confusion, secret-like strings, raw payloads, and query URLs before its existing proof and aggregate checks run.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-10T23:56:00Z
- **Completed:** 2026-08-11T00:00:00Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added a fail-first public-CLI tracer for hostile canonical fields, then closed the canonical key/type/privacy boundary.
- Added named mutations for nested objects, array elements, intentionally empty arrays, scalar families, and privacy controls.
- Certified unchanged canonical evidence and Phase 192 contract behavior with deterministic local gates.

## Task Commits

1. **Task 1: Trace a hostile canonical field through exact-schema privacy rejection** — `2c440ab5` (test), `57c8aa00` (feat)
2. **Task 2: Exhaust canonical mutations and certify Phase 226/192 regression preservation** — `23d44539` (test)

## Files Created/Modified

- `scripts/ci/verify_ci_baseline_contract.sh` — validates canonical type/key structure, recursively scans durable strings, and exercises public-CLI mutation cases.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md` — records Plan 07 controls and positive regression gates.

## Decisions Made

- The canonical artifact is treated as a fixed, versioned document: its recursive type/key tree closes all currently valid object and array boundaries, including empty arrays.
- Mutation tests invoke a fresh public `--input` process so no internal validator path can bypass dispatch or repository checks.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Broadened raw-payload detection to cover the planned synthetic phrase.**
- **Found during:** Task 2
- **Issue:** The initial expression matched qualified request/response/event payload phrases but not `synthetic raw payload`.
- **Fix:** Included the generic raw-payload phrase in the recursive sensitive-string matcher.
- **Files modified:** `scripts/ci/verify_ci_baseline_contract.sh`
- **Verification:** Canonical allowed-field raw-payload mutation now fails through public `--input`.
- **Committed in:** `23d44539`

**Total deviations:** 1 auto-fixed (Rule 1)

## Issues Encountered

None beyond the planned red/green canonical boundary work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 227 can consume the unchanged baseline knowing that its stored-document boundary is exact and privacy-safe. No blockers remain for this plan.

## Self-Check: PASSED

- Confirmed both modified files exist and all three task commits are present in git history.
