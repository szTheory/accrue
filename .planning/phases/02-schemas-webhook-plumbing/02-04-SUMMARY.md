---
phase: 02-schemas-webhook-plumbing
plan: 04
subsystem: webhooks
tags: [webhooks, oban, ecto-multi, handler-dispatch, dlq, pruner, idempotency]

# Dependency graph
requires:
  - plan: 02-01
    provides: WebhookEvent schema, migrations, ingest_changeset, status_changeset
  - plan: 02-03
    provides: Webhook.Plug, Signature, Event, CachingBodyReader, Router macro
provides:
  - Transactional webhook ingest (persist + Oban enqueue + ledger in single Multi)
  - Handler behaviour with crash-isolated dispatch chain
  - DefaultHandler for customer.* event reconciliation
  - DispatchWorker with 25-attempt retry and DLQ status management
  - Pruner cron worker for configurable webhook event retention
affects: [02-05, phase-03, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns: [Ecto.Multi for atomic persist+enqueue+ledger, SELECT-then-INSERT dedup for binary_id, rescue-wrapped handler dispatch, Oban cron worker for retention]

key-files:
  created:
    - accrue/lib/accrue/webhook/ingest.ex
    - accrue/lib/accrue/webhook/handler.ex
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/webhook/pruner.ex
    - accrue/test/accrue/webhook/ingest_test.exs
    - accrue/test/accrue/webhook/dispatch_worker_test.exs
  modified:
    - accrue/lib/accrue/webhook/dispatch_worker.ex
    - accrue/lib/accrue/webhook/plug.ex
    - accrue/lib/accrue/webhook/event.ex
    - accrue/lib/accrue/config.ex
    - accrue/test/accrue/webhook/plug_test.exs

key-decisions:
  - "SELECT-then-INSERT dedup instead of Pitfall 2 (on_conflict id:nil) because binary_id autogenerate produces client-side UUIDs"
  - "Oban.insert/1 inside Multi.run instead of Multi-aware Oban.insert/3 for conditional enqueue"
  - "DefaultHandler needs explicit catch-all because defoverridable replaces injected fallthrough"
  - "Plug tests updated from ExUnit.Case to RepoCase since Ingest requires DB"

patterns-established:
  - "Ecto.Multi.run for conditional writes (dedup check, conditional enqueue, conditional ledger)"
  - "Handler behaviour with use macro injecting fallthrough + defoverridable"
  - "safe_handle/3 pattern: rescue-wrapped dispatch with telemetry exception event"
  - "Pruner: separate retention periods per webhook event status class"

requirements-completed: [WH-03, WH-04, WH-05, WH-06, WH-07, WH-10, WH-11, WH-12]

# Metrics
duration: 9min
completed: 2026-04-12
---

# Phase 02 Plan 04: Webhook Ingest Pipeline + Handler Dispatch Summary

**Transactional webhook ingest with Ecto.Multi (persist+Oban+ledger atomic), crash-isolated handler dispatch chain with DefaultHandler, DLQ status management, and configurable retention pruner -- 12 passing tests covering idempotency, crash isolation, and status lifecycle**

## What Was Built

### Accrue.Webhook.Ingest (accrue/lib/accrue/webhook/ingest.ex)

Orchestrates the atomic persist+enqueue pipeline (D2-24). Uses `Ecto.Multi` with three `run` steps:

1. **:persist** -- SELECT-then-INSERT with `on_conflict: :nothing` guard. Checks for existing event first, inserts if new, returns `{:new, row}` or `{:duplicate, existing}`. The SELECT-first pattern is needed because binary_id autogenerate produces client-side UUIDs, making the Pitfall 2 approach (`id: nil` on conflict) unreliable.

2. **:maybe_enqueue** -- Conditionally inserts an Oban job for `DispatchWorker` only for new events. Uses `Oban.insert/1` inside `Multi.run` (runs within the Multi's transaction context).

3. **:maybe_ledger** -- Conditionally records a `"webhook.received"` entry in the accrue_events ledger via `Accrue.Events.record/1`.

All three succeed atomically or none do. Duplicate POSTs return 200 with no side effects.

### Webhook.Plug Integration

Replaced the temporary `send_resp(200, ...)` in `Accrue.Webhook.Plug.do_call/2` with `Accrue.Webhook.Ingest.run/4`. The Plug now: verify signature -> project event -> persist+enqueue+respond. Updated plug tests from `ExUnit.Case` to `RepoCase` since Ingest requires DB access.

### Accrue.Webhook.Handler (accrue/lib/accrue/webhook/handler.ex)

Behaviour with `handle_event/3` callback (D2-27). The `__using__` macro injects a `defoverridable` fallthrough clause that returns `:ok` for unmatched event types (D2-28).

### Accrue.Webhook.DefaultHandler (accrue/lib/accrue/webhook/default_handler.ex)

Non-disableable default handler (D2-30). Phase 2 scope: handles `customer.created`, `customer.updated`, `customer.deleted` with log+no-op (full reconciliation via `Accrue.Processor.retrieve_customer/2` deferred to Phase 3). Includes explicit catch-all for unmatched types.

### Accrue.Webhook.DispatchWorker (accrue/lib/accrue/webhook/dispatch_worker.ex)

Oban worker (`queue: :accrue_webhooks`, `max_attempts: 25`). Loads WebhookEvent row, transitions to `:processing`, projects to lean `Event` struct via `Event.from_webhook_event/1`, dispatches to handler chain:

1. DefaultHandler first (non-disableable)
2. User handlers from `Accrue.Config.webhook_handlers/0` sequentially
3. Each handler rescue-wrapped via `safe_handle/3` -- crashes logged + telemetry emitted, don't block other handlers
4. Only default handler failure triggers Oban retry
5. Status transitions: `:processing` -> `:succeeded` (on success) or `:failed`/`:dead` (on failure, depending on attempt count)

### Accrue.Webhook.Pruner (accrue/lib/accrue/webhook/pruner.ex)

Oban cron worker (`queue: :accrue_maintenance`) for webhook event retention (D2-34). Deletes `:succeeded` events older than `succeeded_retention_days` (default 14) and `:dead` events older than `dead_retention_days` (default 90). Either can be set to `:infinity` to disable. Host wires the cron schedule.

### Event.from_webhook_event/1

Added to `Accrue.Webhook.Event` -- projects from persisted `WebhookEvent` DB row to lean `Event` struct. Extracts `object_id` from the stored `data` map's `data.object.id` path.

### Config Additions

- `:succeeded_retention_days` -- pos_integer or `:infinity`, default 14
- `:dead_retention_days` -- pos_integer or `:infinity`, default 90
- `:webhook_handlers` -- list of handler modules, default []
- Convenience functions: `succeeded_retention_days/0`, `dead_retention_days/0`, `webhook_handlers/0`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SELECT-then-INSERT dedup instead of on_conflict:nothing id:nil**
- **Found during:** Task 1, GREEN phase
- **Issue:** Plan specified Pitfall 2 approach (`on_conflict: :nothing` + `returning: true` returns struct with `id: nil` on conflict). With binary_id autogenerate, Ecto generates UUIDs client-side before INSERT, so the struct always has an id regardless of conflict.
- **Fix:** Used explicit SELECT-then-INSERT inside `Multi.run`, with `on_conflict: :nothing` as a race-condition guard on the INSERT.
- **Files modified:** accrue/lib/accrue/webhook/ingest.ex
- **Commit:** 7418169

**2. [Rule 1 - Bug] DefaultHandler explicit catch-all clause**
- **Found during:** Task 2, GREEN phase
- **Issue:** `use Accrue.Webhook.Handler` injects a fallthrough via `defoverridable`, but when DefaultHandler defines its own clauses, the injected fallthrough is replaced. Unknown event types raised `FunctionClauseError`.
- **Fix:** Added explicit `def handle_event(_type, _event, _ctx), do: :ok` as final clause in DefaultHandler.
- **Files modified:** accrue/lib/accrue/webhook/default_handler.ex
- **Commit:** b86239d

**3. [Rule 1 - Bug] Plug unused variable after Ingest wiring**
- **Found during:** Task 1
- **Issue:** `event = Accrue.Webhook.Event.from_stripe(...)` became unused after replacing temporary 200 with `Ingest.run/4`. Compilation failed with `--warnings-as-errors`.
- **Fix:** Removed the unused `event` assignment. Event projection now happens inside DispatchWorker from the persisted row.
- **Files modified:** accrue/lib/accrue/webhook/plug.ex
- **Commit:** 7418169

**4. [Rule 3 - Blocking] Plug tests updated to use RepoCase**
- **Found during:** Task 1
- **Issue:** Plug tests used `ExUnit.Case, async: true` but Ingest requires DB access via Ecto sandbox. Tests failed with `DBConnection.OwnershipError`.
- **Fix:** Changed plug tests to `use Accrue.RepoCase`. Updated the `conn.private` assertion test to verify DB persistence instead (private assigns no longer set by Plug).
- **Files modified:** accrue/test/accrue/webhook/plug_test.exs
- **Commit:** 7418169

## Verification

- `mix compile --warnings-as-errors` exits 0
- `mix test test/accrue/webhook/ingest_test.exs` -- 5 tests, 0 failures
- `mix test test/accrue/webhook/dispatch_worker_test.exs` -- 7 tests, 0 failures
- `mix test test/accrue/webhook/` -- 18 tests, 0 failures (including plug tests)
- Duplicate POST produces no second row, no second Oban job
- Transaction atomicity confirmed (all 3 artifacts exist together)
- Request completes in <6ms (well under 100ms target)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 7418169 | Transactional ingest pipeline, Plug wiring, config additions |
| 2 | b86239d | Handler behaviour, DefaultHandler, DispatchWorker, Pruner |

## Self-Check: PASSED

- All 7 created/modified source files: FOUND
- All 2 test files: FOUND
- Commit 7418169: FOUND
- Commit b86239d: FOUND
- All 17 acceptance criteria: PASSED
