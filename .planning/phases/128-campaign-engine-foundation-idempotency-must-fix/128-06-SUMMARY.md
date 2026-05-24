---
phase: 128-campaign-engine-foundation-idempotency-must-fix
plan: 06
subsystem: payments
tags: [dunning, oban, webhooks, idempotency, race-safety, ecto, stripe]

# Dependency graph
requires:
  - phase: 128-01
    provides: "Accrue.Config.dunning_campaign_enabled?/0 + dunning_campaign_steps/0 (D-15 gate, day-0 step lookup)"
  - phase: 128-02
    provides: "Subscription.dunning_campaign_started_at column + dunning_campaign_active?/1 + force_status_changeset casting the anchor (clear path)"
  - phase: 128-05
    provides: "Accrue.Workers.DunningStep.enqueue_step/4 (D-16 unique) + per-step cancel-guard backstop"
provides:
  - "D-09 atomic first-transition elector: campaign starts on the REAL webhook path (day-0 DunningStep enqueued via update_all WHERE is_nil(anchor))"
  - "D-12 cancel-on-recovery: in-transaction anchor-clear (durable, atomic with status write) + post-commit Oban.cancel_all_jobs keyed on campaign_started_at"
  - "D-15 REPLACE gate: standalone :invoice_payment_failed email skipped when campaign enabled"
affects: [129-customer-operator-surfaces, 130-provider-honesty-fake-lane, 131-chimeway-engine-adapter]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Atomic set-once elector: update_all WHERE is_nil(col) as a DB-level exactly-one-winner primitive (NOT advisory Oban unique)"
    - "Commit-boundary split: durable in-transaction state write + post-commit side effect (Oban bulk cancel) handed off via tightly-scoped process dict"
    - "REPLACE gate: enabled-feature short-circuits a legacy dispatch instead of running additively"

key-files:
  created:
    - accrue/test/accrue/webhook/dunning_campaign_start_test.exs
    - accrue/test/accrue/webhook/dunning_campaign_keying_test.exs
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs

key-decisions:
  - "Post-commit bulk cancel handed off via a tightly-scoped process-dict stash (set inside the reducer transaction, consumed once at the dispatch site) rather than widening the reducer return arity — keeps {:ok, %Subscription{}} contract intact for existing consumers/tests"
  - "Post-commit cancel only fires on a committed {:ok, %Subscription{}} result; a rolled-back/deferred/stale reducer discards the stash WITHOUT cancelling (the anchor-clear, if it ran, was rolled back with the transaction)"
  - "Cancel-on-recovery error is logged via Logger.warning (NOT telemetry/ledger — that family is Phase 129) so the no-telemetry-increase scope fence holds; the per-step cancel-guard (D-11) backstops any uncancelled step"
  - "maybe_bump_past_due_since/2 refactored to load the sub once and call two siblings (maybe_bump_attempt + maybe_start_dunning_campaign) so the past_due_since bump and the campaign elector share the loaded row without contending changesets"

patterns-established:
  - "DB-level race election: from(s, where: is_nil(col)) |> Repo.update_all(set: ...) returns count==1 for exactly one concurrent winner"
  - "Recovery keyed on campaign_started_at (captured from row BEFORE the clear) so a stale recovery cannot cancel a fresh re-lapse campaign"

# Metrics
duration: ~10min
completed: 2026-05-24
---

# Phase 128 Plan 06: Wire the Dunning Campaign into the Real Webhook Path Summary

Race-safe campaign start (atomic `update_all WHERE is_nil(anchor)`), durable in-transaction cancel-on-recovery with a post-commit `Oban.cancel_all_jobs` keyed on `campaign_started_at`, and a D-15 REPLACE gate that skips the standalone `:invoice_payment_failed` email when the campaign owns day-0 — all driven through the REAL `DefaultHandler` entry point.

## What Was Built

### Task 1 — D-09 first-transition elector + day-0 enqueue + D-15 REPLACE gate (DUN-02) [commit 72714d4]

- Refactored `maybe_bump_past_due_since("payment_failed", canonical)` to load the linked `%Subscription{}` once and dispatch to two siblings:
  - `maybe_bump_attempt/2` — the UNCHANGED `past_due_since` bump from Stripe's `next_payment_attempt`.
  - `maybe_start_dunning_campaign/2` — the new D-09 atomic elector.
- `maybe_start_dunning_campaign/2` runs (gated on `Accrue.Config.dunning_campaign_enabled?/0`) an atomic `from(s in Subscription, where: s.id == ^sub.id and is_nil(s.dunning_campaign_started_at)) |> Repo.update_all(set: [dunning_campaign_started_at: now_usec])`. `count == 1` (won the first nil→past_due edge) enqueues exactly one day-0 `DunningStep` via `Accrue.Workers.DunningStep.enqueue_step/4` carrying `campaign_started_at: DateTime.to_iso8601(now_usec)`; `count == 0` (already running) is a no-op. It is a sibling `update_all` — never touches `lock_version`, so it cannot contend with the status/`past_due_since` changeset path.
- `now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}` (Fake-lane deterministic clock).
- D-15 REPLACE: the `maybe_dispatch_invoice_email("payment_failed", ...)` clause now returns `:ok` (skips the standalone dispatch) when the campaign is enabled, and falls through to `do_dispatch_invoice/3` (deduped by Plan 04) when disabled.
- Integration test drives `invoice.payment_failed` fixtures through the REAL `DefaultHandler.handle/1` (Pitfall 1): first failure sets the anchor + enqueues one day-0 step; a second in-window failure adds no step; D-15 proven both directions (enabled ⇒ no standalone email; disabled ⇒ one standalone email, no campaign step).

