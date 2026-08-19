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
        [after_days: 0,  key: :reminder,        template: Accrue.Emails.InvoicePaymentFailed],
        [after_days: 5,  key: :action_required, template: Accrue.Emails.DunningActionRequired],
        [after_days: 12, key: :final_notice,    template: Accrue.Emails.DunningFinalNotice]
      ]
    ],
    grace_days: 14
  ]
```

Each step is `[after_days: N, key: atom, template: module]`. `after_days` is
absolute from `dunning_campaign_started_at`, strictly increasing and unique;
`key` is required and unique (it becomes the Oban-unique step identity);
`template` is the email module to send. The default journey is `[0, 5, 12]`
(keys `:reminder`, `:action_required`, `:final_notice`).

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

> The adapter is email-only, with a two-step workflow: the initial email waits 48 hours
> before the escalation email. A recovered invoice terminates that waiting workflow through
> an `invoice.paid` outcome signal.

### Prerequisites

- Chimeway **1.0.0** (or a compatible `~> 1.0` release) published to Hex. Chimeway
  1.0 keeps legacy email-backed correlation; versions exposing the Phase 98 privacy-safe
  recipient boundary use opaque correlation automatically.
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
  as the notifier module. The notifier creates a durable two-step WorkflowRun (initial email
  → 48-hour wait → escalation email) while `orchestration/2` remains `:immediate` for
  delivery planning.
- **Privacy-safe recipient correlation**, when supported by Chimeway, uses an opaque, stable `recipient_ref` derived from
  the Accrue customer UUID (`cw_accrue_customer_<uuid>`). Chimeway persists and routes by that
  reference only. The customer email is passed solely as transient `user:<email>` delivery
  context so it can be used in memory to address the email; it is never the durable workflow
  identity. Chimeway 1.0 lacks this boundary, so Accrue preserves its prior email identity and
  signal actor on that version rather than breaking existing recovery routing.
- **Cancel-on-recovery** emits an `"invoice.paid"` signal via `Chimeway.Signal.track/4` when
  the subscription returns to `:active`. Its actor always matches the durable identity selected
  for the notification: the opaque `recipient_ref` on privacy-safe Chimeway, or the legacy email
  identity on Chimeway 1.0. This lets Chimeway route the outcome to the waiting WorkflowRun.
  Accrue's anchor-clear still prevents any future `start_campaign` call from the recovered
  subscription.
- The adapter is **conditionally compiled**: when `:chimeway` is not present in the host's
  deps, `Accrue.Integrations.Chimeway` is never defined. There is no runtime overhead in the
  default (Oban-only) build.

### What stays the same

The following are **not affected** by switching to Chimeway orchestration:

- **Campaign DB state** — `dunning_campaign_started_at` on `accrue_subscriptions` remains the
  single anchor column; Accrue still owns all dunning DB writes.
- **Email templates** — the same Accrue dunning email modules
  (`Accrue.Emails.InvoicePaymentFailed`, `Accrue.Emails.DunningActionRequired`,
  `Accrue.Emails.DunningFinalNotice`) are used; Chimeway routes delivery, Accrue authors the
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

If you would rather surface payment trouble in your app's UI instead of (or in addition
to) email, see [In-App Banners](#in-app-banners) below — an in-app banner is the
non-email alternative for getting the customer's attention.

---

## In-App Banners

Email is not the only way to ask a customer to fix a failed payment. You can also
surface dunning state directly in your Phoenix UI — a persistent banner across the top
of the app, a callout on the billing page, or any custom markup. There are two
integration paths, and **the choice depends on which package you pull**:

| Path | Package | Use when |
|---|---|---|
| Ready-made component | `accrue_admin` | You already pull `accrue_admin` and want a drop-in banner. |
| Core-only DIY | `accrue` | You only pull core `accrue` and want to roll your own markup. |

> **Dependency boundary.** The ready-made `dunning_banner` component lives in the
> **`accrue_admin`** package (which hard-depends on the LiveView runtime). The
> `Accrue.Dunning.requires_attention?/1` helper used by the DIY path is in **core
> `accrue`** — core stays LiveView-runtime-free, so the component itself is *not* in
> core. Pull `accrue_admin` for the component; use the core helper if you don't.

### Component path (requires `accrue_admin`)

`AccrueAdmin.Components.DunningBanner.dunning_banner/1` is a headless
`Phoenix.Component` that renders **nothing** unless the given customer is in an active
dunning campaign. It takes a single required `:customer` attr and an optional
`inner_block` slot.

**Zero-config default** — render with just the customer, and Accrue supplies a default
red banner:

```heex
<AccrueAdmin.Components.DunningBanner.dunning_banner customer={@customer} />
```

When the customer is in an active dunning campaign, this renders the verbatim default
copy:

> Action Required: We were unable to process your recent payment. Please update your
> payment method to avoid service interruption.

The wrapper carries the `accrue-dunning-banner-wrapper` class and the default message
carries `accrue-default-dunning-banner`, so you can restyle either with your own CSS.

**Customized CTA via `inner_block`** — pass an inner block to replace the default copy
with your own actionable markup. Use the slot form to render an "Update your card" CTA
that deep-links to your host's payment/subscription route:

```heex
<AccrueAdmin.Components.DunningBanner.dunning_banner customer={@customer}>
  <div class="accrue-dunning-banner-wrapper" style="background-color: #fef2f2; color: #991b1b; padding: 1rem; text-align: center;">
    Your last payment didn't go through.
    <.link navigate={~p"/app/billing"} class="font-semibold underline">
      Update your card
    </.link>
    to keep your subscription active.
  </div>
