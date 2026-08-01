---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 03
subsystem: entitlements
tags: [elixir, exunit, streamdata, json, contracts]
requires:
  - phase: 215-01
    provides: v1.59 feasibility and entitlement contract context
provides:
  - Versioned internal data-only entitlement decision corpus
  - Deterministic Markdown and JSON contract exports
  - Property-backed ordering, duplicate, survivor, and atomicity invariants
affects: [216-projection, 217-entitlements, 219-offline-client, documentation]
tech-stack:
  added: []
  patterns: [internal data-only contract, deterministic generated fixtures, StreamData contract properties]
key-files:
  created:
    - accrue/lib/accrue/entitlements/decision_cases.ex
    - accrue/lib/accrue/entitlements/decision_cases/markdown.ex
    - accrue/lib/mix/tasks/accrue.entitlements.decision_cases.ex
    - accrue/priv/entitlements/v1.59-decision-cases.json
    - accrue/test/property/entitlement_decision_cases_property_test.exs
  modified:
    - .planning/research/v1.59-DECISION-TABLE.md
    - accrue/test/accrue/entitlements/decision_cases_test.exs
key-decisions:
  - "Decision cases remain internal data-only structs; renderers and exports do not implement reducer logic."
  - "Generated Markdown and JSON fail closed on byte drift through a bounded Mix task."
patterns-established:
  - "Canonical case source: later consumers derive from DecisionCases.all/0, never a second decision implementation."
requirements-completed: [RSCH-02]
coverage:
  - id: D1
    description: Versioned, validated internal entitlement decision corpus
    requirement: RSCH-02
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/decision_cases_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Deterministic checked-in Markdown and JSON views
    requirement: RSCH-02
    verification:
      - kind: unit
        ref: mix accrue.entitlements.decision_cases --check
        status: pass
    human_judgment: false
  - id: D3
    description: Duplicate, ordering, survivor, and transaction contract properties
    requirement: RSCH-02
    verification:
      - kind: unit
        ref: accrue/test/property/entitlement_decision_cases_property_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 20min
  completed: 2026-07-31
status: complete
---

# Phase 215 Plan 03: Decision-Case Contract Summary

**A versioned, privacy-safe entitlement decision corpus now deterministically drives maintainer Markdown, language-neutral JSON, exhaustive validation, and property evidence without becoming runtime logic.**

## Accomplishments

- Added closed D-07 internal structs and an ordered v1.59 corpus covering duplicate, ordering, survivor, revocation, eligibility, stale continuity, reconnect, and atomic transaction cases.
- Added a deterministic `mix accrue.entitlements.decision_cases --write|--check` producer for checked-in derived Markdown and JSON fixtures.
- Added unit and 50-run StreamData property coverage for exporter drift and data-contract invariants.

## Task Commits

1. **Task 1: Define schema and canonical cases** — `2a24a752` (RED tests), `fa3870df` (implementation)
2. **Task 2: Generate deterministic Markdown and JSON views** — `7aa1f27a` (RED tests), `3612145d` (implementation)
3. **Task 3: Add decision-contract properties** — `975bbb9f` (RED tests), `3c9c1350` (property execution)

## Files Created/Modified

- `accrue/lib/accrue/entitlements/decision_cases.ex` — internal schema, validation, and ordered corpus.
- `accrue/lib/accrue/entitlements/decision_cases/markdown.ex` — pure Markdown and JSON export functions.
- `accrue/lib/mix/tasks/accrue.entitlements.decision_cases.ex` — deterministic write/check task.
- `accrue/priv/entitlements/v1.59-decision-cases.json` — language-neutral derived contract.
- `.planning/research/v1.59-DECISION-TABLE.md` — generated human-readable derived contract.

## Decisions Made

- Kept the corpus private and data-only: it performs no Repo, processor, gateway, reducer, or projector work.
- Treated generated fixture mismatch as a fail-closed condition, including mutation-sensitive tests.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Next Phase Readiness

Plans 215-04 and 215-05 can consume the stable case IDs, contract version, and expected dispositions. Downstream reducer equivalence remains intentionally unverified until production reducers exist, as recorded by the plan's RSCH-02 backstop.

## Self-Check: PASSED

- Confirmed all seven task commits exist and all corpus, exporter, fixture, and test files are present.
- Re-ran the generator check and both targeted test suites successfully.
