# Phase 129: Customer + Operator Surfaces + Observability - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

> **How these decisions were made:** Per the project's standing cohesive-one-shot-synthesis posture
> (`.planning/config.json` → `discuss_high_impact_confirm_bar`; memory
> `feedback_decision_synthesis_style`), five parallel `gsd-advisor-researcher` agents researched the
> five coupled gray areas (telemetry family + event taxonomy · `dunning.exhausted` vs the existing
> terminal-action event · recovered-vs-lost counter API · portal recovery banner · admin
> dunning-state panel + next-action source) against the live `accrue`/`accrue_admin`/`accrue_portal`
> codebase, the Phase 128 engine + its scope-fenced injection points, the enforced telemetry ops
> inventory, and idiomatic Elixir/Phoenix/LiveView practice. Every fork was judged **additive-safe /
> reversible** (config/event-payload reversible; the lib is pre-1.0 and these surfaces are unshipped)
> — so everything below is **locked and decided**; none met the irreversible/published-commitment
> escalation bar.
>
> ⚠ **RECONSTRUCTED AFTER A CRASH (2026-05-25).** The original discuss-phase session synthesized this
> package and created the phase dir, then the terminal crashed *immediately before writing this file*.
> The advisor agents' detailed comparison tables died with the orchestrator context. This CONTEXT was
> rebuilt from the session's preserved conclusions, **re-grounded in `file:line` anchors re-verified
> this session by two `Explore` agents**. One sub-decision (admin "next scheduled action" source) was
> a stated scout *finding* whose exact prior-session *resolution* was not in the recovered summary — it
> is **explicitly flagged** below as a reconstruction inference for you to confirm. Every other decision
> is verbatim from the locked conclusions.
>
> **The one conscious deviation (not an inference):** DUN-08 / the ROADMAP literally spell the telemetry
> family `[:accrue, :dunning, *]`, but the shipped-and-enforced idiom is `[:accrue, :ops, :dunning_*]`.
> We reconcile to `:ops` (decision group A). This was explicitly called out as "the one conscious
> deviation" in the crashed session and is documented prominently here.

<domain>
## Phase Boundary

**DUN-06, DUN-07, DUN-08 only.** On top of the Phase 128 durable campaign engine, make the dunning
journey **visible and observable** from three angles:
- **Customer (DUN-06):** a past-due customer sees a recovery prompt ("update your payment method") in
  `accrue_portal` that deep-links the existing add/update-payment-method flow.
- **Operator (DUN-07):** an operator sees a subscription's active dunning state (current step,
  started-at, next scheduled action) in `accrue_admin`, **read-only**, every string routed through the
  `AccrueAdmin.Copy` SSOT.
- **Observability (DUN-08):** the campaign lifecycle emits `accrue_events` ledger entries
  (`dunning.campaign_started` / `step_sent` / `recovered` / `exhausted`) + an aligned telemetry family,
  and a **recovered-vs-lost** signal is derivable as a ledger-query counter (no new table).

**In scope:** the four dunning ledger event types + their telemetry emissions at the Phase-128
scope-fence points; registration in the enforced ops inventory + `metrics.ex` + `guides/telemetry.md`;
the recovered-vs-lost ledger-fold query; the portal recovery banner (provider-aware CTA); the admin
read-only dunning-state `ax-card` panel + its Copy strings.

**Out of scope (explicitly later phases — do NOT pull forward):**
- Provider-honest dunning docs + merge-blocking drift check + deterministic Fake-lane journey gate +
  default-campaign wiring into `examples/accrue_host` → DUN-09/DUN-10, **Phase 130**.
- `Accrue.Dunning.Engine` behaviour + off-by-default Chimeway adapter → DUN-03, **Phase 131**.
- Entitlements adopter-proof demo → PROOF-03, **Phase 132**.
- Full recovered-revenue analytics dashboard → **milestone Out-of-Scope** (carried). DUN-08 ships the
  ledger counter + telemetry only — a *derivable* signal, not a dashboard.
- Multi-channel (SMS/push/in-app) dunning surfaces → **milestone Out-of-Scope** (carried).

</domain>

<decisions>
## Implementation Decisions

