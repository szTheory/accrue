# Phase 128: Campaign Engine Foundation + Idempotency Must-Fix - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

> **How these decisions were made:** Per the project's standing cohesive-one-shot-synthesis
> posture (`.planning/config.json` → `discuss_high_impact_confirm_bar`; memory
> `feedback_decision_synthesis_style`), four parallel `gsd-advisor-researcher` agents researched
> the four coupled gray areas (default journey design · config DSL + validation · campaign
> lifecycle/keying · idempotency must-fix + step uniqueness) against idiomatic
> Elixir/Phoenix/Oban/Ecto practice, the `lattice_stripe/prompts/` corpus, `.planning/research/`,
> the pre-resolved milestone thread, peer libs (Pay, Laravel Cashier, Chargebee, Recurly, Stripe
> Smart Retries), and the live `accrue/` codebase. Every fork was judged **additive-safe /
> reversible** (config is host-overridable; idempotency keys are `accrue:v1:`-versioned; the
> anchor is a nullable column not a public API; no new table) — so everything below is **locked
> and decided**, none surfaced as an irreversible/published-commitment fork. All load-bearing
> code claims were re-verified against the repo. Build on this; do not re-derive.

<domain>
## Phase Boundary

**DUN-01, DUN-02, DUN-04, DUN-05 only.** Replace today's single un-deduped `:invoice_payment_failed`
email with a first-party, durable, **config-driven multi-step Oban dunning campaign** that:
- schedules each step from local `past_due_since` / first-transition state (independent of when/whether
  the processor re-fires webhooks),
- emails through the existing Mailglass mailer on a host-defined cadence shipped **on by default
  (opt-out)**,
- **never double-sends** (the `:invoice_payment_failed` idempotency must-fix + per-step Oban
  uniqueness),
- **cancels the instant payment recovers** (subscription leaves `past_due`), keyed to the **FIRST**
  nil→`past_due` transition so later failure webhooks in the same window cannot restart/orphan/
  duplicate an in-flight campaign.

**In scope:** the `Accrue.Dunning.Campaign` pure step-resolver; `Accrue.Workers.DunningStep` (chained,
cancel-guarded, Oban-unique); the nested `campaign:` config under the existing `:dunning` key
(NimbleOptions-validated, default journey shipped on); the `last_step.after_days <= grace_days` boot
validation; the `:invoice_payment_failed` idempotency must-fix; a single nullable anchor column on
`accrue_subscriptions`; campaign start at the first transition + "already-running" guard; cancel-on-
recovery wiring; two new Mailglass step templates.

**Out of scope (explicitly later phases — do NOT pull forward):**
- **Ledger events** (`dunning.campaign_started`/`step_sent`/`recovered`/`exhausted`) **and the
  `[:accrue, :dunning, *]` telemetry family + recovered-vs-lost counter → DUN-08, Phase 129.**
  Phase 128 builds the engine; Phase 129 layers observability on top. Build the engine so the events
  drop in cleanly, but do **not** ship the ledger/telemetry surface here.
- Customer portal recovery banner + admin dunning-state view → DUN-06/DUN-07, **Phase 129**.
- Provider-honest docs + drift gate + Fake-lane merge gate + example-host wiring → DUN-09/DUN-10,
  **Phase 130**.
- `Accrue.Dunning.Engine` behaviour + Chimeway adapter → DUN-03, **Phase 131**. (Design the engine so
  a behaviour seam is a clean later extraction, but do not introduce the behaviour here.)

</domain>

<decisions>
## Implementation Decisions

### A. Default dunning journey (DUN-01 — product/DX) — shipped ON by default
- **D-01 — Three escalating steps, absolute day offsets `[0, 5, 12]`.** Default `@default_dunning_steps`:
  | # | `key` | `after_days` | `template` | Copy intent |
  |---|-------|-------------|-----------|-------------|
  | 1 | `:reminder` | `0` | `Accrue.Emails.InvoicePaymentFailed` (**REUSE existing**) | Neutral: "your payment didn't go through — pay now to stay current." |
  | 2 | `:action_required` | `5` | `Accrue.Emails.DunningActionRequired` (**NEW**) | Firmer: "still failing — update your card to avoid losing access," name the consequence + approx cutoff date. |
  | 3 | `:final_notice` | `12` | `Accrue.Emails.DunningFinalNotice` (**NEW**) | Urgent/last-chance: "final notice — subscription will be `[terminal_action]` on `[date]` unless payment succeeds." |
  - `12 ≤ grace_days (14)` satisfies the locked boot validation and leaves a **2-day cushion** before
    `DunningSweeper` moves the sub to `:unpaid`. Offsets are a config default → **tunable in any future
    minor without a breaking change**; they are not a fork.
  - **Every step's primary CTA deep-links to the portal update-payment-method flow**
    (`accrue_portal/.../add_payment_method_live.ex` — highest-converting recovery action). Resolve the
    URL the way `accrue/lib/accrue/emails/card_expiring_soon.ex` already does (`@update_pm_url`).
