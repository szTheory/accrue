# Phase 131: Optional Chimeway Engine Adapter (isolated, off by default) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 131-optional-chimeway-engine-adapter-isolated-off-by-default
**Areas discussed:** Engine behaviour contract, Chimeway adapter self-containment, Cancel-on-recovery mechanism

---

## Engine Behaviour Contract

| Option | Description | Selected |
|--------|-------------|----------|
| 2 thin callbacks (`start_campaign/3` + `cancel_campaign/2`) | Campaign-boundary seam only. DB state (anchor CAS, anchor-clear) stays in Accrue's control. Built-in `Engine.Oban` is a trivial wrapper over existing `DunningStep.enqueue_step` + `Oban.cancel_all_jobs`. | ✓ |
| Larger surface with step-delivery callbacks | Adds `deliver_step/4`, `next_step/3` etc. giving alternate engines full control over step scheduling. Contradicts Phase 128 design note. | |

**User's choice:** 2 thin callbacks (recommended option)
**Notes:** User accepted the unanimous advisor recommendation. The two existing seam points in `default_handler.ex` map directly to the two callbacks — no restructuring of `DunningStep` internals needed.

---

## Chimeway Adapter Self-Containment

| Option | Description | Selected |
|--------|-------------|----------|
| Bundled `DunningNotifier` (batteries-included) | Adapter ships a default `Accrue.Integrations.Chimeway.DunningNotifier` implementing `Chimeway.Notifier` using Accrue's domain models. Host: add dep + set engine config = done. | ✓ |
| Thin scaffold (Sigra-style, host supplies notifier) | Adapter is a thin delegation layer. Host must implement all `Chimeway.Notifier` callbacks themselves. Violates SEED-002 "without changing call sites" promise. | |

**User's choice:** Bundled DunningNotifier (recommended option)
**Notes:** The Sigra analogy was noted as not transferring here — Sigra adapts auth (host owns identity), while dunning notification is Accrue's domain (Accrue owns Customer/Subscription/email templates). Bundled notifier is the only option consistent with "batteries-included on day one."

---

## Cancel-on-Recovery Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Signal-driven (`Chimeway.Signal.track/4` + `stop_conditions` on every wait step) | Idiomatic Chimeway 1.0.0 API. Durable (Signal row + SignalRouterWorker in single `Ecto.Multi`). Produces `{:stopped, run}` terminal `WorkflowRun` state. Survives node restarts. | ✓ |
| Direct API (`Chimeway.Deliveries.cancel_deferred_delivery/3`) | Single-row delivery operation. Leaves `WorkflowRun` in `waiting` state. Race condition with in-flight `SignalRouterWorker` violates DUN-05 correctness guarantee. | |

**User's choice:** Signal-driven via `Chimeway.Signal.track/4` (recommended option)
**Notes:** The advisor research confirmed that Chimeway 1.0.0 has no `cancel_run` public API — signal-driven is the only mechanism that achieves a durable, race-free whole-run termination. The critical constraint captured in CONTEXT.md: every `:wait` step in `DunningNotifier.workflow/2` MUST declare `stop_conditions` or the cancel has a gap.

---

## Claude's Discretion

- Exact module layout for `Engine.Oban` (same file as `Engine` behaviour vs. separate file)
- Whether `cancel_campaign/2` receives ISO anchor string or DateTime struct
- Test strategy for the `with_chimeway` matrix cell (mock-based vs. requiring live Chimeway)
- `tenant_id` resolution in cancel path

## Deferred Ideas

- Multi-channel dunning (SMS/push/in-app via Chimeway) — v1.40 is email-only
- Admin Chimeway state/traces UI — deep introspection stays in Chimeway's own UI
- Per-customer cadence override via Chimeway workflow — out of scope for v1.40
