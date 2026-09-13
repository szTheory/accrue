---
phase: 227-measured-critical-path-improvement
plan: "07"
subsystem: ci-evidence
tags: [critical-path, local-preflight, workflow-contract, fail-closed]
dependency_graph:
  requires: [227-05]
  provides: [v3-unspent-authority, exact-tree-preflight, one-edge-candidate]
  affects: [227-08, PATH-01, PATH-02, SAFE-01, SAFE-02]
tech-stack:
  added: []
  patterns: [detached-worktree-preflight, append-only-authority, runtime-deny-list]
key-files:
  created:
    - scripts/ci/preflight_phase227_candidate.sh
    - .planning/phases/227-measured-critical-path-improvement/227-PREFLIGHT-CONTROL.json
    - .planning/phases/227-measured-critical-path-improvement/227-CANDIDATE-PREFLIGHT.json
  modified:
    - scripts/ci/verify_ci_critical_path.mjs
    - .github/workflows/ci.yml
key-decisions:
  - "v3 authority starts unspent and remote effects disabled; only a separately appended activation can consume it."
  - "Candidate 0339f14d is the sole eligible one-edge workflow commit for Plan 08."
metrics:
  duration: 27m
  completed: 2026-09-12
  tasks: 3
  commits: 17
  plan_head_before: 2b9422a5019b9c7d1e7382c1e600679106a9a36f
status: complete
actuals:
  tokens: 9055
  tasks: 3
  commits: 17
requirements-completed: []
coverage:
  - id: D1
    description: "Fail-closed v3 authority and exact-tree preflight with zero remote effects."
    verification:
      - kind: integration
        ref: "scripts/ci/verify_ci_critical_path.test.mjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Append-only zero-consumption v3 authorization and deterministic report."
    verification:
      - kind: integration
        ref: "verify_ci_critical_path.mjs --verify-evidence"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact one-edge candidate with separately committed preflight evidence."
    verification:
      - kind: integration
        ref: "verify_ci_critical_path.mjs --verify-preflight-evidence"
        status: pass
    human_judgment: false
---

# Phase 227 Plan 07: Local v3 Authority and Candidate Summary

**A zero-consumption v3 authority and exact-SHA one-edge host-integration candidate, proven locally with detached-worktree, CI-compatible checks and no remote effects.**

## Accomplishments

- Added fail-closed v3 reservation, activation, consumption, and kept-only validation while preserving closed v1/v2 ledger records.
- Added a detached exact-commit preflight wrapper plus structural and runtime deny-list tests; all prohibited invocation logs were empty.
- Committed candidate `0339f14d6badaa7d901c27a62379c86b666c5d62`, changing only `.github/workflows/ci.yml` by removing `admin-drift-docs` from `host-integration.needs`.
- Recorded candidate tree `0d96bf3a7f6927f43412c1c08de4b51aeba7c4eb` and evidence digest `sha256:07f26dd87e7bbe3f1bd43b18f600330afb6602c268f715c9f819ef22cacd449b`.

## Verification

- `PHASE227_MIX_CACHE=<disposable-cache> bash scripts/ci/preflight_phase227_candidate.sh ...` passed for restored control and candidate SHA.
- `node scripts/ci/verify_ci_critical_path.mjs --verify-preflight-evidence ... --require-no-remote-effects` passed.
- `node scripts/ci/verify_ci_critical_path.mjs --verify-evidence ...` passed; `--require-kept` correctly failed because PATH-02 remains unmet.
- `node --test scripts/ci/verify_ci_critical_path.test.mjs` passed 6/6, including the runtime sandbox.

## Task Commits

1. Task 1: `0fac122e`, `21655ee9`, `2d067223`, `6ebdcd5f`, `e40ccf59`
2. Task 2: `a4130d62`
3. Task 3 candidate: `0339f14d`; evidence: `0f29ea85`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking environment] Built a disposable lockfile-compatible Mix cache after the existing local cache contained stale dependency versions.
2. [Rule 1 - Test bug] Made the runtime sandbox state-aware after it incorrectly assumed the restored graph while exercising the candidate graph.

## Next Phase Readiness

Plan 08 may use only candidate `0339f14d6badaa7d901c27a62379c86b666c5d62`. v3 authority remains unspent and remote effects disabled; PATH-02 remains unmet.

## Known Stubs

None.

## Self-Check: PASSED

- Candidate preflight evidence, control evidence, wrapper, verifier, and workflow exist.
- Candidate commit `0339f14d` and evidence commit `0f29ea85` exist in Git history.
