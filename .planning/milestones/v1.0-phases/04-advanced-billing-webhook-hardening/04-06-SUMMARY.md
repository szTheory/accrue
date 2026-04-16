---
phase: 04-advanced-billing-webhook-hardening
plan: 06
subsystem: webhook-hardening-events-query-api
tags: [wave-6, wh-08, wh-13, evt-05, evt-06, evt-10, dlq, mix-tasks, multi-endpoint, upcaster, query-api, d4-04]
dependency_graph:
  requires:
    - "04-01 (config keys: dlq_replay_batch_size, dlq_replay_stagger_ms, dlq_replay_max_rows, webhook_endpoints; events_type_inserted_at index)"
    - "Phase 2 D2-33 (WebhookEvent status enum + replay semantics)"
    - "Phase 2 D2-34 (Pruner shape locked)"
    - "Phase 2 D2-35 (dead-letter transition)"
    - "Phase 1 EVT-04 (Accrue.Events.record/1 idempotency key path)"
    - "Phase 3 D3-69 (Accrue.Events.Upcaster behaviour)"
  provides:
    - "Accrue.Webhooks.DLQ public API: requeue/1, requeue_where/2, list/2, count/1, prune/1, prune_succeeded/1 (dual bang/tuple)"
    - "Mix tasks accrue.webhooks.replay (single + bulk + dry-run + --all-dead --yes --force) and accrue.webhooks.prune"
    - "Accrue.Webhook.Pruner now delegates to DLQ.prune/prune_succeeded and emits [:accrue, :ops, :webhook_dlq, :prune] telemetry"
    - "Accrue.Events.timeline_for/3, state_as_of/3, bucket_by/2 query API (EVT-06/EVT-10)"
    - "Accrue.Events.UpcasterRegistry.chain/3 with explicit unknown-version error (EVT-05)"
    - "Accrue.Events.Upcasters.V1ToV2 sample upcaster registered for subscription.created"
    - "Accrue.Webhook.Plug multi-endpoint mode via :endpoint init opt + :webhook_endpoints config (WH-13)"
  affects:
    - "Phase 7 accrue_admin will consume Accrue.Webhooks.DLQ.list/2 + requeue/1 + requeue_where/2"
    - "Ops surface complete: telemetry namespace [:accrue, :ops, :webhook_dlq, :replay | :prune] available for dashboards"
    - "Read path for events ledger now safe under schema_version evolution"
tech_stack:
  added: []
  patterns:
    - "Library-core + thin Mix wrapper (D4-04) — Accrue.Webhooks.DLQ owns logic, Mix.Tasks.Accrue.Webhooks.Replay/Prune are 80-line argv-parsers"
    - "Replay-via-fresh-Oban-job (Pitfall 3) — Oban.insert/2 with webhook_event_id arg, NEVER Oban.retry_job/2 which refuses :discarded/:cancelled"
    - "Audit-on-replay (T-04-06-05) — every requeue records webhook.replay_requested ledger row with idempotency_key 'replay:' <> processor_event_id"
    - "Bulk replay safety (T-04-06-03) — batch_size + stagger_ms + dlq_replay_max_rows hard cap with --force escape hatch"
    - "Endpoint-scoped secret resolution (WH-13) — :endpoint opt looks up :webhook_endpoints[endpoint][:secret]; missing endpoint raises Accrue.SignatureError → 400 fail-closed (T-04-06-01)"
    - "Backward-compat plug — calls without :endpoint fall back to legacy :processor-keyed webhook_signing_secrets (Phase 2 plug tests untouched)"
    - "Upcaster chain on read (Pitfall 10) — every row routed through UpcasterRegistry.chain/3 BEFORE folding in state_as_of/3 and timeline_for/3"
    - "Surface-or-die upcaster (Pitfall 9) — unknown schema_version raises ArgumentError + emits [:accrue, :ops, :events_upcast_failed]; never silent drop"
    - "Literal date_trunc fragments per bucket atom (T-04-06-08) — bucket_size constrained to :day/:week/:month, mapped to hardcoded fragments to satisfy Postgres GROUP BY equivalence detection"
