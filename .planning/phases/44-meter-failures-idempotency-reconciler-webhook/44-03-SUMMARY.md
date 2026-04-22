---
phase: 44-meter-failures-idempotency-reconciler-webhook
plan: "03"
subsystem: webhooks
tags: [telemetry, metering, oban]

requires:
  - plan: "01"
    provides: MeterEvents failure choke + webhook `from_statuses`
provides:
  - `DispatchWorker` ctx `meter_error_object`
  - `DefaultHandler.handle_event/3` for meter error types
  - `mark_failed_by_identifier/3` uses guarded webhook transition + optional `webhook_event_id` metadata
key-files:
  created: []
  modified:
    - accrue/lib/accrue/webhook/dispatch_worker.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/billing/meter_events.ex
    - accrue/test/accrue/webhook/handlers/billing_meter_error_report_test.exs
    - accrue/test/accrue/webhook/dispatch_worker_test.exs
requirements-completed: [MTR-06]
duration: 20min
completed: 2026-04-22
---

# Phase 44 Plan 03 — MTR-06

Production webhook dispatch passes embedded Stripe meter object; webhook failures share guarded ops telemetry (no duplicate on redelivery).

## Self-Check: PASSED

- `mix test test/accrue/webhook/handlers/billing_meter_error_report_test.exs test/accrue/webhook/dispatch_worker_test.exs`