</AccrueAdmin.Components.DunningBanner.dunning_banner>
```

The banner still renders nothing when the customer is not in a dunning campaign — the
`inner_block` is only invoked when attention is required.

> **Pitfall: pass a resolved `%Accrue.Billing.Customer{}`, never a raw billable.**
> The `:customer` attr accepts either a `%Accrue.Billing.Customer{}` (or `nil`) **or** a
> raw billable. Passing a raw billable triggers `Accrue.Billing.customer/1`, which has a
> **get-or-create side effect** — on every render of every request. In a layout banner
> that is a side-effecting customer-creation call on every page load. Resolve the
> customer **once**, strictly from the current scope's active organization, and assign
> it:
>
> ```elixir
> # in your LiveView mount/3 or controller, never from a params-supplied id.
> # Use a READ-ONLY scope lookup — never `customer_for_scope/1`, which is
> # get-or-create and would write a Customer row on every authenticated render.
> def mount(_params, _session, socket) do
>   customer =
>     case AccrueHost.Billing.billing_state_for_scope(socket.assigns.current_scope) do
>       {:ok, %{customer: %Accrue.Billing.Customer{} = customer}} -> customer
>       _ -> nil
>     end
>
>   {:ok, assign(socket, :customer, customer)}
> end
> ```
>
> The banner renders nothing for a `nil` or healthy customer, so the `nil`
> fallback is safe to assign directly.
>
> Resolving from the scope (not from a params-supplied customer id) also prevents a
> cross-tenant dunning-state leak — the banner only ever reflects the signed-in
> tenant's own billing state.

### Core-only DIY path (no `accrue_admin`)

If you only pull core `accrue`, use `Accrue.Dunning.requires_attention?/1` to gate your
own markup. It returns a plain `boolean` and lives in core — no LiveView runtime, no
`accrue_admin` dependency:

```heex
<%= if Accrue.Dunning.requires_attention?(@customer) do %>
  <div class="my-dunning-banner">
    We couldn't process your last payment.
    <.link navigate={~p"/app/billing"}>Update your card</.link>
    to avoid losing access.
  </div>
<% end %>
```

`requires_attention?/1` reads the ledger state as the source of truth (it delegates to
`Accrue.Billing.Query.in_active_dunning_campaign/1`, whose predicate is
`where: not is_nil(s.dunning_campaign_started_at)`), so it avoids projection-lag false
positives. The same get-or-create caveat applies: pass a resolved
`%Accrue.Billing.Customer{}` from the current scope rather than a raw billable, so you
don't trigger a customer-creation side effect on every render.

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
