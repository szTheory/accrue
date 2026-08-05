---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 15
subsystem: crosswake-tracer
tags: [swift, feasibility, provenance, security, tdd]
requires:
  - 215-14
provides:
  - Validator-owned canonical report identity before feasibility proof evaluation
  - Regression coverage for complete attacker-controlled report roots
affects: [phase-216-rail-foundation, phase-219-offline-contract]
tech-stack:
  added: []
  patterns: [canonical artifact identity, fail-closed proof validation, temporary hostile fixture]
key-files:
  created: []
  modified:
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
key-decisions:
  - Only the validator-owned checked-in capability-report.json URL may reach proven-producing evaluation.
  - The internal mutation-test validation seam inherits canonical report identity requirements.
requirements-completed: [RAIL-05]
metrics:
  duration: 2 min
  completed: 2026-08-01
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 215 Plan 15: Canonical Crosswake Report Identity Summary

**The Crosswake validator now authenticates the checked-in capability report location before it trusts report bytes or evidence, so a complete temporary proof tree cannot manufacture `.proven`.**

## Accomplishments

- Added a complete synthetic proven-report fixture with every required capability and evidence lane, including valid native, bridge, simulator, and physical-device artifacts.
- Bound both public and internal validator entry points to the standardized package-root `capability-report.json` derived from the validator source path.
- Preserved all existing schema, capability, evidence containment, file-kind, terminal-reason, and physical-device checks after the identity guard.
- Kept the checked-in report and physical-device evidence byte-unchanged and feasibility-blocked.

## Task Commits

1. **Task 1 RED: Reject a complete proven report rooted outside the checked-in tracer** — `d52f2282` (`test`)
2. **Task 1 GREEN: Bind proof validation to the checked-in report** — `2e45c533` (`feat`)

## Verification

- RED gate: `swift test --filter 'CapabilityReportTests/completeTemporaryProvenReportIsRejected'` failed before implementation because the hostile root returned `.proven`.
- `cd examples/crosswake_tracer && swift test --filter CapabilityReportTests` — passed (9 tests).
- `cd examples/crosswake_tracer && swift test` — passed (23 tests).
- `bash scripts/ci/verify_v159_authority.sh` — passed.
- `bash scripts/ci/verify_entitlement_source_matrix.sh` — passed.
- `cd accrue && mix accrue.entitlements.decision_cases --check` — passed.
- Checked-in report and physical-device evidence byte-drift check — passed.

## Decisions Made

- Canonical path identity is a required provenance condition before any caller-supplied report content can be decoded or evaluated.
- A fail-closed canonical URL guard applies to the internal data mutation seam as well, preventing tests or future callers from creating a second proof authority.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored the public validator return value after adding its guard**
- **Found during:** Task 1 GREEN verification
- **Issue:** The initial guard edit did not return the internal validator result, causing a Swift compile error.
- **Fix:** Returned the guarded `validate(_:reportURL:)` result explicitly.
- **Files modified:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift`
- **Commit:** `2e45c533`

## Known Stubs

None.

## Self-Check: PASSED

- Both modified Swift files exist.
- TDD commits `d52f2282` and `2e45c533` exist in git history.
