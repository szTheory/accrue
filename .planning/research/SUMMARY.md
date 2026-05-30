# Research Summary — v1.47

**Project:** Accrue (Phoenix/Elixir payments + billing library)
**Milestone:** v1.47 — ENT-10 Polish + Adopter-Proof Completeness
**Researched:** 2026-05-30
**Confidence:** HIGH

> Detail lives in the sibling files:
> STACK.md · FEATURES.md · ARCHITECTURE.md · PITFALLS.md

---

## Executive Summary

v1.47 is a correctness-and-closure milestone. The ENT-10 advisory-cache write path (WR-05) has already been partially implemented — the DB-level upsert with `on_conflict_where` is in place in `default_handler.ex` — but three latent bugs remain in `EntitlementSummary.force_changeset/2` and `write_entitlement_summary/8` that undermine the fix's guarantees under concurrency. Separately, four adopter-proof areas (entitlements gating, metered usage, Oban cron wiring, and the StripeFixtures test-support module) exist in the codebase but have gaps in coverage, documentation, or test legibility.

All fixes are in two accrue core files — no new dependencies, no new tables, no migration required. The adopter-proof work is verification and targeted documentation, not new modules.

---

## Stack Additions

No new runtime dependencies. The changes use the already-pinned stack:
- `:ecto ~> 3.13` — `Repo.insert/2` with `on_conflict_where` (available since Ecto 3.5)
- `:oban ~> 2.21` community edition — config-inspection test pattern for cron proof
- `:phoenix_live_view ~> 1.1` — `on_mount` guard chain; no socket runtime in core
- PostgreSQL 14+ — `INSERT ... ON CONFLICT DO UPDATE ... WHERE` with `EXCLUDED` pseudo-table
- `:telemetry ~> 1.3` / `:telemetry_metrics ~> 1.1` — IN-04 adds 1-2 counter lines to `defaults/0`

**What NOT to add:** no `:bypass`, no Oban.Pro, no new `Ecto.Multi` wrapper, no `StaleEntryError` rescue clause.

---

## Feature Table Stakes

### WR-05: Concurrent entitlement summary writes

- Remove `optimistic_lock(:lock_version)` from `EntitlementSummary.force_changeset/2` and remove `lock_version` from `@cast_fields` — the DB-level `on_conflict_where` is the concurrency guard; Ecto OCC is incompatible with the upsert path
- Fix `on_conflict_where` to handle NULL timestamps: `(EXCLUDED.last_stripe_event_ts IS NULL OR e.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts)` — current strict `<` short-circuits to no-op on nil
- After `Repo.insert/2`, compare returned row's `last_stripe_event_ts` against expected; if stale, return `{:ok, :stale}`, skip ledger write, emit `result: :unchanged` telemetry
- Ship with concurrent test: two `Task.async` workers, `Sandbox.allow/3`, assert newer event wins

### IN-01: Processor field accuracy

- `write_entitlement_summary/8` becomes `/9` by adding `processor` as final argument
- Use `to_string(processor)` from the arg, not `processor_name()` (global config lookup)

### IN-02: Livemode null fidelity

- When incoming payload lacks the `livemode` key, carry the prior row's `livemode` forward rather than overwriting with `nil` — mirrors `stamp_summary_watermark/4` pattern

### IN-03: StripeFixtures moduledoc polish

- Update `@moduledoc` to clarify the module lives in `test/support/` and is not part of the published Hex package
- Add `:omit_livemode` option to `entitlement_summary_event/2` so the IN-02 nil-path is testable

### IN-04: Metrics counter

- Add to `Accrue.Telemetry.Metrics.defaults/0`:
  - `counter("accrue.webhooks.malformed_entitlement_summary.count", tags: [:reason])`
  - `counter("accrue.webhooks.orphan_entitlement_summary.count")`

### Adopter-Proof: Entitlements Gating

- Verify existing positive + negative test cases in `entitlements_guard_test.exs` pass
- Add defensive `NotLoaded` guard in `Accrue.Live.Entitlements`; add router comment on `on_mount` order

### Adopter-Proof: Metered Usage

- Extend PROOF-04 or add dedicated test: subscribe to "price_metered" → click Simulate API Call → assert flash + exactly 1 MeterEvent row
- Add inline comment: `# NOTE: use value: not quantity: — quantity: is silently ignored`

