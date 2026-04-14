---
phase: 03-core-subscription-lifecycle
plan: 07
subsystem: core-subscription-lifecycle
tags: [webhook, reducers, out-of-order, operation-id, oban, reconcilers, expiring-cards]
dependency_graph:
  requires:
    - "03-01: Accrue.Clock, Accrue.Actor.put_operation_id, BillingCase, StripeFixtures"
    - "03-02: last_stripe_event_ts/id watermark columns on every projected schema"
    - "03-03: Accrue.Processor.fetch/2 generic dispatcher + scripted_response for fakes"
    - "03-04: SubscriptionProjection.decompose/1 + get/2 dual-key helper"
    - "03-05: InvoiceProjection.decompose/1 + Invoice.force_status_changeset/2"
    - "03-06: charge/refund/PM write-surface row shape the reducers must converge to"
    - "Plan 02 DefaultHandler skeleton (customer.* handlers preserved)"
  provides:
    - "Accrue.Webhook.DefaultHandler.handle/1 — raw-map entry point for Fake.synthesize_event in-process dispatch"
    - "Accrue.Webhook.DefaultHandler.handle_event/3 — Phase 3 event families routed via Accrue.Webhook.Event struct"
    - "Skip-stale (WH-09) + always-refetch (WH-10) + record triple for 24 Phase 3 event types"
    - "Accrue.Plug.PutOperationId plug: request_id → Actor operation_id"
    - "Accrue.Oban.Middleware.put/1 helper: oban-<id>-<attempt> operation_id"
    - "Accrue.Jobs.ReconcileRefundFees — daily sweep of unsettled refund fees"
    - "Accrue.Jobs.ReconcileChargeFees — daily sweep of unsettled charge fees"
    - "Accrue.Jobs.DetectExpiringCards — scheduled card expiry detection with events-table dedup"
  affects:
    - "Plan 08 (plug + installer + health checks) will reference Accrue.Plug.PutOperationId in the endpoint template"
    - "Phase 4 (checkout) inherits skip-stale + refetch for every new event type added"
    - "accrue_admin LiveView on_mount hook is the deferred half of D3-63 (LiveView is hard dep only in the admin package)"
tech_stack:
  added: []
  patterns:
    - "Dual entry points — handle/1 (raw map, both atom- and string-keyed) for Fake.synthesize_event; handle_event/3 for DispatchWorker"
    - "reduce_row/5 shared wrapper: Repo.transact → load row → check_stale → telemetry-or-reducer"
    - "strict :lt skip, :eq processes (D3-49) — no off-by-one on ties"
    - "Processor.__impl__().fetch(type, id) used instead of facade-level Processor.fetch/2 because Accrue.Processor has only @callback fetch, no runtime facade function"
    - "Fees reconciler pattern: scripted_response from Fake lets tests control balance_transaction shape without patching Fake internals"
    - "DetectExpiringCards dedup via `fragment(\"(?->>'threshold')::int = ?\", data, threshold)` — events table is single source of truth, no new dedup column"
    - "All three workers call Accrue.Oban.Middleware.put(job) at the top of perform/1 for deterministic idempotency keys across retry attempts"
