---
phase: 178-e-seed-expressiveness-state-coverage
plan: "04"
subsystem: host-seed
tags:
  - seed
  - edge-states
  - idempotency
  - multi-currency
dependency_graph:
  requires:
    - 178-02
    - 178-03
  provides:
    - host:edge_states.exs dev seed
    - canceling subscription in host dev DB
    - at-risk/dunning subscription in host dev DB
    - JPY charge and invoice in host dev DB
    - long-name customer in host dev DB
  affects:
    - examples/accrue_host/priv/repo/seeds.exs
    - examples/accrue_host/priv/repo/seeds/edge_states.exs
tech_stack:
  added: []
  patterns:
    - upsert (Repo.get_by processor/processor_id → insert if nil)
    - force_status_changeset for :past_due subscription seeding
    - Invoice.changeset/2 for :open status on new inserts
key_files:
  created:
    - examples/accrue_host/priv/repo/seeds/edge_states.exs
  modified:
    - examples/accrue_host/priv/repo/seeds.exs
decisions:
  - Use Invoice.changeset/2 (not force_status_changeset) for :open status — new-record transitions accept any status (data.status == nil passes validate_transition)
  - eval_file matches existing seeds.exs pattern; never require_file (memoizes globally, silently skips on 2nd+ eval in test runs)
metrics:
  duration: "8m"
  completed: "2026-06-04"
  tasks: 2
  files: 2
---

# Phase 178 Plan 04: Edge States Host Seed Summary

Host dev seed (`edge_states.exs`) wired into `seeds.exs` — idempotent canceling sub, at-risk/dunning sub, JPY charge, JPY invoice, and long-name customer via the upsert (get-or-insert) pattern.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create edge_states.exs with idempotent canceling sub, JPY charge, and long-name customer | 541406f8 | examples/accrue_host/priv/repo/seeds/edge_states.exs (created) |
| 2 | Wire edge_states.exs into seeds.exs + verify full seed chain and suite green | 28d8b370 | examples/accrue_host/priv/repo/seeds.exs (modified) |

## What Was Built

### edge_states.exs (new)

New host dev seed file at `examples/accrue_host/priv/repo/seeds/edge_states.exs`. Seeds five entities using the idempotent upsert helper (Repo.get_by processor/processor_id → insert if nil):

1. **Long-name customer** (`cus_e2e_edge_1`): name = "E2E Edge LongName — " + 90-char repeat = 110-char total. Exercises name-truncation paths across CustomerLive, SubscriptionLive, InvoiceLive, ChargeLive.

2. **At-risk / dunning subscription** (`sub_e2e_edge_at_risk`): status `:past_due` via `Subscription.force_status_changeset/2`; `dunning_campaign_started_at` set 5 days ago. Populates RecoveryLive and CampaignLive, and triggers `ax-badge-danger` chip in SubscriptionLive.

3. **Canceling subscription** (`sub_e2e_edge_canceling`): status `:active` + `cancel_at_period_end: true` + `current_period_end` 7 days future. Exercises the `canceling?/1` predicate path. Seeded via standard `Subscription.changeset/2`.

4. **JPY charge** (`ch_e2e_edge_jpy`): `currency: "jpy"`, `amount_cents: 55_000`. Exercises zero-decimal multi-currency charge path in ChargesLive and ChargeLive.

5. **JPY invoice** (`in_e2e_edge_jpy`): status `:open`, `currency: "jpy"`, `total_minor: 55_000`. Uses `Invoice.changeset/2` — `:open` is a non-terminal status and new-record inserts (data.status == nil) pass `validate_transition` for any status.

### seeds.exs (modified)

Appended `Code.eval_file("seeds/edge_states.exs", __DIR__)` after `showcase.exs` in the eval_file chain.

## Verification

- `mix run priv/repo/seeds/edge_states.exs` runs clean (first run inserts 5 rows)
- Second run: only SELECT queries — no duplicate inserts (idempotent)
- `grep "edge_states.exs" seeds.exs` → match found
- `grep "cancel_at_period_end: true" edge_states.exs` → match found
- `grep "currency.*jpy" edge_states.exs` → match found
- Host suite: **188 tests, 0 failures** (`mix test --seed 0`)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all five entities are fully wired with real schema fields.

## Threat Flags

No new network endpoints, auth paths, or trust boundary surfaces introduced. Seed files run in dev/test only.

## Self-Check: PASSED

- `examples/accrue_host/priv/repo/seeds/edge_states.exs` exists: FOUND
- `examples/accrue_host/priv/repo/seeds.exs` contains `edge_states.exs`: FOUND
- Commit 541406f8 exists: FOUND
- Commit 28d8b370 exists: FOUND
- 188 tests pass, 0 failures: PASSED
