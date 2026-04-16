---
phase: 01-foundations
plan: 03
type: execute
wave: 2
depends_on: [01, 02]
files_modified:
  - accrue/lib/accrue/events.ex
  - accrue/lib/accrue/events/event.ex
  - accrue/lib/accrue/events/ledger_immutable_error.ex
  - accrue/lib/accrue/repo.ex
  - accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs
  - accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs
  - accrue/test/support/repo_case.ex
  - accrue/test/support/test_repo.ex
  - accrue/test/accrue/events/immutability_test.exs
  - accrue/test/accrue/events/record_test.exs
autonomous: true
requirements: [EVT-01, EVT-02, EVT-03, EVT-07, EVT-08]
security_enforcement: enabled
tags: [elixir, ecto, postgres, event-ledger, immutability, trigger]
must_haves:
  truths:
    - "A row inserted into accrue_events CANNOT be updated by a normal SQL UPDATE — attempt raises SQLSTATE 45A01"
    - "A row inserted into accrue_events CANNOT be deleted — attempt raises SQLSTATE 45A01"
    - "Accrue.Repo wrapper catches the SQLSTATE and re-raises Accrue.EventLedgerImmutableError (no message-string parsing)"
    - "Accrue.Events.record/1 writes one row with required fields and returns {:ok, %Event{}}"
    - "Accrue.Events.record/1 with a duplicate idempotency_key returns the existing row (on_conflict: :nothing behavior)"
    - "Accrue.Events.record_multi/3 integrates with Ecto.Multi pipelines"
    - "Actor type is enforced by PG CHECK constraint: inserting actor_type='root' raises check_violation"
    - "trace_id column is auto-populated from Accrue.Telemetry.current_trace_id/0 when set"
  artifacts:
    - path: "accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs"
      provides: "accrue_events table + trigger + actor_type CHECK + indexes"
      contains: "accrue_events_immutable"
      min_lines: 40
    - path: "accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs"
      provides: "REVOKE stub migration for mix accrue.install (D-10)"
      contains: "REVOKE UPDATE, DELETE, TRUNCATE"
    - path: "accrue/lib/accrue/events/event.ex"
      provides: "Ecto.Schema for reads + changeset/2 for writes; NO update/delete helpers (D-12)"
    - path: "accrue/lib/accrue/events.ex"
      provides: "record/1 + record_multi/3 + Postgrex error translation"
      contains: "record_multi"
    - path: "accrue/lib/accrue/repo.ex"
      provides: "Thin wrapper around the host-configured Repo; resolves via Accrue.Config.get!(:repo)"
  key_links:
    - from: "accrue/lib/accrue/events.ex"
      to: "accrue/lib/accrue/repo.ex"
      via: "Accrue.Repo.transact/1 for atomic event+state writes"
      pattern: "Accrue\\.Repo\\.transact"
    - from: "accrue/lib/accrue/events.ex"
      to: "Accrue.Telemetry.current_trace_id/0"
      via: "trace_id auto-capture on record/1"
      pattern: "current_trace_id"
    - from: "accrue/lib/accrue/events.ex"
      to: "Accrue.Actor.current/0"
      via: "actor_type + actor_id auto-captured from process dict when caller does not override"
      pattern: "Accrue\\.Actor\\.current"
    - from: "PG trigger"
      to: "Accrue.EventLedgerImmutableError"
      via: "SQLSTATE 45A01 → Postgrex.Error → pattern match → reraise"
      pattern: "45A01"
---

<objective>
Ship the append-only event ledger: table, trigger, REVOKE stub, Ecto schema, and the `Accrue.Events.record/1` + `record_multi/3` API. Enforce immutability at BOTH the Postgres trigger layer AND via a REVOKE migration stub (D-09 defense in depth). Pattern-match Postgrex errors by SQLSTATE code, never by message string (D-11).

