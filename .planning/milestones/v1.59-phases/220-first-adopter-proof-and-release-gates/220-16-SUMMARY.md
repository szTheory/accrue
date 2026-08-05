---
phase: 220-first-adopter-proof-and-release-gates
plan: 16
subsystem: testing
tags: [elixir, exunit, offline-entitlements, reconnect, proof-verification]
requires:
  - phase: 220-13
    provides: closed reference-scenario lifecycle contract
provides:
  - Signed reconnect execution with durable challenge, attempt, and issuance observations
  - Verification-first replacement of a complete executor-local cache tuple
  - Adversarial evidence that substitute adapters cannot satisfy reconnect/cache actions
affects: [220-20, reference-scenarios, offline-entitlements]
tech-stack:
  added: []
  patterns: [opaque-proof runtime handoff, bounded durable collection, verify-before-cache-adoption]
key-files:
  created:
    - accrue/test/support/entitlements/reference_scenario_executor/reconnect_cache.ex
    - accrue/test/accrue/entitlements/reference_scenario_reconnect_test.exs
  modified: []
key-decisions:
  - "Keep the issued proof only in executor runtime state; observations expose bounded facts."
  - "Treat cache adoption as verify-first complete-tuple replacement and retain the prior tuple on failure."
requirements-completed: [PROOF-02]
coverage:
  - id: D1
    description: Signed reconnect produces independently queried challenge, attempt, issuance, and snapshot facts without exposing proof material.
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_reconnect_test.exs#reconnect and verified cache replacement are one signed bounded flow
        status: pass
    human_judgment: false
  - id: D2
    description: Verified cache replacement preserves the prior complete tuple on verification failure and rejects substitute adapters.
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_reconnect_test.exs#failed proof verification preserves the complete prior cache tuple
        status: pass
      - kind: integration
        ref: accrue/test/accrue/entitlements/reference_scenario_reconnect_test.exs#generic replay snapshot and registration substitutes cannot satisfy reconnect actions
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-05
status: complete
---

# Phase 220 Plan 16: Reconnect and Verified Cache Replacement Summary

**A real signed reconnect now settles durable admission and issuance before its opaque proof is verified for complete cache replacement.**

## Accomplishments

- Added a reconnect/cache reference-scenario executor that creates a device, consumes a signed one-time reconnect challenge, and reads durable challenge, reconnect-attempt, issuance, and snapshot facts after settlement.
- Kept proof, nonce, signing material, and idempotency data inside runtime state; bounded observations report only state, revision, disposition, and replacement outcome.
- Added chained conformance coverage for verification-first replacement, prior-cache preservation on invalid proof, and real generic-grant, no-effect, snapshot-only, and registration-only substitutes.

## Verification

Passed:

`cd accrue && mix test test/accrue/entitlements/reference_scenario_reconnect_test.exs test/accrue/entitlements/offline_reconnect_test.exs --seed 458442 --max-failures 1`

Result: 22 tests, 0 failures.

## Task Commits

1. Task 1 — `eb6fc795` test RED coverage; `23cca395` signed reconnect/cache executor implementation.
2. Task 2 — `f4360c47` chained cache conformance verification.

## Files Created

- `accrue/test/support/entitlements/reference_scenario_executor/reconnect_cache.ex` — signed reconnect execution, bounded durable collection, verification-first cache adoption, and substitute adapters.
- `accrue/test/accrue/entitlements/reference_scenario_reconnect_test.exs` — focused chained reconnect/cache tests.

## Decisions Made

- The issued compact proof is retained only under the action-order runtime key, never surfaced through collector output.
- Cache replacement accepts only a verified decision and adopts revision, disposition, and proof state as one tuple; failure leaves the prior tuple unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Blocking runtime discovery] Ensured injected test collaborators are loaded before reconnect dispatch.**

- **Found during:** Task 1
- **Issue:** reconnect checks collaborators with `function_exported?/3`; unloaded nested test modules made a valid no-due coordinator and signing provider appear unavailable.
- **Fix:** Explicitly loaded the bounded test collaborators before issuing the reconnect.
- **Files modified:** `accrue/test/support/entitlements/reference_scenario_executor/reconnect_cache.ex`
- **Verification:** Focused reconnect and offline reconnect suite passed.
- **Committed in:** `23cca395`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Next Phase Readiness

The deterministic reconnect/cache evidence is ready for final aggregate release-gate certification. Crosswake runtime feasibility remains explicitly blocked and is not claimed by this server-side proof.

## Self-Check: PASSED

- Both reconnect/cache files exist.
- All three 220-16 task commits are present in git history.
