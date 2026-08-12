---
phase: 226-ci-baseline-proof-semantics
plan: "14"
subsystem: ci-evidence
tags: [github-actions, baseline, provider-proof, node]
requires:
  - phase: 226-13
    provides: fail-closed prerequisite diagnostics and Phase 226 evidence contracts
provides:
  - Live Actions collection keyed consistently by normalized display identities
  - Current-SHA provider proof freshness anchored to validated manifest completion
affects: [ci-baseline, provider-proof, phase-227]
tech-stack:
  added: []
  patterns: [injected read-only Actions fixture seam, proof-first freshness anchoring]
key-files:
  created: []
  modified: [scripts/ci/collect_ci_baseline.mjs, scripts/ci/verify_ci_baseline.mjs, scripts/ci/provider_proof.mjs, scripts/ci/verify_provider_proof.mjs, .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md]
key-decisions:
  - "Workflow dependencies resolve in normalized observed display-name space, not YAML job-ID space."
  - "Only a fully validated proved record rebases freshness to its own SHA and manifest completion."
patterns-established:
  - "Live Actions collectors expose a narrow injected page-fetch seam for deterministic integration fixtures."
  - "Provider freshness is rederived only after every proof predicate succeeds."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: "Current Actions display identities emit fail-closed durable baseline timing records."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: "A newly successful manifest-backed provider proof renders fresh for its current SHA."
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_provider_proof.mjs --fixtures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Setup ownership and required-lane evidence remain unchanged and green."
    requirement: OWN-01
    verification:
      - kind: other
        ref: "bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-08-12
status: complete
---

# Phase 226 Plan 14: CI baseline proof semantics Summary

**Current GitHub Actions display names now flow into baseline DAG timing, while newly proved provider records immediately render fresh from their own trusted completion.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-12T02:36:47Z
- **Completed:** 2026-08-12T02:39:56Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Normalized live collector prerequisites against observed Actions display names and covered the live mapping with injected API-shaped fixtures.
- Bound proved proof records to the current SHA and validated manifest `finished_at`, then rederived freshness for the actual summary.
- Preserved and reran frozen critical-path, formatter, setup-ownership, and Phase 225 required-lane contracts.

## Task Commits

1. **Task 1: Trace current Actions display identities through liveRuns and collectBaseline** - `8450f8e2` (RED), `65cb357d` (GREEN)
2. **Task 2: Bind a newly proved provider record to its current SHA and trusted completion** - `33b6a549` (RED), `0280b00a` (GREEN)

## Files Created/Modified

- `scripts/ci/collect_ci_baseline.mjs` - Normalized workflow prerequisites and provided the injected live page-fetch seam.
- `scripts/ci/verify_ci_baseline.mjs` - Exercises current API-shaped display identities and negative timing controls.
- `scripts/ci/provider_proof.mjs` - Anchors a proved record to current SHA and validated completion before freshness derivation.
- `scripts/ci/verify_provider_proof.mjs` - Verifies fresh current proof rendering and static finalizer-to-summary workflow wiring.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md` - Records both Plan 14 gates as executed green and approves all eighteen rows.

## Decisions Made

- Workflow topology remains expressed by YAML identifiers, but its runtime prerequisite lookup uses only normalized observed display identities.
- Non-proved paths retain their prior proof anchor; only a fully proved record may replace it.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 226's baseline, provider proof, and ownership contracts are green for Phase 227 consumption.

## Self-Check: PASSED

- Verified all five modified artifacts exist.
- Verified task commits `8450f8e2`, `65cb357d`, `33b6a549`, and `0280b00a` exist in Git history.

