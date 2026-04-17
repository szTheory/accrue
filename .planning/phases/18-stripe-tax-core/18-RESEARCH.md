# Phase 18: Stripe Tax Core - Research

**Researched:** 2026-04-17
**Domain:** Stripe Tax orchestration for Accrue subscription and checkout flows
**Confidence:** MEDIUM

## Summary

Phase 18 does not need a new tax engine or a processor-strategy change. Accrue already has the correct architectural seams: `Accrue.Billing.subscribe/3` and `Accrue.Checkout.Session.create/1` normalize public inputs, `Accrue.Processor.Stripe` is the only Stripe-facing boundary, `Accrue.Processor.Fake` is the deterministic test double, and local projections already persist raw upstream payloads in `data` JSONB while exposing selected derived columns. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/api/checkout/sessions/retrieve?__=]

Stripe Tax enablement for new flows is mechanically simple on the wire: Stripe expects `automatic_tax[enabled]=true` for Subscriptions and Checkout Sessions, and the returned Subscription, Invoice, and Checkout Session objects all carry automatic-tax state that can be projected locally. The planning risk is not the API call itself; it is choosing a public Accrue option shape that is simple, keeping Fake and Stripe response shapes aligned, and projecting only the tax fields that are actually useful without overfitting the schema to Stripe’s fast-moving tax payloads. [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/billing/taxes/collect-taxes] [CITED: https://docs.stripe.com/tax/checkout] [VERIFIED: codebase grep]

**Primary recommendation:** Add one explicit public boolean option for new subscription and checkout creation, translate it to Stripe’s `automatic_tax: %{enabled: true|false}` only inside the processor/request builders, preserve the full upstream tax payload in `data`, and add only minimal derived observability fields where the existing projections are currently blind. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/set-up]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public tax enablement option on `Accrue.Billing.subscribe/3` | API / Backend | Database / Storage | Billing context already owns subscription creation input normalization and calls `SubscriptionActions.subscribe/3`; host/browser code is not the source of truth here. [VERIFIED: codebase grep] |
| Public tax enablement option on `Accrue.Checkout.Session.create/1` | API / Backend | Browser / Client | Checkout sessions are created server-side and handed to the client as a session URL or client secret; Stripe remains canonical. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/checkout] |
| Stripe automatic-tax request passthrough | API / Backend | — | `Accrue.Processor.Stripe` is the sole module allowed to talk to `LatticeStripe`, so Stripe-specific request shape belongs there. [VERIFIED: codebase grep] |
| Fake deterministic tax state | API / Backend | — | `Accrue.Processor.Fake` already owns deterministic resource creation and test-only state transitions; tax enablement should be modeled there rather than mocked elsewhere. [VERIFIED: codebase grep] |
| Subscription and invoice tax observability | Database / Storage | API / Backend | Local Ecto projections own persisted billing state; `SubscriptionProjection` and `InvoiceProjection` already decompose upstream payloads into columns plus `data`. [VERIFIED: codebase grep] |
| Checkout tax observability | API / Backend | — | There is no persisted checkout-session schema today; the local projection is the `%Accrue.Checkout.Session{}` struct returned by the context. [VERIFIED: codebase grep] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TAX-01 | Developer can enable Stripe Tax for new subscription and checkout flows through Accrue's public billing API. | Public option normalization belongs in `SubscriptionActions` and `Checkout.Session`; Stripe expects `automatic_tax[enabled]=true`; Fake and local projections must mirror the same enabled/disabled concept deterministically. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/set-up] [CITED: https://docs.stripe.com/billing/taxes/collect-taxes] [CITED: https://docs.stripe.com/tax/checkout] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+ conventions; do not introduce legacy compatibility work. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Keep `lattice_stripe` as the required Stripe wrapper and preserve the Stripe-first processor strategy. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Webhook signature verification is mandatory and non-bypassable; webhook safety assumptions must not be weakened while adding tax state. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Sensitive Stripe fields must never be logged; Stripe references are stored instead of raw payment PII. Tax work must follow the same discipline. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- All public entry points emit telemetry and OTel span helpers stay available; new subscription/checkout tax paths should remain inside the existing instrumented surfaces. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Adapter resolution is runtime-configured through the existing processor behaviour; Phase 18 must not bypass that abstraction. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Fake is the primary deterministic test surface; live Stripe checks remain advisory. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `lattice_stripe` | `1.1.0` (published 2026-04-14) | Stripe API wrapper used by `Accrue.Processor.Stripe` for subscriptions, invoices, and checkout sessions. [VERIFIED: Hex.pm API] | The repo already depends on `~> 1.1`, the lockfile is on `1.1.0`, and the installed package already models `automatic_tax` on Subscription, Invoice, and Checkout Session resources. [VERIFIED: Hex.pm API] [VERIFIED: codebase grep] |
| `nimble_options` | `1.1.1` (published 2024-05-25) | Public option validation at API boundaries. [VERIFIED: Hex.pm API] | The repo already uses it for checkout/session and other public options; tax enablement should follow the same pattern instead of ad hoc keyword parsing. [VERIFIED: codebase grep] [VERIFIED: Hex.pm API] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Accrue.Processor.Fake` | repo-local | Deterministic processor parity surface for tests. [VERIFIED: codebase grep] | Use for all required Phase 18 tests; reserve live Stripe only for optional parity checks. [VERIFIED: codebase grep] |
| `ExUnit` + `Accrue.BillingCase` | repo-local | Integration-style tests with sandboxed DB and reset Fake state. [VERIFIED: codebase grep] | Use for subscribe/checkout projection tests that need DB rows and Fake reset semantics. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Public boolean tax flag normalized by Accrue | Raw Stripe-shaped nested option everywhere | Raw Stripe parity is familiar, but it leaks processor details into the public API and raises future compatibility cost if Accrue ever needs a provider-neutral contract. [CITED: https://docs.stripe.com/tax/set-up] [VERIFIED: codebase grep] |
| Persist selected tax observability fields plus raw `data` | Full 1:1 Stripe tax schema in local tables | Full parity is brittle because Stripe tax fields have already changed on invoices across API versions; raw payload retention plus narrow derived columns is safer. [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations] [VERIFIED: codebase grep] |

**Installation:**
```bash
# No new dependencies required for Phase 18.
mix deps.get
```

**Version verification:** `lattice_stripe` latest stable is `1.1.0` with Hex release timestamp `2026-04-14T20:51:44Z`; `nimble_options` latest stable is `1.1.1` with Hex release timestamp `2024-05-25T10:51:15Z`. Verified via `mix hex.info` and Hex package API responses. [VERIFIED: Hex.pm API]

## Architecture Patterns

### System Architecture Diagram

```text
Host app / tests
    |
    v
