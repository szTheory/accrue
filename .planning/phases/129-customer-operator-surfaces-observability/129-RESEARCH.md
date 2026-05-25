# Phase 129: Customer + Operator Surfaces + Observability - Research

**Researched:** 2026-05-25
**Domain:** Elixir/Phoenix observability (telemetry + ledger) + Phoenix LiveView surfaces (customer portal banner, read-only admin panel) over the Phase-128 dunning campaign engine
**Confidence:** HIGH (every cited anchor verified in-tree this session; external telemetry semantics confirmed against hexdocs)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
> Copied verbatim from `129-CONTEXT.md` `<decisions>`. All 14 were judged additive-safe/reversible; none escalated. D-14 carries a flagged-inference caveat (confirm at review, but do not re-litigate).

**A. Telemetry family + event taxonomy (the conscious deviation)**
- **D-01 — Telemetry family = `[:accrue, :ops, :dunning_*]`, NOT `[:accrue, :dunning, *]`.** Mirrors the shipped+enforced `[:accrue, :ops, :dunning_exhaustion]` idiom. The four new events:
  | Lifecycle moment | Telemetry event | Measurements | Key metadata |
  |---|---|---|---|
  | Campaign opens | `[:accrue, :ops, :dunning_campaign_started]` | `%{count: 1}` | `subscription_id`, `step_count` |
  | A step email goes out | `[:accrue, :ops, :dunning_step_sent]` | `%{count: 1}` | `subscription_id`, `step_key`, `step_index` |
  | Payment recovers | `[:accrue, :ops, :dunning_recovered]` | `%{count: 1}` | `subscription_id`, `source` |
  | Campaign ends in loss | `[:accrue, :ops, :dunning_exhausted]` | `%{count: 1}` | `subscription_id`, `to_status`, `source` |
  Mirror the existing exhaustion event's `%{count: 1}` + `source` enum (`:accrue_sweeper | :stripe_native | :manual`).
- **D-02 — Ledger event type strings stay dotted:** `"dunning.campaign_started"`, `"dunning.step_sent"`, `"dunning.recovered"`, `"dunning.exhausted"` — matching the existing `"dunning.terminal_action_requested"`. Write via `Accrue.Events.record/1` with `subject_type: "Subscription", subject_id: sub.id, data: %{...}`. Prefer `record_multi/3` where the emit site is already inside an `Ecto.Multi`/transaction.
- **D-03 — Emission points = the Phase-128 scope fences** (`default_handler.ex:802-803` → `dunning.recovered`; `dunning_step.ex:41-47` → `dunning.step_sent`; the first-transition elector winner branch → `dunning.campaign_started`; the exhaustion telemetry site → `dunning.exhausted`).
- **D-04 — Drift-gate obligation is a HARD exit criterion.** Every new event MUST be registered in (a) `expected_ops_events/0`, (b) `metrics.ex` counters, (c) `guides/telemetry.md` (catalog ~:89 + runbook ~:446). Missing any breaks the build by design.

**B. `dunning.exhausted` vs the existing terminal-action event**
- **D-05 — Two distinct moments, kept distinct.** `dunning.terminal_action_requested` = request time (sweeper-only). `dunning.exhausted` = confirmed status transition, all loss sources.
- **D-06 — "Lost" is counted ONLY from `dunning.exhausted`**, never `terminal_action_requested`. The recovered-vs-lost fold reads only `dunning.recovered` vs `dunning.exhausted`.

