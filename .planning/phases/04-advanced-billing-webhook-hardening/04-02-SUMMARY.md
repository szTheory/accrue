---
phase: 04-advanced-billing-webhook-hardening
plan: 02
subsystem: billing-metered-outbox-webhook
tags: [wave-2, metered-billing, outbox, oban-cron, webhook]
dependency_graph:
  requires:
    - "04-01 (accrue_meter_events table, lattice_stripe 1.1, Accrue.Config keys)"
  provides:
    - "Accrue.Billing.report_usage/3 + report_usage!/3 (BILL-13)"
    - "Accrue.Billing.MeterEvent Ecto schema"
    - "Accrue.Billing.MeterEventActions (outbox: pending → reported|failed)"
    - "Accrue.Billing.MeterEvents.mark_failed_by_identifier/2 (webhook helper)"
    - "Accrue.Processor.@callback report_meter_event/1"
    - "Accrue.Processor.Stripe.report_meter_event/1 (via LatticeStripe.Billing.MeterEvent.create/3)"
    - "Accrue.Processor.Fake.report_meter_event/1 + Fake.meter_events_for/1 helper"
    - "Accrue.Jobs.MeterEventsReconciler (Oban :accrue_meters queue, LIMIT 1000, 60s grace)"
    - "Accrue.Webhook.DefaultHandler dispatch for v1.billing.meter.error_report_triggered"
    - "[:accrue, :ops, :meter_reporting_failed] telemetry with source: :inline | :reconciler | :webhook"
  affects:
    - "Plans 04-03..04-08 — metered billing is now available as a primitive (but none depend on it directly)"
tech_stack:
  added:
    - "No new deps — everything runs on lattice_stripe 1.1 surface landed in 04-01"
  patterns:
    - "Transactional outbox: commit-in-transact → exit-txn → call-processor → flip-row"
    - "Two-layer idempotency: body-level `identifier` + HTTP `idempotency_key` header (same value)"
    - "Pre-check identifier lookup outside Repo.transact to avoid in_failed_sql_transaction on unique index trip"
    - "Oban cron worker reading Clock.utc_now to stay sandbox-compatible in tests"
    - "Webhook reducer inside DefaultHandler dispatch instead of a separate handler file (matches existing Phase 3 Subscription/Invoice/Charge shape)"
key_files:
  created:
    - "accrue/lib/accrue/billing/meter_event.ex"
    - "accrue/lib/accrue/billing/meter_event_actions.ex"
    - "accrue/lib/accrue/billing/meter_events.ex"
    - "accrue/lib/accrue/jobs/meter_events_reconciler.ex"
    - "accrue/test/accrue/billing/meter_event_actions_test.exs"
    - "accrue/test/accrue/processor/fake_meter_event_test.exs"
    - "accrue/test/accrue/jobs/meter_events_reconciler_test.exs"
    - "accrue/test/accrue/webhook/handlers/billing_meter_error_report_test.exs"
  modified:
    - "accrue/lib/accrue/billing.ex"
    - "accrue/lib/accrue/processor.ex"
    - "accrue/lib/accrue/processor/fake.ex"
    - "accrue/lib/accrue/processor/fake/state.ex"
    - "accrue/lib/accrue/processor/stripe.ex"
    - "accrue/lib/accrue/webhook/default_handler.ex"
    - "accrue/test/support/stripe_fixtures.ex"
