# Phase 154: Advisory Cache Core Correctness - Research

**Researched:** 2026-05-30
**Domain:** Elixir/Ecto upsert concurrency, optimistic locking, telemetry, PostgreSQL ON CONFLICT semantics
**Confidence:** HIGH — all findings from direct source inspection of production code + official Ecto docs

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Remove `optimistic_lock(:lock_version)` from `EntitlementSummary.force_changeset/2` and remove `lock_version` from `@cast_fields`. The DB-level `on_conflict_where` is the concurrency guard; Ecto OCC is incompatible with the upsert path.

**D-02:** `lock_version` column stays in the DB (no migration). With it removed from `@cast_fields` it is not present in changeset changes and not touched by the upsert's `{:replace_all_except, [...]}`.

**D-03:** Change `on_conflict_where` from strict `<` to `(EXCLUDED.last_stripe_event_ts IS NULL OR e.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts)`.

**D-04:** `upsert_entitlement_summary/2` converts the stale condition (when `on_conflict_where` rejects — see Implementation Note below) to `{:ok, :stale}`. This keeps the Ecto adapter detail internal to the upsert function.

**D-05:** `write_entitlement_summary/9` handles `{:ok, :stale}` with a dedicated branch before the `with`: emit `result: :unchanged` telemetry, skip `maybe_record_summary_event/3`, return `{:ok, :stale}`.

**D-06:** Ship at least one test using two `Task.async` workers both calling the entitlement summary reducer with different timestamps (one older, one newer). Use `Ecto.Adapters.SQL.Sandbox.allow/3` to share the test connection. Assert newer timestamp wins.

**D-07:** `write_entitlement_summary/8` becomes `/9` by adding `processor` as the final argument. Use `to_string(processor)` from the arg, not `processor_name()`.

**D-08:** All call sites in `reduce_entitlement_summary_for_customer/7` must pass the processor arg through.

**D-09:** Nil-check sufficiency: carry the prior row's `livemode` forward whenever `get(obj, :livemode)` returns nil. Pattern mirrors `stamp_summary_watermark/4`.

### Claude's Discretion

None specified — all implementation decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

- **IN-03 (StripeFixtures `:omit_livemode` option)** → Phase 155
- **IN-04 (Telemetry Metrics counters)** → Phase 155
- Any DB migration or schema change
- Any new public API surface

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADV-01 | Remove `optimistic_lock(:lock_version)` from `EntitlementSummary.force_changeset/2` and `lock_version` from `@cast_fields` so concurrent Oban workers don't silently suppress each other's upserts | D-01 decision; entitlement_summary.ex:82-88 source; PITFALLS WR-05-02 |
| ADV-02 | Fix `on_conflict_where` to handle NULL `EXCLUDED.last_stripe_event_ts` via `(EXCLUDED.last_stripe_event_ts IS NULL OR e.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts)` | D-03 decision; PITFALLS WR-05-01; default_handler.ex:682-685 |
| ADV-03 | Stale DB-level skip returns `{:ok, :stale}`, emits `result: :unchanged` telemetry, does not write a ledger event | D-04/D-05; PITFALLS WR-05-03; Ecto StaleEntryError mechanism |
| ADV-04 | Ship concurrent `Task.async` test proving newer event wins, using `Sandbox.allow/3` | D-06; wr05_concurrency_test.exs anatomy; BillingCase sandbox mode |
| POL-01 | `write_entitlement_summary/9` uses `to_string(processor)` arg not `processor_name()` global | D-07/D-08; default_handler.ex:595 (`processor: processor_name()` is the bug) |
| POL-02 | Follow-up event missing `livemode` key carries forward prior row's livemode, not nil | D-09; PITFALLS IN-02-01; `stamp_summary_watermark/4` pattern at line 700-710 |

</phase_requirements>

## Summary

Phase 154 fixes three latent correctness bugs in the advisory entitlement cache write path and two field-accuracy gaps, all confined to two Accrue core files with no migration and no new dependencies.

**The five changes:**

1. **ADV-01 (OCC removal):** `EntitlementSummary.force_changeset/2` currently calls `optimistic_lock(:lock_version)`. In an `Repo.insert/2` upsert path, this injects a `WHERE lock_version = ?` predicate into the conflict-branch UPDATE. Under concurrent delivery, both workers load `lock_version: 1`, both pass `check_stale/2`, both form changesets, one succeeds and advances `lock_version` to 2; the second's `on_conflict_where` guard would let it through but the OCC WHERE clause now fails, silently suppressing the write. Remove the `optimistic_lock` call and `lock_version` from `@cast_fields`.

