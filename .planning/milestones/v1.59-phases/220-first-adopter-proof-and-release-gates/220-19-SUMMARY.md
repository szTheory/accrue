---
phase: 220-first-adopter-proof-and-release-gates
plan: 19
subsystem: testing
tags: [elixir, exunit, offline-entitlements, reconnect, durable-resume]
requires:
  - phase: 220-16
    provides: signed reconnect and verify-first cache replacement patterns
provides:
  - Fixture-declared production reconnect interruption and exact replay proof
  - Bounded durable attempt, challenge, issuance, and cache observations
affects: [220-20, reference-scenarios, offline-entitlements]
tech-stack:
  added: []
  patterns: [closed fault-hook enum, exact signed-request replay, secret-free bounded observations]
key-files:
  created:
    - accrue/test/support/entitlements/reference_scenario_executor/resume.ex
    - accrue/test/accrue/entitlements/reference_scenario_resume_test.exs
  modified:
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
key-decisions:
  - "Keep signed proof material in executor runtime and expose only bounded durable/cache facts."
  - "Bind both fixture actions with a closed request reference and a closed production interruption hook."
requirements-completed: [PROOF-02]
coverage:
  - id: D1
    description: Durable interruption invokes a production reconnect hook and retains an admitted attempt with no issuance.
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_resume_test.exs#durable interruption is a signed reconnect with a persisted resumable boundary
        status: pass
    human_judgment: false
  - id: D2
    description: Exact replay resumes the same attempt and challenge to one issuance and a verified cache replacement while substitute adapters fail.
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_resume_test.exs#same-request replay resumes one authority replaces the complete cache and rejects substitutes
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-08-04
status: complete
---

# Phase 220 Plan 19: Durable Reconnect Resume Summary

**Fixture-declared reconnect interruption now resumes the same signed durable authority to one verified cache replacement without exposing proof material.**

## Accomplishments

- Added a resume executor that calls `Offline.reconnect/3` through the declared production hook, then reads fresh device, challenge, attempt, issuance, and snapshot facts.
- Added explicit fixture `request_ref` and `interruption_hook` contracts so interruption and resume are ordered actions bound to the same request identity.
- Proved exact replay reaches one completed attempt, consumed challenge, allow issuance, and stable verification-first cache adoption; generic-grant, no-effect, and snapshot-only controls fail.

## Verification

Passed:

`cd accrue && mix test test/accrue/entitlements/reference_scenario_resume_test.exs test/accrue/entitlements/offline_reconnect_test.exs --seed 458442 --max-failures 1`

Result: 21 tests, 0 failures.

## Task Commits

1. Task 1 — `db15d4f5` test RED coverage; `eb1a6da9` production interruption implementation.
2. Task 2 — `d743a15b` exact resume/replay proof; `a3550977` authority-fact collection completion.

## Files Created/Modified

- `accrue/test/support/entitlements/reference_scenario_executor/resume.ex` — production fault injection, durable collection, exact replay, cache verification, and controls.
- `accrue/test/accrue/entitlements/reference_scenario_resume_test.exs` — two-action durable-resume conformance tests.
- `accrue/priv/entitlements/v1.59-reference-scenarios.json` — closed request and hook references for the interrupted-resume row.
- `accrue/lib/accrue/entitlements/reference_scenarios.ex` — validates the closed resume command variants.

## Decisions Made

- Opaque signed proofs stay only in executor-local runtime; the test observations contain no proof, nonce, signature, or idempotency material.
- The fixture selects only `after_admission` or `after_issuance_commit`; it cannot inject an arbitrary callback.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical contract] Added fixture request and hook references.**

- **Found during:** Task 1
- **Issue:** The existing interrupted-resume fixture lacked the explicit request/hook references required to prove action ordering and production fault injection.
- **Fix:** Added and validated closed `request_ref` and `interruption_hook` fields.
- **Files modified:** `accrue/priv/entitlements/v1.59-reference-scenarios.json`, `accrue/lib/accrue/entitlements/reference_scenarios.ex`
- **Verification:** Resume conformance and offline reconnect suites pass.
- **Committed in:** `eb1a6da9`

**2. [Rule 1 - Test isolation] Isolated the generic-grant negative-control provider identity.**

- **Found during:** Task 2
- **Issue:** Multiple negative-control accounts reused the fixture provider identity, violating the production uniqueness constraint before the control could be evaluated.
- **Fix:** Derive an account-scoped provider identity only inside the real generic-grant control.
- **Files modified:** `accrue/test/support/entitlements/reference_scenario_executor/resume.ex`
- **Verification:** Resume conformance and offline reconnect suites pass.
- **Committed in:** `d743a15b`

**Total deviations:** 2 auto-fixed (Rule 1: 1; Rule 2: 1). **Impact:** Necessary fixture correctness and isolated test control; no production or Crosswake-runtime behavior changed.

## Known Stubs

None.

## Next Phase Readiness

The final release-gate plan can consume a deterministic, production-backed interruption/resume proof. Crosswake runtime feasibility remains blocked and is not claimed.

## Self-Check: PASSED

- Created executor and conformance test files exist.
- All four task commits are present in git history.
