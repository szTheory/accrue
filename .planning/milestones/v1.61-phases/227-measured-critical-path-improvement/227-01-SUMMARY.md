---
phase: 227
plan: "01"
subsystem: ci
tags: [github-actions, critical-path, evidence]
dependency_graph:
  requires: [phase-226-baseline]
  provides: [one-edge-host-scheduling-improvement, executable-contract]
  affects: [host-integration, playwright-e2e, annotation-sweep]
tech_stack:
  added: []
  patterns: [node-builtins-only, workflow-normalization, frozen-evidence-digests]
key_files:
  created:
    - scripts/ci/verify_ci_critical_path.mjs
    - .planning/phases/227-measured-critical-path-improvement/227-ci-contract.json
    - .planning/phases/227-measured-critical-path-improvement/fixtures/ci-critical-path-cases.json
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/verify_ci_baseline.mjs
decisions:
  - "Host integration now waits only for docs-contracts-shift-left; rollback restores admin-drift-docs."
  - "The verifier hashes the normalized workflow to allow only this one dependency deletion."
metrics:
  duration: "~12m"
  completed_date: "2026-08-12"
status: complete
---

# Phase 227 Plan 01: Critical Path Contract Summary

One reversible host prerequisite deletion is protected by a Node-only CI contract verifier, frozen Phase 226 evidence digests, and positive/negative graph and timing fixtures.

## Completed Tasks

1. Built the contract manifest, fixture pack, and exported verifier for workflow integrity, candidate evidence thresholds, aggregate-failure controls, and explicit rollback.
2. Changed only `host-integration.needs` to `docs-contracts-shift-left`; `playwright-e2e` and the full `annotation-sweep` fan-in remain intact. The literal inverse restores `admin-drift-docs`.

## Verification

- `node scripts/ci/verify_ci_critical_path.mjs --fixtures --workflow .github/workflows/ci.yml --contract .planning/phases/227-measured-critical-path-improvement/227-ci-contract.json --expected-repository szTheory/accrue`
- `node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue`
- `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path --expected-repository szTheory/accrue`
- `node scripts/ci/verify_provider_proof.mjs --fixtures`
- `bash scripts/ci/verify_ci_setup_diagnostics.sh`
- `bash scripts/ci/verify_phase225_required_lane_evidence.sh`

All passed. The three frozen Phase 226 SHA-256 values remain unchanged.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Made the rollback fixture independent of the live workflow state.
- **Found during:** Task 2 verification
- **Fix:** Constructed the inverse fixture by replacing the host job’s candidate edge rather than assuming the working tree was still pre-patch.
- **Commit:** `442da2d5`

2. [Rule 1 - Bug] Aligned the inherited baseline fixture with the authorized host prerequisite.
- **Found during:** Task 2 preservation suite
- **Fix:** The fixture now verifies that missing or skipped `docs-contracts-shift-left` excludes host timing evidence; frozen Phase 226 artifacts were not changed.
- **Commit:** `578debaf`

## Self-Check: PASSED

Created verifier, manifest, fixtures, coverage note, and workflow patch exist; all task commits are present.