Accrue.Billing.subscribe/3 or Accrue.Checkout.Session.create/1
    |
    v
Boundary option normalization (NimbleOptions / keyword handling)
    |
    +--> tax disabled -> existing request shape -> processor
    |
    +--> tax enabled -> add automatic_tax intent -> processor
                                  |
                                  +--> Accrue.Processor.Stripe -> LatticeStripe -> Stripe
                                  |
                                  +--> Accrue.Processor.Fake -> deterministic in-memory resource
    |
    v
Canonical processor payload
    |
    +--> SubscriptionProjection / InvoiceProjection -> DB rows + derived columns + raw data
    |
    +--> Checkout.Session.from_stripe/1 -> session struct returned to caller
    |
    v
Focused tests verify enabled + disabled flows remain backward-compatible
```

### Recommended Project Structure
```text
accrue/lib/accrue/
├── billing/subscription_actions.ex      # add public tax option -> subscription params
├── checkout/session.ex                  # add public tax option -> checkout params/struct
├── processor/stripe.ex                  # pass automatic_tax through Stripe calls
├── processor/fake.ex                    # deterministic enabled/disabled tax payloads
├── billing/subscription_projection.ex   # derive subscription tax observability
└── billing/invoice_projection.ex        # preserve invoice automatic_tax + tax amount state
```

### Pattern 1: Normalize once at the public boundary
**What:** Accept one Accrue-level option on the public API and translate it to processor params in one place. [VERIFIED: codebase grep]
**When to use:** `subscribe/3` and `Checkout.Session.create/1`. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/checkout/session.ex
opts = NimbleOptions.validate!(Map.to_list(params), @create_schema)
{stripe_params, request_opts} = build_stripe_params(opts)
Processor.__impl__().checkout_session_create(stripe_params, request_opts)
```