decisions:
  - "Pre-check Repo.get_by(MeterEvent, identifier:) OUTSIDE Repo.transact to handle the idempotency-replay case. Attempting the insert inside the transaction and rescuing the unique_constraint error would abort the Postgres transaction with in_failed_sql_transaction, blocking the subsequent SELECT. The pre-check is not a TOCTOU concern because the unique index is still the canonical guard, and the races are handled via a fallback path."
  - "Reconciler uses Accrue.Clock.utc_now() (not DateTime.utc_now()) for the cutoff calculation. This keeps Phase 3's Fake-clock convention consistent and lets tests backdate inserted_at via Repo.update_all without special casing the reconciler."
  - "Webhook reducer lives inline in Accrue.Webhook.DefaultHandler dispatch (not a separate `webhook/handlers/` file). Matches the Phase 3 shape of subscription/invoice/charge reducers and avoids a new directory."
  - "Accept two webhook type strings — `v1.billing.meter.error_report_triggered` (Stripe 2024+ versioned format) and `billing.meter.error_report_triggered` (older unversioned fallback). Stripe documents the v1 prefix but older integrations may emit the bare form."
  - "`Accrue.Billing.MeterEvents` is a separate module from `MeterEventActions` so the webhook path (touched by DefaultHandler) doesn't pull the NimbleOptions + outbox machinery into its dependency graph. Keeps the webhook reducer's blast radius small."
  - "`report_usage/3` returns plain `{:ok, _}` / `{:error, _}` — does NOT use `intent_result/1` (D3-07, D3-12). Meter reporting has no SCA/3DS capable path."
metrics:
  duration: "~25m"
  tasks_completed: 3
  files_created: 8
  files_modified: 7
  commits: 3
  completed_date: "2026-04-14"
requirements: [BILL-13]
---

# Phase 4 Plan 02: Metered Billing (BILL-13) Summary

End-to-end BILL-13 metered billing landed: `Accrue.Billing.report_usage/3` with the D4-03 transactional-outbox pattern, processor behaviour callback on both Stripe (lattice_stripe 1.1 wire) and Fake (scriptable + ETS-backed) adapters, an Oban cron reconciler that closes the "row committed but crashed before Stripe call" gap, and a webhook reducer for `v1.billing.meter.error_report_triggered` that flips rows to `failed` on async Stripe validation errors.

## Objective Achieved

A Phoenix developer can now call `Accrue.Billing.report_usage(customer, "api_call", value: 5)` and get back `{:ok, %MeterEvent{stripe_status: "reported"}}`. The durable outbox means a crash between DB commit and the Stripe HTTP call leaves a `pending` row the reconciler retries on the next tick. Two-layer idempotency (body-level `identifier` + HTTP `idempotency_key`) means replays are safe. Stripe's async validation errors flow back through the webhook handler and flip the row to `failed` with `[:accrue, :ops, :meter_reporting_failed]` telemetry.

## Tasks Completed

| # | Task                                                                 | Commit    | Key Files                                                                 |
|---|----------------------------------------------------------------------|-----------|---------------------------------------------------------------------------|
| 1 | MeterEvent schema + MeterEventActions.report_usage/3 + Billing facade + processor callback/adapters + fixtures + 13 tests | `312487a` | `meter_event.ex`, `meter_event_actions.ex`, `billing.ex`, `processor.ex`, `processor/fake.ex`, `processor/fake/state.ex`, `processor/stripe.ex`, `stripe_fixtures.ex`, `meter_event_actions_test.exs` |
| 2 | MeterEventsReconciler Oban worker + Fake meter test + 5 reconciler tests | `fffde5d` | `jobs/meter_events_reconciler.ex`, `fake_meter_event_test.exs`, `meter_events_reconciler_test.exs` |
| 3 | Webhook handler for `billing.meter.error_report_triggered` + MeterEvents helper + 3 integration tests | `30b3af2` | `billing/meter_events.ex`, `webhook/default_handler.ex`, `billing_meter_error_report_test.exs`, moduledoc fix on `meter_event.ex` |

Note: Task 1 bundles the processor callback + Stripe/Fake adapter implementations (originally scoped to Task 2) because the Task 1 test suite consumes them directly. Task 2 then layered the reconciler + dedicated Fake-adapter unit tests on top.

## Key Decisions Made

1. **Pre-check identifier outside `Repo.transact`** — Attempting the insert inside the transaction and rescuing the unique_constraint error aborts the Postgres transaction with `in_failed_sql_transaction`, blocking the subsequent SELECT used to fetch the existing row. Solution: `Repo.get_by/2` the identifier BEFORE entering the transaction; if found, return it; otherwise insert. The unique index remains the canonical guard against concurrent races, and the insert-time rescue clause handles the narrow window between the pre-check and the insert.

