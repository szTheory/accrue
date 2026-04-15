# Phase 5: Connect - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 05-connect
**Areas discussed:** Stripe-Account threading, Connect account persistence + charge API, Platform fee helper, Connect webhook + onboarding surface

User requested advisor-mode research on all four areas with pros/cons/tradeoffs, citing Pay (Rails) and Cashier (Laravel) precedent, idiomatic Elixir/Ecto/Plug/Phoenix, consistency across the phase, DX, and principle of least surprise. Four parallel `gsd-advisor-researcher` agents produced comparison tables synthesized below.

---

## Area 1: Stripe-Account threading

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid: pdict + opts override | `Accrue.Connect.with_account/2` (pdict scope) + `Accrue.Plug.PutConnectedAccount` + `resolve_stripe_account/1` three-level chain (opts > pdict > config). Mirrors existing `api_version` pattern. | ✓ |
| Per-call opts only | Every Billing.* call takes `stripe_account:` opt. Explicit, Pay-style, Task/Oban-safe. | |
| Scoped pdict only | `Accrue.Connect.with_account/2` block. Zero call-site churn but doesn't cross Task/Oban without middleware. | |
| Sub-facade `Accrue.Connect.Billing.*` | Mirror the whole Billing surface with acct_id first arg. Cashier-like but doubles API surface. | |

**User's choice:** Hybrid (Recommended)
**Notes:** Precedent already exists — `resolve_api_version/1` at `accrue/lib/accrue/processor/stripe.ex:820-825` implements the three-level chain, `Accrue.Stripe.with_api_version/2` is the documented template, and lattice_stripe's own per-client/per-request semantics (`lattice_stripe/lib/lattice_stripe/account.ex:12-30`) handle final resolution inside the facade. D-07 stays intact. Sub-facade rejected decisively for doubling API surface.

---

## Area 2: Connect account persistence + charge API (coupled)

### Q2a: Persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid projection (`accrue_connect_accounts` schema) | Typed columns for charges_enabled/details_submitted/payouts_enabled/country/type/email + capabilities jsonb + data jsonb. Webhook-driven via `force_status_changeset`. Matches Phase 3 D3-13/14/15. | ✓ |
| Pure passthrough | No local table; every read hits Stripe. Zero drift, but Admin LV Phase 7 must live-fetch or cache. | |
| Minimal projection (id + acct_id + data jsonb only) | Closest to Pay's `pay_merchants`. Jsonb expression indexes needed for filter/sort. | |

**User's choice:** Hybrid projection (Recommended)
**Notes:** CONN-03 explicitly names `charges_enabled`/`details_submitted`/`payouts_enabled`/`capabilities` as state that must "sync correctly" — requires a local witness. Admin LV Phase 7 will need list + filter + status badges under <100ms page budget and sane rate-limit behavior; pure passthrough fails this. Pay's lighter `pay_merchants` shape works because Pay doesn't ship an Admin LV with filter/sort.

### Q2b: Charge API shape

| Option | Description | Selected |
|--------|-------------|----------|
| Two functions (`destination_charge/2` + `separate_charge_and_transfer/2`) | Each has typed opts, distinct telemetry span, maps 1:1 to Stripe docs. | ✓ |
| Single `charge/3` with `mode:` | One entry point, internal dispatch. | |
| Building blocks only (`transfer/2` + existing `Billing.create_charge/2`) | Composable, no new abstraction. | |

**User's choice:** Two functions (Recommended)
**Notes:** CONN-04 and CONN-05 are listed as separate success criteria precisely because they're two distinct integration patterns with different failure modes and different webhook shapes (`charge.succeeded` on platform vs on connected account). Collapsing into one function with a `mode:` flag loses typed opts, distinct telemetry, and distinct ExDoc sections. Building-blocks-only fails "batteries-included" for a first-class phase.

**Coupling synthesis:** Hybrid projection enables both charge functions to accept either `%Accrue.Connect.Account{}` struct or `"acct_..."` string via internal `resolve_account/1`. Return values bundle the resolved struct so Admin LV links directly to the account detail page without a second lookup.

---

## Area 3: Platform fee helper (CONN-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Pure Money math, config-driven, caller-inject | `platform_fee(%Money{}, opts)` reads NimbleOptions config, returns `%Money{}`. Caller explicitly passes to charge fn as `application_fee_amount:`. | ✓ |
| Pure + auto-inject into charge helpers | Same computation, but charge fns auto-call `platform_fee/2` and inject unless overridden. | |
| Hybrid with `rate_override` OR `fee_amount` bypass | Two override modes in one function. | |
| Ecto-backed `accrue_connect_fee_policies` table | Native per-account overrides with effective_from/to audit trail. | |

