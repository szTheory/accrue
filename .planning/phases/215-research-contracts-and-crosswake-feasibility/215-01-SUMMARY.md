---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 01
subsystem: mobile-client-feasibility
tags: [swift, storekit, secure-enclave, crosswake, feasibility]
requires: []
provides:
  - "A host-owned Swift feasibility boundary with a fail-closed capability reducer"
  - "A machine-readable client/device proof-or-block report and redacted evidence runbook"
affects: [215-05, 216, 219, mobile-runtime-coupling]
tech-stack:
  added: [Swift Package Manager, Swift Testing]
  patterns: ["capability evidence lanes", "fail-closed feasibility reduction", "host-owned bridge boundary"]
key-files:
  created:
    - examples/crosswake_tracer/Package.swift
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/capability-report.json
    - examples/crosswake_tracer/physical-device-evidence.md
  modified:
    - .planning/phases/215-research-contracts-and-crosswake-feasibility/215-RESEARCH.md
key-decisions:
  - "Missing pinned Crosswake source, documented bridge, or dated device proof remains feasibility_blocked."
  - "Lifecycle and network changes can only coalesce authenticated reconciliation; they cannot grant access."
requirements-completed: [RAIL-05]
coverage:
  - id: D1
    description: "Swift feasibility reducer requires every D-10 capability and its required evidence lanes before reporting proven."
    requirement: RAIL-05
    verification:
      - kind: unit
        ref: "swift test --package-path examples/crosswake_tracer"
        status: pass
    human_judgment: false
  - id: D2
    description: "Redacted physical-device evidence procedure for Secure Enclave, Keychain, lifecycle, replacement, transport, and reconnect."
    requirement: RAIL-05
    verification:
      - kind: manual_procedural
        ref: "examples/crosswake_tracer/physical-device-evidence.md"
        status: unknown
    human_judgment: true
    rationale: "Pinned Crosswake source and physical-device evidence are unavailable, so runtime coupling is deliberately blocked."
duration: 8min
completed: 2026-07-31
status: complete
---

# Phase 215 Plan 01: Crosswake feasibility tracer Summary

**A standalone Swift client boundary now records every required evidence lane and fails closed to `feasibility_blocked` until Crosswake and physical-device proof exist.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-31T21:47:00Z
- **Completed:** 2026-07-31T21:55:00Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added an independently buildable Swift package with a narrow host-owned `AccrueOfflineClient` boundary and no Accrue runtime dependency.
- Added a deterministic reducer that requires every D-10 capability exactly once, with its native, bridge, simulator-advisory, and/or dated physical-device lanes before it can report `proven`.
- Recorded a `feasibility_blocked` report, reproducible commands, a redacted device-proof template, and dated research conclusions for unavailable Crosswake/device evidence.

## Task Commits

1. **Task 1: Trace one honest native-to-Crosswake capability result** — `2d1bca01` (test), `3c248c39` (feat)
2. **Task 2: Record the device proof lane, coupling disposition, and resolved research answers** — `32782f59` (docs)

## Files Created/Modified

- `examples/crosswake_tracer/Package.swift` — independently testable Swift package definition.
- `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` — host boundary, evidence requirements, and fail-closed report reducer.
- `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift` — reducer, ordering, and evidence-lane tests.
- `examples/crosswake_tracer/capability-report.json` — machine-readable blocked disposition for all required capabilities.
- `examples/crosswake_tracer/README.md` and `physical-device-evidence.md` — reproducible checks and redacted proof procedure.
- `.planning/phases/215-research-contracts-and-crosswake-feasibility/215-RESEARCH.md` — dated source and device-evidence conclusions.

## Decisions Made

- The package exposes a host-owned contract only; it neither installs nor invents Crosswake APIs.
- Native or simulator observations cannot lift the report to `proven` without every required bridge and physical-device lane.
- Server/vector/JWS tests remain independently merge-blocking and are not report inputs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the test's stale capability case name**
- **Found during:** Task 1
- **Issue:** The initial failing test referred to a capability that was not part of the D-10 enumeration.
- **Fix:** Used `authenticatedHostTransport`, the defined transport capability.
- **Files modified:** `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift`
- **Verification:** `swift test --package-path examples/crosswake_tracer --filter CapabilityReportTests`
- **Committed in:** `3c248c39`

**2. [Rule 2 - Missing Critical Functionality] Required evidence lanes in the reducer**
- **Found during:** Task 2
- **Issue:** A caller could label a row proven without presenting its required evidence kinds.
- **Fix:** The reducer now validates each capability's required evidence-kind set before returning `proven`.
- **Files modified:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift`, `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift`, `examples/crosswake_tracer/capability-report.json`
- **Verification:** `swift test --package-path examples/crosswake_tracer`
- **Committed in:** `32782f59`

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2). Both preserve the plan's fail-closed security contract.

## Known Stubs

None. The pending physical-device fields intentionally document unavailable evidence and keep the report blocked; they are not runtime data paths.

## User Setup Required

None. Physical-device evidence is a future coupling gate, not required to build or run the checked-in tracer.

## Next Phase Readiness

Later mobile runtime coupling remains blocked until a pinned Crosswake source, documented bridge, and approved dated device proof exist. Plan 215-05 server/vector work remains independently mandatory.

## Self-Check: PASSED

- Confirmed the Swift package, report, runbooks, research update, and all three task commits exist.

---
*Phase: 215-research-contracts-and-crosswake-feasibility*
*Completed: 2026-07-31*
