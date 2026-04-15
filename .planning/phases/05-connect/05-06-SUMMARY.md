---
phase: 05-connect
plan: 06
subsystem: connect
tags: [connect, webhooks, reducer, force_status_changeset, out_of_order, tombstone, telemetry]

requires:
  - phase: 05-connect
    plan: 01
    provides: "Accrue.Webhook.ConnectHandler stub wired into DispatchWorker branching + accrue_webhook_events.endpoint column"
  - phase: 05-connect
    plan: 02
    provides: "Accrue.Connect.Account.force_status_changeset/2 + Accrue.Connect.retrieve_account/2 upsert_local path + ConnectCase pdict cleanup"
provides:
  - "Accrue.Webhook.ConnectHandler full D5-05 reducer surface (account.updated, account.application.authorized, account.application.deauthorized, capability.updated, payout.created, payout.paid, payout.failed, person.created, person.updated, catch-all)"
  - "Pitfall 3 mitigation via refetch-canonical: missing local row seeds from Connect.retrieve_account/2 in the same Repo.transact/1; stale replays are functional no-ops because every reducer refetches before writing"
  - "Deauthorization tombstoning via Account.force_status_changeset/2 with deauthorized_at — never hard-deletes (T-05-06-02)"
  - "[:accrue, :ops, :connect_account_deauthorized] + [:accrue, :ops, :connect_capability_lost] + [:accrue, :ops, :connect_payout_failed] ops telemetry events via Accrue.Telemetry.Ops"
  - "Per-reducer [:accrue, :connect, :<event_name>] firehose span with auto-normalized :ok | {:error, term} return"
  - "payload_from_ctx/1 helper — reducers needing full payload (capability.*, payout.*) refetch the persisted accrue_webhook_events.data jsonb via ctx.webhook_event_id instead of trusting the lean Webhook.Event struct"
affects: [05-07]

tech-stack:
  added: []
  patterns:
    - "Webhook-row payload refetch via ctx.webhook_event_id: reducers needing more than event.object_id load the raw Stripe payload from accrue_webhook_events.data jsonb. This keeps the %Webhook.Event{} struct lean (WH-10 refetch-canonical) while still giving Connect reducers access to nested fields (capability.account, payout.destination) that aren't part of the object_id."
    - "Refetch-canonical as the out-of-order mitigation strategy: instead of adding a last_event_ts watermark column to Account and comparing timestamps, the reducer calls Connect.retrieve_account/2 which pulls current Stripe state and upserts locally via force_status_changeset/2. A stale replay overwrites the row with values it already has — functional no-op — while a missing-row first-delivery case is seeded in the same transaction that would otherwise have failed."
    - "span/3 private helper normalizing reducer returns ({:ok, row} | {:error, err}) to the Handler behaviour return type (:ok | {:error, term}) while wrapping in :telemetry.span/3. Reducers are free to return typed structs on success for composability; the span wrapper collapses them at the handler boundary."

key-files:
  created:
    - "accrue/test/accrue/webhook/connect_handler_test.exs"
  modified:
    - "accrue/lib/accrue/webhook/connect_handler.ex"
    - "accrue/test/accrue/webhook/dispatch_worker_test.exs"

key-decisions:
  - "Phase 05 P06: Refetch-canonical (Connect.retrieve_account/2) as the out-of-order mitigation — no new last_event_ts column added to Account. The Account schema from Plan 05-02 is stable, and the refetch pattern is strictly idempotent: stale replays no-op because they write the current Stripe state, and missing-row deliveries are seeded from the same refetch. This is cleaner than a watermark column, requires no migration, and matches Pitfall 3's described fix verbatim."
  - "Phase 05 P06: Payload beyond event.object_id is loaded from the persisted accrue_webhook_events.data jsonb via ctx.webhook_event_id. The lean %Webhook.Event{} struct only carries routing fields (type, object_id, created_at), so capability.* and payout.* reducers — which need the payload's `account`, `destination`, `amount`, `status` fields — reach into the persisted row. This preserves the WH-10 'refetch current state' discipline while giving reducers access to payload fields that aren't object_id."
  - "Phase 05 P06: Every reducer's body runs inside Accrue.Repo.transact/1 wrapping Repo.update! + Accrue.Events.record/1 (not Events.record_multi/3). The plan pseudocode referenced `Events.record_multi(:atom, attrs)` which is not the real signature; the actual API is `record_multi(multi, name, attrs)` for Ecto.Multi pipelines. For simple transact-block reducers, `Events.record/1` is the correct pair. EVT-04 (write + audit atomically) is still upheld because both calls run inside the same outer transaction."
  - "Phase 05 P06: Deauthorization tombstones via force_status_changeset/2 even when the local row did not exist before the webhook arrived — the reducer calls Connect.retrieve_account/2 to seed the row first, then stamps deauthorized_at on it. If the retrieve fails (row genuinely unresolvable), the reducer still records the audit event and emits ops telemetry so the deauthorization signal is never silently lost."
  - "Phase 05 P06: Catch-all returns :ok for unknown Connect event types (e.g. future account.external_account.*, account.updated.capability.*). Connect webhooks should always ack — a crash-on-unknown would park events in DLQ for no good reason. The behaviour fallthrough from `use Accrue.Webhook.Handler` already provides this; the module just documents the contract explicitly."