key_files:
  created:
    - "accrue/lib/accrue/webhooks/dlq.ex"
    - "accrue/lib/accrue/events/upcaster_registry.ex"
    - "accrue/lib/accrue/events/upcasters/v1_to_v2.ex"
    - "accrue/lib/mix/tasks/accrue.webhooks.replay.ex"
    - "accrue/lib/mix/tasks/accrue.webhooks.prune.ex"
    - "accrue/test/accrue/webhooks/dlq_test.exs"
    - "accrue/test/accrue/events/query_api_test.exs"
    - "accrue/test/accrue/events/upcaster_registry_test.exs"
    - "accrue/test/accrue/webhook/multi_endpoint_test.exs"
    - "accrue/test/mix/tasks/accrue_webhooks_replay_test.exs"
  modified:
    - "accrue/lib/accrue/events.ex (alias UpcasterRegistry; full Ecto.Query import; added timeline_for/3, state_as_of/3, bucket_by/2, upcast_to_current/1, current_schema_version/1)"
    - "accrue/lib/accrue/webhook/pruner.ex (delegates to DLQ; emits prune telemetry)"
    - "accrue/lib/accrue/webhook/plug.ex (accepts :endpoint init opt, resolves secrets via webhook_endpoints config; legacy :processor mode preserved)"
decisions:
  - "Used plain error atoms ({:error, :not_found | :already_replayed | :not_dead_lettered | :replay_too_large}) instead of plan's %Accrue.Error{type:} struct because the codebase has no Accrue.Error module — only Accrue.APIError + per-error defexceptions. Atom returns match Phase 3 actions convention."
  - "Pruner delegates to Accrue.Webhooks.DLQ.prune/prune_succeeded (single source of truth for retention SQL). Removes import Ecto.Query + alias WebhookEvent from Pruner since both are now encapsulated inside DLQ."
  - "Plug multi-endpoint mode is opt-in via :endpoint init opt — Phase 2 callers using only :processor still work unchanged. This avoids touching Phase 2 plug_test.exs and the existing Accrue.Router macro."
  - "bucket_by/2 uses literal date_trunc strings per bucket atom because Postgres rejects parameterized GROUP BY/SELECT fragments as 'not in GROUP BY' even when textually identical — guard prevents SQL injection (only :day/:week/:month accepted), no parameter is interpolated into the SQL string at runtime."
  - "Query API tests insert events via direct Ecto.Changeset.change/2 with explicit inserted_at because sandbox transactions cause Postgres now() to return the txn start time identically for every record/1 call within a test, breaking time-based assertions. read_after_writes still reads the value back but Postgres honors explicit values over column DEFAULT."
metrics:
  duration: "~30m"
  completed_date: "2026-04-15"
  tasks_completed: 2
  tests_added: 31
  files_created: 10
  files_modified: 3
---

# Phase 04 Plan 06: Webhook Hardening + Events Query API Summary

## One-Liner

Operator-grade webhook DLQ replay tooling (Mix tasks + library), Connect-ready multi-endpoint plug, append-only events query API (timeline/state-as-of/buckets), and a chain-composition upcaster registry that surfaces unknown schema versions instead of dropping them — closing WH-08, WH-13, EVT-05, EVT-06, and EVT-10 in one wave.

## What Was Built

### 1. `Accrue.Webhooks.DLQ` (WH-08)

Public API for ops engineers and Phase 7 admin LV alike:

- `requeue/1` — single dead-lettered row → fresh Oban dispatch job inside `Repo.transact/2`, ledger row `webhook.replay_requested` recorded with idempotency key `"replay:" <> processor_event_id`
- `requeue_where/2` — bulk replay with `:batch_size`, `:stagger_ms`, `:dry_run`, `:force` opts; hard-capped at `Config.dlq_replay_max_rows()` (default 10_000) unless `force: true`
- `list/2`, `count/1` — paginated browse + accurate count for confirm prompts
- `prune/1`, `prune_succeeded/1` — retention sweepers, accept `:infinity` for disabled pruning
- All public functions ship in dual bang/tuple form per D-05

Telemetry: `[:accrue, :ops, :webhook_dlq, :replay]` (per-replay) and `[:accrue, :ops, :webhook_dlq, :prune]` (per-sweep).

### 2. Mix Tasks

- `mix accrue.webhooks.replay <event_id>` — single requeue
- `mix accrue.webhooks.replay --since 2026-04-01 --type invoice.payment_failed --dry-run` — bulk audit
- `mix accrue.webhooks.replay --all-dead --yes` — bulk replay (>10 rows prompts unless `--yes`)
- `mix accrue.webhooks.replay --force` — bypass max-rows cap
- `mix accrue.webhooks.prune` — manual retention sweep (cron-equivalent code path)

