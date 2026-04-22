---
status: issues
phase: 44-meter-failures-idempotency-reconciler-webhook
depth: standard
files_reviewed: 14
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
reviewed_at: 2026-04-22
---

# Phase 44 — Code review (standard)

Scope from plan SUMMARYs: meter failure transitions, reconciler, webhook dispatch/handler, `Repo.update_all/3`, tests, telemetry metrics, guides, and changelog.

## Summary

Guarded `Repo.update_all` + conditional telemetry correctly prevents duplicate `[:accrue, :ops, :meter_reporting_failed]` emissions on replay. Webhook and sync idempotency paths are coherent with tests. One warning on telemetry payload hygiene; two minor robustness notes.

### WR-01 — `inspect(err)` in ops telemetry for sync/reconciler

`Accrue.Billing.MeterEvents.ops_metadata/4` always sets `error: inspect(err)` for every `source` before webhook-specific enrichment. For `:sync` and `:reconciler`, that string can be large, unstable across releases, and may include more detail than you want attached to metrics or forwarded to observability backends (Accrue’s own bar is “sensitive Stripe fields never logged”; meter errors are lower risk but still worth bounding).

**Suggestion:** Prefer a short, structured summary for non-webhook sources (for example `Exception.message/1` for exceptions, `APIError.code` + truncated `message` for `APIError`, byte cap) and reserve full `inspect/1` for debug-only code paths.

### IN-01 — `Repo.get!` after successful guarded update

After `count == 1` in `mark_failed_with_telemetry/4`, the code loads the row with `Repo.get!/2`. If the row were deleted between `update_all` and `get` (pathological), the call would raise and bubble out of webhook/reconciler paths.

**Suggestion:** Low priority; if you want belt-and-suspenders, use `get/2` and treat `nil` as an internal invariant violation with a single structured log line.

### IN-02 — `extract_meter_identifier/1` coverage

`extract_meter_identifier/1` reads top-level `:identifier` or `reason.identifier`. If Stripe adds alternate shapes for the error object, the handler would log “unknown identifier” and return `{:ok, :ignored}` without failing the job — correct operationally, but easy to miss in monitoring.

**Suggestion:** When adding new Stripe API versions, extend fixtures/tests for any new identifier locations called out in Stripe docs.

## Files in scope

- `accrue/CHANGELOG.md`
- `accrue/guides/operator-runbooks.md`
- `accrue/guides/telemetry.md`
- `accrue/lib/accrue/billing.ex`
- `accrue/lib/accrue/billing/meter_event_actions.ex`
- `accrue/lib/accrue/billing/meter_events.ex`
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex`
- `accrue/lib/accrue/repo.ex`
- `accrue/lib/accrue/telemetry/metrics.ex`
- `accrue/lib/accrue/webhook/default_handler.ex`
- `accrue/lib/accrue/webhook/dispatch_worker.ex`
- `accrue/test/accrue/billing/meter_event_actions_test.exs`
- `accrue/test/accrue/webhook/dispatch_worker_test.exs`
- `accrue/test/accrue/webhook/handlers/billing_meter_error_report_test.exs`

## Positive notes

- Single choke point for durable `pending`/`reported` → `failed` with explicit `from_statuses` for webhook vs sync/reconciler.
- Tests explicitly cover idempotent `report_usage/3` and duplicate webhook telemetry.
- `DispatchWorker` ctx plumbed with `meter_error_object` avoids re-parsing full payloads in handlers.
