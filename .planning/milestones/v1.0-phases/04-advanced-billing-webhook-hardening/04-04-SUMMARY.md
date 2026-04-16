---
phase: 04-advanced-billing-webhook-hardening
plan: 04
subsystem: billing-dunning
tags: [wave-4, dunning, bill-15, d4-02, grace-period, hybrid]
dependency_graph:
  requires:
    - "04-01 (Accrue.Config :dunning key; accrue_subscriptions.past_due_since + dunning_sweep_attempted_at columns)"
    - "04-03 (Subscription.force_status_changeset/2 webhook path)"
  provides:
    - "Accrue.Billing.Dunning.compute_terminal_action/2 + grace_elapsed?/3 (pure policy)"
    - "Accrue.Billing.Subscription.dunning_sweepable?/1 predicate (strictly :past_due)"
    - "Accrue.Billing.Subscription.dunning_exhausted_status/1 predicate (:unpaid | :canceled | nil)"
    - "Accrue.Billing.Query.dunning_sweep_candidates/2 (grace_days-parameterized)"
    - "Accrue.Jobs.DunningSweeper Oban cron (queue :accrue_dunning, max_attempts: 3)"
    - "Accrue.Webhook.DefaultHandler invoice.payment_failed past_due_since bump"
    - "[:accrue, :ops, :dunning_exhaustion] telemetry on webhook-echoed terminal transitions"
    - "dunning.terminal_action_requested accrue_events row stamped by the sweeper"
  affects:
    - "Plans 04-05..04-08 — sweeper/webhook are decoupled from downstream work"
tech_stack:
  added: []
  patterns:
    - "Pure policy module + thin I/O worker split (Dunning vs DunningSweeper)"
    - "D2-29 canonicality — worker calls Stripe only, never flips local status"
    - "Post-Stripe stamping — dunning_sweep_attempted_at stamped ONLY after successful processor call"
    - "Grace-window cutoff via Accrue.Clock.utc_now (Fake-clock aware in tests)"
    - "Webhook status-diff telemetry emitted inside enclosing Repo.transact for replay idempotency"
    - "Dedicated BILL-05 predicates (dunning_sweepable?, dunning_exhausted_status) instead of raw .status access"
key_files:
  created:
    - "accrue/lib/accrue/billing/dunning.ex"
    - "accrue/lib/accrue/jobs/dunning_sweeper.ex"
    - "accrue/test/accrue/billing/dunning_test.exs"
    - "accrue/test/accrue/jobs/dunning_sweeper_test.exs"
    - "accrue/test/accrue/webhook/dunning_exhaustion_test.exs"
  modified:
    - "accrue/lib/accrue/billing/subscription.ex"
    - "accrue/lib/accrue/billing/query.ex"
    - "accrue/lib/accrue/webhook/default_handler.ex"
decisions:
  - "Sweeper calls the existing Processor.update_subscription/3 callback rather than adding a new subscription_update/3 callback. Plan 04-03 already confirmed update_subscription/3 is the canonical Phase 3 name; the plan text's `subscription_update` reference was a naming carryover."
  - "Added Subscription.dunning_sweepable?/1 (strictly :past_due) and dunning_exhausted_status/1 (:unpaid | :canceled | nil) predicates instead of raw status comparisons. BILL-05 + Accrue.Credo.NoRawStatusAccess forbids raw .status access outside Subscription/Query. The :past_due?/1 predicate was not a fit because it also matches :unpaid — the sweeper must NOT re-sweep rows already flipped to :unpaid."
  - "dunning_sweep_attempted_at is assigned with a {0, 6} microsecond tuple via `%{Clock.utc_now() | microsecond: {0, 6}}` because Fake clock returns `~U[2026-01-01 00:00:00Z]` without usec precision, and the column type is :utc_datetime_usec. Ecto's dump_utc_datetime_usec/1 rejects DateTimes without explicit usec."
  - "Sweeper test pins :accrue :dunning via Application.put_env in setup/on_exit because Accrue.ConfigTest deletes the key in its own async: false setup and the global env is not owned by either test module."
  - "invoice.payment_failed bumps past_due_since via a direct Repo.get_by + force_status_changeset update INSIDE the enclosing reducer transact — not a separate transact. This keeps the bump atomic with the invoice projection write."
  - "Dunning-exhaustion telemetry uses a `with` chain guarded by the two new Subscription predicates, so the default_handler module stays free of raw status atoms and passes Accrue.Credo.NoRawStatusAccess unchanged."