2. **ADV-02 (NULL watermark fix):** The current `on_conflict_where` uses `e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")`. When `EXCLUDED.last_stripe_event_ts` is NULL, SQL comparison returns NULL (not TRUE), producing a silent no-op with misleading `result: :written` telemetry. Fix: add `(EXCLUDED.last_stripe_event_ts IS NULL OR ...)`.

3. **ADV-03 (stale signal path):** When `on_conflict_where` rejects (condition false → 0 rows updated), Ecto raises `Ecto.StaleEntryError` (or populates `stale_error_field`). `upsert_entitlement_summary/2` must intercept this and return `{:ok, :stale}`; `write_entitlement_summary/9` must short-circuit on that value, emit `result: :unchanged` telemetry, skip `maybe_record_summary_event/3`.

4. **ADV-04 (concurrent test):** The existing `wr05_concurrency_test.exs` uses `RepoCase` with `async: false` (shared sandbox mode) + raw `Task.async` — does NOT use `Sandbox.allow/3`. The CONTEXT D-06 decision specifies using `Sandbox.allow/3`; the plan should either upgrade the existing test or add a new `BillingCase`-based test that explicitly calls `Sandbox.allow(Accrue.TestRepo, self(), task_pid)` before starting each task.

5. **POL-01 + POL-02 (field accuracy):** `write_entitlement_summary` uses `processor: processor_name()` (always returns the global config processor) and `livemode: get(obj, :livemode)` (returns nil when key absent). Both are 1-3 line fixes.

**Primary recommendation:** Execute as one wave — all five changes are in two files (`entitlement_summary.ex` + `default_handler.ex`) with one test file addition/update. ADV-01 + ADV-02 must ship together.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Concurrency guard for upsert | Database (PostgreSQL ON CONFLICT WHERE) | — | DB-level atomicity is the only true concurrent guard; Ecto OCC is an application-level check that cannot be atomic with the upsert |
| Watermark monotonicity (pre-DB gate) | Application (`check_stale/2`) | Database (`on_conflict_where`) | Two-layer: in-process pre-check first (avoids unnecessary write); DB-level guard second (catches concurrent writes that both passed pre-check) |
| Stale skip signal | Application (`upsert_entitlement_summary/2` return value) | — | Convert DB exception to typed `{:ok, :stale}` at the boundary so callers never see adapter details |
| Telemetry emission | Application (`write_entitlement_summary/9`) | — | Telemetry is always the write-path layer's responsibility; never emitted from schema or repo |
| Processor field accuracy | Application (write path arg threading) | — | `processor` identity is event context, not global config |
| livemode carry-forward | Application (attrs construction) | — | Pure data-merge logic; DB default would be wrong since the DB stores nil, not prior value |

## Standard Stack

No new dependencies. Phase uses only the already-pinned stack:

### Core (in use, no changes)
| Library | Version | Relevant Feature |
|---------|---------|-----------------|
| `:ecto` | `~> 3.13` | `Repo.insert/2` with `on_conflict_where`, `Ecto.StaleEntryError`, `stale_error_field:` option |
| `:ecto_sql` | `~> 3.13` | Sandbox mode for concurrent tests |
| `:postgrex` | `~> 0.22` | `ON CONFLICT DO UPDATE WHERE` with `EXCLUDED` pseudo-table |
| `:telemetry` | `~> 1.3` | `:telemetry.execute/3` for `result: :unchanged` emission |

**Installation:** None required.

## Package Legitimacy Audit

No new packages. Section not applicable.

## Architecture Patterns

### System Architecture Diagram

```
Oban Worker A          Oban Worker B
    |                      |
    v                      v
handle_event/3         handle_event/3
    |                      |
    v                      v
reduce_entitlement_summary/4
    |                      |
    v                      v
reduce_entitlement_summary_for_customer/7  (Repo.transact)
    |                      |
    v                      v
check_stale/2   <-- pre-DB gate (serial per-process)
    |  :stale → {:ok, :stale}
    |  :ok ↓
    v
write_entitlement_summary/9  <-- processor arg threaded here (D-07)
    |                      |
    |  build attrs         |  build attrs
    |  livemode nil-guard  |  livemode nil-guard (D-09)
    v                      v
upsert_entitlement_summary/2
    |                      |
    v                      v
Repo.insert(on_conflict_where: NULL-safe guard)  <-- D-03 fix
    |                      |
    PostgreSQL ON CONFLICT DO UPDATE WHERE (atomic)
    |                      |
    |  both pass → one wins, one gets StaleEntryError
    v                      v
intercept StaleEntryError → {:ok, :stale}  <-- D-04
    |                      |
    v (stale)              v (written)
emit result: :unchanged    emit result: :written
skip ledger event          maybe_record_summary_event/3
{:ok, :stale}              {:ok, saved}
```

