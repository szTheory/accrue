---
phase: 43-meter-usage-happy-path-fake-determinism
plan: "03"
subsystem: testing
tags: [metering, fake, telemetry, test_facade]

requires: []
provides:
  - Accrue.Test.meter_events_for/1 delegating to Fake with processor guard
  - Golden-path idempotency test and billing span telemetry smoke
affects: []

tech-stack:
  added: []
  patterns:
    - "Rename billing meter test module to Accrue.Billing.MeterEventsReportUsageTest to keep rg MeterEventActions guard meaningful"

key-files:
  created:
    - accrue/test/accrue/test/meter_events_for_test.exs
  modified:
    - accrue/lib/accrue/test.ex
    - accrue/test/accrue/billing/meter_event_actions_test.exs

key-decisions:
  - "Golden and telemetry tests use 2026 timestamps inside the 35-day backdating window instead of 2020 literals"

patterns-established:
  - "ArgumentError when meter_events_for/1 is called with a non-Fake processor module configured"

requirements-completed: [MTR-02, MTR-03]

duration: 45min
completed: 2026-04-22
---

# Phase 43 Plan 03 Summary

**Fake meter reporting now has a public `Accrue.Test.meter_events_for/1` helper, guard tests, a deterministic identifier golden path, and a narrow billing telemetry smoke assertion.**

## Performance

- **Tasks:** 5 (telemetry task shipped)
- **Commits:** 4 (`feat` facade, `test` guard file, `test` meter suite, `docs` key-link casing)

## Accomplishments

- Implemented `meter_events_for/1` with `Accrue.Processor.__impl__()` guard and Fake delegation.
- Migrated processor-shaped assertions to `Accrue.Test.meter_events_for/1`.
- Added idempotency proof with fixed `timestamp:` + `Accrue.Actor.put_operation_id/1` aligned to identifier derivation.
- Attached to `[:accrue, :billing, :meter_event, :report_usage, :stop]` once per happy path.

## Task Commits

1. **Task 1** — `b8f5fa3` feat(43-03): meter_events_for facade
2. **Task 2** — `520fb3e` test(43-03): guard module
3. **Tasks 3–5** — `8abd5b6` test(43-03): migrations + golden + telemetry
4. **Key-link** — `645d2a7` docs: lowercase `single facade` in @doc

## Self-Check: PASSED

- `cd accrue && mix compile --warnings-as-errors`
- `mix test test/accrue/billing/meter_event_actions_test.exs test/accrue/processor/fake_meter_event_test.exs test/accrue/test/meter_events_for_test.exs` — 19 tests, 0 failures
- `gsd-sdk query verify.key-links` on `43-03-PLAN.md` — verified

## Deviations

- Renamed test module from `MeterEventActionsTest` to `MeterEventsReportUsageTest` so `rg MeterEventActions` acceptance (zero private-module coupling) is satisfiable without a contradictory module name.
