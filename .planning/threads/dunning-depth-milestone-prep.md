---
slug: dunning-depth-milestone-prep
title: "Dunning depth / notification journeys — next-milestone prep"
status: open
created: 2026-05-24
updated: 2026-05-24
---

# Thread: Dunning depth / notification journeys — next-milestone prep

## Goal

Pre-resolve the research for the selected next milestone (likely **v1.40 — Dunning
depth / multi-step notification journeys**) so its discuss/plan phases start
informed. This is the **one 🟡-bounded item left on the canonical revenue loop**
and the project's own #1 ranked candidate. Captured from the 2026-05-24
post-v1.39 milestone next-step assessment (3 parallel research agents,
repo-local + sibling-repo + prompts-corpus grounded). **Do not re-derive.**

## Context

*Created 2026-05-24. All findings verified against `accrue/lib`, `accrue/test`,
`examples/accrue_host`, the sibling `chimeway` repo, and the `prompts/` corpus.*

### Verified dunning baseline TODAY (what exists — the entire baseline)

1. **Single failed-payment email, re-sent per Stripe retry, NOT deduped.** Stripe
   `invoice.payment_failed` → `:invoice_payment_failed` → `Accrue.Emails.InvoicePaymentFailed`
   (`webhook/default_handler.ex:1466`, mapping `workers/mailer.ex:325`). It routes
   through `deliver_swoosh` and **has no idempotency key** — `idempotency_key/2`
   only covers `:receipt`/`:payment_succeeded`/`:payment_failed` (`workers/mailer.ex:292,314`).
   Charge-level `:payment_failed` IS deduped by `charge_id`. Net: every Stripe Smart
   Retry re-fires the same identical email. **No Accrue-authored cadence, no per-step
   copy, no scheduler.**
2. **`past_due_since` bookkeeping** stamped from Stripe next-retry data (`default_handler.ex:969`).
3. **Grace→terminal sweeper** — `Accrue.Billing.Dunning.compute_terminal_action/2`
   (`billing/dunning.ex:47`) + cron `Accrue.Jobs.DunningSweeper.sweep/0`
   (`jobs/dunning_sweeper.ex:64`). Default `mode: :stripe_smart_retries, grace_days: 14,
   terminal_action: :unpaid` (`config.ex:228`). Sends **no email**; does only the
   terminal action. **Host-wired-optional and NOT wired in `examples/accrue_host`.**
4. **Entitlement grace during past_due** — `Accrue.Entitlements.PastDueGrace.within_grace?/2`
   (default `:none`).
5. **Exhaustion telemetry** — `[:accrue, :ops, :dunning_exhaustion]` (`default_handler.ex:758`).

Well-tested for what it is (`dunning_test.exs`, `dunning_sweeper_test.exs`,
`dunning_exhaustion_test.exs`, `past_due_grace_test.exs`). **A "dunning depth"
milestone is net-new product surface, not polish of an existing journey.**

### Chimeway dependency verdict — **(B) optional integration + thin built-in default**

Build a small self-contained `Accrue.Dunning.Campaign` (Oban-driven, reuses
`accrue_events` + existing mailer, **no new heavy deps**) as the always-on default,
**plus** a conditional-compiled, off-by-default `Accrue.Integrations.Chimeway`
adapter behind an `Accrue.Dunning.Engine` behaviour. **Do NOT hard-depend on Chimeway.**

Chimeway maturity (verified): **published on Hex at `1.0.0`** (owner `sztheory`,
2026-05-08); local `/Users/jon/projects/chimeway/mix.exs` version string is **stale
at `0.1.0`** while tags are at `v1.2`. It is a genuine durable journey engine
(workflow_run/step/transition schemas, `:waiting`/`suspended_until`, signal-driven
cancel, Oban dispatch, built-in idempotency, 64 test files incl. reliability suites).
Why optional not hard-dep: only 1.0.0 on Hex (2 weeks old) → churn risk vs Accrue's
"zero breaking-change pain through v1.x"; it pulls its own Ecto schema/migrations +
Oban → heavy install tax for hosts who just want a 3-email cadence; dunning is **not**
on the critical install path (Mailglass/lattice_stripe are, which is why those are
hard deps). SEED-002 frames Chimeway as a blueprint/integration, not a foundation.

⚠ **Open conflict to verify before coding the adapter:** Chimeway's guide
(`guides/flows/multi-step-journeys.md`) and code disagree on the public surface —
guide uses `Chimeway.Workflow`/`Chimeway.Trigger.trigger`; code's public entry is
`Chimeway.trigger/3` + `Chimeway.Notifier` behaviour with a `workflow/2` callback +
`Chimeway.Signal.track/4`. Pin to and target the **published 1.0.0** API.

### Idiomatic architecture sketch (Oban-chained, cancelable)

- `Accrue.Dunning.Campaign` — pure ordered-step resolution from config (property-testable).
- `Accrue.Dunning.Engine` behaviour → `Engine.Oban` (default) + `Integrations.Chimeway` (opt-in).
- `Accrue.Workers.DunningStep` (queue `:accrue_dunning`): on perform → **cancel guard**
  (re-check live state; if subscription left `past_due` / `past_due_since` cleared →
  `{:cancel, :recovered}`, no email), else deliver step email, record ledger event,
  enqueue next step with `schedule_in: next_delay`.
