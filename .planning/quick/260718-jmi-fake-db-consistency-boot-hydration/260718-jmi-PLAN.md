---
quick_id: 260718-jmi
title: Boot-time Fake↔DB consistency so /app/billing plan actions work
status: complete
created: 2026-07-18
---

# Quick Task 260718-jmi: Boot-time Fake↔DB consistency

## Goal
Fix the pre-existing bug uncovered by 260718-iwa: the demo's in-memory `Accrue.Processor.Fake`
uses sequential IDs from a fresh counter on each boot, but the seeds ran in a separate BEAM node
and persisted `cus_fake_/sub_fake_` IDs to Postgres. So on the running server, `subscribe` collides
(`Ecto.ConstraintError`) and `swap_plan`/`cancel` hit `resource_missing` for seeded personas — no
plan action ever worked. Fix: rehydrate the running Fake from the seeded DB rows at boot, and route
"Choose a different plan" to a swap.

## Tasks
1. **Core Fake seam** — `accrue/lib/accrue/processor/fake.ex`: add `load_fixtures/1` (+ `handle_call`)
   that inserts customers/subscriptions (reusing `build_subscription/3`, which honors explicit sub +
   item IDs) and raises the per-resource counters past loaded IDs. Test in `fake_test.exs`.
2. **Host boot hydration** — NEW `examples/accrue_host/lib/accrue_host/fake_hydration.ex`: on boot,
   query `processor == "fake"` customers + subscriptions (preload customer + items), map to
   descriptors, compute counter floors from `*_fake_NNNNN` suffixes, call `Fake.load_fixtures/1`.
   Guarded on processor == Fake; try/rescue so it never blocks boot. Wired in `application.ex`
   `start/2` after the Repo, before the dev banner.
3. **Swap routing** — `subscription_live.ex`: `start_subscription` calls `change_plan` (swap) when an
   active non-canceled subscription exists on a different plan; else `subscribe`. Reuses the
   "Subscription started." flash. Test in `subscription_live_test.exs`.

## Verification
- `accrue`: `mix test test/accrue/processor/fake_test.exs` → 23/0 (incl. 2 new load_fixtures tests);
  `mix compile --warnings-as-errors` EXIT 0.
- `accrue_host`: `mix test .../subscription_live_test.exs` → 5/0 (incl. swap test); compile EXIT 0.
- Boot log: "FakeHydration loaded 636 customers and 623 subscriptions".
- Playwright (live, seeded healthy@): Choose Studio → "Subscription started.", current shows Studio,
  no crash, no billing error; Cancel → "Subscription canceled now". 7/7.
- No `ConstraintError`/`resource_missing` in web logs during the flow.

## Note
Live verification exercised (and thus mutated) the healthy persona → it is now on a canceled Studio
subscription. `make reset` in examples/accrue_host restores pristine seeded personas when a clean demo
is wanted.