Purpose: Every Phase 2+ state mutation emits a corresponding event in the SAME transaction as the mutation. If this plan ships correctly, Phase 2's webhook plumbing and Phase 3's subscription lifecycle already have a tamper-evident audit trail.
Output: A working ledger against a test Postgres instance, with immutability proven by a destructive test that attempts UPDATE/DELETE and expects `Accrue.EventLedgerImmutableError`.

**Wave-2 file discipline:** This plan does NOT edit `accrue/config/test.exs` — Plan 01 (Wave 0) pre-wired the full `Accrue.TestRepo` sandbox stanza there. This plan only CREATES the `Accrue.TestRepo` module in `test/support/test_repo.ex` and the migration files. Wave 2 parallel plans 03/04/05 have zero shared files by construction.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/01-foundations/01-CONTEXT.md
@.planning/phases/01-foundations/01-RESEARCH.md
@CLAUDE.md
@accrue/lib/accrue/config.ex
@accrue/lib/accrue/actor.ex
@accrue/lib/accrue/telemetry.ex
@accrue/lib/accrue/errors.ex
@accrue/config/test.exs

<interfaces>
<!-- Contracts this plan CREATES. Downstream plans (Phase 2 Billing context) will call these. -->

From accrue/lib/accrue/events.ex:
```elixir
defmodule Accrue.Events do
  @type attrs :: %{
          required(:type) => String.t(),
          required(:subject_type) => String.t(),
          required(:subject_id) => String.t(),
          optional(:schema_version) => integer(),
          optional(:actor) => Accrue.Actor.t(),
          optional(:data) => map(),
          optional(:idempotency_key) => String.t()
        }

  @spec record(attrs()) :: {:ok, Accrue.Events.Event.t()} | {:error, term()}
  def record(attrs)

  @spec record_multi(Ecto.Multi.t(), atom(), attrs()) :: Ecto.Multi.t()
  def record_multi(multi, name, attrs)
end
```

From accrue/lib/accrue/events/event.ex:
```elixir
defmodule Accrue.Events.Event do
  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer(),
          type: String.t(),
          schema_version: integer(),
          actor_type: String.t(),
          actor_id: String.t() | nil,
          subject_type: String.t(),
          subject_id: String.t(),
          data: map(),
          trace_id: String.t() | nil,
          idempotency_key: String.t() | nil,
          inserted_at: DateTime.t()
        }

  @primary_key {:id, :id, autogenerate: true}
  schema "accrue_events" do
    field :type, :string
    field :schema_version, :integer, default: 1
    field :actor_type, :string
    field :actor_id, :string
    field :subject_type, :string
    field :subject_id, :string
    field :data, :map, default: %{}
    field :trace_id, :string
    field :idempotency_key, :string
    field :inserted_at, :utc_datetime_usec, read_after_writes: true
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs)
  # NOTE: NO update/delete helpers exposed (D-12)
end
```

From accrue/lib/accrue/repo.ex:
```elixir
defmodule Accrue.Repo do
  @moduledoc """
  Thin facade over the host-configured Ecto.Repo. Resolves the Repo via
  `Application.get_env(:accrue, :repo)` at call time (runtime resolve) so
  tests can inject `Accrue.TestRepo` via config/test.exs without recompiling.
  """

  @spec transact((-> any())) :: {:ok, any()} | {:error, any()}
  def transact(fun), do: repo().transact(fun)

  @spec insert(Ecto.Changeset.t(), keyword()) :: {:ok, any()} | {:error, any()}
  def insert(changeset, opts \\ []), do: repo().insert(changeset, opts)

  defp repo, do: Application.get_env(:accrue, :repo) || raise Accrue.ConfigError, key: :repo, message: "config :accrue, :repo, MyApp.Repo required"
end
```

