---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 14
subsystem: crosswake-tracer
tags: [swift, feasibility, provenance, fail-closed, tdd]
requires:
  - 215-13
provides:
  - Caller-populatable capability reports that always remain feasibility_blocked
  - A single report-root-aware public route capable of returning proven
affects: [phase-216-rail-foundation, phase-219-offline-contract]
tech-stack:
  added: []
  patterns: [untrusted draft state, provenance-gated proof authority, fail-closed decoding]
key-files:
  created: []
  modified:
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
key-decisions:
  - Caller-controlled capability status, evidence kind, and location data is always feasibility_blocked.
  - Only CheckedInCapabilityReportValidator.validate(reportURL:) may return proven because its URL establishes the evidence root.
requirements-completed: [RSCH-01, RSCH-02, RSCH-03, RAIL-04, RAIL-05]
coverage:
  - id: D1
    description: Untrusted capability report construction and decoding cannot manufacture a proven feasibility decision.
    requirement: RAIL-05
    verification:
      - kind: unit
        ref: examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift#callerSuppliedEvidenceRemainsBlockedAtArbitraryLocations
        status: pass
      - kind: unit
        ref: examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift#decodedCallerSuppliedEvidenceRemainsBlocked
        status: pass
    human_judgment: false
  - id: D2
    description: Checked-in report validation remains provenance-aware and feasibility_blocked without missing Crosswake or device evidence.
    requirement: RAIL-05
    verification:
      - kind: unit
        ref: examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift#checkedInValidatorRejectsFalseProofAndReasonMutations
        status: pass
      - kind: integration
        ref: cd examples/crosswake_tracer && swift test
        status: pass
    human_judgment: false
metrics:
  duration: 4 min
  completed: 2026-08-01
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 215 Plan 14: Provenance-Gated Feasibility Summary

**Crosswake feasibility is now fail-closed for all caller-controlled data, with proven reserved for the checked-in report validator's evidence-root-aware checks.**

## Accomplishments

- Replaced the public synthetic false-proof scenario with regressions covering URL-like, missing relative, absolute, and report-root-escaping locations.
- Made `CapabilityReport` construction and decoding permanently return `feasibility_blocked`, while retaining deterministic capability ordering.
- Preserved `CheckedInCapabilityReportValidator.validate(reportURL:)` as the only public path that may return `.proven` after contained, kind-specific, and physical-device evidence checks.
- Kept the checked-in report and physical-device evidence byte-unchanged and feasibility-blocked.

## Task Commits

1. **Task 1: Trace arbitrary caller evidence to a blocked decision and reserve proven for validated provenance** — `7a0947d9` (test), `a22eb197` (feat)

## Files Created/Modified

- `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` — Fail-closes caller-created and decoded capability reports.
- `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift` — Pins arbitrary-location and decoded-status false-proof regressions.

## Verification

- `cd examples/crosswake_tracer && swift test --filter CapabilityReportTests` — passed (8 tests).
- `cd examples/crosswake_tracer && swift test` — passed (22 tests).
- `bash scripts/ci/verify_v159_authority.sh` — passed.
- `bash scripts/ci/verify_entitlement_source_matrix.sh` — passed.
- `cd accrue && mix accrue.entitlements.decision_cases --check` — passed.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query check.api-coverage-verify-pre 215` — passed; no external API integration declared.
- Byte-drift check for the report, device evidence, and warning-only Elixir files — passed.

## Decisions Made

- A data-only `CapabilityReport` is an untrusted draft, not an authority capable of proving runtime feasibility.
- A report URL is mandatory for a proven result because it establishes the evidence root needed for provenance checks.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Both modified Swift files exist.
- TDD commits `7a0947d9` and `a22eb197` exist in git history.