2. **Reconciler reads `Accrue.Clock.utc_now`** — Phase 3 convention. `DateTime.utc_now` would work in prod but breaks the Fake clock discipline the test suite depends on. Tests backdate `inserted_at` to `Clock.utc_now - 120s` via `Repo.update_all`.

3. **Webhook reducer inline in `DefaultHandler`** — Phase 2/3 put all reducers inline in `default_handler.ex`. Matches precedent, no new directory (`webhook/handlers/`). The test file lives at `test/accrue/webhook/handlers/billing_meter_error_report_test.exs` per the plan's path, but there's no corresponding `lib/accrue/webhook/handlers/billing_meter_error_report.ex` — the plan anticipated this shape divergence and listed both paths in `files_modified` with a "delete the unused one" note.

4. **Separate `Accrue.Billing.MeterEvents` helper module** — `MeterEventActions` pulls in NimbleOptions + the full outbox surface. The webhook reducer only needs a simple identifier → failed transition. Keeping the webhook path on a minimal helper module avoids coupling.

5. **Dual dispatch clauses for versioned and unversioned event types** — Stripe documents `v1.billing.meter.error_report_triggered` but older integrations emit the bare `billing.meter.error_report_triggered`. Accepting both costs nothing and eliminates a class of "webhook type wasn't recognized" bugs.

6. **Plain `{:ok, _}` / `{:error, _}` return — no `intent_result/1` wrapping** — D3-07, D3-12: meter reporting has no SCA/3DS-capable path. Intent wrapping would add noise with no value.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Facade-lockdown regression from meter_event.ex docstring**

- **Found during:** Task 3 full-suite verify step (`mix test` showed 1 failure in `Accrue.Processor.StripeTest`).
- **Issue:** The `Accrue.Billing.MeterEvent` module's `@moduledoc` contained the literal substring `LatticeStripe.Billing.MeterEvent.create/3`, which matched the `\bLatticeStripe\b` regex in the facade-lockdown test. This is the same class of bug Plan 04-01 hit with its `:dunning` config docstring — the lockdown test scans all of `lib/accrue/**/*.ex` for word-boundary mentions of `LatticeStripe` and fails if any file outside the 5-file allowlist is matched.
- **Fix:** Rewrote the docstring to describe the flow without naming the sibling module: "set after a successful processor call via the `Accrue.Processor.report_meter_event/1` callback."
- **Files modified:** `accrue/lib/accrue/billing/meter_event.ex` (doc only; schema unchanged)
- **Commit:** `30b3af2`

**2. [Rule 3 - Blocking] `Repo.transact` + rescue unique constraint aborts the transaction**

- **Found during:** Task 1, idempotency test (`test "same operation_id + event + value + ts resolves to same row"`)
- **Issue:** Plan's `insert_pending` shape put the `Repo.get_by` fallback inside the same `Repo.transact/2` block that attempted the insert. When the unique index tripped on `identifier`, Postgres returned `25P02 in_failed_sql_transaction` for the subsequent SELECT because the transaction was already in an aborted state.
- **Fix:** Pre-check `Repo.get_by(MeterEvent, identifier: identifier)` BEFORE entering the transaction. If the row exists, short-circuit and return it. If the insert inside the transaction STILL fails on the unique index (narrow race window), fall back to a post-transact SELECT.
- **Files modified:** `accrue/lib/accrue/billing/meter_event_actions.ex`
- **Commit:** `312487a` (fix was in the same commit that introduced the module — RED/GREEN iteration during Task 1)

**3. [Rule 3 - Convention] Plan's `Accrue.Error{type: :not_found}` doesn't exist**