**C. Recovered-vs-lost counter (SC#4)**
- **D-07 — Thin fold over the existing ledger** via `Accrue.Events.bucket_by/2` / `bucket_query/1`. recovered = count(`dunning.recovered`), lost = count(`dunning.exhausted`), optional `since:`/`until:` window. **No new table.**
- **D-08 — A small named query function** returning `%{recovered: n, lost: n}` (+ optional rate). Home module is planner's discretion (`Accrue.Dunning` or `Accrue.Events`).

**D. Customer portal recovery banner (DUN-06)**
- **D-09 — A conditional `<section>` in `accrue_portal/.../subscription_live.ex`** (render region ~:153-154), gated on dunning/past-due state. No new layout slot; no banner component exists.
- **D-10 — Gate on already-loaded subscription state** — `Subscription.past_due?/1` + `Subscription.dunning_campaign_active?/1`. No new query.
- **D-11 — The CTA target is provider-aware.** `add_payment_method_live.ex` is Braintree-only (`/payment-methods/new`). Resolve off `subscription.processor`. Reuse the `card_expiring_soon.ex` `@update_pm_url` precedent so banner + email resolve consistently.

**E. Admin read-only dunning-state panel (DUN-07)**
- **D-12 — A new read-only `ax-card`** in `accrue_admin/.../subscription_live.ex` (clone the related-billing card :175-217 or timeline card :449-460). Show campaign-active?, current step + started-at, next scheduled action.
- **D-13 — Every operator string through `AccrueAdmin.Copy`** (add defs to `copy/subscription.ex` or a new `Copy.Dunning`, `defdelegate` in `copy.ex`). Reuse `Events.timeline_for/3` filtered to `dunning.*`.
- **D-14 — "Next scheduled action" source = the pure resolver `Accrue.Dunning.Campaign.next_step/3` (⚠ FLAGGED INFERENCE — confirm at review, don't re-litigate).** Oban `scheduled_at` is the authoritative next-fire timestamp if cheaply available.

### Claude's Discretion
- Home module for the recovered-vs-lost counter (`Accrue.Dunning` vs `Accrue.Events`); raw `%{recovered:, lost:}` vs also a derived rate.
- `dunning_step_sent` per-step (recommended, with `step_key`) vs aggregate.
- Exact `AccrueAdmin.Copy` function names; whether a dedicated `Copy.Dunning` submodule is warranted.
- Exact banner copy/markup; the precise per-provider CTA destinations (Stripe update-PM path).
- Whether the recovered-vs-lost counter is also surfaced in the admin panel (SC#4 only requires it be **derivable**).
- Whether `dunning.exhausted`/`dunning.recovered` ledger writes use `record_multi/3` (in-transaction) or `record/1` (post-commit) per local atomicity.

### Deferred Ideas (OUT OF SCOPE)
- Provider-honest dunning docs + merge-blocking drift check + Fake-lane journey gate + `examples/accrue_host` wiring → DUN-09/DUN-10, **Phase 130**.
- `Accrue.Dunning.Engine` behaviour + off-by-default Chimeway adapter → DUN-03, **Phase 131**.
- Entitlements adopter-proof demo → PROOF-03, **Phase 132**.
- Full recovered-revenue analytics dashboard → milestone Out-of-Scope (DUN-08 ships a *derivable* counter only).
- Multi-channel (SMS/push/in-app) dunning surfaces → milestone Out-of-Scope.
- Surfacing the recovered-vs-lost counter inside the admin UI → optional; planner's discretion.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DUN-06 | Past-due customer sees a recovery prompt in `accrue_portal` deep-linking the add/update-PM flow | Portal LiveView render tree + `@subscription` state + provider-aware CTA: `subscription_live.ex` mount/render verified; `past_due?/1` + `dunning_campaign_active?/1` predicates verified; `card_expiring_soon.ex` `@update_pm_url` precedent + portal `Path` helper + Braintree-only add flow confirmed. |
| DUN-07 | Operator sees active dunning state (current step, started-at, next scheduled action) in `accrue_admin`, read-only, copy via `AccrueAdmin.Copy` | Admin `subscription_live.ex` loads full `%Subscription{}` (with `dunning_campaign_started_at`); `ax-card` clone targets + `timeline_for/3` + `next_step/3` pure resolver verified; `Copy` delegator + `Copy.Subscription` defs pattern confirmed. |
| DUN-08 | Ledger events (`dunning.campaign_started`/`step_sent`/`recovered`/`exhausted`) + aligned telemetry + recovered-vs-lost counter (no new table), aligned with `guides/telemetry.md` + runbooks | All 4 emit sites verified at Phase-128 scope fences; `Events.record/1`/`record_multi/3` + `bucket_by/2`/`bucket_query/1` signatures verified; the drift-gate triad (`telemetry_ops_inventory.ex` + `metrics.ex:72` + `telemetry.md` ~:89/~:446) verified with exact assertion shapes; `Accrue.Telemetry.Ops.emit/3` helper found. |
</phase_requirements>

## Summary

This is an **additive observability + surfacing phase over a finished engine** (Phase 128). There is essentially zero greenfield technology: every primitive the phase needs already exists in-tree, and the CONTEXT already grounded every decision in `file:line` anchors. **The entire research value is anchor verification + nailing the exact contract shapes of three integration seams**, because getting any of them slightly wrong will either silently no-op (telemetry not registered) or break the build (drift gate). All anchors verified this session at (or within ±2 lines of) the claimed positions.

The single highest-risk integration is the **drift-gate triad (D-04)**. The enforcing test (`accrue/test/accrue/telemetry/ops_event_contract_test.exs`) does two things that constrain *where* and *how* the four new telemetry events must be emitted: (1) it **regex-scans `lib/**/*.ex`** for `[:accrue, :ops, …]` literals AND `Ops.emit(:atom, …)` calls — so events emitted from `test/` or `support/` are invisible to it and will fail the `unwired` equality check; emit sites MUST live under `lib/`; (2) it asserts **strict set-equality** between the inventory and what's wired, with only a 3-event documented-gap allowlist (`not_wired_first_party_emits`). Concretely: the moment you add an event to `expected_ops_events/0` you MUST also emit it from `lib/`, declare a matching `counter/2` in `metrics.ex`, and write the literal into `guides/telemetry.md` — all four moves land together or the build is red. This is the intended contract, not an obstacle.

The portal and admin surfaces are low-risk Phoenix LiveView render-tree additions tested entirely with `Phoenix.LiveViewTest` (`live/2`, `has_element?/2`, `render_submit`) — **no Chrome binary involved** (Chrome only matters for PDF, which this phase doesn't touch). One CONTEXT imprecision to flag: the portal `subscription_live.ex` does not literally "read `@subscription.processor` at :259/:265" in the template — those lines are **private helpers that pattern-match `%Subscription{processor: "braintree"}`** (`cancel_subscription/1`, `preview_supported?/1`). The dispatch-on-`processor` pattern is real and well-established; the CTA resolver should follow the same `processor: "braintree"` → X / else → Y shape.

**Primary recommendation:** Treat the four lifecycle events as one atomic "observable contract" unit per event: emit (ledger + telemetry, from `lib/`) → register in inventory → declare in `metrics.ex` → document in `telemetry.md` (catalog + runbook) — all in the same task so the drift gate never goes red mid-plan. Use `Accrue.Telemetry.Ops.emit/3` (auto-merges `operation_id`) for the new telemetry rather than raw `:telemetry.execute/3`. Build the recovered-vs-lost counter as a thin `Repo.aggregate`-style fold over two ledger types; build the portal banner and admin card as render-tree additions over already-loaded state.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dunning lifecycle telemetry (4 events) | API/Backend (`accrue` core, `lib/`) | — | Emitted at webhook-reducer + Oban-worker seams; SREs subscribe to `[:accrue, :ops, *]`. Must be in `lib/` for the contract scanner to see them. |
| Dunning ledger events (4 dotted types) | Database/Storage (`accrue_events` append-only) | API/Backend (emit sites) | Audit trail + the substrate the counter folds over. Written via `Events.record/1`/`record_multi/3`. |
| Recovered-vs-lost counter | API/Backend (`Accrue.Dunning` or `Accrue.Events` query fn) | Database (folds `accrue_events`) | A pure read-fold; no persistence, no new table. |
| Customer recovery banner | Frontend Server (LiveView render, `accrue_portal`) | — | Conditional `<section>` over already-mounted `%Subscription{}`. No socket-runtime change in core. |
| Provider-aware CTA target resolution | Frontend Server (`accrue_portal`) | API/Backend (mirror `card_expiring_soon` precedent) | Resolves a path off `subscription.processor`; routes to the portal's existing add/update-PM destination. |
| Admin dunning-state panel | Frontend Server (LiveView render, `accrue_admin`) | API/Backend (`next_step/3` resolver, `timeline_for/3`) | Read-only `ax-card`; all strings via `AccrueAdmin.Copy`. |

## Standard Stack

No new dependencies. Everything required is already declared in `accrue/mix.exs` / `accrue_admin/mix.exs` and was verified present in-tree.

### Core (already in the tree — reuse, don't add)
| Library | Version (CLAUDE.md) | Purpose in this phase | Why standard |
|---------|---------|---------|--------------|
| `:telemetry` | `~> 1.3` | `:telemetry.execute/3` for the 4 ops events (via `Accrue.Telemetry.Ops.emit/3`) | The Elixir event-instrumentation standard; the ops namespace is already built on it. |
| `:telemetry_metrics` | `~> 1.1` (optional) | `counter/2` declarations in `Accrue.Telemetry.Metrics.defaults/0` | Parity gate (`metrics_ops_parity_test.exs`) requires a `counter` for every ops event. |
| `:ecto`/`:ecto_sql` | `~> 3.13` | The recovered-vs-lost fold query (`bucket_query/1` + `count`) | `accrue_events` is Ecto-modeled; `bucket_by/2` already uses `from`/`where`/`group_by`. |
| `:phoenix_live_view` | `~> 1.1` (admin); `Phoenix.Component`/`~H` (portal) | Portal banner `<section>` + admin `ax-card` render | Both surfaces are LiveView; tested via `Phoenix.LiveViewTest`. |
| `:oban` | `~> 2.21` | (Optional, D-14) `Oban.Job` `scheduled_at` lookup for authoritative next-fire timestamp | Already powers `Accrue.Workers.DunningStep`; the cancel-on-recovery path already queries `Oban.Job`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Accrue.Telemetry.Ops.emit/3` for new events | Raw `:telemetry.execute([:accrue, :ops, :dunning_*], …)` (as `dunning_exhaustion` does) | Both are detected by the contract scanner. `Ops.emit/3` auto-merges `operation_id` and hardcodes the `[:accrue, :ops]` prefix (can't typo the namespace). The raw form is what the *mirror* event uses, so either matches precedent. Recommend `Ops.emit/3` for the new four. |
| D-14 pure resolver `next_step/3` | `Oban.Job` query for next pending `DunningStep` | Resolver is deterministic, DB/Oban-decoupled, engine-seam-clean (Phase 131), already built. Oban query gives the *real* `scheduled_at` but couples the admin UI to Oban internals. CONTEXT picks resolver primary, Oban `scheduled_at` as authoritative-timestamp augment. **Reversible.** |
| Counter via `bucket_by/2` | Direct `Repo.aggregate(query, :count)` per type, or one grouped `group_by: e.type` query | `bucket_by/2` is time-*bucketed* (returns `[{datetime, count}]`); SC#4 only needs a flat `%{recovered:, lost:}`. A simple grouped count is leaner. `bucket_query/1` (the private filter builder) is the reuse path either way — but it's `defp`, so a flat counter likely writes its own small query or a sibling helper. (See Open Questions.) |

**Installation:** None. (`mix deps.get` is a no-op for this phase.)

## Package Legitimacy Audit

> Not applicable — this phase installs **no external packages**. All libraries used are already declared and locked in `accrue/mix.exs` / `accrue_admin/mix.exs` per CLAUDE.md and were verified present in the working tree. No `npm`/`pip`/`hex` install occurs.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────── accrue (core, lib/) ───────────────────────┐
 Stripe/Braintree   │                                                                    │
   webhook ─────────┼──► DefaultHandler.reduce_row (Repo.transact)                       │
                    │      │                                                              │
                    │      ├─ maybe_start_dunning_campaign  (count==1 winner branch)      │
                    │      │     └─► EMIT dunning.campaign_started (ledger + telemetry) ──┼──┐
                    │      ├─ maybe_emit_dunning_exhaustion  (:802-803 sibling)           │  │
                    │      │     └─► EMIT dunning.exhausted   (ledger + telemetry) ───────┼──┤
                    │      └─ maybe_finalize_dunning_campaign (recovery edge, :802-803)   │  │
                    │            └─► EMIT dunning.recovered   (ledger + telemetry) ───────┼──┤
                    │                                                                     │  │
 Oban worker ───────┼──► Workers.DunningStep.perform → deliver_step (:41-47 fence)        │  │
                    │       └─► EMIT dunning.step_sent  (ledger + telemetry) ─────────────┼──┤
                    │                                                                     │  │
                    │   ┌──────────────── accrue_events (append-only PG) ◄────────────────┘  │ telemetry
                    │   │      ▲                                                              ▼ [:accrue,:ops,:dunning_*]
                    │   │      │ Events.record/1 · record_multi/3                       host metrics
                    │   │      │                                                        reporter
                    │   │  recovered-vs-lost fold  (count dunning.recovered            (counter/2 in
                    │   │      └─ vs count dunning.exhausted) → %{recovered, lost}       metrics.ex)
                    │   └──────────────────────────────────────────────────────────────────┘
                    │                                                                    │
   ── DRIFT GATE ── │  ops_event_contract_test  ⟂  telemetry_ops_inventory.expected_ops_events/0
                    │       ⟂  metrics_ops_parity_test  ⟂  guides/telemetry.md literals  │
                    └────────────────────────────────────────────────────────────────────┘

  accrue_portal (LiveView)                          accrue_admin (LiveView)
  ─────────────────────────                         ─────────────────────────
  SubscriptionLive.render                           SubscriptionLive.render
    past_due?/1 + dunning_campaign_active?/1           dunning_campaign_active?/1
       │  true                                          + dunning_campaign_started_at
       ▼                                                + next_step/3 (resolver)
  <section> recovery banner                            + timeline_for("Subscription", id) ∩ dunning.*
    CTA target ← resolve(subscription.processor)         │
      braintree → /payment-methods/new                   ▼
      else      → /payment-methods (or Stripe dest)   read-only ax-card  (all copy via AccrueAdmin.Copy)
```

### Recommended emit-site map (verified anchors)

```
accrue/lib/accrue/webhook/default_handler.ex
  ├─ maybe_start_dunning_campaign/2 :1138  → count==1 branch :1149  → dunning.campaign_started
  │     (step_count = length(Accrue.Config.dunning_campaign_steps()))
  ├─ maybe_emit_dunning_exhaustion/2 :764-781  (the :ops mirror)   → dunning.exhausted (ledger beside telemetry)
  └─ maybe_finalize_dunning_campaign/2 :806  recovery edge, fence :802-803  → dunning.recovered
accrue/lib/accrue/workers/dunning_step.ex
  └─ deliver_step/4 :160  (fence :41-47)  → dunning.step_sent  (after Mailer.deliver/2)
```

### Pattern 1: Ops telemetry emission (mirror the exhaustion event)
**What:** Emit a `[:accrue, :ops, :dunning_*]` event with `%{count: 1}` + low-cardinality metadata.
**When to use:** Each of the four lifecycle moments.
**Example (recommended — `Ops.emit/3`):**
```elixir
# Source: verified pattern from accrue/lib/accrue/telemetry/ops.ex (emit/3)
#         + mirror of accrue/lib/accrue/webhook/default_handler.ex:768-777
Accrue.Telemetry.Ops.emit(
  :dunning_campaign_started,
  %{count: 1},
  %{subscription_id: sub.id, step_count: length(Accrue.Config.dunning_campaign_steps())}
)
```
**Example (raw — what the mirror event itself uses):**
```elixir
# Source: accrue/lib/accrue/webhook/default_handler.ex:768-777 (verbatim shape)
:telemetry.execute(
  [:accrue, :ops, :dunning_exhausted],
  %{count: 1},
  %{subscription_id: updated.id, to_status: to_status, source: dunning_source(row.dunning_sweep_attempted_at)}
)
```
> The contract scanner (`ops_event_contract_test.exs`) detects **both** forms — `Ops.emit(:atom, …)` via regex `~r/Ops\.emit\(\s*:([a-z_]+)\s*,/` and `[:accrue, :ops, …]` literals via `~r/\[:accrue,\s*:ops(?:,\s*:[a-z_]+)+\]/`. Either satisfies the gate. Note `Ops.emit/3`'s suffix atom must be an *existing* atom at parse time (`String.to_existing_atom`); referencing it in `metrics.ex`/inventory guarantees that.

### Pattern 2: Ledger write (clone the sweeper)
**What:** Append a dotted-type event to `accrue_events`.
**Example:**
```elixir
# Source: accrue/lib/accrue/jobs/dunning_sweeper.ex:108-117 (verbatim shape)
{:ok, _event} =
  Accrue.Events.record(%{
    type: "dunning.step_sent",
    subject_type: "Subscription",
    subject_id: sub.id,
    data: %{step_key: step_key_str, step_index: idx}
  })
```
**In-transaction variant (D-02, prefer at multi sites):**
```elixir
# Source: accrue/lib/accrue/events.ex:134-140 (record_multi/3 signature verified)
multi
|> Accrue.Events.record_multi(:dunning_recovered_event, %{
     type: "dunning.recovered",
     subject_type: "Subscription",
     subject_id: updated.id,
     data: %{source: source}
   })
|> Accrue.Repo.transact()
```
> No event-type registration is required. `Accrue.Events.current_schema_version/1` defaults all unknown types to version 1 (`events.ex:395`), and there is no event-type allowlist — the sweeper's `dunning.terminal_action_requested` is registered nowhere special. The new four types "just work" once recorded.

### Pattern 3: `counter/2` declaration (mirror `metrics.ex:72`)
**What:** Declare one Telemetry.Metrics counter per ops event.
**Example:**
```elixir
# Source: accrue/lib/accrue/telemetry/metrics.ex:72 (verbatim sibling)
counter("accrue.ops.dunning_campaign_started.count", tags: [:source]),  # only if :source ∈ metadata
counter("accrue.ops.dunning_step_sent.count"),
counter("accrue.ops.dunning_recovered.count", tags: [:source]),
counter("accrue.ops.dunning_exhausted.count", tags: [:source]),
```
> **CRITICAL `tags:` rule:** every atom in `tags:` MUST exist in the event's metadata, or Telemetry.Metrics **discards** the event ([CITED: hexdocs.pm/telemetry_metrics]). `dunning_campaign_started` metadata (D-01) is `{subscription_id, step_count}` — it has **no `:source`** — so its counter must NOT declare `tags: [:source]`. Match `tags:` to each event's actual metadata: `recovered`/`exhausted` have `:source`; `started` does not; `step_sent` has `:step_key`/`:step_index` (high-ish cardinality — recommend `tags: []` or `tags: [:step_key]` only). The metric name maps `"accrue.ops.X.count"` → event `[:accrue, :ops, :X]`, measurement `:count`; counters count events and ignore the measurement value [CITED: hexdocs.pm/telemetry_metrics].

### Pattern 4: Portal conditional banner (clone the `:if`/`<%= if %>` precedents)
**What:** A `<section class="portal-card">` gated on dunning/past-due, with a provider-aware CTA.
**Example:**
```elixir
# Source: accrue_portal/.../subscription_live.ex render precedents :180 (:if) / :198 (<%= if %>)
<section :if={recovery_prompt?(@subscription)} class="portal-card" role="alert">
  <h2>{Copy.subscription_recovery_heading()}</h2>
  <p>{Copy.subscription_recovery_body()}</p>
  <a href={update_pm_path(@base_path, @subscription)} class="portal-button-secondary">
    {Copy.subscription_recovery_cta()}
  </a>
</section>

# private helpers (mirror cancel_subscription/1 :259 dispatch-on-processor shape):
defp recovery_prompt?(%Subscription{} = sub),
  do: Subscription.past_due?(sub) or Subscription.dunning_campaign_active?(sub)
defp update_pm_path(base, %Subscription{processor: "braintree"}), do: base <> "/payment-methods/new"
defp update_pm_path(base, %Subscription{}), do: base <> "/payment-methods"  # or Stripe update-PM dest
```
> `AccruePortal.Path` (`accrue_portal/lib/accrue_portal/path.ex`) has `payment_methods/1` but **no `payment_methods_new/1`** — add a helper or inline the `<> "/payment-methods/new"` literal (the route exists at `router.ex:91`). Portal Copy already carries past-due strings (`copy.ex:231/246-247`) to mirror in tone.

### Pattern 5: Admin read-only `ax-card` (clone the related-billing/timeline card)
**What:** A read-only card showing campaign state; no `phx-submit`/`phx-click` actions.
**Example:**
```elixir
# Source: accrue_admin/.../subscription_live.ex related-billing card :175-217 (structure)
#         + tax_ownership_card.ex (a standalone ax-card component, :9-45)
<article class="ax-card" data-role="subscription-dunning-state">
  <header class="ax-page-header">
    <p class="ax-eyebrow">{Copy.dunning_panel_eyebrow()}</p>
    <h3 class="ax-heading">{Copy.dunning_panel_heading()}</h3>
  </header>
  <p class="ax-body">{Copy.dunning_active_label(@subscription)}</p>   <%# dunning_campaign_active?/1 %>
  <p class="ax-body">{Copy.dunning_started_at_label()} {format_datetime(@subscription.dunning_campaign_started_at)}</p>
  <p class="ax-body">{Copy.dunning_next_action_label()} {next_action_summary(@subscription)}</p>
</article>
```
```elixir
# next_action_summary via the pure resolver (D-14); @subscription already loaded with the anchor.
defp next_action_summary(%Subscription{dunning_campaign_started_at: %DateTime{} = anchor} = _sub) do
  steps = Accrue.Config.dunning_campaign_steps()
  case Accrue.Dunning.Campaign.next_step(steps, anchor, Accrue.Clock.utc_now()) do
    {:next, step, schedule_in} -> {Keyword.fetch!(step, :key), schedule_in}
    :done -> :done
  end
end
defp next_action_summary(_), do: :inactive
```
> The admin `@subscription` is loaded via `Subscriptions.detail/2` (`subscription_live.ex:35`, returns the full struct at `queries/subscriptions.ex:78` with `dunning_campaign_started_at`). `Copy.*` defs go in `copy/subscription.ex` (or a new `Copy.Dunning`) and are `defdelegate`d in `copy.ex` (pattern at `copy.ex:18-39`). Dunning step history reuses `Events.timeline_for("Subscription", id, …)` (already called at `subscription_live.ex:539`) filtered to `dunning.*` types.

### Anti-Patterns to Avoid
- **Emitting telemetry from `test/` or `support/`:** the contract scanner only reads `lib/**/*.ex`. An event emitted only from a test fixture will fail the `unwired` equality check (it's in the inventory but not "found"). All emit sites MUST be in `lib/`.
- **Declaring `tags: [:source]` on `dunning_campaign_started`:** it has no `:source` metadata → Telemetry.Metrics discards every such event silently. Match `tags:` to actual metadata keys.
- **Counting "lost" from `dunning.terminal_action_requested`:** that's request-time intent (sweeper-only) and can exist with no campaign. Count only `dunning.exhausted` (D-06).
- **Adding a new table for the counter:** explicitly forbidden (D-07; milestone deferred the dashboard). Fold the ledger.
- **Adding write actions to the admin panel:** DUN-07 is read-only (D-12). No `phx-submit`/`phx-click` mutations.
- **Hardcoding operator strings in the admin template:** every string routes through `AccrueAdmin.Copy` (D-13).
- **Opening a `[:accrue, :dunning, *]` telemetry root:** would fork the contract and bypass the drift gate (D-01). Stay in `:ops`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ops telemetry emission | A new emit wrapper or raw `:telemetry.execute` with a hand-typed namespace | `Accrue.Telemetry.Ops.emit/3` | Hardcodes `[:accrue, :ops]` prefix (can't typo), auto-merges `operation_id` from the actor context. |
| Ledger append | A direct `Repo.insert(%Event{})` | `Accrue.Events.record/1` / `record_multi/3` | Handles actor/trace_id normalization, idempotency-key conflict targets, immutability-trigger error re-raise. |
| Type-filtered ledger count | A raw SQL `WHERE type IN (...)` | The `bucket_query/1`-style `where(q, [e], e.type in ^types)` + `count` (or `Repo.aggregate`) | Same query primitive `bucket_by/2` uses; `since:`/`until:` filters already encoded. |
| "Next dunning step" computation | A bespoke date-math loop over config steps | `Accrue.Dunning.Campaign.next_step/3` | Pure, deterministic, tested, engine-seam-clean; returns `{:next, step, schedule_in} | :done`. |
| Subscription past-due / campaign-active checks | Status-atom comparisons in the template | `Subscription.past_due?/1`, `Subscription.dunning_campaign_active?/1` | Canonical predicates; `dunning_campaign_active?/1` reads the Phase-128 anchor column. |
| Provider-aware update-PM target | A new resolver from scratch | Mirror `card_expiring_soon.ex` `@update_pm_url` (dispatch on `processor`) + portal `Path` | Keeps banner CTA and dunning email CTA consistent (a stated phase goal). |
| Admin event timeline | A new ledger query | `Events.timeline_for("Subscription", id, …)` filtered to `dunning.*` | Already used in the same LiveView (`:539`); upcasts rows automatically. |

**Key insight:** This phase is almost entirely *composition of existing primitives*. The risk is not "build the wrong thing" — it's "wire the contract incompletely." Spend planning rigor on the drift-gate triad, not on novel code.

## Runtime State Inventory

> Not a rename/refactor/migration phase — but a few non-code contract surfaces deserve the same explicit treatment, because the drift gate makes them load-bearing.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data (ledger) | `accrue_events` will gain 4 new `type` values (`dunning.campaign_started`/`step_sent`/`recovered`/`exhausted`). No schema change, no migration, no type allowlist. | Code edit (emit sites) only — verified no registration needed (`events.ex:395`; no allowlist). |
| Live service config | None. No external service config (Datadog/Stripe dashboard/etc.) embeds these names. Telemetry is host-wired via `Accrue.Telemetry.Metrics.defaults/0`. | None — verified: ops events flow to whatever reporter the host attaches; no Accrue-side service registration. |
| OS-registered state | None. No OS-level registration. | None — verified (no cron/launchd/systemd touched). |
| Secrets/env vars | None. No new secret or env var. | None. |
| Build artifacts / contract files | The drift gate couples FOUR files: `telemetry_ops_inventory.ex` (`expected_ops_events/0`), `metrics.ex` (`defaults/0` counters), `guides/telemetry.md` (catalog ~:89 + runbook ~:446), AND the emit sites in `lib/`. A change to any one without the others breaks `ops_event_contract_test` or `metrics_ops_parity_test`. | Code edit — all four in lockstep, per event (D-04). |

**The canonical question (adapted):** *After the four events are emitted, what contract surfaces must agree?* → the inventory list, the metrics defaults, the guide literals (both tables), and the lib emit sites. Four files, strict set-equality enforced.

## Common Pitfalls

### Pitfall 1: Telemetry event registered in the inventory but not emitted from `lib/`
**What goes wrong:** `ops_event_contract_test`'s second test fails: `unwired` (inventory − found) ≠ the 3-event `not_wired_first_party_emits` allowlist.
**Why it happens:** The scanner only reads `lib/**/*.ex` (`@lib_root` at `ops_event_contract_test.exs:8`). Emitting only from a test or `support/` file leaves the event "in inventory, not found."
**How to avoid:** Emit every new ops event from a `lib/` module (`default_handler.ex`, `dunning_step.ex`) in the same task that adds it to the inventory.
**Warning signs:** `mix test test/accrue/telemetry/ops_event_contract_test.exs` red with "Ops allowlist vs lib mismatch."

### Pitfall 2: `counter/2` `tags:` referencing absent metadata
**What goes wrong:** Telemetry.Metrics silently discards events whose metadata is missing a declared tag — the counter reads zero forever, no error.
**Why it happens:** Copy-pasting `tags: [:source]` from `dunning_exhaustion` onto `dunning_campaign_started`, which has no `:source` ([CITED: hexdocs.pm/telemetry_metrics]).
**How to avoid:** Match each counter's `tags:` to the event's actual metadata (D-01 table). `started` → no `:source`; `step_sent` → `:step_key`/`:step_index`; `recovered`/`exhausted` → `:source`.
**Warning signs:** A counter that never increments in a manual telemetry-reporter smoke test despite the event firing.

### Pitfall 3: Missing the `guides/telemetry.md` literal (both tables)
**What goes wrong:** `ops_event_contract_test`'s first test fails — the guide must contain `inspect(event)` (e.g. the exact literal `[:accrue, :ops, :dunning_recovered]`) for every inventory entry.
**Why it happens:** Updating the catalog (~:89) but forgetting the operator runbook (~:446), or vice versa — the test only checks the literal *exists somewhere in the file*, but the operator runbook is part of the documented contract (D-04) even if the test passes with one occurrence.
**How to avoid:** Add each event to BOTH the ops-catalog table (~:89) and the operator-runbook table (~:446). The runbook needs a "suggested first actions" cell.
**Warning signs:** Test passes but the guide has a catalog row with no runbook row (contract incomplete per D-04, even if the gate is green).

### Pitfall 4: Double-counting "lost"
**What goes wrong:** The recovered-vs-lost counter overcounts losses if it includes `dunning.terminal_action_requested`.
**Why it happens:** That event looks like a "loss" but is request-time intent (sweeper-only) and can exist where no campaign ran (D-05/D-06).
**How to avoid:** The fold reads ONLY `["dunning.recovered"]` vs `["dunning.exhausted"]` — never the request-time event.
**Warning signs:** Lost count exceeds confirmed terminal transitions in a fixture with sweeper retries.

### Pitfall 5: Provider-CTA divergence / dead link for Stripe
**What goes wrong:** A banner CTA hardcoded to `/payment-methods/new` lands Stripe customers on a Braintree-only hosted-fields form (`add_payment_method_live.ex` calls `BraintreeClient.client_token_for/1` unconditionally).
**Why it happens:** Assuming a generic "update card" route exists. It doesn't — `/payment-methods/new` is Braintree-specific.
**How to avoid:** Dispatch on `subscription.processor` (mirror `cancel_subscription/1`'s `processor: "braintree"` pattern). Braintree → `/payment-methods/new`; Stripe/others → `/payment-methods` (list) or the Stripe update-PM destination. Keep it consistent with the email's `@update_pm_url`.
**Warning signs:** A Stripe-processor fixture rendering a CTA href ending `/payment-methods/new`.

### Pitfall 6: D-14 next-action timestamp drift under Fake clock
**What goes wrong:** Calling `next_step/3` with `DateTime.utc_now()` makes the admin panel's "next action" non-deterministic under the Fake clock (Phase 130 lane) and can flap at step boundaries.
**Why it happens:** The whole dunning engine reads wall-clock via `Accrue.Clock.utc_now/0` for Fake-lane determinism (`dunning_step.ex:39`, `default_handler.ex:896-899`).
**How to avoid:** Pass `Accrue.Clock.utc_now()` (not `DateTime.utc_now()`) as the `now` arg to `next_step/3`, consistent with the rest of the engine.
**Warning signs:** Flaky admin LiveView test asserting the next-action label.

## Code Examples

### Recovered-vs-lost fold (flat counter, no time-bucketing)
```elixir
# Recommended shape (Claude's discretion: home module Accrue.Dunning).
# Mirrors bucket_query/1's where(e.type in ^types) + since/until, but flat.
@recovered "dunning.recovered"
@exhausted "dunning.exhausted"

@spec recovered_vs_lost(keyword()) :: %{recovered: non_neg_integer(), lost: non_neg_integer()}
def recovered_vs_lost(opts \\ []) do
  %{
    recovered: count_events(@recovered, opts),
    lost: count_events(@exhausted, opts)
  }
end

defp count_events(type, opts) do
  import Ecto.Query
  q = from(e in Accrue.Events.Event, where: e.type == ^type)
  q = if since = opts[:since], do: where(q, [e], e.inserted_at >= ^since), else: q
  q = if until = opts[:until], do: where(q, [e], e.inserted_at <= ^until), else: q
  Accrue.Repo.aggregate(q, :count, :id)
end
```
> `Accrue.Events.Event` is the schema module (`events.ex` aliases it; `bucket_query/1` uses `from(e in Event)`). If time-bucketing is later wanted, `bucket_by([type: ["dunning.recovered"]], :month)` is the reuse path (`events.ex:325-352`).

### Step-index derivation for `dunning.step_sent` (D-01 metadata)
```elixir
# step_index = position of step_key in the configured cadence (0-based).
steps = Accrue.Config.dunning_campaign_steps()
step_index = Enum.find_index(steps, fn s -> Atom.to_string(Keyword.fetch!(s, :key)) == step_key_str end)
# emit AFTER Mailer.deliver/2 returns in deliver_step/4 (dunning_step.ex:160-170)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single un-deduped failed-payment email + grace/terminal sweeper | Durable multi-step Oban campaign (`Accrue.Dunning.Campaign` + `Workers.DunningStep`) | Phase 128 (v1.40) | This phase observes/surfaces that engine; the emit seams are pre-marked. |
| Dunning lifecycle invisible (only `dunning.terminal_action_requested` + `dunning_exhaustion` telemetry) | Full lifecycle ledger + telemetry family + recovered-vs-lost counter | Phase 129 (this) | The observability contract. |

**Deprecated/outdated:** None relevant. The `[:accrue, :dunning, *]` spelling in DUN-08/ROADMAP SC#3 is **superseded by design** (D-01) in favor of `[:accrue, :ops, :dunning_*]` — a conscious deviation, not a deprecation.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `dunning.recovered`/`dunning.exhausted`/`dunning.step_sent`/`dunning.campaign_started` need no event-type allowlist or upcaster registration | Pattern 2, Runtime State | LOW — verified no allowlist exists and `current_schema_version/1` defaults unknown types to 1 (`events.ex:395`); the sweeper's existing type isn't registered anywhere. |
| A2 | D-14 next-action source is the pure resolver `next_step/3` (with Oban `scheduled_at` as authoritative-timestamp augment) | D-14, Pattern 5 | LOW/reversible — CONTEXT flagged this as a reconstruction inference; planner/discuss confirms. Both sources verified to exist; choice is engine-seam preference. |
| A3 | The recovered-vs-lost counter is best as a flat grouped/`Repo.aggregate` count, not `bucket_by/2` (which is time-bucketed) | Alternatives, Code Examples | LOW — `bucket_query/1` is `defp`; SC#4 only needs a flat `%{recovered:, lost:}`. Either works; flat is leaner. Planner's discretion (D-08). |
| A4 | Stripe/other-processor CTA target = the portal `/payment-methods` list (vs a Stripe-hosted update-PM URL) | Pattern 4, Pitfall 5 | MEDIUM — CONTEXT leaves "the precise per-provider CTA destinations (Stripe update-PM path)" to planner discretion. The portal has no Stripe-native add-PM LiveView; `/payment-methods` (list) is the safe in-portal default. Confirm intended Stripe destination. |
| A5 | Emitting via `Accrue.Telemetry.Ops.emit/3` (vs raw `:telemetry.execute`) is acceptable to the drift gate | Pattern 1 | LOW — verified the contract scanner detects `Ops.emit(:atom, …)` (regex at `ops_event_contract_test.exs:74`). Both forms pass. |

## Open Questions (RESOLVED)

All three were CONTEXT `## Claude's Discretion` items and are concretely settled in the Phase 129 plans (recorded here for the paper trail).

1. **Stripe/non-Braintree CTA destination (A4).**
   - What we know: `/payment-methods/new` is Braintree-only; `/payment-methods` (list) exists for all providers; the email's `@update_pm_url` is host-supplied, not computed in core.
   - What's unclear: whether the intended Stripe target is the in-portal list, a Stripe Billing Portal session URL, or a host-supplied URL (as the emails use).
   - Recommendation: default the banner CTA to the in-portal `/payment-methods` for non-Braintree, mirroring how the emails accept a host-supplied `update_pm_url`; flag for confirmation in plan-checker. (Discretion item per CONTEXT.)
   - **RESOLVED:** Plan 129-03 dispatches on `subscription.processor` — Braintree → `/payment-methods/new`, non-Braintree (Stripe/other) → in-portal `/payment-methods` list. The email keeps its host-supplied `@update_pm_url`, so banner and email share the CTA *label* verbatim while destinations may differ (acceptable per A4).

2. **`record_multi/3` vs `record/1` per emit site (D-decision, discretion).**
   - What we know: `campaign_started` (in `maybe_start_dunning_campaign`, a sibling `update_all` not inside the reducer's `Repo.transact`), `recovered`/`exhausted` (inside the reducer `Repo.transact`), `step_sent` (in the Oban worker, outside any transaction — `deliver_step/4` is explicitly kept outside `Repo.transact`).
   - What's unclear: nothing blocking — local atomicity dictates each.
   - Recommendation: `recovered`/`exhausted` → `record_multi/3` (already in `Repo.transact`); `step_sent` → `record/1` (post-deliver, no transaction); `campaign_started` → `record/1` (the elector is a standalone `update_all`, not the reducer multi — or fold the ledger write into that branch's own transaction). Planner decides per D-02's "where the emission is inside an existing Multi/transaction."
   - **RESOLVED:** Plan 129-01 uses `record_multi/3` for `recovered`/`exhausted` (inside the reducer `Repo.transact`) and `record/1` for `step_sent` and `campaign_started` (outside any transaction), exactly per the recommendation.

3. **`step_sent` telemetry cardinality.**
   - What we know: D-01 metadata is `{subscription_id, step_key, step_index}`. `subscription_id` is high-cardinality (never a tag); `step_key` is bounded (`:reminder`/`:action_required`/`:final_notice`).
   - Recommendation: `counter("accrue.ops.dunning_step_sent.count")` with no `tags:` (or `tags: [:step_key]` if per-step breakdown is wanted). Avoid tagging `subscription_id`.
   - **RESOLVED:** Plan 129-01 Task 2 declares `counter("accrue.ops.dunning_step_sent.count")` with no `tags:`; `subscription_id` is never tagged.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP toolchain | All compilation + tests | ✓ (assumed per CLAUDE.md floor) | 1.17+/27+ | — |
| PostgreSQL (test DB) | Ledger fold + LiveView tests | ✓ (existing test suite runs against PG) | 14+ | — |
| Chrome/Chromium | NOT required | n/a | — | n/a — this phase touches no PDF; portal/admin tests use `Phoenix.LiveViewTest` render assertions, not headless browser. |
| `:telemetry_metrics` (optional dep) | `metrics_ops_parity_test` + `counter/2` declarations | ✓ (parity test already runs; `metrics.ex` has the non-stub branch) | `~> 1.1` | If absent, `defaults/0` raises and the parity test flunks with an install hint — but it's present in the current tree. |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None. (Chrome is explicitly *not* needed — common misconception flagged because Accrue's PDF lane uses Chrome; the dunning surfaces do not.)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) + `Phoenix.LiveViewTest` for surfaces |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `accrue_portal/test/test_helper.exs`; cases in `accrue/test/support/` (e.g. `Accrue.BillingCase`) |
| Quick run command | `cd accrue && mix test <file>` (e.g. `mix test test/accrue/telemetry/ops_event_contract_test.exs`) |
| Full suite command | `cd accrue && mix test` (per-package); `cd accrue_admin && mix test`; `cd accrue_portal && mix test` |

> **Note (from memory):** the `accrue` full suite has a flaky `PdfTest` — dodge with `--seed 0`. The 6 PackageDocsVerifier failures are RESOLVED (Phase 126). Neither is touched by this phase.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DUN-08 | `dunning.campaign_started` emits ledger + `[:accrue,:ops,:dunning_campaign_started]` on first nil→past_due edge | unit (webhook) | `cd accrue && mix test test/accrue/webhook/dunning_campaign_start_test.exs` (extend) | ✅ extend / ❌ new assertions |
| DUN-08 | `dunning.step_sent` emits per delivered step | unit (worker) | `cd accrue && mix test test/accrue/workers/dunning_step_test.exs` | ❌ Wave 0 (verify worker test exists; likely new) |
| DUN-08 | `dunning.recovered` emits on past_due→active/paid recovery | unit (webhook) | `cd accrue && mix test test/accrue/webhook/dunning_campaign_keying_test.exs` (extend) | ✅ extend |
| DUN-08 | `dunning.exhausted` emits on confirmed terminal transition (all sources), NEVER from `terminal_action_requested` | unit (webhook) | `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs` (extend — mirror existing telemetry-attach pattern) | ✅ extend |
| DUN-08 | Drift gate green: every new event in inventory + metrics + guide + lib emit | contract | `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs` | ✅ exists (will go red until all 4 contract surfaces updated) |
| DUN-08 | recovered-vs-lost fold returns `%{recovered:, lost:}`; never counts `terminal_action_requested`; honors `since:`/`until:` | unit + property | `cd accrue && mix test test/accrue/billing/dunning_test.exs` (extend) | ✅ extend |
| DUN-06 | Past-due/active-campaign subscription renders recovery banner with provider-correct CTA href | LiveView render | `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs` (extend) | ✅ extend |
| DUN-06 | Non-past-due subscription renders NO banner | LiveView render | same file | ✅ extend |
| DUN-07 | Admin renders read-only dunning `ax-card` with active?/started-at/next-action; all strings via Copy; no action controls | LiveView render | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` (extend) | ✅ extend |

### Sampling Rate
- **Per task commit:** the touched file's quick run (e.g. `mix test test/accrue/telemetry/ops_event_contract_test.exs`).
- **Per wave merge:** the full per-package suite for any package touched in the wave (`cd accrue && mix test`, etc.). Because the drift gate is set-equality, run `ops_event_contract_test` + `metrics_ops_parity_test` whenever ANY of the four contract files changed.
- **Phase gate:** all three packages' full suites green before `/gsd:verify-work` (dodge flaky `PdfTest` with `--seed 0`).

### Telemetry-assertion pattern (mirror the existing exhaustion test)
```elixir
# Source: accrue/test/accrue/webhook/dunning_exhaustion_test.exs:87-99 (verbatim shape)
defp attach_telemetry(name) do
  test_pid = self()
  :ok = :telemetry.attach(name, [:accrue, :ops, :dunning_recovered],
          fn event, meas, meta, _ -> send(test_pid, {:telemetry, event, meas, meta}) end, nil)
  ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(name) end)
end
# then: assert_received {:telemetry, [:accrue, :ops, :dunning_recovered], %{count: 1}, %{source: _}}
```

### LiveView render-assertion pattern (no Chrome)
```elixir
# Source: accrue_admin/test/.../subscription_live_test.exs:115-119 (verbatim shape)
{:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")
assert has_element?(view, "[data-role='subscription-dunning-state']")
refute has_element?(view, "[data-role='subscription-dunning-state'] button")  # read-only: no controls
```

### Wave 0 Gaps
- [ ] Verify `accrue/test/accrue/workers/dunning_step_test.exs` exists; if not, create it for the `step_sent` emit assertion (the worker may currently be exercised only via webhook integration tests).
- [ ] Add a `data-role` attribute to the new portal banner `<section>` and admin `<article>` so render tests can `has_element?` them deterministically (mirrors the existing `data-role` convention throughout admin LiveView).
- [ ] Property test (extend `dunning_campaign_property_test.exs` or `billing/dunning_test.exs`): recovered-vs-lost fold never counts `terminal_action_requested`, and respects `since:`/`until:` windows — `stream_data` is already a dev/test dep.
- [ ] Confirm the existing `metrics_ops_parity_test` + `ops_event_contract_test` are in the default `mix test` run (they are — both under `test/accrue/telemetry/`).

*(No framework install needed — ExUnit, `Phoenix.LiveViewTest`, `stream_data`, and the telemetry contract tests all already exist.)*

## Security Domain

> `security_enforcement` is **absent** from `.planning/config.json` (treated as enabled). This phase is low-attack-surface: read-only surfaces + observability over existing state. The relevant controls are PII/cardinality discipline, not new auth.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No new auth. Portal uses `AccruePortal.Authorize`/`AuthPlug` (existing); admin uses `current_owner_scope` + `Subscriptions.detail/2` ownership scoping (existing). |
| V3 Session Management | no | Unchanged; both surfaces reuse existing live_session/on_mount. |
| V4 Access Control | yes | The admin panel MUST stay within the existing `current_owner_scope` (already enforced — `Subscriptions.detail/2` returns `:not_found` cross-scope, `subscription_live.ex:35-42`). The portal banner reads only the already-authorized `@subscription` from `Authorize.subscription/2`. Add NO new data path that bypasses scoping. |
| V5 Input Validation | minimal | No new user input on these surfaces (read-only panel; banner is a static CTA link). The recovered-vs-lost fold takes `since:`/`until:` `%DateTime{}` opts only (no string interpolation — parameterized Ecto). |
| V6 Cryptography | no | None. |
| V7 Logging | yes | Telemetry metadata must be low-cardinality + PII-free (existing `:ops` namespace contract in `guides/telemetry.md`). `subscription_id`/`step_key`/`step_index`/`to_status`/`source` are all safe identifiers/enums. **Never** put customer email, card data, or amounts in telemetry metadata. |

### Known Threat Patterns for {Elixir/Phoenix LiveView + telemetry}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII/secret leakage via telemetry metadata | Information Disclosure | Emit only IDs + bounded enums (`%{count: 1}` + `subscription_id`/`step_key`/`source`); follow the existing `:ops` PII-exclusion contract. |
| Cross-tenant data exposure in admin panel | Information Disclosure / EoP | Reuse `current_owner_scope` scoping (`Subscriptions.detail/2`); the panel reads only `@subscription` already loaded under scope. No new query. |
| Metric cardinality blowup (DoS on the metrics backend) | Denial of Service | Counters tag only low-cardinality keys; never tag `subscription_id`. `tags:` matched to metadata (Pattern 3). |
| Ledger immutability bypass | Tampering | `accrue_events` is append-only (PG trigger raises `45A01`); `Events.record/1` is the only write path and re-raises on the immutability trigger — do not write events any other way. |
| Stripe customer landing on Braintree-only PM form (broken recovery → revenue loss) | (Availability of the recovery path) | Provider-aware CTA dispatch on `processor` (Pitfall 5). |

## Sources

### Primary (HIGH confidence — verified in-tree this session)
- `accrue/lib/accrue/webhook/default_handler.ex` — `maybe_emit_dunning_exhaustion/2` :764-781 (mirror), scope fences :802-803 + :887-888, `maybe_finalize_dunning_campaign/2` :806-837, `maybe_start_dunning_campaign/2` :1138-1155 (campaign-started elector, winner branch :1149), `dunning_source/1` :893-899.
- `accrue/lib/accrue/telemetry/metrics.ex` — `defaults/0` with `counter("accrue.ops.dunning_exhaustion.count", tags: [:source])` :72.
- `accrue/lib/accrue/telemetry/ops.ex` — `Accrue.Telemetry.Ops.emit/3` (hardcoded `[:accrue, :ops]` prefix, `operation_id` auto-merge).
- `accrue/test/support/telemetry_ops_inventory.ex` — `expected_ops_events/0` + `not_wired_first_party_emits/0`.
- `accrue/test/accrue/telemetry/ops_event_contract_test.exs` — the drift gate (regex scan of `lib/`, set-equality assertion).
- `accrue/test/accrue/telemetry/metrics_ops_parity_test.exs` — counter-per-event parity assertion.
- `accrue/lib/accrue/events.ex` — `record/1` :109, `record_multi/3` :135, `timeline_for/3` :262, `bucket_by/2` :326, `bucket_query/1` :354-362, `current_schema_version/1` :395.
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` — `"dunning.terminal_action_requested"` write :108-117.
- `accrue/lib/accrue/workers/dunning_step.ex` — `## Scope fence` :41-47, `deliver_step/4` :160-170, `perform/1` :74-101.
- `accrue/lib/accrue/dunning/campaign.ex` — `next_step/3` :79-94 (`{:next, step, schedule_in} | :done`).
- `accrue/lib/accrue/billing/subscription.ex` — `past_due?/1` :155-158, `dunning_campaign_active?/1` :269-272, `dunning_exhausted_status/1` :255-258.
- `accrue/lib/accrue/config.ex` — `dunning_campaign_steps/0` :863-866, default steps shape `[after_days, key, template]` :19-21.
- `accrue/lib/accrue/emails/card_expiring_soon.ex` — `@update_pm_url` read (not computed) :73-74, :106.
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` — mount :11-34, render region :151-247 (`:if` :180 / `<%= if %>` :198), processor dispatch in `cancel_subscription/1` :259-263 / `preview_supported?/1` :265-266.
- `accrue_portal/lib/accrue_portal/router.ex` — `/payment-methods/new` live route, `/payment-methods` POST controllers.
- `accrue_portal/lib/accrue_portal/path.ex` — has `payment_methods/1`, NO `payment_methods_new/1`.
- `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` — Braintree-only (`BraintreeClient.client_token_for/1`).
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — mount via `Subscriptions.detail/2` :32-59, related-billing card :175-217, timeline card :449-460, `timeline_events/1` :538-539, `load_subscription/1` :529-536.
- `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` — `detail/2` returns full subscription :71-85.
- `accrue_admin/lib/accrue_admin/copy.ex` — `defdelegate` pattern :18-39; `copy/subscription.ex` — string defs.
- `accrue_admin/lib/accrue_admin/components/tax_ownership_card.ex` — standalone `ax-card` component pattern.
- `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` — telemetry attach/assert pattern :87-99, :175-267.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — `live/2` + `has_element?` + `data-role` render-test pattern :80-161.
- `.planning/config.json` — `nyquist_validation: true`, `security_enforcement: absent`.

### Secondary (HIGH — official docs)
- https://hexdocs.pm/telemetry_metrics — `counter/2` semantics: counts events (measurement value ignored), metric name → event_name + measurement inference, `tags:` requires metadata keys present (else event discarded). Verified 2026-05-25.
- https://hexdocs.pm/telemetry — `:telemetry.execute/3` event/measurement/metadata contract (referenced; conventions already embodied by the in-tree `:ops` events).

### Tertiary (LOW)
- None. No claim in this research rests on unverified web sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all libraries verified present and locked in CLAUDE.md.
- Architecture / emit seams: HIGH — every anchor verified at (or ±2 lines of) the CONTEXT's claimed positions; the campaign-started elector + all three scope fences read directly.
- Drift-gate contract: HIGH — the exact assertion shapes of both contract tests were read in full; the `lib/`-only scan and set-equality semantics are confirmed (this is the phase's highest-risk integration and is now fully characterized).
- Pitfalls: HIGH — derived from the verified test mechanics + official Telemetry.Metrics semantics, not speculation.
- One MEDIUM open item: the exact Stripe/non-Braintree CTA destination (A4) is a discretion item with a safe default proposed.

**Research date:** 2026-05-25
**Valid until:** 2026-06-24 (stable — internal codebase anchors; re-verify only if Phase 128 emit sites are refactored before this phase executes).
