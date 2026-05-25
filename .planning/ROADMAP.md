# Roadmap: Accrue

## Active Milestone

🚧 **v1.40 — Dunning depth / notification journeys** (opened **2026-05-24**) — Phases **128–132**.

**Milestone goal:** Promote failed-payment recovery from today's single un-deduped email + grace/terminal sweeper into a first-party, configurable **multi-step dunning journey** (reminder → wait → escalate → final notice) with a customer recovery surface, admin visibility, and provider-honest + Fake-proven behavior. Chimeway is an **optional** engine, not a hard dependency. Also closes the v1.39 adopter-proof gap by demonstrating entitlements gating in `examples/accrue_host`.

**Phase numbering:** continues from v1.39 (ended at Phase 127) → starts at **Phase 128**. Not reset (DEFAULT mode, no `--reset-phase-numbers`).

## Overview

Dunning depth is **net-new product surface over a thin existing baseline** (a single un-deduped failed-payment email + a host-optional, un-wired grace→terminal sweeper), not polish of an existing journey. The build is dependency-ordered around correctness-first: a durable Oban campaign engine + config + the `:invoice_payment_failed` idempotency must-fix + cancel-on-recovery land together as the foundation (Phase 128), because the de-dup fix, the campaign keying, and the cancel-on-recovery guard are tightly-coupled correctness work that everything else inherits its safety contract from. On top of that foundation come the customer recovery surface, the admin dunning-state visibility, and the ledger/telemetry observability (Phase 129); then provider-honest documentation plus the deterministic Fake-lane merge-blocking proof and the default campaign wired into the example host so recovery is demonstrated end-to-end (Phase 130). The optional, off-by-default `Accrue.Integrations.Chimeway` engine adapter is deliberately isolated last (Phase 131) — like v1.39's Phase 127 — so it never blocks the core dunning value. Finally, the folded-in entitlements adopter-proof demo (Phase 132) closes the v1.39 gap by exercising the shipped gate API/guards inside `examples/accrue_host`.

## Phases

**Phase Numbering:**

