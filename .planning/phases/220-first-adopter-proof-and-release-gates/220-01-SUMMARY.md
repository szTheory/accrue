---
phase: 220-first-adopter-proof-and-release-gates
plan: 01
subsystem: entitlements
tags: [elixir, ecto, phoenix, swift, offline, conformance]
requires:
  - phase: 219-offline-study-contract
    provides: Offline proof corpus and reconnect authority
provides:
  - Versioned, strict, synthetic reference scenario corpus
  - Core, Phoenix host, and Swift fixture consumers with stable IDs
affects: [220-02, proof-matrix, release-gates]
tech-stack:
  added: []
  patterns: [data-only scenario corpus, closed evidence lanes, capability-report truth pin]
key-files:
  created:
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
    - examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/ReferenceScenarioTests.swift
  modified:
    - examples/accrue_host/mix.lock
key-decisions:
  - "Scenarios are strict data contracts; they do not calculate entitlement outcomes."
  - "Only deterministic_conformance rows are eligible for merge-blocking enumeration."
  - "Crosswake capability evidence remains feasibility_blocked."
requirements-completed: [PROOF-01, PROOF-02]
coverage:
  - id: D1
    description: Strict shared reference scenario corpus with Apple-to-web and Stripe-to-iOS convergence IDs.
    requirement: PROOF-01
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
        status: pass
      - kind: integration
        ref: examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Deterministic offline, ordering, idempotency, concurrency, interruption, and lane boundary IDs.
    requirement: PROOF-02
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
        status: pass
      - kind: unit
        ref: examples/crosswake_tracer/Tests/AccrueOfflineClientTests/ReferenceScenarioTests.swift
        status: pass
    human_judgment: false
metrics:
  duration: 15m
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 01: Reference Scenario Conformance Summary

**Versioned synthetic scenario corpus with closed evidence lanes, strict Elixir loading, Phoenix-host consumption, and Swift feasibility-truth checks.**

## Performance

- **Duration:** 15 min
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added a closed-schema v1.59 scenario corpus with stable Apple-to-web and Stripe-to-iOS convergence IDs plus deterministic PROOF-02 boundary IDs.
- Enforced UTC clocks, ordered actions, duplicate-ID rejection, bounded diagnostics, artifact/lane consistency, and public-only expected observations.
- Pinned host and Swift consumers to the shared IDs while preserving `capability-report.json` as `feasibility_blocked`.

## Task Commits

1. **Task 1: Trace Apple-to-web convergence** — `0151c588` (RED test), `eed20cde` (implementation)
2. **Task 2: Expand deterministic proof boundaries** — `bc450517`

## Decisions Made

- The fixture loader is data-only and cannot reduce grants, purchase decisions, proof state, or repair outcomes.
- Runtime-capability and advisory rows remain visible but excluded from deterministic merge-blocking selection.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking verification environment] Added the missing locked host dependency entry.**
- **Found during:** Task 2
- **Issue:** `examples/accrue_host` could not run its declared test command because its lockfile omitted the existing transitive `jose` dependency.
- **Fix:** Regenerated the lock entry from the declared dependency graph.
- **Files modified:** `examples/accrue_host/mix.lock`
- **Verification:** Phoenix host conformance tests pass.
- **Committed in:** `bc450517`

**Total deviations:** 1 auto-fixed (Rule 3).

## Known Stubs

None.

## Self-Check: PASSED

Verified the five declared corpus/consumer files exist and task commits `0151c588`, `eed20cde`, and `bc450517` are present.

## Next Phase Readiness

Stable scenario IDs and strict lane semantics are available for diagnostics, repair drills, generated proof material, and release gates.