patterns-established:
  - "payload_from_ctx/1: any webhook handler needing fields beyond %Webhook.Event{} object_id loads the persisted row via ctx.webhook_event_id and extracts data[\"data\"][\"object\"]. Plan 05-06 introduces this for ConnectHandler; future handlers that need nested payload fields (e.g. a payment_intent.amount_capturable_updated reducer inspecting amount_capturable) should adopt the same shape instead of widening the Event struct."
  - "span/3 wrapper normalizing reducer returns: reducers can return typed {:ok, struct} or {:error, term} for composability, and the span wrapper collapses them to the Handler behaviour return type at the handler boundary. Same shape should be used by any future multi-reducer handler module."
  - "Refetch-canonical over watermarks for idempotent state projection: when the processor supports a retrieve round-trip and the schema has force_status_changeset/2 coverage, prefer refetching over adding a last_event_ts column. This is the Phase 5 Connect pattern; contrast with Phase 3 subscription reducers which use timestamp skip-stale (WH-09) because they do NOT always refetch canonical."

requirements-completed: [CONN-03]

duration: 15min
completed: 2026-04-15
---

# Phase 05 Plan 06: ConnectHandler D5-05 Reducer Set Summary

**Replaces the Plan 05-01 pass-through `Accrue.Webhook.ConnectHandler` stub with the full D5-05 webhook reducer surface — account lifecycle, capability status, payout events, and person passthrough — threading every Stripe Connect webhook through `Accrue.Connect.Account.force_status_changeset/2` inside an atomic `Repo.transact/1` + `Events.record/1` pair, mitigating Pitfall 3 (out-of-order delivery) via refetch-canonical via `Connect.retrieve_account/2`, tombstoning deauthorization without ever hard-deleting (T-05-06-02), and emitting ops telemetry (`connect_account_deauthorized`, `connect_capability_lost`, `connect_payout_failed`) for every alertable transition — delivering CONN-03 end-to-end.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-15T04:38:00Z
- **Completed:** 2026-04-15T04:53:00Z
- **Tasks:** 1 (`type="auto" tdd="true"`)
- **Commits:** 1 (`3a302af`)
- **Tests added:** 14 (full reducer matrix + end-to-end dispatch integration)
- **Tests total:** 691 tests / 44 properties / 0 failures (clean second run after one pre-existing Fake GenServer flake surfaced in the first)
- **Files created:** 1
- **Files modified:** 2

## Accomplishments

1. **CONN-03 account state sync from webhooks (full surface).** The `account.updated` reducer handles both the happy path (existing local row gets updated via `force_status_changeset/2`) and the out-of-order case (no local row → `Connect.retrieve_account/2` seeds it in the same transaction). The integration test flips the Fake-side account to `charges_enabled/payouts_enabled/details_submitted = true`, resets the local row's flags to `false`, dispatches the webhook through the full `DispatchWorker` path, and asserts `Account.fully_onboarded?/1` on the result — proving Plan 01 dispatch branching + Plan 06 reducer logic + Plan 02 projection all chain correctly.

2. **Pitfall 3 mitigation via refetch-canonical, no new schema columns.** The plan originally hinted at adding a `last_event_at` watermark column, but refetch-canonical is strictly idempotent in the Connect case: `retrieve_account` always pulls current Stripe state, and `force_status_changeset/2` projects it atomically. A stale replay overwrites the row with values it already has (functional no-op), and a missing row is seeded from the refetch. VALIDATION row 9 test (`out_of_order_seeds_local_row`) seeds the Fake via `create_account`, deletes the local row, then dispatches `account.updated` — the handler calls `retrieve_account`, which re-creates the local row via `upsert_local/3`. This preserves Plan 02's stable schema and ships Pitfall 3 coverage in one clean reducer body.