metrics:
  duration: "~35m"
  tasks_completed: 3
  files_created: 5
  files_modified: 3
  commits: 4
  completed_date: "2026-04-14"
requirements: [BILL-15]
---

# Phase 4 Plan 04: BILL-15 Dunning (D4-02 Hybrid) Summary

Ships BILL-15 dunning as the D4-02 hybrid strategy: Stripe Smart Retries keeps owning the retry cadence, Accrue lays a thin grace-period overlay on top. Three surfaces land together — a pure policy module, an Oban cron that asks Stripe to terminal past_due subs once the grace window elapses, and webhook-driven telemetry that fires on the Stripe-echoed terminal transition. Local subscription status is never touched by the sweeper (D2-29); Stripe remains canonical.

## Objective Achieved

A Phoenix developer running Accrue with the default `:dunning` policy (`grace_days: 14`, `terminal_action: :unpaid`) now gets revenue-recovery visibility without dashboard lock-in:

- `Accrue.Billing.report_usage`-adjacent operators can observe dunning exhaustion via the new `[:accrue, :ops, :dunning_exhaustion]` telemetry event and wire it to their metrics reporter / alerting.
- The Oban cron `Accrue.Jobs.DunningSweeper` scans for `:past_due` rows past the grace window and asks Stripe to move them to `:unpaid` (or `:canceled`, per policy) via `Processor.update_subscription/3`.
- `invoice.payment_failed` webhooks automatically bump the linked subscription's `past_due_since` from Stripe's `next_payment_attempt`, so the grace window always reflects Stripe's latest retry schedule.
- When Stripe finally echoes the terminal transition via `customer.subscription.updated`, the default handler emits `dunning_exhaustion` telemetry tagged with `source: :accrue_sweeper` (if a recent sweep was attempted) or `source: :stripe_native` (if Stripe terminated on its own).

## Tasks Completed

| # | Task | Commits | Key Files |
|---|------|---------|-----------|
| 1 | Accrue.Billing.Dunning pure policy module + Subscription.dunning_sweepable?/1 predicate + 9 tests (2 properties) | `50417ae` (RED), `7c4377a` (GREEN) | `billing/dunning.ex`, `billing/subscription.ex`, `test/.../dunning_test.exs` |
| 2 | Accrue.Jobs.DunningSweeper Oban cron + Query.dunning_sweep_candidates/2 + 7 tests | `e7fe926` | `jobs/dunning_sweeper.ex`, `billing/query.ex`, `test/.../dunning_sweeper_test.exs` |
| 3 | DefaultHandler invoice.payment_failed past_due_since bump + dunning_exhaustion telemetry + Subscription.dunning_exhausted_status/1 + 7 tests | `decbf5e` | `webhook/default_handler.ex`, `billing/subscription.ex`, `test/.../dunning_exhaustion_test.exs` |

## Key Decisions Made

1. **Existing `update_subscription/3` callback, not a new `subscription_update/3`.** The plan's `key_links` named `subscription_update`, but Plan 04-03's SUMMARY already called out that the canonical Phase 3 callback is `update_subscription/3`. Adding a second callback with the same shape would have duplicated surface and forced two Fake/Stripe implementations. The sweeper calls `Processor.__impl__().update_subscription(sub.processor_id, %{status: "unpaid"}, [])` directly.

2. **Two new Subscription predicates instead of raw status comparisons.** The existing `past_due?/1` predicate matches both `:past_due` AND `:unpaid` — fine for entitlement gates, wrong for the sweeper, which must NOT re-flip a row that's already terminal. Added `dunning_sweepable?/1` (strictly `:past_due`) and `dunning_exhausted_status/1` (returns `:unpaid | :canceled | nil`). These are required because `Accrue.Credo.NoRawStatusAccess` (BILL-05) forbids raw `.status` access outside `Accrue.Billing.Subscription` / `Accrue.Billing.Query`. The sweeper code path, the webhook handler, and `Accrue.Billing.Dunning` all gate on these predicates now.