Config keys this plan READS (never writes — Plan 02 owns the schema, Plan 01 wired the test values):
- `:accrue, :repo` (from config/test.exs → `Accrue.TestRepo`)
- `:accrue, Accrue.TestRepo` (sandbox config from config/test.exs)
- `:accrue, :ecto_repos` (from config/test.exs)
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Migration + test Repo module (config/test.exs already wired by Plan 01)</name>
  <read_first>
    - .planning/phases/01-foundations/01-RESEARCH.md §Pattern 3 (full migration body)
    - .planning/phases/01-foundations/01-RESEARCH.md §Pitfall 2 (Postgrex SQLSTATE mapping — verify string vs atom)
    - .planning/phases/01-foundations/01-CONTEXT.md D-09, D-10, D-11
    - accrue/config/test.exs (Plan 01 Wave 0 pre-wired Accrue.TestRepo sandbox — this plan consumes it)
    - hexdocs.pm/ecto_sql Ecto.Adapters.SQL.Sandbox
  </read_first>
  <files>
    accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs
    accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs
    accrue/test/support/test_repo.ex
    accrue/test/support/repo_case.ex
  </files>
  <action>
1. **`accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs`** — use the full migration body from RESEARCH.md §Pattern 3. Key details:
   - `create table(:accrue_events, primary_key: false)` with `add :id, :bigserial, primary_key: true`.
   - All columns per EVT-02: `type, schema_version, actor_type, actor_id, subject_type, subject_id, data (jsonb), trace_id, idempotency_key, inserted_at (utc_datetime_usec default now())`.
   - `create index(:accrue_events, [:subject_type, :subject_id, :inserted_at])`.
   - `create unique_index(:accrue_events, [:idempotency_key], where: "idempotency_key IS NOT NULL")`.
   - `execute` the CHECK constraint for actor_type enum.
   - `execute` the `CREATE OR REPLACE FUNCTION accrue_events_immutable()` that `RAISE SQLSTATE '45A01' USING MESSAGE = 'accrue_events is append-only; UPDATE and DELETE are forbidden'`.
   - `execute` the `CREATE TRIGGER accrue_events_immutable_trigger BEFORE UPDATE OR DELETE ON accrue_events FOR EACH ROW EXECUTE FUNCTION accrue_events_immutable()`.
   - Full `down/0` drops trigger, function, table.

2. **`accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs`** — the REVOKE stub (D-10). This is a template file, NOT run automatically; `mix accrue.install` (Phase 8) copies it into host app. Use body from RESEARCH.md §Pattern 3 end. Add a comment header: "Generated by mix accrue.install — edit the role name to match your PG user. Belt+suspenders with the trigger in create_accrue_events.exs."

3. **`accrue/test/support/test_repo.ex`** — a test-only Repo used by the Phase 1 ledger integration tests. The library does NOT own a Repo in production (D-10 — host owns it), but tests need one:
   ```elixir
   defmodule Accrue.TestRepo do
     use Ecto.Repo, otp_app: :accrue, adapter: Ecto.Adapters.Postgres
   end
   ```
   Put it ONLY in `test/support/` so it's compiled only in `:test` env (Plan 01 set elixirc_paths for this). Document: this is a test fixture, not public API.

4. **config/test.exs is ALREADY wired by Plan 01** — do NOT edit it. Plan 01 Wave 0 added:
   ```elixir
   config :accrue, Accrue.TestRepo,
     database: "accrue_test#{System.get_env("MIX_TEST_PARTITION")}",
     pool: Ecto.Adapters.SQL.Sandbox,
     pool_size: 10,
     username: System.get_env("PGUSER", "postgres"),
     password: System.get_env("PGPASSWORD", "postgres"),
     hostname: System.get_env("PGHOST", "localhost"),
     priv: "priv/repo"

   config :accrue, ecto_repos: [Accrue.TestRepo]
   config :accrue, :repo, Accrue.TestRepo
   ```
   Verify these lines exist in `accrue/config/test.exs` before running `mix ecto.create`. If they're missing, Plan 01 was not applied correctly — STOP and escalate.

