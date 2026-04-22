# Phase 44 — Technical research

**Phase:** 44 — Meter failures, idempotency, reconciler + webhook  
**Date:** 2026-04-22  
**Question answered:** What do we need to know to plan MTR-04..MTR-06 well?

---

## Summary

1. **Telemetry `source`** — Code still emits `:inline` from `MeterEventActions.emit_failure_telemetry/3` while `guides/telemetry.md` documents `:sync | :reconciler | :webhook`. Requirements (MTR-04) expect `:sync`. Single rename + CHANGELOG note (D-02).

2. **“Exactly one” `meter_reporting_failed`** — Today sync path always emits after `failed_changeset` update without checking prior row state. Reconciler emits inline after update. Webhook emits after `mark_failed_by_identifier` without transition guard. **Fix:** one module-level choke in `Accrue.Billing.MeterEvents` using **guarded updates** (e.g. `WHERE stripe_status = 'pending'` or allowed sources) returning whether a transition occurred; emit telemetry only on `true`. Applies to sync (`MeterEventActions`), reconciler (`MeterEventsReconciler`), and webhook (`reduce_meter_error_report`).

3. **Idempotent retry semantics (D-05)** — `insert_pending/6` already returns existing row by identifier. After first failure the row is `failed`; second `report_usage/3` must **not** call the processor, return `{:ok, %MeterEvent{stripe_status: "failed"}}`, and emit **no** duplicate ops telemetry.

4. **`report_usage!/3` (D-06)** — Must not raise when non-bang would return `{:ok, failed_row}` on replay.

5. **Reconciler tests (MTR-05)** — Prefer `Repo.update_all` to backdate `inserted_at` + `MeterEventsReconciler.reconcile/0`; avoid process-kill. One telemetry attach asserting `source: :reconciler` and `count: 1` on failure path.

6. **Webhook production gap (MTR-06 / D-10)** — `DefaultHandler.handle_event/3` calls `dispatch(type, ..., %{"id" => event.object_id})` — meter reducers need **full embedded object** for `extract_meter_identifier/1`. `DispatchWorker.perform/1` must pass `data["object"]` from persisted webhook row into `ctx`; new `handle_event` clauses for `billing.meter.error_report_triggered` and `v1.billing.meter.error_report_triggered` must pass that object into the same `reduce_meter_error_report/2` as `handle/1`.

7. **Webhook dedupe (D-12)** — Redelivery must not increment `meter_reporting_failed` when row already `failed` for same failure epoch — same guarded choke as above.

8. **Metadata (D-13)** — Incremental structured fields (`error_code`, `message`) on webhook path where cheap; full table deferred to Phase 45.

---

## Code anchors (pre-change)

| Area | File | Notes |
|------|------|-------|
| Sync failure + `:inline` | `accrue/lib/accrue/billing/meter_event_actions.ex` | L84–97 `{:error, err}` branch; L222 `emit_failure_telemetry(..., :inline)` |
| Webhook mark failed | `accrue/lib/accrue/billing/meter_events.ex` | `mark_failed_by_identifier/2` unconditional update |
| Reconciler | `accrue/lib/accrue/jobs/meter_events_reconciler.ex` | Inline telemetry L90–98 on error |
| Dispatch ctx | `accrue/lib/accrue/webhook/dispatch_worker.ex` | `ctx` lacks Stripe object |
| handle_event vs handle/1 | `accrue/lib/accrue/webhook/default_handler.ex` | L94–98 generic path; L187–194 dispatch with full `obj` for `handle/1` only |
| Tests | `accrue/test/accrue/billing/meter_event_actions_test.exs` | L113 asserts `:inline` |

---

## Risks

- **Race:** Sync and reconciler both flip same row — guarded update ensures at most one telemetry emission for transition into `failed`.
- **Breaking telemetry:** Hosts matching `:inline` must migrate to `:sync` — documented in CHANGELOG only (pre-1.0 acceptable per CONTEXT).

---

## Validation Architecture

**Dimension 8 (Nyquist):** Execution must keep **continuous automated feedback** on the `accrue` package test suite.

| Dimension | Strategy |
|-----------|----------|
| **Sampling** | After each task: `cd accrue && mix test <touched>_test.exs` (or file-scoped). After each plan wave: `cd accrue && mix test test/accrue/billing/ test/accrue/jobs/meter_events_reconciler_test.exs test/accrue/webhook/handlers/billing_meter_error_report_test.exs` |
| **Instrumentation** | ExUnit + `Fake.scripted_response/2` + narrow `:telemetry.attach` where CONTEXT requires count proofs |
| **Latency budget** | Target &lt; 120s for scoped meter test groups in CI |
| **Failure policy** | Red test blocks merge; no watch-mode |

**Contract test:** If `OpsEventContractTest` or inventory lists `meter_reporting_failed`, ensure no stale `:inline` literals remain in `accrue/` after edits (`rg :inline accrue/lib accrue/test` scoped to meter paths).

---

## RESEARCH COMPLETE

Planning may proceed to PLAN.md generation with `44-CONTEXT.md` as the decision lock.
