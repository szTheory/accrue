---
phase: 260621-idn
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue_admin/lib/accrue_admin/queries/cursor.ex
  - accrue_admin/test/accrue_admin/queries/cursor_test.exs
  - accrue_admin/test/accrue_admin/queries/events_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
autonomous: true
requirements: [QUICK-260621-idn]

must_haves:
  truths:
    - "/admin/events (mounted at /billing/events) no longer raises FunctionClauseError when more than 25 events exist — the page renders and paginates."
    - "Cursor.encode/2 and Cursor.decode/1 round-trip integer ids (the Event integer PK) as well as UUID ids."
    - "A regression spec seeds >25 events and proves the second page loads with no crash and no row overlap — the exact coverage gap that let the crash ship."
  artifacts:
    - path: "accrue_admin/lib/accrue_admin/queries/cursor.ex"
      provides: "Integer-or-binary id encode/decode (HMAC spine unchanged)"
      contains: "is_integer(id)"
    - path: "accrue_admin/test/accrue_admin/queries/cursor_test.exs"
      provides: "Integer-id round-trip test alongside the existing UUID test"
      contains: "is_integer"
    - path: "accrue_admin/test/accrue_admin/queries/events_test.exs"
      provides: ">25-event pagination regression: non-nil next_cursor decoding to {%DateTime{}, integer}, second page loads with no overlap"
      contains: "Events.list"
    - path: "accrue_admin/test/accrue_admin/live/events_live_test.exs"
      provides: "Live render of >25 events → 200 + Load more; trigger load-more → more rows"
      contains: "Load more"
  key_links:
    - from: "accrue_admin/lib/accrue_admin/queries/behaviour.ex"
      to: "accrue_admin/lib/accrue_admin/queries/cursor.ex"
      via: "paginate/3 calls Cursor.encode(last_row.inserted_at, last_row.id) where Event.id is an integer"
      pattern: "Cursor\\.encode"
    - from: "accrue_admin/lib/accrue_admin/queries/events.ex"
      to: "accrue_admin/lib/accrue_admin/queries/behaviour.ex"
      via: "Events.list passes through Behaviour.paginate → apply_cursor keyset on integer id"
      pattern: "Behaviour\\.(paginate|apply_cursor)"
---

<objective>
Fix the `/admin/events` crash: `FunctionClauseError` in `AccrueAdmin.Queries.Cursor.encode/2`.

The `Accrue.Events.Event` schema uses an **integer primary key** (`@primary_key {:id, :id, autogenerate: true}` — intentional per the append-only ledger design). Every other paginating admin schema uses a `:binary_id` (UUID). `Cursor.encode/2` is guarded `when is_binary(id)`, so when the events list overflows the DataTable page limit (25), `Behaviour.paginate/3` hands `Cursor.encode` the integer `event.id` and it raises. It only fires with >25 events, and **no test ever seeded that many** — a real coverage gap.

Purpose: close the crash AND the test gap that let it ship. Generalize the cursor id type to accept integers (no other core/API change), and add spec-driven regression coverage at three levels (Cursor unit, Events query pagination, events LiveView render + load-more).

Output: one atomic commit touching `cursor.ex` + three test files. No bundle rebuild (no CSS/JS). Do NOT edit `behaviour.ex`, `events.ex`, or the core `Event` schema. Do NOT convert the integer PK to UUID. Do NOT touch `examples/accrue_host/mix.lock` or `.planning/research/.cache/`. Do NOT update ROADMAP.md.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md

# The fix site (the ONLY production file edited):
@accrue_admin/lib/accrue_admin/queries/cursor.ex

# Read-only — confirm the keyset still compiles; do NOT edit:
@accrue_admin/lib/accrue_admin/queries/behaviour.ex
@accrue_admin/lib/accrue_admin/queries/events.ex
@accrue/lib/accrue/events/event.ex

# Spec files to extend / create:
@accrue_admin/test/accrue_admin/queries/cursor_test.exs
@accrue_admin/test/accrue_admin/live/events_live_test.exs

