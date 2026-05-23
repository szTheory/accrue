# Jobs to Be Done: A Tour of What You Can Actually Build

**As of:** accrue 1.1.x (v1.38 milestone) · last reviewed 2026-05-22

Most billing docs hand you a wall of functions and let you assemble the picture
yourself. This guide does the opposite. It walks the **life of a paying
customer** — sign-up, first charge, a plan change, a failed card, a refund — and
shows the one or two lines of Accrue you reach for at each step. Read it
start-to-finish in about fifteen minutes and you'll have the mental map of
everything Accrue does and where each job lives.

This is the *what can I do* guide. For *how do I install it*, that's the
[First Hour](first_hour.md). For *will it break in prod*, that's
[Production readiness](production-readiness.md).

> **A note on the code snippets.** After `mix accrue.install`, your app gets a
> generated `MyApp.Billing` facade that mirrors `Accrue.Billing`. The examples
> below use *your* facade — `MyApp.Billing.subscribe(...)` — because that's what
> you'll actually type. Every one delegates to the canonical `Accrue.Billing`
> function of the same name, which is where the reference docs live.

## The mental model (read this part)

Three ideas, and the rest of the library falls into place:

1. **Your app owns the edges. Accrue owns billing state.** You own auth,
   routing, your `User`/`Organization` schema, and your UI. Accrue owns the
   subscriptions, invoices, charges, and the audit trail behind them. The seam
   between you and Accrue is the `MyApp.Billing` facade and the
   [`Accrue.Auth`](auth_adapters.md) adapter.

2. **Stripe (or Braintree) is the source of truth. Accrue keeps a faithful
   local mirror.** Every Stripe object you care about has a local row that
   Accrue keeps in sync — primarily through **webhooks**. You query your own
   database at LiveView speed; you never block a page render on a Stripe API
   call.