Both tasks are thin wrappers that parse argv and call `Accrue.Webhooks.DLQ.*`.

### 3. `Accrue.Webhook.Pruner` Refactor

Now delegates to `Accrue.Webhooks.DLQ.prune/1` and `prune_succeeded/1`, and emits `[:accrue, :ops, :webhook_dlq, :prune]` with both deletion counts and retention windows in metadata. Single source of truth for retention SQL.

### 4. `Accrue.Webhook.Plug` Multi-Endpoint Mode (WH-13)

Opt-in `:endpoint` init option; when present, plug looks up the signing secret via `Accrue.Config.webhook_endpoints/0[endpoint][:secret]`. Missing endpoint config raises `Accrue.SignatureError` (rescued to HTTP 400) — fail-closed, never bypasses verification (T-04-06-01).

Phase 2 callers passing only `:processor` continue to work via `Accrue.Config.webhook_signing_secrets/1` — zero changes to existing routes, plug tests, or `Accrue.Router` macro.

### 5. `Accrue.Events` Query API (EVT-06 / EVT-10)

- `timeline_for(subject_type, subject_id, opts)` — events ordered ascending by `inserted_at`, `:limit` opt
- `state_as_of(subject_type, subject_id, ts)` — folds `data` maps from rows where `inserted_at <= ts`, returns `%{state, event_count, last_event_at}`
- `bucket_by(filter, :day | :week | :month)` — groups by `date_trunc('bucket', inserted_at)`, returns `[{datetime, count}]`

Both `timeline_for/3` and `state_as_of/3` route every row through `UpcasterRegistry.chain/3` before returning (Pitfall 10 mitigation).

### 6. `Accrue.Events.UpcasterRegistry` (EVT-05)

- `chain(type, from, to)` returns:
  - `{:ok, []}` when `from == to` (identity)
  - `{:ok, []}` when type is unregistered (most types)
  - `{:ok, [Mod1, ...]}` when a chain is registered
  - `{:error, {:unknown_schema_version, v}}` when target version is unknown for a registered type — never silently drops (Pitfall 9)

Sample `Accrue.Events.Upcasters.V1ToV2` registered against `subscription.created` to exercise the chain composition path in tests.

## Verification Results

```
mix test                                 → 524 tests, 36 properties, 0 failures (2 excluded)
mix test test/accrue/webhooks/dlq_test.exs                              → 13/13 pass
mix test test/mix/tasks/accrue_webhooks_replay_test.exs                 → 3/3 pass
mix test test/accrue/events/query_api_test.exs                          → 10/10 pass
mix test test/accrue/events/upcaster_registry_test.exs                  → 5/5 pass
mix test test/accrue/webhook/multi_endpoint_test.exs                    → 5/5 pass
mix compile --warnings-as-errors         → clean
mix credo --strict                       → 1341 mods/funs, 0 issues
```

Net additions: +31 tests (490 → 524).

## Commits

| Hash      | Message                                                              |
| --------- | -------------------------------------------------------------------- |
| `c27d0bc` | feat(04-06): DLQ replay/prune library + Mix tasks (WH-08)            |
| `223bbed` | feat(04-06): events query API, upcaster registry, multi-endpoint plug |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan referenced non-existent `%Accrue.Error{type:}` shape**
- **Found during:** Task 1 implementation
- **Issue:** Plan's example code used `%Accrue.Error{type: :not_found}` but the codebase only ships `Accrue.APIError`, `Accrue.CardError`, etc. — no umbrella `Accrue.Error` struct exists.
- **Fix:** Returned plain error atoms (`{:error, :not_found | :already_replayed | :not_dead_lettered | :replay_too_large}`) which matches Phase 3 action module conventions.
- **Files modified:** `accrue/lib/accrue/webhooks/dlq.ex`
- **Commit:** `c27d0bc`

**2. [Rule 1 - Bug] `actor_type: :admin` atom rejected by Event.changeset cast**
- **Found during:** Task 1 first test run
- **Issue:** `Accrue.Events.Event.changeset/1` uses `cast/3` for `actor_type` against a `:string` column, so passing the atom `:admin` produced `{:error, [actor_type: {"is invalid", ...}]}`.
- **Fix:** Pass `actor_type: "admin"` as a string (matches `Accrue.Actor` enum string form).
- **Files modified:** `accrue/lib/accrue/webhooks/dlq.ex`

