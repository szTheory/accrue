---
phase: 223-ios-compatible-accrue-offline-client
plan: 04
subsystem: ios-offline-client
tags: [swift, swiftpm, ios, ci, crosswake, evidence-boundary]
requires:
  - phase: 223-ios-compatible-accrue-offline-client
    provides: standalone core facade, verified admission, atomic cache, reconnect, and Apple policy helpers
provides:
  - Local-path Crosswake conformance consumer of AccrueOfflineClientCore
  - Merge-blocking macOS package and generic iOS 16 core compatibility gate
  - Read-only feasibility evidence assertions around deterministic client checks
affects: [phase-224-crosswake-bridge, phase-225-ios-host-adapter, phase-226-readiness-truth]
tech-stack:
  added: []
  patterns: [path-dependent SwiftPM consumer, core-only iOS target compilation, non-promoting evidence hash guard]
key-files:
  created:
    - packages/accrue-offline-client/README.md
    - scripts/ci/verify_ios_offline_client.sh
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTracerTests/PackageConformanceTests.swift
  modified:
    - examples/crosswake_tracer/Package.swift
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/README.md
    - scripts/ci/verify_reference_scenario_contract.sh
    - .github/workflows/ci.yml
key-decisions:
  - "The tracer is a local-path conformance consumer that re-exports the standalone core facade instead of retaining verifier or cache authority."
  - "The generic iPhoneOS lane compiles only AccrueOfflineClientCore at arm64-apple-ios16.0; package and consumer success cannot promote device feasibility evidence."
patterns-established:
  - "Hash report and physical-device evidence before deterministic commands, then compare afterward and require feasibility_blocked."
  - "Keep SwiftPM process harnesses out of the selected iOS core target graph."
requirements-completed: [IOS-01, IOS-02, IOS-03]
coverage:
  - id: D1
    description: Crosswake tracer consumes the extracted offline client through a local SwiftPM path without a second verifier/cache implementation.
    requirement: IOS-01
    verification:
      - kind: integration
        ref: swift test --package-path examples/crosswake_tracer
        status: pass
    human_judgment: false
  - id: D2
    description: Package tests and a core-only arm64 iOS 16 build are merge-gated while fixtures, keys, host APIs, and crash harnesses remain outside the runtime surface.
    requirement: IOS-02
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ios_offline_client.sh
        status: pass
    human_judgment: false
  - id: D3
    description: Deterministic verification preserves feasibility_blocked report status and does not mutate capability or physical-device evidence.
    requirement: IOS-03
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_reference_scenario_contract.sh
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-06
status: complete
---

# Phase 223 Plan 04: Package Consumer and iOS Gate Summary

The standalone offline client now has host-ownership documentation, a real path-dependent Crosswake consumer, and a macOS merge gate for full package tests plus core-only iOS 16 compilation without inflating device-feasibility claims.

## Accomplishments

- Replaced the tracer's duplicated verifier/cache implementation with a local SwiftPM dependency that re-exports `AccrueOfflineClientCore` for conformance compilation.
- Documented the safe facade path, four states, stale-study-only rule, literal host-copy seam, host ownership, and strict deterministic-versus-device evidence boundary.
- Added `verify_ios_offline_client.sh` and an `ios-offline-client` macOS CI job; the gate runs package tests, core-only `arm64-apple-ios16.0` compilation, surface isolation checks, tracer consumption, and report/evidence hash checks.
- Wired the reference scenario contract to run the standalone gate while preserving `capability-report.json` and physical-device evidence byte-for-byte.

## Task Commits

1. **Task 1: Convert Crosswake tracer into a path-dependent conformance consumer and publish honest host integration guidance**
   - `a03634a2` — `feat(223-04): consume offline client package from tracer`
2. **Task 2: Add merge-blocking package, generic iOS 16 core compilation, runtime-surface, and feasibility-independence gates**
   - `6a3842fa` — `feat(223-04): gate iOS offline client compatibility`

## Verification

- `bash scripts/ci/verify_ios_offline_client.sh` — passed: 10 package tests, core-only `arm64-apple-ios16.0` compilation, tracer conformance test, source-boundary scan, and read-only evidence checks.
- `bash scripts/ci/verify_reference_scenario_contract.sh` — passed, including the standalone iOS gate, reference scenarios, host conformance, adoption proof matrix, and release contract.
- `git diff -- examples/crosswake_tracer/capability-report.json examples/crosswake_tracer/physical-device-evidence.md` — empty after verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a minimal tracer conformance test target**
- **Found during:** Task 1
- **Issue:** SwiftPM exits unsuccessfully for `swift test` when the rewritten consumer has no test target.
- **Fix:** Added a one-test target that compiles the re-exported `OfflineEntitlementClient` facade through the tracer.
- **Files modified:** `examples/crosswake_tracer/Package.swift`, `examples/crosswake_tracer/Tests/AccrueOfflineClientTracerTests/PackageConformanceTests.swift`
- **Verification:** `swift test --package-path examples/crosswake_tracer` passed.
- **Commit:** `a03634a2`

**2. [Rule 1 - Bug] Restored the established public adoption-boundary heading**
- **Found during:** Task 2 end-to-end release-contract verification.
- **Issue:** The rewritten tracer README omitted the heading required by the existing release contract.
- **Fix:** Restored `## Public adoption boundary` with explicit feasibility-blocked language.
- **Files modified:** `examples/crosswake_tracer/README.md`
- **Verification:** `bash scripts/ci/verify_reference_scenario_contract.sh` passed.
- **Commit:** `6a3842fa`

## Known Stubs

None.

## Threat Flags

None. The plan added no network endpoint, authentication path, file-access surface, or schema change; it adds only CI and documentation enforcement around existing boundaries.

## Self-Check: PASSED

- Required artifacts exist on disk.
- Task commits `a03634a2` and `6a3842fa` exist in git history.
- The unrelated Phase 217 workflow hunk remains unstaged and uncommitted.
