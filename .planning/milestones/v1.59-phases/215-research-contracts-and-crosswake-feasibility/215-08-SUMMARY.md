---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 08
subsystem: crosswake-tracer
tags: [swift, offline-cache, crash-recovery, feasibility]
requires: [215-07]
provides: [per-path-cache-coordination, durable-rename-boundary, crash-harness]
affects: [RAIL-05, RSCH-01, RSCH-02, RSCH-03, RAIL-04]
tech-stack:
  added: []
  patterns: [per-standardized-path coordinator, unique same-directory candidates, candidate-and-directory fsync]
key-files:
  created:
    - examples/crosswake_tracer/Sources/AccrueOfflineCacheCrashHarness/main.swift
  modified:
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Package.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
decisions:
  - Shared coordinators are keyed by standardized cache path, not held globally.
  - The checked-in capability report remains feasibility_blocked until bridge and device evidence exist.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 215 Plan 08: Durable Crosswake Cache Tracer Summary

Per-path serialized offline-cache replacement with collision-free candidates, ordered durability barriers, recovery cleanup, and a test-only crash harness while retaining the honest feasibility block.

## Tasks Completed

1. **Serialize one real concurrent allow/deny race per cache path** — `cbcf1985`, `1f428528`
2. **Prove parent-directory durability and crash/reopen recovery** — `987a010f`, `433840d3`, `9be7e524`

## Decisions Made

- Cache handles use one coordinator per standardized URL, so unrelated paths do not share a critical section.
- Replacement candidates use UUID-bearing names in the destination directory, synchronize before rename, and are cleaned on every normal exit; recovery deletes abandoned candidates under that coordinator.
- Capability evidence remains `feasibility_blocked`; native cache proof cannot elevate the Crosswake/device lane.

## Verification

- `bash scripts/ci/verify_v159_authority.sh`
- `bash scripts/ci/verify_entitlement_source_matrix.sh`
- `mix accrue.entitlements.decision_cases --check` and targeted decision/vector tests
- `swift test` in `examples/crosswake_tracer`
- The crash harness exits after deterministic pre-rename and post-directory-sync fault points; fresh handles observe only old or durable new complete bytes.
- Capability-report static status check and clean diff gate

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 3 - Blocking environment issue] Replaced unavailable Ruby runtime for the static JSON assertion**
- **Found during:** Task 2 verification
- **Issue:** The prescribed Ruby invocation was blocked by the local version manager with no Ruby selected.
- **Fix:** Ran the equivalent read-only Node JSON assertion; it confirmed every report row and overall status remain `feasibility_blocked`.
- **Files modified:** None

## Known Stubs

None.

## Self-Check: PASSED

- Required cache source, harness, package target, and test files exist.
- All four task commits exist in git history.