3. **Deauthorization tombstones via force_status_changeset — 3 test cases.**
   - With a local row: `deauthorized_at` is stamped and the row persists (asserted via `Account.deauthorized?/1` + `%DateTime{}` pattern match).
   - Without a local row: `Connect.retrieve_account/2` seeds it first, then `force_status_changeset/2` stamps the tombstone (handles the "app authorized before Accrue was installed" edge case).
   - Ops telemetry: `[:accrue, :ops, :connect_account_deauthorized]` fires with `%{count: 1}` measurements and `%{stripe_account_id:, deauthorized_at:, operation_id:}` metadata (operation_id auto-merged by `Accrue.Telemetry.Ops.emit/3`).

4. **Capability jsonb merge + capability-lost ops telemetry.** The `capability.updated` reducer loads the persisted webhook row's `data["data"]["object"]` via `ctx.webhook_event_id` (the payload carries the `account` field needed to resolve the connected account), merges the new `{capability_name => {status, requested}}` entry into the existing `capabilities` jsonb, and writes via `force_status_changeset/2`. If the prior capability was `"active"` and the incoming status is anything else, emits `[:accrue, :ops, :connect_capability_lost]`. Tested end-to-end: first webhook sets `card_payments` to `active`, second webhook flips it to `inactive`, test asserts the ops event fires with `%{capability: "card_payments", from: "active", to: "inactive"}` metadata.

5. **Payout events-only writes + payout.failed ops telemetry.** No local payout schema in v1.0 (D5-05 explicitly defers payout projection); the reducer writes an `accrue_events` row with `type: "connect.payout.created"|"paid"|"failed"`, `subject_id: destination` (the connected account id), and `data: %{payout_id, destination, amount, currency, status}`. `payout.failed` additionally emits `[:accrue, :ops, :connect_payout_failed]` with `%{stripe_account_id, payout_id, amount, currency, failure_code}` — SREs can alert on this directly without re-parsing the events ledger.

6. **Person reducers are deferred passthroughs.** `person.created` and `person.updated` log a debug line explaining "Custom-account scope, deferred to v1.x" and return `:ok`. The test asserts the call no-ops (no new `connect.person.*` events row inserted).

7. **End-to-end DispatchWorker → ConnectHandler integration test.** Inserts a real `accrue_webhook_events` row with `endpoint: :connect`, type `account.updated`, data pointing at a Fake-seeded account. Calls `DispatchWorker.perform/1` with an `%Oban.Job{}`. Asserts: (a) the worker returns `:ok`, (b) the local `Account` row is updated via `Account.fully_onboarded?/1`, (c) the webhook row transitions to `:succeeded`. This proves Plan 01 dispatch-branching + Plan 02 projection + Plan 06 reducer chain end-to-end.

8. **Dispatch worker test unbreakage (Rule 3).** The existing Plan 05-01 `dispatch_worker_test.exs` test "endpoint :connect routes default handler to ConnectHandler (D5-01)" inserted an `account.updated` row against a non-existent fake account id. With the stub, that was a no-op; with the real reducer, it crashed on `GenServer.call` to the not-started Fake. Changed the test's event type to `account.external_account.created` (hits the catch-all clause returning `:ok`) so the test still exercises dispatch routing without forcing a Connect round-trip. Real reducer coverage lives in the new `connect_handler_test.exs` under the `ConnectCase` template which starts the Fake.

## Task Commits

1. **Task 1: Full ConnectHandler reducers + out-of-order seeding + ops telemetry + 14 tests + dispatch_worker_test unbreakage** — `3a302af` (feat)

## Files Created/Modified

### Created
- `accrue/test/accrue/webhook/connect_handler_test.exs` — 14 tests / 457 LOC covering the full reducer clause matrix plus end-to-end DispatchWorker integration

### Modified
- `accrue/lib/accrue/webhook/connect_handler.ex` — stub (35 LOC) → full reducer module (457 LOC). `use Accrue.Webhook.Handler`, 10 `handle_event/3` clauses (account.updated, account.application.{authorized,deauthorized}, capability.updated, payout.{created,paid,failed}, person.{created,updated}, catch-all), `reduce_*` private helpers, `payload_from_ctx/1` (loads persisted webhook row for payload-beyond-object_id needs), `span/3` wrapper normalizing reducer returns to the Handler behaviour return type
- `accrue/test/accrue/webhook/dispatch_worker_test.exs` — Plan 05-01 dispatch routing test: event type changed from `account.updated` → `account.external_account.created` (catch-all) so the test exercises routing without forcing a reducer round-trip

## Decisions Made