- Integer phases (128, 129, …): Planned milestone work
- Decimal phases (128.1, …): Urgent insertions (marked INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 128: Campaign Engine Foundation + Idempotency Must-Fix** - Config-driven durable Oban dunning campaign with default journey, the `:invoice_payment_failed` email de-dup fix, and cancel-on-recovery campaign keying (completed 2026-05-24)
- [x] **Phase 129: Customer + Operator Surfaces + Observability** - Portal "update your card" recovery banner, read-only admin dunning-state visibility, and dunning ledger events + telemetry incl. a recovered-vs-lost signal (completed 2026-05-25)
- [ ] **Phase 130: Provider Honesty + Fake-Lane Proof + Example-Host Wiring** - Provider-honest dunning docs with a merge-blocking drift check, the deterministic clock-advanceable Fake-lane journey gate, and the default campaign wired into `examples/accrue_host`
- [ ] **Phase 131: Optional Chimeway Engine Adapter (isolated, off by default)** - `Accrue.Dunning.Engine` behaviour + conditionally-compiled off-by-default `Accrue.Integrations.Chimeway` adapter so a host can swap engines without changing call sites
- [ ] **Phase 132: Entitlements Adopter-Proof Demo** - Entitlement-gated route/page in `examples/accrue_host` exercising the v1.39 gate API/guards end-to-end, with a matching adoption-proof-matrix row

## Phase Details

### Phase 128: Campaign Engine Foundation + Idempotency Must-Fix

**Goal**: Failed-payment recovery runs as a first-party, durable, config-driven multi-step Oban campaign that emails on a host-defined cadence from local `past_due_since` state, never double-sends, and stops the instant payment recovers — replacing today's single un-deduped email.
**Depends on**: Nothing (first phase of this milestone; builds on the shipped Mailglass mailer, `past_due_since` bookkeeping, and existing `dunning:` config)
**Requirements**: DUN-01, DUN-02, DUN-04, DUN-05
**Success Criteria** (what must be TRUE):

  1. A host can declare a multi-step dunning cadence (ordered steps, each with a delay and an email template) under the existing `:dunning` config key, `NimbleOptions`-validated, with a sensible default journey shipped on by default (opt-out, not opt-in); an invalid cadence (including `last_step.after_days > grace_days`) fails loudly at boot rather than silently mis-firing.
  2. When a subscription enters `past_due`, a durable `Accrue.Dunning.Campaign` schedules each step via `Accrue.Workers.DunningStep` from local `past_due_since` state and emails through the existing Mailglass mailer — independent of when/whether the processor re-fires webhooks.
  3. Duplicate processor retries (e.g. repeated `invoice.payment_failed`) never produce duplicate emails: the `:invoice_payment_failed` email is now idempotent (closing the `workers/mailer.ex:292,314` un-deduped gap) and each campaign step is uniquely keyed so a step cannot send twice.
  4. The moment a subscription leaves `past_due` (payment recovered), the in-flight campaign cancels — no further steps or emails fire — and the campaign is keyed to the FIRST nil→past_due transition so subsequent failure webhooks within the same past-due window cannot restart, orphan, or duplicate an in-flight campaign.

**Plans**: 6 plans (2 waves)

Plans:
**Wave 1**

- [x] 128-01-PLAN.md — Config-driven dunning cadence schema + two-layer validation + default journey (DUN-01)
- [x] 128-02-PLAN.md — Nullable campaign anchor column + migration + Subscription predicate (DUN-05 foundation)
- [x] 128-03-PLAN.md — Pure `Accrue.Dunning.Campaign` step resolver + property tests (DUN-02)
- [x] 128-04-PLAN.md — `:invoice_payment_failed` idempotency must-fix + two new step email templates (DUN-04, DUN-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 128-05-PLAN.md — `Accrue.Workers.DunningStep` cancel-guarded, Oban-unique, chained worker (DUN-02, DUN-05)
- [x] 128-06-PLAN.md — Webhook wiring: atomic first-transition elector + cancel-on-recovery + D-15 REPLACE gate (DUN-02, DUN-05)

> **Carried-forward open questions for plan context (do not re-litigate, just honor):**
> - Pin the campaign key to the **first** nil→`past_due` transition, not every `past_due_since` bump — `past_due_since` is bumped on every failure; bumps must not restart/orphan in-flight jobs (add a "campaign already running" guard).
> - The NimbleOptions schema must validate `last_step.after_days <= grace_days` so the final notice precedes the sweeper's grace→terminal action (coherence with `Accrue.Billing.Dunning` / `DunningSweeper`).
> - Idempotency = Oban `unique: [keys: [:subscription_id, :step_key, :campaign_started_at]]` + extending `Mailer.idempotency_key/2` to cover `:invoice_payment_failed`.

### Phase 129: Customer + Operator Surfaces + Observability

**Goal**: A customer with a failed payment is prompted to fix it, an operator can see exactly where a customer is in their dunning journey, and the whole campaign lifecycle is observable through the ledger and telemetry — including the recovered-vs-lost signal merchants care about.
**Depends on**: Phase 128 (campaign engine + ledger events emitted by the campaign)
**Requirements**: DUN-06, DUN-07, DUN-08
**Success Criteria** (what must be TRUE):

  1. A customer with a failed payment sees a recovery prompt ("update your payment method") in `accrue_portal` that deep-links into the existing add/update-payment-method flow.
  2. An operator can see a subscription's/customer's active dunning state (current step, started-at, next scheduled action) in `accrue_admin`, read-only, with every operator string routed through the `AccrueAdmin.Copy` SSOT.
  3. Dunning campaign lifecycle is observable: `accrue_events` ledger entries (`dunning.campaign_started` / `step_sent` / `recovered` / `exhausted`) plus a `[:accrue, :dunning, *]` telemetry family aligned with `guides/telemetry.md` and the operator runbooks.
  4. A recovered-vs-lost signal is derivable as a ledger-query counter (no new table) — an operator/developer can answer "how much past-due revenue did dunning recover vs. lose to terminal action?".

**Plans**: 4 plans

- [x] 129-01-PLAN.md — DUN-08 observability contract: 4 dunning lifecycle ledger + telemetry events at the Phase-128 scope fences + drift-gate triad registration (inventory + metrics + guide)
- [x] 129-02-PLAN.md — DUN-08 recovered-vs-lost ledger-fold counter (`Accrue.Billing.Dunning.recovered_vs_lost/1`, no new table)
- [x] 129-03-PLAN.md — DUN-06 portal recovery banner (conditional `portal-card` section + provider-aware update-PM CTA)
- [x] 129-04-PLAN.md — DUN-07 admin read-only dunning-state `ax-card` (resolver-derived next action, all copy via `AccrueAdmin.Copy`)

**UI hint**: yes

### Phase 130: Provider Honesty + Fake-Lane Proof + Example-Host Wiring

**Goal**: Dunning's per-provider behavior is documented honestly and drift-gated, the full journey is proven deterministically as a merge-blocking gate, and recovery is demonstrated end-to-end in the canonical example host instead of shipping as a dormant cron.
**Depends on**: Phase 128 (campaign engine), Phase 129 (ledger events + surfaces the proof and docs describe)
**Requirements**: DUN-09, DUN-10
**Success Criteria** (what must be TRUE):

  1. Dunning behavior is documented provider-honest in `guides/`: Stripe (Smart Retries timing + Accrue cadence; Test Clocks for the real-Stripe E2E lane), Braintree (Accrue-clock-driven cadence, explicitly NOT retry-aligned), Fake (the deterministic proof lane) — with a lifecycle/capability truth note.
  2. Where per-provider dunning labels are claimed, a merge-blocking drift check fails the build if the runtime labels and the published doc diverge (mirroring the SCM-06 / PROC-24 / entitlements support-contract pattern).
  3. A deterministic, clock-advanceable Fake-lane test proves the full journey — start → step progression → cancel-on-recovery → exhaustion — and runs as a merge-blocking gate (using `Accrue.Clock.utc_now/0`).
  4. The default campaign is wired into `examples/accrue_host` so failed-payment recovery is demonstrated end-to-end, closing the dormant-cron gap (recovery is no longer invisible until an adopter reads a guide and adds a crontab).

**Plans**: 4 plans

- [x] 130-01-PLAN.md — DUN-09 SC#2: `dunning:` capability group (campaign convergence + smart_retry_alignment divergence) in `Capabilities` + 3 adapters + support matrix rows/prose + drift-gate pins & negative convergence guard
- [x] 130-02-PLAN.md — DUN-09 SC#1: provider-honest `guides/dunning.md` (per-provider story, over-email warning, Test Clocks note, lifecycle cross-ref) + light guide-side drift pins
- [ ] 130-03-PLAN.md — DUN-10 SC#3: deterministic full-journey Fake-lane test through the real `DefaultHandler` (start → progression → recovery → exhaustion) + observability assertions + D-09 label mirror
- [ ] 130-04-PLAN.md — DUN-10 SC#4: example-host Oban wiring (`accrue_dunning` queue + Cron sweeper) + Fake-backed host wiring proof + adoption-proof-matrix row & verifier needle

> **Carried-forward note for plan context:** also surface the over-emailing risk — if a host has Stripe Dashboard dunning emails enabled, Accrue's cadence can double-email; ship the default opt-out posture with a documented warning (open question #2).

### Phase 131: Optional Chimeway Engine Adapter (isolated, off by default)

**Goal**: A host can optionally upgrade the dunning engine to Chimeway's orchestration engine without changing any call site, while core `accrue` never requires Chimeway and the default built-in campaign remains the always-on path.
**Depends on**: Phase 128 (the `Accrue.Dunning` campaign engine + the engine seam it generalizes). Final core-dunning slice and deliberately isolated.
**Requirements**: DUN-03
**Success Criteria** (what must be TRUE):

  1. The dunning engine is swappable behind an `Accrue.Dunning.Engine` behaviour; the built-in Oban campaign (default) and any alternate engine satisfy the same contract, so call sites do not change when the engine changes.
  2. An off-by-default `Accrue.Integrations.Chimeway` adapter implements the behaviour, conditionally compiled (à la `Integrations.Sigra`) so core `accrue` neither requires nor pulls Chimeway's schema/migrations/Oban for hosts who only want the built-in cadence.
  3. With Chimeway absent or the engine unset (the default), the entire dunning surface behaves exactly as after Phase 130 — no Chimeway dependency on the default recovery path.
  4. The Chimeway adapter is documented as an opt-in upgrade (SEED-002 #1), targeting Chimeway's **published 1.0.0** public API (resolving the guide-vs-code surface mismatch before coding).

**Plans**: TBD

> **Carried-forward open question for plan context (verify before coding the adapter):** Chimeway's guide and code disagree on the public surface — the guide uses `Chimeway.Workflow` / `Chimeway.Trigger.trigger`, while the code's public entry is `Chimeway.trigger/3` + a `Chimeway.Notifier` behaviour (`workflow/2` callback) + `Chimeway.Signal.track/4`. Pin to and target the published 1.0.0 API; note the local repo's `mix.exs` version string is stale at `0.1.0` while Hex is at `1.0.0` (2026-05-08).

### Phase 132: Entitlements Adopter-Proof Demo

**Goal**: The canonical `examples/accrue_host` demonstrates the v1.39 headline JTBD — gate access on what a customer has paid for — end-to-end, so the flagship entitlements capability is provable in the demo, not just unit-tested in core.
**Depends on**: Nothing in this milestone (independent of dunning; uses the shipped v1.39 entitlements gate API/guards). Sequenced last so it never blocks the dunning core value.
**Requirements**: PROOF-03
**Success Criteria** (what must be TRUE):

  1. `examples/accrue_host` gates at least one route or page on entitlement using the v1.39 gate API/guards (`Accrue.entitled?` / `Accrue.Plug.RequireEntitlement` / `Accrue.Live.Entitlements`) — an entitled billable reaches the gated surface and a non-entitled billable is denied.
  2. The adoption-proof matrix gains a matching row so the entitlement-gating demo is part of the proof-posture contract, closing the "headline JTBD not proven in the demo" gap surfaced by the 2026-05-24 assessment.

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 128 → 129 → 130 → 131 → 132

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 128. Campaign Engine Foundation + Idempotency Must-Fix | v1.40 | 6/6 | Complete    | 2026-05-24 |
| 129. Customer + Operator Surfaces + Observability | v1.40 | 4/4 | Complete    | 2026-05-25 |
| 130. Provider Honesty + Fake-Lane Proof + Example-Host Wiring | v1.40 | 2/4 | In Progress|  |
| 131. Optional Chimeway Engine Adapter (isolated) | v1.40 | 0/TBD | Not started | - |
| 132. Entitlements Adopter-Proof Demo | v1.40 | 0/TBD | Not started | - |

## Notes

- **Critical-path isolation:** Phases 128→129→130 deliver the headline dunning value (a configurable multi-step recovery journey that stops on recovery, with customer + operator surfaces, observability, and an end-to-end host demo) with **no new heavy deps and no hard Chimeway dependency**. Phase 131 (optional Chimeway adapter) and Phase 132 (entitlements adopter-proof) are both isolatable slip-points that must not block the dunning core — Phase 131 mirrors how v1.39 isolated its optional Stripe-native sync to the final phase (127).
- **Must-fix lands in the foundation, not deferred:** the `:invoice_payment_failed` email idempotency bug (DUN-04, `workers/mailer.ex:292,314`) is a correctness must-fix and is pulled into Phase 128 alongside the campaign engine, cancel-on-recovery, and campaign keying — these four are tightly-coupled correctness work.
- **Research flag:** Phase 131 (Chimeway adapter) is the only externally-coupled slice — verify Chimeway's published 1.0.0 public API (guide-vs-code mismatch) before coding; consider `/gsd:plan-phase --research-phase` for it. Phases 128–130 and 132 clone existing Accrue patterns (Oban worker chaining + `unique`, `nimble_options` schema under the existing `dunning:` key, Mailglass templates with `idempotency_key`, `accrue_events` + `[:accrue, :ops, :dunning_*]` telemetry, `Accrue.Clock` deterministic Fake-lane proof, `accrue_admin` Copy/VERIFY-01 discipline, the conditional-compile-à-la-`Integrations.Sigra` pattern, adoption-proof-matrix needles) and need no external research.
- **Bounded — scope-creep guards (out of scope, carried from REQUIREMENTS):** full recovered-revenue analytics dashboard (ship only a ledger-derived counter + telemetry); multi-channel (SMS/push/in-app) dunning (email-only for v1.40; the Chimeway engine unlocks it later); exposing Chimeway's full explain/traces UI in admin; per-customer cadence beyond global config + per-step template overrides; owning/duplicating the processor's retry schedule. Standing non-goals unchanged: FIN-03 finance exports, MRR/ARR analytics product, MoR processors, Hyperwallet.

## Recent Milestones

- ✅ **v1.39 Entitlements / Plan-Gating** — Phases **123–127** shipped & archived **2026-05-24**. Headline JTBD (gate features/access on what a customer paid for), fail-closed local-first with no new tables and no Stripe dependency on the gate path, plus the isolated off-by-default Stripe-native advisory sync. Milestone audit `tech_debt` (DoD achieved, zero blockers). Archives: [milestones/v1.39-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.39-ROADMAP.md), [milestones/v1.39-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.39-REQUIREMENTS.md).
- ✅ **v1.38 Linked Release Truth** — Phases **120–122** shipped **2026-05-08**. Locked the three-package release contract, published the linked `1.1.1` trio with canonical proof in `121-VERIFICATION.md`, and finalized the maintainer-facing planning closeout plus `INV-08` certification in `122-VERIFICATION.md`.
- ✅ **v1.37 Subscription Change Management** — Phases **117–119** shipped **2026-05-07**. Promoted official swap/preview semantics, shipped admin and portal change flows, and finalized bounded Braintree `:plan_resolver` support plus drift gates. Archives: [milestones/v1.37-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-ROADMAP.md), [milestones/v1.37-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-REQUIREMENTS.md).

---
*Last updated: 2026-05-24 — v1.40 roadmap created; Phases 128–132 cover DUN-01..10 + PROOF-03 (11/11 mapped). Phase numbering continues from v1.39 (ended at Phase 127); no reset.*
