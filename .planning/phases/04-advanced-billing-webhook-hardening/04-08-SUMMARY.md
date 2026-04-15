---
phase: 04-advanced-billing-webhook-hardening
plan: 08
subsystem: observability
tags: [telemetry, observability, ops, sre, metrics, otel, obs-03, obs-04, obs-05]
requires:
  - Accrue.Telemetry (Phase 1 — span/3 + naming conventions)
  - Accrue.Actor.current_operation_id/0 (Phase 2 — pdict seed)
  - :telemetry_metrics (optional dep, declared in Phase 1 mix.exs)
provides:
  - Accrue.Telemetry.Ops.emit/3 (ops namespace helper)
  - Accrue.Telemetry.Metrics.defaults/0 (15-metric SRE recipe)
  - guides/telemetry.md (ExDoc extra guide)
affects:
  - accrue/mix.exs (registered guide in docs[:extras])
tech_stack:
  added: []
  patterns:
    - "Conditional compile via Code.ensure_loaded?(Telemetry.Metrics) — module shapes itself around presence of optional dep"
    - "Hardcoded namespace prefix in helper (defense in depth — callers cannot inject events outside [:accrue, :ops])"
    - "Map.put_new_lazy/3 for auto-merge fields — preserves caller's explicit value when supplied"
key_files:
  created:
    - accrue/lib/accrue/telemetry/ops.ex
    - accrue/lib/accrue/telemetry/metrics.ex
    - accrue/test/accrue/telemetry/ops_test.exs
    - accrue/test/accrue/telemetry/metrics_test.exs
    - accrue/guides/telemetry.md
  modified:
    - accrue/mix.exs
decisions:
  - "Use Accrue.Actor.current_operation_id/0 (not the plan's nominal Accrue.Context.operation_id/0 — Accrue.Context module does not exist; Actor is the canonical pdict facade per Phase 2 D2-12)"
  - "Conditional-compile sentinel module raises a clear install message instead of silently returning [] when :telemetry_metrics is absent — louder failure prevents silent metric loss"
  - "Default recipe ships 15 metrics not 14 — explicitly include both webhook_dlq.replay.count and webhook_dlq.prune.dead_deleted so SREs can wire DLQ dashboards without touching every event in the table"
metrics:
  duration_minutes: 4
  task_count: 2
  file_count: 6
  completed_date: 2026-04-15
---

# Phase 04 Plan 08: Telemetry Ops Namespace + Default Metrics + Span Conventions Guide Summary

**One-liner:** SRE-actionable `[:accrue, :ops, :*]` namespace helper + 15-metric `Telemetry.Metrics` recipe + guides/telemetry.md documenting OpenTelemetry span naming and PII exclusion contract.

## What was built

Closes the final three observability requirements for Phase 4 — OBS-03 (high-signal ops namespace), OBS-04 (span naming conventions), OBS-05 (default `Telemetry.Metrics` recipe). Together these three pieces turn Accrue from "library that emits telemetry" into "library that drops into an existing SRE stack with one line of glue code".

### `Accrue.Telemetry.Ops.emit/3`

Hardcoded `[:accrue, :ops]` prefix helper for high-signal events. Two clauses (atom suffix → wraps in list; list suffix → real implementation). Auto-merges `operation_id` from `Accrue.Actor.current_operation_id/0` via `Map.put_new_lazy/3` so callers never have to remember to thread it through, and explicit caller-supplied values are preserved. Eight canonical Phase 4 ops events are documented in the moduledoc.

### `Accrue.Telemetry.Metrics`

Conditionally compiled on `Code.ensure_loaded?(Telemetry.Metrics)`. When `:telemetry_metrics` is present, `defaults/0` returns 15 metric definitions:

- 3 billing context counters (subscription create, charge create, report_usage)
- 3 webhook pipeline metrics (received, dispatched, queue_depth `last_value`)
- 1 webhook duration `summary` (native → millisecond)
- 8 ops counters (webhook_dlq dead_lettered/replay/prune, dunning_exhaustion, meter_reporting_failed, charge_failed, revenue_loss, incomplete_expired)

When `:telemetry_metrics` is absent, the sentinel module raises a clear install message instead of silently returning `[]` — so SREs notice immediately that they're missing the dep rather than wondering why their dashboards are empty.

Tags are restricted to low-cardinality fields only (`:status`, `:source`, `:type`, `:stripe_status`) — customer/subscription IDs are spans not tags (T-04-08-03 mitigation).

### `guides/telemetry.md`

ExDoc extra guide registered in `mix.exs` `docs[:extras]`. Six sections:

1. **Namespace split** — firehose vs ops, why the split exists
2. **Ops events in v1.0** — full table of all 8 ops events with measurements + metadata shapes
3. **Span naming conventions** — `accrue.<domain>.<resource>.<action>` pattern, span kind rules, worked examples
4. **Attribute conventions** — allowed allowlist + PROHIBITED PII exclusion list
5. **Using the default metrics recipe** — 4-line host wiring snippet + cardinality discipline note
6. **Emitting custom ops events** — `Ops.emit/3` usage patterns

## Acceptance criteria

