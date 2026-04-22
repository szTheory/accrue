# Phase 43: Meter usage happy path + Fake determinism - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `43-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-04-21  
**Phase:** 43 — Meter usage happy path + Fake determinism  
**Areas discussed:** Public assertion surface (MTR-03); Deterministic identifiers; Documentation placement; Telemetry assertion scope  
**Method:** User selected **all** gray areas and requested parallel subagent research (ecosystem + idiomatic Elixir + tradeoffs); orchestrator synthesized into `43-CONTEXT.md`.

---

## 1 — Public assertion surface (MTR-03)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Document `Accrue.Processor.Fake.meter_events_for/1` only | Zero new API; direct Fake import in tests | |
| (b) `Accrue.Test` facade over Fake | Guarded delegate; matches `Oban.Testing`-style test namespaces | ✓ (merged with c) |
| (c) Repo / `%MeterEvent{}` assertions | Durable Ecto truth; idiomatic Phoenix host tests | ✓ (primary) |
| (d) Telemetry-only assertions | Observability contract; weak alone for billing correctness | |

**User's choice:** Research synthesis — **(c) primary**, **(b) secondary** via existing **`Accrue.Test`** module (not new top-level namespace).  
**Notes:** Pay/Cashier/Stripe patterns favor DB or retrieved resource truth over SDK-internal introspection. Footgun: leaking test helpers onto `Accrue.Billing`. Accrue already has `Accrue.Test` — extend it rather than blessing `Processor.Fake` as the main host-facing doc path.

---

## 2 — Deterministic identifiers

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed golden strings | Best for documented vectors; bad if shared under `async: true` | ✓ (for golden/idempotency tests only) |
| UUID / strong random per call | Parallel-safe; poor for stable docs | ✓ (acceptable where determinism not the subject) |
| Explicit `operation_id` / frozen `timestamp` | Caller-controlled dedupe surface (Stripe idempotency analogy) | ✓ |
| Random defaults everywhere | Hides dedupe behavior | |

**User's choice:** Synthesis — **explicit `operation_id` + fixed `timestamp` in opts** for golden and idempotency tests; **auto-generated operation_id** with process-local uniqueness for routine happy paths; **avoid** asserting full derived `identifier` unless derivation is under test.

**Notes:** ExUnit `async: true` + compile-time module attrs are a known footgun for uniqueness. Inject time via opts (already supported by schema) rather than wall clock.

---

## 3 — Documentation placement

| Option | Description | Selected |
|--------|-------------|----------|
| ExDoc only | Lowest drift for NimbleOptions | ✓ (SSOT for options) |
| `guides/testing.md` fragment | Workflow discoverability | ✓ |
| `guides/metering.md` stub | High creep into telemetry/Stripe narrative | |
| README option tables | High drift | |

**User's choice:** **ExDoc SSOT** + **`guides/testing.md`** fragment with links; **no** `guides/metering.md` in Phase 43; README at most one-line pointer.

**Notes:** Matches Hex/Phoenix library norms (reference in API docs, flows in guides). Respects Phase 40/42 `telemetry.md` SSOT — no duplicate ops tables.

---

## 4 — Telemetry assertion scope (Phase 43)

| Option | Description | Selected |
|--------|-------------|----------|
| Full catalog/metadata assertions in 43 | Strong regression signal; high churn | |
| DB / state only | Stable; MTR-focused | ✓ (primary) |
| Defer all telemetry to 44–45 | Clean phase split | ✓ (for substantive failure/multi-source) |
| Minimal smoke (one start/stop or stop-only) | Belt-and-suspenders on public entrypoint | ✓ (optional ceiling) |

**User's choice:** **Hybrid** — Phase 43 owns **MTR-01..MTR-03**; allow **at most** thin telemetry smoke (event name + no exception + optional 1–2 stable metadata keys); **defer** `meter_reporting_failed` depth to Phases 44–45.

**Notes:** OpenTelemetry and Rails notification testing cultures emphasize **narrow** assertions, not full dynamic attribute matrices.

---

## Claude's Discretion

- Exact public function name on `Accrue.Test` for meter event introspection.  
- Whether Phase 43 ships zero vs one centralized telemetry smoke test file.

## Deferred Ideas

- Full metering operator narrative and telemetry/runbook alignment — Phase **45** (**MTR-07..MTR-08**).  
- `guides/metering.md` — defer until milestone doc spine owns it.
