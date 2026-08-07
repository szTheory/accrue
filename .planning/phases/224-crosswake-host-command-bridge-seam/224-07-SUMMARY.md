---
phase: 224-crosswake-host-command-bridge-seam
plan: 07
subsystem: ios bridge security
tags: [swift, webkit, route-epoch, replay-protection, configuration-validation]
requires:
  - phase: 224-06
    provides: command-safe exact-pin Crosswake conformance runner
provides:
  - Atomic route-epoch/correlation claims before host command side effects
  - Factory-only validated host-command configuration
  - Exact reviewed Crosswake evidence for both verifier closures
affects: [phase-224-verification, phase-225-host-orchestration]
tech-stack:
  added: []
  patterns: [epoch-scoped invocation lifecycle, validated descriptor factory]
key-files:
  created: [224-07-SUMMARY.md]
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift
    - crosswake-source-lock.json
key-decisions:
  - "Claim (routeEpoch, correlationID) atomically after all admission guards and before telemetry or delegate dispatch."
  - "Expose host-command descriptors only through the throwing validated factory."
patterns-established:
  - "Route replacement clears the prior epoch invocation namespace while preserving stale-reply suppression."
  - "Public ordinary configuration stays non-host; descriptor-bearing construction validates before channel creation."
requirements-completed: [BRDG-01, BRDG-02]
coverage:
  - id: D1
    description: "Duplicate admitted correlations invoke host work once and reuse safely after navigation."
    requirement: BRDG-02
    verification:
      - kind: unit
        ref: "HostCommandAdmissionTests#test_duplicate_admitted_correlation_invokes_delegate_and_replies_once; test_correlation_is_reusable_after_route_replacement; test_concurrent_duplicate_correlations_claim_before_host_dispatch"
        status: pass
    human_judgment: false
  - id: D2
    description: "Host-command descriptors are accepted only by the validating factory with strict diagnostics."
    requirement: BRDG-01
    verification:
      - kind: unit
        ref: "HostCommandAdmissionTests#test_invalid_or_duplicate_host_descriptors_fail_setup_with_actionable_diagnostics"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact Crosswake source lock, deterministic evidence, tracer, and blocked capability status agree."
    requirement: BRDG-01
    verification:
      - kind: integration
        ref: "scripts/ci/verify_crosswake_host_commands.sh full"
        status: pass
    human_judgment: false
metrics:
  duration: 5m
  completed: 2026-08-06
status: complete
---

# Phase 224 Plan 07: Crosswake Host Command Bridge Closure Summary

**Atomic epoch-scoped host-command replay protection and mandatory descriptor validation, re-pinned to reviewed Crosswake revision `789175f2`.**

## Performance

- **Duration:** 5m
- **Tasks:** 3/3
- **Files modified:** 6

## Accomplishments

- Claimed admitted `(routeEpoch, correlationID)` pairs before telemetry and host dispatch, with single terminalization and epoch cleanup on navigation.
- Removed descriptor/delegate inputs from the ordinary config initializer; the validating factory now strictly checks version shape and duplicate command IDs.
- Added duplicate, route-reuse, and 32-way contention regressions, then bound passing exact-pin evidence to the new Crosswake revision.

## Task Commits

1. **Task 1: Claim before host side effect** — `83a9a29b` (RED tests), `9f7a197f` (implementation).
2. **Task 2: Mandatory descriptor validation** — `41d7409f` (RED tests), `abc8f925` (implementation).
3. **Task 3: Review and re-pin evidence** — `789175f2` (contention proof), `ffc546a1` (Accrue audit/evidence lock).

## Verification

- `swift test --package-path /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests` — pass (17 tests).
- `swift test --package-path /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios` — pass (31 tests).
- Command-safe `source-gate`, `trusted-frame`, and `full` modes — pass.
- Accrue tracer, evidence digest, and all-capabilities-`feasibility_blocked` assertion — pass.
- Authorized Crosswake checkout is clean at `789175f219de03047456e098fedf4a97891feff2`, descended from immutable base `932b4f32bf087b8e4c0c36c3e54b1031839e867d`.

## Decisions Made

- Retained Crosswake ownership and the existing ordered admission controls; the new claim runs only after they pass.
- Kept all evidence deterministic-only. No simulator, StoreKit, host integration, physical-device, UI, entitlement, or runtime-readiness claim was added.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Crosswake code/test commits and Accrue evidence commit exist.
- Required three Crosswake owners and all evidence artifacts exist.

## Next Phase Readiness

Both verification blockers are closed at the exact reviewed revision. The capability report remains `feasibility_blocked`, so downstream work must not infer runtime readiness.
