---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 12
subsystem: crosswake-tracer
tags: [swift, offline-cache, proof-high-water, capability-report, tdd]
requires:
  - 215-11
provides:
  - Shared disposition-aware proof replacement ordering
  - Schema-aware public capability-report reduction
affects: [phase-219-offline-contract]
tech_stack:
  added: []
  patterns: [single admission predicate, signed-denial precedence, fail-closed schema reduction]
key_files:
  created: []
  modified:
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
decisions:
  - ProofHighWater and authenticated cache replacement share ProofReplacementOrder so equal-revision denial precedence cannot diverge.
  - Only capability report schema 1.0 may reduce to proven; unsupported schemas retain feasibility_blocked.
metrics:
  duration: 4 min
  completed: 2026-08-01
  tasks_completed: 2
  files_modified: 4
status: complete
---

# Phase 215 Plan 12: Public Denial Precedence Summary

**One shared proof-replacement order keeps same-revision signed denials authoritative across public high-water, authenticated persistence, and reconnect-style restarts.**

## Accomplishments

- Added the disposition-aware `ProofReplacementOrder` predicate and routed both `ProofHighWater` and authenticated cache replacement through it.
- Proved allow revision n → signed deny revision n → stale/equal allow rejection across separate child processes, preserving the authenticated denial envelope.
- Made `CapabilityReport` fail unsupported schemas closed, matching the checked-in report validator's schema boundary.

## Task Commits

1. **Task 1: Trace allow revision n through same-revision denial and restart-safe stale-evidence rejection** — `39d1cdbf` (test), `a2333eae` (feat)
2. **Task 2: Fail unsupported public report schemas closed and rerun the complete Phase-215 contract** — `7f826dd0` (test), `db095149` (feat)

## Verification

- `cd examples/crosswake_tracer && swift test --filter GoldenVectorTests && swift test --filter AtomicOfflineCacheProcessTests`
- `cd examples/crosswake_tracer && swift test --filter CapabilityReportTests && swift test`
- `bash scripts/ci/verify_v159_authority.sh`
- `bash scripts/ci/verify_entitlement_source_matrix.sh`
- `cd accrue && mix accrue.entitlements.decision_cases --check && mix test test/accrue/entitlements/decision_cases_test.exs test/property/entitlement_decision_cases_property_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs`
- Byte-drift checks passed for decision cases, golden vectors, and `capability-report.json`.

## Decisions Made

- Public and durable proof admission use one D-13 ordering rule: higher revisions win; at equal revision, denial can replace non-denial only.
- Non-decreasing issued-at and freshness checks remain independent mandatory checks at the public high-water boundary.
- Unsupported public report schemas use the existing bounded `feasibility_blocked` result; Crosswake runtime coupling remains blocked.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All four planned Swift source/test artifacts and this summary exist.
- All four TDD commits exist in git history.
