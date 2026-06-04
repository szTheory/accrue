---
phase: 178-e-seed-expressiveness-state-coverage
plan: "03"
subsystem: host-seeds
tags:
  - dunning
  - seed-idempotency
  - bugfix
  - regression-test
dependency_graph:
  requires:
    - 178-01
  provides:
    - dunning-bug-fix
    - hero-accounts-regression-test
    - e2e-fixture-allowlist-extension
  affects:
    - examples/accrue_host/priv/repo/seeds/hero_accounts.exs
    - examples/accrue_host/test/accrue_host/hero_accounts_test.exs
    - scripts/ci/accrue_host_seed_e2e.exs
tech_stack:
  added: []
  patterns:
    - TDD (RED/GREEN) for regression test
    - Binding reuse — past_due_subscription/canceled_subscription already in scope
    - Additive-only allowlist extension with e2e_ prefix
key_files:
  created:
    - path: examples/accrue_host/test/accrue_host/hero_accounts_test.exs
      note: Added regression test (second test in existing module)
  modified:
    - path: examples/accrue_host/priv/repo/seeds/hero_accounts.exs
      note: 3 phantom Ecto.UUID.generate() replaced with real subscription IDs
    - path: scripts/ci/accrue_host_seed_e2e.exs
      note: Extended @fixture_subscription_processor_ids and @fixture_customer_processor_ids
decisions:
  - "sub_7d/sub_90d use past_due_subscription.id (both share the same at-risk sub); sub_30d uses canceled_subscription.id (30d exhausted window maps to the canceled account)"
  - "sub_e2e_dunning_at_risk and sub_e2e_canceling added to allowlist even though they live in admin TestRepo — forward-compatible and harmless (allowlist entries only match if a row exists)"
  - "Invoice/charge processor_ids (in_e2e_edge_jpy, ch_e2e_edge_jpy) not added: cleanup_fixture_footprint! deletes invoices by LIKE 'inv_host_browser_%' pattern and charges via subscription cascade; explicit allowlist not needed for Plan 04 JPY entities"
metrics:
  duration: "~4 minutes"
  completed_date: "2026-06-04"
  tasks_completed: 2
  files_changed: 3
---

# Phase 178 Plan 03: Host Dunning Bug Fix + Regression Test + CI Idempotency Allowlist Extension Summary

Dunning events in hero_accounts.exs now reference real accrue_subscriptions IDs instead of phantom Ecto.UUID.generate() values; RecoveryLive at-risk table will be non-empty after seeding.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Add failing regression test | 5aa69ccf | hero_accounts_test.exs |
| 1 (GREEN) | Fix 3 phantom UUIDs → real subscription IDs | b489b597 | hero_accounts.exs |
| 2 | Extend @fixture_* allowlists | c47503ff | accrue_host_seed_e2e.exs |

## What Was Built

### Task 1: Dunning Bug Fix (TDD)

**RED:** Added a new test in `AccrueHost.HeroAccountsTest` that queries all `dunning.campaign_started` events with `subject_type == "Subscription"` and asserts each `subject_id` resolves to a real `Accrue.Billing.Subscription` row via `Repo.get/2`. Test failed with: `dunning.campaign_started event seed-dunning-7d-campaign_started has phantom subject_id <uuid>`.

**GREEN:** Replaced all three phantom UUID assignments in `hero_accounts.exs`:
- Line 101: `sub_7d = past_due_subscription.id` (was `Ecto.UUID.generate()`)
- Line 138: `sub_30d = canceled_subscription.id` (was `Ecto.UUID.generate()`)
- Line 164: `sub_90d = past_due_subscription.id` (was `Ecto.UUID.generate()`)

Both `past_due_subscription` and `canceled_subscription` were already bound at lines 31 and 55 respectively — no new queries required. Both tests now pass (2 tests, 0 failures).

### Task 2: @fixture_* Allowlist Extension

Extended `scripts/ci/accrue_host_seed_e2e.exs` module attributes:

**@fixture_subscription_processor_ids** — added 4 new entries:
- `sub_e2e_dunning_at_risk` (Plan 02 admin at-risk fixture)
- `sub_e2e_canceling` (Plan 02 admin canceling fixture)
- `sub_e2e_edge_at_risk` (Plan 04 host edge_states.exs at-risk sub)
- `sub_e2e_edge_canceling` (Plan 04 host edge_states.exs canceling sub)

**@fixture_customer_processor_ids** — added 1 new entry:
- `cus_e2e_edge_1` (Plan 04 host edge_states.exs long-name customer)

`seed_e2e_cleanup_test.exs` remains green (1 test, 0 failures). No `unrelated_` namespace collision.

## Verification Results

```
mix test test/accrue_host/hero_accounts_test.exs test/accrue_host/seed_e2e_cleanup_test.exs --seed 0
3 tests, 0 failures
```

- `grep "Ecto.UUID.generate" examples/accrue_host/priv/repo/seeds/hero_accounts.exs` — 0 matches
- `grep "past_due_subscription.id" hero_accounts.exs` — 2 matches (lines 101, 164)
- `grep "canceled_subscription.id" hero_accounts.exs` — 1 match (line 138)

## Deviations from Plan

None — plan executed exactly as written.

- Invoice/charge IDs (`in_e2e_edge_jpy`, `ch_e2e_edge_jpy`) from Plan 04: not added to explicit allowlists. Inspection of `cleanup_fixture_footprint!/0` shows invoices are cleaned by `LIKE 'inv_host_browser_%'` pattern (not an allowlist), and charges/subscription_items cascade-delete when their parent subscription is deleted by processor_id allowlist. No explicit invoice/charge allowlist exists in the file.

## TDD Gate Compliance

- RED commit: `5aa69ccf` — `test(178-03)` prefix, test fails before fix
- GREEN commit: `b489b597` — `fix(178-03)` prefix, tests pass after implementation
- Both gate commits verified in git log.

## Threat Flags

None — no new attack surface introduced. All changes are in host dev/test seeds and CI fixtures only.

## Self-Check: PASSED

- `examples/accrue_host/priv/repo/seeds/hero_accounts.exs` — exists, 3 phantom UUIDs replaced
- `examples/accrue_host/test/accrue_host/hero_accounts_test.exs` — exists, 2 tests pass
- `scripts/ci/accrue_host_seed_e2e.exs` — exists, 5 new allowlist entries added
- Commits 5aa69ccf, b489b597, c47503ff verified in git log