### A. Telemetry family + event taxonomy (DUN-08 — observability contract) — the conscious deviation
- **D-01 — Telemetry family = `[:accrue, :ops, :dunning_*]`, NOT `[:accrue, :dunning, *]`.** The
  shipped + enforced idiom: `[:accrue, :ops, :dunning_exhaustion]` is emitted at
  `accrue/lib/accrue/webhook/default_handler.ex:764-781` (`maybe_emit_dunning_exhaustion/2`), declared
  at `accrue/lib/accrue/telemetry/metrics.ex:72` (`counter("accrue.ops.dunning_exhaustion.count",
  tags: [:source])`), and **drift-gated** by
  `accrue/test/support/telemetry_ops_inventory.ex` (`expected_ops_events/0`). New campaign-lifecycle
  telemetry events join that family:
  | Lifecycle moment | Telemetry event | Measurements | Key metadata |
  |---|---|---|---|
  | Campaign opens | `[:accrue, :ops, :dunning_campaign_started]` | `%{count: 1}` | `subscription_id`, `step_count` |
  | A step email goes out | `[:accrue, :ops, :dunning_step_sent]` | `%{count: 1}` | `subscription_id`, `step_key`, `step_index` |
  | Payment recovers, campaign cancels | `[:accrue, :ops, :dunning_recovered]` | `%{count: 1}` | `subscription_id`, `source` |
  | Campaign ends in loss | `[:accrue, :ops, :dunning_exhausted]` | `%{count: 1}` | `subscription_id`, `to_status`, `source` |
  This **deviates from DUN-08's literal `[:accrue, :dunning, *]` spelling on purpose** — it preserves the
  one established ops namespace and stays inside the existing drift gate (a parallel `:dunning` root
  would fork the contract and bypass the inventory). Mirror the existing exhaustion event's
  measurement/metadata shape (`%{count: 1}` + `source` enum `:accrue_sweeper | :stripe_native |
  :manual`).
- **D-02 — Ledger event type strings stay dotted, matching the existing convention.** The four
  `accrue_events` types are `"dunning.campaign_started"`, `"dunning.step_sent"`, `"dunning.recovered"`,
  `"dunning.exhausted"` — consistent with the already-recorded
  `"dunning.terminal_action_requested"` (`accrue/lib/accrue/jobs/dunning_sweeper.ex:108-117`). Write via
  `Accrue.Events.record/1` (`accrue/lib/accrue/events.ex:109`) with
  `subject_type: "Subscription", subject_id: sub.id, data: %{...}` — the exact shape the sweeper already
  uses. Prefer `record_multi/3` (`events.ex:135`) where the emission is inside an existing
  `Ecto.Multi`/transaction at the emit site so the ledger write is atomic with the state change.
