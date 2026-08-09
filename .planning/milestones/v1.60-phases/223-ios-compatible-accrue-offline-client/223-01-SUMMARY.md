---
phase: 223-ios-compatible-accrue-offline-client
plan: 01
subsystem: offline-client
tags: [swift, swiftpm, cryptokit, es256, offline-cache]
requires:
  - phase: 222-offline-reconnect-recovery-scheduling-closure
    provides: Offline proof contract and recovery scheduling boundary
provides:
  - Standalone iOS 16 SwiftPM core product with a narrow four-state facade
  - ES256-bound proof admission and authenticated canonical cache recovery
affects: [223-02, 223-03, crosswake-tracer]
tech-stack:
  added: [SwiftPM, CryptoKit]
  patterns: [private verified-proof admission, HMAC-authenticated canonical cache envelope]
key-files:
  created:
    - packages/accrue-offline-client/Package.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift
    - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
  modified: []
key-decisions:
  - "D-02 is published as exactly fresh, stale_offline, denied, and invalid; reconnect_required remains a next action."
  - "Only strict verifier-created proof values reach the internal authenticated cache boundary."
patterns-established:
  - "Runtime source never reads repository fixtures or test keys; fixture access is test-target-only."
requirements-completed: [IOS-01, IOS-02]
coverage:
  - id: D1
    description: Canonical ES256 allow proof is verified, admitted, and returned as fresh/ok/none.
    requirement: IOS-01
    verification:
      - kind: integration
        ref: swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests.tracerAcceptsCanonicalAllowAndRecoversIt
        status: pass
    human_judgment: false
  - id: D2
    description: A fresh client instance authenticates and re-verifies its cached proof through the public read-only facade.
    requirement: IOS-02
    verification:
      - kind: integration
        ref: swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests.freshClientLoadsAuthenticatedCachedStateWithoutGrantingFromPresence
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-08-06
status: complete
---

# Phase 223 Plan 01: Offline Client Authority Tracer Summary

**A standalone SwiftPM core verifies canonical ES256 proofs, persists only authenticated cache envelopes, and exposes the locked four-state offline result facade.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-08-06T15:22:05Z
- **Completed:** 2026-08-06T15:25:36Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Added the iOS 16 `AccrueOfflineClientCore` SwiftPM library product, with no optional Apple/bridge product ahead of its implementation phase.
- Implemented the public `applyServerProof(_:now:)` and `loadCachedState(now:)` facade operations with exactly four `Sendable` result states and bounded reasons/actions.
- Verified the canonical `valid_allow` JWS through ES256, issuer/audience/account/device bindings, then tested authenticated fresh-client cache recovery and malformed-input non-replacement.

## Task Commits

1. **Task 1: Trace one canonical allow proof through verification, durable admission, recovery, and the four-state facade** - `48ce465a` (feat)
2. **Generated-output hygiene** - `d14a85da` (chore)

## Files Created/Modified

- `packages/accrue-offline-client/Package.swift` - Standalone core-only SwiftPM product manifest.
- `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift` - Public bounded result facade and private ES256/JWS verifier.
- `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift` - Internal HMAC-authenticated canonical-envelope cache.
- `packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/GoldenVectorFixtureSupport.swift` - Test-only canonical corpus loading.
- `packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift` - Tracer, fresh recovery, and malformed-proof coverage.
- `packages/accrue-offline-client/.gitignore` - Ignores generated SwiftPM build output.

## Decisions Made

- Confirmed the irreversible D-02 four-state contract before creating public symbols; `reconnect_required` is a next action, not a fifth state.
- Bound cache authentication to the configured path and only re-derived public state from a freshly re-verified cached proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected internal admission visibility and test-corpus root discovery**
- **Found during:** Task 1
- **Issue:** The verifier admission value was file-private across two core files, and test support initially walked one directory too few to the repository corpus.
- **Fix:** Kept the type module-internal but non-public, and corrected the test-only repository-root traversal.
- **Files modified:** `OfflineEntitlementClient.swift`, `GoldenVectorFixtureSupport.swift`
- **Verification:** Full Swift package suite passes.
- **Committed in:** `48ce465a`

**2. [Rule 3 - Blocking] Ignored generated SwiftPM build output**
- **Found during:** Task 1 verification
- **Issue:** `swift test` created an untracked `.build/` directory.
- **Fix:** Added package-local ignore coverage.
- **Files modified:** `packages/accrue-offline-client/.gitignore`
- **Verification:** Worktree contains no untracked generated package output.
- **Committed in:** `d14a85da`

## Issues Encountered

None remaining.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 223-02 can extend negative, ordering, tamper, and recovery coverage on the established core authority path.

## Self-Check: PASSED

All six created artifacts exist and both implementation commits (`48ce465a`, `d14a85da`) are present in git history.
