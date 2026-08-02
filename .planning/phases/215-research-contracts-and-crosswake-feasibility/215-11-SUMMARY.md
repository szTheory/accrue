---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 11
subsystem: offline entitlement cache
tags: [swift, cryptokit, hmac, file-locking, capability-report]
requires:
  - phase: 215-10
    provides: canonical Swift offline-vector corpus binding
provides:
  - authenticated, versioned cache envelopes with durable denial high-water
  - per-path advisory locking across cache processes
  - deterministic capability-report terminal-state validation
affects: [phase-219-offline-study-contract, crosswake-runtime-coupling]
tech-stack:
  added: []
  patterns: [caller-supplied HMAC key, authenticated cache envelope, POSIX advisory lock]
key-files:
  created:
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift
  modified:
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Sources/AccrueOfflineCacheCrashHarness/main.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
key-decisions:
  - "Authenticate cache payload, revision, disposition, envelope version, and standardized path with a host-supplied HMAC key."
  - "Acquire the in-process lock before the per-cache advisory lock, and retain both through restore, comparison, rename, directory sync, and adoption."
  - "Treat only uniform complete proof or uniform feasibility_blocked evidence as valid capability-report terminal states."
patterns-established:
  - "Revisioned cache writes reload authenticated persisted state before applying D-13 ordering."
  - "Process harness secrets travel only through inherited environment variables, never argv or logs."
requirements-completed: [RAIL-05]
coverage:
  - id: D1
    description: Authenticated persisted denial high-water refuses stale replacement after a fresh process restart.
    requirement: RAIL-05
    verification:
      - kind: integration
        ref: examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift#denialRestartRefusesStaleAllow
        status: pass
    human_judgment: false
  - id: D2
    description: Checked-in Crosswake capability report accepts only coherent proven or feasibility-blocked terminal states.
    requirement: RAIL-05
    verification:
      - kind: unit
        ref: examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-08-01
status: complete
---

# Phase 215 Plan 11: Authenticated Offline Cache Summary

**HMAC-authenticated entitlement cache envelopes preserve denial high-water across process restarts under per-path advisory locking.**

## Performance

- **Duration:** 6 min
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Bound cache payload, revision, disposition, envelope version, and cache path into a caller-keyed HMAC envelope.
- Restored authenticated persisted ordering before every candidate decision and serialized the full durable replacement transaction across processes.
- Added fresh-process denial precedence coverage and deterministic capability-report contract validation.

## Task Commits

1. **Task 1: Trace a signed denial from atomic persistence through fresh-process high-water restore** — `03095198` (test), `82b14b3b` (feat)
2. **Task 2: Serialize restart and denial rollback across real process boundaries** — `e414e7df` (test), `8b37821a` (feat)

## Verification

- `cd examples/crosswake_tracer && swift test --filter AtomicOfflineCacheProcessTests`
- Full Phase-215 authority, source-matrix, Elixir decision/vector, Swift package, and capability-report diff gate passed.

## Decisions Made

- The authentication key is injected by the host and is neither persisted nor emitted by the process harness.
- The current report remains uniformly `feasibility_blocked`; runtime coupling remains prohibited until authoritative Crosswake/device evidence exists.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All five planned Swift source/test artifacts exist.
- All four task commits exist in git history.

## Next Phase Readiness

Phase 219 can consume the authenticated cache boundary. Crosswake runtime coupling remains explicitly feasibility-blocked, not human-gated.
