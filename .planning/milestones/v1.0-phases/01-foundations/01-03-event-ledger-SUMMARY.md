---
phase: 01-foundations
plan: 03-event-ledger
subsystem: foundations
tags: [elixir, ecto, postgres, event-ledger, immutability, trigger, sqlstate]
requirements: [EVT-01, EVT-02, EVT-03, EVT-07, EVT-08]
dependency_graph:
  requires:
    - "01-01 bootstrap (mix.exs, config/test.exs Accrue.TestRepo wiring, mox harness)"
    - "01-02 Accrue.Actor, Accrue.Telemetry.current_trace_id/0, Accrue.ConfigError"
  provides:
    - "accrue_events table with BEFORE UPDATE/DELETE trigger + actor_type CHECK"
    - "Accrue.Repo facade resolving host Repo at runtime (D-10)"
    - "Accrue.Events.Event insert-only schema (D-12)"
    - "Accrue.Events.record/1 and record_multi/3 API (D-13)"
    - "Accrue.EventLedgerImmutableError domain error"
    - "Accrue.RepoCase + Accrue.TestRepo integration test harness"
    - "REVOKE migration template for mix accrue.install (D-09, D-10)"
  affects:
    - "Phase 2 webhook plug will call Accrue.Events.record/1 for every inbound event"
    - "Phase 3 Billing context will compose Accrue.Events.record_multi/3 into Ecto.Multi pipelines"
    - "Phase 6 Accrue.Application boot check consumes Accrue.Config :enforce_immutability key"
tech_stack:
  added: []
  patterns:
    - "Append-only ledger via BEFORE UPDATE/DELETE trigger (SQLSTATE 45A01)"
    - "Defense-in-depth: trigger at row level + REVOKE grants template at role level"
    - "Postgrex error pattern-match on postgres.pg_code (not code, not message)"
    - "Partial unique index with unsafe_fragment conflict_target"
    - "Actor context auto-capture via process dictionary"
    - "Library without a Repo — test_helper.exs starts Accrue.TestRepo globally"
key_files:
  created:
    - accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs
    - accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs
    - accrue/lib/accrue/repo.ex
    - accrue/lib/accrue/events.ex
    - accrue/lib/accrue/events/event.ex
    - accrue/lib/accrue/events/ledger_immutable_error.ex
    - accrue/test/support/test_repo.ex
    - accrue/test/support/repo_case.ex
    - accrue/test/accrue/events/record_test.exs
    - accrue/test/accrue/events/immutability_test.exs
  modified:
    - accrue/test/test_helper.exs
decisions:
  - "Postgrex 0.22 surfaces SQLSTATE 45A01 as postgres.pg_code \"45A01\" (string) with postgres.code = nil. Pattern match on pg_code (NOT code) — resolves Pitfall #2 definitively; smoke-tested before writing any pattern-match code."
  - "Partial unique index (UNIQUE idempotency_key WHERE idempotency_key IS NOT NULL) requires conflict_target: {:unsafe_fragment, \"(idempotency_key) WHERE idempotency_key IS NOT NULL\"} — Ecto's symbol-based :idempotency_key target raises 42P10 because Postgres's inference clause has to include the WHERE to match a partial index."
  - "Accrue.TestRepo is started once globally in test_helper.exs (not per-test in RepoCase setup). Lazy per-setup startup races across parallel test files when multiple cases call start_link(Accrue.TestRepo) in lockstep."
  - "Accrue.Repo.update/2 translates Postgrex.Error with pg_code 45A01 into Accrue.EventLedgerImmutableError. This keeps the domain-error wrapper at the facade layer so Plan 06's boot check and downstream callers both benefit."
metrics:
  duration_seconds: 320
  tasks_completed: 2
  files_created: 10
  files_modified: 1
  commits: 2
  tests: 18
  full_suite_tests: 91
  full_suite_properties: 6
completed_date: 2026-04-11
---

# Phase 01 Plan 03: Event Ledger Summary

**One-liner:** Append-only `accrue_events` table with dual-defense immutability (BEFORE UPDATE/DELETE trigger raising SQLSTATE 45A01 + REVOKE template stub), `Accrue.Events.record/1` + `record_multi/3` API auto-capturing actor + trace_id from process dictionary, idempotency-key dedup via partial-unique-index `ON CONFLICT DO NOTHING`, and 18 integration tests proving both raw SQL UPDATE/DELETE rejection and the `Accrue.EventLedgerImmutableError` domain-error wrap at the `Accrue.Repo` facade.

