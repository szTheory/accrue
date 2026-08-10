---
phase: 226-ci-baseline-proof-semantics
plan: 04
subsystem: ci-evidence
tags: [github-actions, bash, jq, ci-baseline, proof-semantics]
requires:
  - phase: 226-03
    provides: ownership matrix and topology regression safeguards
provides:
  - versioned workflow lane policy with fail-closed identity resolution
  - three-run queue/signature baseline with immutable provenance equality
  - independently recomputed cohort, proof, queue, and provenance contract
affects: [phase-227, release-gate, docs-contracts-shift-left]
tech-stack:
  added: []
  patterns: [metadata-only GitHub Actions capture, manifest-derived proof, mutation-tested evidence contracts]
key-files:
  created: [scripts/ci/ci_baseline_workflow_policy.json]
  modified: [scripts/ci/capture_ci_baseline.sh, scripts/ci/verify_ci_baseline_contract.sh, .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json, .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md]
key-decisions:
  - "Use stable manifest identities rather than job-name heuristics for CI proof semantics."
  - "Treat provider-omitted critical-root timestamps as ineligible evidence, never as estimated queue time."
  - "Derive proof and queue aggregates from eligible run records and policy rather than stored booleans."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: Manifest-driven capture records measured queue, normalized root signatures, and conservative cache evidence.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh --self-test
        status: pass
      - kind: integration
        ref: bash scripts/ci/capture_ci_baseline.sh --run-id 31322443304
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical three-run cohort records immutable provenance and derived queue/proof aggregates.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh
        status: pass
    human_judgment: false
  - id: D3
    description: Contract rejects cohort, queue, signature, lane, aggregate, workflow, and lockfile mutations while retaining ownership and topology assertions.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh --self-test
        status: pass
      - kind: integration
        ref: bash scripts/ci/verify_phase192_ci_contract.sh
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-08-10
status: complete
---

# Phase 226 Plan 04: CI Baseline Proof Semantics Summary

**Manifest-derived CI evidence now records three measured queue/signature facts and independently rejects incomplete proof or provenance.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-10T21:42:34Z
- **Completed:** 2026-08-10T21:48:34Z
- **Tasks:** 3/3
- **Files modified:** 5

## Accomplishments

- Added a versioned policy manifest that classifies every observed workflow identity exactly once and fails closed on unknown identities.
- Regenerated the eligible three-run canonical evidence with metadata-only queue, root-signature, cache, provenance, and derived proof facts.
- Expanded the contract’s mutation suite to recompute all required proof, aggregate, cohort, and six-lockfile provenance invariants while preserving OWN-01 safeguards.

## Task Commits

1. **Task 1: Make collection manifest-driven and emit queue/signature evidence** — `282051d4`
2. **Task 2: Repair the canonical cohort, provenance, and derived aggregates** — `8d4ca2a3`
3. **Task 3: Enforce fail-closed cohort, proof, and provenance mutations** — `4dff086a`

## Files Created/Modified

- `scripts/ci/ci_baseline_workflow_policy.json` — versioned lane identity, proof, and critical-root policy.
- `scripts/ci/capture_ci_baseline.sh` — metadata-only manifest capture and queue/signature derivation.
- `scripts/ci/verify_ci_baseline_contract.sh` — independent recomputation and mutation validation.
- `226-CI-BASELINE.json` / `226-CI-BASELINE.md` — repaired authoritative evidence and human rendering.

## Decisions Made

- Kept raw provider artifacts out of the baseline; root signatures use only versioned categories and sorted manifest identities.
- Made provider timestamp omissions explicit ineligible evidence instead of inferred timing.
- Collapsed matrix shards to their stable manifest identity for per-run required proof membership.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 227 can consume a deterministic, three-run baseline with measured queue, privacy-safe failure identity, and fail-closed proof/provenance semantics.

## Self-Check: PASSED

- All five planned artifacts exist and all three task commits are present.
- `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` passed and reported each mutation rejection.
- Canonical validation, live metadata-only capture, Phase 192 topology validation, and `git diff --check` passed.
