---
phase: 226-ci-baseline-proof-semantics
plan: "06"
subsystem: ci
tags: [github-actions, ci-baseline, provider-proof, timestamp-validation, tdd]
requires:
  - phase: 226-05
    provides: CI baseline and provider-proof fixture contracts
provides:
  - Full-CI push and pull-request timing cohorts that remain independent of provider proof state
  - Fail-closed canonical UTC validation for baseline timing and provider freshness inputs
affects: [phase-226-07-baseline-refresh, ci-maintenance, provider-parity]
tech-stack:
  added: []
  patterns: [event-topology timing eligibility, canonical UTC round-trip validation, deterministic fixture regression]
key-files:
  created: [.planning/phases/226-ci-baseline-proof-semantics/226-06-SUMMARY.md]
  modified: [scripts/ci/collect_ci_baseline.mjs, scripts/ci/verify_ci_baseline.mjs, scripts/ci/provider_proof.mjs, scripts/ci/verify_provider_proof.mjs]
key-decisions:
  - "Full-CI timing eligibility is independent of provider proof state; non_run remains recorded as no provider proof."
  - "Baseline and provider timestamps must round-trip through canonical UTC before duration or freshness arithmetic."
patterns-established:
  - "Timing cohorts: use full-CI event topology, green first attempts, original-run/SHA deduplication, and the 90-day window; never provider proof state."
  - "Timestamps: accept only whole-second or millisecond UTC spellings that canonicalize exactly through Date.toISOString()."
requirements-completed: [BASE-01, BASE-02]
coverage:
  - id: D1
    description: Full-CI push and pull-request non_run histories form separate ready 20-run timing cohorts without asserting provider proof.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: node scripts/ci/verify_ci_baseline.mjs --fixtures
        status: pass
    human_judgment: false
  - id: D2
    description: Baseline and provider proof paths reject impossible calendar dates before duration or freshness arithmetic.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_provider_proof.mjs --fixtures
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-11
status: complete
---

# Phase 226 Plan 06: CI Baseline Proof Semantics Summary

**Full-CI non_run push and pull-request histories now form truthful timing cohorts, and both proof paths reject calendar-impossible UTC timestamps before arithmetic.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-11T21:03:00Z
- **Completed:** 2026-08-11T21:15:16Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Qualified green timing samples by full-CI event topology, successful first attempt, original-run/SHA identity, and the rolling 90-day window—not provider proof state.
- Added deterministic 20-run push and pull-request `non_run` cohorts that prove separate ready p50/p95 timing populations while retaining literal `non_run` records.
- Hardened baseline and provider timestamp validators with exact UTC grammar plus canonical `Date.toISOString()` round-trip checks, including impossible-day and invalid-leap-day regressions.

## Task Commits

1. **Task 1: Prove a 20-run non_run full-CI cohort end to end** — `1e117e58` (test), `90f77e3a` (feat)
2. **Task 2: Reject impossible canonical-looking UTC timestamps in both proof paths** — `37ac2c7f` (test), `bf8f0aeb` (feat)

## Files Created/Modified

- `scripts/ci/collect_ci_baseline.mjs` — decouples timing eligibility from provider proof and validates canonical timestamps before duration calculations.
- `scripts/ci/verify_ci_baseline.mjs` — covers non_run full-CI cohorts plus invalid-day and valid-leap-day timestamp controls.
- `scripts/ci/provider_proof.mjs` — validates provider manifest and freshness timestamps through canonical UTC round trips.
- `scripts/ci/verify_provider_proof.mjs` — covers invalid-day, invalid-leap-day, and valid-leap-day provider timestamp controls.

## Decisions Made

- `provider_state: non_run` means no provider proof for the SHA; it is not evidence that an ordinary successful full-CI run is unusable for timing.
- Schedule remains provider-only and excluded from timing samples; push and pull-request continue to use distinct cohort fingerprints.
- Supported UTC whole-second strings canonicalize to `.000Z`; any parsed value that changes calendar fields fails closed.

## Verification

Passed:

```bash
node --check scripts/ci/collect_ci_baseline.mjs && \
node --check scripts/ci/verify_ci_baseline.mjs && \
node --check scripts/ci/provider_proof.mjs && \
node --check scripts/ci/verify_provider_proof.mjs && \
node scripts/ci/verify_ci_baseline.mjs --fixtures && \
node scripts/ci/verify_provider_proof.mjs --fixtures
```

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

Plan 226-07 can recollect the post-repair timing snapshot without changing privacy allowlists, provider-state semantics, or provider promotion negatives.

## Self-Check: PASSED

- Confirmed all four modified CI scripts exist.
- Confirmed task commits `1e117e58`, `90f77e3a`, `37ac2c7f`, and `bf8f0aeb` exist in git history.
