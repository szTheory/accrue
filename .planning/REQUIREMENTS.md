# v1.47 Requirements — ENT-10 Polish + Adopter-Proof Completeness

**Milestone:** v1.47
**Date:** 2026-05-30
**Status:** Active

---

## Advisory Cache Correctness (WR-05)

- [x] **ADV-01** — User (webhook consumer) can deliver concurrent Stripe entitlement events for the same customer without triggering `Ecto.StaleEntryError` or silent upsert suppression (`optimistic_lock(:lock_version)` removed from `EntitlementSummary.force_changeset/2`; `lock_version` removed from `@cast_fields`)
- [x] **ADV-02** — User (webhook consumer) can deliver an entitlement event with no `last_stripe_event_ts` without silently no-oping the row update (`on_conflict_where` handles `NULL` via `(EXCLUDED.last_stripe_event_ts IS NULL OR e.last_stripe_event_ts < EXCLUDED.last_stripe_event_ts)`)
- [x] **ADV-03** — User (operator) can observe whether an entitlement summary write was a live update or a stale skip via telemetry (`result: :unchanged` emitted on stale; `maybe_record_summary_event/3` not called on stale skip)
- [x] **ADV-04** — Developer can verify concurrent delivery correctness via automated test: two `Task.async` workers competing to write the same customer summary, `Sandbox.allow/3` wired, assert the newer event's watermark wins

## Advisory Cache Polish (IN-01..04)

- [x] **POL-01** — User (non-Stripe processor) can see accurate `:processor` field in their entitlement summary row (`write_entitlement_summary/9` uses `to_string(processor)` arg, not `processor_name()` global config)
- [x] **POL-02** — User (operator) can trust that a summary row's `livemode` reflects the most recently known state, not `nil` when a follow-up event omits the key (carry prior `livemode` forward when payload key absent; mirrors `stamp_summary_watermark/4` pattern)
- [x] **POL-03** — Developer can write a test exercising the livemode-absent code path via a `:omit_livemode` fixture option on `entitlement_summary_event/2`; `StripeFixtures` `@moduledoc` clarifies the module is test-only
- [x] **POL-04** — Operator can include `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]` in their Telemetry Metrics reporter by calling `Accrue.Telemetry.Metrics.defaults/0` (both counters added)

## Adopter-Proof: Entitlements Gating

- [x] **PRF-01** — Developer adopting Accrue can see a working `Accrue.Live.Entitlements` `on_mount` guard in `examples/accrue_host` that gracefully handles an unloaded billable association (defensive `NotLoaded` guard + router comment documenting `on_mount` order); existing positive + negative test cases verified passing

## Adopter-Proof: Metered Usage

- [ ] **PRF-02** — Developer adopting Accrue can see and run a full-path metered usage test in `examples/accrue_host`: subscribe to a metered price → trigger Simulate API Call → assert flash confirmation + exactly one `MeterEvent` row; inline `value:` vs `quantity:` comment present

## Adopter-Proof: Oban Crons

- [ ] **PRF-03** — Developer adopting Accrue can verify their host app has all required Oban cron workers and queues wired by running `recovery_wiring_test.exs` — assertions cover all four cron workers (`DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, `MeteredRenewalReconciler`) and all four required Oban queues (`accrue_webhooks`, `accrue_mailers`, `accrue_meters`, `accrue_scheduled`); `config.exs` includes append-merge comment for adopters with existing crontab

---

## Future Requirements (deferred)

- Rich metered/tiered/range entitlement math beyond seat counts — deferred from v1.39
- Atomic seat enforcement / membership management — host-owned; documented recipe
- Typed upstream Stripe Entitlements resources + live API reads — deferred to `lattice_stripe ≥ 1.2`
- Multi-channel (SMS/push) dunning via Chimeway — deferred from v1.45
- SEED-002 ecosystem integration blueprints (Threadline, Scrypath, Relyra) — dormant

## Out of Scope (v1.47)

- **FIN-03 finance exports** — standing non-goal; Accrue is not an accounting system
- **MRR/ARR analytics product** — standing non-goal
- **MoR processors / Hyperwallet** — standing non-goal; closed in v1.33
- **New billing primitives** — v1.47 is correctness + closure only, no new public API surface
- **BillingPortal.Configuration** — deferred to `lattice_stripe 1.2` (Dashboard-managed in interim)

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| ADV-01 | Phase 154 | Complete |
| ADV-02 | Phase 154 | Complete |
| ADV-03 | Phase 154 | Complete |
| ADV-04 | Phase 154 | Complete |
| POL-01 | Phase 154 | Complete |
| POL-02 | Phase 154 | Complete |
| POL-03 | Phase 155 | Complete |
| POL-04 | Phase 155 | Complete |
| PRF-01 | Phase 156 | Complete |
| PRF-02 | Phase 157 | Not started |
| PRF-03 | Phase 158 | Not started |
