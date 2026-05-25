# Phase 129: Customer + Operator Surfaces + Observability - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.
>
> ⚠ **RECONSTRUCTED 2026-05-25 after a mid-session crash.** The original discuss-phase ran 5
> `gsd-advisor-researcher` agents and synthesized a locked package, then crashed before writing any
> file. The advisors' full comparison-table row detail died with the orchestrator context; the tables
> below are reconstructed from the session's preserved conclusions (re-grounded in `file:line` anchors
> re-verified by two `Explore` agents this session). One row (admin next-action source) is a
> reconstruction inference — flagged inline and in CONTEXT.md.

**Date:** 2026-05-25 (reconstructed)
**Phase:** 129-customer-operator-surfaces-observability
**Areas discussed:** Telemetry family + event taxonomy · `dunning.exhausted` vs existing
terminal-action event · recovered-vs-lost counter API · portal recovery banner · admin dunning-state
panel + next-action source

**Mode:** Cohesive one-shot synthesis (project standing posture — `discuss_high_impact_confirm_bar`
+ memory `feedback_decision_synthesis_style`). Five parallel `gsd-advisor-researcher` agents, one per
gray area; each produced a comparison table + single recommendation + high-impact-fork flag. No fork
tripped the "irreversible / externally-published maintainer commitment / genuine product-vision" bar
(the lib is pre-1.0 and these surfaces are unshipped; all forks are config/event-payload reversible),
so all five were auto-resolved into the cohesive package in CONTEXT.md. No AskUserQuestion forks
surfaced; user sanity-checks at CONTEXT/PR review.

---

## Telemetry family + event taxonomy (DUN-08)

| Option | Description | Selected |
|--------|-------------|----------|
| A. `[:accrue, :ops, :dunning_*]` family (4 new events) | Joins the shipped + drift-gated ops namespace; mirrors `[:accrue, :ops, :dunning_exhaustion]` | ✓ |
| B. `[:accrue, :dunning, *]` literal (per DUN-08/ROADMAP wording) | New telemetry root; forks the contract, bypasses `telemetry_ops_inventory.ex` | |
| C. Ledger events only, no telemetry | Loses live metrics; under-delivers DUN-08's "telemetry family" | |

**User's choice:** A (advisor recommendation) — **the one conscious deviation.** Four events
`[:accrue, :ops, :dunning_campaign_started | :dunning_step_sent | :dunning_recovered |
:dunning_exhausted]`, mirroring the existing exhaustion event's `%{count: 1}` + `source` shape. Dotted
ledger type strings (`dunning.campaign_started`/`step_sent`/`recovered`/`exhausted`) alongside, matching
`dunning.terminal_action_requested`.
**Notes:** DUN-08 literally spells `[:accrue, :dunning, *]`, but `[:accrue, :ops, :dunning_exhaustion]`
is already shipped (`default_handler.ex:764-781`), declared (`metrics.ex:72`), and **enforced**
(`telemetry_ops_inventory.ex` `expected_ops_events/0`). A parallel `:dunning` root would fork the one
enforced namespace. Deviation is intentional + documented prominently. Hard exit criterion: register
every new event in inventory + `metrics.ex` + `guides/telemetry.md` or the build breaks. Emit at the
Phase-128 scope fences (`default_handler.ex:802-803/887-888`, `dunning_step.ex:41-47`) + the
first-transition elector. Additive/reversible (event names are not a pre-1.0 published commitment).

## `dunning.exhausted` vs existing `terminal_action_requested` — double-count avoidance (DUN-08)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Count "lost" from the existing `dunning.terminal_action_requested` | Reuses an existing event, but it's request-time + sweeper-only → miscounts | |
| B. New `dunning.exhausted` at the confirmed transition; count "lost" from it only | All sources; transition-confirmed; existing event stays a distinct audit entry | ✓ |
| C. Emit both and dedup in the query | Fragile; couples the counter to two event semantics | |

**User's choice:** B (advisor recommendation). `dunning.exhausted` fires at the confirmed status
transition (beside the existing `[:accrue, :ops, :dunning_exhaustion]` telemetry,
`default_handler.ex:764-781`), covering sweeper/stripe-native/manual. The recovered-vs-lost fold reads
ONLY `dunning.recovered` vs `dunning.exhausted`.
**Notes:** `dunning.terminal_action_requested` (`dunning_sweeper.ex:108-117`) is request-intent
(sweeper-only) and is deliberately excluded from the counter → structurally impossible to double-count
"lost". The two events stay distinct (audit vs lifecycle).

