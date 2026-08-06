---
phase: 223-ios-compatible-accrue-offline-client
plan: "06"
subsystem: offline entitlement cache
tags: [swift, swiftpm, cryptokit, atomic-cache, durability, concurrency]
requires:
  - phase: 223-05
    provides: strict compact-proof admission, authenticated v2 cache envelopes, and cache fault coverage
provides:
  - authenticated prepared/committed transaction sidecars with retryable prior-envelope rollback
  - fresh-process proof for rollback-restore and rollback-directory-sync failures
  - synchronized signed-invalid-context concurrency coverage
affects: [IOS-01, IOS-02, IOS-03, offline reconnect]
tech-stack:
  added: []
  patterns: [authenticated transaction record, same-directory atomic rollback overwrite, bounded harness exit status]
key-files:
  created: []
  modified:
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineCacheCrashHarness/main.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift
key-decisions:
  - "Retain an HMAC-authenticated prepared transaction record and prior envelope until rollback or commit directory synchronization is durable."
  - "Expose fresh-process recovery through the existing public cached-load facade and stable exit status only."
requirements-completed: [IOS-01, IOS-02, IOS-03]
coverage:
  - id: D1
    description: Authenticated late-failure rollback restores byte-exact prior cache authority without destination-first unlink.
    requirement: IOS-01
    verification:
      - kind: unit
        ref: OfflineEntitlementClientTests.lateDurabilityFailureRecoversExactPrior
        status: pass
      - kind: integration
        ref: AtomicOfflineCacheProcessTests.freshProcessRecoversLateRollbackFailures
        status: pass
    human_judgment: false
  - id: D2
    description: One valid proof raced with six independently signed invalid contexts is the sole persisted authority.
    requirement: IOS-02
    verification:
      - kind: unit
        ref: OfflineEntitlementClientTests.concurrentInvalidContextsCannotPersist
        status: pass
    human_judgment: false
  - id: D3
    description: Reconnect continues to use the verified cache boundary after durability hardening.
    requirement: IOS-03
    verification:
      - kind: integration
        ref: OfflineReconnectTests
        status: pass
      - kind: other
        ref: bash scripts/ci/verify_ios_offline_client.sh
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-08-06
status: complete
---

# Phase 223 Plan 06: Offline Cache Durability Gap Closure Summary

**Authenticated prepared transactions now retain and recover the exact prior offline envelope across late replacement and rollback durability failures, with fresh-process and concurrent-admission evidence.**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-08-06
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added authenticated, path-bound prepared/committed transaction records and retained backups; recovery atomically overwrites the destination, synchronizes the directory, and only then removes scoped sidecars.
- Moved rollback fault injection into the actual restore and restored-directory-sync operations, proving a fresh client receives the byte-exact prior allow after each late failure.
- Added a bounded public `load` harness operation plus a deterministic seven-way race of one valid proof and six signed invalid contexts.

## Task Commits

1. **Task 1: Trace a post-replacement sync failure through failed rollback and fresh-client recovery of the exact prior envelope** — `6aed104d` (feat)
2. **Task 2: Prove fresh-process rollback recovery and race every separately signed invalid context against valid authority** — `2b0a21b3` (test)

## Verification

- `swift test --package-path packages/accrue-offline-client` — passed (19 tests)
- `bash scripts/ci/verify_ios_offline_client.sh` — passed
- `bash scripts/ci/verify_reference_scenario_contract.sh` — passed
- Crosswake capability/evidence diff check — clean

## Decisions Made

- Sidecar records carry only bounded internal names, phase, and HMAC; they never contain cache keys, proof bytes, or caller authority.
- Prepared rollback state remains on disk after a failed restore or rollback directory sync, so the next locked cache operation can authenticate and retry it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected optional base64 decoding for transaction-record authentication.**
- **Found during:** Task 1
- **Fix:** Used an explicit `Data(base64Encoded:)` closure compatible with Swift's optional `flatMap` inference.
- **Verification:** Focused late-durability test and full package suite passed.
- **Committed in:** `6aed104d`

## Issues Encountered

The new concurrent-admission test passed on its first execution because strict verification already rejected these contexts before persistence; the test is retained as the missing behavioral race evidence.

## Known Stubs

None.

## Next Phase Readiness

The cache boundary now has transaction-state durability and fresh-process evidence; no public API, host ownership, UI, Crosswake feasibility, or evidence files changed.

## Self-Check: PASSED

- Verified all four scoped files exist and both task commits are present in git history.
