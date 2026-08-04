---
phase: 220-first-adopter-proof-and-release-gates
plan: 07
subsystem: entitlements
tags: [elixir, phoenix, ecto, apple, stripe, offline, conformance]
requires:
  - phase: 220-01
    provides: shared v1.59 reference scenario corpus
provides:
  - Data-only cross-rail production operation inputs
  - Core Apple-to-web and Stripe-to-iOS entitlement conformance coverage
  - Phoenix host proof using AccrueHost.Repo
affects: [reference-host, crosswake-tracer, entitlement-tests]
tech-stack:
  added: []
  patterns: [production-authority-only, host-owned-sandbox, bounded-fixture-consumer]
key-files:
  created: []
  modified:
    - accrue/priv/entitlements/v1.59-reference-scenarios.json
    - accrue/lib/accrue/entitlements/reference_scenarios.ex
    - accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs
    - examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs
decisions:
  - Fixture operation payloads select bounded production commands but contain no result reducer.
  - Crosswake remains feasibility_blocked; Swift coverage is client-schema evidence only.
metrics:
  duration: 6m
  completed: 2026-08-04
status: complete
---

# Phase 220 Plan 07: Production Cross-Rail Scenario Proof Summary

Apple-to-web and Stripe-to-iOS tracer rows now exercise persisted accounts through production entitlement contexts and the Phoenix reference host, while the fixture stays data-only and Crosswake remains feasibility-blocked.

## Completed Tasks

1. Added closed, bounded operation inputs to the two shared tracer rows and drove Apple evidence through public intake, snapshot, purchase decision, Offline verification/action policy, and immutable audit assertions.
2. Drove the inverse Stripe route through Observation and Projector in both the core suite and `AccrueHost.Repo`; each host scenario also proves an unrelated account stays empty.

## Verification

- `cd accrue && mix test test/accrue/entitlements/reference_scenario_conformance_test.exs --seed 458442` — passed (3 tests).
- `cd examples/accrue_host && mix test test/accrue_host/reference_scenario_conformance_test.exs --seed 458442` — passed (2 tests).
- `cd examples/crosswake_tracer && swift test --filter ReferenceScenarioTests` — passed (1 Swift Testing test).
- Confirmed direct Apple Intake, Observation, Projector, Snapshot, PurchaseDecision, Offline, and host Repo call patterns in both Elixir consumers.
- Confirmed `capability-report.json` is byte-unchanged and reports `feasibility_blocked`.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Validate in-memory operation structures**
   - **Found during:** Final plan verification.
   - **Issue:** `ReferenceScenarios.valid?/1` accepted a manually corrupted operation payload because it checked ordering but not the parsed operation struct.
   - **Fix:** Require operation-bearing actions to contain `%Operation{}` during validity checks and corrected the capability-report test path.
   - **Files modified:** `accrue/lib/accrue/entitlements/reference_scenarios.ex`, `accrue/test/accrue/entitlements/reference_scenario_conformance_test.exs`.
   - **Commit:** `8cfcb163`.

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** strengthens the closed, data-only fixture boundary without changing entitlement authority.

## Known Stubs

None.

## Self-Check: PASSED

- All four planned implementation files exist.
- Task commits `37b26a7a`, `f694b800`, `ef839f1a`, `f82d0ad7`, and `8cfcb163` exist in git history.