| Criterion | Result |
|-----------|--------|
| `Ops.emit/3` enforces `[:accrue, :ops]` prefix | PASS — atom and list clauses both prepend |
| `Ops.emit/3` auto-merges operation_id from `Accrue.Actor.current_operation_id/0` | PASS — `Map.put_new_lazy/3` |
| Explicit `operation_id` in metadata preserved (no override) | PASS — test 4 verifies |
| `Metrics.defaults/0` returns ≥14 definitions | PASS — returns 15 |
| Conditional compile on `:telemetry_metrics` presence | PASS — `Code.ensure_loaded?(Telemetry.Metrics)` gate |
| guides/telemetry.md contains span naming pattern, ops events, PROHIBITED PII section, host wiring snippet | PASS — all 11 grep checks green |
| `mix.exs` `docs[:extras]` includes the guide | PASS |
| `mix docs` exits 0 with no warnings about new guide | PASS — pre-existing Subscription.t warnings unrelated |
| `mix test test/accrue/telemetry/...` exits 0 | PASS — 10 tests, 0 failures |
| Full suite (`mix test`) exits 0 | PASS — 555 tests + 36 properties, 0 failures |
| `mix credo --strict` on new files exits 0 | PASS — 8 mods/funs, no issues |

## Test coverage

- **`ops_test.exs`** — 4 tests (1 per acceptance criterion):
  1. Atom suffix → `[:accrue, :ops, :dunning_exhaustion]`
  2. List suffix → `[:accrue, :ops, :webhook_dlq, :replay]`
  3. operation_id auto-merge from `Accrue.Actor` pdict
  4. Explicit `operation_id` preservation
- **`metrics_test.exs`** — 6 tests:
  1. Returns ≥14 definitions
  2. Every entry is a `Telemetry.Metrics` struct
  3. Contains `accrue.ops.dunning_exhaustion.count`
  4. Contains `accrue.ops.webhook_dlq.dead_lettered.count`
  5. Contains `summary` on `accrue.webhooks.dispatch.duration`
  6. Contains revenue_loss / incomplete_expired / charge_failed counters

10/10 green. Telemetry handler-cleanup is wired through `on_exit/1` so cross-test pdict pollution is impossible.

## Threat model dispositions

| Threat ID | Status | Mitigation |
|-----------|--------|------------|
| T-04-08-01 (PII via metadata) | mitigated | Guide documents PROHIBITED attributes; runtime enforcement is host responsibility (Accrue cannot inspect arbitrary values) |
| T-04-08-02 (Tampering namespace) | mitigated | `[:accrue, :ops]` prefix is hardcoded in `emit/3`; no caller override path |
| T-04-08-03 (DoS via cardinality) | mitigated | `defaults/0` tags restricted to enumerated low-cardinality fields; cardinality discipline section in guide |
| T-04-08-04 (Repudiation — missing operation_id) | mitigated | `Map.put_new_lazy/3` auto-pulls from pdict |
| T-04-08-05 (OTel attribute PII leak) | mitigated | Guide enumerates allowed attributes + exhaustive PROHIBITED list |
| T-04-08-06 (Spoofed metric reporter) | accepted | Trust boundary ends at `:telemetry.execute/3`; host owns reporter config |

## Deviations from Plan

### [Rule 1 — Bug] Plan referenced non-existent `Accrue.Context.operation_id/0`

- **Found during:** Task 1 read-first phase
- **Issue:** Plan said to call `Accrue.Context.operation_id/0` for the auto-merge. The `Accrue.Context` module does not exist in this codebase — operation_id lives at `Accrue.Actor.current_operation_id/0` (Phase 2 D2-12).
- **Fix:** Used `Accrue.Actor.current_operation_id/0` in both the implementation and the moduledoc reference. The system reminder in the executor prompt called this out explicitly: "Accrue.Actor.current_operation_id".
- **Files modified:** `accrue/lib/accrue/telemetry/ops.ex`
- **Commit:** `c051228`

### [Rule 2 — Critical functionality] Sentinel module raises instead of silently returning `[]`

- **Found during:** Task 1 implementation
- **Issue:** Plan's `else` branch was already a raise, but worth flagging — silent `defaults() -> []` would be the more dangerous default (SREs would deploy thinking metrics were wired, find empty dashboards days later).
- **Fix:** The sentinel module raises a clear `mix.exs` install message at call-time, so missing dep is impossible to ignore.
- **Files modified:** `accrue/lib/accrue/telemetry/metrics.ex`
- **Commit:** `c051228`

No Rule 4 (architectural) deviations. No auth gates.

## Phase 4 — complete

Plan 04-08 is the final wave of Phase 04. All 22 Phase 4 requirement IDs are now closed:

- BILL-11, BILL-12, BILL-13 (Plans 01–03 — usage billing, schedules, comp/pause)
- BILL-15 (Plan 04 — dunning policy + sweeper)
- COUP-01..04, INV-01..02 (Plan 05 — coupons + promotion codes + invoice discounts)
- WH-08..14 (Plan 06 — DLQ + multi-endpoint + query API)
- CHKT-01..06 (Plan 07 — Checkout + Customer Portal)
- **OBS-03, OBS-04, OBS-05 (Plan 08 — this plan — ops namespace + span conventions + metrics recipe)**

## Self-Check: PASSED

**Files verified to exist:**
- `accrue/lib/accrue/telemetry/ops.ex` — FOUND
- `accrue/lib/accrue/telemetry/metrics.ex` — FOUND
- `accrue/test/accrue/telemetry/ops_test.exs` — FOUND
- `accrue/test/accrue/telemetry/metrics_test.exs` — FOUND
- `accrue/guides/telemetry.md` — FOUND
- `accrue/mix.exs` — modified, `extras: ["guides/telemetry.md"]` confirmed

**Commits verified:**
- `5a7ec21` (test RED) — FOUND
- `c051228` (feat GREEN) — FOUND
- `dcba301` (docs guide) — FOUND
