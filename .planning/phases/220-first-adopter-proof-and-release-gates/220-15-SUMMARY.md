---
phase: 220-first-adopter-proof-and-release-gates
plan: 15
subsystem: entitlements-reference-scenarios
tags: [proof-02, offline, signed-jws, conformance]
requires:
  - phase: 220-13
    provides: closed reference command families
provides:
  - Signed-vector offline policy executor for the five reference actions
  - Adversarial generic-grant and replay substitution proof
affects: [220-16, 220-20, phase-verification]
tech-stack:
  added: []
  patterns: [bounded-offline-observation, signed-vector-execution, adversarial-adapter-proof]
key-files:
  created:
    - accrue/test/support/entitlements/reference_scenario_executor/offline_policy.ex
    - accrue/test/accrue/entitlements/reference_scenario_offline_policy_test.exs
  modified:
    - accrue/test/support/entitlements/reference_scenario_executor.ex
key-decisions:
  - "Offline reference actions resolve their signed semantic vector and execute Offline.verify/3 with the full fixture context."
  - "Downloaded-study continuity is tested separately from expansion authority through Offline.action_policy/2."
requirements-completed: [PROOF-02]
coverage:
  - id: D1
    description: "Five offline reference actions execute signed verification and bounded policy collection."
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/reference_scenario_offline_policy_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generic lifecycle grants and no-effect replays cannot impersonate offline verification."
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/reference_scenario_offline_policy_test.exs#actual generic-grant and no-effect adapters fail every offline expectation"
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
  files_changed: 3
  completed: 2026-08-05
status: complete
---

# Phase 220 Plan 15: Offline Policy Conformance Summary

Signed golden vectors now drive the reference executor for stale study, restricted expansion, signed denial, rollback, and empty-evidence outcomes.

## Completed Tasks

1. Added the offline-policy executor, which resolves the semantic golden vector, passes its complete public-key verification context to `Offline.verify/3`, collects only bounded decision facts, and applies `Offline.action_policy/2` to the requested action.
2. Added five-action conformance coverage, including distinct denial/rollback/malformed reasons, preservation of cache and durable state, empty-proof exclusivity, and real lifecycle/no-effect adapters that fail the offline expectation matcher.

## Verification

- `cd accrue && mix test test/accrue/entitlements/reference_scenario_offline_policy_test.exs test/accrue/entitlements/offline_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs --seed 458442 --max-failures 1` — 17 tests, 0 failures.
- `git diff --check HEAD~4..HEAD` — passed.

## Task Commits

1. Task 1 RED: `c9a9482f` — failing stale-continuity and restricted-expansion coverage.
2. Task 1 GREEN: `b56994fd` — signed-vector executor and dispatcher integration.
3. Task 2 RED: `8554105b` — adversarial deny/rollback/empty-evidence coverage.
4. Task 2 GREEN: `bc0f02fc` — generic-grant/replay rejection and empty-compact guard.

## Decisions Made

- Semantic offline scenarios select the matching signed vector (`stale_at_freshness`, `valid_signed_denial`, or `clock_rollback`) rather than deriving access from fixture metadata.
- The reference fixture's `download_lesson` label maps to production policy action `:download_premium`; the policy itself remains the authority for the reconnect-required denial.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract mismatch] Normalized the fixture's expansion label to the production action vocabulary**
- **Found during:** Task 1
- **Issue:** `download_lesson` is not a production offline policy action, so passing it through would only exercise the unknown-action fallback rather than the expansion boundary.
- **Fix:** Resolved it to `:download_premium` before calling `Offline.action_policy/2`.
- **Files modified:** `accrue/test/support/entitlements/reference_scenario_executor/offline_policy.ex`
- **Verification:** Focused offline conformance suite passes.
- **Committed in:** `b56994fd`

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact:** Correctness-only normalization; no production API or fixture schema changed.

## Issues Encountered

None.

## Next Phase Readiness

The five offline actions now have a production-verifier-backed reference execution seam ready for aggregate certification.

## Self-Check: PASSED

- Created executor and conformance test files exist.
- Task commits `c9a9482f`, `b56994fd`, `8554105b`, and `bc0f02fc` exist in git history.