See `key-decisions` in frontmatter. Key points:

- **Refetch-canonical, no new schema column.** Pitfall 3 is handled by Connect.retrieve_account/2 being strictly idempotent, not by watermarking. Preserves Plan 02's stable schema.
- **Payload refetch via ctx.webhook_event_id.** Reducers needing fields beyond event.object_id load from persisted accrue_webhook_events.data. Keeps the lean %Webhook.Event{} struct intact.
- **Events.record/1 (not record_multi/3) inside Repo.transact.** The plan pseudocode referenced a non-existent signature; the real record_multi/3 is for Ecto.Multi pipelines. Transact-block reducers pair with record/1.
- **Tombstone even when no local row.** If retrieve_account succeeds, seed + tombstone; if it fails, still record the audit event so the deauthorization signal never silently drops.
- **Catch-all returns :ok.** Connect webhooks always ack; crash-on-unknown is strictly worse because it parks events in DLQ for future Stripe-side event types.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `:telemetry.span/3` return-type mismatch with Handler behaviour**
- **Found during:** Task 1 first test run (11/14 failing with `CaseClauseError` in DispatchWorker)
- **Issue:** The initial reducer implementation wrapped each clause directly in `:telemetry.span/3` with the reducer result threaded through. But `Repo.transact/1` returns `{:ok, row}` on success, and `:telemetry.span/3` passes the function's first tuple element through unchanged. So `handle_event/3` was returning `{:ok, %Account{...}}` instead of the `:ok` required by the `Accrue.Webhook.Handler` behaviour, causing `DispatchWorker.perform/1` to hit its `{:error, reason}` clause on a successful reducer.
- **Fix:** Added a private `span/3` helper that wraps `:telemetry.span/3` and normalizes the reducer's return via `normalize_result/1` — `{:ok, _}` → `:ok`, `{:error, term}` → `{:error, term}`, bare `:ok` → `:ok`. Reducers keep their typed struct returns for composability, while the handler boundary collapses them to the behaviour contract.
- **Files modified:** `accrue/lib/accrue/webhook/connect_handler.ex`
- **Committed in:** `3a302af`

**2. [Rule 3 - Blocking] Plan 05-01 dispatch routing test broke with real reducer logic**
- **Found during:** Full-suite verification after Task 1 implementation
- **Issue:** `dispatch_worker_test.exs` "endpoint :connect routes default handler to ConnectHandler" inserted a webhook row with `type: "account.updated"` + a non-existent `cus_test_*` object id. With the stub ConnectHandler this was a no-op, but the real `account.updated` reducer crashed on `GenServer.call(Accrue.Processor.Fake, ...)` because (a) the `DispatchWorkerTest` case does not start the Fake GenServer and (b) the nonexistent id would fail the retrieve_account lookup anyway.
- **Fix:** Changed the test's event type to `account.external_account.created` (hits the ConnectHandler catch-all returning `:ok`) so the test still exercises dispatch routing without forcing a reducer round-trip. Real reducer coverage lives in the new `connect_handler_test.exs` file under the `ConnectCase` template which starts the Fake.
- **Files modified:** `accrue/test/accrue/webhook/dispatch_worker_test.exs`
- **Committed in:** `3a302af`

**3. [Rule 3 - Blocking] Plan pseudocode referenced non-existent `Events.record_multi(:atom, %{...})` signature**
- **Found during:** Task 1 implementation
- **Issue:** The plan's `<interfaces>` and PATTERNS.md Pattern 5 both show `Events.record_multi(:connect_account_updated, %{...})`, but the actual `Accrue.Events.record_multi/3` signature is `record_multi(multi, name, attrs)` for use with `Ecto.Multi` pipelines. There is no 2-arity form for transact-block use.
- **Fix:** Used the correct pair for transact-block reducers: `Accrue.Repo.transact/1` wrapping `Repo.update!` + `Accrue.Events.record/1`. This is the exact same shape `Accrue.Webhook.DefaultHandler` uses for its subscription/invoice/charge reducers (see `record_event/4` helper at default_handler.ex:951). EVT-04 (write + audit atomically) is upheld because both calls run inside the same outer transaction.
- **Files modified:** `accrue/lib/accrue/webhook/connect_handler.ex`
- **Committed in:** `3a302af`

### Out-of-Scope / Deferred

Nothing new logged. The pre-existing Fake GenServer race flake in `test/accrue/processor/fake_phase3_test.exs` (tracked from Plan 05-01/02 in `deferred-items.md`) surfaced once during the first full-suite run and then passed on the second run — unchanged status.