- **D-02 — New email module names are the one published-API commitment (locked now):**
  `Accrue.Emails.DunningActionRequired` (template atom `:dunning_action_required`) and
  `Accrue.Emails.DunningFinalNotice` (`:dunning_final_notice`). Follow the existing
  `Mailglass.Mailable` + `Phoenix.Component` convention (subject/message/render/render_text/
  `put_function`), reuse `Mailglass.Components.Layout.email_layout` + the invoice footer. Add both atoms
  to `Accrue.Workers.Mailer.default_template/1`.
- **D-03 — Opt-out posture + over-email warning.** Ship `enabled: true` (a real default journey, not
  empty). Hosts disable via `dunning: [campaign: [enabled: false]]` (or `campaign: false` shorthand, or
  the umbrella `dunning: [mode: :disabled]`). For hosts who also run **Stripe Dashboard dunning emails**,
  ship a doc-warning recommending they disable one side (full provider-native coordination is deferred);
  the deliberately-sparse 0/5/12 spacing limits collision damage. (Doc itself is Phase 130; the posture
  is decided here.)

### B. Campaign config DSL + validation (DUN-01 — public config API)
- **D-04 — Shape: explicit `enabled:` + ordered absolute-day step list, nested under the existing
  `:dunning` key.** Give the existing `dunning:` entry (`accrue/lib/accrue/config.ex:228`) an explicit
  `:keys` list (typing `mode`/`grace_days`/`terminal_action`/`telemetry_prefix`) and add `campaign:`:
  ```elixir
  campaign: [
    type: {:custom, __MODULE__, :validate_dunning_campaign, []},
    default: [enabled: true, steps: @default_dunning_steps],
    doc: "Multi-step dunning email cadence fired off the first past_due transition. " <>
         "`enabled: false` disables the journey (Stripe/grace overlay still runs). " <>
         "`steps` is an ordered list of `[after_days:, key:, template:]`; `after_days` is " <>
         "ABSOLUTE from campaign start, strictly increasing, unique; the last step's " <>
         "after_days must be <= grace_days."
  ]
  ```
  Step keyword shape: **`[after_days: <non_neg_int>, key: <atom>, template: <module>]`** — all three
  required. `after_days` is **absolute from campaign start** (required so the `<= grace_days` check is
  meaningful and `schedule_in` is a pure function of `after_days[N] − elapsed`). `key` is **required and
  load-bearing** (it becomes the `step_key` Oban-unique arg + the future ledger label + admin display;
  a positional index would break uniqueness on reorder).
- **D-05 — Off-switch:** the custom validator normalizes `campaign: false` → `[enabled: false, steps: []]`;
  `steps: []` while `enabled: true` is a **loud error** (avoids silent-disable). Default ON via schema
  default + accessor.