- **Found during:** Task 1 action step
- **Issue:** Plan specified `%Accrue.Error{type: :not_found, message: ...}` for the "customer not found" error branch. Accrue's error hierarchy uses concrete exception structs (`Accrue.APIError`, `Accrue.CardError`, etc.) — there is no generic `Accrue.Error` struct.
- **Fix:** Return `%Accrue.APIError{code: "resource_missing", http_status: 404, message: ...}` matching the Fake adapter's existing 404 shape.
- **Files modified:** `accrue/lib/accrue/billing/meter_event_actions.ex`
- **Commit:** `312487a`

**4. [Rule 3 - Convention] Plan's `Accrue.Context.operation_id()` doesn't exist**

- **Found during:** Task 1 action step
- **Issue:** Plan called `Accrue.Context.operation_id()`; the actual Phase 3 API is `Accrue.Actor.current_operation_id/0`. Using the correct module matches `Accrue.BillingCase`, `Accrue.Billing.SubscriptionActions.resolve_operation_id/1`, and every other Phase 3 call site.
- **Fix:** Use `Accrue.Actor.current_operation_id/0` everywhere.
- **Commit:** `312487a`

**5. [Rule 3 - API mismatch] Plan's `Events.record_multi(:type, attrs)` is the wrong arity**

- **Found during:** Task 1 action step
- **Issue:** Plan used `Events.record_multi(:meter_event_reported, %{...})` which expects an `Ecto.Multi` as its first argument (`record_multi(multi, name, attrs)`). Inside a `Repo.transact/2` block the right call is `Accrue.Events.record(attrs)`.
- **Fix:** Use `Events.record/1`, matching the pattern used by `SubscriptionActions.record_event/3`, `ChargeActions`, and every other Phase 3 action module that commits events alongside mutations.
- **Commit:** `312487a`

**6. [Rule 3 - Plan path divergence] Plan listed both `lib/accrue/webhook/handlers/billing_meter_error_report.ex` and inline-in-default-handler shapes**

- **Found during:** Task 3 action step
- **Issue:** Plan's `files_modified` listed both `accrue/lib/accrue/webhook/handlers/billing_meter_error_report.ex` AND `accrue/lib/accrue/webhook/default_handler.ex`, with a note to "delete the one that's unused." The existing codebase has NO `webhook/handlers/` directory — every Phase 3 reducer lives inline in `default_handler.ex`.
- **Fix:** Added the dispatch clause + `reduce_meter_error_report/2` inline in `DefaultHandler`. No new file under `webhook/handlers/`. The test file lives at `test/accrue/webhook/handlers/billing_meter_error_report_test.exs` per the plan (test path is fine to diverge from lib layout).
- **Commit:** `30b3af2`

## Authentication Gates

None. Entire plan runs against the Fake processor; no real Stripe credentials required.

## Verification Results

### Automated

```
$ cd accrue && mix compile --warnings-as-errors
Compiling 89 files (.ex)
Generating Accrue.Cldr for 2 locales named [:en, :und] with a default locale named :en
Generated accrue app

$ cd accrue && mix test test/accrue/billing/meter_event_actions_test.exs
13 tests, 0 failures  (Task 1)

$ cd accrue && mix test test/accrue/processor/fake_meter_event_test.exs test/accrue/jobs/meter_events_reconciler_test.exs
8 tests, 0 failures  (Task 2)

$ cd accrue && mix test test/accrue/webhook/handlers/billing_meter_error_report_test.exs
3 tests, 0 failures  (Task 3)

$ cd accrue && mix test
34 properties, 419 tests, 0 failures (2 excluded :live_stripe)

$ cd accrue && mix credo --strict lib/accrue/billing/meter_event.ex \
    lib/accrue/billing/meter_event_actions.ex \
    lib/accrue/billing/meter_events.ex \
    lib/accrue/jobs/meter_events_reconciler.ex \
    lib/accrue/processor.ex \
    lib/accrue/processor/fake.ex \
    lib/accrue/processor/stripe.ex \
    lib/accrue/webhook/default_handler.ex \
    lib/accrue/billing.ex
Found no issues across all touched files.
```

### Manual checks