### Recommended File Structure

All changes confined to existing files:

```
accrue/
├── lib/accrue/billing/entitlement_summary.ex       # ADV-01: remove optimistic_lock + lock_version from @cast_fields
└── lib/accrue/webhook/default_handler.ex
    ├── write_entitlement_summary/8 → /9            # POL-01 processor arg, POL-02 livemode nil-guard, ADV-03 stale branch
    └── upsert_entitlement_summary/2                # ADV-02 NULL watermark fix, ADV-03 StaleEntryError intercept

accrue/
└── test/accrue/webhook/
    └── default_handler_entitlement_summary_test.exs  # ADV-02 nil-ts test, ADV-03 stale-skip test, POL-01 processor test, POL-02 livemode test
    # OR upgrade wr05_concurrency_test.exs with Sandbox.allow/3  (ADV-04)
```

### Pattern 1: Ecto StaleEntryError Intercept (ADV-03 / ADV-04)

**What:** When `on_conflict_where` condition is not met (0 rows updated by the conflict branch), Ecto raises `Ecto.StaleEntryError`. The cleanest intercept is `rescue` inside `upsert_entitlement_summary/2`.

**When to use:** Any upsert with a conditional `on_conflict_where` that has semantically valid "no update" outcomes.

```elixir
# Source: [VERIFIED: github.com/elixir-ecto/ecto/issues/2589] + [ASSUMED: implementation pattern]
defp upsert_entitlement_summary(_row, attrs) do
  import Ecto.Query

  %EntitlementSummary{}
  |> EntitlementSummary.force_changeset(attrs)
  |> Repo.insert(
    returning: true,
    conflict_target: :customer_id,
    on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]},
    on_conflict_where:
      from(e in EntitlementSummary,
        where:
          fragment("EXCLUDED.last_stripe_event_ts IS NULL") or
            e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
      )
  )
rescue
  Ecto.StaleEntryError -> {:ok, :stale}
end
```

**Alternative:** `stale_error_field: :customer_id` option in `Repo.insert/2` which returns `{:error, changeset_with_error}` instead of raising — then pattern match on `{:error, %Ecto.Changeset{valid?: false}}` and convert to `{:ok, :stale}`. The `rescue` approach is simpler and more explicit for this use case.

**Note on D-04 wording:** CONTEXT.md D-04 mentions `{:error, :stale}` as the Ecto return value. This is slightly imprecise — the actual mechanism is `Ecto.StaleEntryError` being raised (not `{:error, :stale}` being returned). The `rescue` pattern is the correct implementation path. The conversion to `{:ok, :stale}` as the return from `upsert_entitlement_summary/2` is correct.

### Pattern 2: NULL-safe on_conflict_where (ADV-02)

**What:** Fix the SQL fragment so NULL `EXCLUDED.last_stripe_event_ts` always allows the update.

```elixir
# Source: [VERIFIED: PITFALLS.md WR-05-01] [VERIFIED: SQL NULL comparison semantics]
on_conflict_where:
  from(e in EntitlementSummary,
    where:
      fragment("EXCLUDED.last_stripe_event_ts IS NULL") or
        e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
  )
```

**Why `fragment("EXCLUDED.last_stripe_event_ts IS NULL")` not Ecto nil check:** `EXCLUDED` is a PostgreSQL pseudo-table only available inside the ON CONFLICT clause. Ecto cannot express `EXCLUDED.col IS NULL` natively without a fragment. The `fragment("...")` form is the standard approach. [ASSUMED: fragment form is correct syntax — verify compiles cleanly]

### Pattern 3: livemode Nil-Guard (POL-02)

**What:** Mirror the `stamp_summary_watermark/4` pattern — carry prior row's value forward when incoming is nil.

