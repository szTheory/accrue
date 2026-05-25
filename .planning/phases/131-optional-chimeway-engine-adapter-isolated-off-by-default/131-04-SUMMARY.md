---
phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default
plan: "04"
subsystem: dunning
tags: [chimeway, conditional-compile, dunning, engine-adapter, optional-dep]
dependency_graph:
  requires: ["131-02"]
  provides: ["Accrue.Integrations.Chimeway", "Accrue.Integrations.Chimeway.DunningNotifier"]
  affects: ["accrue/mix.exs", "accrue/lib/accrue/integrations/chimeway.ex"]
tech_stack:
  added: ["{:chimeway, \"~> 1.0\", optional: true}"]
  patterns: ["Sigra 4-pattern conditional compile", "Code.ensure_loaded? guard", "@compile {:no_warn_undefined, [...]}", "nested notifier defmodule"]
key_files:
  created:
    - accrue/lib/accrue/integrations/chimeway.ex
  modified:
    - accrue/mix.exs
    - accrue/mix.lock
decisions:
  - "workflow/2 omitted for v1.40 — :immediate orchestration creates no WorkflowRun; Signal.track is a safe no-op, cancel-on-recovery guaranteed by anchor-clear"
  - "stop_conditions DSL absent from chimeway.ex — confirmed not present in Chimeway 1.0.0 lib code (RESEARCH override)"
  - "DunningNotifier nested inside Accrue.Integrations.Chimeway — elided entirely when Chimeway absent, host needs zero Chimeway code"
  - "idempotency_key = 'accrue.dunning:<sub.id>:<iso_anchor>' — stable per-campaign, prevents concurrent webhook duplicate triggers (T-131-07)"
  - "tenant_id = sub.customer_id, actor_id = 'accrue.dunning' in Signal.track — scopes routing to customer tenant (T-131-09)"
metrics:
  duration: "7 minutes"
  completed: "2026-05-25"
  tasks: 2
  files: 3
---

# Phase 131 Plan 04: Chimeway Engine Adapter Summary

Off-by-default, conditionally-compiled `Accrue.Integrations.Chimeway` dunning engine adapter following the Sigra 4-pattern, with a bundled `DunningNotifier` implementing `Chimeway.Notifier`'s 4 required callbacks plus `channels/2` (email-only) and `orchestration/2` (:immediate).

## What Was Built

**Task 1 — Optional chimeway dep in mix.exs (commit `654e1673`)**

Added `{:chimeway, "~> 1.0", optional: true}` to the optional-deps block in `accrue/mix.exs`, alongside the existing OTel and telemetry_metrics optional deps. The optional marker means the default `mix deps.get` for accrue does NOT pull Chimeway; the `Code.ensure_loaded?` guard in the adapter elides the entire module when absent.

**Task 2 — Conditionally-compiled adapter + bundled DunningNotifier (commit `b380e08a`)**

Created `accrue/lib/accrue/integrations/chimeway.ex` cloning the Sigra 4-pattern exactly:

1. File header comment documenting the 4-pattern (replacing Sigra→Chimeway, auth→dunning engine)
2. `if Code.ensure_loaded?(Chimeway) do defmodule Accrue.Integrations.Chimeway do ... end end` outer guard
3. `@behaviour Accrue.Dunning.Engine` + `@compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}` inside defmodule
4. Runtime dispatch by config — host sets `config :accrue, dunning: [engine: Accrue.Integrations.Chimeway]`

Engine callbacks:
- `start_campaign/3`: calls `Chimeway.trigger(__MODULE__.DunningNotifier, params, idempotency_key: ..., tenant_id: sub.customer_id)` — stable idempotency key `"accrue.dunning:<sub.id>:<iso_anchor>"`, handles `{:duplicate, _}` as `:ok` no-op (T-131-07)
- `cancel_campaign/3`: calls `Chimeway.Signal.track(sub.customer_id, "accrue.dunning", "payment_recovered", %{subscription_id: sub.id})` — correct (tenant_id, actor_id, event_name, payload) arg order (T-131-08, T-131-09)

Nested `DunningNotifier` with:
- `notification_key/0` → `"accrue.dunning"`
- `version/0` → `1`
- `recipients/1` — resolves `subscription_id` → Subscription → Customer → `%{recipient_identity: customer.email, recipient_type: "email"}`
- `build/2` → `{:ok, %{subscription_id: ...}}`
- `channels/2` → `{:ok, [:email]}` (email-only for v1.40)
- `orchestration/2` → `{:ok, :immediate}` (no WorkflowRun created)
- `workflow/2` — intentionally OMITTED (RESEARCH override: `:immediate` + no `workflow/2` is correct for v1.40)

## Verification

- `mix compile --warnings-as-errors` exits 0 with Chimeway absent (adapter elided)
- `grep -c stop_conditions accrue/lib/accrue/integrations/chimeway.ex` → 0
- `grep -c "def workflow" accrue/lib/accrue/integrations/chimeway.ex` → 0
- `mix test test/accrue/integrations/chimeway_test.exs --seed 0` → **2 tests, 0 failures**

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 — mix.exs dep | `654e1673` | `chore(131-04): add {:chimeway, "~> 1.0", optional: true} dep to accrue/mix.exs` |
| Task 2 — adapter | `b380e08a` | `feat(131-04): add conditionally-compiled Chimeway dunning engine adapter` |

## Deviations from Plan

None — plan executed exactly as written.

The one file-level adjustment: the file header comment originally included "DO NOT add `stop_conditions`" as a negative directive mentioning the string `stop_conditions`. This was revised to "The workflow/2 optional callback is intentionally omitted for the v1.40 email-only path" to satisfy the `grep -c stop_conditions` must-return-0 acceptance criterion without losing the documentation intent.

## Threat Surface Scan

No new trust-boundary surface introduced beyond what the plan's `<threat_model>` covers:

| Threat | Mitigation in Code |
|--------|--------------------|
| T-131-07: Duplicate trigger from concurrent webhooks | `idempotency_key: "accrue.dunning:" <> sub.id <> ":" <> iso_anchor` + `{:duplicate, _} -> :ok` |
| T-131-08: Stale Signal.track cancels fresh re-lapse | iso_anchor is campaign-specific; payment_recovered payload carries old subscription_id only |
| T-131-09: Signal routing cross-tenant | `Signal.track(sub.customer_id, ...)` scopes routing to customer's tenant |
| T-131-10: Sensitive fields logged | trigger params (`subscription_id`, `customer_id`, `anchor`) contain no secrets; Chimeway payload sanitizer strips password/token/secret |

## Self-Check: PASSED

- `accrue/lib/accrue/integrations/chimeway.ex` — FOUND
- `accrue/mix.exs` contains `{:chimeway, "~> 1.0", optional: true}` — FOUND
- Commit `654e1673` exists — FOUND
- Commit `b380e08a` exists — FOUND
- 2 tests passing — VERIFIED
- 0 stop_conditions occurrences — VERIFIED
- 0 def workflow occurrences — VERIFIED