## What Shipped

### Task 1 — Migration, REVOKE template, test Repo harness (commit `ebe9193`)

- **`accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs`** — full schema per EVT-02:
  - `bigserial` primary key + 10 columns (`type, schema_version, actor_type, actor_id, subject_type, subject_id, data jsonb, trace_id, idempotency_key, inserted_at`).
  - `NOT NULL` on `subject_type/subject_id` (EVT-02 requires them); `data` defaults `'{}'::jsonb`.
  - Composite index on `(subject_type, subject_id, inserted_at)` for timeline queries.
  - Partial unique index on `idempotency_key WHERE idempotency_key IS NOT NULL` — lets internal callers omit the key without tripping uniqueness (D-14).
  - `ALTER TABLE ... ADD CONSTRAINT ... CHECK (actor_type IN ('user','system','webhook','oban','admin'))` — EVT-08 enforced at the DB layer.
  - `CREATE OR REPLACE FUNCTION accrue_events_immutable() RAISE SQLSTATE '45A01' USING MESSAGE = 'accrue_events is append-only; UPDATE and DELETE are forbidden'`.
  - `CREATE TRIGGER accrue_events_immutable_trigger BEFORE UPDATE OR DELETE ON accrue_events FOR EACH ROW EXECUTE FUNCTION accrue_events_immutable()`.
  - Full `down/0` reverses trigger, function, constraint, indexes, table.
- **`accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs`** — D-10 belt-and-suspenders. A template file (NOT auto-run) with a `@app_role "accrue_app"` constant the operator edits after `mix accrue.install` copies it into the host app. `up` executes `REVOKE UPDATE, DELETE, TRUNCATE ON accrue_events FROM accrue_app`; `down` reverses with `GRANT`. Header moduledoc explicitly documents the residual superuser bypass risk so Phase 8's install guide has something to point at.
- **`accrue/test/support/test_repo.ex`** — `use Ecto.Repo, otp_app: :accrue, adapter: Ecto.Adapters.Postgres`. Lives in `test/support/` (compiled only under `:test` per `elixirc_paths(:test)` in `mix.exs`) so production release artifacts never ship a library-owned Repo — D-10 is non-negotiable.
- **`accrue/test/support/repo_case.ex`** — `Accrue.RepoCase` ExUnit case template. `setup/1` calls `Ecto.Adapters.SQL.Sandbox.start_owner!/2` with shared-mode fan-out by default (`shared: not tags[:async]`), registers an `on_exit` that calls `stop_owner`. Repo is started globally in `test_helper.exs`, not per-test — see the "Lazy-start race" deviation below.
- **Verification:** `cd accrue && MIX_ENV=test mix ecto.create && mix ecto.migrate` succeeds end-to-end. Up/down/up migration cycle verified. `\d accrue_events` in `psql` confirms trigger, CHECK, partial unique index, and timeline index are all present on a fresh DB.

`config/test.exs` was untouched by this plan — Plan 01 Wave 0 pre-wired the full `Accrue.TestRepo` sandbox stanza, and `git diff` confirms no modification.

### Task 2 — `Accrue.Events.record/1` + `record_multi/3` + immutability integration test (commit `0e31d92`)

