---
phase: 223-ios-compatible-accrue-offline-client
plan: 02
subsystem: offline-client
tags: [swift, swiftpm, cryptokit, es256, atomic-cache]
requires:
  - phase: 223-ios-compatible-accrue-offline-client
    provides: narrow offline client authority tracer
provides:
  - Canonical corpus and adversarial proof coverage
  - Fresh-process cache recovery and concurrent writer evidence
affects: [223-03, crosswake-tracer]
tech-stack:
  added: [SwiftPM executable test harness]
  patterns: [authenticated cache high-water, test-only JWK signing, process isolation]
key-files:
  created:
    - packages/accrue-offline-client/Sources/AccrueOfflineCacheCrashHarness/main.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift
  modified:
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/GoldenVectorFixtureSupport.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift
decisions:
  - Persisted high-water compares issuance, freshness, revision, and signed-denial precedence before replacement.
  - Crash harness receives only compact proof bytes plus test-only environment configuration.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 223 Plan 02: Canonical Offline Client Hardening Summary

Canonical proof behavior, strict mutation rejection, authenticated cache ordering, and fresh-process recovery are now enforced by Swift tests.

## Accomplishments

- Added corpus-driven checks for exact public state, reason, and next-action semantics, plus signed profile/binding/temporal mutations.
- Enforced persisted high-water ordering so stale/equal allows cannot displace a signed denial; repeated verified proofs are idempotent.
- Added a non-library crash harness and fresh-process tests for interrupted candidate cleanup, restart recovery, concurrent replacement, and cache-key non-persistence.

## Task Commits

1. `a4f30cd0` — `feat(223-02): expand offline proof corpus coverage`
2. `e056fc77` — `test(223-02): add offline cache process recovery coverage`

## Verification

- `swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests` — passed (3 tests).
- `swift test --package-path packages/accrue-offline-client --filter AtomicOfflineCacheProcessTests` — passed (2 tests).
- `swift test --package-path packages/accrue-offline-client` — passed (5 tests).
- Runtime-source scan found no fixture, test-key, or repository-path loading symbols in `Sources/AccrueOfflineClientCore`.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Restored the persistence boundary’s same-path lock before cache replacement.
- **Found during:** Task 1
- **Issue:** The extracted cache lacked durable high-water ordering and serialized same-path writers.
- **Fix:** Added authenticated-envelope high-water comparison, advisory lock coordination, candidate cleanup, and parent-directory synchronization where supported.
- **Commit:** `a4f30cd0`

2. [Rule 2 - Missing critical functionality] Bound the public verifier to the caller’s clock high-water.
- **Found during:** Task 1 canonical `clock_rollback` case.
- **Fix:** Added an optional configuration clock high-water check that returns the bounded `clock_rollback` reason.
- **Commit:** `a4f30cd0`

## Known Stubs

None.

## Self-Check: PASSED

All four core/harness artifacts exist and task commits `a4f30cd0` and `e056fc77` are present in git history.
