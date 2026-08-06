---
phase: 223-ios-compatible-accrue-offline-client
plan: 03
subsystem: offline-client
tags: [swift, swiftpm, reconnect, keychain, security]
requires:
  - phase: 223-ios-compatible-accrue-offline-client
    provides: verified ES256 admission and atomic high-water cache boundary
provides:
  - Host-owned asynchronous reconnect proof seam
  - Optional explicit Apple ThisDeviceOnly Keychain policy descriptors
affects: [crosswake-tracer, ios-host-integration]
tech-stack:
  added: [Security]
  patterns: [host-owned byte transport, direct admission reuse, policy-only Keychain helper]
key-files:
  created:
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineReconnect.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineReconnectTests.swift
    - packages/accrue-offline-client/Tests/AccrueOfflineClientAppleTests/KeychainCacheKeyTests.swift
  modified:
    - packages/accrue-offline-client/Package.swift
key-decisions:
  - "Reconnect transports return only compact proof bytes; the facade delegates every response to applyServerProof."
  - "Apple helpers expose only explicit ThisDeviceOnly policy descriptors and bounded OSStatus outcomes."
requirements-completed: [IOS-02, IOS-03]
coverage:
  - id: D1
    description: Host-authenticated reconnect proof bytes use the identical verified cache-admission path.
    requirement: IOS-03
    verification:
      - kind: unit
        ref: packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineReconnectTests.swift#reconnectUsesDirectAdmission
        status: pass
      - kind: unit
        ref: packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineReconnectTests.swift#reconnectFailuresAndOrderingPreserveCache
        status: pass
    human_judgment: false
  - id: D2
    description: Apple Keychain policy requires explicit ThisDeviceOnly accessibility without cache-key custody.
    requirement: IOS-02
    verification:
      - kind: unit
        ref: packages/accrue-offline-client/Tests/AccrueOfflineClientAppleTests/KeychainCacheKeyTests.swift
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-06
status: complete
---

# Phase 223 Plan 03: Host-Owned Reconnect and Apple Policy Summary

Reconnect now accepts only host-fetched compact proofs and reuses the existing strict verifier/atomic cache boundary; the optional Apple product provides explicit ThisDeviceOnly Keychain configuration without key custody.

## Accomplishments

- Added `OfflineProofReconnectTransport`, a one-method async transport that keeps endpoints, credentials, request construction, and retry policy host-owned.
- Routed reconnect result bytes directly into `applyServerProof`, preserving verifier, high-water, signed-deny, and atomic replacement semantics under repeated and concurrent calls.
- Published `AccrueOfflineClientApple` with explicit `ThisDeviceOnly` descriptor mappings and bounded Keychain availability/status outcomes, with no fetch, write, generation, or retention of key material.

## Task Commits

1. **Task 1: Route host-authenticated reconnect bytes through the identical private admission and atomic replacement boundary**
   - `e7fc39ae` — `test(223-03): add reconnect admission coverage`
   - `6b09779d` — `feat(223-03): add host-owned proof reconnect seam`
2. **Task 2: Publish explicit Apple Keychain policy helpers without library key custody**
   - `0515d551` — `test(223-03): add Apple keychain policy coverage`
   - `4a2edef3` — `test(223-03): guard Apple helper key custody boundary`
   - `06ddb59c` — `feat(223-03): add explicit Apple keychain policy helper`

## Verification

- `swift test --package-path packages/accrue-offline-client --filter OfflineReconnectTests` — passed (2 tests).
- `swift test --package-path packages/accrue-offline-client --filter KeychainCacheKeyTests` — passed (3 tests).
- `swift test --package-path packages/accrue-offline-client` — passed (10 tests across 4 suites).
- `swift package --package-path packages/accrue-offline-client dump-package | jq ...` — passed; library products are exactly `AccrueOfflineClientApple` and `AccrueOfflineClientCore`.
- Public reconnect-source and Apple custody-operation scans passed; the iOS 16 target build completed successfully.

## Decisions Made

- Kept reconnect as a byte-only protocol and deliberately did not add any credential, endpoint, StoreKit, lifecycle, purchase, restore, or generic transport API.
- Kept `afterFirstUnlockThisDeviceOnly` explicit and documented it solely for host-required background recovery; pre-first-unlock status is a bounded outcome rather than a policy downgrade.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

All four plan artifacts exist and task commits `e7fc39ae`, `6b09779d`, `0515d551`, `4a2edef3`, and `06ddb59c` are present in git history.