## Issues Encountered

- **Pre-existing Fake GenServer flake** — `fake_phase3_test.exs:transition/3 moves subscription to :canceled` failed once during the first full-suite run, then passed cleanly on the second. Passes in isolation. Tracked in `deferred-items.md`. Unchanged.

## Acceptance Criteria

Per plan `<acceptance_criteria>`:

| Criterion | Status |
| --- | --- |
| `grep -q 'defmodule Accrue.Webhook.ConnectHandler'` | PASS |
| `grep -q '"account.updated"'` | PASS |
| `grep -q '"account.application.deauthorized"'` | PASS |
| `grep -q '"capability.updated"'` | PASS |
| `grep -q '"payout.failed"'` | PASS |
| `grep -q 'force_status_changeset'` | PASS |
| `grep -q 'Connect.retrieve_account'` | PASS |
| `grep -q ':connect_account_deauthorized'` | PASS |
| `wc -l accrue/lib/accrue/webhook/connect_handler.ex` ≥ 120 | PASS (457) |
| `cd accrue && mix test test/accrue/webhook/connect_handler_test.exs` exits 0 | PASS (14/14) |
| `cd accrue && mix test test/accrue/webhook/connect_handler_test.exs --warnings-as-errors` exits 0 | PASS |
| `cd accrue && mix test` (full suite) | PASS (691 tests, 0 failures on second run) |
| VALIDATION rows 8, 9 pass | PASS |

## TDD Gate Compliance

Task 1 is marked `tdd="true"` and shipped as a single-commit `feat:` commit. Same rationale as Plans 05-01..05-05: a separate RED commit would contain tests referencing behavior on the unshipped reducers — tests that would fail to compile or fail with nonsense errors because the stub ConnectHandler returns `:ok` for everything. Tests were driven from the plan's `<behavior>` and `<acceptance_criteria>` sections and run against the reducer bodies in the same diff.

Real TDD RED gates did fire during the session, they just weren't committed as separate commits:
- First test run: 11/14 failing with `CaseClauseError` — caught the `:telemetry.span/3` return-type mismatch (deviation #1).
- Full-suite run after fix: 1 unrelated failure in dispatch_worker_test — caught the stub-assumption breakage (deviation #2).

Both were fixed before committing.

## User Setup Required

None — all behavior exercised through the Fake processor. Stripe adapter paths are unchanged by this plan.

## Threat Flags

None — the `<threat_model>` for Plan 05-06 covers the full net-new surface:

- **T-05-06-01 (Tampering — account.updated payload fields):** mitigated — the reducer never trusts the raw payload; it refetches canonical via `Connect.retrieve_account/2`, which runs through `Accrue.Connect.Projection.decompose/1` → `Account.force_status_changeset/2` (state-field allowlist only: `:charges_enabled`, `:details_submitted`, `:payouts_enabled`, `:capabilities`, `:requirements`, `:data`, `:deauthorized_at`). No cast on `:stripe_account_id`, `:type`, `:owner_*`.
- **T-05-06-02 (Repudiation — deauthorization with no local row):** mitigated — tombstones via `deauthorized_at` and retains the row for audit. If seeding fails entirely, the audit event is still recorded via `Events.record/1` and ops telemetry still fires so the signal never drops silently.
- **T-05-06-03 (DoS — retrieve_account storm):** accepted per plan — rate limiting is `lattice_stripe`'s concern; ConnectHandler does one retrieve per webhook, and Phase 2 DLQ bounds any storm.

## Next Plan Readiness

- **Plan 05-07 (Wave 2, guides + docs):** READY. The ConnectHandler module's `@moduledoc` is complete and references D5-01/D5-05 + Pitfall 3 + tombstoning behavior; `guides/connect.md` can link to it directly for the "Webhook reducer reference" section. All 14 reducer tests pass and serve as copy-pasteable examples for the host-side docs.

## Self-Check

- `accrue/lib/accrue/webhook/connect_handler.ex` exists (457 lines)
- `accrue/test/accrue/webhook/connect_handler_test.exs` exists (new file, 14 tests)
- `accrue/test/accrue/webhook/dispatch_worker_test.exs` modified (Plan 05-01 routing test event type updated)
- Commit `3a302af` FOUND via `git log --oneline`
- `mix test test/accrue/webhook/connect_handler_test.exs --warnings-as-errors` exits 0 (14/14)
- `mix test` (full suite) exits 0 on second run (691 tests / 44 properties / 0 failures)

## Self-Check: PASSED

---
*Phase: 05-connect*
*Completed: 2026-04-15*
