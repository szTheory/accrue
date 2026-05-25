---
phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default
plan: "03"
subsystem: dunning-engine
tags: [dunning, engine-adapter, oban, webhook, refactor, DUN-03]
one_liner: "Engine.Oban behaviour impl + default_handler.ex seams routed through Config.dunning_engine()"
dependency_graph:
  requires: ["131-02"]
  provides: ["131-04"]
  affects: ["accrue/lib/accrue/dunning/engine/oban.ex", "accrue/lib/accrue/webhook/default_handler.ex"]
tech_stack:
  added: []
  patterns:
    - "@behaviour Accrue.Dunning.Engine verbatim extraction from default_handler.ex"
    - "Config.dunning_engine() dispatch replacing hardcoded DunningStep calls"
    - "Process-dict stash carries full %Subscription{} struct (not bare sub_id)"
key_files:
  created:
    - accrue/lib/accrue/dunning/engine/oban.ex
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
decisions:
  - "emit_campaign_started/1 stays in default_handler.ex called BEFORE engine dispatch (RESEARCH Pitfall 3)"
  - "cancel_campaign/3 rescue returns :ok to honour D-12 never-crash contract"
  - "day_zero_step_key/0 private helper copied to Engine.Oban (only calls Accrue.Config — always-on)"
  - "Process-dict stash upgraded from {sub_id, iso_anchor} to {%Subscription{}, iso_anchor} enabling Chimeway adapter to read sub.customer_id as tenant_id (Plan 04 prerequisite)"
metrics:
  duration_minutes: 8
  completed_date: "2026-05-25"
  tasks_completed: 2
  files_changed: 2
requirements: [DUN-03]
---

# Phase 131 Plan 03: Engine.Oban + default_handler seam routing Summary

Engine.Oban behaviour impl + default_handler.ex seams routed through Config.dunning_engine() — verbatim extraction of enqueue/cancel bodies with zero default-host behavior change.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Create Accrue.Dunning.Engine.Oban (verbatim extraction) | 7dbe3e34 | accrue/lib/accrue/dunning/engine/oban.ex (created) |
| 2 | Route default_handler.ex seams through Config.dunning_engine() + stash full struct | 61466f2c | accrue/lib/accrue/webhook/default_handler.ex |

## What Was Built

### Task 1 — `Accrue.Dunning.Engine.Oban`

New file `accrue/lib/accrue/dunning/engine/oban.ex` implementing `@behaviour Accrue.Dunning.Engine`.

**`start_campaign/3`** — verbatim extraction from the former `enqueue_day_zero_step/3` in `default_handler.ex`, minus `emit_campaign_started/1` (that stays in the handler). Resolves the day-0 step via a private `day_zero_step_key/0` copy. Wraps `DunningStep.enqueue_step/4` return values into `:ok | {:error, term()}` to satisfy the callback contract.

**`cancel_campaign/3`** — verbatim extraction from the former `cancel_dunning_steps/2`, keyed on `^sub.id` instead of a bare `sub_id` binary. The `rescue e -> Logger.warning(...); :ok` block is preserved exactly (D-12 never-crash contract).

**Isolation:** Zero Chimeway references. Only references always-on deps (`Oban`, `Accrue.Workers.DunningStep`, `Accrue.Config`). Compiles unconditionally.

### Task 2 — `default_handler.ex` seam modifications

Three surgical changes only, no behavioral change for default hosts:

1. **SEAM 1 (start):** `maybe_start_dunning_campaign/2` count==1 branch now calls `emit_campaign_started(sub)` first (moved out of the deleted `enqueue_day_zero_step/3`) then dispatches via `Accrue.Config.dunning_engine().start_campaign(sub, now_usec, [invoice_id: get(canonical, :id)])`.

2. **SEAM 2 stash write:** `Process.put(:accrue_dunning_cancel, {updated, iso_anchor})` — stores the full `%Subscription{}` struct instead of `updated.id` so the Chimeway adapter (Plan 04) can read `sub.customer_id` as its tenant_id.

3. **SEAM 2 stash read:** `run_post_commit_dunning_cancel/1` matches `{%Subscription{} = sub, iso_anchor}` and dispatches `Accrue.Config.dunning_engine().cancel_campaign(sub, iso_anchor, [])`.

**Removed from `default_handler.ex`:** `enqueue_day_zero_step/3`, `cancel_dunning_steps/2`, `day_zero_step_key/0` (all bodies now live in `Engine.Oban`).

## Verification Results

- `mix compile --warnings-as-errors` exits 0 — no unused-function warnings
- `mix test test/accrue/dunning/engine_test.exs test/accrue/dunning/engine/oban_test.exs --seed 0` — 9/9 tests pass (5 behaviour-contract + 4 start/cancel unit tests)
- `mix test test/accrue/dunning/ test/accrue/webhook/default_handler_test.exs --seed 0` — 21/21 tests pass (full dunning suite + handler suite; includes Phase 130 full-journey regression)
- `grep -c "defp enqueue_day_zero_step|defp cancel_dunning_steps" default_handler.ex` = 0

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both seams are fully wired. `Config.dunning_engine()` resolves to `Accrue.Dunning.Engine.Oban` by default and the engine dispatches real Oban jobs.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The process-dict stash upgrade (T-131-06 accepted in plan threat register) stores the full `%Subscription{}` struct in the current process's dict for the duration of one synchronous webhook call. The struct is consumed-and-deleted on read. `customer_id` and `id` are reference IDs, not PII.

## Self-Check: PASSED

Files verified present:
- `accrue/lib/accrue/dunning/engine/oban.ex` — FOUND
- `accrue/lib/accrue/webhook/default_handler.ex` — FOUND (modified)

Commits verified:
- `7dbe3e34` — feat(131-03): create Accrue.Dunning.Engine.Oban — FOUND
- `61466f2c` — feat(131-03): route default_handler.ex seams — FOUND
