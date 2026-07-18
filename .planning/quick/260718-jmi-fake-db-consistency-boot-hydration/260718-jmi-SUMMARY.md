---
quick_id: 260718-jmi
title: Boot-time Fake↔DB consistency so /app/billing plan actions work
status: complete
date: 2026-07-18
commits: ffdad355, c23a6656
---

# Quick Task 260718-jmi — Summary

## What changed
- **`accrue/lib/accrue/processor/fake.ex`** (commit `ffdad355`) — new public `load_fixtures/1` + its
  `handle_call`: inserts customers and subscriptions into the in-memory state keyed by `processor_id`
  (reusing `build_subscription/3`, which honors explicit subscription + item ids) and raises the
  per-resource counters past the loaded ids via a counter floor. Additive, idempotent. Two new tests in
  `fake_test.exs` (rehydrated sub is mutable via update/cancel; counter floor makes fresh creates skip
  loaded ids).
- **`examples/accrue_host/lib/accrue_host/fake_hydration.ex`** (NEW, commit `c23a6656`) — `run/0` loads
  every `processor == "fake"` customer + subscription (preloading customer + items) into the running Fake
  and passes counter floors computed from `*_fake_NNNNN` suffixes. Guarded to the Fake processor;
  try/rescue + Logger so a failure never blocks boot.
- **`application.ex`** — calls `AccrueHost.FakeHydration.run/0` in `start/2` after the Repo starts,
  before the dev banner.
- **`subscription_live.ex`** — `start_subscription` routes to `change_plan` (swap) when an active,
  non-canceled subscription exists on a different plan; otherwise subscribes. Reuses the
  "Subscription started." flash. New `subscription_live_test.exs` test asserts a plan change swaps (one
  subscription row, item now on `price_pro`).

## Why
Removing automatic tax (260718-iwa) exposed that the demo's Fake keeps state in memory with sequential
ids reset to 0 each boot, while the seeds — run in a **separate BEAM node** — had persisted
`cus_fake_/sub_fake_` ids to Postgres. So on the running server every `subscribe` collided on the
`processor_id` unique index (crash) and `swap`/`cancel` hit `resource_missing`. Rehydrating the Fake from
the DB at boot (restart-proof) + advancing counters fixes create/change/cancel for the seeded personas.

## Verification
- `accrue`: `mix test test/accrue/processor/fake_test.exs` → **23/0**; `mix compile --warnings-as-errors` EXIT 0.
- `accrue_host`: `mix test .../subscription_live_test.exs` → **5/0**; compile EXIT 0.
- Boot log: `FakeHydration loaded 636 customers and 623 subscriptions into the Fake processor`.
- Playwright (live, seeded **healthy@** on Launch): **7/7** — Choose Studio → "Subscription started.",
  current subscription flips to **Studio**, no crash, no billing error; Cancel → "Subscription canceled now".
- No `Ecto.ConstraintError` / `resource_missing` in web logs during the flow.

## Note / follow-up
Live verification exercised the healthy persona, so it is now on a **canceled Studio** subscription (the
flows mutate real data, as intended). `make reset` in `examples/accrue_host` (nuke volume + reseed;
idempotent seeds won't restore an already-subscribed org otherwise) restores pristine seeded personas when
a clean demo is wanted. Pre-existing dirty files + `examples/accrue_host/mix.lock` (Docker-boot artifact)
left untouched.
