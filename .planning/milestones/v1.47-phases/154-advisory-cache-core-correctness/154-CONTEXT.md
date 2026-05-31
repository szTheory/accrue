# Phase 154: Advisory Cache Core Correctness - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix three latent correctness bugs in the advisory entitlement cache write path and two field-accuracy gaps, and ship the concurrent-delivery test that proves the fixes work. All changes are confined to two accrue core files — no migrations, no new dependencies, no new public API surface.

- **In scope:** `EntitlementSummary.force_changeset/2` OCC removal, `on_conflict_where` NULL watermark fix, stale skip return path + telemetry, concurrent `Task.async` test, `write_entitlement_summary/8 → /9` processor arg, livemode carry-forward
- **Out of scope:** StripeFixtures `:omit_livemode` option (Phase 155), Telemetry Metrics counters (Phase 155), adopter-proof examples (Phases 156–158), any DB migration or schema change

</domain>

<decisions>
## Implementation Decisions

### Concurrency guard (ADV-01)
- **D-01:** Remove `optimistic_lock(:lock_version)` from `EntitlementSummary.force_changeset/2` and remove `lock_version` from `@cast_fields`. The DB-level `on_conflict_where` is the concurrency guard; Ecto OCC is incompatible with the upsert path and silently suppresses concurrent writes.
- **D-02:** `lock_version` column stays in the DB (no migration). With it removed from `@cast_fields` it is not present in changeset changes and not touched by the upsert's `{:replace_all_except, [...]}`.

### NULL watermark fix (ADV-02)
- **D-03:** Change `on_conflict_where` from strict `<` to `(EXCLUDED.last_stripe_event_ts IS NULL OR e.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts)`. The current strict `<` short-circuits to a SQL NULL (no-op) when `EXCLUDED.last_stripe_event_ts` is NULL, silently leaving the row un-updated and misfiring `result: :written` telemetry.

### Stale skip signal path (ADV-03) — DECIDED IN DISCUSSION
- **D-04:** `upsert_entitlement_summary/2` converts `{:error, :stale}` (Ecto's return when `INSERT ... ON CONFLICT DO UPDATE WHERE <guard>` fires and 0 rows are updated, because `RETURNING` emits nothing on a no-op conflict branch) to `{:ok, :stale}`. This keeps the Ecto adapter detail internal to the upsert function.
- **D-05:** `write_entitlement_summary/9` handles `{:ok, :stale}` with a dedicated branch (case or head clause before the `with`): emit `result: :unchanged` telemetry, skip `maybe_record_summary_event/3`, return `{:ok, :stale}`. Non-stale but non-material writes continue to use the existing `material?` check (they are not stale — the row was updated, just not materially changed).

### Concurrent delivery test (ADV-04)
- **D-06:** Ship at least one test using two `Task.async` workers both calling the entitlement summary reducer with different timestamps (one older, one newer) starting from the same customer row. Use `Ecto.Adapters.SQL.Sandbox.allow/3` to share the test connection. Assert that after both tasks complete, the row's `last_stripe_event_ts` equals the newer timestamp. Serial tests cannot catch the OCC+upsert race.

### Processor field accuracy (POL-01)
- **D-07:** `write_entitlement_summary/8` becomes `write_entitlement_summary/9` by adding `processor` as the final argument. Use `to_string(processor)` from the arg, not `processor_name()` (which is a global config lookup that always returns `"stripe"` regardless of which processor handled the event).
- **D-08:** All call sites in `reduce_entitlement_summary/4` (which already has `processor` in scope) must pass the processor arg through.

### livemode carry-forward (POL-02) — DECIDED IN DISCUSSION
- **D-09:** Nil-check sufficiency: carry the prior row's `livemode` forward whenever `get(obj, :livemode)` returns nil (covering both absent key and explicit nil — a distinction that doesn't exist in Stripe's wire format, where livemode is always a boolean). Pattern mirrors `stamp_summary_watermark/4` for timestamps. On first-ever write (no prior row), `livemode` stays nil if the key is absent — acceptable.

### Folded Todos
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)** — Filed 2026-05-24 from Phase 127 code review, `resolves_phase: 154`. Origin document for this phase's scope. Key file references: `default_handler.ex:613-623`, `entitlement_summary.ex:82-88`, `telemetry/metrics.ex:88`, `test/support/stripe_fixtures.ex:3`. IN-03 and IN-04 items from this todo are deferred to Phase 155 (per roadmap scope boundary).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §"Advisory Cache Correctness (WR-05)" — ADV-01..ADV-04 requirements with precise acceptance criteria
- `.planning/REQUIREMENTS.md` §"Advisory Cache Polish (IN-01..04)" — POL-01, POL-02 requirements (POL-03, POL-04 are Phase 155)