3. **Microsecond-precision stamping via explicit tuple.** The Fake clock's epoch is `~U[2026-01-01 00:00:00Z]` — no microseconds. Ecto's `:utc_datetime_usec` type rejects `%DateTime{microsecond: {0, 0}}`. The sweeper now builds the stamp with `%{Accrue.Clock.utc_now() | microsecond: {0, 6}}` so both the Fake-clocked test path and any production path that already carries usec work uniformly.

4. **DunningSweeperTest pins `:dunning` config in setup.** `Accrue.ConfigTest` (async: false) has a `describe "Phase 4 config — dunning defaults"` block whose setup calls `Application.delete_env(:accrue, :dunning)` and never restores it. Test execution order is non-deterministic, so the sweeper test module pins the policy in its own setup and restores on exit. The pin is scoped via `on_exit` so no other test module sees the override.

5. **`past_due_since` bump lives inside `reduce_invoice`'s existing transact.** Plan 04-04 suggested a helper `update_subscription_past_due_since/2` that would run inside a separate transact block. Keeping the bump inside `reduce_invoice`'s `reduce_row` closure is atomic with the invoice projection write and avoids a second round-trip. The helper name in the file is `maybe_bump_past_due_since/2` so it reads clearly at the call site.

6. **Telemetry emitted inside `reduce_subscription`'s `reduce_row` closure.** The plan required "inside the same Repo.transact as the state write." The `maybe_emit_dunning_exhaustion/2` call is now threaded into the existing `with`-chain between `upsert_subscription_items/2` and `record_event/4`. Because the dispatch layer (D3-49 + WH-09 stale gate) short-circuits replays before the reducer body runs, the telemetry is idempotent under replay without any additional dedup.

7. **Strictly-positive `grace_days` guard clause on `Query.dunning_sweep_candidates/2`.** The function accepts `grace_days` as a runtime arg rather than reading `Config.dunning()` internally, so the sweeper can thread whatever policy it sees. NimbleOptions schema validation at boot rejects a zero grace_days anyway (T-04-04-05), but the guard clause adds belt-and-suspenders and keeps Dialyzer happy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Raw `.status` access trips `Accrue.Credo.NoRawStatusAccess` (BILL-05)**

- **Found during:** Task 1 credo verify step
- **Issue:** The initial `Accrue.Billing.Dunning.compute_terminal_action/2` used `sub.status != :past_due` as a skip guard. The project's custom Credo rule `Accrue.Credo.NoRawStatusAccess` flags any `.status` comparison outside `Accrue.Billing.Subscription` and `Accrue.Billing.Query`.
- **Fix:** Added `Accrue.Billing.Subscription.dunning_sweepable?/1` predicate (strictly `:past_due`, excluding `:unpaid`) and rewrote the `cond` branch to gate on `not Subscription.dunning_sweepable?(sub)`. Same fix applied in Task 3 for the webhook `:past_due → :unpaid|:canceled` check, which grew a second predicate `dunning_exhausted_status/1`.
- **Files modified:** `accrue/lib/accrue/billing/dunning.ex`, `accrue/lib/accrue/billing/subscription.ex`, `accrue/lib/accrue/webhook/default_handler.ex`
- **Commits:** `7c4377a` (Dunning), `decbf5e` (webhook)

**2. [Rule 1 - Bug] Ecto `:utc_datetime_usec` rejects Fake epoch without microseconds**

- **Found during:** Task 2 happy-path test
- **Issue:** `Accrue.Clock.utc_now()` under `:test` env returns the Fake clock (`State.@epoch = ~U[2026-01-01 00:00:00Z]`). The `accrue_subscriptions.dunning_sweep_attempted_at` column is `:utc_datetime_usec`. Ecto's `Ecto.Type.dump_utc_datetime_usec/1` raises `ArgumentError: :utc_datetime_usec expects microsecond precision`.
- **Fix:** Stamp via `%{Accrue.Clock.utc_now() | microsecond: {0, 6}}` to force `{0, 6}` precision. Same idiom used for `past_due_since` bumps in the webhook path.
- **Commits:** `e7fe926`, `decbf5e`

