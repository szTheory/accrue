# Phase 44: Meter failures, idempotency, reconciler + webhook - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **MTR-04..MTR-06**: synchronous processor `{:error, _}` paths, **idempotent** retries that do **not** duplicate `[:accrue, :ops, :meter_reporting_failed]`, **reconciler** recovery for stale `pending` rows, and **webhook** `billing.meter.error_report_triggered` / `v1.billing.meter.error_report_triggered` handling **including the real `DispatchWorker` → `handle_event/3` path** — with tests and telemetry metadata aligned to `guides/telemetry.md` and operator runbooks.

**Explicitly not this phase:** Full MTR-07..MTR-08 prose alignment across all guides (Phase **45**); **PROC-08**; Stripe Dashboard meter UX.

</domain>

<decisions>
## Implementation Decisions

### 1 — Ops `source` vocabulary (`:sync` vs `:inline`)

- **D-01:** Emit **`source: :sync`** (not `:inline`) from the synchronous `Accrue.Billing.MeterEventActions` failure path so the closed enum is **`:sync | :reconciler | :webhook`** everywhere: code, **MTR-04**, `guides/telemetry.md`, `Accrue.Telemetry.Metrics` tag docs, operator runbooks, and tests. Update internal moduledocs that still say “inline vs deferred” to **“sync request path vs reconciler vs webhook.”**
- **D-02:** Treat the metadata value rename as a **telemetry contract change**: document in **`accrue/CHANGELOG.md`** (Telemetry subsection) so any host dashboard or attach handler matching on `:inline` can migrate once. Pre-1.0 Hex version is acceptable; prefer a single clean rename over dual keys or double emit.

### 2 — Idempotent retry, return contract, and “exactly one” failure telemetry (MTR-04)

- **D-03:** Define **`[:accrue, :ops, :meter_reporting_failed]`** as **billing-ops signal for the first durable transition of a given meter row into terminal `failed`** (per row / failure epoch), **not** “this HTTP/processor invocation returned an error.” Host retries, Stripe wire idempotency replays, and duplicate webhook deliveries must **not** inflate ops counters for the same row state.
- **D-04:** **Centralize** “mark row failed + emit ops telemetry” in one module-level choke point (extend **`Accrue.Billing.MeterEvents`** or equivalent) used by **`MeterEventActions`**, **`MeterEventsReconciler`**, and **`DefaultHandler.reduce_meter_error_report`**. Implementation should use a **guarded update** (e.g. `WHERE stripe_status = 'pending'` or allowed source states) so only the transition that actually flips the row emits **`meter_reporting_failed`**, avoiding double fires when reconciler and sync path race.
- **D-05:** After a row is **`failed`**, a subsequent **`report_usage/3`** with the same logical keys (same derived **`identifier`** / dedupe bucket) returns **`{:ok, %MeterEvent{stripe_status: "failed"}}`** — **not** a second **`{:error, _}`** — and performs **no** processor call when the loaded row is already **`reported`** or **`failed`** (idempotent **read-your-writes** semantics; aligns with Stripe “same idempotency key → same outcome” mental model).
- **D-06:** Align **`report_usage!/3`**: if the non-bang API returns **`{:ok, failed_row}`** on idempotent replay, the bang variant must **not** raise for that outcome (raise only when the non-bang would have returned a true error tuple such as validation / missing customer / insert failure).
- **D-07:** Document in **`Accrue.Billing` / `report_usage` ExDoc** (short paragraph): **`{:error, _}`** means this **call** could not establish or advance durable state as requested; **inspect the row** (`stripe_status`, `stripe_error`) when you need the persisted outcome after retries.

### 3 — Reconciler proof strategy (MTR-05)