### Pattern 2: Keep Stripe-specific shape inside the processor/request builders
**What:** Build `automatic_tax: %{enabled: true|false}` only after Accrue has normalized the public option. [CITED: https://docs.stripe.com/tax/set-up] [VERIFIED: codebase grep]
**When to use:** Subscription creation and checkout-session creation. [CITED: https://docs.stripe.com/billing/taxes/collect-taxes] [CITED: https://docs.stripe.com/tax/checkout]
**Example:**
```elixir
# Source: https://docs.stripe.com/billing/taxes/collect-taxes
%{
  customer: customer.processor_id,
  items: [item_params],
  automatic_tax: %{enabled: true}
}
```

### Pattern 3: Project narrow observability fields and keep the raw payload
**What:** Store only the tax fields Accrue needs to query or render directly; keep the full upstream payload in `data` for forward compatibility. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations]
**When to use:** Subscription and invoice projections. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice_projection.ex
%{
  tax_minor: SubscriptionProjection.get(stripe_inv, :tax),
  data: SubscriptionProjection.to_string_keys(stripe_inv)
}
```

### Anti-Patterns to Avoid
- **Leaking Stripe shape into the public API:** Do not require host apps to construct nested Stripe maps just to enable tax. Normalize once inside Accrue. [VERIFIED: codebase grep]
- **Creating a custom tax-calculation layer:** Stripe Tax owns calculation and jurisdiction logic; Accrue should only express intent and observe results. [CITED: https://docs.stripe.com/tax/set-up]
- **Adding 1:1 local columns for every Stripe tax field:** Stripe tax objects are evolving; local schemas should stay narrow. [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations]
- **Making Fake “tax aware” only through ad hoc scripted responses:** Fake should natively emit deterministic enabled/disabled tax payloads so core tests stay simple and provider-parity drift is visible. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tax calculation | Custom rate/jurisdiction engine | Stripe Tax automatic tax on Subscription / Checkout / Invoice flows | Jurisdiction rules, registrations, and rate changes are Stripe’s domain here; custom logic creates compliance and maintenance risk. [CITED: https://docs.stripe.com/tax/set-up] |
| Stripe resource modeling | Local structs for every tax sub-object | `lattice_stripe` models plus raw payload retention | The installed wrapper already exposes `automatic_tax`, `total_details`, and tax-related invoice fields. [VERIFIED: codebase grep] |
| Test doubles for tax flows | Mocks around Stripe SDK calls | `Accrue.Processor.Fake` plus focused integration tests | The repo’s existing testing strategy is Fake-first and already resets deterministic processor state through `BillingCase`. [VERIFIED: codebase grep] |
| Checkout session persistence | New `checkout_sessions` DB table for Phase 18 | `%Accrue.Checkout.Session{}` projection plus existing webhook/event records | The repo does not persist checkout sessions today, and Phase 18’s success criteria do not require a new table. [VERIFIED: codebase grep] |

**Key insight:** The safest plan is to widen the existing processor/projection seam slightly, not to introduce a new “tax subsystem.” [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/set-up]

## Common Pitfalls

### Pitfall 1: Treating tax enablement as only a request concern
**What goes wrong:** Stripe calls succeed, but local rows cannot tell whether tax was enabled or whether Stripe considered the automatic-tax state valid. [VERIFIED: codebase grep]
**Why it happens:** Current subscription projection does not extract any automatic-tax fields, and checkout/session projection currently exposes only generic totals and raw data. [VERIFIED: codebase grep]
**How to avoid:** Add a minimal derived projection for automatic-tax state while retaining raw payloads in `data`. [VERIFIED: codebase grep]
**Warning signs:** Tests can assert Stripe params were sent but cannot assert local observability after reconciliation or projection. [VERIFIED: codebase grep]

### Pitfall 2: Overfitting to today’s Stripe invoice tax payload
**What goes wrong:** Local code hard-codes `total_tax_amounts` or top-level tax fields that are already changing in newer Stripe API versions. [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations]
**Why it happens:** Tax payloads look stable until a version upgrade lands. [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations]
**How to avoid:** Keep `data` as the forward-compatible escape hatch and expose only stable derived fields such as enabled/status/tax total that the product actually needs. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations]
**Warning signs:** Planning starts with “add columns for every field under `automatic_tax`, `total_details`, and `tax_amounts`.” [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations]

### Pitfall 3: Making tax enablement implicitly dependent on location capture in this phase
**What goes wrong:** Phase 18 scope expands into customer-address validation and rollout safety work that belongs to Phase 19. [CITED: https://docs.stripe.com/billing/taxes/collect-taxes] [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
**Why it happens:** Stripe docs couple automatic tax to valid customer location, but the roadmap explicitly split core enablement from location and rollout safety. [CITED: https://docs.stripe.com/billing/taxes/collect-taxes] [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
**How to avoid:** In Phase 18, add enablement plumbing and observability only; defer validation UX and migration guidance to Phase 19. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]
**Warning signs:** New work touches customer address forms, recovery UX, or migration docs for existing subscriptions. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md]

### Pitfall 4: Letting Fake and Stripe drift apart on tax shape
**What goes wrong:** Tests pass with Fake but fail in provider-parity mode because Fake omits `automatic_tax`, `total_details.amount_tax`, or invoice tax fields that Stripe returns. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/api/checkout/sessions/retrieve?__=]
**Why it happens:** Fake currently returns simple checkout and subscription shapes with no tax modeling. [VERIFIED: codebase grep]
**How to avoid:** Add native Fake payload fields for tax-enabled and tax-disabled flows and update fixtures to cover both. [VERIFIED: codebase grep]
**Warning signs:** Tests must use `scripted_response/2` just to represent ordinary tax-enabled success paths. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and the current codebase:

### Subscription creation with automatic tax
```elixir
# Source: https://docs.stripe.com/billing/taxes/collect-taxes
%{
  customer: customer.processor_id,
  items: [%{price: price_id, quantity: quantity}],
  automatic_tax: %{enabled: true},
  payment_behavior: "default_incomplete",
  expand: ["latest_invoice.payment_intent"]
}
```

### Checkout Session creation with automatic tax
```elixir
# Source: https://docs.stripe.com/tax/checkout
%{
  "mode" => "subscription",
  "customer" => customer.processor_id,
  "line_items" => [%{"price" => "price_basic_monthly", "quantity" => 1}],
  "automatic_tax" => %{"enabled" => true},
  "success_url" => "https://example.com/success"
}
```

### Existing local projection pattern to preserve raw payload plus selected fields
```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice_projection.ex
invoice_attrs = %{
  processor_id: SubscriptionProjection.get(stripe_inv, :id),
  tax_minor: SubscriptionProjection.get(stripe_inv, :tax),
  data: SubscriptionProjection.to_string_keys(stripe_inv)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat invoice tax as top-level `tax` / `total_tax_amounts` forever | Stripe is moving invoice tax modeling toward `taxes` / `total_taxes` in newer API versions | 2025-03-31 (`2025-03-31.basil`) [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations] | Accrue should not lock Phase 18 to strict 1:1 invoice tax columns. [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations] |
| Wrapper libraries dropping unknown tax fields | `lattice_stripe` preserves unknown `automatic_tax` fields in `extra` on invoice/subscription automatic-tax structs | Present in `lattice_stripe` `1.1.0` [VERIFIED: codebase grep] | Forward compatibility is better if Accrue keeps raw payloads and avoids over-modeling. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Full reliance on `invoice.total_tax_amounts` as the long-term canonical breakdown is outdated for newer Stripe API versions. [CITED: https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None | — | — |

All claims in this research were verified or cited — no user confirmation needed.

## Open Questions (RESOLVED)

1. **Resolved: what exact public option name should Accrue standardize on?**
   - Decision: Phase 18 standardizes on `automatic_tax: true | false` for both `Accrue.Billing.subscribe/3` and `Accrue.Checkout.Session.create/1`. [VERIFIED: codebase grep]
   - Why: The repo already favors flat keyword options on billing actions and `NimbleOptions`-validated flat inputs on checkout; `automatic_tax` matches Stripe terminology without leaking nested Stripe request maps into the public API. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/set-up]
   - Plan alignment: `18-01-PLAN.md` and `18-04-PLAN.md` both require a boolean-only `automatic_tax` option and explicitly reject caller-supplied nested Stripe maps. [VERIFIED: codebase grep]

2. **Resolved: which automatic-tax fields deserve first-class DB columns in Phase 18?**
   - Decision: Phase 18 adds only `automatic_tax` and `automatic_tax_status` columns to `accrue_subscriptions` and `accrue_invoices`, while continuing to use existing invoice `tax_minor` plus raw `data` for forward-compatible tax amount detail. [VERIFIED: codebase grep]
   - Why: This preserves enabled/status observability without locking Accrue to a 1:1 Stripe tax schema, and it keeps richer invalid-location UX and rollout handling in Phase 19 where the roadmap already places it. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] [CITED: https://docs.stripe.com/billing/taxes/collect-taxes]
   - Plan alignment: `18-03-PLAN.md` creates the migration and projection work around exactly those columns, while checkout continues to project `amount_tax` from the returned session struct without adding a checkout table in Phase 18. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build/test | ✓ | `1.19.5` | — |
| Mix | Build/test | ✓ | `1.19.5` | — |
| PostgreSQL CLI (`psql`) | Local test DB workflows | ✓ | `14.17` | — |
| Hex package registry access | Version verification | ✓ | live HTTP | — |
| Context7 CLI | Optional doc lookup | ✗ (quota exceeded) | — | Official Stripe docs + local dependency source |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment probe]

**Missing dependencies with fallback:**
- Context7 CLI quota is exhausted for this session, but official Stripe docs and local `deps/lattice_stripe` source were sufficient for this phase research. [VERIFIED: local environment probe]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Ecto SQL Sandbox + Fake processor [VERIFIED: codebase grep] |
| Config file | `/Users/jon/projects/accrue/accrue/test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/checkout_test.exs test/accrue/billing/subscription_test.exs test/accrue/billing/invoice_projection_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `cd accrue && mix test.all` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TAX-01 | `subscribe/3` accepts tax-enabled and tax-disabled creation without breaking existing callers | integration | `cd accrue && mix test test/accrue/billing/subscription_test.exs` | ✅ |
| TAX-01 | `Checkout.Session.create/1` accepts tax-enabled and tax-disabled session creation and exposes session tax fields | integration | `cd accrue && mix test test/accrue/checkout_test.exs` | ✅ |
| TAX-01 | Projection code preserves automatic-tax state and tax amounts from Stripe/Fake payloads | unit | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs` | ✅ |
| TAX-01 | Processor adapters pass through automatic-tax intent consistently | unit | `cd accrue && mix test test/accrue/processor/fake_test.exs test/accrue/processor/stripe_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `cd accrue && mix test test/accrue/checkout_test.exs test/accrue/billing/subscription_test.exs`
- **Per wave merge:** `cd accrue && mix test.all`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `accrue/test/accrue/billing/subscription_tax_test.exs` — dedicated subscription tax enablement coverage for enabled/disabled projection behavior. [VERIFIED: codebase grep]
- [ ] `accrue/test/accrue/checkout_tax_test.exs` or expansion of `checkout_test.exs` — explicit assertions on `automatic_tax` / `amount_tax` projection fields. [VERIFIED: codebase grep]
- [ ] `accrue/test/accrue/billing/invoice_projection_tax_test.exs` or expansion of `invoice_projection_test.exs` — automatic-tax status and future-proof invoice tax payload handling. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Existing auth is out of scope for Phase 18. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] |
| V3 Session Management | no | Phase 18 does not create app auth/session state. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] |
| V4 Access Control | no | Billing ownership rules are unchanged in this phase. [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] |
| V5 Input Validation | yes | Use `NimbleOptions` and existing keyword/map normalization on public APIs. [VERIFIED: codebase grep] [VERIFIED: Hex.pm API] |
| V6 Cryptography | no | No new crypto primitives are introduced; Stripe/webhook signature handling remains unchanged. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] |

### Known Threat Patterns for Stripe Tax orchestration

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Host-supplied tax totals trusted over Stripe payload | Tampering | Accept only a boolean enablement intent from callers; derive actual tax amounts/status from processor payloads. [CITED: https://docs.stripe.com/tax/set-up] [VERIFIED: codebase grep] |
| Sensitive billing/tax details leaking through logs | Information Disclosure | Keep tax work inside the existing processor boundary and avoid logging raw Stripe payloads with customer address details. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] [VERIFIED: codebase grep] |
| Fake/Stripe mismatch hiding provider drift | Repudiation | Add deterministic Fake tax fields and keep optional live-Stripe parity lane separate from required tests. [VERIFIED: codebase grep] |
| Silent invalid automatic-tax state | Denial of Service | Persist or preserve `automatic_tax.status` for observability now, then add recovery UX in Phase 19. [CITED: https://docs.stripe.com/billing/taxes/collect-taxes] [VERIFIED: /Users/jon/projects/accrue/.planning/ROADMAP.md] |

## Sources

### Primary (HIGH confidence)
- https://docs.stripe.com/tax/set-up - verified that API integrations enable tax by sending `automatic_tax[enabled]=true` and that existing recurring items are not retroactively updated.
- https://docs.stripe.com/billing/taxes/collect-taxes - verified subscription automatic-tax flow, preview guidance, and `automatic_tax.status` semantics.
- https://docs.stripe.com/tax/checkout - verified checkout-session automatic-tax request patterns for existing and new customers.
- https://docs.stripe.com/api/checkout/sessions/retrieve?__= - verified Checkout Session response fields `automatic_tax` and `total_details.amount_tax`.
- https://docs.stripe.com/changelog/basil/2025-03-31/invoice-tax-configurations - verified Stripe’s invoice tax model changes and why Phase 18 should avoid 1:1 local tax schemas.
- https://hex.pm/api/packages/lattice_stripe - verified current `lattice_stripe` version and publish date.
- https://hex.pm/api/packages/nimble_options - verified current `nimble_options` version and publish date.

### Secondary (MEDIUM confidence)
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex` - verified current subscribe flow and option normalization surface.
- `/Users/jon/projects/accrue/accrue/lib/accrue/checkout/session.ex` - verified checkout session boundary, current struct fields, and request builder shape.
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_projection.ex` - verified existing subscription projection behavior and raw `data` retention.
- `/Users/jon/projects/accrue/accrue/lib/accrue/billing/invoice_projection.ex` - verified existing invoice tax projection behavior.
- `/Users/jon/projects/accrue/accrue/lib/accrue/processor/fake.ex` - verified Fake currently lacks native automatic-tax modeling.
- `/Users/jon/projects/accrue/accrue/deps/lattice_stripe/lib/lattice_stripe/checkout/session.ex` - verified wrapper support for Checkout Session `automatic_tax` and `total_details`.
- `/Users/jon/projects/accrue/accrue/deps/lattice_stripe/lib/lattice_stripe/invoice/automatic_tax.ex` - verified wrapper support for invoice/subscription automatic-tax structs and forward-compatible `extra` fields.

### Tertiary (LOW confidence)
- Context7 CLI lookup was attempted but blocked by monthly quota exhaustion; no unreconciled claims depend solely on that source. [VERIFIED: local environment probe]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified against Hex and the repo lockfiles, and no new dependency choice is required.
- Architecture: MEDIUM - the repo seams are clear, but the exact public option name and the exact minimal derived columns still need plan-level choice.
- Pitfalls: HIGH - they are grounded in current code shape plus current Stripe tax documentation and changelog guidance.

**Research date:** 2026-04-17
**Valid until:** 2026-04-24