**3. [Rule 1 - Bug] Fake clock offset silently masked grace-window tests**

- **Found during:** Task 2 isolated test run (`mix test --seed 0`)
- **Issue:** The sweeper test's initial `past_due_since` value was computed as `DateTime.utc_now() - 30 days`, but `Query.dunning_sweep_candidates/2` uses `Accrue.Clock.utc_now()` for its cutoff — which under `:test` env returns the Fake clock's `~U[2026-01-01 ...]`, not real wall clock. Real-time `past_due_since` was 3+ months AFTER the Fake-clock cutoff, so the sub was never a candidate.
- **Fix:** Changed all `past_due_since` / `dunning_sweep_attempted_at` fixture computations in the sweeper test to use `Accrue.Clock.utc_now()` so the test aligns with the Fake clock.
- **Commit:** `e7fe926`

**4. [Rule 3 - Blocking] ConfigTest leaks `:dunning` app env across async: false modules**

- **Found during:** Task 2 full-suite test run
- **Issue:** `Accrue.ConfigTest` (`async: false`) has a describe block whose setup deletes `:accrue, :dunning` and never restores it. Test module execution order is non-deterministic, so when DunningSweeperTest ran after that block, `Config.dunning()` returned the schema default — but if ConfigTest's async: true variant had ALSO put a temporary override that bled into shared env, `Config.dunning()` returned a stale policy with the wrong `grace_days`.
- **Fix:** DunningSweeperTest's `setup` now pins `:accrue, :dunning` to a known policy via `Application.put_env/3` and restores it on `on_exit`. No modifications to ConfigTest — the pin is scoped to this module.
- **Commit:** `e7fe926`

**5. [Rule 3 - Naming] Plan `subscription_update` vs actual `update_subscription`**

- **Found during:** Task 2 sweeper module action step
- **Issue:** Plan's `key_links` said `Processor.__impl__().subscription_update/3`. The actual Phase 3 callback is `update_subscription/3` (verb-first, Phase 3 Plan 07 convention). Plan 04-03's summary already flagged this as a carryover naming issue.
- **Fix:** Call `Processor.__impl__().update_subscription(sub.processor_id, %{status: Atom.to_string(terminal_action)}, [])`. No new callback added.
- **Commit:** `e7fe926`

**6. [Rule 1 - Test seed collision] `seed_sub/2` helper originally created two Fake subscriptions**

- **Found during:** Task 2 happy-path test
- **Issue:** The initial `seed_sub/2` called `Fake.create_subscription` twice (leftover from iteration) and `Map.merge`'d processor_id in the wrong key order, so the local `accrue_subscriptions` row pointed at a processor_id the Fake did not know about. `Processor.update_subscription/3` then returned `resource_missing`.
- **Fix:** Rewrote `seed_sub/2` to call `Fake.create_subscription` exactly once and mirror the returned `fake_sub.id` into the local row's `processor_id`.
- **Commit:** `e7fe926`

## Authentication Gates

None. Entire plan runs against the Fake processor; no real Stripe credentials required.

## Verification Results

### Automated

```
$ cd accrue && mix compile --warnings-as-errors
Generated accrue app

$ cd accrue && mix test test/accrue/billing/dunning_test.exs
2 properties, 9 tests, 0 failures

$ cd accrue && mix test test/accrue/jobs/dunning_sweeper_test.exs
7 tests, 0 failures

$ cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs
7 tests, 0 failures

$ cd accrue && mix test
36 properties, 463 tests, 0 failures (2 excluded :live_stripe)

$ cd accrue && mix credo --strict
1226 mods/funs, found no issues.
```

### Manual checks