- **Start** at the nil→`past_due` transition (`maybe_bump_past_due_since`, `default_handler.ex:969`);
  pin the campaign key to the **first** transition, not every bump (bumps must not
  restart/orphan in-flight jobs — open question #4 below).
- **Cancel on recovery** when webhook flips status back to active/paid → `Oban.cancel_all_jobs`
  for the campaign key (or Chimeway signal).
- **Idempotency** = Oban `unique: [keys: [:subscription_id, :step_key, :campaign_started_at]]`
  + extend `Mailer.idempotency_key/2` to cover `:invoice_payment_failed` (this closes
  the existing un-deduped re-send — **must-fix this milestone**).
- Reuse `accrue_events` (`dunning.campaign_started`/`step_sent`/`recovered`/`exhausted`)
  → recovered-revenue "counter" is a ledger query, **no new table**. Extend the
  `[:accrue, :ops, :dunning_*]` telemetry family.
- **Testability**: Fake-lane deterministic clock-advance proof is the merge gate
  (`Accrue.Clock.utc_now/0` already used at `dunning_sweeper.ex:101`); Stripe Test
  Clocks documented for the real-Stripe E2E lane only.
- **Provider honesty**: Stripe = full (Smart Retries + cadence + Test Clocks);
  Braintree = clock-driven cadence works (off `past_due_since`) but **not retry-aligned**
  (Braintree has no smart-retry overlay) — document; Fake = the proof lane.

### Comparator steal/avoid (condensed)

- **Steal:** named configurable stages with distinct copy (reminder → action-required →
  final-notice, à la Chargebee/Recurly); every step CTA deep-links to the portal
  update-card flow (`accrue_portal/.../add_payment_method_live.ex` already exists —
  highest-converting recovery action); a recovered-revenue counter (the metric merchants
  care about); **stop the instant a retry succeeds** (Stripe behavior — non-negotiable).
- **Avoid:** Cashier's **hardcoded cadence paths** (make it config-driven); over-emailing /
  duplicating Stripe Dashboard's own dunning emails (opt-out + doc warning); no idempotency
  (the current bug); forgetting the "card fixed → journey keeps emailing" cancellation;
  ignoring Test Clocks.

### "Done enough" checklist (bounded to one milestone)

**In:** the `:invoice_payment_failed` idempotency must-fix; `Dunning.Campaign` + config
schema (nested `campaign:` under existing `dunning:` at `config.ex:228`); `Engine`
behaviour + `Engine.Oban` + `Workers.DunningStep` (chaining, cancel guard, unique);
campaign start + cancel-on-recovery wiring; 2 new Mailglass templates (action_required,
final_notice) with portal-update-card CTA; ledger events + telemetry; **one** customer
recovery surface (portal "payment failed — update card" banner → add_payment_method);
admin dunning-state visibility on subscription/customer live; `Integrations.Chimeway`
opt-in adapter + guide (SEED-002 requirement); Fake-lane deterministic test (merge gate);
**wire the default campaign into `examples/accrue_host`** (closes the dormant-cron gap).

**Deferred (scope-creep guards):** full recovered-revenue analytics dashboard (ship only
a ledger counter + telemetry); multi-channel (SMS/push — Chimeway-as-engine unlocks later);
exposing Chimeway's full explain/traces UI in admin; per-customer cadence beyond global
config; provider-native dunning-email coordination beyond a doc warning.

### Open questions / risks for the maintainer

1. Chimeway guide-vs-code public-surface mismatch — verify against published 1.0.0 first.
2. Double-emailing if host has Stripe Dashboard dunning emails on → opt-out + doc warning.
3. Campaign final-notice vs sweeper grace→terminal must be coherent → validate
   `last_step.after_days <= grace_days` in the NimbleOptions schema.
4. `past_due_since` is bumped on every failure → pin campaign key to the FIRST transition
   so bumps don't orphan/restart in-flight jobs; add a "campaign already running" guard.
5. Braintree cadence is Accrue-clock-only, not retry-aligned → document.

## References

- `accrue/lib/accrue/workers/mailer.ex` (`idempotency_key/2:292`, `default_template/1:325`) — **must-fix site**
- `accrue/lib/accrue/mailer/default.ex` (`deliver/2:33` — plain `Oban.insert`, no `unique`)
- `accrue/lib/accrue/webhook/default_handler.ex` (`do_dispatch_invoice:1472`, `maybe_bump_past_due_since:969`)
- `accrue/lib/accrue/billing/dunning.ex`, `accrue/lib/accrue/jobs/dunning_sweeper.ex`, `accrue/lib/accrue/entitlements/past_due_grace.ex`
- `accrue/lib/accrue/config.ex:228` (existing `dunning:` schema to extend)
- `accrue_portal/lib/accrue_portal/live/{home_live,subscriptions_live,add_payment_method_live}.ex` (recovery banner target)
- `accrue_admin/lib/accrue_admin/live/{subscription_live,customer_live}.ex` (admin dunning state)
- `.planning/seeds/SEED-002-ecosystem-integrations.md` (#1 Chimeway+Mailglass)
- Chimeway: `/Users/jon/projects/chimeway/lib/chimeway.ex`, `lib/chimeway/workflows.ex`, `lib/chimeway/notifier.ex`, `guides/flows/multi-step-journeys.md`, `mix.exs` (stale 0.1.0)
- `prompts/payments_domain_field_guide.md` (§"The dunning flow"), `prompts/The definitive Stripe library gap in Elixir - a master research document.md`

## Next Steps

- The user kicks off the milestone (`/gsd-new-milestone "v1.40 Dunning depth"`).
- discuss/plan phase: lift the "done enough" checklist into REQUIREMENTS; confirm the
  Chimeway 1.0.0 public API before committing the adapter (open question #1).
- Pull the idempotency must-fix into the first phase regardless of cadence scope.