# Setup conventions to MIRROR (RepoCase base, insert helpers, Events.record/1):
@accrue_admin/test/accrue_admin/queries/query_modules_test.exs
@accrue_admin/test/support/repo_case.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Widen the cursor id to integers + spec-driven regression coverage (atomic)</name>
  <files>accrue_admin/lib/accrue_admin/queries/cursor.ex, accrue_admin/test/accrue_admin/queries/cursor_test.exs, accrue_admin/test/accrue_admin/queries/events_test.exs, accrue_admin/test/accrue_admin/live/events_live_test.exs</files>
  <behavior>
    Specs MUST fail pre-fix (prove the gap closes) and pass post-fix. Write the three test additions first, watch them fail, then apply the cursor.ex change, then watch them pass.

    - Cursor unit (extend cursor_test.exs): `Cursor.encode(ts, 16)` then `Cursor.decode/1` returns `{:ok, {ts, 16}}` where the decoded id is an integer. Keep the existing UUID round-trip and tamper-rejection tests intact.
    - Events query (new events_test.exs): seeding >25 events and calling `Events.list(limit: 25)` returns a non-nil `next_cursor` that decodes (via `AccrueAdmin.Queries.Cursor.decode/1`) to `{%DateTime{}, id}` with `is_integer(id)`. A second page via `Events.list(limit: 25, cursor: next_cursor)` returns rows with NO id overlap against page 1, and does not raise.
    - Events LiveView (extend events_live_test.exs): with >25 in-scope events seeded, `live(conn, "/billing/events")` returns `{:ok, view, html}` (200), `html =~ "Load more"`; rendering the `load-more` event (target the DataTable `#events` live_component) appends more rows.
  </behavior>
  <action>
THE FIX — `accrue_admin/lib/accrue_admin/queries/cursor.ex` ONLY:
- Widen the type: `@type value :: {DateTime.t(), Ecto.UUID.t() | integer()}`.
- `encode/2` guard: change `when is_binary(id)` to `when is_binary(id) or is_integer(id)`. Leave the `@spec`, the `:erlang.term_to_binary` payload, the HMAC `sign/1` call, and the Base64 join EXACTLY as-is — `term_to_binary` already round-trips integers. (Optionally relax the `@spec` id type to `Ecto.UUID.t() | integer()` to match; do not change behavior.)
- `decode/1`: relax the final validation step `true <- is_binary(id)` to `true <- is_binary(id) or is_integer(id)`. Keep the full `with` spine intact: `String.split`, both `Base.url_decode64`, `Plug.Crypto.secure_compare(signature, sign(payload))`, `:erlang.binary_to_term(payload, [:safe])`, and `DateTime.from_iso8601(timestamp)` are UNCHANGED — signature verification and timestamp parsing must remain exactly as they are.
- Do NOT edit `behaviour.ex` (`paginate/3` passes whatever `:id` the row has) or `events.ex`. After the change, confirm `apply_cursor/3`'s keyset `... or (field == ^timestamp and row.id < ^id)` still compiles — it compares the integer cursor id against the integer `event.id` column, which is correct. Run `cd accrue_admin && mix compile --warnings-as-errors`.

SPEC 1 — extend `accrue_admin/test/accrue_admin/queries/cursor_test.exs`:
- Add ONE test that encodes `{~U[...]Z, 16}` (a plain integer id) and asserts `Cursor.decode/1` returns `{:ok, {ts, id}}` with the decoded id an integer (e.g. assert `is_integer(id)` and `id == 16`). Place it alongside the existing UUID round-trip test. Do not modify the existing tests.

SPEC 2 — NEW `accrue_admin/test/accrue_admin/queries/events_test.exs` (MIRROR `query_modules_test.exs` conventions):
- `use AccrueAdmin.RepoCase, async: false` (the Ecto sandbox base used by `query_modules_test.exs`).
- `alias Accrue.Events`, `alias AccrueAdmin.Queries.{Cursor, Events, ...}` — note the module name collision: refer to `Accrue.Events` (the core context that records events) vs `AccrueAdmin.Queries.Events` (the admin query) explicitly to avoid alias ambiguity. Insert events via `Accrue.Events.record/1` (the same path `events_live_test.exs` uses), seeding 30 events with `type`, `subject_type: "Subscription"`, `subject_id` (any stable string), `actor_type: "admin"`, `actor_id: "admin_1"`. Use NO `owner_scope` (or `owner_scope: nil`) so the org-scope fragment is not applied and all rows are visible.
- Watch-out (DETERMINISTIC ORDERING): `Accrue.Events.Event.inserted_at` is `read_after_writes` (DB clock at insert), so several rows may share a microsecond timestamp. The query orders `desc: inserted_at, desc: id`, and the keyset cursor tiebreaks on the integer `id` — that integer tiebreak IS the code path under test, so DO NOT try to force distinct timestamps. Seeding sequentially gives ascending integer ids; the desc-id tiebreak guarantees a stable, non-overlapping split between page 1 and page 2.
- Assertions: `{rows1, next_cursor} = AccrueAdmin.Queries.Events.list(limit: 25)`; assert `length(rows1) == 25`, `is_binary(next_cursor)`, and `{:ok, {%DateTime{}, id}} = Cursor.decode(next_cursor)` with `is_integer(id)`. Then `{rows2, _} = AccrueAdmin.Queries.Events.list(limit: 25, cursor: next_cursor)`; assert `rows2 != []`, and `MapSet.disjoint?(MapSet.new(rows1, & &1.id), MapSet.new(rows2, & &1.id))` (no id overlap). The whole call MUST NOT raise (pre-fix it raises `FunctionClauseError` at the `paginate/3` → `Cursor.encode` boundary).