- **D-03 — Emission points = the Phase-128 scope fences (already pre-marked in the source).** Do not
  hunt for sites — Phase 128 left exact fences:
  - `default_handler.ex:802-803` — "emits NO `dunning.recovered` ledger event / telemetry (Phase 129)"
    → emit `dunning.recovered` (ledger + telemetry) here, on the past_due→active/paid recovery
    transition (the sibling of `maybe_finalize_dunning_campaign/2`).
  - `default_handler.ex:887-888` — the error/terminal-path fence ("that family is Phase 129").
  - `dunning_step.ex:41-47` — the `## Scope fence` block ("this worker emits NO ledger events and NO
    telemetry") → emit `dunning.step_sent` (ledger + telemetry) after a step email is delivered.
  - **Campaign-started** is emitted in the first-transition elector
    (`maybe_bump_past_due_since/2`, the `count == 1` winner branch) where the campaign actually opens.
- **D-04 — Drift-gate obligation is a HARD exit criterion.** Every new `[:accrue, :ops, :dunning_*]`
  event MUST be (a) added to `expected_ops_events/0` in `telemetry_ops_inventory.ex`, (b) declared in
  `metrics.ex` (counters mirroring `dunning_exhaustion.count`, line 72), and (c) documented in
  `accrue/guides/telemetry.md` (the ops catalog at ~:89 and the operator runbook at ~:446). If a new
  event is emitted but not registered in all three, the inventory gate breaks the build — which is the
  intended contract enforcement, not an obstacle.

### B. `dunning.exhausted` vs the existing terminal-action event — no double-counting "lost" (DUN-08)
- **D-05 — Two distinct moments, kept distinct.** The sweeper already records
  `"dunning.terminal_action_requested"` at **request time** (sweeper-only — when Accrue *asks* the
  processor to move the sub to `:unpaid`/`:canceled`, `dunning_sweeper.ex:108-117`). The new
  `dunning.exhausted` fires at the **confirmed status transition** (the same authoritative point as the
  existing `[:accrue, :ops, :dunning_exhaustion]` telemetry, `default_handler.ex:764-781`) and covers
  **all** loss sources (sweeper / stripe-native / manual), not just the Accrue sweeper.
- **D-06 — "Lost" is counted from `dunning.exhausted`, never from `terminal_action_requested`.** The
  request-time event is intent (and may exist where no campaign was running); the transition-confirmed
  `dunning.exhausted` is the canonical "this campaign ended in loss" signal. The recovered-vs-lost fold
  (group C) reads **only** `dunning.recovered` vs `dunning.exhausted` — campaign-lifecycle events at
  confirmed transitions — so the existing sweeper event can never double-count. Emit `dunning.exhausted`
  (ledger) right beside the existing exhaustion telemetry at the transition point.

### C. Recovered-vs-lost counter (DUN-08 SC#4) — ledger fold, no new table
- **D-07 — Thin fold over the existing ledger via the existing query primitive.**
  `Accrue.Events.bucket_by/2` (`accrue/lib/accrue/events.ex:326`; the type-filter lives in
  `bucket_query/1` at :354-362, which already does `where(q, [e], e.type in ^types)`) already
  filters/folds events by type. The counter is: **recovered = count(`dunning.recovered`)**, **lost =
  count(`dunning.exhausted`)**, over an optional `since:`/`until:` window. **No new table** (honors the
  standing no-new-table stance — the milestone explicitly deferred the full dashboard).
- **D-08 — A small named query function answers the operator question.** Add a function (planner's
  discretion on home module — `Accrue.Dunning` (`accrue/lib/accrue/billing/dunning.ex`, alongside
  `compute_terminal_action/2`) is the natural fit, or `Accrue.Events`) returning a
  `%{recovered: n, lost: n}` (and optionally a rate) so an operator/developer can answer "how much
  past-due revenue did dunning recover vs. lose to terminal action?". A simple grouped count is fine if
  windowed bucketing is unneeded; `bucket_by/2` is the reuse path if time-bucketing is wanted.

### D. Customer portal recovery banner (DUN-06)
- **D-09 — A conditional banner section in the portal subscription LiveView, not a new layout slot.**
  No reusable banner/alert component exists (only flash; the root layout
  `accrue_portal/lib/accrue_portal/layouts.ex` is minimal). Render a conditional `<section>` in
  `accrue_portal/lib/accrue_portal/live/subscription_live.ex` (render region ~:153-154, before the main
  `portal-card`), gated on dunning/past-due state. Follow the existing portal conditional-render
  precedents (`subscription_live.ex:70` `<%= if ... %>`, `:198` `:if={...}`).
- **D-10 — Gate on the subscription state already loaded in the portal.** `mount/3`
  (`subscription_live.ex:11-34`) assigns the full `%Subscription{}` via `Authorize.subscription/2`, so
  `Subscription.past_due?/1` (`accrue/lib/accrue/billing/subscription.ex:156-158`) and
  `Subscription.dunning_campaign_active?/1` (`subscription.ex:269-272`, reads the Phase-128
  `dunning_campaign_started_at` column at `subscription.ex:66`) are directly callable — no new query.
  Show the banner when the customer is past-due / has an active campaign.
- **D-11 — The CTA target is provider-aware.** `add_payment_method_live.ex` is **Braintree-only**
  (hardcoded `BraintreeClient.client_token_for/1`, route `/payment-methods/new` at
  `accrue_portal/lib/accrue_portal/router.ex:91`). A generic "update your card" link cannot assume it.
  Resolve the CTA off `subscription.processor` (the portal already reads `@subscription.processor`,
  `subscription_live.ex:259/265`): Braintree → `/payment-methods/new`; Stripe/others → the provider's
  update-PM destination. Reuse the URL-resolution precedent in
  `accrue/lib/accrue/emails/card_expiring_soon.ex` (`@update_pm_url`) so the banner CTA and the email
  CTA resolve consistently.

### E. Admin read-only dunning-state panel (DUN-07)
- **D-12 — A new `ax-card` panel in the admin subscription detail LiveView.** Add to
  `accrue_admin/lib/accrue_admin/live/subscription_live.ex` by cloning an existing card — the
  related-billing inline `ax-card` (:175-217) or the ledger-timeline card (:449-460). **Read-only** (no
  actions). Show: campaign active? (`dunning_campaign_active?/1`), current step + started-at
  (`dunning_campaign_started_at`), and next scheduled action (D-14).
- **D-13 — Every operator string through `AccrueAdmin.Copy`.** Add new `def`s to
  `accrue_admin/lib/accrue_admin/copy/subscription.ex` (or a new `AccrueAdmin.Copy.Dunning`
  submodule), `defdelegate` them in `accrue_admin/lib/accrue_admin/copy.ex`, and call as
  `Copy.dunning_*()` in the template — mirroring `Copy.subscription_drill_related_card_title()`
  (`subscription_live.ex:177`). Campaign step history can reuse `Events.timeline_for("Subscription",
  id, ...)` (`accrue/lib/accrue/events.ex:262`, already used at `subscription_live.ex:539`) filtered to
  the `dunning.*` types from D-02.
- **D-14 — "Next scheduled action" source = the pure resolver (⚠ FLAGGED INFERENCE — confirm at
  review).** Two sources exist: (a) the pure resolver `Accrue.Dunning.Campaign.next_step/3`
  (`accrue/lib/accrue/dunning/campaign.ex:79-94`, returns `{:next, step, schedule_in} | :done`) called
  with `Config` steps + `dunning_campaign_started_at` + `now`; (b) an `Oban.Job` query for the next
  pending `"Accrue.Workers.DunningStep"` (precedent:
  `accrue_admin/lib/accrue_admin/live/webhook_live.ex`). **Reconstruction picks (a) the pure resolver**
  as primary (decoupled from Oban internals, deterministic, already built, engine-seam-clean for Phase
  131), with the Oban job's `scheduled_at` as the authoritative next-fire *timestamp* if cheaply
  available. **This one sub-decision's exact prior-session resolution was not in the recovered summary**
  — the scout listed it as "Oban-query vs pure-resolver" and a coherent choice was locked, but its text
  is lost. Confirm or flip at CONTEXT review.

### Claude's Discretion (planner decides)
- Home module for the recovered-vs-lost counter (`Accrue.Dunning` vs `Accrue.Events`) and whether it
  returns a raw `%{recovered:, lost:}` or also a derived rate.
- Whether `dunning_step_sent` telemetry is per-step (one event per send, with `step_key`) or aggregate
  — per-step recommended for parity with the per-step ledger entry.
- Exact `AccrueAdmin.Copy` function names + whether a dedicated `Copy.Dunning` submodule is warranted.
- Exact banner copy/markup and the precise per-provider CTA destinations (Stripe update-PM path).
- Whether the recovered-vs-lost counter is *also* surfaced in the admin panel or stays a query API —
  SC#4 only requires it be **derivable**; surfacing is a nice-to-have.
- Whether `dunning.exhausted` / `dunning.recovered` ledger writes use `record_multi/3` (in-transaction)
  or `record/1` (post-commit) at each emit site, per local atomicity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & milestone context (read first)
- `.planning/ROADMAP.md` — Phase 129 goal + SC#1–4 (portal banner · admin dunning state · ledger
  events + telemetry · recovered-vs-lost counter) + the phase-boundary split (docs/Fake-lane/host
  wiring = Phase 130).
