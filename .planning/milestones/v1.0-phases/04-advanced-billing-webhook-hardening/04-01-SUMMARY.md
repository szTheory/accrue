---
phase: 04-advanced-billing-webhook-hardening
plan: 01
subsystem: billing-webhooks-config-schema
tags: [wave-0, foundation, dep-bump, config, migrations]
dependency_graph:
  requires: []
  provides:
    - "lattice_stripe ~> 1.1 resolved from Hex (Billing.Meter, Billing.MeterEvent, Billing.MeterEventAdjustment, BillingPortal.Session)"
    - "Accrue.Config keys: :dunning, :webhook_endpoints, :dlq_replay_batch_size, :dlq_replay_stagger_ms, :dlq_replay_max_rows"
    - "Accrue.Config helpers: dunning/0, webhook_endpoints/0, dlq_replay_batch_size/0, dlq_replay_stagger_ms/0, dlq_replay_max_rows/0"
    - "accrue_meter_events table (D4-03 audit/outbox)"
    - "accrue_subscription_schedules table (BILL-16 projection)"
    - "accrue_promotion_codes table (BILL-27 projection)"
    - "accrue_subscriptions columns: past_due_since, dunning_sweep_attempted_at, paused_at, pause_behavior, discount_id"
    - "accrue_invoices column: total_discount_amounts"
    - "accrue_events_type_inserted_at_idx composite index"
    - "accrue_subscriptions_past_due_since_idx partial index"
    - "accrue_meter_events_failed_idx partial index (free DLQ view)"
  affects:
    - "plans 04-02..04-08 (all depend on this wave-0 surface)"
tech_stack:
  added:
    - "lattice_stripe 1.1.0 (upgraded from 1.0.0)"
  patterns:
    - "NimbleOptions schema extension (D4-02/D4-04 config keys)"
    - "binary_id PK with gen_random_uuid() default (Phase 3 convention)"
    - "processor_id naming (not stripe_id) for projection tables"
    - "partial indexes on common-filter predicates (failed, past_due_since IS NOT NULL)"
key_files:
  created:
    - "accrue/priv/repo/migrations/20260414130000_create_accrue_meter_events.exs"
    - "accrue/priv/repo/migrations/20260414130100_create_accrue_subscription_schedules.exs"
    - "accrue/priv/repo/migrations/20260414130200_create_accrue_promotion_codes.exs"
    - "accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs"
    - "accrue/priv/repo/migrations/20260414130400_add_discount_columns_to_invoices.exs"
    - "accrue/priv/repo/migrations/20260414130500_add_events_type_inserted_at_index.exs"
  modified:
    - "accrue/mix.exs"
    - "accrue/mix.lock"
    - "accrue/lib/accrue/config.ex"
    - "accrue/test/accrue/config_test.exs"
decisions:
  - "Use Hex-published lattice_stripe 1.1.0 directly — no path: dep. D4-01 originally proposed path-dep transitional, but 1.1.0 was already published on Hex (2026-04-14)."
  - "Phase 4 migration timestamps shifted from 20260414120xxx → 20260414130xxx because 20260414120000 was already claimed by Phase 3 schema upgrades migration."
  - "discount_minor column on accrue_invoices already existed from Phase 3; new migration adds only total_discount_amounts (avoiding duplicate-add failure)."
  - "Removed LatticeStripe module reference from config.ex :dunning @schema doc string to pass Accrue.Processor.StripeTest facade-lockdown check (only Processor.Stripe + Webhook files may name LatticeStripe.*)."
  - "Added Phase 4 convenience accessors (Config.dunning/0 etc) following the existing pattern of stripe_api_version/0, succeeded_retention_days/0, etc."
metrics:
  duration: "22m"
  tasks_completed: 3
  files_created: 6
  files_modified: 4
  commits: 3
  completed_date: "2026-04-14"
---

# Phase 4 Plan 01: Wave 0 Foundation Summary