- `Accrue.Billing.Dunning.compute_terminal_action(%Subscription{status: :past_due, past_due_since: 30 days ago}, Config.dunning())` returns `{:sweep, :unpaid}` with default policy.
- `Accrue.Jobs.DunningSweeper.sweep/0` on an empty DB returns `{:ok, 0}`; on a seeded past_due sub with 30-day-old `past_due_since` it returns `{:ok, 1}`, stamps `dunning_sweep_attempted_at`, writes a `dunning.terminal_action_requested` event row, and leaves local `subscription.status` at `:past_due` (Stripe/webhook is canonical).
- `Accrue.Webhook.DefaultHandler.handle/1` with an `invoice.payment_failed` event carrying `next_payment_attempt: <future unix>` writes `past_due_since` on the linked subscription. The same event with `next_payment_attempt: nil` preserves any prior `past_due_since`.
- `customer.subscription.updated` with a `:past_due → :unpaid` transition emits `[:accrue, :ops, :dunning_exhaustion]` telemetry with `source: :accrue_sweeper` when `dunning_sweep_attempted_at` is within 5 minutes; emits with `source: :stripe_native` when `sweep_attempted_at` is nil or older than 5 minutes.
- An `:active → :canceled` transition (non-dunning) does NOT emit `dunning_exhaustion`.
- Facade lockdown check (`Accrue.Processor.StripeTest`) still passes — `LatticeStripe` references remain confined to the 5-file allowlist.

## Requirements Marked Complete

- **BILL-15** — Dunning grace-period overlay (D4-02 hybrid): pure policy module, Oban sweeper, webhook telemetry, past_due_since tracking.

## Known Stubs

None. Every function is fully wired end-to-end against the Fake. The Stripe adapter's existing `update_subscription/3` callback is reused without modification — lattice_stripe 1.1's `Subscription.update/3` already accepts a `status` param on the server side.

## Threat Flags

None beyond the plan's STRIDE register. Every T-04-04-{01..06} threat is mitigated as planned:

- T-04-04-01 (sweeper flipping local status) — verified: `dunning_sweeper.ex` does NOT reference `force_status_changeset`; only changes `dunning_sweep_attempted_at` via `Ecto.Changeset.change/2`. Acceptance criterion grep confirmed.
- T-04-04-02 (double-fire telemetry on replay) — telemetry fires inside the same `Repo.transact` as the upsert, and the dispatch layer deduplicates replays via `accrue_webhook_events.stripe_event_id` unique index before the reducer body runs.
- T-04-04-03 (PII in telemetry metadata) — metadata contains only `subscription_id`, `from_status`, `to_status`, `source`. No email / customer / card info.
- T-04-04-04 (sweeper infinite-retry loop) — sweep failure path leaves `dunning_sweep_attempted_at` unset and returns `false`, so the next cron tick retries. `max_attempts: 3` on the worker bounds per-tick retries.
- T-04-04-05 (malicious `:terminal_action` config) — NimbleOptions schema validation at boot constrains `terminal_action: :unpaid | :canceled` (Plan 04-01 `@schema` entry).
- T-04-04-06 (customer cancellation without notification) — accepted; Phase 6 MAIL-10 `subscription_canceled` covers this.

## Self-Check

- `accrue/lib/accrue/billing/dunning.ex` — FOUND, contains `def compute_terminal_action`, `def grace_elapsed?`, no `Repo`/`Processor`/`Events`/`:telemetry` references
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` — FOUND, contains `queue: :accrue_dunning`, `update_subscription`, `dunning.terminal_action_requested`, does NOT contain `force_status_changeset`
- `accrue/lib/accrue/billing/query.ex` — FOUND, contains `def dunning_sweep_candidates`
- `accrue/lib/accrue/billing/subscription.ex` — FOUND, contains `def dunning_sweepable?`, `def dunning_exhausted_status`
- `accrue/lib/accrue/webhook/default_handler.ex` — FOUND, contains `[:accrue, :ops, :dunning_exhaustion]`, `dunning_source`, `maybe_bump_past_due_since`, `next_payment_attempt`
- `accrue/test/accrue/billing/dunning_test.exs` — FOUND, 9 tests + 2 properties
- `accrue/test/accrue/jobs/dunning_sweeper_test.exs` — FOUND, 7 tests
- `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` — FOUND, 7 tests
- Commit `50417ae` (RED) — FOUND
- Commit `7c4377a` (Dunning GREEN) — FOUND
- Commit `e7fe926` (Sweeper) — FOUND
- Commit `decbf5e` (Webhook) — FOUND

## Self-Check: PASSED