- `.planning/REQUIREMENTS.md` — DUN-06, DUN-07, DUN-08 (this phase); DUN-09/10 + DUN-03 + PROOF-03
  (later-phase out-of-scope boundary).
- `.planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-CONTEXT.md` — the engine
  this phase observes/surfaces; **read the scope-fence notes** (D-11/D-12 there explicitly deferred the
  ledger/telemetry to here) and the anchor/predicate names (`dunning_campaign_started_at`,
  `dunning_campaign_active?/1`, `Accrue.Dunning.Campaign.next_step/3`, `Accrue.Workers.DunningStep`).

### Observability anchors (DUN-08)
- `accrue/lib/accrue/events.ex` — `record/1`:109, `record_multi/3`:135, `timeline_for/3`:262,
  `bucket_by/2`:326 + type-filter `bucket_query/1`:354-362.
- `accrue/lib/accrue/webhook/default_handler.ex` — `maybe_emit_dunning_exhaustion/2`:764-781 (the
  `[:accrue, :ops, :dunning_exhaustion]` emission to mirror); scope fences :802-803 + :887-888.
- `accrue/lib/accrue/workers/dunning_step.ex` — `## Scope fence`:41-47 (the `step_sent` emit point).
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` — `"dunning.terminal_action_requested"` ledger
  write:108-117 (the request-time event to keep distinct from `dunning.exhausted`).
- `accrue/lib/accrue/telemetry/metrics.ex` — `counter("accrue.ops.dunning_exhaustion.count", tags:
  [:source])`:72 (declaration pattern for the new counters).
- `accrue/test/support/telemetry_ops_inventory.ex` — `expected_ops_events/0` (the drift gate; register
  every new event here).
- `accrue/guides/telemetry.md` — ops catalog ~:89 + operator runbook ~:446 (the published contract to
  extend).

### Customer-surface anchors (DUN-06)
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` — `mount/3`:11-34, render region :153-154,
  conditional-render precedents :70/:198, `@subscription.processor` reads :259/:265.
