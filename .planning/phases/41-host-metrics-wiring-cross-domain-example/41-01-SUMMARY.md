---
phase: 41-host-metrics-wiring-cross-domain-example
plan: 01
subsystem: testing
tags: [telemetry, metrics, tel-01, ex_unit]

requires: []
provides:
  - Shared ops tuple inventory for contract and parity tests
  - TEL-01 ExUnit gate on Accrue.Telemetry.Metrics.defaults/0 event_name
affects: [41-02]

tech-stack:
  added: []
  patterns:
    - "Single Accrue.TestSupport.TelemetryOpsInventory module owns ops allowlist for tests"

key-files:
  created:
    - accrue/test/support/telemetry_ops_inventory.ex
    - accrue/test/accrue/telemetry/metrics_ops_parity_test.exs
  modified:
    - accrue/test/accrue/telemetry/ops_event_contract_test.exs

key-decisions:
  - "Parity asserts metric struct event_name equals each inventory tuple (no string heuristics)"

patterns-established:
  - "Ops catalog in tests: expected_ops_events/0 + not_wired_first_party_emits/0 in one module"

requirements-completed: [TEL-01]

duration: 12min
completed: 2026-04-21
---

# Phase 41: Host metrics wiring — Plan 01 Summary

**Centralized the ops event allowlist in test support and added an ExUnit parity test so every inventory tuple must match a `Telemetry.Metrics` default `event_name` in `Accrue.Telemetry.Metrics.defaults/0`.**

## Performance

- **Duration:** ~12 min
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Introduced `Accrue.TestSupport.TelemetryOpsInventory` as the single source for `expected_ops_events` and `not_wired_first_party_emits`.
- Refactored `OpsEventContractTest` to call the inventory module; remediation strings point at `telemetry_ops_inventory.ex`.
- Added `Accrue.Telemetry.MetricsOpsParityTest` enforcing TEL-01 parity via `event_name` equality.

## Task Commits

1. **Task 1: Add OpsInventory support module** — `a069601` (test)
2. **Task 2: Refactor OpsEventContractTest to use OpsInventory** — `37984f8` (test)
3. **Task 3: Add MetricsOpsParityTest** — `8af3b83` (test)

## Files Created/Modified

- `accrue/test/support/telemetry_ops_inventory.ex` — canonical ops tuples + documented unwired set
- `accrue/test/accrue/telemetry/ops_event_contract_test.exs` — consumes inventory
- `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs` — TEL-01 parity vs `defaults/0`

## Verification

- `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs test/accrue/telemetry/metrics_test.exs` — PASS (10 tests)

## Self-Check: PASSED

- Key files from `key-files.created` exist on disk.
- `git log --oneline --grep=41-01` shows task commits.

## Issues Encountered

None.

## Deviations

None.