## Recovered-vs-lost counter API (DUN-08 SC#4)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Ledger fold via existing `Events.bucket_by/2` / type-count, no new table | recovered = count(`dunning.recovered`), lost = count(`dunning.exhausted`) | ✓ |
| B. New `accrue_dunning_outcomes` rollup table | Violates no-new-table; premature for a derivable signal | |
| C. Derive live from Oban/subscription state | Not historical; can't answer "how much recovered vs lost over time" | |

**User's choice:** A (advisor recommendation). A small `%{recovered:, lost:}` query function
(planner's discretion: `Accrue.Dunning` vs `Accrue.Events`) over `accrue_events`, using the existing
`bucket_by/2` type-filter substrate (`events.ex:326`, `bucket_query/1`:354-362).
**Notes:** Honors the standing no-new-table stance; the milestone explicitly deferred the full
recovered-revenue dashboard, so a derivable counter (SC#4 wording: "derivable as a ledger-query
counter") is exactly the bar. Time-bucketing via `bucket_by/2` only if a window is wanted.

## Customer portal recovery banner (DUN-06)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Conditional `<section>` banner in the portal subscription LiveView, provider-aware CTA | Uses already-loaded `@subscription`; no new route/layout; CTA resolves per `processor` | ✓ |
| B. New global banner component in the root layout | No component exists; over-scopes a one-condition prompt; needs cross-cut data | |
| C. Hardcode the CTA to `/payment-methods/new` | `add_payment_method_live` is Braintree-only → breaks for Stripe/other | |

**User's choice:** A (advisor recommendation). Conditional banner in
`accrue_portal/.../subscription_live.ex` (render ~:153-154), gated on `Subscription.past_due?/1` /
`dunning_campaign_active?/1` (already on the loaded struct), CTA target resolved off
`subscription.processor` reusing the `card_expiring_soon.ex` `@update_pm_url` precedent.
**Notes:** No banner component exists (only flash; minimal root layout). Conditional-render precedents
already in the portal LiveView (:70/:198). Braintree → `/payment-methods/new` (router.ex:91);
Stripe/others → provider update-PM destination. Provider-aware CTA is the load-bearing correctness
point (the add-PM live is Braintree-only).

## Admin dunning-state panel + next-action source (DUN-07)

| Option | Description | Selected |
|--------|-------------|----------|
| A. New read-only `ax-card` panel cloning related-billing/timeline card; Copy-routed strings | Reuses ax-card + `Events.timeline_for/3` + `AccrueAdmin.Copy` SSOT | ✓ |
| Next-action (a) pure resolver `Campaign.next_step/3` | Decoupled, deterministic, already built, engine-seam-clean | ✓ *(reconstruction inference)* |
| Next-action (b) `Oban.Job` query for next pending `DunningStep` | Reflects the actual enqueued job; precedent in `webhook_live.ex` | |

**User's choice:** A (advisor recommendation) for the panel. ⚠ **Next-action source = (a) pure
resolver is a RECONSTRUCTION INFERENCE** — the scout listed the fork as "Oban-query vs pure-resolver"
and a coherent choice was locked last session, but its exact text was not in the recovered summary.
Reconstruction picks the pure resolver (`Campaign.next_step/3`, `campaign.ex:79-94`) as primary, with
the Oban job's `scheduled_at` as the authoritative next-fire timestamp if cheaply available. **Confirm
or flip at CONTEXT review.**
**Notes:** Read-only panel; state from `dunning_campaign_active?/1` + `dunning_campaign_started_at`;
step history via `Events.timeline_for("Subscription", id)` filtered to `dunning.*`. All strings via
`AccrueAdmin.Copy` (`copy/subscription.ex` defs → `copy.ex` delegate → `Copy.dunning_*()` calls).

## Claude's Discretion
- Counter home module (`Accrue.Dunning` vs `Accrue.Events`) + raw `%{recovered:, lost:}` vs derived rate.
- `dunning_step_sent` telemetry per-step (recommended) vs aggregate.
- Exact `AccrueAdmin.Copy` fn names + whether a `Copy.Dunning` submodule is warranted.
- Exact banner copy/markup + precise per-provider CTA destinations.
- Whether the recovered-vs-lost counter is also surfaced in the admin panel (SC#4 only needs it
  derivable).
- `record_multi/3` (in-transaction) vs `record/1` (post-commit) per emit site.

## Deferred Ideas
- Provider-honest docs + drift gate + Fake-lane journey gate + example-host wiring → DUN-09/10, Phase 130.
- `Accrue.Dunning.Engine` behaviour + Chimeway adapter → DUN-03, Phase 131.
- Entitlements adopter-proof demo → PROOF-03, Phase 132.
- Full recovered-revenue analytics dashboard → milestone Out-of-Scope (counter + telemetry only).
- Multi-channel (SMS/push/in-app) dunning + per-customer cadence → milestone Out-of-Scope.
