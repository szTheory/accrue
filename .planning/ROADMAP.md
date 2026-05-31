# Roadmap: Accrue

## Milestones

- ✅ **v1.46 Maintenance & Closure** — Phases 151–153 (shipped 2026-05-30)
- [ ] **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154–158

## Phases

<details>
<summary>✅ v1.46 Maintenance & Closure (Phases 151–153) — SHIPPED 2026-05-30</summary>

### Phase 151: Maintenance & Triage

**Goal:** Review and address any routine maintenance, dependency updates, or open bugs. Verify that the project remains stable and in a good "done" state.
**Requirements:** MNT-01
**Plans:** 3/3 plans complete

- [x] 151-01-PLAN.md — Resolve webhook caching code-review feedback (ENT-10)
- [x] 151-02-PLAN.md — Update dependencies across the monorepo
- [x] 151-03-PLAN.md — Execute closure criteria validation and publish

### Phase 152: Close v1.46 closure gaps: @since warnings, verification, Hex publish + tag

**Goal:** Fix all malformed @since annotations, run the Three Zeros closure gate green, and cut the linked 1.3.0 Hex release across all three packages (accrue, accrue_admin, accrue_portal).
**Requirements:** D-01 (target 1.3.0), D-02 (@doc since: fix), D-03 (Three Zeros gate), D-04 (Release Please pipeline)
**Depends on:** Phase 151
**Plans:** 3/3 plans complete

- [x] 152-01-PLAN.md — Fix all 8 @since annotations to canonical @doc since: "1.3.0" (dunning.ex ×7, funnel_chart.ex ×1)
- [x] 152-02-PLAN.md — Run Three Zeros closure gate: mix test/dialyzer/credo/coveralls + all verify_*.sh scripts
- [x] 152-03-PLAN.md — Release PR reconciliation: release-notes.md + CHANGELOG + Release Please PR merge + linked Hex publish

### Phase 153: Close v1.46 audit trail: VERIFICATION.md for Phase 151, ROADMAP + REQUIREMENTS checkbox updates

**Goal:** Close the three documentation gaps identified in v1.46-MILESTONE-AUDIT.md: produce 151-VERIFICATION.md from committed evidence, update ROADMAP.md Phase 151 plan checkboxes, update REQUIREMENTS.md MNT-01 to Complete, and archive the v1.46 milestone.
**Requirements:** MNT-01
**Depends on:** Phase 152
**Plans:** 2/2 plans complete

- [x] 153-01-PLAN.md — Create 151-VERIFICATION.md (synthesized from evidence) + update ROADMAP status + update REQUIREMENTS.md MNT-01 + close MILESTONE-AUDIT.md
- [x] 153-02-PLAN.md — Confirm all gaps closed + archive v1.46 milestone via gsd-sdk query milestone complete v1.46

</details>

<details open>
<summary>🔄 v1.47 ENT-10 Polish + Adopter-Proof Completeness (Phases 154–158) — IN PROGRESS</summary>

### Phase 154: Advisory Cache Core Correctness

**Goal:** The advisory cache write path is correct under concurrent delivery — no `Ecto.StaleEntryError`, no silent upsert suppression, and accurate `processor` + `livemode` fields on every written row.
**Depends on:** Phase 153
**Requirements:** ADV-01, ADV-02, ADV-03, ADV-04, POL-01, POL-02
**Success Criteria** (what must be TRUE):
  1. Two concurrent webhook workers delivering entitlement events for the same customer complete without error, and the row reflects the newer event's watermark.
  2. A webhook worker delivering an entitlement event with no prior `last_stripe_event_ts` in the DB updates the row (does not silently no-op).
  3. A stale (out-of-order) write returns `{:ok, :stale}`, emits `result: :unchanged` telemetry, and does not write a ledger event.
  4. A non-Stripe processor's entitlement summary row shows the correct `:processor` value, not the global config default.
  5. A follow-up event that omits the `livemode` key carries forward the prior row's `livemode` rather than overwriting with `nil`.
**Plans:** 1 plan

Plans:
- [x] 154-01-PLAN.md — OCC removal, NULL watermark fix, stale skip path, processor arg threading, livemode carry-forward, concurrent delivery test

### Phase 155: StripeFixtures Polish + Telemetry Counters