Landed the Phase 4 foundation in a single plan: bumped `lattice_stripe` from `~> 1.0` to `~> 1.1` (resolving to the newly-published 1.1.0 from Hex), extended `Accrue.Config` with five new NimbleOptions keys for dunning + DLQ machinery, and shipped six schema/alter migrations covering metered billing, subscription schedules, promotion codes, dunning/pause columns, invoice discount breakdown, and the EVT-06 events composite index.

## Objective Achieved

Zero behavior changes. Pure surface-area plan that unblocks every downstream Phase 4 plan. Every `LatticeStripe.Billing.Meter*`, `LatticeStripe.BillingPortal.Session`, and `:dunning`/`:dlq_replay_*` config key that plans 04-02..04-08 need is now available.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Bump lattice_stripe ~> 1.0 → ~> 1.1 | `e9399d3` | accrue/mix.exs, accrue/mix.lock |
| 2 | Extend Accrue.Config with 5 new NimbleOptions keys + helpers + tests | `adc5fcb` | accrue/lib/accrue/config.ex, accrue/test/accrue/config_test.exs |
| 3 | Ship 6 Phase 4 migrations (meter events, subscription schedules, promotion codes, dunning/pause alters, invoice discounts, events index) | `fbba906` | accrue/priv/repo/migrations/20260414130*.exs, accrue/lib/accrue/config.ex (facade lockdown fix) |

## Key Decisions Made

1. **Hex-direct lattice_stripe dep** — D4-01 originally prescribed `path: "../lattice_stripe"` as a transitional dep during Phase 4 dev. That's now obsolete because `lattice_stripe 1.1.0` was published to Hex on 2026-04-14. Consume directly; no path hack; `mix.lock` records the checksum for supply-chain integrity (T-04-01-01).

2. **Migration timestamp shift 120xxx → 130xxx** — Phase 3's `20260414120000_phase3_schema_upgrades.exs` had already claimed the 120xxx slot. Shifted Phase 4 migrations to `20260414130000`..`20260414130500` with the same logical ordering the plan specified.

3. **`discount_minor` already exists** — Phase 3's rollup migration added `discount_minor` (bigint) to `accrue_invoices`. The Phase 4 migration adds only the new `total_discount_amounts` (jsonb) column — Stripe's per-discount line-item breakdown. BILL-28 surface is complete once this is combined with the pre-existing `discount_minor`.

4. **Facade-lockdown fix in :dunning doc string** — The plan's schema comment for `:dunning` referenced `LatticeStripe.Subscription.update(id, status: terminal_action)` verbatim. That string matched the `\bLatticeStripe\b` regex in `Accrue.Processor.StripeTest` (which scans `lib/accrue/**/*.ex` and asserts only 5 allowlisted files may reference the sibling module). Rewrote the doc to describe the behavior without naming the facade sidestep — "asks the processor facade to move the subscription to the terminal action."

5. **Added Phase 4 convenience accessors** — Followed the existing `Config.stripe_api_version/0` / `Config.succeeded_retention_days/0` pattern and shipped `Config.dunning/0`, `Config.webhook_endpoints/0`, `Config.dlq_replay_batch_size/0`, `Config.dlq_replay_stagger_ms/0`, `Config.dlq_replay_max_rows/0`. Plans 04-02..04-08 can call these directly without threading `get!/1` through every call site.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Migration timestamp collision with Phase 3**

- **Found during:** Task 3
- **Issue:** Plan specified `20260414120000..120500` timestamps, but `20260414120000_phase3_schema_upgrades.exs` was committed in Phase 3. Ecto would have rejected the duplicate.
- **Fix:** Shifted all six migration filenames and module timestamp slugs to `20260414130000..130500`. Logical ordering preserved. Updated the rollback verification command reference internally.
- **Files modified:** all six new migration files
- **Commit:** `fbba906`

