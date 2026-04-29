---
phase: 094-strategy-capability-matrix-target-lock
plan: 03
subsystem: test
tags: [processor-support, exunit, validation, docs]

# Dependency graph
requires:
  - phase: 094-strategy-capability-matrix-target-lock
    provides: matrix and bash verifiers from Plans 01-02
provides:
  - ExUnit smoke coverage for the processor-support matrix verifier
  - Package-docs drift coverage for the Phase 94 support-boundary pins
  - Updated Nyquist validation contract for the phase
affects: [phase-95, docs tests, validation]

# Tech tracking
tech-stack:
  added: []
  patterns: [bash-verifier-shellout-test, validation-contract-ssot]

key-files:
  created:
    - accrue/test/accrue/docs/processor_support_matrix_test.exs
  modified:
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - .planning/milestones/v1.31-phases/094-strategy-capability-matrix-target-lock/094-VALIDATION.md

key-decisions:
  - "Exercise the matrix verifier from ExUnit using the thin shell-out pattern already used elsewhere in the repo."
  - "Keep Phase 94 drift coverage focused on support-boundary literals rather than broad temp-harness complexity."
  - "Mark Wave 0 complete only after the bash and ExUnit verifier surfaces both exist."

requirements-completed: [PROC-09]

# Metrics
duration: ~25m
completed: 2026-04-29
---

# Phase 94 Plan 03: Close the verification loop

**The Phase 94 support contract is now executable from both bash CI and ExUnit, and the phase validation file reflects the real quick/full commands.**

## Accomplishments
- Added `accrue/test/accrue/docs/processor_support_matrix_test.exs` to shell out to the new matrix verifier.
- Extended `accrue/test/accrue/docs/package_docs_verifier_test.exs` with Phase 94 support-boundary drift coverage.
- Updated `094-VALIDATION.md` so Wave 0 is complete and the quick/full verification commands match the new contract.

## Verification
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_processor_support_matrix.sh`
- `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/processor_support_matrix_test.exs`

## Task Commits

1. **Task 1: Add ExUnit smoke + validation updates** — `bd8efeb`

## Self-Check: PASSED

---
*Phase: 094-strategy-capability-matrix-target-lock*
*Completed: 2026-04-29*
