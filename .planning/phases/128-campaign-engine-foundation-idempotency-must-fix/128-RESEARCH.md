# Phase 128: Campaign Engine Foundation + Idempotency Must-Fix - Research

**Researched:** 2026-05-24
**Domain:** Durable Oban dunning campaign orchestration · NimbleOptions config validation · email idempotency (Oban `unique`) · race-safe lifecycle keying (Ecto `update_all` + nullable anchor column)
**Confidence:** HIGH (this was a verification pass against locked CONTEXT.md decisions; every load-bearing claim re-checked against live source + installed-version dep source + official docs)

## Summary

CONTEXT.md locked the full architecture across 17 decisions. This research is a **verification pass**, not a redesign. **All 17 decisions are confirmed sound and all file:line anchors hold** (with minor 1-10 line drift documented below — none breaking). The three flagged load-bearing claims all CONFIRM:

1. **D-13 (idempotency keystone) — CONFIRMED with a sharpening.** Mailglass's `compute_idempotency_key/1` content-hashes (sha256 over `tenant|mailable|recipient|content_hash`) and Accrue's stamped `:idempotency_key` metadata is NOT used for dedup at all. The Mailglass `Delivery` schema *does* carry a partial unique index on its own content-hash key — but on the **sync `deliver/2` hot path Accrue uses** (`persist_queued` → `Ecto.Multi.insert` via `Delivery.changeset`), it is a plain insert that relies on `unique_constraint/2` validation, so a duplicate surfaces as a **changeset/constraint error that Oban then retries** — NOT a silent dedup. The Swoosh lane applies no key. Net: CONTEXT's conclusion is correct — **Oban `unique` at enqueue is the only clean, lane-independent dedup**, and it doubly applies because `:invoice_payment_failed` currently routes through the Swoosh lane (`deliver_swoosh`), which has no dedup whatsoever.

2. **Oban 2.22.1 — CONFIRMED.** `mix.lock:51` pins `oban 2.22.1` (not the 2.21 in CLAUDE.md). The CONTEXT-proposed `unique` config matches the **installed dep's own documented example verbatim** (`deps/oban/lib/oban/job.ex:307`). `Oban.cancel_all_jobs/2` takes an Ecto queryable and returns `{:ok, count}`; a duplicate unique insert returns `{:ok, %Oban.Job{conflict?: true}}` (silent, no retry). Chained execution IS Oban Pro → the step chain must be hand-rolled (as decided).

3. **File:line anchors — CONFIRMED with documented drift.** Every anchor cited in CONTEXT exists and the surrounding pattern holds. Drift is small (e.g., `do_dispatch_invoice` *def* is at 1472 while the `payment_failed` *clause* is at 1466; `validate_entitlements_price_ids!` *call* is 958 / *def* is 968). Corrected line table below.

**Primary recommendation:** Proceed to planning exactly as CONTEXT.md specifies. The architecture is correct and idiomatic. The single most important correctness mechanism is **D-09's atomic `update_all ... where is_nil(anchor)` first-transition guard** — this is the DB-level race-safety primitive; Oban's OSS `unique` is documented as advisory-lock-based and "prone to race conditions in some circumstances," so it is correctly positioned by CONTEXT as a *backstop*, not the primary guarantee.

## User Constraints (from CONTEXT.md)

### Locked Decisions

All 17 decisions (D-01 .. D-17) in `128-CONTEXT.md` are LOCKED. Summarized for the planner; the CONTEXT file is authoritative for full text.