- `accrue_portal/lib/accrue_portal/router.ex` — `/payment-methods/new` route:91 (+ `POST` :63).
- `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` — Braintree-only CTA target:1-79.
- `accrue_portal/lib/accrue_portal/layouts.ex` — minimal root layout (no banner component exists).
- `accrue/lib/accrue/billing/subscription.ex` — `past_due?/1`:156-158,
  `dunning_campaign_active?/1`:269-272, `dunning_campaign_started_at`:66.
- `accrue/lib/accrue/emails/card_expiring_soon.ex` — `@update_pm_url` provider-CTA resolution precedent.

### Operator-surface anchors (DUN-07)
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — clone targets: related-billing
  card:175-217, timeline card:449-460; `timeline_events/1`:539; Copy call sites :177/:250.
- `accrue_admin/lib/accrue_admin/components/tax_ownership_card.ex` — reusable `ax-card` component
  pattern:21.
- `accrue_admin/lib/accrue_admin/copy.ex` (delegator) + `accrue_admin/lib/accrue_admin/copy/subscription.ex`
  (string defs) — the SSOT to extend.
- `accrue/lib/accrue/dunning/campaign.ex` — `next_step/3`:79-94 (pure resolver for "next action").
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` — `Oban.Job` query precedent (alternative
  next-action source per the D-14 flag).

### External (verify-before-coding)
- `:telemetry` event/measurement/metadata conventions + `Telemetry.Metrics` counter semantics:
  https://hexdocs.pm/telemetry · https://hexdocs.pm/telemetry_metrics — match the existing ops events.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (clone, don't reinvent)
- **Ledger write shape:** `Events.record/1` + `record_multi/3` with `subject_type/subject_id/data` —
  the sweeper's `"dunning.terminal_action_requested"` write is the exact template (D-02).
- **Telemetry emission shape:** `maybe_emit_dunning_exhaustion/2` (`%{count: 1}` + `source` enum) —
  clone for the four new `[:accrue, :ops, :dunning_*]` events (D-01).
- **Type-filtered ledger query:** `Events.bucket_by/2` / `bucket_query/1` — the recovered-vs-lost fold
  substrate (D-07).
- **`ax-card` panels + `Events.timeline_for/3`:** admin SubscriptionLive related-billing/timeline
  cards — clone for the dunning-state panel (D-12/D-13).
- **`AccrueAdmin.Copy` delegator + submodule:** the operator-string SSOT — extend for all panel copy
  (D-13).
- **Portal conditional-render + `@subscription` state:** `subscription_live.ex` `if`/`:if` precedents +
  the already-loaded subscription struct — the banner needs no new data load (D-09/D-10).
- **Provider-CTA resolution:** `card_expiring_soon.ex` `@update_pm_url` — the provider-aware target
  precedent for the banner CTA (D-11).
- **Pure step resolver:** `Accrue.Dunning.Campaign.next_step/3` — the decoupled "next action" source
  (D-14).

### Established Patterns (constrain this phase)
- **The `:ops` telemetry namespace is the single enforced family** — `telemetry_ops_inventory.ex`
  gates it. New dunning telemetry joins `:ops`; it does NOT open a `[:accrue, :dunning, *]` root (D-01).
- **Dotted ledger type strings** (`"<domain>.<event>"`) — the new events follow `dunning.*` (D-02).
- **Read-only admin surfaces + Copy SSOT** — the dunning panel performs no mutations and hardcodes no
  strings (D-12/D-13).
- **No-new-table / reuse-existing** — the counter folds `accrue_events`; the panel/banner read existing
  subscription + ledger state (D-07/D-10).

### Integration Points
- DUN-08 emit sites are **pre-marked** by Phase-128 scope fences (`default_handler.ex:802-803/887-888`,
  `dunning_step.ex:41-47`) + the first-transition elector — drop the ledger+telemetry in there; the
  drift gate (`telemetry_ops_inventory.ex` + `metrics.ex` + `telemetry.md`) must be updated in lockstep
  (D-03/D-04).
- DUN-06 mounts in the existing portal subscription LiveView render tree (no new route, no new layout
  slot) with a provider-aware CTA (D-09–D-11).
- DUN-07 mounts as a new `ax-card` in the existing admin subscription LiveView (no new route),
  read-only, Copy-routed (D-12–D-14).
- **Engine-seam readiness (Phase 131):** keep emissions/labels keyed on `step_key` +
  `campaign_started_at` so a later `Accrue.Dunning.Engine` adapter emits the same observable contract.

</code_context>

<specifics>
## Specific Ideas

- **One observable contract across ledger + telemetry:** the four lifecycle moments
  (`campaign_started`/`step_sent`/`recovered`/`exhausted`) each emit BOTH a dotted ledger event (audit
  trail / counter substrate) AND an `[:accrue, :ops, :dunning_*]` telemetry event (live metrics) at the
  same site — so the recovered-vs-lost answer is derivable from the ledger and observable in real time.
- **"Lost" has exactly one canonical source:** `dunning.exhausted` at the confirmed transition. The
  pre-existing `dunning.terminal_action_requested` (request-time, sweeper-only) stays an audit event and
  is deliberately excluded from the counter — structurally impossible to double-count.
- **Both customer surfaces resolve the update-PM target the same provider-aware way** (`processor` +
  the `card_expiring_soon` precedent), so the banner CTA and the dunning emails never diverge.
- **The admin panel is pure read-over-existing-state** — `dunning_campaign_active?/1` +
  `dunning_campaign_started_at` + `next_step/3` + `timeline_for/3`; no new persistence, no new query
  layer.

</specifics>

<deferred>
## Deferred Ideas

- **Provider-honest dunning docs + merge-blocking drift check + deterministic Fake-lane journey gate +
  default-campaign wiring into `examples/accrue_host`** — DUN-09/DUN-10, **Phase 130**.
- **`Accrue.Dunning.Engine` behaviour + off-by-default conditionally-compiled Chimeway adapter** —
  DUN-03, **Phase 131** (verify Chimeway's published 1.0.0 API first; guide-vs-code mismatch).
- **Entitlements adopter-proof demo** — PROOF-03, **Phase 132** (independent of dunning).
- **Full recovered-revenue analytics dashboard** — milestone Out-of-Scope; DUN-08 ships a *derivable*
  ledger counter + telemetry only (add a dashboard only on a sourced need).
- **Multi-channel (SMS/push/in-app) dunning surfaces / per-customer cadence** — milestone Out-of-Scope
  (carried; Chimeway engine unlocks multi-channel later).
- **Surfacing the recovered-vs-lost counter inside the admin UI** — optional; SC#4 only requires it be
  derivable. Planner's discretion whether to also render it in the dunning panel.

</deferred>

---

*Phase: 129-customer-operator-surfaces-observability*
*Context gathered (reconstructed): 2026-05-25*
