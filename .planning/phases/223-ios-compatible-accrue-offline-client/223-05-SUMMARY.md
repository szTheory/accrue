---
phase: 223-ios-compatible-accrue-offline-client
plan: "05"
subsystem: offline-client
tags: [swift, jws, cache, durability]
requires: [223-04]
provides: [duplicate-safe-jws-admission, canonical-claim-validation, denial-race-evidence]
affects: [IOS-01, IOS-02, IOS-03]
tech-stack:
  added: []
  patterns: [duplicate-preserving-json-admission, authenticated-cache-replacement, process-race-tests]
key-files:
  created: [packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift]
  modified:
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineCacheCrashHarness/main.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift
decisions:
  - Duplicate member detection runs before Foundation JSON map decoding.
  - Invalid existing cache bytes have no high-water authority and can be replaced only by verified proofs.
metrics:
  tasks_completed: 3
status: complete
---

# Phase 223 Plan 05: Offline Client Hardening Summary

Strict duplicate-safe JWS admission, canonical claim validation, cache recovery, and denial-race process evidence for the standalone Swift client.

## Completed Tasks

1. Added recursive duplicate JSON-member rejection before protected-header and payload map decoding, plus verified replacement of malformed or unauthenticated cache bytes.
2. Enforced bounded canonical claims, strict normalization, exact `cnf.jkt`, and read-only cache-load failure mapping with mutation-preservation tests.
3. Made the crash harness report rejected admission with a stable nonzero status and required equal-revision process races to end in signed denial.

## Verification

- `swift test --package-path packages/accrue-offline-client` — passed (15 tests).
- `bash scripts/ci/verify_ios_offline_client.sh` — passed.
- `bash scripts/ci/verify_reference_scenario_contract.sh` — passed.
- Crosswake feasibility evidence diff — clean.

## Commits

- `40537755` feat(223-05): harden signed proof admission and recovery
- `5176f966` feat(223-05): validate canonical claim profile
- `8814d1fe` test(223-05): enforce deny race process evidence

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Mapped duplicate-scanner failures to the public bounded malformed result rather than a cache-write failure.
2. [Rule 1 - Bug] Kept cache loading read-only while preserving the documented malformed versus cache-recovery failure distinction.

## Known Stubs

The plan's deterministic per-stage filesystem fault seam is internal but does not yet have direct test coverage for every named stage. The production transactional path and process ordering coverage passed; explicit stage-fault coverage remains for a follow-up hardening plan.

## Self-Check: PASSED

All declared source/test artifacts and the three task commits exist.
