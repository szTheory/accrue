# Accrue Copy Blocks

Ratified: 2026-06-14 — Phase 185
Constraint source: `brandbook/voice.md` (D-01..D-11 per 185-CONTEXT.md)

All blocks are ready to paste verbatim. Review gate is Plan 03. Editing happens there, not here.

---

## GitHub

### Repo description

Billing state, modeled clearly — the Elixir billing library for Phoenix apps

Note: This 69-character string is the exact locked string from D-05. Fits GitHub's 350-character limit with room for all topics below.

### Topics / tags

`elixir`, `phoenix`, `billing`, `subscriptions`, `stripe`, `ecto`, `payments`, `saas`,
`webhooks`, `hex`, `invoices`, `open-source`, `otp`

---

## Hex.pm

### Package description

The Elixir-native billing library for Phoenix apps. Subscriptions, checkout, invoices, coupons, emails, PDFs, webhook handling, and a mounted admin UI — all Ecto-native, all in one package pair.

Note: Replaces current mix.exs description: "Billing state, modeled clearly." (too abstract for search-indexed context per D-05). Leads with the indexed category noun ("The Elixir-native billing library") for search legibility. Under 300 characters.

---

## HexDocs

### Intro paragraph

Accrue is the Elixir-native billing library for Phoenix apps. Your app owns the billing facade (`MyApp.Billing`), routes, auth boundary, and runtime config; Accrue owns the billing engine behind them — Ecto-native schemas for Subscription, Invoice, Coupon, and every state transition in between. To evaluate Accrue without a live Stripe account, follow the proof path (VERIFY-01): start one Fake-backed subscription, post one signed webhook, inspect and replay the result in the mounted admin UI, and run `mix verify` to confirm correctness on every change. Pull requests are merge-blocked on GitHub Actions until the full proof suite passes.

Note: Tone Precise=5 / Formal=4 (API reference surface, D-09). No adjective-led claims — mechanism-only.

---

## README Hero

### H1 + tagline + descriptor

# Accrue

Billing state, modeled clearly.

Accrue is an open-source billing library for Elixir, Ecto, and Phoenix. Your app owns the billing facade, routes, auth boundary, and runtime config; Accrue owns the billing engine behind them.

Note: This block is already live in root README.md and matches D-06. Do not restructure — tagline leads because this is an engaged surface.

---

## Landing Page

### Hero section

**Headline**

Billing state, modeled clearly.

**Subhead**

The Elixir billing library for Phoenix apps.

**Body**

Your app owns the billing facade, routes, and auth boundary. Accrue owns the billing engine behind them — Ecto-native schemas, signature-verified webhooks, append-only event ledger, and a mounted admin UI, all shipping together at v1.0.

**CTAs**

Get started
Browse the source

MIT · Elixir 1.17+ · Phoenix 1.8+

---

### Problem section

Elixir developers building SaaS need billing that is idiomatic to Ecto, modeled with explicit state machines, and ships complete on day one. A thin HTTP wrapper around the Stripe API leaves every billing state — Subscription, Invoice, Coupon, proration, dunning — as caller-owned domain work. Accrue takes ownership of that domain, so your team ships a working billing loop rather than engineering one.

---

### Solution section

Every webhook is signature-verified before it touches your database, and the verification step is non-bypassable by design.

A tamper-evident, append-only event ledger records every billing state change — Subscription created, Invoice finalized, dunning step sent — without overwriting history.

Ecto-native schemas for Subscription, Invoice, Coupon, and PromotionCode ship as first-class domain objects, not raw HTTP responses.

An Oban-backed webhook processor handles retries, uniqueness, and async dispatch — configurable per host app, no separate Oban instance required.

A mounted LiveView admin UI (`accrue_admin`) gives operators a real-time view of billing state, webhook events, and customer subscriptions.

Ships complete at v1.0: subscriptions, checkout, invoices, coupons, emails, PDFs, webhook handling, and a mounted admin UI in one package pair.

---

### Install section

```elixir
# mix.exs deps
{:accrue, "~> 1.4"},
{:accrue_admin, "~> 1.4"}
```

Then run `mix deps.get && mix accrue.install`.

See the install guide →

---

### Benefits section

Your pull requests are merge-blocked if billing correctness regresses, because `mix verify.full` runs on every CI push via the `host-integration` job.

Your team evaluates Accrue without a live Stripe account, because the Fake processor runs the full billing loop deterministically from `examples/accrue_host`.