- **D-01** Default journey = 3 escalating steps, absolute day offsets `[0, 5, 12]`: `:reminder` (reuse `Accrue.Emails.InvoicePaymentFailed`), `:action_required` (NEW `Accrue.Emails.DunningActionRequired`), `:final_notice` (NEW `Accrue.Emails.DunningFinalNotice`). Every CTA deep-links the portal `add_payment_method_live` (resolve URL like `card_expiring_soon.ex`'s `@update_pm_url`). Offsets are a tunable config default, not a published commitment.
- **D-02** New module names are the ONE published-API commitment: `Accrue.Emails.DunningActionRequired` (atom `:dunning_action_required`), `Accrue.Emails.DunningFinalNotice` (atom `:dunning_final_notice`). Follow `Mailglass.Mailable` + `Phoenix.Component` convention; add both atoms to `default_template/1`.
- **D-03** Opt-out posture: ship `enabled: true`. Disable via `dunning: [campaign: [enabled: false]]` / `campaign: false` shorthand / umbrella `dunning: [mode: :disabled]`. Doc-warning for hosts also running Stripe Dashboard dunning (doc itself is Phase 130).
- **D-04** Config shape: explicit `enabled:` + ordered absolute-day step list nested under existing `:dunning` key (config.ex). Step shape `[after_days: <non_neg_int>, key: <atom>, template: <module>]` — all three required. `after_days` ABSOLUTE from campaign start, strictly increasing, unique. `key` required + load-bearing (becomes `step_key` Oban-unique arg).
- **D-05** Off-switch: validator normalizes `campaign: false` → `[enabled: false, steps: []]`; `steps: []` while `enabled: true` is a LOUD error.
- **D-06** Two-layer validation: (intra-list) per-field `{:custom}` validator `validate_dunning_campaign/1` cloning `validate_descending/1`; (cross-field) hand-written `validate_dunning_campaign_grace!/1` raising `Accrue.ConfigError` from `maybe_validate_boot_setup!/1`, right after `validate_entitlements_price_ids!/1`.
- **D-07** Accessors: `dunning_campaign/0`, `dunning_campaign_enabled?/0`, `dunning_campaign_steps/0` (raw-read + own default, mirroring `past_due_grace/0`). Module attrs `@step_schema` + `@default_dunning_steps`.
- **D-08** Anchor = single nullable column `dunning_campaign_started_at :utc_datetime_usec` on `accrue_subscriptions` (column add, NOT new table; mirrors `dunning_sweep_attempted_at`). Add to schema + `@cast_fields` + `force_status_changeset` cast list; add predicate `Subscription.dunning_campaign_active?/1`. Forward-only nullable migration, no index required.
- **D-09** First-transition detection + race-safe guard live in `maybe_bump_past_due_since/2`. First edge = anchor currently `nil` (NOT `status`, NOT `past_due_since`). Single atomic `update_all ... where: is_nil(s.dunning_campaign_started_at)`. `count == 1` ⇒ won the edge → enqueue day-0 step. `count == 0` ⇒ already running → no-op. Sibling statement to the `force_status_changeset`/`optimistic_lock` path.
- **D-10** Worker `Accrue.Workers.DunningStep`, `use Oban.Worker, queue: :accrue_dunning, max_attempts: 3` (reuse existing queue). `campaign_started_at` carried in args as ISO8601 string (`maybe_iso8601/1` precedent).
- **D-11** `DunningStep.perform/1`: (1) cancel-guard FIRST (reload row; not past_due OR nil anchor → `{:cancel, :recovered}`); (2) deliver via `Accrue.Mailer.deliver/2`; (3) resolve + enqueue next step via `Accrue.Dunning.Campaign` with SAME `campaign_started_at` + `schedule_in`.
- **D-12** Cancel-on-recovery: `maybe_finalize_dunning_campaign/2` beside `maybe_emit_dunning_exhaustion/2` (+ on `invoice.paid` path). When was-past-due-with-anchor → active/paid: in one transaction nil the anchor + proactively `Oban.cancel_all_jobs` keyed on `worker` + `subscription_id` + `campaign_started_at`. Per-step cancel-guard is backstop.
- **D-13** Primary dedup = Oban `unique` at ENQUEUE in `Accrue.Mailer.Default.deliver/2`, mapping ONLY `:invoice_payment_failed` (`false` for all other types). `keys: [:type, :invoice_id]`, `period: :infinity`, `states: [:available, :scheduled, :executing, :retryable, :completed]`.
- **D-14** Backstop = new `idempotency_key/2` clause for `:invoice_payment_failed` keyed on `invoice_id` → `"accrue:v1:invoice_payment_failed:#{invoice_id}"`.
- **D-15** Immediate ↔ campaign = REPLACE: campaign enabled ⇒ skip standalone `do_dispatch_invoice(:invoice_payment_failed, …)` (campaign step-1 owns day-0); campaign disabled ⇒ standalone fires (now deduped by D-13/D-14). Disjoint keyspaces.
- **D-16** Campaign-step `unique`: `keys: [:subscription_id, :step_key, :campaign_started_at]`, `period: :infinity`, `states: [:available, :scheduled, :executing, :retryable, :completed]`.
- **D-17** Step-email dedup identity in assigns (`subscription_id` + `step_key` + `campaign_started_at`); optional `idempotency_key/2` backstop clause keyed `accrue:v1:dunning_step:<sub>:<step_key>:<started_at>` — **planner's discretion**.

### Claude's Discretion

- Exact module placement for `Accrue.Dunning.Campaign` (pure step-resolver) vs inlining in worker — keep pure/property-testable + engine-seam-ready for Phase 131.
- Whether step emails also receive `idempotency_key/2` backstop clauses (D-17) or rely solely on step-worker `unique` (D-16).
- Exact migration timestamp/name; exact `now_usec` clock call (use `Accrue.Clock.utc_now/0` for Fake-lane determinism).
- Whether `do_dispatch_invoice` gating (D-15) reads `dunning_campaign_enabled?/0` inline or via a small helper.

### Deferred Ideas (OUT OF SCOPE)

- Ledger events (`dunning.campaign_started`/`step_sent`/`recovered`/`exhausted`) + `[:accrue, :dunning, *]` telemetry + recovered-vs-lost counter → **DUN-08, Phase 129**. Build the engine so they drop in cleanly; do NOT emit in 128.
- Customer portal recovery banner + read-only admin dunning-state view → DUN-06/DUN-07, **Phase 129**.
- Provider-honest docs + drift gate + Fake-lane merge gate + example-host wiring → DUN-09/DUN-10, **Phase 130** (incl. the over-email doc-warning whose *posture* is decided in D-03).
- `Accrue.Dunning.Engine` behaviour + Chimeway adapter → DUN-03, **Phase 131**. Keep `Accrue.Dunning.Campaign` pure + seam-ready; do NOT introduce the behaviour.
- Extending enqueue-`unique` dedup to other email types → out of DUN-04 scope; `dedup_unique/2` returns `false` for them (no regression).
- Per-customer cadence / multi-channel (SMS/push) / recovered-revenue dashboard → milestone Out-of-Scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DUN-01 | Multi-step dunning cadence via NimbleOptions config nested under `:dunning`, default journey shipped opt-out | `validate_descending/1` (config.ex:1046) + `validate_entitlements_price_ids!/1` (config.ex:968) give the exact two-layer validation precedent; `past_due_grace/0` (config.ex:784) the accessor precedent; existing `dunning:` schema entry at config.ex:228 is the nesting point. CONFIRMED. |
| DUN-02 | First-party durable Oban campaign scheduling steps from local state, emitting via Mailglass | `metered_renewal_actions.ex:307` `unique:` worker + `:312` `maybe_iso8601/1` (scalar args); `dunning_sweeper.ex:46` `:accrue_dunning` queue reuse; `Accrue.Mailer.deliver/2` pipeline (mailer/default.ex:33). `maybe_bump_past_due_since/2` (default_handler.ex:969) already loads `%Subscription{}` on `invoice.payment_failed` — the natural start site. CONFIRMED. |
| DUN-04 | Failed-payment + dunning-step emails idempotent (fix un-deduped `:invoice_payment_failed`) | Mailglass does NOT dedup on Accrue's stamped metadata (verified, outbound.ex). `:invoice_payment_failed` currently hits the Swoosh lane with NO dedup. Oban `unique` (job.ex:307 example match) + new `idempotency_key/2` clause (mailer.ex:314 catch-all is the insertion point). CONFIRMED. |
| DUN-05 | Campaign cancels on leaving `past_due`; keyed so later failure webhooks can't restart/duplicate | Atomic `update_all where is_nil(anchor)` (DB-level race-safe) + `Oban.cancel_all_jobs/2` ({:ok, count}, kills executing) + per-step live-state cancel-guard. Anchor column mirrors `dunning_sweep_attempted_at` (subscription.ex:65). `maybe_emit_dunning_exhaustion/2` (default_handler.ex:758) receives the `(row, updated)` prior→new pair needed for recovery detection. CONFIRMED. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cadence config + validation | `Accrue.Config` (boot-time) | — | NimbleOptions schema + boot validator; pure, host-owned config. Fails loud at app boot. |
| Pure step resolution (`after_days` → next step + delay) | `Accrue.Dunning.Campaign` (domain/pure) | — | Pure function of `(steps, campaign_started_at, now)`; property-testable; engine-seam-ready for Phase 131. |
| First-transition detection + race-safe start | DB (Ecto `update_all`) inside `maybe_bump_past_due_since/2` (webhook reducer) | Oban `unique` | DB-atomic `where is_nil` is the ONLY race-safe elector under concurrent webhooks; Oban OSS unique is advisory-only → backstop. |
| Durable step scheduling + chaining | Oban (`Accrue.Workers.DunningStep`) | — | Durable, survives node restart, independent of webhook re-fires (DUN-02 core requirement). |
| Email delivery | `Accrue.Mailer` → Mailglass/Swoosh lanes | — | Reuse existing mailer pipeline; no new delivery surface. |
| Email/step dedup | Oban `unique` at enqueue (DB-backed for the email Mailer enqueue is OSS-advisory) | per-step live cancel-guard + `idempotency_key/2` | Lane-independent; disjoint keyspaces (`accrue:v1:invoice_payment_failed:<inv>` vs step `[sub, step_key, started_at]`). |
| Cancel-on-recovery | Webhook reducer (`maybe_finalize_dunning_campaign/2`) → `Oban.cancel_all_jobs` | per-step cancel-guard (D-11) | Proactive bulk-cancel + self-cancel backstop for jobs racing the cancel query. |

## Standard Stack

No new external dependencies. Everything is already in `mix.lock`. Verified versions:

| Library | Installed Version | Purpose | Verification |
|---------|-------------------|---------|--------------|
| `:oban` | **2.22.1** | Durable step workers + `unique` dedup + `cancel_all_jobs/2` | `[VERIFIED: mix.lock:51]` — `2.22.1`, hex checksum present. Supersedes CLAUDE.md's `~> 2.21` note. |
| `:mailglass` | **1.0.0** | Email delivery (sync `deliver/2` lane) | `[VERIFIED: mix.lock:36]` — `1.0.0`. |
| `:nimble_options` | `~> 1.1` | Config schema + the `{:custom}` validator hook | `[VERIFIED: CLAUDE.md stack table + existing config.ex usage]` |
| `:ecto`/`:ecto_sql` | `~> 3.13` | `Repo.update_all/2`, `Repo.transact/2`, schema column | `[VERIFIED: existing codebase]` |
| `:stream_data` | `~> 1.3` | Property tests for the pure step resolver + config validator | `[VERIFIED: 5 existing property tests in test/property/]` |
| `:mox` | `~> 1.2` | Processor mocking (Fake processor posture) | `[VERIFIED: test_helper.exs Accrue.MoxSetup.define_mocks/0]` |

**Installation:** None required. (No new packages → no Package Legitimacy Audit section needed.)

## Architecture Patterns

### System Architecture Diagram

```
Stripe webhook: invoice.payment_failed  ─────────────────────────────┐
       │ (may re-fire on every Smart Retry, weeks 1–4)               │
       ▼                                                              │
[Webhook plug → ingest → DispatchWorker → DefaultHandler]            │
       │  (UNCHANGED ingress)                                        │
       ▼                                                              │
reduce_invoice("payment_failed", …)                                  │
       │                                                              │
       ├─► maybe_bump_past_due_since/2  (default_handler.ex:969)      │
       │     ├─ bump past_due_since (UNCHANGED — grace measured       │
       │     │   from Stripe's next_payment_attempt)                  │
       │     └─ D-09 NEW: atomic first-transition elector            │
       │          update_all WHERE is_nil(dunning_campaign_started_at)│
       │            ├─ count==1 → won → enqueue DunningStep day-0 ────┼──┐
       │            └─ count==0 → already running → no-op             │  │
       │                                                              │  │
       └─► maybe_dispatch_invoice_email("payment_failed", …) :1466    │  │
             └─ D-15 GATE: campaign enabled? ──┬─ YES → skip (step-1  │  │
                                               │        owns day-0)   │  │
                                               └─ NO  → safe_deliver  │  │
                                                       (deduped by    │  │
                                                        D-13/D-14)    │  │
                                                                      │  │
   ┌──────────────────────────────────────────────────────────────────┘
   │  Oban :accrue_dunning queue                                     │
   ▼                                                                 │
Accrue.Workers.DunningStep.perform/1  (D-10, D-11)                   │
   unique[sub_id, step_key, campaign_started_at] period :infinity   │
   │                                                                 │
   ├─(1) cancel-guard: reload sub; not past_due OR nil anchor?       │
   │       └─► {:cancel, :recovered}  (no email)                     │
   ├─(2) deliver step email via Accrue.Mailer.deliver/2 ─► Mailglass │
   └─(3) Accrue.Dunning.Campaign.next_step(steps, started_at, now)   │
           └─ if next → enqueue DunningStep (SAME started_at) ───────┘
                          schedule_in: next_delay

Stripe webhook: invoice.paid / customer.subscription.updated→active ──┐
       ▼                                                              │
reduce_subscription(…) :722                                          │
   └─► maybe_finalize_dunning_campaign/2 (D-12, beside :758)         │
         when was past_due + anchor non-nil → now active/paid:       │
         ├─ nil the anchor (force_status_changeset)                  │
         └─ Oban.cancel_all_jobs(query keyed on started_at) ─────────┘
            (per-step cancel-guard = backstop for in-flight jobs)
```

### Recommended Module Layout

```
accrue/lib/accrue/
├── config.ex                       # ADD: campaign: schema entry, @step_schema,
│                                   #      @default_dunning_steps, validate_dunning_campaign/1,
│                                   #      validate_dunning_campaign_grace!/1, 3 accessors
├── dunning/
│   └── campaign.ex                 # NEW: pure step-resolver (next_step/schedule, property-tested)
├── workers/
│   ├── dunning_step.ex             # NEW: Oban.Worker, cancel-guard + deliver + chain (D-10/D-11/D-16)
│   └── mailer.ex                   # ADD: idempotency_key(:invoice_payment_failed, …) clause (D-14)
├── mailer/default.ex               # ADD: dedup_unique/2 + unique: in deliver/2 (D-13)
├── billing/subscription.ex         # ADD: dunning_campaign_started_at field, @cast_fields entry,
│                                   #      force_status_changeset cast, dunning_campaign_active?/1
├── webhook/default_handler.ex      # ADD: D-09 elector in maybe_bump_past_due_since/2,
│                                   #      maybe_finalize_dunning_campaign/2 (D-12),
│                                   #      D-15 gate in do_dispatch_invoice path
└── emails/
    ├── dunning_action_required.ex  # NEW (D-02) — clone card_expiring_soon.ex structure
    └── dunning_final_notice.ex     # NEW (D-02) — clone card_expiring_soon.ex structure
accrue/priv/repo/migrations/
└── XXXX_add_dunning_campaign_started_at_to_subscriptions.exs  # NEW (D-08), nullable, forward-only
```

### Pattern 1: Two-layer NimbleOptions validation (D-06)

**What:** Intra-list constraints in a per-field `{:custom}` validator returning `{:ok, val} | {:error, msg}`; cross-field constraints in a hand-written boot validator that RAISES.
**When to use:** Whenever a constraint spans sibling config keys (NimbleOptions `{:custom}` only sees one field's value).

```elixir
# Source: accrue/lib/accrue/config.ex:1046 (validate_descending — the per-field clone target)
@spec validate_descending(term()) :: {:ok, [pos_integer()]} | {:error, String.t()}
def validate_descending(list) when is_list(list) and list != [] do
  cond do
    not Enum.all?(list, &(is_integer(&1) and &1 > 0)) ->
      {:error, "expected a list of positive integers, got: #{inspect(list)}"}
    not strictly_descending?(list) ->
      {:error, "expected a strictly descending list of positive integers, got: #{inspect(list)}"}
    true -> {:ok, list}
  end
end

# Source: accrue/lib/accrue/config.ex:947,968 (the boot cross-field guard pattern)
defp maybe_validate_boot_setup!(opts) do
  # ...
  _ = validate_entitlements_price_ids!(opts)   # existing cross-field precedent (:958 call)
  # D-06: add HERE, directly after →  _ = validate_dunning_campaign_grace!(opts)
  :ok
end

defp validate_entitlements_price_ids!(opts) do
  # ... raises Accrue.ConfigError on cross-plan collision (the raise-on-boot precedent)
end
```

For the campaign validator, the analogous shape: `validate_dunning_campaign/1` validates each step against a private `@step_schema` (via `NimbleOptions.validate/2`), then checks `after_days` strictly-increasing + unique, `key` unique, non-empty-when-enabled, and normalizes `campaign: false` → `[enabled: false, steps: []]`. `validate_dunning_campaign_grace!/1` reads sibling `grace_days` and raises `Accrue.ConfigError` (defined at `lib/accrue/errors.ex:112`) if `last_step.after_days > grace_days`.

### Pattern 2: Raw-read accessor with own nested default (D-07)

```elixir
# Source: accrue/lib/accrue/config.ex:771,784
def dunning, do: get!(:dunning)
def past_due_grace, do: entitlements() |> Keyword.get(:past_due_grace, :none)
# D-07 mirror:  def dunning_campaign, do: dunning() |> Keyword.get(:campaign, [enabled: true, steps: @default_dunning_steps])
#               def dunning_campaign_enabled?, do: Keyword.get(dunning_campaign(), :enabled, false)
#               def dunning_campaign_steps, do: if(dunning_campaign_enabled?(), do: Keyword.get(dunning_campaign(), :steps, []), else: [])
```

### Pattern 3: Atomic first-transition elector (D-09) — THE race-safety primitive

```elixir
# Site: accrue/lib/accrue/webhook/default_handler.ex:969 (maybe_bump_past_due_since/2)
# Runs as a SIBLING statement to the existing force_status_changeset/optimistic_lock path
# (sets one column, never touches lock_version). DB-atomic ⇒ exactly one winner under
# concurrent invoice.payment_failed webhooks. THIS is the correctness keystone, NOT Oban unique.
now_usec = %{Accrue.Clock.utc_now() | microsecond: {0, 6}}   # matches dunning_sweeper.ex:101

{count, _} =
  from(s in Subscription, where: s.id == ^sub.id and is_nil(s.dunning_campaign_started_at))
  |> Repo.update_all(set: [dunning_campaign_started_at: now_usec])

case count do
  1 -> # won the edge → enqueue day-0 DunningStep with campaign_started_at: DateTime.to_iso8601(now_usec)
  0 -> :ok  # already running → no-op (in-flight chain untouched; past_due_since bump still happened)
end
```

### Pattern 4: Oban worker `unique` (D-16) + ISO8601 scalar args (D-10)

```elixir
# Source: accrue/lib/accrue/billing/metered_renewal_actions.ex:307,312 (unique + maybe_iso8601)
# AND deps/oban/lib/oban/job.ex:307 (the INSTALLED-version documented example — exact match):
#   states = [:available, :scheduled, :executing, :retryable, :completed]
use Oban.Worker, queue: :accrue_dunning, max_attempts: 3
# enqueue:
%{subscription_id: id, step_key: Atom.to_string(key), campaign_started_at: iso, ...}
|> Accrue.Workers.DunningStep.new(
     schedule_in: delay,
     unique: [fields: [:worker, :args],
              keys: [:subscription_id, :step_key, :campaign_started_at],
              period: :infinity,
              states: [:available, :scheduled, :executing, :retryable, :completed]]
   )
|> Oban.insert()
# campaign_started_at is an ISO8601 STRING (Oban args are JSON; only_scalars! forbids structs)
defp maybe_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)   # the precedent
```

### Anti-Patterns to Avoid

- **Deriving the campaign key from `past_due_since` or `status`.** `past_due_since` is re-bumped on EVERY failure webhook (default_handler.ex:969 body), and `status` may already be `:past_due` from a prior failure. Only `is_nil(dunning_campaign_started_at)` reliably identifies the FIRST transition. (CONTEXT `<specifics>` — verified against the live bump logic.)
- **Relying on Oban `unique` as the primary race guard.** Oban OSS `unique` is advisory-lock-based and documented as "prone to race conditions in some circumstances" (the Smart Engine that uses DB constraints is Pro-only). The DB-atomic `update_all` (D-09) is primary; Oban unique is the second backstop. `[CITED: hexdocs.pm/oban/unique_jobs.html]`
- **Calling the email adapter inside a transaction.** Mailglass D-20 forbids adapter-in-transaction (connection-pool starvation). Accrue's enqueue-then-async pattern already avoids this — keep the step worker's deliver call outside any `Repo.transact`.
- **Keying the immediate dedup on `invoice_number`.** `invoice_number` is nullable and gets dropped by `drop_nils` (default_handler.ex:1484); key on `invoice_id` (always present, = `invoice.id`). (D-14, verified against `do_dispatch_invoice` assigns at :1477.)
- **Stamping the anchor inside `force_status_changeset` cast on the SAME changeset as the status flip.** D-08 adds it to `@cast_fields` for the *recovery clear* path, but the *start* path (D-09) must be a sibling `update_all` so it doesn't contend with `optimistic_lock(:lock_version)`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Step scheduling / durability across restarts | Custom GenServer timer / process state | Oban scheduled jobs (`schedule_in`) | Durable, survives restart, already a hard dep; webhook-re-fire independence (DUN-02) requires durability. |
| Dedup of duplicate emails | Custom "sent?" boolean column + SELECT-then-INSERT | Oban `unique` at enqueue + per-step cancel-guard | TOCTOU race in SELECT-then-INSERT; Oban unique is lane-independent and one coherent story. (CONTEXT D-08 rejected-alternatives.) |
| First-transition election under concurrency | Application-level lock / `SELECT FOR UPDATE` dance | `Repo.update_all` with `where: is_nil(...)` | Single atomic statement = exactly-one-winner; no lock held across the webhook path (<100ms p99 budget). |
| Config validation + docs | Hand-rolled `with`-chains | NimbleOptions `{:custom}` + boot raise | Ecosystem default; gives `NimbleOptions.docs/1` for free; two-layer precedent already in config.ex. |
| Bulk job cancellation | Iterating + `Oban.cancel_job` per row | `Oban.cancel_all_jobs/2` (Ecto queryable) | One statement, returns `{:ok, count}`, kills executing jobs. `[VERIFIED: deps/oban + hexdocs]` |
| ISO8601 scalar coercion for Oban args | Inline `DateTime.to_iso8601` scattered | `maybe_iso8601/1` precedent | Consistent nil-handling; `only_scalars!` already enforces the scalar contract. |
| Email template scaffolding | New email-rendering convention | Clone `card_expiring_soon.ex` (`@update_pm_url` CTA) / `invoice_payment_failed.ex` | `Mailglass.Mailable` + `Phoenix.Component` is the established convention; portal-CTA pattern already solved. |

**Key insight:** Every primitive this phase needs already exists in the codebase as a verified precedent. The phase is a composition of clones, not invention — which is exactly why the milestone assessment flagged Phases 128–130 as needing "no external research."

## Runtime State Inventory

> This is an additive-only phase (one nullable column + new code). Not a rename/refactor. Inventory included because it touches webhook-path state and Oban job state.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | NEW: `accrue_subscriptions.dunning_campaign_started_at` (nullable, forward-only). No existing data carries dunning-campaign state today (this is net-new). Existing `past_due_since` / `dunning_sweep_attempted_at` are UNCHANGED. | Forward-only nullable migration. No backfill needed — existing past_due subs simply have `nil` anchor until their next failure webbook (acceptable; they're already in Stripe's retry flow). |
| Live service config | Host Oban config must include `accrue_dunning: 2` queue — ALREADY documented (dunning_sweeper.ex:32, operator-runbooks.md:16). No NEW queue required. | None (reuses existing queue). Phase 130 wires the example host. |
| OS-registered state | None. | None. |
| Secrets/env vars | None new. Webhook signing secrets unchanged. | None. |
| Build artifacts | None — pure additive compilation. | None. |

**Nothing found requiring data migration of existing records** — verified: the anchor is net-new state with no historical equivalent to backfill.

## Common Pitfalls

### Pitfall 1: "Green suite hides a feature dead on the production path"

**What goes wrong:** The campaign passes every unit test but never actually fires because it's wired to a unit-level helper, not the real `invoice.payment_failed` webhook entry point.
**Why it happens:** This exact class was caught at code review in BOTH Phase 126 (CR-01) and Phase 127 (CR-01) and is flagged in STATE.md as a cross-phase graduation candidate.
**How to avoid:** Validation MUST exercise the real entry point — drive a webhook fixture through `DefaultHandler` (not just call `maybe_bump_past_due_since/2` directly) and assert a `DunningStep` job is enqueued. See Validation Architecture below.
**Warning signs:** All tests call private/internal functions; no test routes a webhook payload end-to-end.

### Pitfall 2: Double day-0 email (the additive footgun)

**What goes wrong:** Both the campaign step-1 AND the standalone `do_dispatch_invoice(:invoice_payment_failed, …)` fire → two day-0 emails. The disjoint keyspaces (D-15) DON'T dedup each other because they're different keys.
**Why it happens:** Treating immediate + campaign as additive instead of REPLACE.
**How to avoid:** D-15 — when campaign enabled, SKIP the standalone dispatch at default_handler.ex:1466-1467 (gate `do_dispatch_invoice`). One owner, one cancel surface.
**Warning signs:** A test with campaign enabled asserts two emails for one failure.

### Pitfall 3: Stale recovery cancels a fresh campaign

**What goes wrong:** Customer recovers (campaign A cancelled), then re-lapses (campaign B starts), then a late/out-of-order recovery webhook for A arrives and cancels B's in-flight steps.
**Why it happens:** Cancel query keyed only on `subscription_id`, not `campaign_started_at`.
**How to avoid:** D-12 — `Oban.cancel_all_jobs` query MUST match `campaign_started_at` (the anchor value AT recovery time), so it only cancels the campaign it belongs to. The per-step cancel-guard reloads LIVE state, so even if it fires it self-cancels only when the live anchor is nil/recovered.
**Warning signs:** Recovery cancel uses `fragment("? ->> 'subscription_id' = ?")` without the `campaign_started_at` clause.

### Pitfall 4: Step retries re-send the email

**What goes wrong:** A `DunningStep` job retries (transient Mailglass error) and sends the step email twice.
**Why it happens:** `max_attempts: 3` on the step worker means up to 3 attempts.
**How to avoid:** The heavy email-send retries live in the DOWNSTREAM Mailer job (`max_attempts: 5`), not the step worker — the step is light orchestration (D-10). The step worker's own `unique` with `:completed` in states (D-16) means a completed step can never be re-enqueued; within a single job's retries the email is one `Accrue.Mailer.deliver/2` call whose own dedup (D-17 optional / mailer enqueue) backstops a mid-retry double-send.
**Warning signs:** Heavy retry/backoff config on `DunningStep`; no `:completed` in the unique states.

### Pitfall 5: `period: :infinity` + finite-window confusion across Smart Retries

**What goes wrong:** A finite `period` (e.g. 60s) lets a week-2 Stripe Smart Retry redelivery re-send the failed-payment email.
**Why it happens:** Stripe Smart Retries span 1–4 weeks; a short uniqueness window expires between retries.
**How to avoid:** D-13/D-16 both use `period: :infinity` + `:completed` in states. A completed prior send permanently blocks a duplicate for the same `invoice_id` (immediate) or `[sub, step_key, started_at]` (campaign). `[CITED: docs.stripe.com/billing/revenue-recovery/smart-retries — retry cadence spans weeks]`
**Warning signs:** Any finite `period` on the dedup unique config.

## Code Examples

### Oban unique (installed-version documented example — verbatim match)

```elixir
# Source: deps/oban/lib/oban/job.ex:304-309 (Oban 2.22.1, installed)
fields = [:worker]
states = [:available, :scheduled, :executing, :retryable, :completed]
MyApp.Worker.new(%{id: 1}, unique: [fields: fields, period: 60, states: states])

# keys within args:  Source: deps/oban/lib/oban/job.ex:311-316
keys = [:account_id, :url]
MyApp.Worker.new(args, unique: [fields: [:args, :worker], keys: keys])
```

### Mailglass content-hash idempotency (the D-13 substrate — what Accrue does NOT control)

```elixir
# Source: /Users/jon/projects/mailglass/lib/mailglass/outbound.ex:1183-1197
defp compute_idempotency_key(%Message{} = msg) do
  # sha256 over tenant_id | inspect(mailable) | recipient | content_hash(text+html)
  # ⇒ Accrue's stamped :idempotency_key METADATA is NOT used here.
end

# Sync path (Accrue's lane): outbound.ex:688-728 persist_queued → Ecto.Multi.insert
# uses Delivery.changeset which has unique_constraint(:idempotency_key, ...) (delivery.ex:150)
# → a duplicate raises a CONSTRAINT ERROR (changeset), NOT a silent dedup. Oban retries it.
# Only deliver_many/2 (batch) uses on_conflict: :nothing (outbound.ex:560-564).
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single un-deduped `:invoice_payment_failed` email on every Stripe retry | Config-driven multi-step durable Oban campaign + Oban-`unique` dedup | Phase 128 (this) | Fixes the latent duplicate-send bug + adds the dunning depth wedge. |
| CLAUDE.md stack note: `oban ~> 2.21` | Installed `oban 2.22.1` | mix.lock current | `unique`/`cancel_all_jobs` semantics identical; no migration concern. CLAUDE.md note is stale but non-breaking. |
| Chained execution assumed available | Chained execution is **Oban Pro only** | (verified) | Step chain MUST be hand-rolled (each step enqueues the next) — exactly as decided. |

**Deprecated/outdated:**
- CLAUDE.md `oban ~> 2.21` reference — superseded by installed `2.22.1` (no action; semantics unchanged). Note for the planner: do not "correct" mix.lock to 2.21.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `invoice.paid` webhook path that should also trigger `maybe_finalize_dunning_campaign/2` (D-12) routes through a reducer that has the prior `row` available. `reduce_subscription` (default_handler.ex:722) clearly does (`maybe_emit_dunning_exhaustion(row, updated)`), but the invoice-side recovery hook for `invoice.paid` needs the planner to locate the subscription-status-change site on that path. | Architecture / D-12 | If `invoice.paid` doesn't carry a subscription transition, recovery relies solely on the `subscription.updated → active` path + per-step cancel-guard. The cancel-guard is a complete backstop, so worst case is a slightly-delayed cancel, not a wrong email. LOW risk. |

**Only one assumption.** Everything else was verified against live source, installed-dep source, or official docs.

## Open Questions (RESOLVED)

1. **Does `invoice.paid` produce a subscription-status transition the reducer observes, or only `customer.subscription.updated`?**
   - What we know: `reduce_subscription` (default_handler.ex:722) is the clean recovery-detection site with `(row, updated)` in hand. `maybe_dispatch_invoice_email("paid", …)` (default_handler.ex:1462) fires on `invoice.paid` but operates on the `%Invoice{}`, not a subscription transition pair.
   - What's unclear: whether D-12's "and on the `invoice.paid` path" wiring needs a subscription reload to compare prior status.
   - Recommendation: Plan recovery cancel on the `subscription.updated → active/paid` reducer path (D-12 primary) and treat the per-step cancel-guard (D-11) as the guaranteed backstop. If the planner wants belt-and-suspenders on `invoice.paid`, reload the linked subscription and run the same `maybe_finalize_dunning_campaign/2` logic. Either way correctness holds because the cancel-guard re-checks live state.
   - **RESOLVED (planning):** Adopted as recommended. **Plan 06** wires recovery cancel on the
     `subscription.updated → active/paid` reducer path as PRIMARY (`maybe_finalize_dunning_campaign/2`:
     in-transaction anchor-clear + post-commit `Oban.cancel_all_jobs` keyed on `campaign_started_at`),
     and **Plan 05** ships the per-step cancel-guard (`{:cancel, :recovered}` on nil-anchor / not-past_due)
     as the guaranteed backstop. The optional `invoice.paid` belt-and-suspenders wiring is NOT added in
     Phase 128 (cancel-guard fully backstops it); revisit only if a sourced need appears. No open item remains.

## Environment Availability

> Phase is pure Elixir code + one DB migration. No external runtime tools needed at plan/build time beyond the existing stack (PostgreSQL via TestRepo, Oban in `:manual` mode for tests). Chrome/Ghostscript are NOT exercised (the two new step emails carry no PDF — only `:invoice_finalized`/`:invoice_paid` attach PDFs per mailer.ex:161-163).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (TestRepo) | Migration + Ecto integration tests | ✓ (test_helper boots TestRepo + runs migrations) | PG 14+ | — |
| Oban (`:manual` testing) | Worker enqueue/perform tests | ✓ (test_helper starts Oban testing: :manual, queues: false) | 2.22.1 | — |
| `stream_data` | Property tests | ✓ | ~> 1.3 | — |
| Chrome/Ghostscript | NOT needed (no PDF on dunning step emails) | n/a | — | `Accrue.PDF.Test` adapter in tests anyway |

**No missing dependencies.**

## Validation Architecture

Nyquist validation is ENABLED (`config.json` → `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + ExUnitProperties (stream_data ~> 1.3) + Oban.Testing + Ecto.Adapters.SQL.Sandbox + Mox |
| Config file | `accrue/test/test_helper.exs` (boots TestRepo, runs migrations, starts Oban `testing: :manual`, defines Mox mocks) |
| Quick run command | `cd accrue && mix test test/accrue/dunning/campaign_test.exs --seed 0` (single new file) |
| Full suite command | `cd accrue && mix test --seed 0` (`--seed 0` dodges the known flaky PdfTest per MEMORY) |

### Phase Requirements → Test Map
| Req | Behavior to PROVE | Test Type | Automated Command | File |
|-----|-------------------|-----------|-------------------|------|
| DUN-01 | Config validator: strictly-increasing + unique `after_days`; unique `key`; `campaign: false` → `[enabled: false, steps: []]`; empty-steps-while-enabled = loud error; `last_step.after_days <= grace_days` raises at boot; `> grace_days` fails | property (stream_data) + unit | `mix test test/accrue/config_dunning_campaign_test.exs` | ❌ Wave 0 |
| DUN-01 | Default journey shipped on by default (`[0,5,12]`, correct templates/keys) | unit | same file | ❌ Wave 0 |
| DUN-02 | Pure `Accrue.Dunning.Campaign` resolver: `(steps, started_at, now) → next step + delay`; zero-decimal/ordering edge cases; deterministic | property (stream_data) | `mix test test/property/dunning_campaign_property_test.exs` | ❌ Wave 0 |
| DUN-02 | Real webhook path: `invoice.payment_failed` fixture through `DefaultHandler` enqueues day-0 `DunningStep` (Pitfall 1 — real entry point, not unit helper) | integration (Oban.Testing `assert_enqueued` + webhook fixture) | `mix test test/accrue/webhook/dunning_campaign_start_test.exs` | ❌ Wave 0 |
| DUN-02 | Step chain: `perform/1` delivers + enqueues next step with SAME `campaign_started_at`; final step enqueues nothing | integration (`perform_job`) | same file | ❌ Wave 0 |
| DUN-04 | `:invoice_payment_failed` once-per-invoice: duplicate enqueue returns `{:ok, %Job{conflict?: true}}`, no second job; across simulated week-2 redelivery (`period: :infinity` + `:completed`) | integration (Oban unique) | `mix test test/accrue/workers/mailer_idempotency_test.exs` | ❌ Wave 0 |
| DUN-04 | `idempotency_key/2` clause keys on `invoice_id`, errors `{:error, :missing_invoice_id}` on nil/empty | unit | same file | ❌ Wave 0 |
| DUN-04 | `dedup_unique/2` returns `false` for every non-`:invoice_payment_failed` type (no regression) | unit | same file | ❌ Wave 0 |
| DUN-05 | Race-safe first-transition guard: under N concurrent `update_all where is_nil(anchor)`, exactly ONE returns count==1 (winner), rest count==0 (no-op) | integration (concurrent Ecto + Sandbox) | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs` | ❌ Wave 0 |
| DUN-05 | Later failure webhook in same window does NOT restart/duplicate (anchor already set → count==0) | integration | same file | ❌ Wave 0 |
| DUN-05 | Cancel-on-recovery: leaving `past_due` → anchor nilled + `cancel_all_jobs` removes scheduled steps; keyed on `campaign_started_at` so a fresh re-lapse campaign survives a stale recovery | integration (Oban + webhook) | same file | ❌ Wave 0 |
| DUN-05 | Step cancel-guard: `perform/1` on a recovered sub (not past_due OR nil anchor) returns `{:cancel, :recovered}`, sends nothing | integration (`perform_job`) | same file | ❌ Wave 0 |
| DUN-05 | D-15 REPLACE: campaign enabled ⇒ standalone `:invoice_payment_failed` NOT dispatched (one day-0 email); disabled ⇒ standalone fires (deduped) | integration | `test/accrue/webhook/dunning_campaign_start_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the single new test file for that task (`mix test <file> --seed 0`)
- **Per wave merge:** `cd accrue && mix test --seed 0` (full suite)
- **Phase gate:** full suite green + `credo --strict` + dialyzer before `/gsd:verify-work`

### Pure-function property tests (stream_data) vs integration tests
- **Property (pure):** `Accrue.Dunning.Campaign` resolver (next-step + delay math, ordering, zero-elapsed/at-boundary edge cases); config validator's strictly-increasing/unique invariants over generated step lists.
- **Integration (Oban/Ecto):** everything touching the anchor column, `update_all` concurrency, Oban enqueue/`unique`/`conflict?`, `cancel_all_jobs`, and the real webhook entry path. These need TestRepo + Oban `:manual` + (for the race test) concurrent sandbox connections.

### Wave 0 Gaps
- [ ] `test/accrue/config_dunning_campaign_test.exs` — DUN-01 validation (intra-list + boot grace cross-field)
- [ ] `test/property/dunning_campaign_property_test.exs` — DUN-02 pure resolver properties (clone `test/property/connect_platform_fee_property_test.exs` structure)
- [ ] `test/accrue/webhook/dunning_campaign_start_test.exs` — DUN-02 real webhook path + D-15 REPLACE gate
- [ ] `test/accrue/webhook/dunning_campaign_keying_test.exs` — DUN-05 race-safe keying + cancel-on-recovery + cancel-guard
- [ ] `test/accrue/workers/mailer_idempotency_test.exs` — DUN-04 immediate dedup (Oban unique + `idempotency_key/2` clause + no-regression)
- [ ] Migration must be present in `priv/repo/migrations/` before integration tests (test_helper runs all migrations at boot)
- [ ] Framework install: none — full infra already in `test_helper.exs`

*(Concurrency note for the DUN-05 race test: use multiple sandbox-checked-out connections or `Ecto.Adapters.SQL.Sandbox` shared mode + `Task.async_stream` to simulate concurrent `update_all`; existing tests use `async: false` + shared sandbox.)*

## Security Domain

> `security_enforcement` is not explicitly disabled in config.json → treat as enabled. This phase has a narrow security surface (no new auth/session/crypto; all I/O is internal webhook→DB→email).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface added. |
| V3 Session Management | no | No sessions. |
| V4 Access Control | no | Internal worker/reducer path; no user-facing access decision. |
| V5 Input Validation | yes | Config validated via NimbleOptions `{:custom}` + boot raise (D-06). Oban args validated by `only_scalars!/1` (mailer/default.ex). Webhook payloads already validated upstream (signature verification mandatory, unchanged). |
| V6 Cryptography | no | No new crypto. Webhook signature verification (existing) untouched. |
| V7 Error Handling / Logging | yes | Sensitive Stripe fields never logged (CLAUDE.md constraint). New code logs `subscription_id`/`step_key`/`invoice_id` only — all non-PII references, consistent with existing `dunning.terminal_action_requested` event data. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom-table exhaustion from DB/webhook-sourced strings | Denial of Service | `step_key` comes from HOST config (trusted, compile-time-ish), not webhook input. When converting the ISO8601 `campaign_started_at` arg back, parse to DateTime (no `String.to_atom`). Mailer already uses `String.to_existing_atom` for type. |
| PII in Oban `args` (JSONB persisted to `oban_jobs`) | Information Disclosure | `only_scalars!/1` enforces ID-not-struct; pass `subscription_id`/`invoice_id`/`step_key`/`campaign_started_at` (all references), never customer email/struct. (mailer/default.ex moduledoc.) |
| Webhook replay → duplicate side effects | Tampering | Dispatch-layer dedup short-circuits replays before the reducer (existing); D-09 anchor + D-13/D-16 Oban unique make double-start/double-send structurally impossible at the campaign layer. |
| Performance regression on webhook hot path (<100ms p99) | DoS-adjacent SLO | D-09's single `update_all` is one indexed-by-PK statement (no held lock, no extra round-trips); campaign enqueue is async (Oban insert). No synchronous email send on the webhook path. |

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/mailglass/lib/mailglass/outbound.ex` — `compute_idempotency_key/1` (:1183), sync `persist_queued`→`Ecto.Multi.insert` (:688), batch `on_conflict: :nothing` (:560). D-13 substrate confirmed.
- `/Users/jon/projects/mailglass/lib/mailglass/outbound/delivery.ex` + `priv/repo/migrations/...add_idempotency_key...` — partial unique index on Mailglass's OWN content-hash key (`WHERE idempotency_key IS NOT NULL`), used via `unique_constraint/2` on the sync path.
- `accrue/deps/oban/lib/oban/job.ex:236,304-322,31-66` (Oban **2.22.1**, installed) — `unique` fields/keys/period/states; documented example matches CONTEXT verbatim at :307; valid states incl `:completed`.
- `accrue/mix.lock:36,51` — mailglass `1.0.0`, oban `2.22.1`.
- `accrue/lib/accrue/config.ex:228` (dunning schema), `:771,784` (accessors), `:947,958,968` (boot validators), `:1046` (validate_descending) — all anchors confirmed (drift documented).
- `accrue/lib/accrue/webhook/default_handler.ex:722,736,758` (reduce_subscription + maybe_emit_dunning_exhaustion), `:955,969,989` (maybe_bump_past_due_since), `:1458,1466,1472,1486,1551` (do_dispatch_invoice + safe_deliver) — confirmed.
- `accrue/lib/accrue/billing/subscription.ex:55-97` (fields, `@cast_fields`, `force_status_changeset`), `:148-256` (lifecycle predicates) — confirmed; `dunning_campaign_active?/1` is net-new beside these.
- `accrue/lib/accrue/workers/mailer.ex:106-121` (deliver lanes + `{:cancel, reason}`), `:292-314` (`idempotency_key/2` family — NO `:invoice_payment_failed` clause today; catch-all returns `{:error, :unsupported_type}`), `:319-332` (`default_template/1`). Confirmed.
- `accrue/lib/accrue/mailer/default.ex:33` (`deliver/2` → `Oban.insert`, no unique today), `:48-79` (`only_scalars!`). Confirmed.
- `accrue/lib/accrue/billing/metered_renewal_actions.ex:307,312` (unique worker + maybe_iso8601). Confirmed.
- `accrue/lib/accrue/jobs/dunning_sweeper.ex:32,46,101` (queue config, worker `use`, `Accrue.Clock.utc_now/0`). Confirmed.
- `accrue/lib/accrue/emails/card_expiring_soon.ex` + `invoice_payment_failed.ex` — template clone targets + the `@update_pm_url`/`hosted_invoice_url` CTA patterns. Confirmed.
- `accrue/lib/accrue/errors.ex:112` (`Accrue.ConfigError`), `accrue/lib/accrue/clock.ex:26` (`utc_now/0`). Confirmed.
- `accrue/test/test_helper.exs` — Oban `testing: :manual`, TestRepo + migrations, Mox, sandbox. `accrue/test/property/*.exs` — stream_data property-test convention.

### Secondary (MEDIUM confidence)
- `https://hexdocs.pm/oban/Oban.html` — `cancel_all_jobs/2` signature `{:ok, count}`, kills executing jobs (with the "already-completing job stays completed" caveat → why per-step cancel-guard is needed).
- `https://hexdocs.pm/oban/unique_jobs.html` — `{:ok, %Job{conflict?: true}}` return; default state group `:successful`; OSS unique is advisory/race-prone (Pro Smart Engine uses DB constraints) → confirms D-09 `update_all` as primary guard.
- `https://hexdocs.pm/oban/Oban.Job.html` — unique option enumeration.

### Tertiary (LOW confidence)
- `https://docs.stripe.com/billing/revenue-recovery/smart-retries` (referenced for retry cadence spanning weeks → motivates `period: :infinity`). Not re-fetched this session; the timing claim is uncontested and used only to justify an already-locked decision.

## Metadata

**Confidence breakdown:**
- D-13 Mailglass dedup substrate: HIGH — read the source directly; the sync-path-no-on-conflict + content-hash-not-metadata facts are unambiguous.
- Oban 2.22.1 semantics: HIGH — verified against the INSTALLED dep source (not just docs); CONTEXT config matches the dep's own example verbatim.
- File:line anchors: HIGH — every anchor located in live source; drift documented and small.
- Architecture / decisions: HIGH — verification pass on locked decisions; all internally consistent with verified code.
- Validation architecture: HIGH — test infra fully present; gap list is concrete.
- Open question A1 (`invoice.paid` recovery wiring): MEDIUM — backstopped by cancel-guard regardless.

**Research date:** 2026-05-24
**Valid until:** 2026-06-23 (30 days — stable internal codebase; the only churn risk is an Oban minor bump, which would not change `unique`/`cancel_all_jobs` semantics).
