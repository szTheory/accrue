---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 10
subsystem: offline-entitlements-contract-testing
tags: [swift, testing, offline-entitlements, canonical-contract, json]
requires:
  - phase: 215-09
    provides: corrected generated offline corpus and Elixir canonical binding contract
provides:
  - Strict Swift offline-corpus schema, identity, and field binding before observation
  - Canonical DecisionCases version and disposition binding for every Swift vector
  - Mutation-sensitive regression coverage, including valid substituted JWS bytes
affects: [215-11, 217, 219]
tech-stack:
  added: []
  patterns: [pre-observation canonical corpus binding, exact JSON key-set validation]
key-files:
  created: []
  modified:
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
key-decisions:
  - "Swift test fixtures bind exactly to the generated corpus and decision-case metadata before JWS or cache observation."
  - "Passing Swift contract tests do not establish Crosswake bridge or physical-device feasibility."
requirements-completed: [RSCH-02, RAIL-05]
coverage:
  - id: D1
    description: Swift rejects schema, identity, field, and optional fault-point drift against the generated offline corpus before observation.
    requirement: RSCH-02
    verification:
      - kind: unit
        ref: cd examples/crosswake_tracer && swift test --filter GoldenVectorTests
        status: pass
    human_judgment: false
  - id: D2
    description: Every Swift vector is bound to canonical case ID, contract version, and expected disposition without upgrading feasibility status.
    requirement: RAIL-05
    verification:
      - kind: unit
        ref: GoldenVectorTests canonical case binding coverage; capability-report byte check
        status: pass
    human_judgment: true
duration: 4m
completed: 2026-08-02
status: complete
---

# Phase 215 Plan 10: Swift Canonical Corpus Binding Summary

**Swift now rejects every tested deviation from the generated offline corpus and canonical decision cases before running its JWS/cache oracle, while retaining the existing feasibility-blocked boundary.**

## Performance

- **Duration:** 4m
- **Completed:** 2026-08-02
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Added complete pre-observation structural validation for exact corpus and vector key sets, required values, unique IDs, and baseline identity parity.
- Bound every candidate vector field and optional `fault_point` presence to the generated corpus, including exact compact-JWS bytes.
- Bound every vector case to generated DecisionCases contract-version and disposition metadata, with stable bounded diagnostics.
- Re-ran the approved tracer verification: all 9 `GoldenVectorTests` passed and `capability-report.json` remained byte-unchanged.

## Task Commits

1. **Task 1: Trace one offline vector through Swift canonical metadata validation** — `c414455f`, `07e1bbe7`

## Files Created/Modified

- `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` — Exact JSON schema and canonical binding validator before observation.
- `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift` — Focused mutation, identity, metadata, and valid-JWS substitution regressions.

## Decisions Made

- Swift test fixtures bind exactly to the generated corpus and decision-case metadata before JWS or cache observation.
- Passing Swift contract tests do not establish Crosswake bridge or physical-device feasibility.

## Human Verification

The tracer feedback gate was approved by the user. The re-run automated evidence remains valid: `swift test --filter GoldenVectorTests` passed 9 tests, and the protected feasibility report was byte-unchanged.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Verification

- `cd examples/crosswake_tracer && swift test --filter GoldenVectorTests` — passed (9 tests).
- `git diff --exit-code -- examples/crosswake_tracer/capability-report.json` — passed; report remains byte-unchanged and feasibility-blocked.
- Verified user-owned diffs for `215-VERIFICATION.md` and `SEED-007-google-play-billing-rail.md` were unchanged by this closeout.

## Next Phase Readiness

Plan 215-11 may rely on strict Swift corpus parity, but the authoritative Crosswake bridge and dated physical-device proof remain unavailable; contract parity must not be read as feasibility approval.

## Self-Check: PASSED

- Confirmed both Swift implementation and regression files exist.
- Confirmed task commits `c414455f` and `07e1bbe7` exist in git history.
