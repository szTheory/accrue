---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 06
subsystem: entitlements-contract-testing
tags: [elixir, exunit, stream-data, entitlements, contract]
requires:
  - phase: 215-05
    provides: "Canonical v1.59 decision-case corpus and offline vector contract"
provides:
  - "Fail-closed D-07 DecisionCases validator with closed value vocabularies"
  - "Test-only canonical decision-case transition consumer"
  - "Generated contract properties for duplicate, ordering, survivor, atomicity, and invalid input"
affects: [217-canonical-projection, 219-offline-study-contract]
tech-stack:
  added: []
  patterns: ["closed data contracts", "test-support conformance consumer", "StreamData transition properties"]
key-files:
  created:
    - accrue/test/support/entitlements/decision_case_contract_consumer.ex
  modified:
    - accrue/lib/accrue/entitlements/decision_cases.ex
    - accrue/test/accrue/entitlements/decision_cases_test.exs
    - accrue/test/property/entitlement_decision_cases_property_test.exs
key-decisions:
  - "D-07 validation uses explicit closed vocabularies and a bounded snapshot shape."
  - "The contract consumer remains compiled only from test/support and interprets a caller-supplied canonical case."
patterns-established:
  - "Generated decision evidence must be consumed by test-support conformance machinery before assertions."
requirements-completed: [RSCH-02]
coverage:
  - id: D1
    description: "Closed D-07 validator rejects malformed case fields without raising."
    requirement: RSCH-02
    verification:
      - kind: unit
        ref: "mix test test/accrue/entitlements/decision_cases_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated evidence and prior state traverse a test-only canonical transition consumer."
    requirement: RSCH-02
    verification:
      - kind: integration
        ref: "mix test test/accrue/entitlements/decision_cases_test.exs test/property/entitlement_decision_cases_property_test.exs && ! rg -n 'DecisionCaseContractConsumer' lib"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-01
status: complete
---

# Phase 215 Plan 06: D-07 Contract Closure Summary

**Closed D-07 decision-case validation and generated conformance transitions without introducing a production entitlement reducer.**

## Performance

- **Duration:** 9 min
- **Completed:** 2026-08-01T22:36:54Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Closed every D-07 validator boundary: bindings, evidence kind, prior sources and snapshots, ordering, expected outcomes, atomicity, reason, and non-negative revision deltas.
- Added a test-only consumer that validates and interprets a passed canonical case; it has no case-ID table and is not imported from production code.
- Replaced fixture-only properties with 50-run generated duplicate, older-ordering, survivor, atomic-result, and invalid-input transition proofs.

## Task Commits

1. **Task 1: Close one D-07 case path from malformed binding to rejected contract** - `2a01f941`, `1ea385e2`
2. **Task 2: Drive generated evidence and prior state through the contract consumer** - `f969a991`, `219cfd97`

## Files Created/Modified

- `accrue/lib/accrue/entitlements/decision_cases.ex` - Fail-closed D-07 vocabulary and shape validation.
- `accrue/test/accrue/entitlements/decision_cases_test.exs` - Mutation-sensitive D-07 boundary tests.
- `accrue/test/support/entitlements/decision_case_contract_consumer.ex` - Test-only canonical transition interpreter.
- `accrue/test/property/entitlement_decision_cases_property_test.exs` - Generated consumer-driven contract properties.

## Decisions Made

- Reused the canonical `DecisionCase` contract as the sole policy input; the test consumer only applies the supplied case transition.
- Preserved a prior snapshot for `:noop` and `:preserve` outcomes so older and duplicate evidence cannot restore an allow state.
- RSCH-02 production-reducer equivalence remains explicitly unresolved until Phase 217 supplies a production reducer.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Next Phase Readiness

Phase 217 can use the closed corpus and generated conformance properties as a reducer-equivalence backstop without treating the test-support consumer as runtime entitlement logic.

## Self-Check: PASSED

- All four implementation and test files exist.
- All four task commits (`2a01f941`, `1ea385e2`, `f969a991`, `219cfd97`) exist in git history.