5. **`accrue/test/support/repo_case.ex`** — `Accrue.RepoCase` using `ExUnit.CaseTemplate`, Sandbox mode setup, `checkout` on setup, `sandbox_mode(:manual)` on start. Modeled on the stock Ecto `data_case.ex` template but stripped to essentials. Starts `Accrue.TestRepo` via `start_supervised!/1` in the setup block (no library-level supervisor).

6. **Create the test database**: run `cd accrue && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate` as the verify step. If Postgres is not available locally, the migration fails loudly — that's the signal to the user per RESEARCH.md §Environment Availability (PostgreSQL is a Phase 1 prereq).

The `Accrue.TestRepo` MUST live in `test/support/` (not `lib/`) so production builds don't ship a Repo with the library (D-10 is strict: host owns Repo).
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && grep -q "Accrue.TestRepo" config/test.exs && MIX_ENV=test mix ecto.drop --quiet 2>/dev/null ; MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate 2>&1 | tail -20</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "SQLSTATE '45A01'" accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs`
    - `grep -q "accrue_events_immutable_trigger" accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs`
    - `grep -q "actor_type IN ('user','system','webhook','oban','admin')" accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs`
    - `grep -q "REVOKE UPDATE, DELETE, TRUNCATE" accrue/priv/accrue/templates/migrations/revoke_accrue_events_writes.exs`
    - `MIX_ENV=test mix ecto.migrate` succeeds and the trigger exists in `pg_trigger`
    - `accrue/test/support/test_repo.ex` exists; `accrue/lib/` contains NO `test_repo.ex` or production Repo file
    - Plan did NOT modify `accrue/config/test.exs` (git diff shows no changes to that file)
  </acceptance_criteria>
  <done>Migration applies cleanly against a fresh test database; trigger + CHECK + REVOKE template all present; test.exs untouched (Plan 01 pre-wired).</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Accrue.Events.Event schema + Accrue.Events.record/1 + Accrue.Repo facade + immutability integration test</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-11, D-12, D-13, D-14, D-15, D-16
    - .planning/phases/01-foundations/01-RESEARCH.md §Pattern 4 (Postgrex error pattern-matching)
    - .planning/phases/01-foundations/01-RESEARCH.md §Pitfall 2 (code may be string "45A01", not atom — VERIFY at impl time)
    - CLAUDE.md §Config Boundaries (Accrue.Repo uses runtime get_env for the :repo key)
  </read_first>
  <files>
    accrue/lib/accrue/repo.ex
    accrue/lib/accrue/events/event.ex
    accrue/lib/accrue/events/ledger_immutable_error.ex
    accrue/lib/accrue/events.ex
    accrue/test/accrue/events/record_test.exs
    accrue/test/accrue/events/immutability_test.exs
  </files>
  <behavior>
    - `Accrue.Events.record(%{type: "subscription.created", subject_type: "Subscription", subject_id: "sub_123"})` returns `{:ok, %Event{}}` with `actor_type: "system"` (default from Accrue.Actor.current/0 fallback)
    - `Accrue.Actor.put_current(%{type: :webhook, id: "evt_X"}) ; Accrue.Events.record(%{...})` yields a row with `actor_type: "webhook", actor_id: "evt_X"`
    - Setting `Accrue.Telemetry.current_trace_id/0` (via a process-dict override for testability, or via `:seq_trace`) makes the `trace_id` column populate
    - Duplicate `idempotency_key` returns the EXISTING row (via `on_conflict: :nothing` + `conflict_target: :idempotency_key` + manual fetch fallback)
    - `Accrue.Events.record_multi(Ecto.Multi.new(), :event, attrs) |> Accrue.Repo.transact/1` writes the event atomically
    - **Immutability test**: after inserting one event, `Accrue.TestRepo.query!("UPDATE accrue_events SET type = 'x' WHERE id = $1", [event.id])` raises `Postgrex.Error` with `postgres.code` equal to `"45A01"` (or the atom `:accrue_event_immutable` — VERIFY which)
    - The `Accrue.Repo` wrapper `insert/2` catches the Postgrex error and re-raises `Accrue.EventLedgerImmutableError` (for downstream callers; the direct raw SQL test asserts on the underlying Postgrex error)
    - Inserting with `actor_type: "root"` raises a Postgrex `check_violation` (the PG CHECK constraint on actor_type)
  </behavior>
  <action>
1. `lib/accrue/repo.ex`: the facade per `<interfaces>` block. Use `Application.get_env(:accrue, :repo)` at call time (runtime resolve) so tests can inject `Accrue.TestRepo` via config. Also export `insert/2`, `transact/1`, `all/2`, `one/2` as thin passthroughs.

2. `lib/accrue/events/ledger_immutable_error.ex`:
   ```elixir
   defmodule Accrue.EventLedgerImmutableError do
     defexception [:message, :event_id, :operation]
   end
   ```

3. `lib/accrue/events/event.ex`: the Ecto schema per `<interfaces>`. `changeset/2`:
   - `cast` type, schema_version, actor_type, actor_id, subject_type, subject_id, data, trace_id, idempotency_key.
   - `validate_required([:type, :actor_type, :subject_type, :subject_id])`.
   - `validate_inclusion(:actor_type, ~w[user system webhook oban admin])`.
   - NO `update_changeset`, NO `delete` helpers (D-12).

4. `lib/accrue/events.ex`:
   - `record/1`:
     - Merge in `actor_type`/`actor_id` from `Accrue.Actor.current/0 || %{type: :system, id: nil}` unless caller passed `:actor`.
     - Merge `trace_id: Accrue.Telemetry.current_trace_id()`.
     - `schema_version: attrs[:schema_version] || 1`.
     - Build `Event.changeset/2`.
     - If `idempotency_key` present: `Accrue.Repo.insert(changeset, on_conflict: :nothing, conflict_target: :idempotency_key, returning: true)` — if insert returns a struct with `id: nil` (conflict no-op path in some adapters), fetch the existing row by the idempotency_key.
     - Else: `Accrue.Repo.insert(changeset)`.
     - Wrap in try/rescue for `Postgrex.Error` matching the immutable trigger. Per Pitfall #2, pattern match BOTH `%Postgrex.Error{postgres: %{code: :accrue_event_immutable}}` AND `%Postgrex.Error{postgres: %{code: "45A01"}}` — whichever fires, re-raise `Accrue.EventLedgerImmutableError`.
   - `record_multi/3`:
     ```elixir
     def record_multi(multi, name, attrs) do
       attrs = normalize(attrs)
       changeset = Event.changeset(attrs)
       Ecto.Multi.insert(multi, name, changeset,
         on_conflict: :nothing,
         conflict_target: :idempotency_key,
         returning: true
       )
     end
     ```

5. `test/accrue/events/record_test.exs`: uses `Accrue.RepoCase`, async: false (sandbox). Cases:
   - Minimal attrs round-trip.
   - Actor auto-populated from process dict.
   - trace_id populated (set via test helper that puts a known trace_id into process dict).
   - Duplicate idempotency_key: returns same row (or `:ok` with the same id).
   - `record_multi/3` inside `Ecto.Multi.new() |> record_multi(:evt, ...) |> Accrue.Repo.transact/1` commits.

6. `test/accrue/events/immutability_test.exs`: uses `Accrue.RepoCase`, async: false. Cases:
   - Insert one event. Attempt raw `Accrue.TestRepo.query("UPDATE accrue_events SET type = 'x' WHERE id = $1", [id])`. Assert `{:error, %Postgrex.Error{postgres: %{code: code}}}` where `code == "45A01"` OR `code == :accrue_event_immutable` (accept either — test both paths).
   - Attempt raw DELETE — same assertion.
   - Insert with `actor_type: "root"`: expect check constraint violation.
   - Insert via `Accrue.Events.record/1` (happy path), then attempt `Accrue.Repo.update(changeset)` — assert it raises `Accrue.EventLedgerImmutableError` (the high-level wrap).

**Smoke-test the exact Postgrex shape first**: run one quick IEx session or an early test that prints the `%Postgrex.Error{}` struct from the trigger — this determines whether the code is `"45A01"` string or a Postgrex-assigned atom, and fixes Pitfall #2 before other tests depend on the match shape.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && MIX_ENV=test mix test test/accrue/events/ --trace</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/events/record_test.exs` reports all tests passing
    - `mix test test/accrue/events/immutability_test.exs` reports all tests passing (both UPDATE and DELETE paths rejected)
    - `grep -q "45A01" accrue/lib/accrue/events.ex`
    - `grep -q "Accrue.EventLedgerImmutableError" accrue/lib/accrue/events.ex`
    - `grep -q "on_conflict: :nothing" accrue/lib/accrue/events.ex`
    - `grep -q "conflict_target: :idempotency_key" accrue/lib/accrue/events.ex`
    - `grep -q "Accrue.Actor.current" accrue/lib/accrue/events.ex`
    - `grep -q "Accrue.Telemetry.current_trace_id" accrue/lib/accrue/events.ex`
  </acceptance_criteria>
  <done>Event ledger is operational with immutability proven by destructive tests, idempotency dedup working, actor + trace_id auto-populated.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Application role → accrue_events table | DB role must not be able to tamper with audit trail |
