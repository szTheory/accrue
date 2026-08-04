---
phase: 220-first-adopter-proof-and-release-gates
plan: 06
subsystem: release-contracts
tags: [v1.59, ci, documentation, release-gates, exunit]
requires:
  - phase: 220-04
    provides: Versioned public-contract fixture, generated matrix, and canonical scenario gate
  - phase: 220-05
    provides: Hand-authored first-adopter recipe, App Review guide, runbooks, release notes, and watchlist
provides:
  - One deterministic release-contract command coordinating generated facts and authored procedures
  - Isolated known-bad evidence for v1.59 claim, privacy, procedure, and inventory drift
affects: [PROOF-01, PROOF-02, PROOF-03, PROOF-04, PROOF-05, docs-contracts-shift-left]
tech-stack:
  added: []
  patterns: [canonical-gate-composition, region-scoped-prose-contradiction-checks, isolated-doc-fixtures]
key-files:
  created:
    - accrue/test/accrue/docs/v159_release_contract_test.exs
  modified:
    - scripts/ci/verify_adoption_proof_matrix.sh
    - scripts/ci/verify_release_contract.sh
    - scripts/ci/README.md
key-decisions:
  - "The coordinated gate composes the Plan-04 reference scenario check instead of duplicating exact fixture needles."
  - "Contradiction checks scan public/procedure regions while retaining explicit prohibition language in runbooks."
patterns-established:
  - "Use ROOT_DIR isolated copies plus V159_SOURCE_ROOT canonical release metadata for adversarial shell-gate tests."
requirements-completed: [PROOF-01, PROOF-02, PROOF-03, PROOF-04, PROOF-05]
coverage:
  - id: D1
    description: Coordinated v1.59 command validates the fixture/matrix, adoption route, authored release contract, and linked-release checks.
    requirement: PROOF-05
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_release_contract.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Isolated known-bad public claims, privacy exposure, missing procedure/watchlist content, and backend-first copy fail with the owning artifact.
    requirement: PROOF-05
    verification:
      - kind: unit
        ref: accrue/test/accrue/docs/v159_release_contract_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 7min
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 06: Release-contract drift gates Summary

**One v1.59 merge gate now composes generated evidence, adopter guidance, release procedures, and adversarial documentation checks without competing with fixture authority.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-04T16:08:00Z
- **Completed:** 2026-08-04T16:15:33Z
- **Tasks:** 1/1
- **Files modified:** 4

## Accomplishments

- Composed the canonical reference-scenario and adoption-matrix checks into `verify_release_contract.sh`, then validated exact scenario IDs and the authored recipe, App Review, privacy, release-note, runbook, and watchlist contracts.
- Added region-scoped contradiction checks for runtime feasibility, Apple lifecycle ownership, automatic cross-rail mutation, stale value expansion, private-data exposure, and backend-first procedure drift.
- Added clean-source and isolated known-bad ExUnit coverage, plus CI ownership, co-update, and failure-triage guidance.

## Task Commits

1. **Task 1: Coordinate public-contract, adoption, and release drift gates** — `e3e6d41e` (RED tests), `87cdd549` (implementation), `1ee6ef50` (format), `9f50d1fd` (compatibility fix)

## Files Created/Modified

- `scripts/ci/verify_adoption_proof_matrix.sh` — checks the compact v1.59 adopter path while preserving the existing ORG-09 output contract.
- `scripts/ci/verify_release_contract.sh` — coordinates canonical generated checks with authored-document drift checks and precise ownership failures.
- `scripts/ci/README.md` — documents the one command, merge owner, co-update boundary, and triage path.
- `accrue/test/accrue/docs/v159_release_contract_test.exs` — exercises clean and isolated known-bad release-contract sources.

## Decisions Made

- Exact fixture/matrix semantics remain solely in the Plan-04 canonical gate; the release gate invokes it rather than copying its facts.
- Tests use isolated documentation copies but retain the canonical repository’s pre-existing linked-release configuration, so adversarial cases never mutate source material.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Formatted the new ExUnit contract file.**
- **Found during:** Task 1 verification
- **Issue:** `mix test.all` rejected the new test under `--check-formatted`.
- **Fix:** Applied `mix format` and committed the formatter-only result.
- **Files modified:** `accrue/test/accrue/docs/v159_release_contract_test.exs`
- **Verification:** focused suite and `mix test.all` passed.
- **Committed in:** `1ee6ef50`

**2. [Rule 1 - Bug] Preserved the existing adoption-gate success message.**
- **Found during:** Task 1 verification
- **Issue:** an older ORG-09 test expects `verify_adoption_proof_matrix: OK` exactly as a substring.
- **Fix:** Kept that output and emitted the v1.59 success line separately.
- **Files modified:** `scripts/ci/verify_adoption_proof_matrix.sh`
- **Verification:** `mix test.all` passed.
- **Committed in:** `9f50d1fd`

**Total deviations:** 2 auto-fixed (Rule 3 blocking, Rule 1 bug). No scope expansion.

## Issues Encountered

- `examples/accrue_host && mix verify.full` has one unrelated failure in `AccrueHost.BillingFacadeTest`: duplicate `accrue_subscriptions_processor_processor_id_index` for the Fake-backed subscription. The task does not touch billing persistence or host fixtures, so it remains deferred rather than being changed here.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all four task artifacts exist and all task commits (`e3e6d41e`, `87cdd549`, `1ee6ef50`, `9f50d1fd`) are present in git history.

## Next Phase Readiness

- The release-contract command and focused contract suite are green.
- The unrelated host full-suite uniqueness failure should be resolved before relying on `mix verify.full` as phase-wide green evidence.

---
*Phase: 220-first-adopter-proof-and-release-gates*
*Completed: 2026-08-04*