- **`Accrue.Repo`** (`lib/accrue/repo.ex`) — the facade. Resolves `Application.get_env(:accrue, :repo)` at **call time**, raising `Accrue.ConfigError` with a targeted message when unset. Re-exports `transact/2`, `insert/2`, `all/2`, `one/2`, `update/2`. `update/2` wraps in a `rescue Postgrex.Error` that pattern-matches `pg_code: "45A01"` (or the atom alias `:accrue_event_immutable`, if a future Postgrex version assigns one) and re-raises `Accrue.EventLedgerImmutableError`. This is how callers get a clean domain error instead of the raw Postgrex shape.
- **`Accrue.EventLedgerImmutableError`** (`lib/accrue/events/ledger_immutable_error.ex`) — `defexception [:message, :event_id, :operation, :pg_code]` with derived `message/1`. Moduledoc documents the dual-defense model and points at the REVOKE template.
- **`Accrue.Events.Event`** (`lib/accrue/events/event.ex`) — `use Ecto.Schema`, 11 fields matching the table. `@primary_key {:id, :id, autogenerate: true}` for bigserial. `inserted_at` uses `read_after_writes: true` so Postgres's `now()` default populates the struct after insert. `changeset/1` casts all writable fields, validates `[:type, :actor_type, :subject_type, :subject_id]` required, and `validate_inclusion(:actor_type, ~w[user system webhook oban admin])` as the Ecto-layer pair to the DB CHECK constraint. **No `update_changeset/2`, no `delete/1`** (D-12) — verified by `grep -E "def (update|delete)"` returning nothing.
- **`Accrue.Events`** (`lib/accrue/events.ex`) — the public API:
  - `record/1`:
    1. `normalize/1` merges in actor context (precedence: caller-supplied `:actor_type` > caller-supplied `:actor` map > `Accrue.Actor.current()` > `"system"` fallback with `actor_id: nil`).
    2. Merges `trace_id` from `Accrue.Telemetry.current_trace_id/0` when caller omits it.
    3. Defaults `schema_version: 1` and `data: %{}`.
    4. Builds `Event.changeset/1` and routes to `Accrue.Repo.insert/2`.
    5. With `:idempotency_key` present: uses `insert_opts/1` returning `[on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}, returning: true]`. Conflict no-op path (`{:ok, %Event{id: nil}}`) falls through to `fetch_by_idempotency_key/1` which re-reads the winning row.
    6. Wrapped in `rescue err in Postgrex.Error → reraise_if_immutable/2` that translates `pg_code: "45A01"` into `Accrue.EventLedgerImmutableError`. Non-45A01 Postgrex errors re-raise unchanged.
  - `record_multi/3`: same normalization + changeset path, but composes into `Ecto.Multi.insert/4` with the same `insert_opts/1`. The multi-arity form is what Phase 2+ will use for `Billing.subscribe/2` to co-commit state mutation and event in one transaction.
- **`accrue/test/accrue/events/record_test.exs`** — 11 tests covering minimal round-trip, `Accrue.Actor.current/0` injection, `:actor` override, direct `:actor_type/:actor_id` override, data payload round-trip, duplicate `idempotency_key` returning existing row, missing-required errors, invalid-actor-type Ecto validation, caller `:trace_id` preservation, `Ecto.Multi` pipeline insert, and `record_multi` with idempotency-key ON CONFLICT uniqueness scoped by `where: idempotency_key == ^key`.
- **`accrue/test/accrue/events/immutability_test.exs`** — 7 tests covering: raw `Accrue.TestRepo.query("UPDATE accrue_events SET type = ...")` returning `Postgrex.Error{postgres: %{pg_code: "45A01"}}`; raw `DELETE` same; `Accrue.Repo.update/2` re-raising `Accrue.EventLedgerImmutableError` with message matching `~r/append-only/`; raw SQL INSERT with `actor_type='root'` raising `%Postgrex.Error{postgres: %{code: :check_violation, constraint: "accrue_events_actor_type_check"}}`; `Accrue.Events.record` rejecting `actor_type: "root"` at the changeset layer (no DB trip); partial-unique-index correctness (two records with the same non-nil key collapse to one; two with `nil` keys both insert — partial index semantics).
- **`test/test_helper.exs`** — added `Accrue.TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox)` and `Sandbox.mode(Accrue.TestRepo, :manual)` before `ExUnit.start()`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Partial unique index needs `{:unsafe_fragment, ...}` conflict_target, not `:idempotency_key` atom**