SPEC 3 — extend `accrue_admin/test/accrue_admin/live/events_live_test.exs` (MIRROR its existing conventions — `use AccrueAdmin.LiveCase, async: false`, the in-file `AuthAdapter`, `Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")`, mount path `/billing/events`):
- Add ONE test that seeds >25 in-scope events. Reuse the existing `setup` block's webhook/customer/invoice scaffolding only if needed; the simplest path is a global (no active-organization session) mount so the org-scope filter is not applied — match how the "always renders a 'By actor' chip" test mounts with just `admin_token: "admin"`. Seed the 26+ events via `Accrue.Events.record/1` inside the test (or a helper).
- Assert `{:ok, view, html} = live(conn, "/billing/events")` (200) and `html =~ "Load more"`. Then exercise load-more: the DataTable is a `live_component` with `id="events"` and `phx-click="load-more"`; render the click against that component (e.g. `view |> element("#events [data-role=\"load-more\"]") |> render_click()` — confirm the exact selector against `data_table.ex` lines ~314-320: `phx-click="load-more"`, `data-role="load-more"`). Assert the post-click render contains more event rows than the first page (e.g. a row count or a known seeded `type` string that only appears past row 25). This reproduces the exact reported crash and locks it.

COMMIT: one atomic commit — `cursor.ex` + the three test files together. Suggested message subject: `fix(admin): paginate integer-PK event ids in admin cursor`. No bundle rebuild. Do not stage `examples/accrue_host/mix.lock`, `.planning/research/.cache/`, or ROADMAP.md.
  </action>
  <verify>
    <automated>cd accrue_admin && mix compile --warnings-as-errors && mix test test/accrue_admin/queries/cursor_test.exs test/accrue_admin/queries/events_test.exs test/accrue_admin/live/events_live_test.exs</automated>
  </verify>
  <done>
    - `cursor.ex` encode/2 guard accepts `is_integer(id)`; decode/1 validation accepts integer ids; HMAC sign/verify + DateTime parse spine unchanged; `mix compile --warnings-as-errors` clean.
    - Integer-id round-trip test passes in `cursor_test.exs` (UUID + tamper tests still pass).
    - `events_test.exs` exists: >25 events → non-nil next_cursor decoding to `{%DateTime{}, integer}`, page-2 loads with no id overlap, no raise.
    - `events_live_test.exs` new test: `/billing/events` with >25 events renders 200 + "Load more"; load-more click yields more rows.
    - The three specs FAIL when run against the un-widened `cursor.ex` and PASS after the fix (gap-closure sanity confirmed).
    - One atomic commit; no bundle rebuild; ROADMAP.md / mix.lock / research cache untouched.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| client → admin LiveView | Pagination cursor arrives as a URL/param value (`?cursor=...`); it is HMAC-signed and must fail closed on tampering. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-idn-01 | Tampering | `Cursor.decode/1` | mitigate | The `with` spine keeps `Plug.Crypto.secure_compare(signature, sign(payload))` and `:erlang.binary_to_term(payload, [:safe])` UNCHANGED. Widening the id-type guard does NOT relax signature verification — a forged/tampered cursor still fails closed (`:error`). The existing tamper-rejection test in `cursor_test.exs` must remain green. |
| T-idn-02 | Elevation of Privilege | `AccrueAdmin.Queries.Events` org scope | accept | Widening the cursor id type does not touch the `scope_query/2` org-scope fragment in `events.ex`; the live regression test mounts without an active org (global view) only to exercise pagination, not to bypass scope. No scope change. |
</threat_model>

<verification>
- `cd accrue_admin && mix compile --warnings-as-errors` — clean (confirms `apply_cursor/3` integer keyset still compiles).
- `cd accrue_admin && mix test test/accrue_admin/queries/cursor_test.exs test/accrue_admin/queries/events_test.exs test/accrue_admin/live/events_live_test.exs` — all green.
- Sanity (optional but recommended): stash the `cursor.ex` edit, re-run the three spec files, confirm they FAIL (FunctionClauseError / decode mismatch), then restore the edit and confirm they PASS — proves the specs close the actual gap.
- Manual smoke (optional): `/billing/events` with >25 events renders and paginates without crashing.
</verification>

<success_criteria>
- `/admin/events` (`/billing/events`) renders and paginates with >25 events — no `FunctionClauseError`.
- `Cursor` round-trips integer ids (and still UUIDs) with signature verification intact.
- Three regression specs exist and pass; they fail against the pre-fix `cursor.ex`.
- One atomic commit (cursor.ex + 3 test files); no asset bundle rebuild; ROADMAP.md, `examples/accrue_host/mix.lock`, and `.planning/research/.cache/` untouched.
</success_criteria>

<output>
Create `.planning/quick/260621-idn-fix-admin-events-cursor-crash-integer-pk/260621-idn-SUMMARY.md` when done.
</output>