**Goal:** Test authors can exercise the livemode-absent code path via a fixture option, and operators can include the two previously-missing malformed/orphan entitlement counters in their telemetry reporter.
**Depends on:** Phase 154
**Requirements:** POL-03, POL-04
**Success Criteria** (what must be TRUE):
  1. A test can call `entitlement_summary_event/2` with `:omit_livemode` and receive a fixture without the `livemode` key, enabling direct coverage of the IN-02 carry-forward path.
  2. Calling `Accrue.Telemetry.Metrics.defaults/0` includes `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]` counters, so operators can wire them into any `telemetry_metrics` reporter.
  3. `StripeFixtures` `@moduledoc` makes clear the module is test-only and not part of the published Hex package.
**Plans:** 1/1 plans complete

Plans:
- [x] 155-01-PLAN.md — Add `omit_livemode` fixture support, test-only `StripeFixtures` docs, and missing entitlement-summary webhook default counters

### Phase 156: Entitlements Gating Adopter Proof

**Goal:** An adopter reading `examples/accrue_host` can see a complete, safe `on_mount` entitlement guard — including the defensive `NotLoaded` case — and understand the required `on_mount` ordering from the router comment.
**Depends on:** Phase 153
**Requirements:** PRF-01
**Success Criteria** (what must be TRUE):
  1. The `Accrue.Live.Entitlements` `on_mount` guard in `examples/accrue_host` handles an unloaded billable association without raising, failing closed in the safe direction.
  2. The router comment documents the required `on_mount` ordering so adopters know where `Accrue.Live.Entitlements` must appear relative to other guards.
  3. Existing positive and negative test cases in `entitlements_guard_test.exs` pass without modification.
**Plans:** TBD

### Phase 157: Metered Usage Adopter Proof

**Goal:** An adopter reading `examples/accrue_host` can see and run a full end-to-end metered usage test — subscribe to a metered price, trigger a usage event, assert the meter row was recorded — with an inline comment clarifying the `value:` vs `quantity:` distinction.
**Depends on:** Phase 153
**Requirements:** PRF-02
**Success Criteria** (what must be TRUE):
  1. A test in `examples/accrue_host` exercises the full path: subscribe to a metered price → trigger Simulate API Call → assert flash confirmation + exactly one `MeterEvent` row.
  2. An inline code comment explains that `value:` must be used (not `quantity:`, which is silently ignored) when submitting meter events.
**Plans:** TBD

### Phase 158: Oban Cron Wiring Adopter Proof

