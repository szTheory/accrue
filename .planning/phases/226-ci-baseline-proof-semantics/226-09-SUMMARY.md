---
phase: 226-ci-baseline-proof-semantics
plan: "09"
subsystem: ci-validation
tags: [bash, jq, github-actions, policy-manifest, security]
requires:
  - phase: 226-08
    provides: policy-owned lane semantics and public validator baseline
provides:
  - exact CI workflow-origin validation
  - complete eligible-run release-proof validation
  - versioned complete workflow topology contract
affects: [phase-227, ci, release-proof]
tech-stack:
  added: []
  patterns: [policy-derived public negative controls, fail-closed workflow topology checks]
key-files:
  created: [.planning/phases/226-ci-baseline-proof-semantics/226-09-SUMMARY.md]
  modified: [scripts/ci/ci_baseline_workflow_policy.json, scripts/ci/capture_ci_baseline.sh, scripts/ci/verify_ci_baseline_contract.sh]
key-decisions:
  - "Provider and candidate workflow names must equal the checked-in policy workflow."
  - "Every eligible run must observe and prove every policy-required identity."
  - "The policy owns the complete live CI job topology, matrix breadth, and live-stripe condition."
requirements-completed: [BASE-01, BASE-02, OWN-01]
status: complete
---

# Phase 226 Plan 09: CI Baseline Proof Semantics Summary

**Fail-closed CI evidence validation now binds workflow origin, complete required proof, and the full workflow topology to one versioned policy.**

## Tasks Completed

1. Added RED/GREEN public-path workflow and required-lane completeness controls.
2. Added the complete versioned workflow topology, including release support cells, Playwright shards, and live-stripe applicability.

## Verification

- `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` passed.
- `bash scripts/ci/verify_ci_baseline_contract.sh` passed.
- `bash scripts/ci/verify_phase192_ci_contract.sh` passed.
- API coverage declaration gate passed.
- Protected workflow and baseline evidence files were not modified.

## Deviations from Plan

None - plan executed as written. The immutable canonical evidence retains its historical policy snapshot while validation derives current topology from the checked-in manifest.

## Self-Check: PASSED

- Task commits `6f3e613d`, `896927fd`, `c76198a5`, and `20d9b008` exist.
- All three planned implementation artifacts exist.