**User's choice:** Pure Money math, caller-inject (Recommended)
**Notes:** Pay deliberately ships no fee calculator; Stripe's own Connect guidance is "compute in your app, pass `application_fee_amount` explicitly." Explicit caller-inject respects auditability — a debugging host sees the fee amount at the call site and in telemetry metadata, not inside framework code. Auto-inject hides money math behind a charge call; Ecto-backed policy is over-engineering for the 80% flat-rate case and can be added additively in v1.x. Per-account overrides are a documented 5-line guide recipe. StreamData property tests across JPY/USD/KWD are non-negotiable.

---

## Area 4: Connect webhook handler + onboarding return shape

### Q4a: Webhook handler surface

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated `Accrue.Webhook.ConnectHandler` | Conditionally dispatched when `ctx.endpoint == :connect`. Separate reducers for account.*/capability.*/person.*/account.application.*. DefaultHandler stays focused on platform events. | ✓ |
| Extend `DefaultHandler` with new clauses | Zero new wiring; pattern stays flat. | |
| User-implemented `ConnectHandler` behaviour | No built-in reconciliation; host implements. | |

**User's choice:** Dedicated `ConnectHandler` (Recommended)
**Notes:** Phase 4 D4-04 already established endpoint atom as first-class routing key; the plumbing is half-built. Keeps `DefaultHandler` legible as Phase 3 expands with Phase 5/6/7 families. Leaves room for Connect-specific idempotency semantics (e.g., `account.application.deauthorized` tombstone behavior). Pay's `Pay::Webhooks::Stripe::AccountUpdated` as sibling class validates splitting on endpoint boundary. User-behaviour option rejected because ship-complete + D2-29 demand built-in reconciliation.

### Q4b: AccountLink / LoginLink return shape

| Option | Description | Selected |
|--------|-------------|----------|
| `%Accrue.Connect.AccountLink{}` + `%LoginLink{}` structs with Inspect-masked `:url` | Matches Phase 4 CHKT-04 `BillingPortal.Session` precedent verbatim. Preserves `expires_at`. `defimpl Inspect` defends credential leak. Dual bang/tuple per D-05. | ✓ |
| Bare URL string `{:ok, url}` | Simplest API. Loses `expires_at`, no masking, breaks Phase 4 symmetry. | |
| Three-tuple `{:ok, url, expires_at}` | Carries expiry but unconventional, breaks with/else chains, no Inspect hook. | |

**User's choice:** Structs with Inspect-masked `:url` (Recommended)
**Notes:** Phase 4 CHKT-04 locked the "struct wrapping short-lived credential URL with Inspect masking" pattern for `BillingPortal.Session`. AccountLink (onboarding bearer, ~1hr expiry) and LoginLink (5-min Express dashboard bearer) are exactly the same credential-hygiene shape. Principle of least surprise demands symmetry. Do NOT ship framework-owned `refresh_url`/`return_url` helpers — host router owns those; Phase 4 explicitly kept Phoenix hard-dep out of core.

---

## Claude's Discretion

Downstream researcher and planner pick defaults for:
- Account type handling at onboarding (CONN-01) — require explicit `type:` opt
- Capability request idiom — nested-map `update/4` per lattice_stripe D-04b, no helper
- `Accrue.Connect.Account.Requirements` nested struct — jsonb verbatim
- Payout schedule config (CONN-08) — passthrough nested-map update
- LoginLink vs Account retrieve dashboard URL — Express-only
- Ops telemetry events for Connect — `connect_account_deauthorized`, `connect_capability_lost`, `connect_payout_failed`
- Test fixtures — `Accrue.Test.Factory.connect_account/1` presets

## Deferred Ideas

- Ecto-backed per-account fee policy table → v1.x
- Framework-owned return_url/refresh_url helpers → rejected (host owns Phoenix router)
- `request_capability/3` helper → rejected (fake ergonomics)
- Dedicated `accrue_connect_payouts` schema → v1.x (events ledger only in v1.0)
- Custom-type `person.*` webhook persistence → v1.x
- Standard-type dashboard redirect helper → rejected (no Stripe-blessed shortcut)
- `Accrue.Connect.Account.Requirements` typed nested struct → rejected
- `Accrue.Connect.Billing.*` sub-facade → rejected
- OAuth-based Connect onboarding → out of scope