**Goal:** An adopter running `recovery_wiring_test.exs` gets a deterministic pass/fail signal that all four required Oban cron workers and all four required Oban queues are wired in their host config — with a `config.exs` comment showing the safe append-merge pattern for adopters who already have a crontab.
**Depends on:** Phase 153
**Requirements:** PRF-03
**Success Criteria** (what must be TRUE):
  1. `recovery_wiring_test.exs` asserts the presence of all four cron workers: `DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, and `MeteredRenewalReconciler`.
  2. `recovery_wiring_test.exs` asserts all four required Oban queues (`accrue_webhooks`, `accrue_mailers`, `accrue_meters`, `accrue_scheduled`) are declared in host config.
  3. The host `config.exs` includes a comment showing the append-merge pattern, so adopters with an existing crontab know how to add Accrue's workers safely.
**Plans:** TBD

</details>

## Phase Details

### Phase 154: Advisory Cache Core Correctness
**Goal:** The advisory cache write path is correct under concurrent delivery — no `Ecto.StaleEntryError`, no silent upsert suppression, and accurate `processor` + `livemode` fields on every written row.
**Depends on:** Phase 153
**Requirements:** ADV-01, ADV-02, ADV-03, ADV-04, POL-01, POL-02
**Success Criteria** (what must be TRUE):
  1. Two concurrent webhook workers delivering entitlement events for the same customer complete without error, and the row reflects the newer event's watermark.
  2. A webhook worker delivering an entitlement event with no prior `last_stripe_event_ts` in the DB updates the row (does not silently no-op).
  3. A stale (out-of-order) write returns `{:ok, :stale}`, emits `result: :unchanged` telemetry, and does not write a ledger event.
  4. A non-Stripe processor's entitlement summary row shows the correct `:processor` value, not the global config default.
  5. A follow-up event that omits the `livemode` key carries forward the prior row's `livemode` rather than overwriting with `nil`.
**Plans:** 1/1 plans complete

Plans:
- [x] 154-01-PLAN.md — OCC removal, NULL watermark fix, stale skip path, processor arg threading, livemode carry-forward, concurrent delivery test

### Phase 155: StripeFixtures Polish + Telemetry Counters
**Goal:** Test authors can exercise the livemode-absent code path via a fixture option, and operators can include the two previously-missing malformed/orphan entitlement counters in their telemetry reporter.
**Depends on:** Phase 154
**Requirements:** POL-03, POL-04
**Success Criteria** (what must be TRUE):
  1. A test can call `entitlement_summary_event/2` with `:omit_livemode` and receive a fixture without the `livemode` key, enabling direct coverage of the IN-02 carry-forward path.
  2. Calling `Accrue.Telemetry.Metrics.defaults/0` includes `[:accrue, :webhooks, :malformed_entitlement_summary]` and `[:accrue, :webhooks, :orphan_entitlement_summary]` counters, so operators can wire them into any `telemetry_metrics` reporter.
  3. `StripeFixtures` `@moduledoc` makes clear the module is test-only and not part of the published Hex package.
**Plans:** 1/1 plans complete

Plans:
- [x] 155-01-PLAN.md — Add `omit_livemode` fixture support, test-only `StripeFixtures` docs, and missing entitlement-summary webhook default counters

### Phase 156: Entitlements Gating Adopter Proof
**Goal:** An adopter reading `examples/accrue_host` can see a complete, safe `on_mount` entitlement guard — including the defensive `NotLoaded` case — and understand the required `on_mount` ordering from the router comment.
**Depends on:** Phase 153
**Requirements:** PRF-01
**Success Criteria** (what must be TRUE):
  1. The `Accrue.Live.Entitlements` `on_mount` guard in `examples/accrue_host` handles an unloaded billable association without raising, failing closed in the safe direction.
  2. The router comment documents the required `on_mount` ordering so adopters know where `Accrue.Live.Entitlements` must appear relative to other guards.
  3. Existing positive and negative test cases in `entitlements_guard_test.exs` pass without modification.
**Plans:** TBD

### Phase 157: Metered Usage Adopter Proof
**Goal:** An adopter reading `examples/accrue_host` can see and run a full end-to-end metered usage test — subscribe to a metered price, trigger a usage event, assert the meter row was recorded — with an inline comment clarifying the `value:` vs `quantity:` distinction.
**Depends on:** Phase 153
**Requirements:** PRF-02
**Success Criteria** (what must be TRUE):
  1. A test in `examples/accrue_host` exercises the full path: subscribe to a metered price → trigger Simulate API Call → assert flash confirmation + exactly one `MeterEvent` row.
  2. An inline code comment explains that `value:` must be used (not `quantity:`, which is silently ignored) when submitting meter events.
**Plans:** TBD

### Phase 158: Oban Cron Wiring Adopter Proof
**Goal:** An adopter running `recovery_wiring_test.exs` gets a deterministic pass/fail signal that all four required Oban cron workers and all four required Oban queues are wired in their host config — with a `config.exs` comment showing the safe append-merge pattern for adopters who already have a crontab.
**Depends on:** Phase 153
**Requirements:** PRF-03
**Success Criteria** (what must be TRUE):
  1. `recovery_wiring_test.exs` asserts the presence of all four cron workers: `DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, and `MeteredRenewalReconciler`.
  2. `recovery_wiring_test.exs` asserts all four required Oban queues (`accrue_webhooks`, `accrue_mailers`, `accrue_meters`, `accrue_scheduled`) are declared in host config.
  3. The host `config.exs` includes a comment showing the append-merge pattern, so adopters with an existing crontab know how to add Accrue's workers safely.
**Plans:** TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 151. Maintenance & Triage | v1.46 | 3/3 | Complete | 2026-05-30 |
| 152. Close v1.46 closure gaps | v1.46 | 3/3 | Complete | 2026-05-30 |
| 153. Close v1.46 audit trail | v1.46 | 2/2 | Complete | 2026-05-30 |
| 154. Advisory Cache Core Correctness | v1.47 | 1/1 | Complete   | 2026-05-31 |
| 155. StripeFixtures Polish + Telemetry Counters | v1.47 | 1/1 | Complete    | 2026-05-31 |
| 156. Entitlements Gating Adopter Proof | v1.47 | 0/? | Not started | - |
| 157. Metered Usage Adopter Proof | v1.47 | 0/? | Not started | - |
| 158. Oban Cron Wiring Adopter Proof | v1.47 | 0/? | Not started | - |

## Standing Backlog (FRG-03 anchors)

These items are tracked in the v1.17 Friction Inventory and carried forward to future milestones:

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Braintree/multi-processor integration
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Billing portal configuration
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Admin UI role-based access