```elixir
# Source: [VERIFIED: default_handler.ex:700-710 stamp_summary_watermark pattern]
# In write_entitlement_summary/9 attrs construction:
livemode: resolve_livemode(get(obj, :livemode), row)

# Helper (or inline):
defp resolve_livemode(nil, %EntitlementSummary{livemode: prior}) when not is_nil(prior), do: prior
defp resolve_livemode(livemode, _row), do: livemode
```

**Or inline equivalent:**

```elixir
livemode:
  case get(obj, :livemode) do
    nil -> row && row.livemode
    value -> value
  end
```

### Pattern 4: Concurrent Task.async Test with Sandbox.allow/3 (ADV-04)

**What:** The existing `wr05_concurrency_test.exs` uses `RepoCase` with `async: false` (sandbox `shared: true` mode) which allows spawned processes to see the shared connection automatically. The CONTEXT D-06 decision requires `Sandbox.allow/3` explicitly.

**Key distinction:** `shared: true` (from `async: false` in RepoCase) vs. `Sandbox.allow/3`:
- `shared: true` — the owner checkout is in shared mode; all other processes that check in through ANY connection see the same data. Simpler but less precise.
- `Sandbox.allow/3` — explicitly allows a specific PID (the Task) to use the owner's connection. More explicit and what the requirement specifies.

```elixir
# Source: [VERIFIED: BillingCase billing_case.ex:49 — shared: not tags[:async]]
# Source: [CITED: Ecto.Adapters.SQL.Sandbox docs]
test "concurrent writes — newer timestamp wins", %{customer: customer} do
  parent = self()

  tasks = [
    Task.async(fn ->
      Ecto.Adapters.SQL.Sandbox.allow(Accrue.TestRepo, parent, self())
      DefaultHandler.handle(event_older)
    end),
    Task.async(fn ->
      Ecto.Adapters.SQL.Sandbox.allow(Accrue.TestRepo, parent, self())
      DefaultHandler.handle(event_newer)
    end)
  ]

  results = Task.await_many(tasks)
  for {:ok, _} <- results, do: :ok  # both must succeed

  row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
  assert row.last_stripe_event_ts == newer_ts
end
```

**Which test module:** `BillingCase` is the natural home (already imports `StripeFixtures`, aliases the schema types). Use `async: false` to get the `shared: true` sandbox mode that makes `Sandbox.allow/3` work correctly. Alternatively, upgrade the existing `wr05_concurrency_test.exs` to add explicit `Sandbox.allow/3` calls.

**`BillingCase` vs `RepoCase` for concurrent test:** The existing `wr05_concurrency_test.exs` uses `RepoCase` and `TestRepo` directly. A new ADV-04 test in `default_handler_entitlement_summary_test.exs` (which uses `BillingCase`) is cleaner — it lives with the other entitlement summary handler tests and uses the `StripeFixtures` helpers. Both approaches are valid; the plan should decide which file to put it in. [ASSUMED: adding to existing `default_handler_entitlement_summary_test.exs` is preferred]

### Pattern 5: Stale Skip Branch in write_entitlement_summary/9 (ADV-03)

**What:** D-05 says handle `{:ok, :stale}` before the `with` chain. Current `write_entitlement_summary/8` structure:

```elixir
# Current (line 610-629):
Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fn ->
  with {:ok, saved} <- upsert_entitlement_summary(row, attrs),
       {:ok, _} <- maybe_record_summary_event(material?, saved, evt_id) do
    :telemetry.execute(...)
    {:ok, saved}
  end
end)
```

**After fix — stale path is a pre-`with` case:**

```elixir
# Source: [ASSUMED: implementation pattern derived from CONTEXT.md D-05]
Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fn ->
  case upsert_entitlement_summary(row, attrs) do
    {:ok, :stale} ->
      :telemetry.execute(
        [:accrue, :entitlements, :summary_synced],
        %{count: 1, entitlement_count: entitlement_count},
        Map.put(metadata, :result, :unchanged)
      )
      {:ok, :stale}

    {:ok, saved} ->
      with {:ok, _} <- maybe_record_summary_event(material?, saved, evt_id) do
        :telemetry.execute(
          [:accrue, :entitlements, :summary_synced],
          %{count: 1, entitlement_count: entitlement_count},
          Map.put(metadata, :result, if(material?, do: :written, else: :unchanged))
        )
        if has_more do
          Accrue.Telemetry.Ops.emit(:entitlement_summary_truncated, %{count: 1}, %{customer_id: customer.id})
        end
        {:ok, saved}
      end

    error ->
      error
  end
end)
```