### Research
- `.planning/research/PITFALLS.md` — WR-05-01 through WR-05-04: exact failure modes, SQL behavior, prevention patterns, warning signs. MANDATORY read before planning.
- `.planning/research/SUMMARY.md` — Executive summary + feature table with precise change descriptions for all Phase 154 items

### Source files (read before planning)
- `accrue/lib/accrue/webhook/default_handler.ex` — lines 500–723: `reduce_entitlement_summary/4`, `write_entitlement_summary/8`, `upsert_entitlement_summary/2`, `stamp_summary_watermark/4`, `check_stale/2` — the entire write path being changed
- `accrue/lib/accrue/billing/entitlement_summary.ex` — lines 56–88: schema fields (`livemode`, `lock_version`, `@cast_fields`) and `force_changeset/2` with `optimistic_lock` call
- `accrue/lib/accrue/telemetry/metrics.ex` — line 88: existing metrics context (for ADV-03 telemetry shape consistency)

### Todo origin
- `.planning/todos/pending/2026-05-24-ent10-advisory-cache-followups.md` — full problem description and solution sketch from Phase 127 code review (folded into Phase 154 scope)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `stamp_summary_watermark/4` pattern (default_handler.ex ~700): nil-guard carry-forward for timestamps — same pattern to apply for livemode nil-check (D-09)
- `check_stale/2` (default_handler.ex ~541): pre-DB stale gate; the DB-level `on_conflict_where` is the second gate that must handle what `check_stale` lets through
- `Accrue.Telemetry.span/3` + `:telemetry.execute/3` (write_entitlement_summary/8): existing telemetry emission pattern to follow for the stale path

### Established Patterns
- `{:ok, :stale}` return convention: already used by other reducers in `default_handler.ex` for stale-skip signaling — consistent to use here
- `upsert_entitlement_summary/2` currently returns raw `Repo.insert/2` result — will need to intercept `{:error, :stale}` and convert (D-04)
- `Ecto.Adapters.SQL.Sandbox.allow/3` for async test access — Accrue's DataCase uses sandbox mode; concurrent tests require explicit allow

### Integration Points
- `reduce_entitlement_summary/4` (default_handler.ex ~500): the caller of `write_entitlement_summary` — must pass the new `processor` 9th arg (D-07, D-08)
- `maybe_record_summary_event/3`: NOT called on stale skip (D-05); only called via existing `material?` branch for real writes
- `on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]}` in `upsert_entitlement_summary/2`: `lock_version` absent from cast_fields means it's not in changeset changes and won't be replaced (D-02)

</code_context>

<specifics>
## Specific Ideas

- The concurrent test (D-06) must use `Sandbox.allow/3` (not `:shared` checkout mode) per ADV-04 requirement — the distinction matters for DataCase compatibility
- The `on_conflict_where` NULL fix (D-03) is a SQL fragment; use `fragment("EXCLUDED.last_stripe_event_ts IS NULL OR ...")` or Ecto query form — whichever is cleaner given the existing `from(e in EntitlementSummary, where: ...)` structure
- ADV-01 + ADV-02 must ship together — fixing the `on_conflict_where` without removing `optimistic_lock` still leaves silent suppression under concurrent delivery (documented in STATE.md key decisions)

</specifics>

<deferred>
## Deferred Ideas

- **IN-03 (StripeFixtures moduledoc + `:omit_livemode` option)** → Phase 155 per roadmap scope
- **IN-04 (Telemetry Metrics counters for malformed/orphan entitlement summary)** → Phase 155 per roadmap scope

</deferred>

---

*Phase: 154-Advisory-Cache-Core-Correctness*
*Context gathered: 2026-05-30*
