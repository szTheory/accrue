# Phase 129: Customer + Operator Surfaces + Observability - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 14 (4 telemetry/ledger emit-site edits · 3 drift-gate contract files · 1 counter query · 1 portal banner · 1 admin panel · 2 Copy files · 2 predicate/resolver reuse-only)
**Analogs found:** 14 / 14 (every new behavior has an in-tree clone source)

> This is an additive observability + surfacing phase over the finished Phase-128 dunning engine. There
> is essentially **zero greenfield** — every primitive already exists in-tree, the CONTEXT/RESEARCH
> grounded every decision in `file:line` anchors, and this map re-verified each analog this session
> (all at or within ±2 lines of the claimed positions). The pattern risk is **not** "build the wrong
> thing" — it's "wire the drift-gate contract incompletely." Spend planning rigor on the **drift-gate
> triad** (Shared Pattern: Drift Gate), not on novel code.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/webhook/default_handler.ex` (edit — emit `dunning.campaign_started` @ :1149, `dunning.recovered` @ :806-837, `dunning.exhausted` @ :764-781) | webhook reducer | event-driven | `maybe_emit_dunning_exhaustion/2` :764-781 (same file) | exact |
| `accrue/lib/accrue/workers/dunning_step.ex` (edit — emit `dunning.step_sent` @ `deliver_step/4` :160-170) | worker | event-driven | `dunning_sweeper.ex` `Events.record/1` :108-117 + `Ops.emit/3` | exact (ledger) / role-match (telemetry from worker) |
| `accrue/lib/accrue/billing/dunning.ex` (edit — add `recovered_vs_lost/1` counter; *home module is discretion — `Accrue.Dunning` recommended*) | service / query | transform (read-fold) | `events.ex` `bucket_by/2` :326 + `bucket_query/1` :354-362 | role-match (flat count vs time-bucketed) |
| `accrue/test/support/telemetry_ops_inventory.ex` (edit — add 4 events to `expected_ops_events/0`) | config (contract) | — | existing `expected_ops_events/0` :5-28 (same file) | exact |
| `accrue/lib/accrue/telemetry/metrics.ex` (edit — add 4 `counter/2` to `defaults/0`) | config (contract) | — | `counter("accrue.ops.dunning_exhaustion.count", tags: [:source])` :72 | exact |
| `accrue/guides/telemetry.md` (edit — catalog ~:89 + runbook ~:446) | config (docs contract) | — | `dunning_exhaustion` rows :89 / :446 (same file) | exact |
| `accrue_portal/lib/accrue_portal/live/subscription_live.ex` (edit — add banner `<section>` @ render :153, + 2 private helpers) | component (LiveView render) | request-response | `:if`/`<%= if %>` precedents :180/:198 + `cancel_subscription/1` :259-263 dispatch | exact |
| `accrue_portal/lib/accrue_portal/copy.ex` (edit — banner strings) | utility (copy SSOT) | — | existing `Copy.subscription_*` defs (same module) | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (edit — add read-only dunning `ax-card` + helpers) | component (LiveView render) | request-response | related-billing card :175-217 / timeline card :449-460 (same file) | exact |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` (edit — or new `Copy.Dunning`) | utility (copy SSOT) | — | `copy/subscription.ex` string defs :6-40 | exact |
| `accrue_admin/lib/accrue_admin/copy.ex` (edit — `defdelegate` new defs) | utility (copy delegator) | — | `defdelegate ..., to: Subscription` :18-39 (same file) | exact |
| `accrue/lib/accrue/dunning/campaign.ex` (**read-only reuse** — `next_step/3` :79-94) | service (pure resolver) | transform | — (reused as-is, not modified) | n/a (reuse) |
| `accrue/lib/accrue/billing/subscription.ex` (**read-only reuse** — `past_due?/1` :155-158, `dunning_campaign_active?/1` :269-272) | model (predicates) | — | — (reused as-is, not modified) | n/a (reuse) |
| `accrue/lib/accrue/telemetry/ops.ex` (**read-only reuse** — `Ops.emit/3`) | utility (emit helper) | event-driven | — (reused as-is, not modified) | n/a (reuse) |

