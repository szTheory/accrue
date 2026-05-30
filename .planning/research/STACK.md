# Stack Research — v1.47

**Project:** Accrue ENT-10 Polish + Adopter-Proof Completeness
**Researched:** 2026-05-30
**Scope:** WR-05 DB upsert concurrency fix, IN-01..04 minor corrections, adopter-proof examples

---

## Ecto Upsert Pattern for Entitlement Summary

### Current State (what is already in the codebase)

`default_handler.ex` lines 669–686 already contain the WR-05 upsert:

```elixir
%EntitlementSummary{}
|> EntitlementSummary.force_changeset(attrs)
|> Repo.insert(
  returning: true,
  conflict_target: :customer_id,
  on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]},
  on_conflict_where:
    from(e in EntitlementSummary,
      where: e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
    )
)
```

This is already written. The remaining work is in `EntitlementSummary.force_changeset/2`, which still calls `optimistic_lock(:lock_version)`. That call is **incompatible** with the DB-level upsert path.

### The Problem with `optimistic_lock` + `Repo.insert` `on_conflict`

`Ecto.Changeset.optimistic_lock/2` works by:
1. Reading the current `lock_version` from the row.
2. Adding a `WHERE lock_version = ^current` clause to the `UPDATE`.
3. Checking `affected_rows == 1`; if 0, raising `Ecto.StaleEntryError`.

When `Repo.insert/2` is used with `on_conflict: {:replace_all_except, ...}`, Ecto issues a PostgreSQL `INSERT ... ON CONFLICT DO UPDATE SET ...`. The `optimistic_lock` machinery does not participate in `ON CONFLICT DO UPDATE` — Ecto does not inject the lock-version `WHERE` predicate into the upsert's conflict-update clause. The result is two problems:

- On **insert path** (first write for a customer): `lock_version` starts at 1 — harmless, upsert works.
- On **update path** (existing row): The upsert replaces `lock_version` from `EXCLUDED` (the new value), which is whatever the changeset computed. If the changeset casts `lock_version: 1` (from a `%EntitlementSummary{}` struct default), it overwrites the real DB `lock_version` with 1 on every upsert — breaking monotonicity of the field and making it useless.

### Correct Fix: Remove `optimistic_lock` from `force_changeset/2`

`optimistic_lock` is only meaningful in `Repo.update/2` flows where Ecto can inject the `WHERE` clause. For the upsert path, the stale-skip watermark is enforced at the DB level via the `on_conflict_where` predicate (`last_stripe_event_ts < EXCLUDED.last_stripe_event_ts`). That IS the concurrency guard — it is strictly stronger than optimistic lock for this use case because:

- It is atomic at the DB level (evaluated inside the same PG lock held for the upsert).
- It never raises an exception — a stale insert simply becomes a no-op (0 rows affected).
- Concurrent workers for the same customer converge to the newest watermark without retries.

**Action:** Remove `|> optimistic_lock(:lock_version)` from `EntitlementSummary.force_changeset/2`. Update the `@moduledoc` to remove the claim that `force_changeset` carries `optimistic_lock`. The `lock_version` column can stay in the schema and migration (removing it would be a breaking migration change); it just must not be managed by the changeset anymore. Additionally, remove `lock_version` from `@cast_fields` so it is never written by the changeset — this prevents accidentally casting a stale value into the upsert.

### Stale-Skip Watermark: How the DB Predicate Preserves It

The `on_conflict_where` clause:
```sql
WHERE accrue_entitlement_summaries.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts
```
translates to: "only apply the UPDATE if the existing row's watermark is older than the incoming event's watermark." When this predicate is false (incoming event is older or same age), PostgreSQL performs no update — zero rows are affected. `Repo.insert/2` with `returning: true` then returns `{:ok, %EntitlementSummary{}}` with the struct Ecto built from the insert params, NOT the existing DB row.

**Important caveat:** When the `on_conflict_where` predicate is false (stale skip), `Repo.insert/2` returns `{:ok, struct}` — not `{:ok, :stale}`. The returned struct has the fields from the attempted insert (not the actual DB row). The pre-existing `check_stale/2` guard above the call site already handles the coarse-grained stale check before the upsert runs; the DB-level predicate is the race-window guard for concurrent delivery of two events that both pass the pre-check. The existing `{:ok, saved}` return type is acceptable — the stale-skip at the DB level is the correct outcome and the pre-check telemetry handles observability.

### `{:replace_all_except, [...]}` Correctness

`on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]}` means: on conflict on `customer_id`, replace every column EXCEPT `:id`, `:inserted_at`, and `:customer_id`. This is correct for the entitlement summary use case:

- `:id` — never overwrite the primary key.
- `:inserted_at` — preserve the original creation timestamp.
- `:customer_id` — the conflict target, already unchanged.
- All other columns (`:processor`, `:stripe_customer_id`, `:livemode`, `:entitlement_count`, `:truncated`, `:data`, `:synced_at`, `:last_stripe_event_ts`, `:last_stripe_event_id`, `:updated_at`) are replaced.

