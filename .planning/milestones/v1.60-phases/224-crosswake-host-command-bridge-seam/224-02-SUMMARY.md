---
phase: 224-crosswake-host-command-bridge-seam
plan: "02"
subsystem: native bridge
tags: [crosswake, swiftpm, ios, host-command, route-epoch, telemetry]
requires:
  - phase: 224-crosswake-host-command-bridge-seam
    provides: immutable Crosswake source lock and typed entitlement-refresh tracer
provides:
  - four-command closed host capability contract with setup validation
  - route-epoch-bound one-shot host reply terminalization
  - reviewed Crosswake patch pin with admission and lifecycle verification modes
affects: [225-crosswake-host-command-admission, 226-crosswake-host-command-lifecycle, 227-crosswake-host-command-evidence]
tech-stack:
  added: []
  patterns: [literal capability intersection, validating setup, route-epoch reply suppression, bounded telemetry]
key-files:
  created:
    - .planning/phases/224-crosswake-host-command-bridge-seam/224-02-SUMMARY.md
  modified:
    - scripts/ci/verify_crosswake_host_commands.sh
    - .planning/phases/224-crosswake-host-command-bridge-seam/224-CROSSWAKE-SOURCE-AUDIT.md
    - .planning/phases/224-crosswake-host-command-bridge-seam/crosswake-source-lock.json
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift (Crosswake)
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift (Crosswake)
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift (Crosswake)
key-decisions:
  - "The command set is closed to four literal no-field descriptors; host command success remains transport-only, never entitlement authority."
  - "Crosswake rechecks its captured session and route epoch at the single terminalization point and suppresses stale or duplicate replies."
requirements-completed: [BRDG-01, BRDG-02]
coverage:
  - id: D1
    description: Four literal capability descriptors require exact manifest, registration, and version intersection with early configuration diagnostics.
    requirement: BRDG-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_crosswake_host_commands.sh admission
        status: pass
    human_judgment: false
  - id: D2
    description: Host command replies remain route-epoch-bound and stale results are suppressed by Crosswake with bounded telemetry.
    requirement: BRDG-02
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_crosswake_host_commands.sh lifecycle
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-06
status: complete
---

# Phase 224 Plan 02: Crosswake Host-Command Bridge Seam Summary

**Four literal Accrue host commands, validated before installation and terminalized once against the captured Crosswake route epoch.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-06T15:41:00Z
- **Completed:** 2026-08-06T15:45:00Z
- **Tasks:** 2/2
- **Files modified:** 6 (3 Accrue, 3 Crosswake)

## Accomplishments

- Closed the capability contract to purchase, restore, entitlement refresh, and offline reconnect, each with an exact versioned manifest/registration intersection and no request or success-response fields.
- Added actionable descriptor validation plus bounded `request_malformed`, `command_not_registered`, `handler_failed`, and stale `reply_expired` behavior without carrying host transport or entitlement authority to the delegate.
- Captured and rechecked a route/session epoch at the sole host-command terminalizer; stale and duplicate replies are suppressed and emit data-minimized operational metadata only.
- Pinned the reviewed bridge expansion to `8611c09d4c9e6a32233425b3d876321632b89aef` with diff identity `8c4955c5aa0f5cc7d9615ebf2ac2ed16bfcc646824405db9e73ceaccc5bfc1ba`.

## Task Commits

1. **Task 1: Complete the closed capability, typed schema, registry, denial, and telemetry contract**
   - `87f02f56` (Crosswake, test): failing contract tests
   - `f809da2f` (Crosswake, feat): closed four-command admission
2. **Task 2: Bind invocation lifetime and one-shot reply authority to the active route epoch**
   - `d70b0c8d` (Crosswake, test): failing route-epoch test
   - `8611c09d` (Crosswake, feat): route-bound terminalization
3. **Reviewed source metadata**
   - `96f659b2` (Accrue, docs): audit, lock, and verifier modes

## Verification

- PASS — `swift test --package-path packages/crosswake-shell-core-ios` (23 tests).
- PASS — `CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh source-gate`.
- PASS — `... verify_crosswake_host_commands.sh admission`.
- PASS — `... verify_crosswake_host_commands.sh lifecycle`.

## Deviations from Plan

None - plan executed without scope expansion. The pinned source is synchronous, so cooperative cancellation is represented by its immutable cancellation context and stale native work is prevented from delivering by final route/session/epoch revalidation.

## Issues Encountered

None.

## Next Phase Readiness

Phase 225 can consume the locked `8611c09d` Crosswake bridge patch, its literal descriptor validation, and the admission/lifecycle runner modes. The capability report remains `feasibility_blocked`; these deterministic native tests do not assert device or entitlement proof.

## Self-Check: PASSED

- The audit, lock, runner, and summary exist in Accrue; all four Crosswake commits are present on `chore/accrue-host-command-bridge`, which is clean.

---
*Phase: 224-crosswake-host-command-bridge-seam*
*Completed: 2026-08-06*
