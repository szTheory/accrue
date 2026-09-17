---
phase: 226-ci-baseline-proof-semantics
plan: "20"
subsystem: ci-evidence
tags: [github-actions, provenance, ndjson, markdown, validation]
requires:
  - phase: 226-19
    provides: provider, formatter, setup, and required-lane preservation contracts
provides:
  - per-run head-SHA workflow contract binding
  - semantically validated and injection-safe baseline rendering
  - refreshed byte-reproducible 90-day CI baseline
affects: [227-critical-path-optimization]
tech-stack:
  added: []
  patterns: [immutable-workflow-source-per-run, semantic-ndjson-validation, paired-evidence-transaction]
key-files:
  created: []
  modified: [scripts/ci/collect_ci_baseline.mjs, scripts/ci/verify_ci_baseline.mjs, .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson, .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md, .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md]
key-decisions:
  - "Use fetched head-SHA workflow bytes as the authoritative historical job contract."
  - "Reject invalid persisted records before any Markdown interpolation."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: Historical job topology, runner, and DAG timing derive from the workflow source at each run head SHA.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: scripts/ci/verify_ci_baseline.mjs --fixtures
        status: pass
    human_judgment: false
  - id: D2
    description: The canonical baseline pair is semantically valid, byte-reproducible, and retains the measured critical-path conclusion.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-12
status: complete
---

# Phase 226 Plan 20: Historical CI Baseline Semantics Summary

**Historical workflow topology is bound to immutable head-SHA sources, with a freshly authenticated, byte-reproducible 20-path CI baseline (p50 2083s, p95 2602s, confirmed).**

## Accomplishments

- Fetched and parsed each run's historical workflow bytes for identity, runner, prerequisite, and timing decisions.
- Enforced semantic NDJSON validation and immutable GitHub evidence URLs before Markdown rendering.
- Recollected and independently reproduced the frozen baseline pair; provider, formatter, setup, and required-lane contracts stayed green.

## Task Commits

1. Task 1 — `9f39d738` feat: immutable workflow contracts and forged-render controls.
2. Task 2 — `e5689c17` feat: authenticated baseline recollection and paired installation.
3. Task 3 — `3bf3c67e` docs: executed validation evidence and Phase 227 frozen-input note.

## Decisions Made

- The fetched workflow source, not current checkout topology, is the historical evidence authority.
- Renderer input is fully validated so persisted values cannot inject headings or link destinations.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Matrix prerequisite aliases were not retained for exact timestamp lookup.
- Found during: Task 2
- Fix: Resolve declared matrix prerequisites to their observed Actions alias before record normalization.
- Verification: Fresh collection and complete baseline verifier passed.
- Commit: `e5689c17`

## Verification

- `node scripts/ci/verify_ci_baseline.mjs --fixtures` — passed.
- Installed critical-path verifier, provider fixtures, formatter ExUnit test, setup diagnostics, and required-lane evidence — passed.

## Next Phase Readiness

Phase 227 can consume the canonical NDJSON/Markdown pair as its frozen before-state.

## Self-Check: PASSED

- Required canonical artifacts and all three task commits exist.
