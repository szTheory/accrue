---
phase: 44-meter-failures-idempotency-reconciler-webhook
plan: "02"
subsystem: billing
tags: [oban, metering, telemetry]

requires:
  - plan: "01"
    provides: MeterEvents failure choke
provides:
  - Reconciler failure path uses `mark_failed_with_telemetry(..., :reconciler)`
key-files:
  created: []
  modified:
    - accrue/lib/accrue/jobs/meter_events_reconciler.ex
requirements-completed: [MTR-05]
duration: 10min
completed: 2026-04-22
---

# Phase 44 Plan 02 — MTR-05

Reconciler no longer emits inline `meter_reporting_failed`; delegates to shared `MeterEvents` guarded update.

## Self-Check: PASSED

- `mix test test/accrue/jobs/meter_events_reconciler_test.exs`