key_files:
  created:
    - accrue/lib/accrue/plug/put_operation_id.ex
    - accrue/lib/accrue/oban/middleware.ex
    - accrue/lib/accrue/jobs/reconcile_refund_fees.ex
    - accrue/lib/accrue/jobs/reconcile_charge_fees.ex
    - accrue/lib/accrue/jobs/detect_expiring_cards.ex
    - accrue/test/accrue/webhook/default_handler_phase3_test.exs
    - accrue/test/accrue/webhook/default_handler_out_of_order_test.exs
    - accrue/test/accrue/plug/put_operation_id_test.exs
    - accrue/test/accrue/jobs/reconcile_refund_fees_test.exs
    - accrue/test/accrue/jobs/reconcile_charge_fees_test.exs
    - accrue/test/accrue/jobs/detect_expiring_cards_test.exs
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
decisions:
  - "Accrue.Processor has no facade-level fetch/2, only @callback fetch/2. Reducers dispatch via Processor.__impl__().fetch(type, id) — matches the existing pattern in InvoiceActions/SubscriptionActions where processor_fn is applied on the adapter module."
  - "Schemas use mixed processor_id/stripe_id naming — subscription, invoice, charge, payment_method, customer use :processor_id, while refund + invoice_item use :stripe_id. load_row/2 dispatches per type so reducers don't leak the inconsistency."
  - "DefaultHandler ships BOTH handle/1 (raw-map from Fake.synthesize_event) and handle_event/3 (from Accrue.Webhook.DispatchWorker via Accrue.Webhook.Event struct) — the dispatch worker calls handle_event which routes Phase 3 types through the same shared dispatch/4 function. Zero reducer duplication between entry points."
  - "Invoice reducer ALWAYS uses Invoice.force_status_changeset/2 — never Invoice.changeset/2 — so Stripe-driven illegal transitions never raise. User-path transitions stay enforced through InvoiceActions."
  - "Refund reducer handles both charge-as-string and charge-as-nested-map shapes. The Fake stores charge: as a plain string id; reconciliation path via scripted_response or Stripe's expand both return nested charge objects. Single reducer supports both via conditional extraction."
  - "Fee reconcilers go through Accrue.Oban.Middleware.put(job) at the top of perform/1 so the outbound Stripe refetch carries a deterministic idempotency key derived from oban-<id>-<attempt>."
  - "DetectExpiringCards uses exact-day match (days_until == threshold) not a crossing window — simpler than tracking previous-run state and the 1-year events-table dedup window prevents accidental re-emission from cron jitter."
  - "Fake.transition/3 returns {:ok, map()}, not :ok. Initial test wrote `:ok = Fake.transition(...)` and failed with MatchError during the RED→GREEN pass; fixed to {:ok, _} = pattern."
  - "Accrue.Repo has no one!/1 delegation, but tests use the Accrue.TestRepo alias (BillingCase) directly for one!/get! since TestRepo IS a real Ecto.Repo. Production paths go through Accrue.Repo — this split is intentional."
metrics:
  duration: "~12 minutes"
  completed: "2026-04-14"
  tasks_completed: 3
  files_created: 11
  files_modified: 1
  test_count: "357 tests, 20 properties, 0 failures (up from 340 baseline, +17 new: 7 webhook, 4 plug, 6 jobs)"
requirements: [WH-09, BILL-24, BILL-26, PROC-02]
---

# Phase 3 Plan 07: Webhook reconcile + operation_id + reconcilers

Ships the Phase 3 webhook reconcile layer on top of the Phase 2
DefaultHandler skeleton: 24 Phase 3 event types handled via
skip-stale + always-refetch + record triple. Adds the HTTP
`Accrue.Plug.PutOperationId` plug and `Accrue.Oban.Middleware.put/1`
helper for deterministic idempotency key derivation across Plug and
Oban paths (D3-63). Lands three Oban backstop workers
(`ReconcileRefundFees`, `ReconcileChargeFees`, `DetectExpiringCards`)
for the async reconciliation of fee data and expiring-card detection.
Goal 5 (out-of-order handling) and Goal 6 (webhook-driven
reconciliation) of the phase goal are now met; BILL-24 (expiring
card notifications) and the BILL-26 backstop for refund fees land
here.

## Work Completed

### Task 1 — DefaultHandler Phase 3 event reducers (TDD)

**Commits:** `82c8d64` (RED), `38c3f70` (GREEN)

`Accrue.Webhook.DefaultHandler` grows two entry points that share a
single `dispatch/4` reducer pipeline:

- **`handle/1`** — raw event map entry point used by
  `Accrue.Processor.Fake.synthesize_event/3`. Accepts both string- and
  atom-keyed shapes via a local `get/2` helper that tries atom then
  stringified key. Converts `created` unix integer (or DateTime) into
  `evt_ts`, extracts the nested `data.object`, then delegates to
  `dispatch/4`.
- **`handle_event/3`** — the `Accrue.Webhook.Handler` behaviour clause
  invoked by `Accrue.Webhook.DispatchWorker`. Gets a lean
  `%Accrue.Webhook.Event{}` struct (`type`, `object_id`, `created_at`,
  `processor_event_id`) and calls the same `dispatch/4` with a
  fabricated `%{"id" => event.object_id}` object map. Non-Phase-3
  types fall through to `:ok`.

**Shared `reduce_row/5`** wraps the reducer in `Repo.transact/1`,
loads the local row by processor/stripe id, and applies the skip-stale
gate:

