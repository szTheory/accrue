---
phase: 226-ci-baseline-proof-semantics
plan: 01
subsystem: ci-testing
tags: [github-actions, gh, jq, ci-baseline, privacy, proof-state]
requires:
  - phase: 225-required-lane-signal-repair
    provides: "Fresh SHA-bound repair run 31322443304 and required/advisory lane evidence"
provides:
  - "Metadata-only Actions collector with live and sanitized-fixture inputs"
  - "Canonical baseline for run 31322443304 with provider-enforcement snapshot"
  - "Fail-closed proof-state and privacy contract"
affects: [phase-226-plan-02, phase-227, release-gate]
tech-stack:
  added: []
  patterns:
    - "Reduce Actions API responses immediately to an explicit metadata allowlist."
    - "Derive proved only from required first-attempt eligible success."
key-files:
  created:
    - scripts/ci/capture_ci_baseline.sh
    - scripts/ci/verify_ci_baseline_contract.sh
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md
  modified: []
key-decisions:
  - "GitHub effective rules plus classic branch protection, not CI YAML, define external enforcement."
  - "The observed empty-rules and classic-404 responses are recorded as none-enforced."
  - "Unsafe metadata shapes and query-bearing URLs fail the contract rather than being redacted."
requirements-completed: [BASE-01, BASE-02]
coverage:
  - id: D1
    description: "Read-only collector reproduces the fixed run identity and wall duration using only allowlisted metadata."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "bash scripts/ci/capture_ci_baseline.sh --run-id 31322443304 --output <temporary-file> && bash scripts/ci/verify_ci_baseline_contract.sh --input <temporary-file>"
        status: pass
    human_judgment: false
  - id: D2
    description: "Proof states and unsafe metadata negative controls are mechanically enforced."
    requirement: BASE-02
    verification:
      - kind: unit
        ref: "bash scripts/ci/verify_ci_baseline_contract.sh --self-test"
        status: pass
    human_judgment: false
duration: 35m
completed: 2026-08-09
status: complete
---

# Phase 226 Plan 01: CI Baseline Tracer Summary

**A metadata-only, fail-closed Actions baseline now records repair run 31322443304’s 2,380-second wall time, approximately 39m36s required chain, and explicit provider proof semantics.**

## Accomplishments

- Added a strict `gh`/`jq` collector with numeric input validation, atomic output, read-only versioned API calls, fixture mode, and immediate allowlisted reduction.
- Recorded the first canonical run, its 11-second required-chain queue delay, 20 observed lanes, artifacts as metadata only, and GitHub’s `none-enforced` rules/404 snapshot.
- Added synthetic required/advisory/skipped/not-applicable coverage and privacy negative controls for secret/environment/payload-shaped fields and query-bearing URLs.

## Task Commits

1. **Task 1: Trace run 31322443304 from Actions metadata to a verified baseline** — `79f46302` (TDD RED), `66cf6d8c` (feat)
2. **Task 2: Enforce proof-state semantics and privacy negative controls** — `2b4686f6` (test)

## Files Created/Modified

- `scripts/ci/capture_ci_baseline.sh` — API-versioned metadata-only live and fixture collector.
- `scripts/ci/verify_ci_baseline_contract.sh` — schema, privacy, policy, and proof-state contract with synthetic tests.
- `226-CI-BASELINE.json` — canonical facts for the repair run.
- `226-CI-BASELINE.md` — concise authoritative-JSON review rendering.

## Decisions Made

- GitHub provider responses are the authority for externally enforced checks; YAML remains taxonomy only.
- Provider omissions remain null; cache hits are recorded only when an explicit skipped PLT-create step supports the observation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected jq composition in the collector’s classic required-check reduction.**
- **Found during:** Task 1
- **Fix:** Parenthesized the two allowlisted check arrays and constructed the record with `jq -n`.
- **Verification:** Fixture self-test and live read-only collection pass.

**2. [Rule 1 - Bug] Corrected the privacy contract to permit its explicit boolean absence indicators.**
- **Found during:** Task 2
- **Fix:** Kept `logs_downloaded`, `artifact_archives_downloaded`, `env_values_recorded`, and `raw_payloads_recorded` as safe false-only fields while rejecting unsafe arbitrary keys.
- **Verification:** Synthetic unsafe-key and query-URL controls fail closed.

## Issues Encountered

None remaining.

## User Setup Required

None — live collection uses the maintainer’s existing read-only `gh` authentication.

## Next Phase Readiness

Plan 02 can consume the canonical JSON and its documented provider-policy boundary. It must not treat workflow success, artifacts, advisory lanes, or skipped lanes as release proof.

## Self-Check: PASSED

- Confirmed collector, contract, canonical JSON, and Markdown baseline exist.
- Confirmed RED, feature, and proof/privacy test commits exist in git history.
