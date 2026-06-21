---
phase: 260621-idn
plan: 01
subsystem: accrue_admin
status: complete
tags: [admin, pagination, cursor, events, bugfix, regression-test]
requires:
  - AccrueAdmin.Queries.Behaviour.paginate/3
  - Accrue.Events.record/1
provides:
  - "Cursor.encode/2 + decode/1 round-trip integer event-ledger PKs (and UUIDs)"
  - ">25-event admin pagination no longer raises FunctionClauseError"
affects:
  - accrue_admin/lib/accrue_admin/queries/cursor.ex
tech-stack:
  added: []
  patterns:
    - "Guard widening (is_binary or is_integer) on signed cursor id without touching HMAC spine"
key-files:
  created:
    - accrue_admin/test/accrue_admin/queries/events_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/queries/cursor.ex
    - accrue_admin/test/accrue_admin/queries/cursor_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
decisions:
  - "Generalize the cursor id type instead of converting the Event integer PK to UUID — preserves the append-only ledger design."
  - "Count rows via data-row-id (present on every row regardless of selectable) rather than toggle-row (only rendered when selectable)."
metrics:
  duration: ~12m
  completed: 2026-06-21
  tasks: 1
  files: 4
---

# Phase 260621-idn Plan 01: Fix admin events cursor crash (integer PK) Summary

Widened `AccrueAdmin.Queries.Cursor` to round-trip the integer primary key of the append-only event ledger (not just binary UUIDs), fixing the `/admin/events` (`/billing/events`) `FunctionClauseError` that fired only with >25 events, and added spec-driven regression coverage at three levels (Cursor unit, Events query pagination, LiveView load-more) that fail pre-fix and pass post-fix.

## What Was Built

- **The fix (`cursor.ex` only):**
  - `@type value :: {DateTime.t(), Ecto.UUID.t() | integer()}`
  - `encode/2` guard: `when is_binary(id) or is_integer(id)` (and the matching `@spec`)
  - `decode/1` inner value validation: `true <- is_binary(id) or is_integer(id)` (~line 37 — the cursor *value* id, NOT the outer `decode(cursor) when is_binary(cursor)` token guard)
  - HMAC `sign/verify`, `:erlang.term_to_binary` / `binary_to_term(..., [:safe])`, `Plug.Crypto.secure_compare`, and `DateTime.from_iso8601` spine left **exactly** as-is. `term_to_binary` already round-trips integers.
- **`behaviour.ex`, `events.ex`, and the core `Event` schema were NOT edited** — `apply_cursor/3`'s keyset already compares the integer cursor id against the integer `id` column correctly (confirmed by a clean `mix compile --warnings-as-errors`).

## Tests Added (RED → GREEN proven)

1. **`cursor_test.exs`** — integer-id round-trip (`Cursor.encode(ts, 16)` → `{:ok, {ts, 16}}`, `is_integer`). Existing UUID round-trip + tamper-rejection tests kept intact.
2. **`events_test.exs` (new)** — seeds 30 events via `Accrue.Events.record/1`, `AccrueAdmin.Queries.Events.list(limit: 25)` yields a non-nil `next_cursor` decoding to `{%DateTime{}, integer}`; page 2 loads with no id overlap (`MapSet.disjoint?`) and no raise. Fully-qualified module names disambiguate `Accrue.Events` (context) from `AccrueAdmin.Queries.Events` (query). Relies on the integer-id desc tiebreak (not forced distinct `inserted_at`).
3. **`events_live_test.exs`** — seeds 30 global events, `live(conn, "/billing/events")` returns 200 + `"Load more"`; `render_click` on `#events [data-role="load-more"]` appends rows (`data-row-id` count grows).

**Pre-fix sanity (gap-closure confirmed):** Running the three spec files against the un-widened `cursor.ex` produced exactly 3 failures, all `(FunctionClauseError) no function clause matching in AccrueAdmin.Queries.Cursor.encode/2` — the reported crash. After the fix all pass.

## Verification (exact results)

- `cd accrue_admin && mix compile --warnings-as-errors` → **clean** (`Compiling 1 file (.ex)` / `Generated accrue_admin app`, no warnings).
- `cd accrue_admin && mix test test/accrue_admin/queries/cursor_test.exs test/accrue_admin/queries/events_test.exs test/accrue_admin/live/events_live_test.exs` → **9 tests, 0 failures**.
- Full `cd accrue_admin && mix test` → **332 tests, 0 failures**.

## Deviations from Plan

**1. [Rule 1 - Test robustness] LiveView row counter uses `data-row-id` instead of `toggle-row`**
- **Found during:** Task 1, SPEC 3 authoring.
- **Issue:** The plan suggested targeting `data-role="toggle-row"`, but `toggle-row` only renders when the DataTable is `selectable` (default `false`), and the events table is not selectable — so the counter would always be 0.
- **Fix:** Count `data-row-id` occurrences, which render on every `<tr>` and responsive `<article>` regardless of `selectable`. The load-more selector (`#events [data-role="load-more"]`) matches `data_table.ex` exactly as specified.
- **Files modified:** `accrue_admin/test/accrue_admin/live/events_live_test.exs` (test-only).
- **Commit:** 4a937532

## Commit

- `4a937532` — `fix(admin): paginate integer-PK event ids in admin cursor` (4 files: cursor.ex + 3 test files; 112 insertions, 4 deletions; 0 deletions of tracked files). `examples/accrue_host/mix.lock`, `.planning/research/.cache/`, and `ROADMAP.md` deliberately left untouched/unstaged.

## Self-Check: PASSED

- FOUND: accrue_admin/lib/accrue_admin/queries/cursor.ex (contains `is_integer(id)`)
- FOUND: accrue_admin/test/accrue_admin/queries/cursor_test.exs (contains `is_integer`)
- FOUND: accrue_admin/test/accrue_admin/queries/events_test.exs (contains `Events.list`)
- FOUND: accrue_admin/test/accrue_admin/live/events_live_test.exs (contains `Load more`)
- FOUND: commit 4a937532 in `git log`
