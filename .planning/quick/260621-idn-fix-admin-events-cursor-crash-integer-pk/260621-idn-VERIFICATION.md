---
phase: 260621-idn
verified: 2026-06-21T13:30:00Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Quick 260621-idn: Fix admin events cursor crash (integer PK) Verification Report

**Task Goal:** Fix the events page crash (`FunctionClauseError` in `AccrueAdmin.Queries.Cursor.encode/2`, caused by the Event integer primary key) by widening the cursor to accept integer ids, AND close the coverage gap with spec-driven regression tests. One atomic commit.

**Verified:** 2026-06-21T13:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `/admin/events` (`/billing/events`) no longer raises FunctionClauseError with >25 events — page renders and paginates | ✓ VERIFIED | events_live_test.exs:110 mounts `/billing/events` with 30 events → 200 + "Load more" + load-more appends rows; passes in full suite (332/0). Pre-fix probe: this exact test raises FunctionClauseError in encode/2. |
| 2 | `Cursor.encode/2` and `decode/1` round-trip integer ids as well as UUID ids | ✓ VERIFIED | cursor.ex:15 guard `is_binary(id) or is_integer(id)`; cursor.ex:37 inner validation `is_binary(id) or is_integer(id)`; cursor_test.exs:15 round-trips integer 16 with `is_integer(decoded_id)`. UUID + tamper tests intact. |
| 3 | A regression spec seeds >25 events and proves page 2 loads with no crash and no row overlap | ✓ VERIFIED | events_test.exs seeds 30, asserts `length(rows1)==25`, decoded cursor id `is_integer`, page 2 non-empty, `MapSet.disjoint?` (no overlap). |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `cursor.ex` | Integer-or-binary encode/decode, HMAC spine unchanged | ✓ VERIFIED | Diff shows ONLY `@type`/`@spec` widened + two guards relaxed. `sign/1` HMAC (line 34, 44-46), `secure_compare`, `term_to_binary`/`binary_to_term([:safe])`, `DateTime.from_iso8601` (line 36), and outer `decode(cursor) when is_binary(cursor)` token guard (line 30) all UNCHANGED — no security regression. |
| `cursor_test.exs` | Integer round-trip alongside UUID | ✓ VERIFIED | Line 15-26: `is_integer` + `== 16`; existing UUID round-trip + tamper tests untouched. |
| `events_test.exs` | >25-event pagination, decoded cursor id integer, no overlap | ✓ VERIFIED | New file; seeds 30 via `Accrue.Events.record/1`; `AccrueAdmin.Queries.Events.list`; `is_integer(id)`; `MapSet.disjoint?`. |
| `events_live_test.exs` | Live render >25 events → 200 + Load more + load-more appends | ✓ VERIFIED | Line 110-138; selector `#events [data-role="load-more"]` matches data_table.ex:317; counts `data-row-id` (every row). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| behaviour.ex | cursor.ex | `paginate/3` calls `Cursor.encode(..., :id)` | ✓ WIRED | behaviour.ex:73 `Cursor.encode(Map.fetch!(last_row, field), Map.fetch!(last_row, :id))` — passes the integer Event PK. |
| events.ex | behaviour.ex | `Events.list` → `paginate` keyset on integer id | ✓ WIRED | events_test page-2 query (`MapSet.disjoint?`) compiles and runs without raising; full suite green. |

### Behavioral Spot-Checks (gap-closure / RED-GREEN proof)

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Full accrue_admin suite green | `mix test` | `332 tests, 0 failures` | ✓ PASS |
| Specs FAIL pre-fix (gap genuinely closed) | Revert cursor.ex guards to `is_binary` only, run 3 specs | `9 tests, 3 failures`, all `FunctionClauseError ... in AccrueAdmin.Queries.Cursor.encode/2` (cursor.ex:15) | ✓ PASS |
| Root cause confirmed | `grep primary_key accrue/lib/accrue/events/event.ex` | `@primary_key {:id, :id, autogenerate: true}` (integer) | ✓ PASS |

### Anti-Patterns Found

None. No debt markers, no stubs. The cursor.ex change is a minimal 8-line widening; security spine demonstrably unchanged.

### Guardrails

| Guardrail | Status | Evidence |
| --- | --- | --- |
| Single atomic commit | ✓ | `4a937532` only — 4 files, 112 insertions, 4 deletions. |
| Scope = cursor.ex + 3 test files | ✓ | `git show --name-only` lists exactly those 4. |
| behaviour.ex / events.ex / Event schema unchanged | ✓ | Not present in commit. |
| No mix.lock / research cache / ROADMAP.md in commit | ✓ | None present. (`examples/accrue_host/mix.lock` is a PRE-EXISTING working-tree modification unrelated to this task — correctly left unstaged.) |

### Gaps Summary

No gaps. The crash is fixed via the minimal guard widening with the HMAC/timestamp security spine demonstrably intact (verified by diff and surviving tamper-rejection test). The coverage gap is closed by three regression specs that are PROVEN to fail pre-fix with the exact reported `FunctionClauseError` and pass post-fix. Full suite is 332 tests / 0 failures. All guardrails (single commit, scope, untouched files) hold.

---

_Verified: 2026-06-21T13:30:00Z_
_Verifier: Claude (gsd-verifier)_