Your billing state is always inspectable, because every state change writes to the append-only `accrue_events` ledger — nothing is overwritten or deleted.

Your host app stays decoupled from Accrue internals, because the public surface is a single generated context module (`MyApp.Billing`) — internal schemas, reducer modules, and worker internals are not app-facing APIs.

---

### Comparison section

Accrue is inspired by Pay for Rails and Laravel Cashier — both excellent billing libraries in their ecosystems. Accrue brings the same table-stakes completeness to Elixir, built idiomatically for Ecto and Phoenix.

| Feature | stripity_stripe | Raw Stripe API | Accrue |
|---|---|---|---|
| Stripe API version | Pinned to 2019 API (no active updates) | Current (caller manages) | Current via lattice_stripe (tracks Stripe 2026-03-25.dahlia) |
| Ecto-native domain modeling | None (raw HTTP responses) | None (raw HTTP responses) | Explicit Ecto schemas: Subscription, Invoice, Coupon, etc. |
| Webhook handling | None (caller implements) | None (caller implements) | Signature-verified, async via Oban, non-bypassable |
| Admin UI | None | None | Mounted LiveView dashboard (accrue_admin) |
| Test support | None (HTTP stubs required) | None (HTTP stubs required) | Fake processor — no live keys, no HTTP in tests |

Factual note: stripity_stripe last significant Stripe API update was 2019 (source: hex.pm/packages/stripity_stripe changelog). Raw Stripe API: all domain modeling and webhook verification is caller-responsibility.

---

### CTAs (secondary)

Read the guide
View on Hex
Browse the source

---

## Release Notes

### Voice template

```
## v{VERSION} — {DATE}

### Added
- {Mechanism-led description of what was added and why it matters}

### Fixed
- {What was wrong; what the correct behavior is now}

### Changed
- {What changed; migration note if any}
```

**Example (register-correct, not a real release):**

```
## v1.5.0 — 2026-07-01

### Added
- `Accrue.Billing.meter_event/2` records usage events for metered subscriptions
  via Stripe's Meter Events API, with two-layer idempotency via Oban uniqueness.

### Fixed
- `Accrue.Webhook.Handler` now correctly handles `customer.subscription.paused`
  events that arrive before the corresponding `invoice.finalized` — no state
  machine regression.
```

### Changelog entry pattern

Lead with the affected module or behavior, not with "We". State the corrected behavior, not the symptom. Include a migration note if any public-facing API changed.

---

## Microcopy

### Error states

Tone: Precise=5 / Formal=3 (error/empty-state surface, D-09). No apologetic softening. State the fact; give the next action.

**Webhook signature verification failure**
Message: Signature mismatch — this request was not accepted.
Guidance: Check that ACCRUE_WEBHOOK_SECRET matches the value in your Stripe dashboard under Webhooks → signing secret.

**Stripe API key missing at startup**
Message: ACCRUE_STRIPE_SECRET_KEY is not set.
Guidance: Set this in config/runtime.exs from an environment variable. See the configuration guide.

**Subscription not found (admin UI)**
Message: No subscription found for this customer.
Guidance: The customer may not have completed checkout, or the event has not been processed yet. Check the webhook events log.

**Config validation failure at boot**
Message: Accrue configuration error: :from_email is required.
Guidance: Add `config :accrue, from_email: "billing@yourapp.com"` to config/runtime.exs.

**Invoice finalization failed**
Message: Invoice could not be finalized — Stripe returned an error.
Guidance: Check the webhook events log for the raw Stripe error payload. Common cause: payment method expired or detached.

**Oban queue not configured**
Message: Accrue requires an Oban queue named :accrue_webhooks.
Guidance: Add `accrue_webhooks: 10` to your Oban queue config. See the install guide.

### Empty states

**Subscriptions list — no subscriptions yet**
Message: No active subscriptions.
Guidance: Subscriptions appear here after a customer completes checkout.

**Webhook events log — empty**
Message: No webhook events received.
Guidance: Send a test event from the Stripe dashboard, or run `mix verify` to generate Fake events.

**Invoice list — no invoices**
Message: No invoices on record.
Guidance: Invoices are created automatically when a subscription is activated or renewed.

**Dunning log — no campaigns**
Message: No dunning campaigns running.
Guidance: Dunning starts automatically when a subscription enters past_due status and the campaign is enabled in config.

### Success states

Subscription activated.

Webhook event processed and recorded.

Invoice finalized.

Dunning campaign cancelled — subscription recovered.