### Anti-Patterns to Avoid

- **Rescuing `Ecto.StaleEntryError` in `write_entitlement_summary/9` (not in `upsert_entitlement_summary/2`):** The rescue must be in the innermost upsert function so the stale signal is cleanly typed as `{:ok, :stale}` before it reaches the `with` chain. Rescuing at a higher level entangles the adapter detail with business logic.
- **Adding `lock_version` to `{:replace_all_except, [...]}` exclusion list:** Unnecessary once `lock_version` is removed from `@cast_fields` — it won't be in changeset changes so the upsert SET clause won't include it at all. Adding to exclusion list is defensive but adds noise.
- **Using `is_nil(get(obj, :livemode))` for the livemode guard:** `get/2` returns `nil` for both absent keys and explicit nil values. The guard should use `== nil` or a nil pattern match, not `is_nil/1` (same result, but clarity matters).
- **Using `:shared` checkout mode alone instead of `Sandbox.allow/3`:** D-06 explicitly requires `Sandbox.allow/3`. Even though `shared: true` (from `async: false`) allows spawned processes automatically, the test should demonstrate the explicit allow pattern per the requirement.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Concurrent upsert serialization | Custom locking, advisory locks, ETS serializer | PostgreSQL `ON CONFLICT DO UPDATE WHERE` — atomic at the row level |
| Stale detection after no-op conflict | Watermark comparison after the insert | `rescue Ecto.StaleEntryError` in the upsert function |
| Monotonic watermark | Custom timestamp compare functions | Existing `check_stale/2` + DB-level `on_conflict_where` (two-layer pattern already in place) |
| Test connection sharing | Custom ETS-based fixture state | `Ecto.Adapters.SQL.Sandbox.allow/3` |

**Key insight:** The DB-level `ON CONFLICT DO UPDATE WHERE` is the correct serialization primitive. Ecto OCC (`optimistic_lock/1`) is designed for `Repo.update/2` paths, not upsert paths — they conflict by design.

## Common Pitfalls

### Pitfall 1: ADV-01 + ADV-02 Must Ship Together

**What goes wrong:** Fixing only the NULL watermark without removing `optimistic_lock` still leaves concurrent silent suppression. Fixing only the `optimistic_lock` without the NULL fix still allows nil-timestamp retries to trigger the existing stale no-op (now silently returning `{:ok, struct}` with wrong watermark instead of raising).

**Why it happens:** Two independent bugs intersect in the upsert path. Each fix addresses a distinct failure mode. Both must be present for the concurrent delivery success criterion to hold.

**How to avoid:** Always task ADV-01 and ADV-02 changes together in the same plan/wave.

### Pitfall 2: `lock_version` Stays in the Generated SQL Unless Removed from `@cast_fields`

**What goes wrong:** Even with `optimistic_lock(:lock_version)` removed from `force_changeset/2`, if `lock_version` stays in `@cast_fields`, the upsert's SET clause will still include `lock_version = EXCLUDED.lock_version`. This is benign for correctness but leaves vestigial noise.

**Why it happens:** `{:replace_all_except, [:id, :inserted_at, :customer_id]}` replaces all fields in the changeset's changes. If `lock_version` is still cast, it's in changes, it's in the SET.

**How to avoid:** D-01 removes `lock_version` from `@cast_fields`. After removal, it won't appear in changeset changes and therefore won't appear in the generated UPDATE SET clause.

**Verification:** Run the existing tests after the change and check the SQL log — `lock_version` should no longer appear in the SET clause.

### Pitfall 3: `EXCLUDED` Pseudo-Table Requires SQL Fragment

**What goes wrong:** Attempting to express `EXCLUDED.last_stripe_event_ts IS NULL` using Ecto's native DSL (e.g., `is_nil(e.last_stripe_event_ts)` where `e` refers to the EXCLUDED row) won't compile or will bind to the wrong table.

**Why it happens:** `EXCLUDED` is a PostgreSQL-specific pseudo-table. Ecto's query DSL only binds named bindings to real schema aliases. The `EXCLUDED` reference has no Ecto binding.

**How to avoid:** Use `fragment("EXCLUDED.last_stripe_event_ts IS NULL")` for the NULL check side. The `e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")` pattern is already in the codebase and proves this approach compiles. [ASSUMED: the fragment form `fragment("EXCLUDED.last_stripe_event_ts IS NULL")` compiles cleanly — verify during implementation]

