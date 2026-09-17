---
phase: 226-ci-baseline-proof-semantics
plan: "17"
subsystem: ci
tags: [github-actions, ci-baseline, postgres, diagnostics, shell]
requires:
  - phase: 226-ci-baseline-proof-semantics
    provides: "Plan 16 baseline collector, setup diagnostic registry, and fixture contracts"
provides:
  - "Immutable workflow-revision-bound historical CI compatibility controls"
  - "Owner-first initial Postgres readiness diagnostic with a persisted safe fact"
affects: [ci-baseline, host-integration, phase-226-plan-18]
tech-stack:
  added: []
  patterns: ["Fail closed on unknown CI identities and workflow revisions", "Capture early shell-command statuses before owner diagnostic routing"]
key-files:
  created: []
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - scripts/ci/accrue_host_uat.sh
    - scripts/ci/verify_ci_setup_diagnostics.sh
key-decisions:
  - "Historical CI exceptions require an audited immutable workflow revision and exact identity tuple."
  - "The initial Postgres readiness branch emits the fixed fixture_or_database diagnostic before host delegation."
patterns-established:
  - "Shell wrappers capture prerequisite failures under set +e, then restore strict mode before rendering a safe diagnostic."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: "Historical compatibility and workflow identity resolution reject unknown revisions, topology, and suffixes."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Initial Postgres readiness failures emit a privacy-safe host diagnostic before mix verify.full delegation."
    requirement: OWN-01
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_ci_setup_diagnostics.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Provider proof semantics remain preserved alongside baseline admission repairs."
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures"
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-08-12
status: complete
---

# Phase 226 Plan 17: CI Baseline Admission and Initial Readiness Diagnostics Summary

**Fail-closed comparable-run CI admission plus a fact-backed, owner-first Postgres readiness failure path.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-08-12T16:17:06Z
- **Completed:** 2026-08-12T16:38:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Bound historical CI compatibility to immutable workflow revisions and exact or enumerated workflow identities.
- Added production-shaped adversarial controls for unknown revisions, unknown topology, and spoofed job suffixes.
- Routed initial Postgres-readiness failures through the existing `fixture_or_database` registry fact before host delegation.
- Proved the early path preserves the readiness status, does not invoke `mix verify.full`, and does not expose sensitive-looking PG values.

## Task Commits

1. **Task 1: Trusted CI collection tracer** — `05625ea7` (test), `e9548aff` (feat)
2. **Task 2: Diagnose initial Postgres readiness failure before host delegation** — `195fad34` (test), `d6031df0` (feat)

## Files Created/Modified

- `scripts/ci/collect_ci_baseline.mjs` — revision-bound compatibility inventory and exact identity resolver.
- `scripts/ci/verify_ci_baseline.mjs` — adversarial production-path CI admission controls.
- `scripts/ci/accrue_host_uat.sh` — captured readiness status and safe early diagnostic route.
- `scripts/ci/verify_ci_setup_diagnostics.sh` — shadowed readiness regression, privacy, and delegation assertions.

## Decisions Made

- Require immutable workflow-revision and exact identity binding for historical compatibility exceptions.
- Reuse the stable `fixture_or_database` registry entry rather than create a new diagnostic code for early database readiness.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 18 can recollect and render baseline evidence using the repaired CI-admission and host-setup boundaries.

## Self-Check: PASSED

- Confirmed all four implementation files exist and all Task 1/Task 2 commits are present in git history.