**2. [Rule 3 - Blocking] `discount_minor` column already exists on accrue_invoices**

- **Found during:** Task 3
- **Issue:** Plan said to add `discount_minor` + `total_discount_amounts` to `accrue_invoices`. Phase 3's rollup migration (D3-14) already added `discount_minor :bigint`. Adding it again would have raised `ALTER TABLE ... ADD COLUMN "discount_minor" already exists`.
- **Fix:** `20260414130400_add_discount_columns_to_invoices.exs` now adds only `total_discount_amounts :map, null: false, default: %{}`. Documented the deviation in the migration's `@moduledoc`.
- **Commit:** `fbba906`

**3. [Rule 1 - Bug] Facade-lockdown regression from :dunning @schema doc**

- **Found during:** Task 3 verify step (`mix test` showed 1 failure)
- **Issue:** `Accrue.ConfigTest` initially passed but `Accrue.Processor.StripeTest` ("LatticeStripe module references only appear inside Accrue.Processor.Stripe.* files") failed because the new `:dunning` schema entry's `doc:` string included the literal substring `LatticeStripe.Subscription.update`, and the lockdown test scans all of `lib/accrue/**/*.ex` for `\bLatticeStripe\b`.
- **Fix:** Rewrote the doc string to describe the dunning terminal-action flow without naming the sibling module directly: "asks the processor facade to move the subscription to the terminal action."
- **Files modified:** `accrue/lib/accrue/config.ex` (doc string only, schema structure unchanged)
- **Commit:** `fbba906` (bundled with Task 3 migration commit since the test failure surfaced during that task's verify step)

**4. [Rule 1 - Naming] Plan used `Config.fetch!/1` but actual API is `get!/1`**

- **Found during:** Task 2 action step
- **Issue:** Plan's `must_haves.truths` said `Accrue.Config.fetch!(:dunning)`. Existing Config module uses `get!/1` (not `fetch!/1`). Consistency matters more than the plan's terminology.
- **Fix:** Used `get!/1` throughout tests + helpers. Semantic meaning is preserved — raises `Accrue.ConfigError` on unknown keys.
- **Commit:** `adc5fcb`

**5. [Rule 3 - No-op] Plan listed `dead_retention_days` and `succeeded_retention_days` as new keys, but both already exist from Phase 2**

- **Found during:** Task 2 (initial read of config.ex)
- **Issue:** Plan's `@schema` extension listed seven keys; two (`dead_retention_days`, `succeeded_retention_days`) were already present from Phase 2's webhook retention work.
- **Fix:** Added only the five genuinely-new keys: `:dunning`, `:webhook_endpoints`, `:dlq_replay_batch_size`, `:dlq_replay_stagger_ms`, `:dlq_replay_max_rows`. Config tests still assert the Phase 2 retention defaults to verify they survive Phase 4 additions.
- **Commit:** `adc5fcb`

## Authentication Gates

None. Entire plan was library-local: dep bump + config schema extension + migration files. No external services contacted.

## Verification Results

### Automated

```
$ cd accrue && mix deps.get
  Upgraded: lattice_stripe 1.0.0 => 1.1.0 (from Hex.pm)

$ cd accrue && mix compile --warnings-as-errors
==> lattice_stripe  (Compiling 94 files .ex — Generated lattice_stripe app)
==> accrue          (Compiling 4 files .ex — Generated accrue app)

$ cd accrue && mix credo --strict lib/accrue/config.ex
21 mods/funs, found no issues.

$ cd accrue && mix test test/accrue/config_test.exs
28 tests, 0 failures  (12 new Phase 4 tests added in Task 2)

$ cd accrue && MIX_ENV=test mix ecto.drop && mix ecto.create && mix ecto.migrate
All migrations applied forward, including 20260414130000..130500.

$ cd accrue && MIX_ENV=test mix ecto.rollback --to 20260414130000
Rolled back 20260414130500 → 130000 (six migrations).

$ cd accrue && MIX_ENV=test mix ecto.migrate
Re-applied all six Phase 4 migrations cleanly.

$ cd accrue && mix test
34 properties, 395 tests, 0 failures  (2 excluded :live_stripe)
```

### Manual DB inspection (psql against accrue_test)

- `\d accrue_meter_events` — 13 columns (id uuid, customer_id uuid FK nilify, stripe_customer_id varchar not null, event_name varchar not null, value bigint not null, identifier varchar not null, occurred_at ts not null, reported_at ts, stripe_status varchar not null default 'pending', stripe_error jsonb, operation_id varchar, inserted_at, updated_at). Indexes: pkey, `accrue_meter_events_customer_event_occurred_idx`, `accrue_meter_events_failed_idx` (partial on `stripe_status = 'failed'`), `accrue_meter_events_identifier_index` (unique).
- `\d accrue_subscriptions` — confirmed all five new columns present: `past_due_since`, `dunning_sweep_attempted_at`, `paused_at`, `pause_behavior`, `discount_id`; partial index `accrue_subscriptions_past_due_since_idx` on `past_due_since IS NOT NULL`.
- `\d accrue_invoices` — `discount_minor` (bigint, pre-existing from Phase 3) and `total_discount_amounts` (jsonb, not null, default `'{}'::jsonb`) both present.
- `\d accrue_events` + `pg_indexes` — composite `accrue_events_type_inserted_at_idx` on `(type, inserted_at)` present.

## Requirements Marked Complete (Wave 0 — surface only)

This plan lands schema + config surface only. Full requirement completion happens in 04-02..04-08 which implement the logic on top of this surface. The frontmatter's `requirements:` list is reserved for this plan's direct contributions; the rest of Phase 4 will complete them as logic lands.

Per the plan frontmatter, this plan's Wave 0 foundation provides surface area for: BILL-11, BILL-13, BILL-15, BILL-16, BILL-27, BILL-28, EVT-06, WH-08, WH-13.

## Known Stubs

None. Every column, index, and config key added is fully functional. Downstream plans will READ/WRITE these columns and ADD logic modules — none of this surface is placeholder.

## Threat Flags

None. Every file touched is covered by the plan's existing STRIDE register (T-04-01-01..05). The `mix.lock` update records the Hex checksum (T-04-01-01 mitigated). The `stripe_error :map` column is schema-only — actual projection logic lives in plan 04-02 and will enforce the "no raw Stripe payload" rule (T-04-01-02).

## Self-Check

- `accrue/mix.exs` — FOUND, contains `{:lattice_stripe, "~> 1.1"}`
- `accrue/mix.lock` — FOUND, updated to lattice_stripe 1.1.0
- `accrue/lib/accrue/config.ex` — FOUND, contains `dunning:`, `webhook_endpoints:`, `dlq_replay_max_rows:`, `grace_days: 14`, `default: 10_000`
- `accrue/test/accrue/config_test.exs` — FOUND, 12 new Phase 4 tests added
- `accrue/priv/repo/migrations/20260414130000_create_accrue_meter_events.exs` — FOUND
- `accrue/priv/repo/migrations/20260414130100_create_accrue_subscription_schedules.exs` — FOUND
- `accrue/priv/repo/migrations/20260414130200_create_accrue_promotion_codes.exs` — FOUND
- `accrue/priv/repo/migrations/20260414130300_add_dunning_and_pause_columns_to_subscriptions.exs` — FOUND
- `accrue/priv/repo/migrations/20260414130400_add_discount_columns_to_invoices.exs` — FOUND
- `accrue/priv/repo/migrations/20260414130500_add_events_type_inserted_at_index.exs` — FOUND
- Commit `e9399d3` — FOUND
- Commit `adc5fcb` — FOUND
- Commit `fbba906` — FOUND

## Self-Check: PASSED