### Pitfall 4: Existing wr05_concurrency_test.exs Does Not Use Sandbox.allow/3

**What goes wrong:** The existing concurrent test at `test/accrue/webhook/wr05_concurrency_test.exs` uses `RepoCase, async: false` which gives shared sandbox mode implicitly. It does NOT use `Sandbox.allow/3`. D-06 requires `Sandbox.allow/3` explicitly.

**Why it matters:** The ADV-04 requirement specifically calls out `Sandbox.allow/3`. If the plan reuses the existing test file, it must add explicit `Sandbox.allow/3` calls to the concurrent task lambdas.

**How to avoid:** Add a new test to `default_handler_entitlement_summary_test.exs` (which uses `BillingCase`) and use `Sandbox.allow/3` explicitly, OR modify `wr05_concurrency_test.exs` to add the explicit allow calls. Either way, the test must call `Sandbox.allow(Accrue.TestRepo, self(), task_pid)` (or `Sandbox.allow(Accrue.TestRepo, parent_pid, self())` inside the task lambda).

### Pitfall 5: Stale Branch Telemetry Must Use `result: :unchanged`

**What goes wrong:** The stale skip should emit `result: :unchanged` to the `[:accrue, :entitlements, :summary_synced]` event. If the `{:ok, :stale}` branch short-circuits BEFORE the telemetry execute call (e.g., returns early before the span finishes), the `summary_synced` event is never emitted, and operators see a gap in metrics.

**Why it matters:** ADV-03 requirement: "A stale write returns `{:ok, :stale}`, emits `result: :unchanged` telemetry." The telemetry must be emitted inside the `Accrue.Telemetry.span` block to complete the span correctly.

**How to avoid:** Put the stale telemetry execute call inside the span lambda (as shown in Pattern 5 above), not before or after it.

### Pitfall 6: `maybe_record_summary_event/3` Takes `%EntitlementSummary{}` as Second Arg

**What goes wrong:** In the stale branch, there is no `%EntitlementSummary{}` `saved` struct (the upsert returned `{:ok, :stale}`). Calling `maybe_record_summary_event(material?, saved, evt_id)` would crash.

**Why it happens:** The stale branch must skip `maybe_record_summary_event/3` entirely — this is already specified in D-05 ("skip `maybe_record_summary_event/3`").

**How to avoid:** The stale branch returns `{:ok, :stale}` directly after emitting telemetry, never calling `maybe_record_summary_event/3`.

## Code Examples

### Current entitlement_summary.ex (the bug, lines 68-88)

```elixir
# Source: [VERIFIED: accrue/lib/accrue/billing/entitlement_summary.ex:68-88]
@cast_fields ~w[
  processor customer_id stripe_customer_id livemode entitlement_count
  truncated data synced_at lock_version   # <-- lock_version here is the problem
  last_stripe_event_ts last_stripe_event_id
]a

def force_changeset(summary_or_changeset, attrs \\ %{}) do
  summary_or_changeset
  |> cast(attrs, @cast_fields)
  |> optimistic_lock(:lock_version)   # <-- this is the OCC call to remove
  |> unique_constraint(:customer_id)
  |> foreign_key_constraint(:customer_id)
end
```

**After fix (ADV-01):**
- Remove `lock_version` from `@cast_fields`
- Remove `|> optimistic_lock(:lock_version)` line
- `lock_version` field declaration in `schema` block stays as-is (D-02: column stays)

### Current upsert SQL (the two bugs, lines 669-687)

```elixir
# Source: [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex:669-687]
defp upsert_entitlement_summary(_row, attrs) do
  import Ecto.Query

  %EntitlementSummary{}
  |> EntitlementSummary.force_changeset(attrs)
  |> Repo.insert(
    returning: true,
    conflict_target: :customer_id,
    on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]},
    on_conflict_where:
      from(e in EntitlementSummary,
        where: e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
        #  ^^ bug: NULL EXCLUDED.last_stripe_event_ts → NULL comparison → no-op
      )
  )
  # ^^ no rescue: Ecto.StaleEntryError propagates to callers
end
```

### Current write_entitlement_summary/8 processor bug (line 595)

```elixir
# Source: [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex:595]
processor: processor_name(),  # <-- always global config, ignores event processor arg
```

**After POL-01 fix:** `processor: to_string(processor)` (where `processor` is the new 9th arg)

### Current livemode bug (line 596)

```elixir
# Source: [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex:596]
livemode: get(obj, :livemode),  # <-- nil when key absent; overwrites prior known value
```

