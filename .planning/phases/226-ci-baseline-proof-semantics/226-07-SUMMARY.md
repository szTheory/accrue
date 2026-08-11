---
phase: 226-ci-baseline-proof-semantics
plan: "07"
subsystem: ci
tags: [github-actions, critical-path, percentiles, deterministic-evidence, tdd]
requires:
  - phase: 226-06
    provides: Repaired full-CI cohort eligibility and canonical timestamp validation
provides:
  - Deterministic release-gate through latest-Playwright staged-path derivation
  - Required critical-path validation and confirmed/contrary report grammar
  - Live-history diagnosis proving exact-fingerprint readiness is over-constrained
affects: [phase-226-08-compatible-critical-path, ci-baseline, critical-path-reporting]
tech-stack:
  added: []
  patterns: [per-run staged spans, latest parallel-shard completion, byte-exact critical-path validation]
key-files:
  created: [.planning/phases/226-ci-baseline-proof-semantics/226-07-SUMMARY.md]
  modified: [scripts/ci/render_ci_baseline.mjs, scripts/ci/verify_ci_baseline.mjs]
key-decisions:
  - "Measure release-gate start through the latest Playwright shard completion; never sum parallel shards."
  - "Split live recollection into Plan 226-08 after direct history inspection disproved the exact-20-fingerprint availability assumption."
patterns-established:
  - "Critical-path evidence: derive spans per successful first-attempt run and render literal p50/p95 plus confirmed or contrary_measured_result."
requirements-completed: []
coverage:
  - id: D1
    description: The renderer and verifier share deterministic staged-path derivation with missing-stage, ordering, rerun, under-sample, cross-cohort, and parallel-shard controls.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: node scripts/ci/verify_ci_baseline.mjs --fixtures
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-11
status: complete
---

# Phase 226 Plan 07: Staged Critical-Path Derivation Summary

**Per-run release-to-latest-Playwright percentile derivation is deterministic and tested; live recollection moved to Plan 226-08 because direct Actions history invalidated the exact-fingerprint readiness assumption.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-11T21:58:00Z
- **Completed:** 2026-08-11T22:10:00Z
- **Tasks:** 1/1 implemented; the original live-evidence task was superseded by Plan 226-08
- **Files modified:** 2

## Accomplishments

- Added deterministic staged-path fixtures covering 20 ordered full-CI runs and critical negative controls.
- Added shared release-gate → host-integration → latest Playwright derivation plus confirmed/contrary rendering and `--require-critical-path` enforcement.
- Diagnosed the live checkpoint with a read-only 90-day collection: 28/28 successful first attempts have complete paths, but 149 fingerprints split them into cohorts of at most four.

## Task Commits

1. **Task 1: Trace staged paths into a percentile conclusion** — `7c5027d5` (test), `c293e08b` (feat)

## Files Created/Modified

- `scripts/ci/render_ci_baseline.mjs` — derives per-run staged spans and renders literal percentile conclusions.
- `scripts/ci/verify_ci_baseline.mjs` — verifies deterministic fixtures and required critical-path report content.

## Decisions Made

- The exact-fingerprint sample threshold is not a truthful availability gate for this repository: ordinary workflow/job-set evolution fragments otherwise complete full-CI evidence.
- Plan 226-08 will select the latest 20 compatible complete paths, retain fingerprints as strata, and report cohort sensitivity rather than requiring one stratum to contain all 20 observations.

## Deviations from Plan

### Scope split after blocking checkpoint

- **Found during:** Original Task 2 live recollection
- **Issue:** The plan assumed one exact fingerprint could supply 20 successes. Live history instead contains 28 complete eligible paths across 12 strata, with a maximum stratum size of four.
- **Resolution:** Preserve the completed, tested derivation work in this summary and transfer recollection plus compatible-sample semantics to Plan 226-08.
- **Impact:** No evidence was fabricated or broadened silently; the changed comparability rule is explicit and independently testable.

## Issues Encountered

The original checkpoint message said there were zero complete staged spans. Direct inspection showed that all 28 successful first-attempt full-CI runs had complete ordered spans; zero was an artifact of counting spans only after exact-cohort readiness.

## Verification

Passed:

```bash
node --check scripts/ci/render_ci_baseline.mjs && \
node --check scripts/ci/verify_ci_baseline.mjs && \
node scripts/ci/verify_ci_baseline.mjs --fixtures
```

## User Setup Required

None.

## Next Phase Readiness

Plan 226-08 can revise the compatibility predicate, recollect the already-sufficient live history, freeze byte-reproducible artifacts, and run the complete Phase 226 contract.

## Self-Check: PASSED

- Confirmed commits `7c5027d5` and `c293e08b` exist.
- Confirmed the fixture gate passes.
- Confirmed the frozen NDJSON, frozen Markdown, and `226-VALIDATION.md` were untouched by the blocked recollection.

---
*Phase: 226-ci-baseline-proof-semantics*
*Completed: 2026-08-11*
