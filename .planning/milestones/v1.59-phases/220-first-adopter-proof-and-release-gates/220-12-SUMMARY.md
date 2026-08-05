---
phase: 220-first-adopter-proof-and-release-gates
plan: 12
subsystem: entitlements
tags: [elixir, phoenix, ecto, offline-entitlements, device-replacement, action-contract, swift]
requires:
  - phase: 220-11
    provides: action_contract v1 consumer contract and deterministic scenario executor
provides:
  - Host-authorized atomic device replacement and revocation through Offline.replace_device/3
  - device_replace action_contract v1 dispatch with persisted-state conformance evidence
  - Credential-free core, host, Swift, generator, source-matrix, and release-gate validation
affects: [offline-entitlements, action-contract, host-adoption, crosswake-tracer, release-gates]
tech-stack:
  added: []
  patterns: [account/prior-device/challenge locking, audit-backed idempotent replay, bounded fixture references]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/offline.ex
    - accrue/lib/accrue/entitlements/offline/registration.ex
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
    - accrue/test/support/entitlements/reference_scenario_executor.ex
key-decisions:
  - "Device replacement reuses the registration PoP and challenge boundary; it does not add a parallel device subsystem or migration."
  - "The shared device_replace scenario observes freshly queried durable facts, while fixtures remain synthetic references only."
requirements-completed: [PROOF-02]
coverage:
  - id: D1
    description: "Host-authorized, atomic, idempotent replacement or revocation transitions an account device with bounded audit data."
    requirement: PROOF-02
    verification:
      - kind: unit
        ref: "accrue/test/accrue/entitlements/offline_registration_test.exs"
        status: pass
      - kind: integration
        ref: "cd accrue && mix test --seed 458442 --max-failures 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "The action_contract v1 device_replace scenario dispatches the real public operation and matches durable effects without exposing private proof material."
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: "cd accrue && mix accrue.entitlements.reference_scenarios --check --root .."
        status: pass
      - kind: integration
        ref: "bash scripts/ci/verify_reference_scenario_contract.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Host and Swift contract consumers remain credential-free and Crosswake remains feasibility_blocked."
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: "cd examples/accrue_host && mix test --seed 458442 --max-failures 1"
        status: pass
      - kind: integration
        ref: "cd examples/crosswake_tracer && swift test"
        status: pass
    human_judgment: false
metrics:
  duration: 1m
  completed: 2026-08-04
  tasks: 3
  files: 7
status: complete
---

# Phase 220 Plan 12: Device Replacement and Release Gates Summary

**A host-authorized Offline.replace_device/3 operation atomically replaces or revokes a device, proves replacement possession, records one bounded audit event, and is exercised by the shared v1 action-contract corpus.**

## Performance

- **Duration:** 1m (resumed final validation session)
- **Started:** 2026-08-04T21:09:37Z
- **Completed:** 2026-08-04T21:10:31Z
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- Added the public, host-authorized replacement boundary with transaction locking, coherent lifecycle transitions, replacement proof-of-possession, replay handling, and bounded immutable audit attribution.
- Bound the `device_replace` v1 corpus row to that production operation and a freshly observed durable transition tuple, rejecting generic/no-effect substitutes and secret-bearing fixture fields.
- Preserved host and Swift evidence boundaries while validating formatting, full credential-free core/host/Swift suites, deterministic generation, source matrix, and all Phase-220 release gates.

## Task Commits

1. **Task 1: Ship one authorized atomic replacement through the public Offline boundary** — `d01fb11b` (`feat`)
2. **Task 2: Bind action_contract v1 device replacement to the production operation and exact durable tuple** — `95b5f4bf` (`feat`)
3. **Task 3: Preserve host and Swift consumers, privacy boundaries, and the full release validation suite** — validation completed; no Task-3 fixture diff was needed because existing consumers already parsed action_contract v1 correctly.

## Files Created/Modified

- `accrue/lib/accrue/entitlements/offline.ex` — public replacement facade behind host authorization.
- `accrue/lib/accrue/entitlements/offline/registration.ex` — replacement request/result, atomic lifecycle transaction, PoP, idempotency, and audit logic.
- `accrue/test/accrue/entitlements/offline_registration_test.exs` — replacement authorization, rollback, replay, concurrency, schema, and privacy coverage.
- `accrue/priv/entitlements/v1.59-reference-scenarios.json` — exact `device_replace` v1 references and expected tuple.
- `accrue/lib/accrue/entitlements/reference_scenarios.ex` — strict closed action-contract decoding.
- `accrue/test/support/entitlements/reference_scenario_executor.ex` — real replacement dispatch plus durable observation collector.
- `accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs` — exact persisted tuple conformance.

## Decisions Made

- Reused the registration challenge and P-256 validation path to keep the public operation narrow and preserve existing registration compatibility.
- Made database locks and existing identity indexes the concurrency authority; no migration or in-memory coordination was added.
- Kept host and Swift as contract consumers only: the host does not implement replacement, and Crosswake remains `feasibility_blocked`.

## Verification

- `cd accrue && mix format --check-formatted && mix test --seed 458442 --max-failures 1` — passed.
- `cd accrue && mix accrue.entitlements.reference_scenarios --check --root ..` — passed.
- `cd examples/accrue_host && mix test --seed 458442 --max-failures 1` — passed.
- `cd examples/crosswake_tracer && swift test` — passed.
- `bash scripts/ci/verify_entitlement_source_matrix.sh` — passed.
- `bash scripts/ci/verify_reference_scenario_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_release_contract.sh` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Isolated host suite tests that assumed a live Braintree credential or conflated billing operations.**
- **Found during:** Task 3
- **Issue:** The complete credential-free host suite had an environment-sensitive Braintree gateway test and an ambiguous latest-billing-state assertion.
- **Fix:** Isolated the gateway test and distinguished the billing-state operation without changing the replacement contract.
- **Files modified:** `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs`
- **Verification:** Full host suite passed credential-free.
- **Committed in:** `56cc0368`, `a8e8b0d8`

---

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** Required for the plan's explicit credential-free host-suite gate; no replacement behavior, fixture authority, or release claim changed.

## Issues Encountered

The full core suite emits existing compiler warnings for unused attributes and aliases in action-contract support code, but completed successfully; no warnings were introduced or changed by this closeout.

`state.advance-plan` assumed sequential completion and reported plan 4 of 8 despite this out-of-order Plan 12 closeout; the tracked position was reconciled to the actual 10 of 12 completed plans.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

PROOF-02 now has production replacement/revocation evidence through the same shared corpus consumed by core, host, and Swift-compatible tests. The source audit and all required credential-free release gates are green.

## Self-Check: PASSED

- Required implementation and corpus files exist.
- Task commits `d01fb11b` and `95b5f4bf` exist in git history.
- No stub markers were found in the Plan 220-12 task files.

---
*Phase: 220-first-adopter-proof-and-release-gates*
*Completed: 2026-08-04*