- `nil` row → no skip (new row from canonical refetch path)
- `nil` watermark → no skip (first event on this row)
- `evt_ts` strictly `:lt` watermark → emit
  `[:accrue, :webhooks, :stale_event]` telemetry with
  `%{object_type, stripe_id, event_id}` meta, return `{:ok, :stale}`
  **without refetching** (WH-09, D3-48 step 2)
- `:eq` or `:gt` → proceed to reducer (D3-49 tie handling)

**Five reducers** — subscription, invoice, charge, refund, payment
method — each follow the same shape:

1. `Processor.__impl__().fetch(type, stripe_id)` — refetch canonical.
   Uses the adapter's `fetch/2` directly because `Accrue.Processor`
   has only `@callback fetch/2`, no runtime facade function.
2. Project via the appropriate decomposer (or inline for charge/PM/
   refund which have no standalone projector).
3. Call `stamp_watermark/3` to merge
   `last_stripe_event_ts/last_stripe_event_id` into attrs.
4. Upsert — insert when `row == nil` (looks up the parent by
   `processor_id`, raising `Ecto.NoResultsError` to DLQ on missing
   parent per T-03-07-03), else update.
5. For subscription / invoice reducers: upsert child items via
   schema-specific helpers.
6. Call `Events.record/1` with a webhook-typed attrs map — all in the
   same transaction (EVT-04).

**Entry-point routing** — `dispatch/4` pattern-matches the event type
string and routes to the appropriate reducer:

- `customer.subscription.{created,updated,trial_will_end,deleted,paused,resumed}`
- `invoice.{created,finalized,paid,payment_failed,voided,marked_uncollectible,sent}`
- `charge.{succeeded,failed,updated,refunded}`
- `charge.refund.updated` + `refund.{created,updated}`
- `payment_method.{attached,detached,updated,card_automatically_updated}`

`trial_will_end` is remapped to the `subscription.trial_ended` event
type (per D3-66) — no schema mutation, just telemetry + ledger.
`card_automatically_updated` becomes `payment_method.auto_updated`.
Refund events that settle fees emit `refund.fees_settled` instead of
`refund.updated` when `Refund.fees_settled?/1` is true.

**Invoice reducer** uses `Invoice.force_status_changeset/2` exclusively
— the webhook path is Stripe-canonical and must never surface illegal
transition errors on `:status`. Invoice item upsert is by `stripe_id`
(not FK) because Stripe may reference items we haven't projected yet
(matches Plan 05 convention).

**Refund reducer** handles both charge-as-string (Fake default) and
charge-as-nested-map (Stripe expand path). When the canonical `charge`
key is a string, it queries `accrue_charges` by `processor_id`. When
it's nested, it extracts `balance_transaction` from the nested object.

**7 tests** across two test files:

- `default_handler_out_of_order_test.exs` (2): skip-stale older
  event emits telemetry + no refetch; tie on equal timestamps
  processes normally.
- `default_handler_phase3_test.exs` (5): subscription.updated
  refetches new status; invoice.paid uses force_status_changeset;
  charge.succeeded extracts fee; payment_method.updated patches
  exp_month/exp_year; charge.refund.updated upserts refund row.

### Task 2 — operation_id propagation (TDD)

**Commit:** `7664666`

`Accrue.Plug.PutOperationId` is a `@behaviour Plug` with three
fallback branches:

1. `conn.assigns[:request_id]` (populated by `Plug.RequestId`
   upstream)