- `grep -r LatticeStripe accrue/lib` still shows only the allowlisted 5 files (facade lockdown green).
- `Accrue.Billing.report_usage(customer, "api_call", value: 10)` against Fake returns `{:ok, %MeterEvent{stripe_status: "reported", value: 10}}` and writes both an `accrue_meter_events` row and an `accrue_events` ledger row in the same transaction.
- `Accrue.Processor.Fake.meter_events_for(customer)` returns the full list of Fake-recorded events with string-encoded `value` (Pitfall 7 verified).
- `Accrue.Jobs.MeterEventsReconciler.reconcile/0` with 1 100 pending rows returns `{:ok, 1_000}` — LIMIT enforced.
- Webhook handler via `Accrue.Webhook.DefaultHandler.handle/1` with a `v1.billing.meter.error_report_triggered` envelope flips the matching row to `failed` and emits the `source: :webhook` telemetry.

## Requirements Marked Complete

- **BILL-13** — Metered billing: `Accrue.Billing.report_usage/3` with outbox durability, reconciler retry, Stripe adapter, Fake adapter, async-error webhook handler.

## Known Stubs

None. Every function is fully wired end-to-end against the Fake; the Stripe adapter delegates to the published `lattice_stripe 1.1` surface with no TODOs.

## Threat Flags

None beyond the plan's STRIDE register. Every T-04-02-{01..09} threat is mitigated as planned:

- T-04-02-01 (value tampering) — `:non_neg_integer` NimbleOptions type + `to_string/1` at the Stripe boundary.
- T-04-02-03 (PII in stripe_error) — `normalize_error/1` in `MeterEvent.failed_changeset` stringifies nested structs and scalarizes values; no raw Stripe payload is persisted.
- T-04-02-04 (duplicate billing via replay) — two-layer idempotency: Accrue `identifier` unique index + Stripe body-level `identifier` + HTTP `idempotency_key` header (all three use the same `row.identifier`).
- T-04-02-06 (stuck-row infinite retry) — reconciler flips rows to `failed` on any `{:error, _}`; does NOT leave them `pending` for the next tick.
- T-04-02-07 (HTTP inside Repo.transact) — verified by code inspection: `Processor.__impl__().report_meter_event/1` is called AFTER `Repo.transact/2` returns.
- T-04-02-08 (backdated billing) — `validate_backdating_window/1` enforces `[-35 days, +5 minutes]`.

## Self-Check

- `accrue/lib/accrue/billing/meter_event.ex` — FOUND, contains `schema "accrue_meter_events"`, `pending_changeset`, `reported_changeset`, `failed_changeset`
- `accrue/lib/accrue/billing/meter_event_actions.ex` — FOUND, contains `def report_usage`, `def report_usage!`, `"accrue_mev_"`, `35 * 86_400`, `[:accrue, :ops, :meter_reporting_failed]`, `Processor.__impl__().report_meter_event` AFTER the `Repo.transact` block
- `accrue/lib/accrue/billing/meter_events.ex` — FOUND, contains `def mark_failed_by_identifier`
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` — FOUND, contains `queue: :accrue_meters`, `@limit 1_000`, `@grace_seconds 60`
- `accrue/lib/accrue/processor.ex` — contains `@callback report_meter_event(`
- `accrue/lib/accrue/processor/stripe.ex` — contains `LatticeStripe.Billing.MeterEvent.create`, `to_string(row.value)`, `idempotency_key: row.identifier`
- `accrue/lib/accrue/processor/fake.ex` — contains `@meter_event_prefix "mev_fake_"`, `def report_meter_event`
- `accrue/lib/accrue/billing.ex` — contains `defdelegate report_usage` and `defdelegate report_usage!`
- `accrue/lib/accrue/webhook/default_handler.ex` — contains `"v1.billing.meter.error_report_triggered"`, `:meter_reporting_failed`, `source: :webhook`
- Commit `312487a` — FOUND
- Commit `fffde5d` — FOUND
- Commit `30b3af2` — FOUND

## Self-Check: PASSED