With `lock_version` removed from `@cast_fields`, it will also be excluded from the upsert (Ecto only generates SQL for cast fields). That is the correct behavior.

### Ecto Version Compatibility

This pattern uses `Repo.insert/2` with `conflict_target:`, `on_conflict:`, and `on_conflict_where:` — all available since **Ecto 3.5**. The project pins `ecto ~> 3.13`, so no version concern.

`on_conflict_where:` accepts either a keyword list or an `Ecto.Query` fragment. The query form used here (`from(e in EntitlementSummary, where: ...)`) is the canonical pattern. The `fragment("EXCLUDED.last_stripe_event_ts")` references PostgreSQL's `EXCLUDED` pseudo-table, which is standard SQL/PG syntax available since PG 9.5 (project floor is PG 14).

**Confidence: HIGH** — verified against Ecto 3.x behavior and the existing `ingest.ex` pattern in this codebase.

---

## Oban Conflict / Concurrency Patterns

### Current Oban Config

The host app already configures all necessary queues and crontab entries in `examples/accrue_host/config/config.exs`:

```elixir
config :accrue_host, Oban,
  repo: AccrueHost.Repo,
  queues: [
    accrue_webhooks: 10,
    accrue_mailers: 20,
    accrue_pdf: 5,
    accrue_dunning: 2,
    accrue_meters: 5,
    accrue_scheduled: 5
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24},
    {Oban.Plugins.Cron,
     crontab: [
       {"*/15 * * * *", Accrue.Jobs.DunningSweeper},
       {"@daily", Accrue.Jobs.DetectExpiringCards},
       {"* * * * *", Accrue.Jobs.MeterEventsReconciler},
       {"*/5 * * * *", Accrue.Jobs.MeteredRenewalReconciler}
     ]}
  ]
```

The cron wiring is structurally complete. The v1.47 adopter-proof is a test that verifies this config, not a new wiring change.

### Oban Uniqueness for Entitlement Summary Writes

The entitlement summary reducer does NOT need Oban-level uniqueness on the webhook dispatch worker side — uniqueness for the `DispatchWorker` is already handled by the `accrue_webhook_events` dedup at the ingest layer. The DB-level upsert with `on_conflict_where` handles concurrent delivery of the same Stripe event ID by Oban retries.

For the `maybe_record_summary_event/3` ledger write, the idempotency key `"entitlements.summary.synced:" <> evt_id` already collapses Oban retries of the same event. No new Oban patterns are needed.

### Oban Cron Adopter-Proof Pattern

The `SubscriptionLive` "Recovery Wiring Demo (PROOF-06)" section names the cron jobs in static text. For v1.47 the proof should be a test that verifies the cron is actually configured. The idiomatic pattern (matching `dunning_wiring_test.exs` and `recovery_wiring_test.exs` already in the codebase):

```elixir
# examples/accrue_host/test/accrue_host/oban_cron_proof_test.exs
test "accrue cron jobs are wired into host Oban config" do
  conf = Application.fetch_env!(:accrue_host, Oban)
  plugins = Keyword.fetch!(conf, :plugins)
  {Oban.Plugins.Cron, cron_opts} = List.keyfind!(plugins, Oban.Plugins.Cron, 0)
  crontab = Keyword.fetch!(cron_opts, :crontab)
  modules = Enum.map(crontab, fn {_schedule, mod} -> mod end)

  assert Accrue.Jobs.DunningSweeper in modules
  assert Accrue.Jobs.DetectExpiringCards in modules
  assert Accrue.Jobs.MeterEventsReconciler in modules
end
```

This is a config-inspection test — no DB, no running Oban instance, no Oban Pro needed.

**Confidence: HIGH** — Oban 2.21 community edition; pattern matches existing test style.

---

## IN-01..04 Minor Corrections — Stack Implications

### IN-01: Set `:processor` in `write_entitlement_summary/8`

`write_entitlement_summary/8` currently sets `processor: processor_name()` in attrs, which uses the compile-time configured global processor. For the entitlement summary path, the processor is passed through from `handle_event/3` as `event.processor` (atom: `:stripe`). The fix is to use the `processor` argument passed down to `reduce_entitlement_summary/4` and into `write_entitlement_summary/8`. One argument addition to the function signature and one change in the attrs map. No stack addition.

### IN-02: Pass raw boolean-or-nil for livemode

`get(obj, :livemode)` returns `true | false | nil`. `EntitlementSummary` schema has `field(:livemode, :boolean)` — Ecto's `:boolean` type casts `nil` to `nil` correctly. No coercion risk from typed Stripe JSON. This is a defensive guard or documentation clarification. No stack change.

### IN-03: `stripe_fixtures` moduledoc polish

Documentation-only. No stack change.