- **D-08:** **Primary test harness:** insert a **`pending`** `%MeterEvent{}`, then **backdate `inserted_at`** with **`Repo.update_all`** (or equivalent) so the row is past the reconciler grace window — **no** process-kill between txn and processor, **no** sleeps. The spike “crash after commit” story stays **moduledoc / runbook** narrative; the **test contract** is observable **durable row shape** + **`MeterEventsReconciler.reconcile/0`** behavior.
- **D-09:** **Assertions:** **Repo-first** (`stripe_status`, `reported_at`, `stripe_error`); use **`Fake.scripted_response/2`** only for processor failure cases; **at most one** narrow **`:telemetry.attach`** on the reconciler failure test asserting **`source: :reconciler`** + `count: 1`. Prefer **`reconcile/0`** for bulk coverage; at most **one** optional **`Oban.Testing.perform_job`** smoke if cron wiring needs explicit proof. Keep **`BillingCase, async: false`** for these tests.

### 4 — Webhook meter error path + production wiring (MTR-06)

- **D-10 (critical):** Today **`DefaultHandler.handle_event/3`** dispatches with **`%{"id" => event.object_id}`** only, while **`reduce_meter_error_report/2`** needs the **full embedded Stripe object** (for **`identifier`** / nested **`reason`**). That means the **DispatchWorker** async path can miss identifiers even when **`handle/1`** tests pass. **Fix:** extend **`Accrue.Webhook.DispatchWorker.perform/1`** `ctx` with the persisted **`data["data"]["object"]`** map (string keys as stored), and add **`handle_event/3` clauses** for **`billing.meter.error_report_triggered`** and **`v1.billing.meter.error_report_triggered`** that pass that object into **`dispatch/4`** (same reducer as today’s **`handle/1`** path).
- **D-11:** **Tests:** add **`billing.meter.error_report_triggered`** (unversioned) coverage; add at least one test that exercises **`handle_event(type, event, ctx)`** (or **`safe_handle/3`**) with **DispatchWorker-shaped** `ctx` + **`Event.from_webhook_event/1`** projection so MTR-06 proves **production entry**, not only raw **`handle/1`** maps.
- **D-12:** **Webhook dedupe / idempotency:** HTTP ingest dedupes on Stripe **`processor_event_id`**; **add transition-guarded failure handling** so **redelivery or Oban retry** does **not** emit a **second** **`meter_reporting_failed`** for the same row already in **`failed`** with the same failure epoch (same principle as **D-03** / **D-04**). Optional **`Logger.info`** when webhook confirms an already-terminal row is acceptable.
- **D-13:** **Metadata parity (incremental):** In Phase 44, add **structured failure fields** to webhook **`meter_reporting_failed`** metadata where available (e.g. normalized **`error_code`** / **`message`** from `stripe_error`), matching the spirit of sync/reconciler paths. Full **cross-source metadata table** prose belongs in **Phase 45** (MTR-07..08) unless trivial to land here without scope creep.
- **D-14 (optional stretch):** If small, emit a dedicated **non-alerting** telemetry event for **unknown meter identifier** (today log-only) so ops can chart volume; if not small, **defer** with explicit note in **Deferred**.

### Claude's Discretion

- Exact helper names (`mark_failed_once/2` vs extending **`mark_failed_by_identifier/2`** with options) and the precise **`WHERE`** clause for guarded updates — planner/executor choose the smallest diff that satisfies **D-03..D-06** and **D-12**.
- Whether **`StripeFixtures.meter_event_error_report_triggered/1`** gains a sibling **`full_webhook_envelope/1`** helper — convenience only.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and milestone
- `.planning/REQUIREMENTS.md` — **MTR-04**, **MTR-05**, **MTR-06**
- `.planning/ROADMAP.md` — v1.10 table; Phase 44 goal and success criteria
- `.planning/PROJECT.md` — v1.10 narrative; Fake parity; observability expectations
- `.planning/research/v1.10-METERING-SPIKE.md` — four acceptance scenarios (items 2–4 are Phase 44)