## Pattern Assignments

### `accrue/lib/accrue/webhook/default_handler.ex` (webhook reducer, event-driven)

**Analog:** `maybe_emit_dunning_exhaustion/2` in the *same file* :764-781 — the canonical `[:accrue, :ops, :dunning_*]` emission shape. Three of the four lifecycle events land in this file.

**Telemetry emission pattern — mirror this exactly** (:768-777, the `dunning_exhaustion` raw-execute form):
```elixir
:telemetry.execute(
  [:accrue, :ops, :dunning_exhaustion],
  %{count: 1},
  %{
    subscription_id: updated.id,
    from_status: :past_due,
    to_status: to_status,
    source: dunning_source(row.dunning_sweep_attempted_at)
  }
)
```
> Recommended for the new four: use `Accrue.Telemetry.Ops.emit/3` (hardcodes `[:accrue, :ops]`, can't typo the namespace, auto-merges `operation_id`) — both forms are detected by the drift-gate scanner. The `source` enum + `dunning_source/1` helper (:893-904) already exist; reuse for `recovered`/`exhausted`.

**Emit sites in this file (verified anchors):**
- **`dunning.exhausted`** — beside the existing exhaustion telemetry inside `maybe_emit_dunning_exhaustion/2` :764-781 (confirmed-transition point, all loss sources). Both run inside the enclosing `Repo.transact/2` (the docstring :757-761 states this) → use `record_multi/3` for the ledger half.
- **`dunning.recovered`** — `maybe_finalize_dunning_campaign/2` :806-837, the recovery edge. The scope fence is explicit at :802-803: *"Scope fence: emits NO `dunning.recovered` ledger event / telemetry (Phase 129)."* This is your drop point. The `force_status_changeset` anchor-clear write at :821-823 is the in-transaction sibling → `record_multi/3` candidate.
- **`dunning.campaign_started`** — `maybe_start_dunning_campaign/2` :1138-1155, **the `count == 1` winner branch** at :1149 (`enqueue_day_zero_step`). This is a standalone `update_all` (not the reducer's `Repo.transact`) per the comment :1132-1135 → `record/1` (post-write) is the fit; `step_count = length(Accrue.Config.dunning_campaign_steps())`.

**Metadata shapes (D-01):**
- `dunning_campaign_started` → `%{subscription_id, step_count}` (**no `:source`**)
- `dunning_recovered` → `%{subscription_id, source}`
- `dunning_exhausted` → `%{subscription_id, to_status, source}`

> Pitfall (RESEARCH): the recovery/exhaustion edges *share* `maybe_finalize_dunning_campaign/2` (`finalizing_transition?/1` :843-846 covers both). Keep `dunning.recovered` and `dunning.exhausted` distinguished by which edge fired — `Subscription.active?/1` (recovery) vs `dunning_exhausted_status/1` non-nil (loss). Do NOT count "lost" from the sweeper's request-time event (see Shared Pattern: Lost-counting discipline).

---

### `accrue/lib/accrue/workers/dunning_step.ex` (worker, event-driven)

**Analog (ledger):** `dunning_sweeper.ex` :108-117 (the `Events.record/1` template). **Analog (telemetry):** `Accrue.Telemetry.Ops.emit/3`.

**Emit site:** `deliver_step/4` :160-170, **after** `Mailer.deliver(...)` returns (:169). The `## Scope fence` block :41-47 explicitly states *"this worker emits NO ledger events and NO telemetry (DUN-08, Phase 129)"* — your drop point. `deliver_step/4` is kept OUTSIDE any transaction (:156-157) → use `record/1` (not `record_multi/3`).

**Ledger write pattern — clone the sweeper** (:108-117):
```elixir
{:ok, _event} =
  Events.record(%{
    type: "dunning.terminal_action_requested",
    subject_type: "Subscription",
    subject_id: sub.id,
    data: %{terminal_action: Atom.to_string(terminal_action), mode: "accrue_sweeper"}
  })
```
For `step_sent`, `type: "dunning.step_sent"`, `data: %{step_key: step_key_str, step_index: idx}`. The worker already has `step_key_str` and `sub` in scope at :160. `step_index` derivation (RESEARCH Code Examples):
```elixir
steps = Accrue.Config.dunning_campaign_steps()
step_index = Enum.find_index(steps, fn s -> Atom.to_string(Keyword.fetch!(s, :key)) == step_key_str end)
```
**Telemetry:** `Ops.emit(:dunning_step_sent, %{count: 1}, %{subscription_id: sub.id, step_key: step_key_str, step_index: step_index})`.
> `subscription_id` is high-cardinality → never a tag. `step_key` is bounded (`:reminder`/`:action_required`/`:final_notice`).

---

### `accrue/lib/accrue/billing/dunning.ex` (service/query, transform) — `recovered_vs_lost/1`

**Analog:** `events.ex` `bucket_query/1` :354-362 — the type-filtered query primitive (`where(q, [e], e.type in ^types)` + `since:`/`until:` clauses). `bucket_by/2` :326 is the *time-bucketed* public reuse path; SC#4 only needs a flat `%{recovered:, lost:}`, so write a sibling flat counter (`bucket_query/1` is `defp`).

**Type-filter + window pattern to mirror** (:354-362):
```elixir
defp bucket_query(filter) do
  Enum.reduce(filter, from(e in Event), fn
    {:type, types}, q when is_list(types) -> where(q, [e], e.type in ^types)
    {:type, t}, q when is_binary(t) -> where(q, [e], e.type == ^t)
    {:since, %DateTime{} = ts}, q -> where(q, [e], e.inserted_at >= ^ts)
    {:until, %DateTime{} = ts}, q -> where(q, [e], e.inserted_at <= ^ts)
  end)
end
```
**Recommended flat-counter shape** (RESEARCH Code Examples; home module `Accrue.Dunning`):
```elixir
@spec recovered_vs_lost(keyword()) :: %{recovered: non_neg_integer(), lost: non_neg_integer()}
def recovered_vs_lost(opts \\ []) do
  %{recovered: count_events("dunning.recovered", opts), lost: count_events("dunning.exhausted", opts)}
end

defp count_events(type, opts) do
  import Ecto.Query
  q = from(e in Accrue.Events.Event, where: e.type == ^type)
  q = if since = opts[:since], do: where(q, [e], e.inserted_at >= ^since), else: q
  q = if until = opts[:until], do: where(q, [e], e.inserted_at <= ^until), else: q
  Accrue.Repo.aggregate(q, :count, :id)
end
```
> **No new table** (D-07). Counts ONLY `dunning.recovered` vs `dunning.exhausted` — never `dunning.terminal_action_requested` (D-06; see Shared Pattern: Lost-counting discipline).

---

### `accrue_portal/lib/accrue_portal/live/subscription_live.ex` (component, request-response) — recovery banner

**Analog:** the same file's conditional-render precedents (`:if={...}` :180, `<%= if ... %>` :198) and processor-dispatch private helpers (`cancel_subscription/1` :259-263, `preview_supported?/1` :265-266).

**Mount already loads everything needed** (:11-34): `assign(:subscription, subscription)` (:19) + `assign(:base_path, portal["mount_path"])` (:18). No new query — `Subscription.past_due?/1` and `dunning_campaign_active?/1` are directly callable on `@subscription`.

**Conditional-render precedent to clone** — the existing portal cards are `<section class="portal-card">` with `:if`/`<%= if %>` gating and `Copy.subscription_*()` strings throughout (:176-193). Insert a new `<section :if={recovery_prompt?(@subscription)} class="portal-card" role="alert" data-role="subscription-recovery-banner">` at render region ~:153 (before the first `portal-card` at :154), per UI-SPEC Markup Inventory.

**Processor-dispatch helper pattern to mirror** (:259-263 — the ONLY real precedent; note CONTEXT's ":259/:265 reads `@subscription.processor`" is imprecise — these are *private helpers* pattern-matching `%Subscription{processor: "braintree"}`, NOT template reads):
```elixir
defp cancel_subscription(%Subscription{processor: "braintree"} = subscription),
  do: Billing.cancel(subscription)
defp cancel_subscription(%Subscription{} = subscription),
  do: Billing.cancel_at_period_end(subscription)
```
New helpers (same shape):
```elixir
defp recovery_prompt?(%Subscription{} = sub),
  do: Subscription.past_due?(sub) or Subscription.dunning_campaign_active?(sub)
defp update_pm_path(base, %Subscription{processor: "braintree"}), do: base <> "/payment-methods/new"
defp update_pm_path(base, %Subscription{}), do: base <> "/payment-methods"  # Stripe dest = discretion (RESEARCH A4)
```
> `AccruePortal.Path` has `payment_methods/1` but NO `payment_methods_new/1` (RESEARCH :544) — add a helper or inline the `<> "/payment-methods/new"` literal; the Braintree route exists at `router.ex:91`. Provider-CTA must mirror `card_expiring_soon.ex` `@update_pm_url` (see Shared Pattern: Provider-aware CTA).

**UI-SPEC contract (binding):** reuse `.portal-card`, `.portal-actions`, `.portal-button-primary` verbatim — NO new CSS. Banner copy: heading "Your payment didn't go through", CTA "Update payment method" (matches the email CTA verbatim). Tone = neutral `.portal-card` (NOT the alarmist red `.portal-inline-error`). `role="alert"`. Never leak `dunning`/`campaign`/`past_due` to the customer.

---

### `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (component, request-response) — read-only dunning panel

**Analog:** the related-billing `ax-card` :175-217 (structure) and the ledger-timeline `ax-card` :449-460 (Copy-routed header + `Timeline` reuse) — both in the same file.

**`ax-card` structure to clone** (:175-179 — header pattern):
```elixir
<article class="ax-card" data-role="subscription-related-billing">
  <header class="ax-page-header">
    <p class="ax-eyebrow"><%= Copy.subscription_drill_related_card_title() %></p>
    <h3 class="ax-heading"><%= Copy.subscription_drill_related_card_title() %></h3>
  </header>
```
**Timeline reuse pattern** (:455-459 + `timeline_events/1` :538-539) — for optional dunning step history filtered to `dunning.*`:
```elixir
defp timeline_events(subscription_id),
  do: Events.timeline_for("Subscription", subscription_id, limit: 25)
```
**Next-action via the pure resolver (D-14)** — `@subscription` is loaded with `dunning_campaign_started_at` (`load_subscription/1` :529-536 preloads the full struct). Call `Accrue.Dunning.Campaign.next_step/3` (:79-94, returns `{:next, step, schedule_in} | :done`):
```elixir
defp next_action_summary(%Subscription{dunning_campaign_started_at: %DateTime{} = anchor}) do
  steps = Accrue.Config.dunning_campaign_steps()
  case Accrue.Dunning.Campaign.next_step(steps, anchor, Accrue.Clock.utc_now()) do
    {:next, step, schedule_in} -> {Keyword.fetch!(step, :key), schedule_in}
    :done -> :done
  end
end
defp next_action_summary(_), do: :inactive
```
> Pass `Accrue.Clock.utc_now()` (NOT `DateTime.utc_now()`) for Fake-lane determinism, matching the rest of the engine (RESEARCH Pitfall 6).

**UI-SPEC contract (binding):** `<article class="ax-card" data-role="subscription-dunning-state">`; reuse `.ax-card`, `.ax-page-header`, `.ax-eyebrow`, `.ax-heading`, `.ax-stack-sm`, `.ax-body`, `.ax-label`, `.ax-status-badge` (tone: `-amber` active / `-moss` recovered / `-slate` none), `.ax-status-dot`. **Read-only — NO `phx-click`/`phx-submit`/`<button>`/`<form>`** (render test asserts `refute has_element?(view, "[data-role='subscription-dunning-state'] button")`). Every string via `Copy.dunning_*()`.

---

### `accrue_admin/lib/accrue_admin/copy/subscription.ex` + `accrue_admin/lib/accrue_admin/copy.ex` (copy SSOT + delegator)

**Analog:** existing `Copy.Subscription` string defs :6-40 + the `defdelegate ..., to: Subscription` delegator pattern in `copy.ex` :18-39.

**String-def pattern** (`copy/subscription.ex` :20-23):
```elixir
def subscription_action_cancel_now, do: "Cancel now"
def subscription_action_cancel_at_period_end, do: "Cancel at period end"
```
**Delegator pattern** (`copy.ex` :27-28):
```elixir
defdelegate subscription_action_cancel_now(), to: Subscription
defdelegate subscription_action_cancel_at_period_end(), to: Subscription
```
> Add the dunning panel strings (UI-SPEC prescribed wording: "DUNNING" eyebrow, "Dunning campaign" title, "Started"/"Current step"/"Next scheduled action" labels, "No active dunning campaign" empty state, etc.) as new `def`s, then `defdelegate` each in `copy.ex`. A dedicated `AccrueAdmin.Copy.Dunning` submodule is acceptable (alias + `defdelegate ..., to: Dunning`) — discretion per CONTEXT.

---

### `accrue_portal/lib/accrue_portal/copy.ex` (copy SSOT)

**Analog:** the portal's existing `Copy.subscription_*()` defs (every visible portal string already routes here — `subscription_live.ex` :155-205). Add `subscription_recovery_heading/0`, `_body/0`, `_cta/0` with UI-SPEC wording. Portal Copy already carries past-due strings to mirror in tone (RESEARCH :255).

---

## Shared Patterns

### Drift Gate (HARD exit criterion — the phase's #1 risk)
**Sources:** `accrue/test/accrue/telemetry/ops_event_contract_test.exs` (set-equality scanner) + `metrics_ops_parity_test.exs`.
**Apply to:** all four new telemetry events — register them in **lockstep, per event**, or the build goes red.

Four contract surfaces must agree (strict set-equality, enforced):
1. **Inventory** — add to `expected_ops_events/0` in `accrue/test/support/telemetry_ops_inventory.ex` (:5-28). Append:
   ```elixir
   [:accrue, :ops, :dunning_campaign_started],
   [:accrue, :ops, :dunning_step_sent],
   [:accrue, :ops, :dunning_recovered],
   [:accrue, :ops, :dunning_exhausted]
   ```
2. **Emit site in `lib/`** — the scanner regex-scans `lib/**/*.ex` ONLY. An event in the inventory but emitted only from `test/`/`support/` FAILS the `unwired` check. Emit from `default_handler.ex` / `dunning_step.ex` (both under `lib/`).
3. **Metrics** — add a `counter/2` per event in `metrics.ex` `defaults/0` (mirror :72). **`tags:` MUST match actual metadata** or Telemetry.Metrics silently discards the event:
   ```elixir
   counter("accrue.ops.dunning_campaign_started.count"),               # NO :source
   counter("accrue.ops.dunning_step_sent.count"),                      # NO :source (avoid subscription_id)
   counter("accrue.ops.dunning_recovered.count", tags: [:source]),
   counter("accrue.ops.dunning_exhausted.count", tags: [:source]),
   ```
4. **Guide** — add each `inspect(event)` literal to `accrue/guides/telemetry.md` BOTH the ops catalog (~:89, mirror the `dunning_exhaustion` row :89) AND the operator runbook (~:446, mirror :446 with a "suggested first actions" cell).

> The `:ops` namespace is the single enforced family — do NOT open a `[:accrue, :dunning, *]` root (D-01); that would fork the contract and bypass the gate. The DUN-08/ROADMAP literal `[:accrue, :dunning, *]` is superseded by design.

### Ledger write (clone the sweeper)
**Source:** `accrue/lib/accrue/jobs/dunning_sweeper.ex` :108-117 (`Events.record/1`) + `accrue/lib/accrue/events.ex` `record_multi/3` :134-140 (in-transaction).
**Apply to:** all four ledger events. `record/1` post-write/post-deliver; `record_multi/3` where the emit site is already inside an `Ecto.Multi`/`Repo.transact` (`recovered`/`exhausted` → multi; `step_sent`/`campaign_started` → `record/1`). No event-type registration needed — `current_schema_version/1` (`events.ex:395`) defaults unknown types to 1; there is no allowlist (the sweeper's existing dotted type is registered nowhere special).

### Ops telemetry emission (mirror the exhaustion event)
**Source:** `accrue/lib/accrue/telemetry/ops.ex` `emit/3` (hardcoded `[:accrue, :ops]` prefix, `operation_id` auto-merge) + `default_handler.ex:768-777` (raw form).
**Apply to:** all four telemetry events. Prefer `Ops.emit/3` for the new four (can't typo namespace); the raw `:telemetry.execute/3` form (what the mirror uses) is equally gate-detected. Measurements always `%{count: 1}`.

### Lost-counting discipline (no double-count)
**Source:** D-05/D-06; the request-time event lives at `dunning_sweeper.ex:108-117` (`"dunning.terminal_action_requested"`).
**Apply to:** `recovered_vs_lost/1` AND the new `dunning.exhausted` emit. "Lost" is counted ONLY from `dunning.exhausted` (confirmed transition, all sources) — NEVER from `dunning.terminal_action_requested` (request-time intent, sweeper-only, may exist with no campaign). The two are deliberately distinct moments → structurally impossible to double-count.

### Provider-aware CTA (banner ↔ email must not diverge)
**Source:** `accrue/lib/accrue/emails/card_expiring_soon.ex` `@update_pm_url` (:73-75, :106) — the email reads a host-supplied/resolved update-PM URL; the portal banner must resolve the same target the same provider-aware way.
**Apply to:** the portal banner CTA. Dispatch on `subscription.processor` (mirror `cancel_subscription/1` :259-263): Braintree → `/payment-methods/new` (the only PM-add LiveView, which is Braintree-only via `BraintreeClient.client_token_for/1`); Stripe/others → `/payment-methods` (in-portal list, the safe default — RESEARCH A4 flags the exact Stripe destination as discretion). Banner CTA wording matches the email's "Update payment method" verbatim.

### Read-only + Copy-SSOT (admin surface discipline)
**Source:** D-12/D-13; UI-SPEC Copywriting Contract.
**Apply to:** the admin dunning panel. NO mutations (`phx-*`/`<button>`/`<form>`). Every operator string through `AccrueAdmin.Copy` (hardcoded string in template = contract violation). Reuse `current_owner_scope` — the panel reads ONLY `@subscription` already loaded under scope (`Subscriptions.detail/2` / `load_subscription/1` :529-536); add no new data path that bypasses scoping.

### Reuse, don't reinvent (no-new-table / canonical predicates)
**Apply to:** banner gate + admin panel + counter. `Subscription.past_due?/1` (:155-158) and `dunning_campaign_active?/1` (:269-272) are the canonical predicates (the latter reads the Phase-128 `dunning_campaign_started_at` anchor) — call them, don't compare status atoms in templates. `Accrue.Dunning.Campaign.next_step/3` is the pure next-action resolver — don't hand-roll date math. The counter folds `accrue_events` — no new table, no new persistence.

## No Analog Found

None. Every new behavior in this phase has an in-tree clone source (verified this session). The closest thing to a gap is the **recovered-vs-lost flat counter**: `bucket_by/2` is *time-bucketed* and `bucket_query/1` is `defp`, so the flat `%{recovered:, lost:}` counter writes its own small `Repo.aggregate` query — but it directly mirrors `bucket_query/1`'s type-filter + `since:`/`until:` shape, so this is a role-match, not a no-analog.

## Metadata

**Analog search scope:** `accrue/lib/accrue/{webhook,workers,jobs,dunning,billing,telemetry,emails,events}.ex`, `accrue/test/support/`, `accrue/guides/`, `accrue_admin/lib/accrue_admin/{live,copy,components}/`, `accrue_portal/lib/accrue_portal/{live,copy,path}.ex`.
**Files scanned (read this session):** 14 analog sources, every CONTEXT/RESEARCH `file:line` anchor re-verified (all at/within ±2 lines of claimed positions).
**Pattern extraction date:** 2026-05-25
