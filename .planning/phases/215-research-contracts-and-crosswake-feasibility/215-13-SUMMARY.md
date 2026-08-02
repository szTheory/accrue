---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 13
subsystem: crosswake-tracer
tags: [swift, offline-cache, authenticated-state, evidence-validation, tdd]
requires:
  - 215-12
provides:
  - Authenticated-only durable cache replacement with signed-denial preservation
  - Evidence-root-aware feasibility report validation
affects: [phase-219-offline-contract]
tech_stack:
  added: []
  patterns: [authenticated write boundary, process-isolated denial preservation, fail-closed evidence provenance]
key_files:
  created: []
  modified:
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Sources/AccrueOfflineCacheCrashHarness/main.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
    - .planning/phases/215-research-contracts-and-crosswake-feasibility/COVERAGE.md
decisions:
  - Production AtomicOfflineCache construction and replacement require host authentication plus explicit disposition and revision.
  - Checked-in capability proof is evaluated relative to its report root and remains blocked without pinned bridge and completed device evidence.
metrics:
  duration: 5 min
  completed: 2026-08-01
  tasks_completed: 2
  files_modified: 6
status: complete
---

# Phase 215 Plan 13: Authenticated Cache and Evidence Validation Summary

**Signed denial state can no longer be overwritten by a no-key process, and report evidence can no longer turn unavailable Crosswake lanes into false proof.**

## Accomplishments

- Removed the public no-key cache initializer and raw replacement overload; every production cache write now carries a key, disposition, and revision.
- Rejected obsolete harness arguments before cache construction and proved a separate no-key process preserves exact authenticated denial bytes, metadata, and candidate cleanup.
- Made checked-in capability validation report-root-aware, terminal-reason-aware, and fail closed for unresolved, escaping, placeholder, wrong-kind, or incomplete physical-device proof.
- Kept the checked-in capability report and physical-device evidence byte-unchanged and feasibility-blocked.

## Task Commits

1. **Task 1: Trace authenticated denial persistence through an attempted legacy no-key overwrite** — `6332c54a` (test), `ed70e5d6` (feat)
2. **Task 2: Reject fabricated proven reports and rerun every Phase-215 contract gate** — `024d1746` (test), `2bd7bc3d` (feat)

## Verification

- `cd examples/crosswake_tracer && swift test --filter AtomicOfflineCacheProcessTests && swift test --filter GoldenVectorTests`
- `cd examples/crosswake_tracer && swift test --filter CapabilityReportTests && swift test`
- `bash scripts/ci/verify_v159_authority.sh`
- `bash scripts/ci/verify_entitlement_source_matrix.sh`
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query check.api-coverage-verify-pre 215`
- `cd accrue && mix accrue.entitlements.decision_cases --check && mix test test/accrue/entitlements/decision_cases_test.exs test/property/entitlement_decision_cases_property_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs`
- Byte-drift checks passed for entitlement JSON corpora, `capability-report.json`, and `physical-device-evidence.md`.

## Decisions Made

- The cache key is host-supplied and never optional; only the verified disposition/revision path may atomically replace persisted state.
- A capability report's file URL is the evidence root, so public validation cannot decide feasibility from detached JSON bytes.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All six planned code, test, and coverage artifacts exist.
- All four TDD commits exist in git history.
