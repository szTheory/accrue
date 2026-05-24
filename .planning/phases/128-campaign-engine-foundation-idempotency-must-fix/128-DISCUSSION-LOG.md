# Phase 128: Campaign Engine Foundation + Idempotency Must-Fix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-24
**Phase:** 128-campaign-engine-foundation-idempotency-must-fix
**Areas discussed:** Default journey design · Config DSL + validation · Campaign lifecycle/keying · Idempotency must-fix + step uniqueness

**Mode:** Cohesive one-shot synthesis (project standing posture — `discuss_high_impact_confirm_bar`
+ memory `feedback_decision_synthesis_style`). Four parallel `gsd-advisor-researcher` agents, one per
gray area; each produced a comparison table + single recommendation + high-impact-fork flag. No fork
tripped the "irreversible / externally-published maintainer commitment / genuine product-vision" bar,
so all four were auto-resolved into the cohesive package in CONTEXT.md. No AskUserQuestion forks
surfaced; user sanity-checks at CONTEXT/PR review.

---

## Default journey design (DUN-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Single email (status quo, deduped) | 1 step day 0, reuse InvoicePaymentFailed | |
| B. 2-step (reminder → final) | Day 0, 10; 1 new template | |
| C. 3-step (reminder → action-required → final) | Day 0/5/12; reuse + 2 new templates | ✓ |
| D. 4-step | Day 0/3/7/13; 3 new templates | |

**User's choice:** C (advisor recommendation). 3 escalating steps at absolute offsets `[0, 5, 12]`,
step-1 reuses `Accrue.Emails.InvoicePaymentFailed`, new `DunningActionRequired` + `DunningFinalNotice`;
on-by-default opt-out; `12 ≤ grace_days(14)` leaves a 2-day cushion before the sweeper.
**Notes:** Offsets are a host-overridable config default (tunable in a minor → not a fork). The two new
email module names are the only sticky published commitment — locked now. Every CTA deep-links to the
portal update-card flow. Cross-product evidence: Stripe/Chargebee/Recurly named-stage cadences; avoid
Cashier's hardcoded paths + over-emailing.

## Config DSL + validation (DUN-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A. List-of-keyword-steps under `dunning: [campaign: [enabled:, steps: [[after_days:, key:, template:]]]]` | Absolute days, explicit enabled flag | ✓ |
| B. Flat parallel lists (`campaign_days`/`campaign_templates`) | Index-zip footgun | |
| C. Map keyed by step name | Unordered map fights "ordered cadence" | |
| D. `steps: []` means off (no enabled flag) | Silent-disable footgun | |

**User's choice:** A (advisor recommendation). `{:custom, __MODULE__, :validate_dunning_campaign, []}` on
the `campaign:` key; per-field intra-list validation (strictly-increasing/unique `after_days`, unique
`key`, non-empty-when-enabled) + a hand-written boot cross-field validator for `last_step.after_days <=
grace_days` (NimbleOptions can't cross-validate). Accessors `dunning_campaign/0`,
`dunning_campaign_enabled?/0`, `dunning_campaign_steps/0`.
**Notes:** Mirrors existing `validate_descending/1`, `validate_entitlements_price_ids!/1`, and
`past_due_grace/0` precedents exactly. `key:` is required + load-bearing (→ Oban `step_key` + ledger
label + admin). Absolute days chosen so the grace check is meaningful. Off via `enabled: false` /
`campaign: false`. Additive-safe (new keys append non-breaking).

## Campaign lifecycle / keying / where identity lives (DUN-02, DUN-05)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Nullable column `dunning_campaign_started_at` on subscriptions | Atomic set-once guard; mirrors `dunning_sweep_attempted_at` | ✓ |
| (b) Derive from `past_due_since` | Drifts (bumped every failure) → breaks first-transition pin | |
| (c) Oban meta/tags only | SELECT-then-INSERT TOCTOU race; coupled to retention | |
| (d) `accrue_events` anchor | Append-only can't nil; liveness-by-fold awkward on hot path | |

**User's choice:** (a) (advisor recommendation). Column add (NOT a new table — honors the locked
stance), anchor set via atomic `Repo.update_all WHERE is_nil(...)` in `maybe_bump_past_due_since/2`
(count==1 ⇒ start; count==0 ⇒ already-running no-op). Cancel-on-recovery = proactive
`Oban.cancel_all_jobs` (keyed on `campaign_started_at`) beside `maybe_emit_dunning_exhaustion/2` +
per-step live-state cancel-guard backstop. `Accrue.Workers.DunningStep` on `:accrue_dunning`,
`campaign_started_at` as ISO8601 arg.
**Notes:** First-transition edge = `is_nil(anchor)`, not `status`/`past_due_since`. No fork (forward-only
nullable column is internal storage; ledger event-type strings additive).

## Idempotency must-fix + step uniqueness (DUN-04, DUN-05)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Mailglass metadata only | Swoosh lane gets no key; stamped metadata isn't Mailglass's dedup key (content-hash) → cancels/retry-storms | |
| B. Oban `unique` at enqueue | Lane-independent; conflict?=true no-op; matches step worker | |
| C. Both (Oban `unique` primary + versioned `idempotency_key/2` backstop) | Lane-independent + provider-side belt | ✓ |

**User's choice:** C (advisor recommendation). Primary = Oban `unique` in `Mailer.Default.deliver/2`
mapping **only** `:invoice_payment_failed` (`keys: [:type, :invoice_id], period: :infinity`); backstop =
new `idempotency_key/2` clause `accrue:v1:invoice_payment_failed:<invoice_id>`. Immediate ↔ campaign =
**REPLACE** (campaign owns day-0 when enabled; standalone fires + deduped only when disabled). Step
`unique: keys [:subscription_id, :step_key, :campaign_started_at], period :infinity, states incl
:completed`.
**Notes:** Advisor **corrected the prep-thread premise** — Mailglass does not dedup on stamped metadata
(content-hashes + plain insert → constraint error → Oban retry); only Oban-unique-at-enqueue is clean
and lane-independent. Installed Oban is **2.22.1** (mix.lock), not 2.21. Key on `invoice_id`
(always-present) not `invoice_number` (nullable). Disjoint keyspaces by construction. Versioned keys →
reversible.

## Claude's Discretion
- `Accrue.Dunning.Campaign` module placement (pure resolver vs inlined) — keep pure/property-testable +
  engine-seam-ready for Phase 131.
- Whether step emails also get `idempotency_key/2` backstop clauses (D-17) or rely on step-worker unique.
- Migration timestamp/name; clock call (`Accrue.Clock.utc_now/0` for Fake-lane determinism).
- `do_dispatch_invoice` enabled-gate read (inline vs helper).

## Deferred Ideas
- Dunning ledger events + `[:accrue, :dunning, *]` telemetry + recovered-vs-lost counter → DUN-08, Phase 129.
- Portal recovery banner + admin dunning-state view → DUN-06/DUN-07, Phase 129.
- Provider-honest docs + drift gate + Fake-lane gate + example-host wiring → DUN-09/DUN-10, Phase 130.
- `Accrue.Dunning.Engine` behaviour + Chimeway adapter → DUN-03, Phase 131.
- Entitlements adopter-proof demo → PROOF-03, Phase 132.
- Extending enqueue-`unique` dedup to other email types — out of DUN-04 scope (returns `false` now).