### IN-04: Metrics counter or documented omission

`accrue.entitlements.summary_synced.count` is already in `Accrue.Telemetry.Metrics.defaults/0`. Two telemetry events emitted in `default_handler.ex` are NOT yet in `Metrics.defaults/0`:

- `[:accrue, :webhooks, :malformed_entitlement_summary]` — emitted via `:telemetry.execute` in `emit_summary_malformed/2`, no counter in `defaults/0`.
- `[:accrue, :webhooks, :orphan_entitlement_summary]` — emitted in `reduce_entitlement_summary_for_customer/7`, no counter in `defaults/0`.

If IN-04 requires these, add to `defaults/0`:
```elixir
counter("accrue.webhooks.malformed_entitlement_summary.count", tags: [:reason]),
counter("accrue.webhooks.orphan_entitlement_summary.count"),
```

No new library dep — all telemetry infrastructure is already present.

---

## Adopter-Proof Example Stack Needs

### Entitlements Gating Proof

The config already defines the `premium` plan gating `advanced_reports`. `AccrueHostWeb.AdvancedReportsLive` exists. The proof needs a test asserting that a non-premium user cannot access the advanced reports page, and a premium user can. No new library needed — use `ConnCase` / `DataCase` patterns already in `examples/accrue_host/test/support/`.

### Metered Usage Proof

`SubscriptionLive` (PROOF-04) already has the "Simulate API Call" button calling `Billing.report_usage_for_scope/3`. What may be missing is a test verifying this path end-to-end with the Fake processor. No new library needed.

### Oban Cron Proof

See the config-inspection test pattern above. No new library.

### No New Libraries Needed for Examples

`examples/accrue_host/mix.exs` does not need any new dependencies for v1.47. All needed functionality is in `accrue`, `phoenix_live_view`, and `oban` (already present).

---

## What NOT to Add

- **Do NOT add `Ecto.StaleEntryError` rescue** around the upsert call. Remove `optimistic_lock` from the changeset instead; rescue-wrapping leaves the changeset in an inconsistent state.

- **Do NOT add a new migration** for the WR-05 fix. The existing `UNIQUE INDEX ON accrue_entitlement_summaries (customer_id)` is already the conflict target. No schema change required.

- **Do NOT add `lock_version` to the `{:replace_all_except, [...]}` exclusion list** without also removing it from `@cast_fields`. The cleanest solution is removing it from `@cast_fields` so the upsert never writes it.

- **Do NOT add `:bypass` as a test dep**. `Accrue.Processor.Fake` covers the webhook event path deterministically.

- **Do NOT add `Oban.Pro` or `Oban.Web`** for the cron adopter-proof. Config-inspection is sufficient.

- **Do NOT add `:opentelemetry` as a required dep** for v1.47. Remains optional per project constraint.

- **Do NOT wrap the upsert in a new `Ecto.Multi`**. It is already inside `Repo.transact` via `reduce_entitlement_summary_for_customer/7`. Atomicity is correct.

---

## Summary of Changes Required

| Change | File | Type |
|--------|------|------|
| Remove `optimistic_lock(:lock_version)` and `lock_version` from `@cast_fields` | `accrue/lib/accrue/billing/entitlement_summary.ex` | Code (2 lines) |
| Update `@moduledoc` to remove optimistic_lock claim | `accrue/lib/accrue/billing/entitlement_summary.ex` | Doc |
| Use `processor` arg instead of `processor_name()` in attrs | `accrue/lib/accrue/webhook/default_handler.ex` | Code (1 line) |
| Add missing telemetry counters to `Metrics.defaults/0` (IN-04) | `accrue/lib/accrue/telemetry/metrics.ex` | Code (1-2 lines) |
| Add cron wiring test | `examples/accrue_host/test/accrue_host/oban_cron_proof_test.exs` | New test file |
| Add/extend entitlements gating test | `examples/accrue_host/test/` | New or extended test |

**No new mix dependencies required for any of these changes.**

---

## Sources

- Direct source reads: `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/lib/accrue/billing/entitlement_summary.ex`, `accrue/lib/accrue/telemetry/metrics.ex`, `examples/accrue_host/config/config.exs`, `accrue/priv/repo/migrations/20260524120000_create_accrue_entitlement_summaries.exs` — HIGH confidence.
- Ecto 3.x `Repo.insert/2` `on_conflict` / `on_conflict_where` behavior — HIGH confidence (project pins `ecto ~> 3.13`; pattern matches existing `ingest.ex`).
- Oban 2.21 community edition `Oban.Plugins.Cron` config shape — HIGH confidence (pinned in project; matches existing `dunning_wiring_test.exs` pattern).
- PostgreSQL 14 `INSERT ... ON CONFLICT DO UPDATE ... WHERE` / `EXCLUDED` pseudo-table — HIGH confidence (PG 14 project floor; standard since PG 9.5).