3. **Nothing important happens without leaving a trace.** Every state change
   lands in an append-only, tamper-evident [event ledger](#trust-the-audit-ledger).
   You can replay a customer's entire billing history, or reconstruct their state
   at any past moment.

The library ships as three packages: **`accrue`** (the engine), **`accrue_admin`**
(the LiveView back-office), and **`accrue_portal`** (a mounted self-service portal
for Braintree). And there's a **Fake processor** that behaves like the real thing
in tests and CI — so your whole billing suite runs with no network and no Chrome.

A running example for the rest of the tour: *you're shipping a team analytics
SaaS. Three plans — Free, Pro (`price_pro`, $19/mo), Team (`price_team`, $49/mo).*

## Get a customer paying

**The job:** turn a signed-up user into a paying subscriber.

The fastest path is a hosted checkout. Grab the customer (created lazily the
first time you touch it), open a session, and redirect — Stripe collects the card:

```elixir
{:ok, customer} = MyApp.Billing.customer(user)

{:ok, session} =
  MyApp.Billing.create_checkout_session(customer,
    mode: :subscription,
    line_items: [%{price: "price_pro", quantity: 1}],
    success_url: ~p"/billing/welcome",
    cancel_url: ~p"/pricing"
  )

redirect(conn, external: session.url)
```

Already have a card on file (say, from an earlier setup)? Subscribe directly,
with a trial if you want one:

```elixir
{:ok, subscription} =
  MyApp.Billing.subscribe(user, "price_pro", trial_end: {:days, 14})
```

`customer/1` lazily creates the billing customer the first time you touch it, so
you rarely have to think about customer creation as a separate step. Trials are a
single option (`{:days, n}` or a `DateTime`); the subscription comes back in
`:trialing` status and flips to `:active` on its own.

→ **In admin:** the new subscription appears under `/subscriptions` and on the
customer's page at `/customers/:id`.
→ **Deep dive:** [First Hour](first_hour.md) · [Lifecycle semantics](lifecycle_semantics.md)

## Money moves

**The job:** charge cards, produce invoices, send receipts.

For subscriptions you mostly *don't* author invoices — Stripe generates them each
cycle and Accrue mirrors them in, lifecycle and all (`draft → open → paid`). What
you do reach for:

```elixir
# A one-off charge outside any subscription (e.g. a one-time onboarding fee)
{:ok, charge} = MyApp.Billing.charge(customer, Accrue.Money.new(4900, :usd))

# Render the PDF for an invoice — pure Elixir, no headless Chrome required
{:ok, pdf_binary} = MyApp.Billing.render_invoice_pdf(invoice)
```

Invoice PDFs render through [Rendro](pdf.md) by default, so the normal path needs
no browser binary in your container. Receipts, payment-failure notices, and the
other transactional emails are wired up out of the box — Accrue sends them on the
right webhook events, and you can switch any of them off or override the template.
Payment methods are full CRUD (`add`, `list`, `set_default`, `delete`), and the
card itself is always stored as a processor reference — never raw PII.

→ **In admin:** `/invoices`, `/charges`, and the payment-methods tab on the
customer page (view, sync, set default, remove).
→ **Deep dive:** [PDF rendering](pdf.md) · [Email](email.md)

## The customer changes their mind

**The job:** upgrades, downgrades, more seats, pauses, cancellations — the daily
churn of a real subscription.

This is where Accrue earns its keep. The canonical pattern is **preview, then
commit** — show the customer exactly what the proration will cost before you pull
the trigger:

```elixir
# "What will it cost to move from Pro to Team right now?"
{:ok, preview} = MyApp.Billing.preview_upcoming_invoice(subscription, price: "price_team")

# They said yes — make the change
{:ok, subscription} =
  MyApp.Billing.swap_plan(subscription, "price_team", proration: :create_prorations)
```

The rest of the lifecycle is one call each:

```elixir
MyApp.Billing.update_quantity(subscription, 5)        # 5 seats on the Team plan
MyApp.Billing.pause(subscription)                     # pause collection, keep it alive
MyApp.Billing.resume(subscription)                    # bring it back
MyApp.Billing.cancel_at_period_end(subscription)      # let it ride out the period
MyApp.Billing.cancel(subscription)                    # end it now
```

For pre-programmed changes — "trial at $0, then Pro, then auto-bump to Team next
quarter" — there are **subscription schedules** (`subscribe_via_schedule/3`).

A word on honesty: Accrue tells you the truth about what each provider supports.
`swap_plan` and `cancel_at_period_end` are native on Stripe, test-only on Fake,
and *bounded* on Braintree (they need a `:plan_resolver` you configure). The
library labels this everywhere rather than pretending the providers are identical.

→ **In admin:** the subscription page exposes the supported preview/change/cancel
actions directly.
→ **Deep dive:** [Lifecycle semantics](lifecycle_semantics.md)

## Gate access on what they paid for

**The job:** they're subscribed — now actually *lock the paid features* behind
that subscription, everywhere in your app.

This is the other half of billing: not just collecting money, but enforcing what
the money bought. Accrue answers one question — *"what has this billable paid
for?"* — from local subscription state, with zero processor calls on the gate
path. The whole API collapses to one fail-closed boolean: the only path to
`true` is an affirmative, resolved match, so any ambiguity (no sub, unmapped
plan, even a hiccup) denies rather than leaks a paid feature for free.

```elixir
# In a function: branch on a feature or a plan
if Accrue.entitled?(user, :reports), do: render_reports(), else: upsell()

# In the router: gate a whole scope (controller plug or LiveView on_mount)
pipeline :require_pro do
  require_plan :pro                # Accrue.Plug.RequireEntitlement under the hood
end

live_session :paid, on_mount: [{Accrue.Live.Entitlements, {:require_feature, :reports}}] do
  live "/reports", ReportsLive
end
```

You declare the plan→feature map once in config (`:entitlements`), and the same
call returns the byte-identical answer across Stripe, Braintree, and Fake — it's
local-identical, not provider-forked. Denies are opaque (a `403` that leaks
nothing), and a `past_due_grace` knob lets you keep access through dunning if you
want it.

→ **In admin:** a customer's resolved active plans, granted features, quantities,
and grace state — plus any unmapped-plan drift — show on the customer page under
the **Entitlements** tab.
→ **Deep dive:** [Entitlements](entitlements.md)

## When payments fail

**The job:** a card declines on renewal. Don't lose the customer, don't lose your
mind.

Two systems share this work, and Accrue is honest about the split:

- **Stripe owns the retry cadence** (Smart Retries decides *when* to re-attempt).
- **Accrue owns the grace period and the terminal decision** — how long a
  `past_due` subscription gets before you cancel it or mark it unpaid. That's the
  [`Accrue.Billing.Dunning`](operator-runbooks.md) policy, swept on a schedule by
  `Accrue.Jobs.DunningSweeper`, emitting `[:accrue, :ops, :dunning_exhaustion]`
  when a subscription runs out of road.

Underneath all of it, **webhooks** are what keep your local mirror honest. The
ingest path verifies the signature, persists the raw event, enqueues async
handling, and returns `200` — fast, and never trusting an unsigned payload. When
you need custom behavior, you implement one callback:

```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  def handle_event("invoice.payment_failed", event, _ctx) do
    MyApp.Notifications.payment_failed(event)
    :ok
  end
end
```

Anything that fails to process lands in a dead-letter queue you can inspect and
**replay** from the admin UI.

→ **In admin:** `/webhooks` shows delivery health, the DLQ, and one-click replay.
→ **Deep dive:** [Webhooks](webhooks.md) · [Webhook gotchas](webhook_gotchas.md) · [Operator runbooks](operator-runbooks.md)

## Discounts and usage-based pricing

**The job:** run a promo; bill for what customers actually consume.

Coupons and promotion codes are first-class:

```elixir
{:ok, coupon} = MyApp.Billing.create_coupon(%{percent_off: 20, duration: :once})
{:ok, code}   = MyApp.Billing.create_promotion_code(%{coupon: coupon.id, code: "LAUNCH20"})
MyApp.Billing.apply_promotion_code(subscription, "LAUNCH20")
```

For metered products — API calls, gigabytes, seats-by-the-hour — report usage as
it happens. Accrue's metering has **two-layer idempotency**, so a retried report
never double-bills:

```elixir
MyApp.Billing.report_usage(customer, "api_calls", value: 1_000, identifier: request_id)
```

Metering works against Stripe meters and against a local metering ledger on
Braintree (with renewal settlement), so the same call works on either provider.

→ **Deep dive:** [Metering](metering.md) · [Stripe vs Braintree promotions](stripe-vs-braintree-promotions.md)

## Let customers help themselves

**The job:** stop being your customers' billing support desk.

One call gives a customer a self-service portal to update cards, see invoices, and
manage their subscription:

```elixir
{:ok, session} = MyApp.Billing.create_billing_portal_session(customer,
  return_url: ~p"/settings/billing")

redirect(conn, external: session.url)
```

On Stripe this is the hosted portal. On Braintree it's a portal **mounted in your
own app** via the `accrue_portal` package, with the same facade — so your code
doesn't fork on provider.

→ **Deep dive:** [Braintree local portal](braintree-local-portal.md) · [Portal configuration checklist](portal_configuration_checklist.md)

## You, the operator

**The job:** see what's happening and fix it, without writing a query.

Mount `accrue_admin` behind your auth and you get a real back-office, not a debug
page:

- **Dashboard** — KPIs, recent events, webhook health at a glance.
- **Customers / Subscriptions / Invoices / Charges** — list + drill-down, with the
  supported actions (refund a charge, change or cancel a subscription, download an
  invoice PDF) right there.
- **Webhooks** — delivery history, DLQ, replay.
- **Events** — the full audit timeline.

It's accessible (axe-checked in CI), mobile-credible, and gated entirely by your
host auth — operators are whoever your [`Accrue.Auth`](auth_adapters.md) adapter
says they are.

→ **Deep dive:** [Admin UI guide](https://hexdocs.pm/accrue_admin) · [Organization billing](organization_billing.md)

## Sell on behalf of others

**The job:** you're a marketplace — money flows to *your sellers*, you take a cut.

[`Accrue.Connect`](connect.md) wraps Stripe Connect: create connected accounts,
onboard them with account links, and move money with destination charges or
separate charge-and-transfer:

```elixir
{:ok, account} = Accrue.Connect.create_account(%{type: :express})

{:ok, charge} =
  Accrue.Connect.destination_charge(%{
    amount: Accrue.Money.new(10_000, :usd),
    customer: buyer,
    destination: account,
    application_fee_amount: Accrue.Money.new(1_000, :usd)
  })
```

→ **Deep dive:** [Connect](connect.md)

## Trust the audit ledger

**The job:** answer "what happened to this customer's billing, and when?" — with
proof.

Every meaningful change writes to an append-only ledger that a database trigger
physically prevents from being updated or deleted. Two queries do most of the
work:

```elixir
# The full story of one subscription, oldest first
Accrue.Events.timeline_for("subscription", subscription.id)

# What did this customer's billing look like last March 1st?
Accrue.Events.state_as_of("customer", customer.id, ~U[2026-03-01 00:00:00Z])
```

Pair that with telemetry: every public entry point emits `:telemetry`
start/stop/exception spans (`[:accrue, ...]`), and the OTel helpers no-op
gracefully if you haven't wired OpenTelemetry. You get a billing system you can
actually observe and audit — not a black box.

→ **Deep dive:** [Telemetry](telemetry.md)

## Testing all of it

**The job:** prove your billing logic without touching the network.

```elixir
use Accrue.Test
```

The Fake processor implements the same contract as Stripe and Braintree and holds
state in memory, so your full billing suite — subscriptions, webhooks, refunds,
metering — runs hermetically in CI. It's not a second-class mock; it's the
merge-blocking proof lane the library itself ships on.

→ **Deep dive:** [Testing](testing.md)

## Scope and maturity

*What's in, what's deliberately out.*

Accrue is **feature-complete for its core promise**: launch a real SaaS with
subscription billing, operate it, and trust it. On the subscription-billing core
it matches or exceeds the libraries it's modeled after (Pay for Rails, Laravel
Cashier), and it ships things they don't — the admin UI, the audit ledger,
first-class telemetry, metered billing, and Connect.

A few things are **intentionally not Accrue's job**, by written decision — not
oversight:

| Deliberately out of scope | Why | Where it belongs |
|---------------------------|-----|------------------|
| Revenue recognition / accounting exports (FIN-03) | Accrue is a billing library, not an accounting system | Stripe-native reporting; see [Finance handoff](finance-handoff.md) |
| MRR / ARR / churn analytics | The math is business-specific; opinionated numbers would mislead | Build on the event ledger, or Stripe Sigma / Metabase |
| Merchant-of-record processors (Paddle, Lemon Squeezy) | PROC-08 is a bounded Stripe + Braintree core | — |
| Marketplace payouts via Hyperwallet | Durable no-go decision (v1.33) | — |
| GDPR data purge / cascading delete | Host policy; the audit ledger is immutable by design | Your app's data-retention layer |

**Core entitlements** ✅ **shipped** — first-party helpers to *gate features* on a
subscription. You get the fail-closed gate API (`has_active_plan?` / `entitled?`
/ `features_for` / `entitlement_quantity`), a `Accrue.Plug.RequireEntitlement`
controller plug plus `require_feature`/`require_plan` router macros, a
conditionally-compiled LiveView `on_mount` guard, and an admin entitlements view.
It's **provider-honest** (local-identical across Stripe/Braintree/Fake) and
**lifecycle-truthful** (derives from `entitling?/1`, with a `past_due_grace`
knob). The *optional* Stripe-native sync (consuming
`entitlements.active_entitlement_summary.updated`) is a deferred, off-by-default
add-on (Phase 127) — the core gate needs no Stripe dependency. See
[Entitlements](entitlements.md).

Accrue runs in **intake-gated maintenance mode** — stable, with new work driven by
real adopter needs rather than speculative expansion. The full reasoning, and the
stop rules behind it, are in [Maturity and maintenance](maturity-and-maintenance.md).

---

## Update log

- **2026-05-22** — Initial tour. As of accrue 1.1.1 / v1.38. Snippets verified
  against `Accrue.Billing`. Scope table mirrors the internal capability frontier.
- **2026-05-23** — entitlements ✅ shipped (v1.39): added the "Gate access on what
  they paid for" section and flipped the scope table row from gap to shipped. Core
  gate API + Plug/LiveView guards + admin view are first-party and provider-honest;
  the optional Stripe-native sync stays deferred and off by default (Phase 127).