### Prior phase constraints
- `.planning/phases/43-meter-usage-happy-path-fake-determinism/43-CONTEXT.md` — Repo-first tests, **`Accrue.Test.meter_events_for/1`**, minimal telemetry smoke in Phase 43, **`guides/telemetry.md`** SSOT
- `.planning/phases/40-telemetry-catalog-guide-truth/40-CONTEXT.md` — ops catalog discipline
- `.planning/phases/42-operator-runbooks/42-CONTEXT.md` — **`meter_reporting_failed`** mini-playbook

### Code entry points (implementation anchors)
- `accrue/lib/accrue/billing/meter_event_actions.ex` — sync path, **`emit_failure_telemetry/3`**, processor call ordering
- `accrue/lib/accrue/billing/meter_events.ex` — webhook failure persistence (extend for shared choke point per **D-04**)
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` — reconciler batch + failure telemetry
- `accrue/lib/accrue/webhook/default_handler.ex` — **`handle_event/3`**, **`handle/1`**, **`reduce_meter_error_report/2`**
- `accrue/lib/accrue/webhook/dispatch_worker.ex` — **`perform/1`**, **`ctx`** construction (extend per **D-10**)
- `accrue/lib/accrue/webhook/event.ex` — **`from_webhook_event/1`** projection
- `accrue/test/accrue/billing/meter_event_actions_test.exs` — sync failure + idempotency tests
- `accrue/test/accrue/jobs/meter_events_reconciler_test.exs` — reconciler tests
- `accrue/test/accrue/webhook/handlers/billing_meter_error_report_test.exs` — webhook reducer tests

### Docs / ship targets
- `accrue/guides/telemetry.md` — **`meter_reporting_failed`** row + `source` enum
- `accrue/guides/operator-runbooks.md` — meter mini-playbook
- `accrue/CHANGELOG.md` — telemetry contract note (**D-02**)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`Accrue.Test.setup_fake_processor/1`** and **`Accrue.Test.meter_events_for/1`** (Phase 43) for Fake-shaped assertions when needed; **Repo assertions remain primary** per Phase 43.
- **`Fake.scripted_response/2`** for deterministic **`{:error, _}`** injection.
- **`MeterEventsReconciler.reconcile/0`** — public seam already documented for tests.

### Established patterns
- **Transactional outbox:** short **`Repo.transact`** for **`pending`** + ledger, processor **outside** txn (`MeterEventActions` moduledoc).
- **Telemetry attach + detach** in **`try/after`** (`meter_event_actions_test.exs` pattern).

### Integration points
- **`DispatchWorker`** is the **production** webhook entry — Phase 44 must align **`handle_event/3`** with **`handle/1`** for meter errors (**D-10**).
- **Default metrics** tag **`source`** in **`Accrue.Telemetry.Metrics`** — keep a **3-value** closed set after **D-01**.

</code_context>

<specifics>
## Specific Ideas

- **Cross-ecosystem lesson:** Stripe and library consumers think **request-time** vs **event-time** vs **background reconciliation** — telemetry `source` should use that vocabulary (**`:sync`**, **`:webhook`**, **`:reconciler`**), not implementation layout terms (**`:inline`**).
- **Pay / Cashier lesson:** Alerting on **every retry** trains operators to ignore signals; tie **`meter_reporting_failed`** to **durable state transition**, not raw call count (**D-03**).
- Subagent research for this context is summarized in **`44-DISCUSSION-LOG.md`** (audit trail).

</specifics>

<deferred>
## Deferred Ideas

- **Full metadata schema table** across all three sources in prose (when **`error`**, when **`webhook_event_id`**, etc.) — **Phase 45** unless **D-13** lands trivially.
- **Dedicated telemetry for unknown meter identifier** — **D-14** optional stretch; otherwise explicit deferral to a later phase.
- **PROC-08** second processor — out of milestone per **PROJECT.md**.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 44.

</deferred>

---

*Phase: 44-meter-failures-idempotency-reconciler-webhook*  
*Context gathered: 2026-04-22*
