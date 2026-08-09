---
phase: 224-crosswake-host-command-bridge-seam
plan: "01"
subsystem: native bridge
tags: [crosswake, swiftpm, ios, bridge, source-pin, host-command]
requires:
  - phase: 220-first-adopter-proof-and-release-gates
    provides: feasibility-blocked capability report and first-adopter bridge contract
provides:
  - immutable Crosswake source lock with base, patch, diff, and audit binding
  - Crosswake-owned `host.accrue.entitlements.refresh` typed tracer
  - credential-free pinned-source gate and native tracer runner
affects: [225-crosswake-host-command-admission, 226-crosswake-host-command-lifecycle, 227-crosswake-host-command-evidence]
tech-stack:
  added: []
  patterns: [base-then-reviewed source pin, manifest-registration intersection, transport-free delegate]
key-files:
  created:
    - .planning/phases/224-crosswake-host-command-bridge-seam/224-CROSSWAKE-SOURCE-AUDIT.md
    - .planning/phases/224-crosswake-host-command-bridge-seam/crosswake-source-lock.json
    - scripts/ci/verify_crosswake_host_commands.sh
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift (Crosswake)
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift (Crosswake)
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift (Crosswake)
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift (Crosswake)
key-decisions:
  - "Pin the short-lived Alpha-owned Crosswake branch to an immutable base and reviewed patch rather than build an Accrue-local bridge."
  - "Require exact route-manifest capability version plus exact host registration before a typed delegate can run."
  - "Keep the tracer zero-field and return only a closed success/denial outcome through Crosswake's reply owner."
patterns-established:
  - "Source gate: verify clean remote, immutable revision, audit digest, ancestry, and diff before native tests."
  - "Host command: manifest declaration and registration/version are an intersection, never alternative admission paths."
requirements-completed: [BRDG-01, BRDG-02]
coverage:
  - id: D1
    description: "Pinned Crosswake bridge source gate binds the audited base and reviewed patch."
    requirement: BRDG-01
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_crosswake_host_commands.sh source-gate"
        status: pass
    human_judgment: false
  - id: D2
    description: "The declared and registered entitlement-refresh tracer reaches only the typed Crosswake delegate."
    requirement: BRDG-02
    verification:
      - kind: unit
        ref: "swift test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-06
status: complete
---

# Phase 224 Plan 01: Crosswake Host-Command Bridge Seam Summary

**Immutable Crosswake source pin and one typed, zero-field entitlement-refresh tracer guarded by exact manifest and host-registration versions.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-08-06T19:32:00Z
- **Completed:** 2026-08-06T19:37:45Z
- **Tasks:** 1/1
- **Files modified:** 7 (3 Accrue, 4 Crosswake)

## Accomplishments

- Audited and committed the clean Crosswake base lock before its first source edit, including a sanitized remote, Alpha delivery lane, test target, and audit digest.
- Added Crosswake-owned `host.accrue.entitlements.refresh` admission requiring the exact route-manifest declaration and host registration/version, with no payload fields and a transport-free typed delegate.
- Bound the reviewed patch `e04928e36381fbbf076ec72eed09737f39c94986` to its immutable base and diff identity; the source gate and tracer runner pass.

## Task Commits

1. **Task 1: Gate source access, audit the safe bridge, and pin one Crosswake-owned host-command tracer**
   - `f61d484f` (Accrue, docs): lock Crosswake bridge source base
   - `e04928e3` (Crosswake, feat): add bounded host command tracer
   - `15ac4df9` (Accrue, docs): pin reviewed Crosswake tracer patch

## Files Created/Modified

- `.planning/phases/224-crosswake-host-command-bridge-seam/224-CROSSWAKE-SOURCE-AUDIT.md` — source ownership, exact seam, test, and patch record.
- `.planning/phases/224-crosswake-host-command-bridge-seam/crosswake-source-lock.json` — two-stage immutable source lock.
- `scripts/ci/verify_crosswake_host_commands.sh` — clean remote/revision/diff/audit gate and tracer entry point.
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/{BridgeChannel,CrosswakeDelegates,CrosswakeShellConfig}.swift` (Crosswake) — typed host-command seam.
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` (Crosswake) — end-to-end tracer and deny-path coverage.

## Decisions Made

- Used the explicitly authorized `chore/accrue-host-command-bridge` Alpha delivery lane, retaining `932b4f32bf087b8e4c0c36c3e54b1031839e867d` byte-for-byte as the immutable base.
- Kept Crosswake as the sole bridge/reply owner; Accrue contains only audit, lock, and verification artifacts.
- Kept capability-report status `feasibility_blocked`; deterministic Swift tests are not physical-device or entitlement-authority evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Source gate recognizes a linked Git worktree**
- **Found during:** Task 1
- **Issue:** The authorized clean Crosswake checkout has a `.git` file, so the initial directory-only check rejected it.
- **Fix:** Accepted either a Git directory or linked-worktree `.git` file with `-e`.
- **Files modified:** `scripts/ci/verify_crosswake_host_commands.sh`
- **Verification:** `source-gate` passed against the authorized checkout before Crosswake edits.
- **Committed in:** `f61d484f`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** The fix was necessary for the authorized checkout model and did not widen source access.

## Known Boundary

The audited `WKScriptMessageHandler` seam does not expose content-world identity in its current public contract. The patch does not make an unsupported content-world assertion; it preserves the existing protocol/runtime/route/origin/pack/manifest gates and records that broader message-context hardening remains for the planned admission/lifecycle/security work.

## Verification

- PASS — baseline: `swift test --package-path packages/crosswake-shell-core-ios` (19 tests).
- PASS — `CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh source-gate`.
- PASS — `CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh tracer` (5 tracer tests).
- PASS — checked-in capability report remains wholly `feasibility_blocked`.

## Next Phase Readiness

Plans 02–03 can consume the reviewed lock, the `HostCommandDescriptor` / `HostCommandDelegate` seam, and the exact admission test target. The content-world boundary finding is documented for their security/lifecycle expansion; it is not represented as physical-device proof.

## Self-Check: PASSED

- All three Accrue artifacts exist and the reviewed Crosswake patch `e04928e3` is present in the authorized branch history.

---
*Phase: 224-crosswake-host-command-bridge-seam*
*Completed: 2026-08-06*
