# Dunning — multi-step email recovery campaigns

For the canonical meaning of `past_due`, `unpaid`, and the grace window that governs
whether a past-due subscriber remains entitled — see
[Lifecycle Semantics](lifecycle_semantics.md#past_due). Use that guide for the truth of
*what dunning territory looks like*; use **this** guide for how the dunning campaign
behaves per provider, how to configure it, and what observability it emits.

> **Tagline:** one provider-independent email cadence, two per-provider retry stories,
> zero processor calls on the campaign step path.

---

## Overview — a provider-independent campaign

Accrue's dunning campaign is a multi-step email cadence that fires automatically when a
subscription enters `past_due` territory. The campaign is **entirely local-identical**:
it is driven off `dunning_campaign_started_at` (anchored on the first
`nil → past_due` transition) and the `Accrue.Clock` testable clock, making
**zero processor calls** on the campaign step path. The step sequencer never touches
the Stripe or Braintree API — it reads local subscription state and schedules Oban jobs.

**Default journey:** `[0, 5, 12]` — a day-0 first notice, a day-5 reminder, and a
day-12 final notice before the dunning grace window expires. Each value is an absolute
`after_days` offset from `dunning_campaign_started_at`.

Because the campaign is Accrue-clock-driven with zero processor calls, **the campaign
cadence behaves identically across Stripe, Braintree, and Fake**. The only
per-provider difference is what happens at the *payment-retry* layer beneath the
campaign — documented in the per-provider section below.

### all first-party

The `dunning.campaign` capability carries the public label **all first-party**: Stripe,
Braintree, and Fake all receive the same `[0, 5, 12]` step sequence, the same step
emails, and the same `recovered` / `exhausted` terminal paths. There is no provider
that "does it natively" because the campaign is **local-identical** — processor calls
are never made to advance it.

---

## Per-provider breakdown

### Stripe — native (Smart Retries)

Stripe has **native (Smart Retries)**: an adaptive payment-retry schedule (typically
1–4 weeks) that Stripe runs automatically beneath Accrue's email campaign. When Smart
Retries succeed between two campaign steps, the subscription transitions back to
`:active` before the next step fires, and the campaign marks itself recovered
(`dunning.recovered` ledger event). The two systems (Stripe Smart Retries + Accrue
campaign) are complementary — Stripe controls the payment retry timing; Accrue controls
the customer-facing email timing.

**Stripe Test Clocks** are the advisory tool for real-Stripe end-to-end testing of the
dunning path: you can advance a test-clock subscription through the `past_due` →
`unpaid` path in a sandbox environment and observe how Smart Retries interact with the
campaign steps. Test Clocks are a network-gated advisory lane, **not** the merge gate
(see [Fake — testing/local-only](#fake--testinglocal-only) below). Reference:
<https://docs.stripe.com/billing/testing/test-clocks>.

### Braintree — unsupported (clock-driven only)

Braintree is **unsupported (clock-driven only)**: there is no processor-native smart-retry
overlay. Braintree is **not retry-aligned** — a Braintree host gets Accrue's
`[0, 5, 12]` email cadence but no adaptive payment retry schedule running beneath it.
Braintree has its own dunning settings in the Control Panel (retry count, retry
interval), but those are separate, host-configured, and Accrue does not orchestrate or
observe them. The Accrue campaign emails are the sole retry signal from Accrue's
perspective.

If a Braintree subscription recovers via a Braintree-initiated retry between campaign
steps, the webhook projection updates local state and the campaign marks itself
recovered in the normal way — Braintree's retry can trigger recovery, but Accrue's
cadence does not *drive* it.

### Fake — testing/local-only

Fake is the **testing/local-only** proof lane: a deterministic, clock-advanceable
substrate for the CI merge gate. The `Accrue.Clock` in test is a controllable fake
clock; advancing it past step boundaries causes the DunningStep worker to resolve and
schedule the next step without any network access. This is the canonical path for
validating campaign step logic in CI and in local development.

The Fake lane is the **merge gate** for campaign correctness. Stripe Test Clocks and
Braintree sandbox paths are advisory / real-provider verification lanes that you run
manually before major releases — not the automated gate.

---

## Configuration

The campaign is configured under the `:dunning` key in your Accrue config:

```elixir
# config/runtime.exs
config :accrue,
  dunning: [
    campaign: [
      enabled: true,
      steps: [
        [after_days: 0,  template: :dunning_step_1],
        [after_days: 5,  template: :dunning_step_2],
        [after_days: 12, template: :dunning_step_3]
      ]
    ],
    grace_days: 14
  ]
```

The `steps:` list is ordered by `after_days` (ascending). Each step maps an
`after_days` offset (absolute from `dunning_campaign_started_at`) to a Swoosh email
template key. The default journey is `[0, 5, 12]`.

**Opt out entirely:**

```elixir
config :accrue, dunning: [campaign: [enabled: false]]
# or shorthand:
config :accrue, dunning: [campaign: false]
```

**Accessor:** `Accrue.Config.dunning_campaign_steps/0` returns the configured steps
list (or the default) at runtime. See `Accrue.Config` for the full reference and
NimbleOptions schema.

---

## Upgrading to Chimeway orchestration

The built-in campaign engine — `Accrue.Dunning.Engine.Oban` — is **always on by default**
and requires no additional dependencies. Core Accrue never requires Chimeway.

If you want to delegate dunning orchestration to [Chimeway](https://hex.pm/packages/chimeway),
Accrue ships an **optional, off-by-default** adapter (`Accrue.Integrations.Chimeway`) that
implements the `Accrue.Dunning.Engine` behaviour and routes campaign lifecycle events through
Chimeway's `trigger/3` + `Notifier` surface. This section is the opt-in upgrade guide.

> **v1.40 scope:** the adapter is email-only with `:immediate` orchestration. Multi-channel
> and multi-step workflow orchestration are deferred to a future v1.x minor.

### Prerequisites

- Chimeway **1.0.0** (or a compatible `~> 1.0` release) published to Hex.
- Accrue v1.40 or later (the `Accrue.Dunning.Engine` behaviour and adapter ship together).
- Chimeway's own migrations must be run in the host database. Accrue does **not** start
  Chimeway — that is the host app's responsibility.

### Installation

Add `:chimeway` to your host's `mix.exs`:

```elixir
defp deps do
  [
    {:accrue, "~> 1.40"},
    {:chimeway, "~> 1.0"},   # optional — only needed when upgrading to Chimeway orchestration
    # ...
  ]
end
```

Follow Chimeway's install guide to add the required Chimeway migrations and start Chimeway in
your supervision tree. Accrue does not start or supervise Chimeway.

### Configuration

Flip the `engine:` key under `:dunning`:

```elixir
# config/config.exs  (compile-time is acceptable — engine adapter is stable per-deploy)
config :accrue,
  dunning: [engine: Accrue.Integrations.Chimeway]
```

The `dunning: [engine:` key accepts any module that implements the `Accrue.Dunning.Engine`
behaviour. The built-in default is `Accrue.Dunning.Engine.Oban`. Switching to
`Accrue.Integrations.Chimeway` is additive and reversible — remove the key to fall back to the
built-in engine.

### What changes

- **Orchestration of dunning notifications** delegates to Chimeway. When a campaign starts,
  Accrue calls `Chimeway.trigger/3` with the bundled `Accrue.Integrations.Chimeway.DunningNotifier`
  as the notifier module. The `DunningNotifier` implements `Chimeway.Notifier` with
  `channels/2` returning `[:email]` and `orchestration/2` returning `:immediate` — so
  Chimeway delivers the dunning email immediately, with no WorkflowRun created.
- **Cancel-on-recovery** emits a `"payment_recovered"` signal via `Chimeway.Signal.track/4`
  when the subscription returns to `:active`. With `:immediate` orchestration this signal
  routes to zero WorkflowRuns (a safe no-op); Accrue's anchor-clear prevents any future
  `start_campaign` call from the recovered subscription.
- The adapter is **conditionally compiled**: when `:chimeway` is not present in the host's
  deps, `Accrue.Integrations.Chimeway` is never defined. There is no runtime overhead in the
  default (Oban-only) build.

### What stays the same

The following are **not affected** by switching to Chimeway orchestration:

- **Campaign DB state** — `dunning_campaign_started_at` on `accrue_subscriptions` remains the
  single anchor column; Accrue still owns all dunning DB writes.
- **Email templates** — the same Accrue dunning email templates (`dunning_step_1`,
  `dunning_step_2`, `dunning_step_3`) are used; Chimeway routes delivery, Accrue authors the
  content.
- **Ledger events** — `dunning.campaign_started`, `dunning.step_sent`, `dunning.recovered`, and
  `dunning.exhausted` are still written to `accrue_events`.
- **Telemetry** — the `[:accrue, :ops, :dunning_*]` telemetry family is unchanged.
- **Customer and admin surfaces** — the portal recovery banner, the admin dunning-state card,
  and `Accrue.Billing.Dunning.recovered_vs_lost/1` all work identically.
- **`Accrue.Dunning.Engine` behaviour** — the behaviour is the seam. You can implement your own
  adapter via `@behaviour Accrue.Dunning.Engine` and configure it under `dunning: [engine:]`.

---

## Observability

The dunning campaign emits four **ledger events** (written to `accrue_events`):

| Event | When |
|---|---|
| `dunning.campaign_started` | Anchor set; day-0 step enqueued |
| `dunning.step_sent`        | An individual step email was sent |
| `dunning.recovered`        | Subscription returned to `:active` before exhaustion |
| `dunning.exhausted`        | All steps fired with no recovery; terminal sweep action taken |

In addition, the `[:accrue, :ops, :dunning_*]` telemetry family emits
`:start` / `:stop` / `:exception` spans for campaign entry points. See
[Telemetry & Observability](telemetry.md) for the full event payload reference and
the default metrics recipe — do **not** re-specify event shapes here.

The `recovered_vs_lost/1` counter (`Accrue.Billing.Dunning.recovered_vs_lost/1`)
folds the ledger into `%{recovered: count, lost: count}` for an optional since/until
window. It does not double-count: a `dunning.exhausted` event that was followed by
a manual recovery action (logged separately) counts as `lost` at the campaign level.

---

## Over-email warning

> **Warning:** if your Stripe account has **Stripe Dashboard dunning emails** enabled
> (under **Billing → Subscriptions → Manage failed payments → Send emails to
> customers**) AND Accrue's campaign is also enabled (`dunning: [campaign: [enabled:
> true]]`), customers on Stripe **will receive duplicate emails** — one set from Stripe
> Dashboard and one set from Accrue. Disable one side:
>
> - **Disable Accrue's campaign:** `dunning: [campaign: [enabled: false]]` or
>   `dunning: [campaign: false]` in `config/runtime.exs`.
> - **Disable Stripe Dashboard emails:** turn off the "Send emails to customers" toggle
>   under **Billing → Subscriptions → Manage failed payments** in the Stripe Dashboard.
>
> There is no risk of duplicate emails on Braintree (Braintree has no shared email
> cadence that Accrue would overlap with). There is no risk with Fake (local-only, no
> real sends).

---

## Lifecycle and entitlements interaction

This guide does **not** re-derive the `past_due` / `unpaid` / grace lifecycle truth —
see [Lifecycle Semantics → `past_due`](lifecycle_semantics.md#past_due) for the
canonical mapping.

Two orthogonal knobs operate independently:

1. **Dunning campaign** — the email recovery cadence (this guide).
2. **`past_due_grace` entitlement knob** — whether a `past_due` subscriber remains
   entitled during the dunning window. Configured under `:entitlements` as
   `past_due_grace: :dunning` (reuse the `grace_days` window) or
   `past_due_grace: N` (independent day count). See
   [Entitlements](entitlements.md) for the full knob reference.

A `past_due` subscriber **may still be entitled** while the campaign emails are
firing — those are orthogonal knobs. Setting `past_due_grace: :dunning` makes the
entitlement window match the campaign window; setting `past_due_grace: :none` (the
default) fails the subscriber closed immediately on `past_due` while the campaign
continues to email. Neither knob controls the other.

`Accrue.Config.dunning_campaign_steps/0` is the accessor for campaign config;
`Accrue.Config.entitlements/0` is the accessor for the grace knob. They compose
independently.