### Adopter-Proof: Oban Cron

- Extend `recovery_wiring_test.exs` to assert all four cron workers are in the crontab: `DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, `MeteredRenewalReconciler`
- Assert all four Accrue queues (`accrue_webhooks`, `accrue_mailers`, `accrue_meters`, `accrue_scheduled`) are declared in host config
- Add `config.exs` comment showing the append-merge pattern for adopters who already have a crontab

---

## Architecture Insights

The WR-05 fix is entirely within two files in accrue core: `default_handler.ex` and `entitlement_summary.ex`.

Call chain:
```
DispatchWorker → handle_event → dispatch/5 → reduce_entitlement_summary/4
  → reduce_entitlement_summary_for_customer/7  (Repo.transact)
      → check_stale/2
      → write_entitlement_summary/8 → upsert_entitlement_summary/2
                                    → maybe_record_summary_event/3
```

Key facts:
- The `processor` atom is already threaded through every level except the final `write_entitlement_summary` call — IN-01 is literally the last hop (~3 lines)
- The entitlement gate read path (`Accrue.Live.Entitlements`, `entitled?/2`) reads ONLY from local plan config, never from `accrue_entitlement_summaries` — WR-05 fixes are orthogonal to gate-path adopter-proof tests
- No migration needed — `lock_version` column stays in DB; only the changeset call is removed
- `UNIQUE INDEX (customer_id)` is already present — the upsert conflict target is in place
- All adopter-proof integration points are in `examples/accrue_host/` only

**Build order:**
```
Phase A (154) — WR-05 + IN-01..02 — accrue core; correctness
Phase B (155) — IN-03..04          — additive; can run parallel with A
Phase C (156) — Entitlements proof — examples/accrue_host; independent of A/B
Phase D (157) — Metered usage proof— examples/accrue_host; independent of A/B
Phase E (158) — Oban cron proof    — examples/accrue_host; independent of A/B
```

---

## Watch Out For

1. **`optimistic_lock` silently stalls concurrent upserts** (WR-05) — Remove from `force_changeset/2`; serial tests pass even with this bug, only a `Task.async` concurrent test catches it
2. **NULL `EXCLUDED.last_stripe_event_ts` turns retries into silent no-ops** — Change `on_conflict_where` to handle `NULL` explicitly; without this, retries with no timestamp never update the row but return `{:ok, row}` as if they did
3. **`returning: true` hands back the pre-conflict row on stale skip** — spurious ledger entries follow; compare returned `last_stripe_event_ts` against expected and return `{:ok, :stale}` when mismatched
4. **Missing Oban queue silently stalls all webhook processing** — adopter-proof config must list all four queues; Oban does not error on insert if consumer queue is absent; extend `recovery_wiring_test.exs` to assert queue presence
5. **`active_organization` not preloaded before entitlement guard fires** — `on_mount` order is safety-critical; add defensive `NotLoaded` check in guard and document the constraint

---

## Recommended Phase Structure

| Phase | Name | Goal | Files |
|-------|------|------|-------|
| 154 | Core correctness | Remove `optimistic_lock`, fix NULL watermark, add stale-skip detection, thread `processor` arg; concurrent regression test | `entitlement_summary.ex`, `default_handler.ex`, `entitlement_summary_test.exs` |
| 155 | StripeFixtures + telemetry | Add `:omit_livemode` fixture option, add 2 missing telemetry counters | `stripe_fixtures.ex`, `metrics.ex` |
| 156 | Entitlements proof | Add `NotLoaded` guard, router comment, verify existing test cases | `examples/accrue_host/` |
| 157 | Metered usage proof | Extend PROOF-04 with full path test, add `value:`/`quantity:` comment | `subscription_live_test.exs` |
| 158 | Oban cron proof | Assert all 4 workers + all 4 queues in `recovery_wiring_test.exs`; add config merge comment | `recovery_wiring_test.exs`, `config.exs` |

**Confidence:** HIGH across all areas. Direct source inspection at 2026-05-30.

**Gap to address at plan time:** Verify `optimistic_lock` + `on_conflict_where` interaction at Ecto 3.13 before committing to removal approach (recommendation: minimal repro in scratch test during Phase 154 planning).