### stamp_summary_watermark/4 pattern to mirror for POL-02

```elixir
# Source: [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex:700-710]
defp stamp_summary_watermark(attrs, %DateTime{} = evt_ts, evt_id, _row),
  do: stamp_watermark(attrs, evt_ts, evt_id)

defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, nil), do: attrs

defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, %EntitlementSummary{} = row) do
  Map.merge(attrs, %{
    last_stripe_event_ts: row.last_stripe_event_ts,
    last_stripe_event_id: row.last_stripe_event_id
  })
end
```

### Existing concurrent test to upgrade (wr05_concurrency_test.exs pattern)

```elixir
# Source: [VERIFIED: accrue/test/accrue/webhook/wr05_concurrency_test.exs:71-76]
# Current — uses shared sandbox implicitly, no Sandbox.allow/3:
tasks = [
  Task.async(fn -> DefaultHandler.handle(event1) end),
  Task.async(fn -> DefaultHandler.handle(event2) end)
]
results = Enum.map(tasks, &Task.await/1)
```

## State of the Art

| Old Approach | Current Approach | Phase 154 Change |
|--------------|-----------------|-----------------|
| `Repo.update` with `optimistic_lock` (Phase 127 original) | `Repo.insert` with `on_conflict` (WR-05 partial fix already shipped) | Remove the lingering `optimistic_lock` from `force_changeset/2` (it now causes silent suppression instead of raising) |
| Strict `<` in `on_conflict_where` | Same strict `<` | Change to NULL-safe `(IS NULL OR <)` |
| No stale-skip detection at DB level | No stale-skip detection at DB level | Add `rescue Ecto.StaleEntryError → {:ok, :stale}` in upsert; handle in write path |

**Deprecated/outdated in this codebase:**
- `optimistic_lock(:lock_version)` in `force_changeset/2`: appropriate for `Repo.update/2` paths, incompatible with `Repo.insert/2` upsert paths using `on_conflict_where`.
- `processor_name()` inside `write_entitlement_summary`: was correct when only Stripe existed; incorrect for multi-processor scenarios.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `fragment("EXCLUDED.last_stripe_event_ts IS NULL")` compiles cleanly inside `on_conflict_where` Ecto query | Pattern 2, Pitfall 3 | Plan must include a compile-check task before committing; if fragment syntax is wrong, use raw SQL string form |
| A2 | `rescue Ecto.StaleEntryError` is the correct intercept pattern (vs. `stale_error_field:` option) | Pattern 1 | Both work; rescue is simpler. If Ecto version changes the exception type, the rescue stops catching it — but Ecto 3.13 raises `Ecto.StaleEntryError` per PITFALLS research |
| A3 | Adding ADV-04 test to `default_handler_entitlement_summary_test.exs` (BillingCase) is preferred over modifying `wr05_concurrency_test.exs` (RepoCase) | Pattern 4 | Either is valid; planner can choose the RepoCase file instead — the `Sandbox.allow/3` pattern is the same either way |
| A4 | `Task.await_many/1` is available in the Elixir version (1.17+) | Pattern 4 | `Task.await_many/1` was added in Elixir 1.11; confirmed available on Elixir 1.17+ floor [CITED: Elixir docs] |

## Open Questions

1. **`fragment` form for `EXCLUDED IS NULL` check**
   - What we know: `fragment("EXCLUDED.last_stripe_event_ts")` is already used in the codebase and compiles. `IS NULL` predicates in fragments are standard SQL supported by postgrex.
   - What's unclear: Whether Ecto's `on_conflict_where` accepts an `or` composition with a raw fragment on the left side (e.g., `fragment("EXCLUDED.last_stripe_event_ts IS NULL") or e.field < fragment(...)`).
   - Recommendation: Plan Wave 0 task to verify compilation with a scratch test or by running `mix compile` after the change.

2. **Whether to add `lock_version` to `{:replace_all_except, [...]}` exclusion list**
   - What we know: D-02 says just remove from `@cast_fields`. If it's not in cast_fields, it's not in changeset changes, so it won't be in the SET clause regardless of the exclusion list.
   - What's unclear: Whether there's value in adding it to the exclusion list anyway for defensive documentation.
   - Recommendation: Do NOT add — it would be dead code and would confuse readers about the mechanism. The @cast_fields removal is the correct single point of control.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — all changes are code-only in existing Elixir/Ecto/PostgreSQL stack already confirmed running).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `accrue/test/test_helper.exs` |
