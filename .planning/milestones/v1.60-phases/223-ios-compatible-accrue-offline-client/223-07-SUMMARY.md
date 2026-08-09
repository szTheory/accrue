---
phase: 223-ios-compatible-accrue-offline-client
plan: "07"
subsystem: offline entitlement client security
tags: [swift, swiftpm, cache, hmac, clock-rollback, json-admission]
requires:
  - phase: 223-06
    provides: authenticated prepared cache transactions, recovery coverage, and strict verifier boundary
provides:
  - authenticated durable observed-time cache envelopes with version-2 compatibility migration
  - clock rollback rejection across fresh offline-client instances
  - compact-proof byte ceilings and depth-bounded duplicate-aware JSON admission
affects: [IOS-01, IOS-02, offline reconnect, iOS compilation gate]
tech-stack:
  added: []
  patterns: [authenticated monotonic observed time, bounded untrusted compact-JWS admission]
key-files:
  created:
    - .planning/phases/223-ios-compatible-accrue-offline-client/223-07-SUMMARY.md
  modified:
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift
key-decisions:
  - "Observed time is a version-3 HMAC-authenticated cache-envelope field; authenticated version-2 envelopes remain readable and migrate only through verified admission."
  - "The core bounds compact proof input to 256 KiB, decoded header to 1 KiB, decoded payload to 128 KiB, and JSON nesting to 32 containers before Foundation parsing."
metrics:
  duration: 6min
  completed: 2026-08-06
status: complete
---

# Phase 223 Plan 07: Observed Time and Bounded Admission Summary

**The offline client now durably rejects clock rollback after a later verified observation and fails oversized or overly nested compact proofs at the existing bounded invalid state.**

## Accomplishments

- Added a version-3 authenticated cache envelope carrying monotonic `observed_at`, while preserving exact version-2 HMAC validation for migration.
- Routed verified direct and cached proof admissions through durable time observation, returning `.invalid(.clockRollback, .reconnectRequired)` when a fresh client sees a lower clock.
- Added pre-decode compact and encoded-segment limits, decoded JSON limits, and a 32-container limit in the duplicate-aware admission scanner.
- Added public-boundary regressions that prove hostile inputs leave an authenticated cache byte-for-byte unchanged.

## Task Commits

1. **Task 1: Carry one verified cached proof through durable time observation, restart, rollback rejection, and authenticated recovery**
   - `052a1204` — red regression
   - `b38bcdf0` — durable observed-time implementation
2. **Task 2: Bound compact-proof allocation and JSON nesting before untrusted admission work**
   - `df2a45c5` — red regressions
   - `26cb698e` — bounded admission implementation

## Verification

- `swift test --package-path packages/accrue-offline-client` — passed (21 tests)
- `bash scripts/ci/verify_ios_offline_client.sh` — passed, including iOS 16 core compilation and tracer non-promotion checks
- `bash scripts/ci/verify_reference_scenario_contract.sh` — passed
- Focused durable-clock, signed-deny ordering, reconnect, canonical-vector, duplicate-member, and hostile-input tests — passed

## Decisions Made

- A legacy v2 envelope has no reconstructable historical observation; the first verified post-upgrade access establishes and durably records its baseline time.
- Bounds apply after the host has supplied `Data`; the library prevents subsequent UTF-8, base64, JSON, and recursive-work amplification without claiming to bound host transport allocation.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Verified all four scoped implementation/test files and commits `052a1204`, `b38bcdf0`, `df2a45c5`, and `26cb698e` exist.