- **Found during:** Task 2, first `mix test test/accrue/events/` run.
- **Issue:** The plan said `conflict_target: :idempotency_key`. Ecto translates that to `ON CONFLICT (idempotency_key)` which Postgres rejects with `42P10 invalid_column_reference` because our index is partial (`WHERE idempotency_key IS NOT NULL`) and Postgres requires the inference clause to include the exact WHERE predicate.
- **Fix:** Introduced `insert_opts/1` returning `conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}`. Shared between `record/1` and `record_multi/3` so both paths use the same conflict specification. Tests now exercise the partial-index semantics correctly (non-nil keys dedupe; nil keys don't).
- **Files modified:** `accrue/lib/accrue/events.ex`
- **Commit:** `0e31d92`

**2. [Rule 1 - Bug] Postgrex 0.22 surfaces SQLSTATE 45A01 on `pg_code`, NOT `code`**

- **Found during:** Pre-Task-2 smoke test (the plan's Pitfall #2 directive: "smoke-test the exact Postgrex shape first").
- **Issue:** I ran a direct `TestRepo.query("UPDATE accrue_events ...")` via `mix run` and inspected `%Postgrex.Error{postgres: pg}`. The real shape is `postgres: %{code: nil, pg_code: "45A01", message: "accrue_events is append-only; ...", severity: "ERROR", routine: "exec_stmt_raise", ...}`. The plan's draft pattern-match on `code: :accrue_event_immutable` would have silently never fired.
- **Fix:** Pattern-match on `postgres: %{pg_code: "45A01"}` as the primary clause, keeping the atom clause (`postgres: %{code: :accrue_event_immutable}`) as a forward-compat fallback. Both immutability tests assert `pg.pg_code == "45A01" or pg.code == :accrue_event_immutable` so a future Postgrex version that assigns an atom stays green.
- **Files modified:** `accrue/lib/accrue/events.ex`, `accrue/lib/accrue/repo.ex`
- **Commit:** `0e31d92` (+ the probe evidence was what let me write the correct code in the first pass)

**3. [Rule 3 - Blocker] Lazy-start Accrue.TestRepo race across parallel test files**

- **Found during:** Task 2, running `mix test` (the full suite) after `mix test test/accrue/events/` passed in isolation.
- **Issue:** `Accrue.RepoCase.start_test_repo/0` originally lazy-started `Accrue.TestRepo` inside the per-test `setup/1`. Under ExUnit's parallel test file scheduling, two cases can race on `Process.whereis(Accrue.TestRepo)` and both attempt `start_link/1`, producing `{:error, {:already_started, pid}}` or a connection-pool teardown mid-test. Symptom was `RuntimeError: could not lookup Ecto repo Accrue.TestRepo because it was not started`.
- **Fix:** Moved `Accrue.TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox)` + `Sandbox.mode(:manual)` to `test/test_helper.exs`, before `ExUnit.start()`. Per-test setup only calls `start_owner!/2` to check out a connection. This is the idiomatic Phoenix `ecto.gen.repo` pattern — the dev/prod Repo is in the supervision tree; tests that share a library-owned Repo need the same "start once" semantics. Accrue ships without an app supervisor (Plan 06 adds it later, and even then won't own the test Repo), so `test_helper.exs` is the right place.
- **Files modified:** `accrue/test/test_helper.exs`, `accrue/test/support/repo_case.ex` (removed the lazy-start branch)
- **Commit:** `0e31d92`

### Rule 4 — Architectural changes

None. All three deviations are straightforward wiring fixes — none touch the plan's architectural decisions (D-09 through D-16).

## Threat Register Status

- **T-EVT-01 (Tampering: post-insert row mutation):** mitigated. `accrue_events_immutable_trigger` is installed by the migration (verified via `\d accrue_events`) and two integration tests assert both `UPDATE` and `DELETE` paths are rejected with `Postgrex.Error pg_code: "45A01"`. The REVOKE template ships for operators as the second layer.
- **T-EVT-02 (Repudiation: missing actor):** mitigated. The `actor_type` CHECK constraint is installed and tested (`actor_type='root'` raises `check_violation`). The Ecto `validate_inclusion` is a second layer that catches bad actors before a DB round-trip. Default fallback is `"system"` only when the process dict has no actor — never silently omitted.
- **T-EVT-03 (Information Disclosure: PII in `data`):** accepted per the plan's threat model. Phase 1 does NOT sanitize the jsonb column; the `Accrue.Events` moduledoc loudly documents that callers MUST NOT put payment-method PII in `data`. A future redactor is deferred.
- **T-EVT-04 (Tampering: idempotency replay):** mitigated. Partial unique index + `ON CONFLICT DO NOTHING` + `fetch_by_idempotency_key/1` fallback ensures duplicate keys collapse to a single row. The integration test "two records with the same non-nil key collapse to one row" asserts this at both the API and DB level.
- **T-EVT-05 (DoS: oversize `data` jsonb):** accepted; Phase 4 ops telemetry will surface oversize events.

## Verification Results

```
cd accrue && MIX_ENV=test mix ecto.drop --quiet ; MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate
  # migration applies; trigger, function, CHECK, indexes all created

cd accrue && MIX_ENV=test mix compile --warnings-as-errors  # clean
cd accrue && MIX_ENV=test mix test test/accrue/events/       # 18 tests, 0 failures
cd accrue && MIX_ENV=test mix test                            # 91 tests, 6 properties, 0 failures

grep -q "SQLSTATE '45A01'" accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs        # present
grep -q "accrue_events_immutable_trigger" accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs  # present
grep -q "actor_type IN ('user','system','webhook','oban','admin')" accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs  # present
grep -q "REVOKE UPDATE, DELETE, TRUNCATE" accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs  # present
grep -q "45A01" accrue/lib/accrue/events.ex                                                            # present
grep -q "Accrue.EventLedgerImmutableError" accrue/lib/accrue/events.ex                                 # present
grep -q "on_conflict: :nothing" accrue/lib/accrue/events.ex                                            # present
grep -q "Accrue.Actor.current" accrue/lib/accrue/events.ex                                             # present (via alias Accrue.Actor + Actor.current/0)
grep -q "Accrue.Telemetry.current_trace_id" accrue/lib/accrue/events.ex                                # present (via alias Accrue.Telemetry + Telemetry.current_trace_id/0)
grep -E "def (update|delete)" accrue/lib/accrue/events/event.ex                                        # empty (D-12)
git diff main~3 -- accrue/config/test.exs                                                               # empty (Plan 01 owns the wiring)
test -f accrue/lib/accrue/test_repo.ex                                                                 # absent (test_repo lives under test/support — D-10)
```

All green.

## Success Criteria Met

Phase 2's webhook plumbing can now:

- `alias Accrue.Events` and call `Events.record(%{type: ..., subject_type: ..., subject_id: ..., idempotency_key: stripe_event_id})` to idempotently persist inbound Stripe events — replays collapse to the existing row.
- Compose `Events.record_multi(multi, :event, attrs)` into any `Ecto.Multi` pipeline and commit state + event atomically via `Accrue.Repo.transact/1`.
- Rely on `Accrue.Actor.put_current(%{type: :webhook, id: event_id})` upstream of the record call to get actor stamping for free — no explicit passthrough required.
- Rely on `Accrue.Telemetry.current_trace_id/0` to populate the `trace_id` column when `:opentelemetry` is loaded — zero boilerplate.
- Trust that any `UPDATE accrue_events` or `DELETE FROM accrue_events` anywhere in the application (including misconfigured migrations or admin tooling) is rejected at the row level with `Accrue.EventLedgerImmutableError`.

## Known Stubs

None. Every shipped module is fully functional and exercised by integration tests against a real Postgres instance:

- Migration applies cleanly up/down/up.
- `Accrue.Events.Event` schema round-trips through `Accrue.TestRepo`.
- `Accrue.Events.record/1` happy path, actor injection, trace_id capture, idempotency dedup all green.
- `Accrue.Events.record_multi/3` integrates with `Ecto.Multi`.
- `Accrue.Repo.update/2` re-raises `Accrue.EventLedgerImmutableError` with the correct message on attempted mutation.
- REVOKE migration template is a deliberate stub (it's a template; `@app_role` is the only line an operator edits) — this is intended, not a missing wiring.

The REVOKE template is NOT run by Phase 1 — it ships for `mix accrue.install` in Phase 8 to copy into the host app, per plan D-10 and RESEARCH §Open Q2. Phase 1's defense-in-depth comes from the trigger alone; the REVOKE stub is the second layer operators opt into when they're ready.

## Self-Check: PASSED

- `accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs` — FOUND
- `accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs` — FOUND
- `accrue/lib/accrue/repo.ex` — FOUND
- `accrue/lib/accrue/events.ex` — FOUND
- `accrue/lib/accrue/events/event.ex` — FOUND
- `accrue/lib/accrue/events/ledger_immutable_error.ex` — FOUND
- `accrue/test/support/test_repo.ex` — FOUND
- `accrue/test/support/repo_case.ex` — FOUND
- `accrue/test/accrue/events/record_test.exs` — FOUND
- `accrue/test/accrue/events/immutability_test.exs` — FOUND
- `accrue/test/test_helper.exs` — MODIFIED (Accrue.TestRepo global startup)
- Commit `ebe9193` — FOUND
- Commit `0e31d92` — FOUND
- `mix compile --warnings-as-errors` — green
- `mix test test/accrue/events/` — 18 tests, 0 failures
- `mix test` (full suite) — 91 tests + 6 properties, 0 failures