| Webhook handler → Events.record | Replayed events must not double-write (idempotency) |
| Caller-supplied data map → jsonb column | Arbitrary JSON may contain PII or large blobs |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-EVT-01 | Tampering | accrue_events rows post-insert | mitigate | BEFORE UPDATE/DELETE trigger raising SQLSTATE 45A01 (D-09 primary defense); REVOKE stub template ships for host to run as belt-and-suspenders (D-10); both tested in Task 2 immutability_test.exs |
| T-EVT-02 | Repudiation | Missing actor context on events | mitigate | PG CHECK constraint enforces actor_type ∈ {user,system,webhook,oban,admin} (EVT-08); Ecto changeset validates same enum; defaults to `:system` only when process dict is empty (never silently omitted) |
| T-EVT-03 | Information Disclosure | PII in event.data jsonb | accept | Phase 1 does not automatically sanitize the data map — callers (Phase 2+) are responsible for redacting. Document in `Accrue.Events` moduledoc that sensitive fields MUST NOT be put in `data` at the call site. Phase 6 may add a redactor. |
| T-EVT-04 | Tampering | Replay attack via duplicate idempotency_key | mitigate | `UNIQUE (idempotency_key) WHERE idempotency_key IS NOT NULL` partial index + `on_conflict: :nothing` ensures double-writes collapse to a single row (D-14) |
| T-EVT-05 | Denial of Service | Large data jsonb blowing up row size | accept | Phase 1 does not enforce size limit; Phase 4 ops telemetry (OBS-03) will surface oversize events |
</threat_model>

<verification>
- `mix test test/accrue/events/` fully green, including destructive immutability tests
- `mix ecto.migrate` + `mix ecto.rollback` + `mix ecto.migrate` succeeds (up/down/up cycle)
- `grep -q "defp.*update\\|defp.*delete" accrue/lib/accrue/events/event.ex` returns nothing (D-12 — no update/delete helpers exposed)
- `grep -q "DELETE\\|UPDATE" accrue/lib/accrue/events.ex` returns only the error-handling references, not any actual update/delete calls
- `git diff accrue/config/test.exs` shows no changes from this plan (Plan 01 owns test.exs wiring)
</verification>

<success_criteria>
Phase 2's webhook plumbing plan can `use Accrue.Events` and emit rows transactionally with webhook state without modifying this plan's code. Phase 3's `Billing.subscribe/2` can wrap state mutations and `Events.record/1` in a single `Accrue.Repo.transact/1` block.
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundations/01-03-SUMMARY.md`.
</output>
