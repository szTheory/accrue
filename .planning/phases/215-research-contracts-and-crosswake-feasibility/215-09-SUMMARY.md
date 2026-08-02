---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 09
subsystem: entitlements-contract-testing
tags: [elixir, exunit, offline-entitlements, canonical-contract, json]
requires:
  - phase: 215-08
    provides: shared v1.59 offline golden corpus and deterministic replacement evidence
provides:
  - Correct lease and continuity projection in the generated decision table
  - Exhaustive offline corpus drift rejection for schema, vectors, and bindings
  - Elixir fixture binding to canonical DecisionCases before observation
affects: [215-10, 217, 219]
tech-stack:
  added: []
  patterns: [closed canonical corpus comparison, pre-observation fixture binding]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/decision_cases/markdown.ex
    - .planning/research/v1.59-DECISION-TABLE.md
    - accrue/test/support/entitlements/offline_golden_vector_verifier.ex
    - accrue/test/accrue/entitlements/decision_cases_test.exs
    - accrue/test/accrue/entitlements/offline_golden_vectors_test.exs
key-decisions:
  - "Render canonical continuity separately from lease and make corpus metadata drift merge-blocking."
requirements-completed: [RSCH-02, RAIL-05]
coverage:
  - id: D1
    description: Generated decision table distinguishes lease from continuity and rejects complete corpus drift.
    requirement: RSCH-02
    verification:
      - kind: unit
        ref: mix accrue.entitlements.decision_cases --check; test/accrue/entitlements/decision_cases_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Elixir offline-vector reader binds schema, vector identity, case ID, version, and disposition before cryptographic observation.
    requirement: RAIL-05
    verification:
      - kind: unit
        ref: test/accrue/entitlements/offline_golden_vectors_test.exs
        status: pass
    human_judgment: false
duration: 18m
completed: 2026-08-02
status: complete
---

# Phase 215 Plan 09: Offline Contract Binding Summary

**Canonical v1.59 decision-table semantics and Elixir corpus validation now reject lease/continuity confusion and every tested metadata drift before vector observations run.**

## Performance

- **Duration:** 18m
- **Completed:** 2026-08-02
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Rendered Lease and Continuity as distinct canonical columns, with the maintainer table regenerated from DecisionCases.
- Replaced the partial offline drift oracle with exact schema, identity, key-set, vector-field, and optional fault-point validation.
- Bound each Elixir vector to canonical case ID, contract version, and expected disposition before cryptographic and cache observation.

## Task Commits

1. **Task 1: Trace one canonical case through correct Continuity rendering and full corpus drift rejection** — `8ee40e57`, `220133a3`
2. **Task 2: Bind every Elixir vector observation to canonical case metadata** — `d36a12db`, `73e79286`

## Files Created/Modified

- `accrue/lib/accrue/entitlements/decision_cases/markdown.ex` — Correct decision table projection and complete generated-corpus oracle.
- `.planning/research/v1.59-DECISION-TABLE.md` — Regenerated semantic maintainer view.
- `accrue/test/accrue/entitlements/decision_cases_test.exs` — Exhaustive deterministic corpus mutation coverage.
- `accrue/test/support/entitlements/offline_golden_vector_verifier.ex` — Canonical pre-observation binding boundary.
- `accrue/test/accrue/entitlements/offline_golden_vectors_test.exs` — Canonical metadata and duplicate-ID regressions.

## Decisions Made

- Canonical continuity is displayed independently of the lease/freshness state.
- Fixture outcomes are trusted only after schema, unique identity, and canonical case/version/disposition binding succeeds.
- Production reducer equivalence remains intentionally unresolved for Phase 217; this plan changes only generated and test-support consumers.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Verification

- `mix accrue.entitlements.decision_cases --check` — passed.
- `mix test test/accrue/entitlements/decision_cases_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs` — passed (20 tests).
- API coverage artifact existence and no-external-integration declaration — passed.

## Next Phase Readiness

Phase 215-10 can consume the corrected corpus to enforce matching Swift schema and canonical binding rules. The Phase-217 production-reducer-equivalence backstop remains unresolved by design.

## Self-Check: PASSED

- Confirmed the five implementation/test artifacts and regenerated decision table exist.
- Confirmed commits `8ee40e57`, `220133a3`, `d36a12db`, and `73e79286` exist in git history.
