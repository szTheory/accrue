---
phase: 44-meter-failures-idempotency-reconciler-webhook
plan: "01"
subsystem: billing
tags: [telemetry, metering, ecto]

requires: []
provides:
  - Guarded `MeterEvents.mark_failed_with_telemetry/4` with ops emit on first qualifying transition
  - Idempotent `report_usage/3` / `report_usage!/3` for terminal rows
  - `Accrue.Repo` delegates `update_all/3`, `get!/3`
key-files:
  created: []
  modified:
    - accrue/lib/accrue/billing/meter_events.ex
    - accrue/lib/accrue/billing/meter_event_actions.ex
    - accrue/lib/accrue/billing.ex
    - accrue/lib/accrue/repo.ex
    - accrue/test/accrue/billing/meter_event_actions_test.exs
    - accrue/guides/telemetry.md
    - accrue/lib/accrue/telemetry/metrics.ex
    - accrue/guides/operator-runbooks.md
    - accrue/CHANGELOG.md
requirements-completed: [MTR-04]
duration: 30min
completed: 2026-04-22
---

# Phase 44 Plan 01 — MTR-04

Central meter **failed** transition + **:sync** ops vocabulary; idempotent sync retries return `{:ok, failed row}` without duplicate `meter_reporting_failed`.

## Self-Check: PASSED

- `mix compile --warnings-as-errors`; targeted tests for meter actions + ops contract.
