# Requirements: Accrue — Milestone v1.40

**Defined:** 2026-05-24
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.40 — Dunning depth / notification journeys

**Goal:** Promote failed-payment recovery from today's single un-deduped email + grace/terminal sweeper into a first-party, configurable **multi-step dunning journey** (reminder → wait → escalate → final notice) with a customer recovery surface, admin visibility, and provider-honest + Fake-proven behavior. Chimeway is an **optional** engine, not a hard dependency. Also closes the v1.39 adopter-proof gap by demonstrating entitlements gating in `examples/accrue_host`.

**Source:** `research/JTBD-FRONTIER.md` ranks dunning depth the **#1** remaining JTBD and the only 🟡-bounded item on the canonical revenue loop. Backed by **SEED-002 #1** (Chimeway + Mailglass). Pre-resolved research: `.planning/threads/dunning-depth-milestone-prep.md` (verified baseline, Chimeway dependency verdict, idiomatic Oban-campaign architecture, comparator lessons, "done enough" checklist, open questions) and `.planning/threads/adopter-proof-gaps.md`. Post-v1.39 assessment (2026-05-24) put the lib at ~90–95% done for scope; this is the last important revenue wedge.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Dunning Campaign Engine & Configuration

- [x] **DUN-01**: A host can configure a multi-step dunning cadence (ordered steps, each with a delay and an email template) via `NimbleOptions`-validated config nested under the existing `:dunning` key, with a sensible default journey shipped out of the box (opt-out, not opt-in).
- [ ] **DUN-02**: Failed-payment recovery runs as a first-party durable built-in Oban campaign (`Accrue.Dunning.Campaign` + `Accrue.Workers.DunningStep`) that schedules each step from local `past_due_since` state, independent of when/whether the processor re-fires webhooks, and emits each step's email through the existing Mailglass mailer.
- [ ] **DUN-03**: The dunning engine is swappable behind an `Accrue.Dunning.Engine` behaviour, with an off-by-default `Accrue.Integrations.Chimeway` adapter (conditionally compiled; core `accrue` does not require Chimeway) so a host can upgrade to the Chimeway orchestration engine without changing call sites (SEED-002 #1).

### Correctness & Idempotency

- [ ] **DUN-04**: Failed-payment and dunning-step emails are idempotent — duplicate processor retries (e.g. repeated `invoice.payment_failed`) never produce duplicate emails (fixes today's un-deduped `:invoice_payment_failed`, `workers/mailer.ex:292,314`).
- [ ] **DUN-05**: A dunning journey automatically cancels the moment a subscription leaves `past_due` (payment recovered) — no further steps or emails fire — and is keyed so subsequent failure webhooks within the same past-due window cannot restart or duplicate an in-flight campaign.

### Customer & Operator Surfaces

- [ ] **DUN-06**: A customer with a failed payment sees a recovery prompt ("update your payment method") in `accrue_portal` that deep-links to the existing add/update-payment-method flow.
- [ ] **DUN-07**: An operator can see a subscription/customer's active dunning state (current step, started-at, next scheduled action) in `accrue_admin`, read-only, with all copy routed through the `AccrueAdmin.Copy` SSOT.

### Observability

- [ ] **DUN-08**: Dunning campaign lifecycle is observable — `accrue_events` ledger entries (`dunning.campaign_started` / `step_sent` / `recovered` / `exhausted`) plus `[:accrue, :dunning, *]` telemetry including a recovered-vs-lost signal (ledger-derived counter, no new table) — aligned with `guides/telemetry.md` and the operator runbooks.

### Provider Honesty & Proof

- [ ] **DUN-09**: Dunning behavior is provider-honest and documented — Stripe (Smart Retries timing + Accrue cadence; Test Clocks for the real-Stripe E2E lane), Braintree (Accrue-clock-driven cadence, explicitly not retry-aligned), Fake (deterministic proof lane) — captured in `guides/` with a lifecycle/capability truth note and a merge-blocking drift check where labels are claimed.
- [ ] **DUN-10**: A deterministic, clock-advanceable Fake-lane test proves the full journey (start → step progression → cancel-on-recovery → exhaustion) as a merge-blocking gate, and the default campaign is wired into `examples/accrue_host` so recovery is demonstrated end-to-end (closing the dormant-cron gap).

### Adopter Proof (folded in from the v1.39 gap)

- [ ] **PROOF-03**: The canonical `examples/accrue_host` demonstrates entitlement gating end-to-end (at least one entitlement-gated route/page using the v1.39 gate API/guards), with a matching adoption-proof-matrix row — closing the "headline JTBD not proven in the demo" gap surfaced by the 2026-05-24 assessment.

## Future Requirements

Deferred. Tracked but not in this milestone's roadmap.

- **Multi-channel notification journeys** (SMS / push / in-app) — unlocked by the Chimeway engine once the adapter is in place; v1.40 is email-only.
- **Recovered-revenue analytics dashboard** — v1.40 ships only a ledger-derived counter + telemetry; a charts/reporting surface is a separate milestone (and brushes the MRR/ARR non-goal — keep bounded).
- **Braintree native smart-retry overlay** — only if a sourced adopter need appears; Braintree dunning stays Accrue-clock-driven in v1.40.
- **Admin search** across billing records (SEED-002 #5 / Scrypath) — intake-gated.

## Out of Scope

Explicitly excluded for v1.40. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Hard dependency on Chimeway | Chimeway is `1.0.0`-on-Hex (2026-05-08); a hard dep risks Accrue's zero-breaking-change promise and taxes every install with Chimeway's schema/migrations. Ship a thin built-in default + optional adapter. |
| Full recovered-revenue analytics dashboard | A ledger-derived counter + telemetry is the value; a reporting product brushes the MRR/ARR non-goal. |
| Multi-channel (SMS / push / in-app) dunning | Email-only for v1.40; multi-channel is what the Chimeway engine unlocks later. |
| Exposing Chimeway's full explain/traces UI inside `accrue_admin` | Admin shows basic Accrue dunning state only; deep Chimeway introspection stays in Chimeway. |
| Per-customer cadence customization beyond global config | Global config + per-step template overrides is enough; per-customer journeys are out of scope. |
| Owning/duplicating the processor's retry schedule | Stripe Smart Retries still owns retry timing; Accrue owns the notification cadence + grace/terminal overlay only. |
| FIN-03 finance exports · MRR/ARR analytics product · MoR processors · Hyperwallet | Standing non-goals with written boundaries. |

## Traceability

Which phases cover which requirements. Phases continue from v1.39 (ended at Phase 127) → **v1.40 starts at Phase 128** (no phase-number reset). Mapped by the v1.40 roadmap (`.planning/ROADMAP.md`).

| Requirement | Phase | Status |
|-------------|-------|--------|
| DUN-01 | Phase 128 | Complete |
| DUN-02 | Phase 128 | Pending |
| DUN-04 | Phase 128 | Pending |
| DUN-05 | Phase 128 | Pending |
| DUN-06 | Phase 129 | Pending |
| DUN-07 | Phase 129 | Pending |
| DUN-08 | Phase 129 | Pending |
| DUN-09 | Phase 130 | Pending |
| DUN-10 | Phase 130 | Pending |
| DUN-03 | Phase 131 | Pending |
| PROOF-03 | Phase 132 | Pending |

**Phase map:**

| Phase | Goal (one line) | Requirements |
|-------|-----------------|--------------|
| 128 — Campaign Engine Foundation + Idempotency Must-Fix | Durable config-driven Oban dunning campaign, idempotency must-fix, cancel-on-recovery keying | DUN-01, DUN-02, DUN-04, DUN-05 |
| 129 — Customer + Operator Surfaces + Observability | Portal recovery banner, read-only admin dunning state, ledger events + telemetry + recovered-vs-lost counter | DUN-06, DUN-07, DUN-08 |
| 130 — Provider Honesty + Fake-Lane Proof + Example-Host Wiring | Provider-honest docs + drift gate, deterministic Fake-lane journey gate, default campaign wired into example host | DUN-09, DUN-10 |
| 131 — Optional Chimeway Engine Adapter (isolated) | `Accrue.Dunning.Engine` behaviour + off-by-default conditionally-compiled Chimeway adapter | DUN-03 |
| 132 — Entitlements Adopter-Proof Demo | Entitlement-gated route/page in `examples/accrue_host` + adoption-proof-matrix row | PROOF-03 |

**Coverage:**

- v1.40 requirements: 11 total
- Mapped to phases: 11 ✓ (each to exactly one phase; no orphans, no duplicates)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 — v1.40 roadmap created; DUN-01..10 + PROOF-03 mapped to Phases 128–132 (11/11). Phase numbering continues from v1.39 (ended at Phase 127); no reset.*