### Task 2 — D-12 cancel-on-recovery (in-transaction anchor-clear + post-commit cancel) (DUN-05) [commit f71ae41]

- `maybe_finalize_dunning_campaign/2` (cloning the `maybe_emit_dunning_exhaustion/2` `(row, updated)` signature + `with true <- ...` guard) wired into `reduce_subscription/1`'s `with` chain. When `row` was `dunning_campaign_active?/1` and `updated` is `active?/1`, it captures `iso_anchor = DateTime.to_iso8601(row.dunning_campaign_started_at)` (the anchor value AT recovery, read BEFORE the clear), then nils the anchor via `force_status_changeset(%{dunning_campaign_started_at: nil}) |> Repo.update` INSIDE the enclosing `reduce_row -> Repo.transact` — so the anchor-clear commits atomically with the status write.
- The post-commit bulk cancel is split across the commit boundary: `maybe_finalize_dunning_campaign/2` stashes `{updated.id, iso_anchor}` in a tightly-scoped process-dict key; the dispatch site calls `run_post_commit_dunning_cancel(result)` AFTER `reduce_subscription` returns. It runs `Oban.cancel_all_jobs` keyed on `worker == "Accrue.Workers.DunningStep"` + `subscription_id` + `campaign_started_at` OUTSIDE any transaction, only on a committed `{:ok, %Subscription{}}` (a rolled-back/deferred result discards the stash without cancelling).
- Durability: the bulk cancel is wrapped in `rescue` that `Logger.warning`s and returns `:ok` — a cancel error never rolls back or re-sets the committed anchor; the per-step cancel-guard (D-11) backstops any uncancelled step.
- Keying integration test: (1) concurrent `update_all` exactly-one-winner race via `Task.async_stream` + shared sandbox; (2) already-running no-op; (3) cancel-on-recovery nils the anchor + cancels scheduled steps (state `cancelled`); (4) stale-recovery isolation (a cancel keyed to an old campaign leaves a fresh campaign's steps live); (5) anchor-clear durability with no jobs to cancel + a non-recovery transition.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale standalone-dispatch test for the D-15 REPLACE gate**
- **Found during:** Task 1 (surfaced when running the full webhook suite after the D-15 gate landed)
- **Issue:** `default_handler_mailer_dispatch_test.exs:375` asserted `invoice.payment_failed` always dispatches the standalone `:invoice_payment_failed` email. With the campaign enabled by default (test-env default), that email is now correctly REPLACED by campaign step-1, so the pre-existing assertion was stale. The failure was DIRECTLY caused by this plan's D-15 gate (in scope).
- **Fix:** Scoped the test to the campaign-disabled condition (per-test `Application.put_env` + `on_exit` restore) so it continues to exercise the standalone-dispatch wiring it was written for, with a doc note explaining the D-15 REPLACE semantics. Renamed the test to "...when the campaign is disabled".
- **Files modified:** accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs
- **Commit:** f71ae41

## Authentication Gates

None.

## Verification

- `mix test test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` — 4 tests, 0 failures (Task 1 gate).
- `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` — 6 tests, 0 failures (Task 2 gate).
- `mix compile --warnings-as-errors` — exits 0.
- `mix test test/accrue/webhook/` — 115 tests, 0 failures (no regression).
- `mix test test/accrue/workers/ test/accrue/config_dunning_campaign_test.exs test/property/dunning_campaign_property_test.exs` — 6 properties, 80 tests, 0 failures (adjacent dunning plans unaffected).

### Acceptance grep proofs

- `is_nil(s.dunning_campaign_started_at)` present (the atomic elector).
- `Repo.update_all` sibling elector present; start path does NOT call `force_status_changeset`/`optimistic_lock`.
- `dunning_campaign_enabled?` present (start gate + D-15 gate).
- `Accrue.Clock.utc_now` count = 4 (≥1); no new `DateTime.utc_now` in the elector (the only one, in `dunning_source/1`, is pre-existing).
- `maybe_finalize_dunning_campaign` def + wired into `reduce_subscription` (grep count = 3).
- `Oban.cancel_all_jobs` at the post-commit site (`cancel_dunning_steps/2`), NOT inside `reduce_row`'s `Repo.transact`.
- Cancel query matches on `campaign_started_at`; `iso_anchor` captured from `row` before nilling.
- `:telemetry`/`Accrue.Events` count unchanged at 18 (no Phase-129 emission added).

## Scope Fence Honored

No ledger events, no telemetry, no `dunning.recovered` emission, no `Accrue.Dunning.Engine` behaviour — all deferred to Phases 129/131. The cancel-failure path uses `Logger.warning`, not telemetry, to keep the `:telemetry`/`Accrue.Events` count flat.

## Known Stubs

None. The `[]`/`:ok`/`nil` returns in the new code are correct domain no-op paths (campaign disabled, count==0 already-running, no day-0 step configured), not unwired placeholders.

## Self-Check: PASSED

- All created/modified files exist on disk (verified).
- Both per-task commits exist in git history (72714d4, f71ae41).