2. `x-request-id` header (when RequestId isn't wired)
3. Randomly generated `"http-" <> 16hex` sentinel

All three call `Accrue.Actor.put_operation_id/1`. The header branch
documents the T-03-07-05 trust boundary inline: an attacker pinning
the header at worst causes their own retries to converge to the same
Stripe call, which is the correct behaviour.

`Accrue.Oban.Middleware.put/1` is the explicit worker-side helper for
the Oban path. Format: `"oban-#{id}-#{attempt}"`. Keying on `attempt`
(not just `id`) ensures each retry gets a fresh idempotency key —
Stripe re-processes the call on retry instead of returning the cached
failed result.

**LiveView on_mount hook** is deferred to `accrue_admin` per the
CLAUDE.md dependency rule. `phoenix_live_view` is a hard dep only in
`accrue_admin`, never in core `accrue`.

**4 tests** cover all three plug branches + the Oban middleware format.

### Task 3 — Reconcilers + DetectExpiringCards

**Commit:** `95bc620`

Three `Oban.Worker` modules, all at `queue: :accrue_reconcilers`
(fee reconcilers) or `:accrue_scheduled` (expiring cards), all
`max_attempts: 3`, all wrapping `perform/1` with
`Accrue.Oban.Middleware.put(job)` at the top.

**`Accrue.Jobs.ReconcileRefundFees.sweep/0`** — selects refunds where
`fees_settled_at IS NULL AND inserted_at < now() - 24h`, refetches
canonical via `Processor.retrieve_refund(sid, expand: [balance_transaction, charge.balance_transaction])`,
and when both `fee` and `fee_refunded` are populated writes:

- `stripe_fee_refunded_amount_minor = fee_refunded`
- `merchant_loss_amount_minor = fee - fee_refunded`
- `fees_settled_at = Accrue.Clock.utc_now()`

Emits `[:accrue, :billing, :refund, :fees_settled]` telemetry +
`refund.fees_settled` event. `extract_charge_balance_transaction/1`
handles both nested-charge and top-level balance_transaction shapes.

**`Accrue.Jobs.ReconcileChargeFees.sweep/0`** — analogous for
charges, with `expand: [balance_transaction]`. Writes
`stripe_fee_amount_minor` + `stripe_fee_currency` + `fees_settled_at`.

**`Accrue.Jobs.DetectExpiringCards.scan/0`** — scans all PMs with
non-nil `exp_month`/`exp_year`, computes `days_until` as
`DateTime.diff(end_of_month(year, month), now, :second) |> div(86_400)`,
and for each `(pm, threshold)` pair where `days_until == threshold`
AND `already_warned?/2` returns false, records a
`card.expiring_soon` event + telemetry.

`already_warned?/2` uses a parameterized Ecto fragment:

```elixir
fragment("(?->>'threshold')::int = ?", e.data, ^threshold)
```

which safely extracts and casts the jsonb threshold without string
interpolation (T-03-07-06 mitigation).

`end_of_month/2` builds a DateTime at 23:59:59 on
`:calendar.last_day_of_the_month(year, month)` so the diff math
matches Stripe's month-end expiry semantics.

Thresholds come from `Accrue.Config.get!(:expiring_card_thresholds)`
(default `[30, 7, 1]`, validated as strictly descending by Plan 01's
`validate_descending/1` custom NimbleOptions type).

**6 tests** across three test files. The expiring-cards test
computes `days_until` from the Fake clock, configures a single-element
threshold list matching that value, asserts one emission, then
re-scans and asserts the second scan suppresses via the 365-day
events-table dedup window.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan's `Processor.fetch/2` as facade call**

- **Found during:** Task 1 first compile
- **Issue:** Plan literal uses `Processor.fetch(:subscription, id)` —
  but `Accrue.Processor` only declares `@callback fetch/2`, not a
  runtime facade function. Compile fails with "Accrue.Processor.fetch/2
  is undefined or private" under `--warnings-as-errors`.
- **Fix:** Rewrote all five reducer call sites to
  `Processor.__impl__().fetch(type, id)` — matches the adapter-dispatch
  pattern already used by `InvoiceActions`/`SubscriptionActions` for
  processor_fn application.
- **Files modified:** `accrue/lib/accrue/webhook/default_handler.ex`
- **Commit:** `38c3f70`

**2. [Rule 2 — Missing critical functionality] DefaultHandler schema-name drift**

- **Found during:** Task 1 test run
- **Issue:** Plan literal uses `row.stripe_id` uniformly, but Phase 3
  schemas landed with mixed naming: `subscription`, `invoice`,
  `charge`, `payment_method`, `customer` use `:processor_id`, while
  `refund` and `invoice_item` use `:stripe_id`. Using `stripe_id`
  everywhere would fail the `Repo.get_by/2` queries for 5 of the 7
  schemas.
- **Fix:** `load_row/2` dispatches per object type so reducers don't
  leak the naming inconsistency. Each clause uses the correct column
  name for its schema. Documented in decisions[1].
- **Files modified:** `accrue/lib/accrue/webhook/default_handler.ex`
- **Commit:** `38c3f70`

**3. [Rule 1 — Bug] Fake.transition/3 returns tuple, not :ok**

- **Found during:** Task 1 test iteration
- **Issue:** Initial test wrote `:ok = Fake.transition(sub.processor_id, :active, ...)`
  expecting `:ok` but `Fake.transition/3` spec is `{:ok, map()} | {:error, ...}`.
  MatchError at runtime.
- **Fix:** Pattern match to `{:ok, _} = Fake.transition(...)`.
- **Files modified:** `accrue/test/accrue/webhook/default_handler_phase3_test.exs`
- **Commit:** `38c3f70`

**4. [Rule 3 — Blocking] `use Plug.Test` deprecated warning**

- **Found during:** Task 2 first compile
- **Issue:** `use Plug.Test` is deprecated in Plug 1.16+; warning
  surfaces as a hard error under `--warnings-as-errors`.
- **Fix:** Changed to `import Plug.Test` (all the `conn/2` helper
  imports come through that). Dropped unused `import Plug.Conn`
  since `Plug.Conn.assign/3` and `put_req_header/3` are accessed
  via fully-qualified names in the test.
- **Files modified:** `accrue/test/accrue/plug/put_operation_id_test.exs`
- **Commit:** `7664666`

**5. [Rule 3 — Blocking] DetectExpiringCards nested DateTime.new/2 math**

- **Found during:** Task 3 test writing
- **Issue:** Initial test tried to inline `{:ok, dt} = DateTime.new(...)`
  inside a `DateTime.diff(...)` chain — doesn't parse cleanly.
- **Fix:** Extracted `days_until_end_of_month/3` helper in the test
  file that mirrors the worker's `end_of_month/2` semantics exactly.
  Clean computation of the expected threshold value before asserting.
- **Files modified:** `accrue/test/accrue/jobs/detect_expiring_cards_test.exs`
- **Commit:** `95bc620`

### Pre-existing flake (seed-dependent)

`test/accrue/webhook/dispatch_worker_test.exs` still reports one
failure when run in a specific seed order (same harness issue noted
in 03-03 and 03-04 SUMMARYs — GenServer teardown race in parallel
test groups). `--seed 0` is clean. Not caused by Plan 07 changes.

## Verification Results

- `mix compile --warnings-as-errors --force` — 0 warnings, 82 files
- `mix test --seed 0` — **357 tests, 20 properties, 0 failures**
  (up from 340 baseline, +17 new)
- `mix test test/accrue/webhook/default_handler_phase3_test.exs test/accrue/webhook/default_handler_out_of_order_test.exs` — 7/7
- `mix test test/accrue/plug/put_operation_id_test.exs` — 4/4
- `mix test test/accrue/jobs/` — 6/6
- `mix credo --strict` — **0 issues** across 135 source files
  (970 mods/funs analyzed)

## Success Criteria

- [x] DefaultHandler handles customer.subscription.created/updated/
      deleted/trial_will_end via skip-stale + refetch + record triple
- [x] DefaultHandler handles invoice.created/finalized/paid/
      payment_failed/voided/marked_uncollectible/sent via
      force_status_changeset
- [x] DefaultHandler handles charge.succeeded/failed/refunded/updated
      via refetch canonical
- [x] DefaultHandler handles charge.refund.updated + refund.created/
      updated with fee reconciliation and emits refund.fees_settled
      when fees settle
- [x] DefaultHandler handles payment_method.attached/detached/
      updated/card_automatically_updated
- [x] Out-of-order event (older `stripe_created_at`) skipped with
      `:stale_event` telemetry, NO refetch
- [x] Tie on equal timestamps does not skip (processes later arrival)
- [x] ReconcileRefundFees sweeps refunds with `fees_settled_at IS
      NULL AND inserted_at < now() - 24h`
- [x] ReconcileChargeFees analogous
- [x] DetectExpiringCards queries accrue_events for last 365d dedup
      per `(pm_id, threshold)`
- [x] Accrue.Plug.PutOperationId reads `conn.assigns.request_id` and
      writes to Accrue.Actor
- [x] Accrue.Oban.Middleware formats `oban-<id>-<attempt>`

## Acceptance Criteria Checklist

Task 1:

- [x] `grep -q "check_stale" accrue/lib/accrue/webhook/default_handler.ex`
- [x] `grep -q "last_stripe_event_ts" accrue/lib/accrue/webhook/default_handler.ex`
- [x] `grep -q ":accrue, :webhooks, :stale_event" accrue/lib/accrue/webhook/default_handler.ex`
- [x] `grep -q "Processor.__impl__().fetch" accrue/lib/accrue/webhook/default_handler.ex`
      (plan literal used `Processor.fetch` — see Deviation 1)
- [x] `grep -q "force_status_changeset" accrue/lib/accrue/webhook/default_handler.ex`
- [x] `grep -q "customer.subscription." accrue/lib/accrue/webhook/default_handler.ex`
- [x] `grep -q "charge.refund.updated" accrue/lib/accrue/webhook/default_handler.ex`
- [x] `grep -q "payment_method." accrue/lib/accrue/webhook/default_handler.ex`
- [x] `grep -q "fees_settled_at" accrue/lib/accrue/webhook/default_handler.ex`

Task 2:

- [x] `grep -q "defmodule Accrue.Plug.PutOperationId" accrue/lib/accrue/plug/put_operation_id.ex`
- [x] `grep -q "@behaviour Plug" accrue/lib/accrue/plug/put_operation_id.ex`
- [x] `grep -q "Accrue.Actor.put_operation_id" accrue/lib/accrue/plug/put_operation_id.ex`
- [x] `grep -q "defmodule Accrue.Oban.Middleware" accrue/lib/accrue/oban/middleware.ex`
- [x] `grep -q "def put" accrue/lib/accrue/oban/middleware.ex`
- [x] `grep -q "oban-" accrue/lib/accrue/oban/middleware.ex`

Task 3:

- [x] `grep -q "defmodule Accrue.Jobs.ReconcileRefundFees" accrue/lib/accrue/jobs/reconcile_refund_fees.ex`
- [x] `grep -q "use Oban.Worker" accrue/lib/accrue/jobs/reconcile_refund_fees.ex`
- [x] `grep -q "is_nil(r.fees_settled_at)" accrue/lib/accrue/jobs/reconcile_refund_fees.ex`
- [x] `grep -q "inserted_at < \\^cutoff" accrue/lib/accrue/jobs/reconcile_refund_fees.ex`
- [x] `grep -q "defmodule Accrue.Jobs.ReconcileChargeFees" accrue/lib/accrue/jobs/reconcile_charge_fees.ex`
- [x] `grep -q "defmodule Accrue.Jobs.DetectExpiringCards" accrue/lib/accrue/jobs/detect_expiring_cards.ex`
- [x] `grep -q "expiring_card_thresholds" accrue/lib/accrue/jobs/detect_expiring_cards.ex`
- [x] `grep -q "already_warned" accrue/lib/accrue/jobs/detect_expiring_cards.ex`
- [x] `grep -q "card.expiring_soon" accrue/lib/accrue/jobs/detect_expiring_cards.ex`

## Self-Check: PASSED

All created files exist and all commits are in the log:

- `accrue/lib/accrue/webhook/default_handler.ex` — MODIFIED (+500 lines Phase 3 reducers)
- `accrue/lib/accrue/plug/put_operation_id.ex` — FOUND
- `accrue/lib/accrue/oban/middleware.ex` — FOUND
- `accrue/lib/accrue/jobs/reconcile_refund_fees.ex` — FOUND
- `accrue/lib/accrue/jobs/reconcile_charge_fees.ex` — FOUND
- `accrue/lib/accrue/jobs/detect_expiring_cards.ex` — FOUND
- `accrue/test/accrue/webhook/default_handler_phase3_test.exs` — FOUND (5 tests)
- `accrue/test/accrue/webhook/default_handler_out_of_order_test.exs` — FOUND (2 tests)
- `accrue/test/accrue/plug/put_operation_id_test.exs` — FOUND (4 tests)
- `accrue/test/accrue/jobs/reconcile_refund_fees_test.exs` — FOUND (2 tests)
- `accrue/test/accrue/jobs/reconcile_charge_fees_test.exs` — FOUND (2 tests)
- `accrue/test/accrue/jobs/detect_expiring_cards_test.exs` — FOUND (2 tests)
- Commit `82c8d64` (Task 1 RED) — FOUND
- Commit `38c3f70` (Task 1 GREEN) — FOUND
- Commit `7664666` (Task 2) — FOUND
- Commit `95bc620` (Task 3) — FOUND