| Quick run command | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` |
| Full suite command | `mix test` (from `accrue/` directory) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ADV-01 | OCC removed: serial upsert still works, `lock_version` absent from SET clause | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ✅ existing tests verify write path works |
| ADV-02 | Nil `last_stripe_event_ts` event updates the row (not a silent no-op) | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 — no nil-ts test exists |
| ADV-03 | Stale DB-level skip returns `{:ok, :stale}`, emits `result: :unchanged`, no ledger event | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 — existing stale test only covers check_stale/2 pre-DB gate, not DB-level stale |
| ADV-04 | Two concurrent Task.async workers: newer timestamp wins, no crash | integration | `mix test test/accrue/webhook/wr05_concurrency_test.exs` OR `default_handler_entitlement_summary_test.exs` | ✅ existing test but lacks `Sandbox.allow/3` — needs upgrade |
| POL-01 | Non-Stripe processor event writes correct `:processor` field | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 — no processor accuracy assertion exists |
| POL-02 | Follow-up event with absent `livemode` key carries forward prior row's livemode | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 — no livemode carry-forward test exists |

### Sampling Rate
- **Per task commit:** `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs`
- **Per wave merge:** `mix test` from `accrue/` directory
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for ADV-02 (nil timestamp event updates row)
- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for ADV-03 (DB-level stale skip: deliver newer, then concurrent older, assert `{:ok, :stale}` + `result: :unchanged` telemetry + no ledger event for older)
- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for POL-01 (processor: "stripe" when global config is Fake)
- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for POL-02 (livemode absent in second event → prior livemode carried forward)
- [ ] ADV-04 concurrent test — upgrade `wr05_concurrency_test.exs` to add `Sandbox.allow/3` OR add new test in `default_handler_entitlement_summary_test.exs`

## Security Domain

No security surface changes. All modifications are internal write-path logic with no new input surfaces, no new authentication, no new data exposure. Security section not applicable.

## Project Constraints (from CLAUDE.md)

- No new dependencies — confirmed. Phase uses only existing `:ecto`, `:telemetry`, `:postgrex`.
- No migration — confirmed. `lock_version` column stays in DB (D-02).
- No new public API surface — confirmed. `write_entitlement_summary/9` is a private `defp`.
- `:oban` integration: webhook workers are Oban workers; the concurrent test simulates two Oban worker processes but does not need Oban itself running (uses raw `Task.async`).
- Mox for mocks: not needed for this phase — the write path is tested against the real `TestRepo` (real DB with sandbox).
- `BillingCase` uses `Fake` processor by default — this is why `processor_name()` returns `"fake"` in tests, confirming the POL-01 bug is observable in the existing test suite.

## Sources

### Primary (HIGH confidence)
- `accrue/lib/accrue/billing/entitlement_summary.ex` — direct source read, `force_changeset/2` with `optimistic_lock`, `@cast_fields`
- `accrue/lib/accrue/webhook/default_handler.ex:500-730` — direct source read, entire write path
- `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` — test coverage inventory
- `accrue/test/accrue/webhook/wr05_concurrency_test.exs` — existing concurrent test (lacks `Sandbox.allow/3`)
- `accrue/test/support/billing_case.ex` — sandbox mode configuration
- `.planning/research/PITFALLS.md` — WR-05-01 through IN-02-01 failure mode documentation
- `.planning/phases/154-advisory-cache-core-correctness/154-CONTEXT.md` — all locked decisions

### Secondary (MEDIUM confidence)
- [Ecto StaleEntryError with on_conflict_where](https://github.com/elixir-ecto/ecto/issues/2589) — confirms `Ecto.StaleEntryError` is raised when `on_conflict_where` condition not met; `stale_error_field` is the documented suppress mechanism
- [Ecto.Repo docs — stale_error_field](https://ecto.hexdocs.pm/Ecto.Repo.html) — `stale_error_field:` option converts StaleEntryError to changeset error

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, existing stack confirmed
- Architecture: HIGH — sourced from direct code reading
- Pitfalls: HIGH — sourced from PITFALLS.md (itself sourced from direct code reading)
- Stale intercept mechanism (rescue vs stale_error_field): MEDIUM — confirmed from Ecto issue tracker; A2 assumption flags this

**Research date:** 2026-05-30
**Valid until:** 60 days (Ecto 3.13 is stable; no churn expected)
