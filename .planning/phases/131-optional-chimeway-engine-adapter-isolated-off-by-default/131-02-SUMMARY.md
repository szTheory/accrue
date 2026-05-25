---
phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default
plan: "02"
subsystem: dunning-engine
tags: [dunning, behaviour, config, dun-03]
dependency_graph:
  requires: []
  provides:
    - Accrue.Dunning.Engine behaviour (DUN-03 D-01)
    - Config.dunning_engine/0 accessor (DUN-03 D-03)
  affects:
    - accrue/lib/accrue/dunning/engine.ex
    - accrue/lib/accrue/config.ex
tech_stack:
  added: []
  patterns:
    - NimbleOptions :atom key for open module type (per RESEARCH Open Question 3)
    - Behaviour-only module (no facade delegation) dispatched via Config accessor
key_files:
  created:
    - accrue/lib/accrue/dunning/engine.ex
  modified:
    - accrue/lib/accrue/config.ex
decisions:
  - "Use type: :atom (not {:module, behaviour}) for the :engine NimbleOptions key — NimbleOptions has no built-in module/behaviour validator; @behaviour on each adapter enforces the contract at compile time"
  - "dunning_engine/0 returns the atom without Code.ensure_loaded? — T-131-03 mitigation; module resolution happens at dispatch time in default_handler.ex"
  - "Behaviour-only module (no facade delegation) — unlike Accrue.Auth, the engine is invoked directly via Config.dunning_engine().start_campaign(...)"
metrics:
  duration: "8min"
  completed: "2026-05-25T16:13:51Z"
  tasks: 2
  files: 2
---

# Phase 131 Plan 02: Engine Behaviour + Config Accessor Summary

Defined the `Accrue.Dunning.Engine` behaviour (DUN-03 D-01) and the `dunning: [engine:]` NimbleOptions config key + `Config.dunning_engine/0` accessor — the interface-first foundation that Plan 03 (Engine.Oban) and Plan 04 (Chimeway adapter) implement against.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create Accrue.Dunning.Engine behaviour | 5efb529f | accrue/lib/accrue/dunning/engine.ex (+) |
| 2 | Add :engine config key + dunning_engine/0 accessor | 89a728a4 | accrue/lib/accrue/config.ex (M) |

## What Was Built

**Task 1 — Accrue.Dunning.Engine behaviour**

New file `accrue/lib/accrue/dunning/engine.ex` defining `Accrue.Dunning.Engine` with exactly two arity-3 callbacks (D-01, locked signatures):

- `start_campaign(subscription :: Accrue.Billing.Subscription.t(), anchor_at :: DateTime.t(), opts :: keyword()) :: :ok | {:error, term()}`
- `cancel_campaign(subscription :: Accrue.Billing.Subscription.t(), iso_anchor :: String.t(), opts :: keyword()) :: :ok | {:error, term()}`

Behaviour-only module — no facade delegation functions. The engine is dispatched directly via `Config.dunning_engine().start_campaign(...)`. Module doc states the design contract: engines control which orchestration system is invoked at campaign boundaries; DB state is Accrue-managed regardless of engine; `Engine.Oban` is always-on; `Accrue.Integrations.Chimeway` is off-by-default and conditionally compiled.

**Task 2 — Config schema extension + accessor**

Two-site modification to `accrue/lib/accrue/config.ex`:

1. Added `engine: Accrue.Dunning.Engine.Oban` to the `:dunning` schema `default:` list and a new `engine:` key to `keys:` with `type: :atom`, `default: Accrue.Dunning.Engine.Oban`, and a `doc:` string containing the required substrings `Module implementing`, `Accrue.Dunning.Engine.Oban`, and `Accrue.Integrations.Chimeway`.

2. Added `dunning_engine/0` accessor after `dunning_campaign_steps/0`: returns `Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban)`. Atom-only return — no `Code.ensure_loaded?` per T-131-03 mitigation.

## Verification

- `mix compile --warnings-as-errors` exits 0
- `Accrue.Dunning.Engine.behaviour_info(:callbacks)` → `[start_campaign: 3, cancel_campaign: 3]`
- `Accrue.Config.dunning_engine()` → `Accrue.Dunning.Engine.Oban` (default, no config override)
- Custom engine override via `Application.put_env/3` resolves correctly
- 36 existing config tests pass, 0 failures, 0 regressions

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both files are production-complete for their scope. `Accrue.Dunning.Engine.Oban` (the default atom value) is created in Plan 03.

## Threat Flags

No new threat surface beyond what is documented in the plan's threat model. The `:engine` config key accepts any atom (T-131-02, accept disposition), and the accessor returns the atom without loading the module (T-131-03, mitigated).

## Self-Check: PASSED

- [x] `accrue/lib/accrue/dunning/engine.ex` exists
- [x] `accrue/lib/accrue/config.ex` modified
- [x] Commit `5efb529f` exists (Task 1)
- [x] Commit `89a728a4` exists (Task 2)
- [x] `{:start_campaign, 3}` and `{:cancel_campaign, 3}` in behaviour_info(:callbacks)
- [x] `dunning_engine/0` returns `Accrue.Dunning.Engine.Oban` by default