**3. [Rule 1 - Bug] Mix task `confirm_if_nuclear!` raised BadBooleanError on non-`--all-dead` invocations**
- **Found during:** Task 1 Mix task tests
- **Issue:** `if opts[:all_dead] and not opts[:yes]` — `nil and not nil` is invalid because `and` requires booleans on the left side.
- **Fix:** Compared explicitly: `if opts[:all_dead] == true and opts[:yes] != true do`.
- **Files modified:** `accrue/lib/mix/tasks/accrue.webhooks.replay.ex`

**4. [Rule 1 - Bug] `bucket_by/2` with parameterized `^bucket_str` failed Postgres GROUP BY equivalence**
- **Found during:** Task 2 query API tests
- **Issue:** Three identical `fragment("date_trunc(?, ?)", ^bucket_str, e.inserted_at)` calls in GROUP BY / ORDER BY / SELECT compiled to expressions with parameter references; Postgres treats them as non-equal even when textually identical, raising `column "a0.inserted_at" must appear in the GROUP BY clause`.
- **Fix:** Replaced with literal `fragment("date_trunc('day', ?)", e.inserted_at)` per bucket atom; the bucket_size guard already restricts input to `:day/:week/:month` so the literal is fully safe (no SQL injection vector — the bucket string is never user-supplied).
- **Files modified:** `accrue/lib/accrue/events.ex`

**5. [Rule 1 - Bug] Multi-endpoint test router declared `/webhooks/stripe` before `/webhooks/stripe/connect`**
- **Found during:** Task 2 multi-endpoint plug tests
- **Issue:** `Plug.Router.forward` matches by prefix in declaration order, so `/webhooks/stripe/connect` requests were caught by the `/webhooks/stripe` forward and routed through the primary endpoint.
- **Fix:** Reordered router so more specific prefixes (`/webhooks/stripe/connect`, `/webhooks/stripe/missing`) are declared before `/webhooks/stripe`.
- **Files modified:** `accrue/test/accrue/webhook/multi_endpoint_test.exs`

**6. [Rule 1 - Bug] Sandbox transactions cause Postgres `now()` to be identical for every event in a test**
- **Found during:** Task 2 `state_as_of/3` test
- **Issue:** Tests using `Events.record/1` to seed events with sleeps between calls observed the same `inserted_at` for every row because all inserts happen inside the parent sandbox txn — Postgres `now()` returns the txn-start time, not wall time. Time-based assertions produced false positives.
- **Fix:** Query API tests now insert events directly via `%Event{} |> Ecto.Changeset.change(%{..., inserted_at: explicit_ts}) |> TestRepo.insert!()` — Postgres honors the explicit value over the column DEFAULT, and `read_after_writes: true` simply reads it back unchanged.
- **Files modified:** `accrue/test/accrue/events/query_api_test.exs`

### Authentication Gates

None — Task 1 and Task 2 are pure library/plug work with no external auth.

## Threat Flags

None — no new external surface beyond what the plan's `<threat_model>` already enumerates. The `:endpoint` opt expands the existing webhook trust boundary in a constrained, fail-closed way (T-04-06-01 mitigation).

## Self-Check: PASSED

Verified files exist:

- `accrue/lib/accrue/webhooks/dlq.ex` — FOUND
- `accrue/lib/accrue/events/upcaster_registry.ex` — FOUND
- `accrue/lib/accrue/events/upcasters/v1_to_v2.ex` — FOUND
- `accrue/lib/mix/tasks/accrue.webhooks.replay.ex` — FOUND
- `accrue/lib/mix/tasks/accrue.webhooks.prune.ex` — FOUND
- `accrue/test/accrue/webhooks/dlq_test.exs` — FOUND
- `accrue/test/accrue/events/query_api_test.exs` — FOUND
- `accrue/test/accrue/events/upcaster_registry_test.exs` — FOUND
- `accrue/test/accrue/webhook/multi_endpoint_test.exs` — FOUND
- `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs` — FOUND

Commits verified in `git log`:

- `c27d0bc` — FOUND
- `223bbed` — FOUND

Test suite green: `mix test → 524 tests, 0 failures`.
Lint green: `mix credo --strict → 0 issues`.
Compile clean: `mix compile --warnings-as-errors → no warnings`.
