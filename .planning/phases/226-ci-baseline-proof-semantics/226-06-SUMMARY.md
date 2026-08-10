---
phase: 226-ci-baseline-proof-semantics
plan: "06"
subsystem: ci-evidence
tags: [bash, github-actions, evidence, pagination, phase192]
requires:
  - phase: 226-05
    provides: Exact collector-record schema and proof semantics
provides:
  - Corrected v2 comparable CI baseline evidence
  - Live GitHub pagination support for metadata-only collection
  - Executable negative-control validation map
affects: [227-critical-path-optimization, ci-baseline]
tech-stack:
  added: []
  patterns: [canonical-json-derived-markdown, bounded-total-count-pagination, eligible-only-proof]
key-files:
  created: [226-06-SUMMARY.md]
  modified:
    - scripts/ci/capture_ci_baseline.sh
    - scripts/ci/verify_ci_baseline_contract.sh
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
key-decisions:
  - "Initial runner queue and staged critical-chain duration are separate evidence fields."
  - "Live list pagination is bounded from total_count because GitHub places navigation in response headers."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: Corrected three-run canonical CI evidence with eligible-only proof and provider snapshot.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_ci_baseline_contract.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Deterministic negative controls for privacy, provider, proof, pagination, timing, and signatures.
    requirement: BASE-02
    verification:
      - kind: unit
        ref: bash scripts/ci/verify_ci_baseline_contract.sh --self-test
        status: pass
    human_judgment: false
  - id: D3
    description: Preserved setup ownership, CI topology, and Phase 192 artifact contract.
    requirement: OWN-01
    verification:
      - kind: integration
        ref: bash scripts/ci/verify_phase192_ci_contract.sh
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-08-10
status: complete
---

# Phase 226 Plan 06: Corrected Baseline Publication Summary

**Canonical CI evidence now records seconds-scale runner queue independently from the staged critical path, with eligible-only proof and timestamp-scoped provider state.**

## Accomplishments

- Recollected the immutable three-run cohort through authenticated GETs and published a v2 canonical JSON/Markdown pair.
- Corrected live pagination handling, then made canonical validation recompute queue, chain, proof, and provenance facts.
- Documented executable negative controls while retaining stable CI topology, ownership, cache setup, and Phase 192 contracts.

## Task Commits

1. Task 1 — `6540f6e4` `fix(226-06): regenerate corrected CI baseline evidence`
2. Task 2 — `b1c12639` `docs(226-06): certify CI baseline gap closure`

## Verification

- `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` — passed.
- Read-only collector for run `31322443304` followed by record-mode `--input` validation — passed.
- `bash scripts/ci/verify_ci_baseline_contract.sh` — passed.
- `bash scripts/ci/verify_phase192_ci_contract.sh` — passed.
- `git diff --check` and the protected workflow/ownership/Phase 192 empty-diff check — passed.

## Decisions Made

- Treat the structured v2 JSON as authority and Markdown as a derived rendering with no independent estimates.
- Derive bounded live pagination from `total_count`; fixture-only navigation fields are not required in GitHub REST bodies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the collector's live pagination contract**
- **Found during:** Task 1
- **Issue:** The collector expected a `next_page` body key which GitHub REST list responses do not provide, rejecting valid authenticated metadata.
- **Fix:** Retained strict fixture pagination and derived bounded live pages from `total_count`; updated canonical validation for v2 evidence.
- **Files modified:** `scripts/ci/capture_ci_baseline.sh`, `scripts/ci/verify_ci_baseline_contract.sh`
- **Verification:** Live one-run collector record and full self-test suite passed.
- **Commit:** `6540f6e4`

**Total deviations:** 1 auto-fixed (Rule 1 bug).

## Known Stubs

None.

## Next Phase Readiness

Phase 227 can select only the cohort-backed measured candidates from the corrected JSON baseline.

## Self-Check: PASSED

- Confirmed the five changed CI evidence and validation files exist.
- Confirmed task commits `6540f6e4` and `b1c12639` exist.
