---
phase: 146
plan: "01"
subsystem: billing/webhook
tags: [dunning, query-composer, event-enrichment, tdd]
dependency_graph:
  requires: []
  provides: [emit_campaign_started/2, in_active_dunning_campaign/1]
  affects: [accrue/lib/accrue/billing/query.ex, accrue/lib/accrue/webhook/default_handler.ex]
tech_stack:
  added: []
  patterns: [composable-query-fragment, tdd-red-green]
key_files:
  created: []
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/lib/accrue/billing/query.ex
    - accrue/test/accrue/webhook/dunning_campaign_start_test.exs
    - accrue/test/accrue/billing/query_test.exs
decisions:
  - "D-04: emit_campaign_started/2 stores invoice_id: get(canonical, :id) in dunning.campaign_started data map; telemetry metadata unchanged (T-146-02 compliant)"
  - "D-11: in_active_dunning_campaign/1 uses WHERE dunning_campaign_started_at IS NOT NULL, composable predicate following dunning_sweep_candidates/2 pattern"
metrics:
  duration: "2m"
  completed: "2026-05-27"
  tasks: 2
  files: 4
---

# Phase 146 Plan 01: emit_campaign_started/2 + in_active_dunning_campaign/1 Summary

**One-liner:** `emit_campaign_started/2` now injects Stripe Invoice ID into `dunning.campaign_started` event data; `in_active_dunning_campaign/1` composable query predicate added to `Accrue.Billing.Query`.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 (RED) | Failing test: invoice_id in campaign_started event | d8844631 | dunning_campaign_start_test.exs |
| 1 (GREEN) | emit_campaign_started/1 → /2 with invoice_id enrichment | f97105df | default_handler.ex |
| 2 (RED) | Failing tests: in_active_dunning_campaign/1 | d7709a70 | query_test.exs |
| 2 (GREEN) | in_active_dunning_campaign/1 query composer | e1a48959 | query.ex |

## What Was Built

### Task 1: emit_campaign_started/1 → /2 (D-04)

Refactored `emit_campaign_started` from a 1-arity to a 2-arity private function in `accrue/lib/accrue/webhook/default_handler.ex`:

- Call site changed from `emit_campaign_started(sub)` to `emit_campaign_started(sub, canonical)` in `maybe_start_dunning_campaign/2`.
- Function signature updated to `defp emit_campaign_started(%Subscription{} = sub, canonical)`.
- `data` map in `Events.record/1` extended: `%{step_count: step_count, invoice_id: get(canonical, :id)}`.
- Telemetry metadata (`Accrue.Telemetry.Ops.emit`) left unchanged — no `invoice_id` in telemetry per T-146-02.
- `get/2` macro already imported in the enclosing scope — no new import required.

### Task 2: in_active_dunning_campaign/1 (D-11)

New composable query function added to `accrue/lib/accrue/billing/query.ex`:

```elixir
@doc "Subscriptions currently in an active dunning campaign (anchor column is non-nil). Composable — pipe after any Subscription query to add the campaign-active predicate."
@spec in_active_dunning_campaign(Ecto.Queryable.t()) :: Ecto.Query.t()
def in_active_dunning_campaign(query \\ Subscription) do
  from(s in query, where: not is_nil(s.dunning_campaign_started_at))
end
```

Placed after `dunning_sweep_candidates/2`, before the module `end`. No new imports or aliases required — module-level `import Ecto.Query` already covers all needed macros.

## Verification

Full run: `mix test test/accrue/webhook/dunning_campaign_start_test.exs test/accrue/billing/query_test.exs --seed 0`

**Result: 16 tests, 0 failures**

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all behavioral changes are complete with real data flows.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundaries introduced. T-146-02 mitigation (no `invoice_id` in telemetry) confirmed by test assertion.

## TDD Gate Compliance

Both tasks followed RED/GREEN cycle:

- Task 1: `test(146-01)` commit (RED) → `feat(146-01)` commit (GREEN)
- Task 2: `test(146-01)` commit (RED) → `feat(146-01)` commit (GREEN)

RED gates confirmed as actual failures before implementation.

## Self-Check: PASSED

- `accrue/lib/accrue/webhook/default_handler.ex` — modified, exists ✓
- `accrue/lib/accrue/billing/query.ex` — modified, exists ✓
- `accrue/test/accrue/webhook/dunning_campaign_start_test.exs` — modified, exists ✓
- `accrue/test/accrue/billing/query_test.exs` — modified, exists ✓
- Commit d8844631 exists ✓
- Commit f97105df exists ✓
- Commit d7709a70 exists ✓
- Commit e1a48959 exists ✓
