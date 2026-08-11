---
phase: 226-ci-baseline-proof-semantics
plan: "08"
subsystem: ci-contract-testing
tags: [bash, jq, ci, workflow-policy, proof-semantics]
requires:
  - phase: 226-07
    provides: Exact recursive privacy and schema validation for the durable baseline.
provides:
  - Fail-closed candidate job binding to the checked-in workflow-policy manifest.
  - Public-CLI regression coverage for identity, policy, and proof-state forgeries.
affects: [phase-227-critical-path-optimization, ci-baseline-evidence]
tech-stack:
  added: []
  patterns: [exact-one manifest matching, policy-derived proof state, public-input mutation matrix]
key-files:
  created: []
  modified:
    - scripts/ci/verify_ci_baseline_contract.sh
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
key-decisions:
  - "Treat every input job field as an assertion and re-derive policy/proof facts from the manifest."
  - "Exercise collector and canonical validation only through fresh public --input processes."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: Candidate collector and canonical jobs must bind to exactly one trusted workflow-policy lane before validation accepts them.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh --self-test
        status: pass
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json
        status: pass
    human_judgment: false
  - id: D2
    description: Policy-owned facts and proof state are derived from manifest policy, run eligibility, and observed conclusion rather than candidate fields.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh --self-test
        status: pass
    human_judgment: false
  - id: D3
    description: Existing ownership, topology, privacy, and Phase 192 evidence contracts remain unchanged and green.
    requirement: OWN-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-08-11
status: complete
---

# Phase 226 Plan 08: CI Baseline Proof Semantics Summary

**Collector and canonical CI evidence now derive every job’s trusted workflow policy and release-proof state from the versioned manifest before aggregate proof is accepted.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-08-11T00:42:00Z
- **Completed:** 2026-08-11T01:13:05Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added one shared exact-one lane predicate for collector records and canonical cohorts, including policy tuple and proof-state derivation.
- Added fresh public-CLI mutation coverage for fabricated names, each policy-owned field, and all proof precedence paths.
- Preserved the canonical evidence, collector, workflow topology, ownership documentation, privacy boundary, and Phase 192 contracts with deterministic regression gates.

## Task Commits

1. **Task 1: Bind one collector and canonical job end-to-end to trusted policy semantics** — `1d438b51` (test), `6f9d92d9` (feat)
2. **Task 2: Prove every policy/proof forgery fails and certify preserved Phase 226/192 contracts** — `a9b7f868` (test), `53d18ba3` (docs)

## Files Created/Modified

- `scripts/ci/verify_ci_baseline_contract.sh` — derives and validates manifest-owned job and proof facts; tests both public input modes.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md` — maps policy-binding adversarial controls and preservation gates.

## Decisions Made

- The manifest is the only trusted policy interpretation boundary; a candidate job must match one and only one lane.
- `proof_state` is derived with collector precedence: skipped, advisory, conditional, eligible required success, otherwise not-applicable.

## Deviations from Plan

None - plan executed as specified. The tracer feedback gate was replaced with its requested public-CLI automation; no human verification remains.

## Issues Encountered

The existing self-test intentionally prints failures from its negative controls; the suite exits successfully only when every rejection is observed.

## User Setup Required

None - no external service configuration or human verification is required.

## Next Phase Readiness

Phase 227 can consume the unchanged three-run baseline with policy and proof facts independently re-derived by the public validator.

## Self-Check: PASSED

- Confirmed both modified implementation and validation files exist.
- Confirmed all four task commits are present in git history.
