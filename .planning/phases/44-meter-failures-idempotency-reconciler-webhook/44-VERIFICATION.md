---
status: passed
phase: 44-meter-failures-idempotency-reconciler-webhook
verified: "2026-04-22"
---

# Phase 44 verification

## Automated

- `cd accrue && mix compile --warnings-as-errors` — PASS
- `mix test test/accrue/billing/meter_event_actions_test.exs test/accrue/jobs/meter_events_reconciler_test.exs test/accrue/webhook/handlers/billing_meter_error_report_test.exs test/accrue/webhook/dispatch_worker_test.exs test/accrue/telemetry/ops_event_contract_test.exs` — PASS

## Must-haves (MTR-04..MTR-06)

| ID | Evidence |
|----|----------|
| MTR-04 | `Accrue.Billing.MeterEvents.mark_failed_with_telemetry/4` + `MeterEventActions` idempotent `{:ok, failed}` replay; ops `source: :sync`; tests in `meter_event_actions_test.exs` |
| MTR-05 | `MeterEventsReconciler` delegates failures to `MeterEvents`; `source: :reconciler`; `meter_events_reconciler_test.exs` |
| MTR-06 | `DispatchWorker` `ctx[:meter_error_object]`; `DefaultHandler.handle_event/3` for unversioned + v1 meter types; guarded webhook path; `billing_meter_error_report_test.exs` + `dispatch_worker_test.exs` |

## Human verification

None required for this phase.
