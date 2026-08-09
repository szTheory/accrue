---
phase: 224-crosswake-host-command-bridge-seam
plan: "03"
subsystem: native bridge
tags: [crosswake, swiftpm, ios, host-command, privacy, lifecycle]
requires:
  - phase: 224-crosswake-host-command-bridge-seam
    provides: four-command manifest/registry intersection and epoch terminalization
provides:
  - throwing host delegates fail closed through the Crosswake-owned terminalizer
  - normalized transport-free delegate surface coverage
  - exact-pin combined native runner mode
affects: [225-first-adopter-host-storekit-adapter, 226-readiness-truth]
tech-stack:
  added: []
  patterns: [opaque handler failure, exact revision source gate, bounded delegate contract]
key-files:
  created:
    - .planning/phases/224-crosswake-host-command-bridge-seam/224-03-SUMMARY.md
  modified:
    - scripts/ci/verify_crosswake_host_commands.sh
    - .planning/phases/224-crosswake-host-command-bridge-seam/224-CROSSWAKE-SOURCE-AUDIT.md
    - .planning/phases/224-crosswake-host-command-bridge-seam/crosswake-source-lock.json
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift (Crosswake)
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift (Crosswake)
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift (Crosswake)
key-decisions:
  - "A throwing host delegate is normalized to the existing opaque handler_failed denial before reply terminalization."
  - "The final runner executes the source gate and entire pinned SwiftPM suite; device and entitlement claims remain blocked."
requirements-completed: [BRDG-01, BRDG-02]
coverage:
  - id: D1
    description: "Host-command delegate errors, normalized API surface, closed descriptors, no-field input, and stale epoch suppression are tested against the immutable bridge pin."
    requirement: BRDG-01
    verification:
      - kind: integration
        ref: CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh admission
        status: pass
    human_judgment: false
  - id: D2
    description: "The complete exact-pin native suite retains one-shot route-bound host-command delivery and opaque failure behavior."
    requirement: BRDG-02
    verification:
      - kind: integration
        ref: CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh full
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-08-06
status: complete
---

# Phase 224 Plan 03: Crosswake Host-Command Bridge Seam Summary

**Pinned Crosswake host commands now turn delegate exceptions into one opaque, route-epoch-bound denial and verify the complete native suite at revision `57e03b61`.**

## Performance

- **Duration:** 16 min
- **Tasks:** 2/2
- **Files modified:** 6 (3 Accrue, 3 Crosswake)

## Accomplishments

- Added a failing-then-green Swift contract for a throwing host delegate; no exception detail is exposed and terminal reply ownership stays in Crosswake.
- Kept the typed request/cancellation surface transport-free and covered its only normalized fields alongside the existing literal command, manifest/registry, schema, and epoch denials.
- Pinned the reviewed patch to `57e03b61082b1f865bc31c5e8b6dcee444f56dad` with diff `9d5330a471d7446fb8657fa22c5c41ade458b4eb739c50cbf245a1457d954e31`, and added the full native runner mode.

## Task Commits

1. **Task 1: Prove ordered admission, fixed schemas, delegate isolation, and privacy with deterministic negatives**
   - `cfbb3c35` (Crosswake, test): failing throwing-delegate contract
   - `57e03b61` (Crosswake, feat): opaque delegate failure terminalization and API-surface coverage
2. **Task 2: Prove handler failure, cancellation, double completion, and navigation races cannot inject stale replies**
   - Included in `57e03b61`; the synchronous pinned delegate uses immutable cancellation and the existing epoch/one-shot terminalizer.

## Verification

- PASS — `CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh admission` (11 host-command tests).
- PASS — `... verify_crosswake_host_commands.sh lifecycle` (11 host-command tests).
- PASS — `... verify_crosswake_host_commands.sh full` (25 SwiftPM tests).
- PASS — source gate validates the base ancestry, exact patch revision, audit digest, and binary diff identity before each mode.

## Decisions Made

- Delegate failures are caught at the sole ordered dispatcher and use the same bounded `handler_failed` response as an explicit failure outcome.
- The host command remains transport-only: no request, cancellation context, or outcome gains WebKit, raw envelope, evaluator, callback, frame, or reply authority.
- `feasibility_blocked` remains unchanged; deterministic bridge tests are neither device evidence nor entitlement authority.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Host delegate throws would escape the safe bridge boundary**
- **Found during:** Task 2
- **Issue:** `HostCommandDelegate` could only return a value, so a host implementation could not surface an error through Crosswake's bounded denial path.
- **Fix:** Made the delegate operation throwing and normalized errors to `handler_failed` before epoch and one-shot terminalization.
- **Files modified:** `BridgeChannel.swift`, `CrosswakeDelegates.swift`, `HostCommandAdmissionTests.swift`
- **Verification:** failing red test at `cfbb3c35`; full suite green at `57e03b61`.

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug).
**Impact on plan:** Correctness hardening only; no new bridge authority, package, host UI, StoreKit, Accrue dependency, or runtime-proof claim.

## Known Boundary

The audited source's delegate operation is synchronous. Its deterministic cancellation/race proof is therefore the captured immutable cancellation context plus final route/session/epoch recheck and correlation one-shot claim; it has no scheduler or seed facility. This does not promote device/runtime status.

## Next Phase Readiness

Plan 224-04 can consume the final lock, audit, and `full` runner at `57e03b61`; its evidence publication must preserve the existing `feasibility_blocked` classification.

## Self-Check: PASSED

- The three Accrue artifacts exist, `57e03b61` is present on `chore/accrue-host-command-bridge`, and the full exact-pin runner passed.

---
*Phase: 224-crosswake-host-command-bridge-seam*
*Completed: 2026-08-06*
