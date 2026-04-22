# Phase 44: Meter failures, idempotency, reconciler + webhook - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`44-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 44 — Meter failures, idempotency, reconciler + webhook  
**Areas discussed:** (1) Ops `source` atoms, (2) Idempotent retry + failure telemetry, (3) Reconciler test strategy, (4) Webhook meter error path — via **parallel subagent research** + principal synthesis

---

## Research method

The user requested **`all`** gray areas with deep comparative research. Four **`generalPurpose`** subagents ran in parallel (pros/cons, Elixir/Ecto/Oban idioms, Pay/Cashier/Stripe parallels, DX and least surprise). Findings were merged into a **single coherent decision set** in **`44-CONTEXT.md`** (no contradictions: e.g. subagent idempotency note still said `:inline` in places — **canonical project choice is `:sync`** per requirements + catalog).

---

## 1 — Ops `source` vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| A | Rename **`:inline` → `:sync`** in code + tests; docs already say `:sync` | ✓ |
| B | Keep **`:inline`**; rewrite requirements + telemetry guide |  |
| C | Dual emit / alias keys |  |

**User's choice:** Research-driven default (Option A), aligned with **MTR-04**, **`guides/telemetry.md`**, and principle of least surprise for operators.

**Notes:** Reconciler moduledoc historically contrasted “inline vs deferred”; implementation comment in **`MeterEventActions`** should adopt **sync / reconciler / webhook** language.

---

## 2 — Idempotent retry + failure telemetry

| Theme | Recommendation | Rationale |
|-------|----------------|-----------|
| Telemetry semantics | Emit **`meter_reporting_failed`** on **transition into `failed`**, not on every processor error | Avoids Pay-style alert fatigue on retries |
| Return contract | **`{:ok, failed_row}`** on idempotent replay; **skip processor** for terminal **`reported` / `failed`** rows | Read-your-writes; Stripe idempotency mental model |
| Implementation | **Guarded update** + shared choke point for all three sources | Races between sync, reconciler, webhook |
| Bang variant | **Do not raise** on idempotent **`{:ok, failed_row}`** | Consistent with non-bang |

**User's choice:** Full research-backed stack (see **D-03..D-07** in CONTEXT).

**Code note surfaced in research:** **`report_usage/3`** currently may still call **`Processor.report_meter_event/1`** after **`insert_pending`** returns an existing row — Phase 44 should branch on **`stripe_status`** per CONTEXT **D-05**.

---

## 3 — Reconciler test strategy

| Harness | Verdict |
|---------|---------|
| (A) Insert `pending` + backdate `inserted_at` | ✓ Primary |
| (B) Simulate crash between commit and processor | ✗ Skip — wrong layer, brittle |
| (C) `Process.exit` kill games | ✗ Avoid — flaky, tests wrong concern |

**User's choice:** (A) + Repo-first assertions + narrow telemetry attach on failure; **`reconcile/0`** as main seam.

---

## 4 — Webhook meter error path

| Finding | Severity |
|---------|----------|
| **`handle_event/3`** passes only `%{"id" => event.object_id}`; reducer needs full **`data.object`** | **Production gap** for async dispatch |
| Tests mostly **`handle/1`** + versioned type only | Coverage gap vs **MTR-06** |

**User's choice:** Extend **`DispatchWorker`** `ctx` with persisted embedded object; dedicated **`handle_event`** clauses for both type strings; contract test on async path; transition-guarded telemetry (**D-10..D-12**).

---

## Claude's Discretion

- Exact SQL/Ecto shape for guarded updates and helper naming — left to implementation (**CONTEXT** “Claude's Discretion”).

## Deferred Ideas

See **`44-CONTEXT.md` `<deferred>`** — Phase 45 doc alignment; optional unknown-identifier telemetry.