- **D-06 — Validation (two layers, mirroring existing precedents):**
  - **Intra-list** in the per-field `{:custom, ...}` validator `validate_dunning_campaign/1` (clone the
    `validate_descending/1` precedent): each step validated against a private `@step_schema`; `after_days`
    **strictly increasing + unique**; `key` **unique**; non-empty when enabled.
  - **Cross-field** `last_step.after_days <= grace_days` is genuinely cross-key (campaign vs sibling
    `grace_days`) and NimbleOptions cannot cross-validate — so a hand-written boot validator
    `validate_dunning_campaign_grace!/1` raises `Accrue.ConfigError` from `maybe_validate_boot_setup!/1`
    (config.ex ~:947), **directly after `validate_entitlements_price_ids!/1`** (the established cross-field
    precedent at config.ex ~:958, whose comment already documents *why* cross-field can't be `{:custom}`).
    Fails **loudly at boot**, never silently mis-fires.
- **D-07 — Accessors (raw-read + own nested default, mirroring `past_due_grace/0` at config.ex ~:784):**
  `dunning_campaign/0`, `dunning_campaign_enabled?/0`, `dunning_campaign_steps/0` (steps return `[]` when
  disabled). Namespaced `dunning_campaign*`, not bare `campaign/0`. Module attrs `@step_schema` (private
  per-step NimbleOptions schema) + `@default_dunning_steps` (the D-01 cadence) at the top of
  `Accrue.Config`.

### C. Campaign lifecycle, keying & where identity lives (DUN-02, DUN-05 — correctness)
- **D-08 — Anchor = a single nullable column `dunning_campaign_started_at :utc_datetime_usec` on
  `accrue_subscriptions`.** This is a **column add, NOT a new table** — it honors the locked "no new
  table" stance and directly mirrors the **existing sibling timestamp `dunning_sweep_attempted_at`**
  (subscription.ex:65, in the `force_status_changeset` cast list at :91). Rejected alternatives:
  derive-from-`past_due_since` (drifts — bumped every failure → violates the first-transition pin);
  Oban-meta-only (SELECT-then-INSERT TOCTOU race + correctness coupled to job retention/pruning);
  `accrue_events`-anchor (append-only can't be nilled; liveness-by-fold is awkward on a hot guard path).
  Add `field(:dunning_campaign_started_at, :utc_datetime_usec)`, add to `@cast_fields` + the
  `force_status_changeset` cast list, and add predicate `Subscription.dunning_campaign_active?/1`
  (`not is_nil(...)`) beside the existing lifecycle predicates. **Forward-only migration**, nullable, no
  index required for correctness (optional partial index `WHERE dunning_campaign_started_at IS NOT NULL`
  only if admin "active campaigns" queries later warrant it — Phase 129's call).
- **D-09 — Transition detection + race-safe "already-running" guard live in
  `maybe_bump_past_due_since/2`** (`accrue/lib/accrue/webhook/default_handler.ex:969` — already the single
  site that fires on `invoice.payment_failed` with the `%Subscription{}` in hand). Keep the existing
  `past_due_since` bump unchanged (sweeper still measures grace from Stripe's latest retry). The first
  nil→`past_due` edge = **the anchor column is currently `nil`** (NOT `status`, which may already be
  `past_due` from a prior failure; NOT `past_due_since`, which is re-bumped). Elect exactly one winner
  with a single atomic conditional update:
  ```elixir
  {count, _} =
    from(s in Subscription, where: s.id == ^sub.id and is_nil(s.dunning_campaign_started_at))
    |> Repo.update_all(set: [dunning_campaign_started_at: now_usec])
  ```
  `count == 1` ⇒ this webhook won the edge → enqueue the first `DunningStep` (day-0). `count == 0` ⇒
  campaign already running → **no-op** (in-flight chain untouched; the `past_due_since` bump still
  happened). Run as a sibling statement to the `force_status_changeset`/`optimistic_lock` path (it sets a
  single column, does not touch `lock_version`). The `DunningStep` Oban-unique keys are a second backstop
  against a double first-step enqueue.
- **D-10 — Worker `Accrue.Workers.DunningStep`**, `use Oban.Worker, queue: :accrue_dunning,
  max_attempts: 3` (**reuse** the existing `:accrue_dunning` queue — already configured `accrue_dunning: 2`
  in dunning_sweeper.ex:32 and documented in operator-runbooks.md:16; `max_attempts: 3` matches the
  sweeper worker — the heavy email-send retries live in the downstream Mailer job, so the step is light
  orchestration). `campaign_started_at` is carried in `args` as an **ISO8601 string** (Oban args are JSON
  + `only_scalars!` forbids structs — use the `maybe_iso8601/1` precedent at
  metered_renewal_actions.ex:312).
- **D-11 — Step chaining + cancel-guard.** `DunningStep.perform/1`: **(1) cancel-guard FIRST** — reload the
  row; if not past_due OR `is_nil(dunning_campaign_started_at)` → `{:cancel, :recovered}`, deliver nothing
  (matches the Mailer worker `{:cancel, reason}` convention at mailer.ex:108). **(2)** deliver the step
  email via `Accrue.Mailer.deliver/2` (reuses the mailer pipeline/lanes). **(3)** resolve the next step via
  `Accrue.Dunning.Campaign` and, if any, enqueue it with the **same** `campaign_started_at` arg +
  `schedule_in: next_delay`. The anchor threads through verbatim, so the chain shares one identity.
  *(Note: the `dunning.step_sent` ledger event + telemetry that would also live here are Phase 129 — do
  not emit them in 128.)*
- **D-12 — Cancel-on-recovery (belt-and-suspenders).** Recovery is detected at the existing transition
  hook: add `maybe_finalize_dunning_campaign/2` **beside `maybe_emit_dunning_exhaustion/2`** in the
  subscription reducer (default_handler.ex:736/758) and on the `invoice.paid` path. When the row **was**
  past_due with a non-nil anchor and the new state is active/paid, in one transaction: (a) nil the anchor
  (`force_status_changeset(%{dunning_campaign_started_at: nil})`), (b) **proactively** cancel scheduled
  steps:
  ```elixir
  from(j in Oban.Job,
    where: j.worker == "Accrue.Workers.DunningStep",
    where: fragment("? ->> 'subscription_id' = ?", j.args, ^sub.id),
    where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor))
  |> Oban.cancel_all_jobs()
  ```
  The per-step cancel-guard (D-11) is the **backstop** for any job that slips between the cancel query and
  execution or an out-of-order recovery webhook → it re-checks live state and self-cancels with no email.
  Match the cancel key on `campaign_started_at` so a **new** campaign from a later re-lapse is never
  cancelled by a stale recovery. *(The `dunning.recovered` ledger event is Phase 129.)*

### D. Idempotency must-fix + step uniqueness (DUN-04, DUN-05 — correctness)
- **D-13 — Primary dedup = Oban `unique` at ENQUEUE, lane-independent.** Advisor research **corrected the
  prep-thread premise**: Mailglass does **not** dedup on the stamped `:idempotency_key` metadata — its
  `compute_idempotency_key/1` content-hashes and inserts with a plain (non-`on_conflict`) insert, so a
  duplicate raises a constraint error that Oban then *retries*; and the Swoosh lane applies no key at all.
  ⚠ **Planner: re-confirm this against `/Users/jon/projects/mailglass/lib/mailglass/outbound.ex` before
  relying on it.** Either way the only clean, lane-independent dedup is **Oban `unique` at enqueue**, which
  also matches the campaign-step mechanism for one coherent story. Add a derived `unique` to
  `Accrue.Mailer.Default.deliver/2` (`accrue/lib/accrue/mailer/default.ex:33`), **mapping only
  `:invoice_payment_failed`** (return `false`/no-unique for every other type → **no regression, no scope
  creep** into receipt/etc. dedup):
  ```elixir
  defp dedup_unique(:invoice_payment_failed, %{invoice_id: id}) when is_binary(id) and id != "",
    do: [fields: [:worker, :args], keys: [:type, :invoice_id], period: :infinity,
         states: [:available, :scheduled, :executing, :retryable, :completed]]
  defp dedup_unique(_type, _assigns), do: false
  ```
  `period: :infinity` (Stripe Smart Retries span 1–4 weeks — a finite 60s window would let a week-2 retry
  re-send); `keys` includes `:type` (so a `:receipt` and an `:invoice_payment_failed` sharing an id can't
  collide); `:completed` included (a completed prior send still blocks a duplicate); exclude
  `:cancelled`/`:discarded` (a cancelled send should be re-sendable). A duplicate enqueue returns
  `{:ok, %Job{conflict?: true}}` — silent, no retry storm, no cancel of legit sends.
- **D-14 — Backstop = a new `idempotency_key/2` clause** in `Accrue.Workers.Mailer` (before the catch-all
  at mailer.ex:314), keyed on **`invoice_id`** (always present after `drop_nils` — it is `invoice.id`;
  `invoice_number` is nullable and gets dropped, so keying on it would cause collisions/cancels):
  ```elixir
  defp idempotency_key(:invoice_payment_failed, assigns) do
    case assigns[:invoice_id] || assigns["invoice_id"] do
      nil -> {:error, :missing_invoice_id}
      ""  -> {:error, :missing_invoice_id}
      invoice_id -> "accrue:v1:invoice_payment_failed:#{invoice_id}"
    end
  end
  ```
  Granularity = **once per invoice** (≥1 immediate email across all Smart-Retry redeliveries of the same
  invoice) — exactly the must-fix intent.
- **D-15 — Immediate ↔ campaign relationship = REPLACE (campaign owns day-0), gated by the enabled flag.**
  When the campaign is **enabled** (default), the campaign's step-1 (`after_days: 0`, reusing
  `InvoicePaymentFailed`) **is** the failed-payment email — **skip** the standalone
  `do_dispatch_invoice(:invoice_payment_failed, …)` (default_handler.ex:1466) and let campaign-start own
  it. When the campaign is **disabled**, the standalone email fires (now deduped by D-13/D-14 — so the
  must-fix lands for non-campaign hosts too). Rationale: keeping both = the double-email footgun the thread
  flags; the two keyspaces are intentionally **disjoint and never collide** (immediate =
  `accrue:v1:invoice_payment_failed:<invoice_id>`; campaign step = Oban-unique on
  `[:subscription_id, :step_key, :campaign_started_at]`), but additive would still produce two day-0
  emails because different keys don't dedup each other. Replace gives one owner + one cancel surface.
- **D-16 — Campaign-step `unique` (the `DunningStep` worker):**
  ```elixir
  unique: [fields: [:worker, :args],
           keys: [:subscription_id, :step_key, :campaign_started_at],
           period: :infinity,
           states: [:available, :scheduled, :executing, :retryable, :completed]]
  ```
  `period: :infinity` + `:completed` ⇒ a given step **can never send twice** across retries/redeliveries/
  duplicate webhooks; including `campaign_started_at` in keys ⇒ a **new** past-due window (new anchor) is
  correctly a new campaign whose steps may run again. Exclude `:cancelled`/`:discarded` so a recovered-
  then-relapsed customer's cancelled steps don't block a fresh campaign.
- **D-17 — Step-email dedup identity.** Dunning step emails carry `subscription_id` + `step_key` +
  `campaign_started_at` in assigns; the step worker's own `unique` (D-16) guarantees once-per-step at the
  orchestration layer. For defense-in-depth against a mid-retry double-send, the new step email types may
  also get `idempotency_key/2` clauses keyed `accrue:v1:dunning_step:<subscription_id>:<step_key>:<campaign_started_at>`
  — **planner's discretion** on exact clause structure (the step-worker unique already satisfies DUN-05's
  "a step cannot send twice").

### Claude's Discretion (planner decides)
- Exact module placement for `Accrue.Dunning.Campaign` (pure step-resolver) vs. inlining resolution in the
  worker — keep it pure/property-testable either way (zero-decimal/ordering edge cases) and engine-seam-
  ready for Phase 131.
- Whether step emails also receive `idempotency_key/2` backstop clauses (D-17) or rely solely on the
  step-worker `unique` (D-16).
- Exact migration timestamp/name; exact `now_usec` clock call (use `Accrue.Clock.utc_now/0` for Fake-lane
  determinism in Phase 130).
- Whether `do_dispatch_invoice` gating (D-15) reads `Accrue.Config.dunning_campaign_enabled?/0` inline or
  via a small helper.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase research & milestone context (read first)
- `.planning/threads/dunning-depth-milestone-prep.md` — the pre-resolved milestone research (verified
  baseline, Chimeway-optional verdict, idiomatic Oban-campaign architecture sketch, comparator
  steal/avoid, "done enough" checklist, the 5 open questions). **Authoritative** — but note this CONTEXT
  *corrects* its premise that Mailglass dedups on metadata (see D-13).
- `.planning/ROADMAP.md` — Phase 128 goal + SC#1–4 + the three carried-forward open questions (now
  resolved as D-08/D-09 first-transition pin, D-06 grace validation, D-13/D-16 idempotency) + the
  phase-boundary split (ledger/telemetry = Phase 129).
- `.planning/REQUIREMENTS.md` — DUN-01, DUN-02, DUN-04, DUN-05 (this phase); DUN-06..10 + DUN-03 +
  PROOF-03 (later phases — the out-of-scope boundary).

### Project research (binding inputs)
- `.planning/research/ARCHITECTURE.md` — webhook pipeline + resolver seam shape.
- `.planning/research/PITFALLS.md` — dunning/idempotency stances.
- `.planning/research/FEATURES.md` — dunning feature framing.
- `.planning/seeds/SEED-002-ecosystem-integrations.md` — Chimeway/Mailglass framing (#1) — **Phase 131
  cross-reference only**, not this phase.

### Idiomatic / DX deep-research corpus (sibling `lattice_stripe/prompts/`)
- `/Users/jon/projects/lattice_stripe/prompts/payments_domain_field_guide.md` — § "The dunning flow".
- `/Users/jon/projects/lattice_stripe/prompts/elixir-best-practices-deep-research.md`,
  `.../elixir-opensource-libs-best-practices-deep-research.md` — config/DX + Oban idioms.

### Accrue code to extend (full relative paths)
- `accrue/lib/accrue/config.ex` — `dunning:` schema (:228), enum/validator precedents
  (`unmapped_action`:390, `validate_descending`, `validate_entitlements_price_ids!`:958,
  `maybe_validate_boot_setup!`:947), accessor pattern (`past_due_grace/0` ~:784).
- `accrue/lib/accrue/webhook/default_handler.ex` — `maybe_bump_past_due_since/2`:969,
  `maybe_emit_dunning_exhaustion/2`:736/758, `do_dispatch_invoice`:1466, `maybe_dispatch_invoice_email`.
- `accrue/lib/accrue/billing/subscription.ex` — `dunning_sweep_attempted_at`:65 + `past_due_since`:64
  (column precedent), `force_status_changeset`/`@cast_fields`:91, lifecycle predicates.
- `accrue/lib/accrue/workers/mailer.ex` — `idempotency_key/2` family :292–314,
  `deliver_mailglass`/`deliver_swoosh` :95–125, `default_template/1` :325, `{:cancel, reason}` :108.
- `accrue/lib/accrue/mailer/default.ex` — `deliver/2`:33 (`Oban.insert`, `only_scalars!`).
- `accrue/lib/accrue/billing/metered_renewal_actions.ex` — `unique:` worker precedent :307,
  `maybe_iso8601/1` :312.
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` — `:accrue_dunning` queue :32/:46, `Accrue.Clock.utc_now/0`
  :101 (Fake-lane determinism), the grace→terminal sweeper the cadence must precede.
- `accrue/lib/accrue/billing/dunning.ex` — `compute_terminal_action/2` (grace coherence).
- `accrue/lib/accrue/emails/invoice_payment_failed.ex` (reused step-1 template) +
  `accrue/lib/accrue/emails/card_expiring_soon.ex` (the `@update_pm_url` portal-CTA precedent for the new
  templates).
- `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` — the recovery CTA target.
- `/Users/jon/projects/mailglass/lib/mailglass/outbound.ex` — `compute_idempotency_key/1` + sync insert
  (the dedup-substrate correction behind D-13 — re-confirm).

### External (verify-before-coding)
- Oban `unique` keys/period/states + `cancel_all_jobs/2`: https://hexdocs.pm/oban/Oban.Job.html ·
  https://hexdocs.pm/oban/unique_jobs.html — **installed Oban is 2.22.1** (mix.lock:51), NOT the 2.21 in
  CLAUDE.md/the thread; `unique` semantics are identical. Chained execution is Oban **Pro** → the step
  chain is hand-rolled (matches the architecture sketch).
- Stripe Smart Retries (cadence coexistence + the over-email warning): https://docs.stripe.com/billing/revenue-recovery/smart-retries

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (clone, don't reinvent)
- **Column precedent:** `dunning_sweep_attempted_at :utc_datetime_usec` (subscription.ex:65) — the exact
  template for the new `dunning_campaign_started_at` nullable anchor (D-08).
- **Oban queue:** `:accrue_dunning` already configured (`accrue_dunning: 2`, dunning_sweeper.ex:32) and
  documented (operator-runbooks.md:16) — reuse for `DunningStep` (D-10).
- **`unique` worker precedent:** metered_renewal_actions.ex:307 (`unique: [fields: [:worker, :args],
  keys: [...], period: ...]`) + `maybe_iso8601/1` :312 (scalar-safe datetime args).
- **Config validators:** `validate_descending/1` (per-field `{:custom,...}`) +
  `validate_entitlements_price_ids!/1` (hand-written cross-field at boot, config.ex:958) — the two-layer
  validation model for D-06; `past_due_grace/0` (config.ex:784) raw-read+own-default accessor for D-07.
- **Transition hook:** `maybe_emit_dunning_exhaustion/2` (default_handler.ex:758) already observes the
  prior→new `past_due` transition — `maybe_finalize_dunning_campaign/2` (D-12) is its sibling.
- **Mailer dedup primitives:** `idempotency_key/2` family + `{:cancel, reason}` lane behavior
  (mailer.ex:108/292) + `Oban.insert` enqueue point (mailer/default.ex:33).
- **Email template convention:** `card_expiring_soon.ex` (the `@update_pm_url` portal-CTA pattern) +
  `invoice_payment_failed.ex` (reused step 1) — clone for the two new step templates (D-02).

### Established Patterns (constrain this phase)
- **`force_status_changeset` + `optimistic_lock(:lock_version)`** on Subscription — the anchor set/clear
  run as a sibling `update_all` (D-09) so they don't fight the lock.
- **`only_scalars!/1`** Oban-args safety (mailer/default.ex) — `campaign_started_at` MUST be an ISO8601
  string, not a `DateTime` (D-10).
- **`Accrue.Clock.utc_now/0`** (dunning_sweeper.ex:101) — use for the anchor timestamp so Phase 130's
  Fake-lane clock-advance proof is deterministic.
- **No-new-table / reuse-existing** stance — honored: one nullable column + Oban + (Phase-129) the
  existing `accrue_events`.

### Integration Points
- Webhook ingress is **unchanged** (type-agnostic plug → ingest → DispatchWorker → DefaultHandler). New
  code: the `campaign:` config + validators + accessors; the anchor column + migration; the start-guard in
  `maybe_bump_past_due_since/2`; `Accrue.Dunning.Campaign` + `Accrue.Workers.DunningStep`; the
  cancel-on-recovery hook; the `:invoice_payment_failed` dedup (enqueue-unique + key clause); the
  `do_dispatch_invoice` enabled-gate (D-15); two new email templates.
- **Engine-seam readiness (Phase 131):** keep `Accrue.Dunning.Campaign` pure and the worker's
  step-resolution swappable so a later `Accrue.Dunning.Engine` behaviour is a clean extraction — but do
  NOT introduce the behaviour here.

</code_context>

<specifics>
## Specific Ideas

- **One coherent "every dunning email is deduped" story:** Oban `unique` at enqueue is the single primary
  mechanism for both the standalone `:invoice_payment_failed` (keyed `[:type, :invoice_id]`) and each
  campaign step (keyed `[:subscription_id, :step_key, :campaign_started_at]`); the `idempotency_key/2`
  clauses are versioned (`accrue:v1:`) backstops. Disjoint keyspaces by construction.
- **Cancel closed twice:** proactive `Oban.cancel_all_jobs` on recovery + a per-step live-state cancel-guard
  backstop — the "card fixed → journey keeps emailing" footgun (Pay/Cashier/Chargebee) is structurally
  impossible.
- **The anchor column is the edge signal, not `status`/`past_due_since`:** because `past_due_since` is
  re-bumped on every failure and `status` may already be `past_due`, only `is_nil(dunning_campaign_started_at)`
  reliably identifies the FIRST transition (the locked open-question #4 resolution).

</specifics>

<deferred>
## Deferred Ideas

- **Dunning ledger events + `[:accrue, :dunning, *]` telemetry + recovered-vs-lost counter** — DUN-08,
  **Phase 129** (build the engine so they drop in; do not emit in 128).
- **Customer portal recovery banner + read-only admin dunning-state view** — DUN-06/DUN-07, **Phase 129**.
- **Provider-honest docs + merge-blocking drift check + deterministic Fake-lane journey gate +
  example-host wiring** — DUN-09/DUN-10, **Phase 130** (incl. the Stripe-Dashboard over-email doc-warning
  whose *posture* is decided in D-03).
- **`Accrue.Dunning.Engine` behaviour + off-by-default conditionally-compiled Chimeway adapter** — DUN-03,
  **Phase 131** (verify Chimeway's published 1.0.0 API first; guide-vs-code mismatch).
- **Entitlements adopter-proof demo** — PROOF-03, **Phase 132** (independent of dunning).
- **Extending enqueue-`unique` dedup to other email types** (`:receipt`/`:payment_succeeded`/etc.) —
  out of DUN-04's must-fix scope; `dedup_unique/2` returns `false` for them now (no regression). Add only
  on a sourced need.
- **Per-customer cadence / multi-channel (SMS/push) / full recovered-revenue dashboard** — milestone
  Out-of-Scope (carried from REQUIREMENTS).

</deferred>

---

*Phase: 128-campaign-engine-foundation-idempotency-must-fix*
*Context gathered: 2026-05-24*
