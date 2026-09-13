---
phase: 226-ci-baseline-proof-semantics
plan: "16"
subsystem: ci-evidence
tags: [github-actions, baseline, dag-compatibility, runner-cohorts]
requires:
  - phase: 226-ci-baseline-proof-semantics
    provides: exact workflow display-name and staged-path baseline controls
provides:
  - Exact-attempt job isolation and workflow-declared runner cohorting
  - Bounded, auditable historical DAG compatibility inventory with fail-closed future bounds
  - Fresh 90-day canonical CI evidence with deterministic critical-path rendering
affects: [BASE-01, BASE-02, OWN-01]
tech-stack:
  added: []
  patterns: [attempt-scoped Actions API, trusted workflow runner resolver, historical compatibility table, atomic evidence replacement]
key-files:
  created: []
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
decisions:
  - Historical DAG compatibility is an explicit repository-scoped table bounded before 2026-08-12T14:00:00Z, never a generic missing-prerequisite fallback.
  - Current and future runs, different repositories, and unmatched job identities remain fail-closed.
  - The canonical evidence is replaced only after a fresh temporary collection, critical-path validation, and byte-identical independent renders.
metrics:
  duration: 50m
  completed: 2026-08-12
status: complete
---

# Phase 226 Plan 16: Exact Attempt and Historical DAG Evidence Summary

The CI baseline now uses exact Actions attempts, trusted workflow runner contracts, and a bounded historical DAG inventory to generate a fresh, privacy-safe 90-day critical-path record.

## Completed Tasks

1. Added RED/GREEN regressions for attempt-scoped job retrieval, trusted runner cohorts, historical workflow topology compatibility, and future-negative controls.
2. Recollected the canonical NDJSON from read-only Actions metadata, validated twenty staged paths, rendered twice, byte-compared, and installed the matching Markdown report.

## Verification

- `node --check scripts/ci/collect_ci_baseline.mjs`
- `node --check scripts/ci/render_ci_baseline.mjs`
- `node --check scripts/ci/verify_ci_baseline.mjs`
- `node --check scripts/ci/verify_provider_proof.mjs`
- `node scripts/ci/verify_ci_baseline.mjs --fixtures`
- `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path`
- `node scripts/ci/verify_provider_proof.mjs --fixtures`
- `(cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors)`
- `bash scripts/ci/verify_ci_setup_diagnostics.sh`
- `bash scripts/ci/verify_phase225_required_lane_evidence.sh`

All passed. The authenticated read-only collection produced 3,014 NDJSON records, with twenty compatible complete staged paths and byte-identical independent renders.

## Commits

- `3b03e0a6` — `test(226-16): add failing attempt and runner cohort controls`
- `87eb235e` — `feat(226-16): isolate CI attempts and trusted runners`
- `fdeca18f` — `test(226-16): cover historical scheduled admin topology`
- `5558f7d6` — `feat(226-16): preserve scheduled admin DAG topology`
- `55860edf` — `test(226-16): inventory historical DAG compatibility`
- `0d88dacd` — `feat(226-16): inventory historical CI DAG compatibility`
- `85258034` — `docs(226-16): recollect repaired CI baseline evidence`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Inventory all historical DAG mismatches before evidence replacement**
- **Found during:** Task 2 precondition collection.
- **Issue:** The initial scheduled-root repair exposed the next missing prerequisite one at a time, so it could not demonstrate a complete historical candidate inventory.
- **Fix:** Added a centralized compatibility table with repository, event, job identity, prerequisite, and time bounds; collection now aggregates unresolved prerequisites before record emission.
- **Files modified:** `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/verify_ci_baseline.mjs`.
- **Verification:** Focused fixtures cover each accepted mapping and future-negative controls; the fresh 90-day collection is clean.
- **Commit:** `0d88dacd`.

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Historical compatibility is auditable and bounded without changing current workflow topology or weakening unknown-run rejection.

## Known Stubs

None.

## Self-Check: PASSED

- All five modified plan artifacts exist.
- All seven Plan 16 commits are present in Git history.
