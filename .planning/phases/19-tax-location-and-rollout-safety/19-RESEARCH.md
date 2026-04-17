# Phase 19: Tax Location and Rollout Safety - Research

**Researched:** 2026-04-17
**Domain:** Stripe Tax customer-location validation, invalid-location recovery, and rollout-safe recurring billing behavior
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TAX-02 | Developer can collect and validate customer tax location before creating tax-enabled recurring payments. | Add a public Accrue customer tax-location update path that calls Stripe customer update with `tax.validate_location`, maps `customer_tax_location_invalid` into an actionable Accrue error, and blocks `automatic_tax` subscription creation when the customer location is invalid. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/taxes] [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto] |
| TAX-03 | User or admin can identify and recover from missing or invalid tax location states without silent tax rollout failure. | Persist and surface `automatic_tax.disabled_reason` and `invoice.finalization_failed` / `last_finalization_error.code` state, extend webhook handling for the missing failure events, and add troubleshooting/admin visibility for recovery paths. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/subscriptions/webhooks] |
| TAX-04 | Existing recurring subscriptions have explicit migration guidance before automatic tax rollout. | Add rollout docs that say enabling Stripe Tax or automatic tax does not retroactively update existing subscriptions, invoices, or payment links, and document the explicit migration path for legacy recurring items plus the Checkout existing-customer caveat requiring `customer_update[address]=auto` or `customer_update[shipping]=auto`. [CITED: https://docs.stripe.com/billing/taxes] [CITED: https://docs.stripe.com/payments/checkout/taxes] |
</phase_requirements>

## Summary

Phase 19 should not introduce a new tax subsystem. The right shape is to extend the existing Accrue flow from `Accrue.Billing` to the processor boundary, then project only the narrow invalid-location state that operators need. The key missing seam today is customer tax-location mutation: `Accrue.Billing.create_customer/1` talks to the processor, but `Accrue.Billing.update_customer/2` is local-only, so there is currently no public Accrue path that updates Stripe customer address or `tax.validate_location` before a tax-enabled subscription is created. [VERIFIED: codebase grep]

Stripe’s rules split into two different failure families that the plan needs to treat separately. First, subscription creation and preview flows expect a recognized customer location up front; Stripe recommends setting `tax.validate_location="immediately"` when collecting the address, and invalid data fails with `customer_tax_location_invalid`. Second, if a recurring subscription later loses a valid location, Stripe can finalize invoices without tax, flip automatic tax off, and publish `invoice.updated` plus `customer.subscription.updated`; by contrast, manual/API finalization without a valid location raises `customer_tax_location_invalid` and can emit `invoice.finalization_failed`. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/taxes] [CITED: https://docs.stripe.com/billing/subscriptions/webhooks]

**Primary recommendation:** add a dedicated public customer tax-location update API in `Accrue.Billing`, keep Stripe-specific validation flags inside the processor call, add local visibility for `automatic_tax.disabled_reason` plus invoice finalization errors, and make Fake able to deterministically simulate both “invalid before subscribe” and “became invalid after rollout” cases. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public customer tax-location update and validation | API / Backend | Database / Storage | `Accrue.Billing` already owns customer create/update entry points and telemetry, while the processor boundary owns Stripe request shape. [VERIFIED: codebase grep] |
| Stripe customer address precedence and validation flags | API / Backend | — | Stripe address precedence and `tax.validate_location` are provider rules and belong inside `Accrue.Processor.Stripe`, not host LiveView or admin code. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto] |
| Invalid-location observability on subscriptions/invoices | Database / Storage | API / Backend | Local billing rows and projections are the canonical Accrue observability surface for tax state. [VERIFIED: codebase grep] |
| Finalization-failure reconciliation | API / Backend | Database / Storage | `Accrue.Webhook.DefaultHandler` owns async Stripe state reconciliation and is currently the missing place for `invoice.finalization_failed`. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/billing/subscriptions/webhooks] |
| Operator visibility in admin | Frontend Server (SSR) | Database / Storage | `accrue_admin` LiveViews and query modules already render local projections; they should not fetch Stripe directly. [VERIFIED: codebase grep] |
| Rollout and migration guidance | Browser / Client | API / Backend | The user-facing outcome is documentation, but the guidance must be based on Stripe’s recurring-item behavior. [CITED: https://docs.stripe.com/billing/taxes] [CITED: https://docs.stripe.com/payments/checkout/taxes] |

## Project Constraints (from CLAUDE.md)

- Keep the implementation Elixir/Phoenix/Ecto-native and aligned with the existing Stripe-first processor strategy. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Use `lattice_stripe` for Stripe calls and keep provider details behind `Accrue.Processor.Stripe`. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Do not weaken webhook guarantees; signed webhook verification remains mandatory and non-bypassable. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Sensitive Stripe fields must never be logged, and payment/tax PII must not leak into telemetry or copied logs. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- All public entry points should remain inside the existing telemetry/OTel surfaces. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md]
- Fake remains the deterministic primary test surface; live Stripe stays advisory parity coverage. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] [VERIFIED: codebase grep]

## Concrete Accrue Modules Likely Affected

- `accrue/lib/accrue/billing.ex`: add the public customer tax-location API and keep telemetry at the facade. `update_customer/2` is local-only today, so Phase 19 should avoid silently changing its semantics. [VERIFIED: codebase grep]
- `accrue/lib/accrue/billing/customer.ex`: extend the schema only for fields Accrue truly needs locally; Phase 19 intentionally avoids first-class local customer address columns and should store only sanitized or derived customer tax-location summaries if a plan explicitly adds them. [VERIFIED: codebase grep] [ASSUMED]
- `accrue/lib/accrue/processor/stripe.ex`: wire Stripe `Customer.update` / create params for address, shipping, `tax.ip_address`, and `tax.validate_location`. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/api/customers/update?api-version=2025-12-15.preview]
- `accrue/lib/accrue/processor/stripe/error_mapper.ex`: map `customer_tax_location_invalid` into a stable Accrue error surface with safe metadata. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations]
- `accrue/lib/accrue/processor/fake.ex`: simulate deterministic valid/invalid customer tax-location state and post-rollout automatic-tax disable behavior. [VERIFIED: codebase grep]
- `accrue/lib/accrue/billing/subscription_actions.ex`: preflight or fail clearly when `automatic_tax: true` is used against a customer without a valid tax location. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/billing/taxes]
- `accrue/lib/accrue/billing/subscription_projection.ex` and `accrue/lib/accrue/billing/invoice_projection.ex`: project `automatic_tax.disabled_reason` in addition to today’s `enabled/status` fields. Current code ignores the disabled-reason path that Stripe uses for recurring invalid-location rollback. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations]
- `accrue/lib/accrue/billing/subscription.ex` and `accrue/lib/accrue/billing/invoice.ex`: add additive columns if the plan chooses first-class disabled-reason/finalization-error observability. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations]
- `accrue/lib/accrue/webhook/default_handler.ex`: handle `invoice.finalization_failed`; broad `customer.updated` reconciliation stays out of scope for Phase 19 unless a plan explicitly adds it because invalid-location visibility is expected to come from explicit public update paths plus invoice/subscription webhook projections. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/billing/subscriptions/webhooks]
- `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `invoice_live.ex`, `subscription_live.ex`, `customers_live.ex`, `invoices_live.ex`, `subscriptions_live.ex`, and their query modules: surface tax-location risk and make it filterable/searchable without raw JSON spelunking. [VERIFIED: codebase grep]
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` and host tests: add a public user path to collect/update tax location before starting a tax-enabled subscription. [VERIFIED: codebase grep]
- `accrue/guides/troubleshooting.md`, `guides/testing-live-stripe.md`, and tax/checkout guides: add explicit rollout and recovery docs. [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Accrue.Billing` facade + `Accrue.Processor` boundary | repo-local | Public API and provider isolation for customer/subscription lifecycle. | This is already the package’s stable write surface and the correct place to preserve provider boundaries. [VERIFIED: codebase grep] |
| `lattice_stripe` | `1.1.0` in `accrue/mix.lock` | Stripe API transport for customer, subscription, invoice, and checkout calls. | Accrue already depends on it and Phase 19 should extend the existing Stripe adapter rather than introduce direct HTTP calls. [VERIFIED: accrue/mix.lock] [VERIFIED: codebase grep] |
| Ecto projections (`Customer`, `Subscription`, `Invoice`) | repo-local | Persist narrow local observability and raw provider payloads. | Phase 18 already uses this pattern for automatic-tax visibility; Phase 19 should keep extending it. [VERIFIED: codebase grep] |

### Supporting
| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `Accrue.Processor.Fake` | repo-local | Deterministic provider parity for tax-location failure and recovery tests. | Use for all required Phase 19 tests and as the canonical local verification path. [VERIFIED: codebase grep] |
| `Accrue.Webhook.DefaultHandler` | repo-local | Canonical async reconciliation path for Stripe events. | Use whenever Stripe documents state changes that arrive by webhook rather than immediate request/response. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/billing/subscriptions/webhooks] |
| `accrue_admin` LiveViews + query modules | repo-local | Local operator visibility for customer, subscription, and invoice tax state. | Use for TAX-03 visibility instead of building direct Stripe-admin fetches. [VERIFIED: codebase grep] |
| `nimble_options` | `1.1.1` in `accrue/mix.lock` | Input validation for public option surfaces. | Keep using it for any new public API shape that accepts structured location input. [VERIFIED: accrue/mix.lock] [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated customer tax-location API in `Accrue.Billing` | Extend `update_customer/2` to also call Stripe | Reusing `update_customer/2` is smaller, but it changes current local-only semantics and makes rollout riskier for existing callers. [VERIFIED: codebase grep] [ASSUMED] |
| First-class `automatic_tax_disabled_reason` columns | Raw JSON only in `data` | Raw JSON is cheaper, but TAX-03 calls for visible invalid-location state in projections/admin surfaces, which is hard to operationalize without a derived field or query helper. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations] |

**Installation:**
```bash
# No new Hex packages are required for Phase 19.
```

**Version verification:** Existing stack versions already present in the repo and verified this session: `lattice_stripe 1.1.0`, `nimble_options 1.1.1`, `oban 2.21.1`. [VERIFIED: accrue/mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Host public billing UI / host controller
        |
        v
Accrue.Billing.update_customer_tax_location/2   [recommended new API]
        |
        +--> validate public opts / normalize address input
        |
        v
Accrue.Processor.update_customer/3
        |
        +--> Stripe: customer address/shipping/tax.validate_location
        |         |
        |         +--> success: canonical customer state
        |         +--> invalid: customer_tax_location_invalid
        |
        v
local Customer projection + event row
        |
        +--> later subscribe/preview/finalize
                  |
                  +--> success: automatic tax active
                  +--> invalid at creation: request error
                  +--> invalid after rollout: webhook/event path
                                      |
                                      v
                         Accrue.Webhook.DefaultHandler
                                      |
                                      v
                  Subscription / Invoice projections + admin/docs visibility
```

### Recommended Project Structure

```text
accrue/lib/accrue/
├── billing.ex                          # public billing facade
├── billing/customer.ex                 # customer schema / local persistence
├── billing/subscription_actions.ex     # tax-enabled subscribe preconditions
├── billing/subscription_projection.ex  # disabled_reason projection
├── billing/invoice_projection.ex       # finalization / disabled_reason projection
├── processor/stripe.ex                 # Stripe request shaping
├── processor/stripe/error_mapper.ex    # Stripe error -> Accrue error
├── processor/fake.ex                   # deterministic invalid-location behavior
└── webhook/default_handler.ex          # async recovery/failure visibility

accrue_admin/lib/accrue_admin/
├── live/*.ex                           # customer/subscription/invoice visibility
└── queries/*.ex                        # filterable tax-risk rows

accrue/guides/
└── troubleshooting.md                  # recovery and rollout guidance
```

### Pattern 1: Dedicated Customer Tax-Location Update API
**What:** Add a new public Accrue API specifically for updating provider-backed customer tax location, instead of overloading the current local-only `update_customer/2`. [VERIFIED: codebase grep] [ASSUMED]
**When to use:** Before creating a tax-enabled subscription, after the host collects a billing or shipping address, and when recovering from `customer_tax_location_invalid`. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/taxes]
**Recommended API shape:** `Accrue.Billing.update_customer_tax_location(customer, attrs, opts \\ [])` where `attrs` accepts `:address`, optional `:shipping`, optional `:tax_ip_address`, and a validated `:validate_location` policy that Accrue maps to Stripe inside the processor. Keep `:validate_location` defaulted by call site, not globally hidden. For address collection, use `:immediately`; for later maintenance on tax-enabled subscriptions, prefer `:auto` when the Stripe API version supports it. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto] [CITED: https://docs.stripe.com/api/customers/update?api-version=2025-12-15.preview] [ASSUMED]
**Example:**
```elixir
# Source: existing Accrue Billing facade pattern + Stripe customer validation docs
attrs = %{
  address: %{
    line1: "27 Fredrick Ave",
    city: "Brothers",
    state: "OR",
    postal_code: "97712",
    country: "US"
  },
  validate_location: :immediately
}

case Accrue.Billing.update_customer_tax_location(customer, attrs) do
  {:ok, customer} -> {:ok, customer}
  {:error, %Accrue.TaxLocationError{} = error} -> {:error, error}
end
```

### Pattern 2: Project Both `status` and `disabled_reason`
**What:** Keep the Phase 18 `automatic_tax` and `automatic_tax_status` fields, but add derived observability for `automatic_tax.disabled_reason` on subscriptions and invoices because Stripe uses that field when recurring automatic tax gets turned off after customer-location loss. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations]
**When to use:** In projections, admin queries, and troubleshooting copy. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: Stripe recurring invalid-location behavior + existing projection style
automatic_tax = SubscriptionProjection.get(stripe_inv, :automatic_tax) || %{}

invoice_attrs = %{
  automatic_tax: get(automatic_tax, :enabled) || false,
  automatic_tax_status: get(automatic_tax, :status),
  automatic_tax_disabled_reason: get(automatic_tax, :disabled_reason)
}
```

### Pattern 3: Recovery Through Explicit Public Paths, Not Stripe Dashboard Assumptions
**What:** Recovery should be documented and testable through Accrue public surfaces: update customer location, retry/finalize when applicable, or explicitly disable automatic tax on the affected recurring objects when no valid address is available. [CITED: https://docs.stripe.com/tax/customer-locations]
**When to use:** TAX-03 troubleshooting flows and TAX-04 rollout docs. [CITED: https://docs.stripe.com/tax/customer-locations]

### Anti-Patterns to Avoid
- **Changing `update_customer/2` semantics silently:** current callers expect a local row update only. [VERIFIED: codebase grep]
- **Relying on `automatic_tax_status` alone:** Stripe uses `disabled_reason` for the recurring auto-disable path, so status alone misses the failure cause. [CITED: https://docs.stripe.com/tax/customer-locations]
- **Trusting Checkout to update existing customer addresses automatically:** Checkout requires explicit `customer_update[address]=auto` or `customer_update[shipping]=auto` for existing customers. [CITED: https://docs.stripe.com/payments/checkout/taxes]
- **Persisting full address PII everywhere:** the project already strips address/phone/shipping from initial customer `data` and blocks address from OTel attributes. [VERIFIED: codebase grep]

## Stripe Semantics That Matter for Planning

### Customer location precedence

For Billing, Subscriptions, and custom integrations, Stripe Tax uses the first viable location in this order: customer shipping address, then customer billing address, then billing details from the most specific default payment method, then IP address. If a shipping or billing address is present but invalid, Stripe raises `customer_tax_location_invalid` instead of falling through to the next source. [CITED: https://docs.stripe.com/tax/customer-locations]

### `tax.validate_location` choices

Stripe’s customer update API currently documents `auto`, `deferred`, and `immediately`; in the preview reference opened today, `auto` is the default and recommended value, `deferred` is deprecated, and `immediately` fails the request if the tax location is invalid. Stripe’s October 28, 2024 changelog introduced `auto` specifically for customer updates, while Stripe’s customer-location guide still recommends `immediately` during address collection to prevent later failures. [CITED: https://docs.stripe.com/api/customers/update?api-version=2025-12-15.preview] [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto] [CITED: https://docs.stripe.com/tax/customer-locations]

**Planning interpretation:** use `immediately` for the public “set/repair tax location” flow that the host calls before tax-enabled subscription creation, and use `auto` only if Accrue later adds a broader generic customer-maintenance path for already-tax-enabled recurring customers. [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto] [ASSUMED]

### `customer_tax_location_invalid`

Stripe uses `customer_tax_location_invalid` for invalid or insufficient customer location in the create/update/finalize paths. Phase 19 should treat it as a first-class domain error with human repair guidance, not a generic API error. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/taxes]

### `automatic_tax.status = requires_location_inputs`

For invoice previews and some invoice calculation flows, Stripe tells you the address is invalid or insufficient by setting `automatic_tax.status` to `requires_location_inputs`. That is the right preflight signal before a user starts a tax-enabled recurring payment. [CITED: https://docs.stripe.com/billing/taxes]

### Recurring invalid-location rollback behavior

If Stripe no longer has a recognized customer location for a subscription invoice, it can finalize the invoice without tax, flip `automatic_tax.enabled` to `false` on the subscription and invoice, set invoice `automatic_tax.disabled_reason` to `finalization_requires_location_inputs`, set subscription `automatic_tax.disabled_reason` to `requires_location_inputs`, and emit `invoice.updated` plus `customer.subscription.updated`. Current Accrue projections do not extract these disabled reasons. [CITED: https://docs.stripe.com/tax/customer-locations] [VERIFIED: codebase grep]

### `invoice.finalization_failed`

Stripe explicitly tells integrators using recurring taxes to listen for `invoice.finalization_failed`. If the invoice `automatic_tax.status` is `requires_location_inputs`, the customer location is invalid or insufficient. Accrue’s default handler does not currently dispatch this event family. [CITED: https://docs.stripe.com/billing/taxes] [VERIFIED: codebase grep]

### Checkout tax address behavior for existing customers

Checkout validates and uses attached customer shipping or billing addresses for existing customers, but it will not automatically overwrite existing customer addresses unless the session sets `customer_update[address]=auto` or `customer_update[shipping]=auto`. That matters for TAX-04 docs because merely turning on automatic tax for Checkout is not a migration strategy for already-created customers or payment links. [CITED: https://docs.stripe.com/payments/checkout/taxes]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tax address validity rules | Homegrown country/postal/state validator | Stripe `tax.validate_location` + invoice preview status | Stripe’s country-specific rules and fallback behavior are product logic, not stable app logic. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/taxes] |
| Recurring invalid-location detection | Custom heuristics over old local rows | Stripe webhook events + `automatic_tax` fields | Stripe changes automatic-tax state asynchronously and documents specific event families for it. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/subscriptions/webhooks] |
| Rollout migration script for legacy recurring objects | Bulk blind SQL/update job in Accrue | Explicit documentation and operator-run migration steps | Stripe’s docs say existing subscriptions and payment links need explicit update paths; accidental blanket mutation is high-risk. [CITED: https://docs.stripe.com/billing/taxes] [CITED: https://docs.stripe.com/payments/checkout/taxes] |

**Key insight:** Stripe already owns location validation and the recurring rollback semantics. Accrue should orchestrate, map, persist, and explain them, not reimplement them. [CITED: https://docs.stripe.com/tax/customer-locations]

## Common Pitfalls

### Pitfall 1: Updating only the local customer row
**What goes wrong:** The host thinks the customer now has a valid tax address, but Stripe still sees the old or missing address. [VERIFIED: codebase grep]
**Why it happens:** `Accrue.Billing.update_customer/2` currently updates only the local row and records an event. [VERIFIED: codebase grep]
**How to avoid:** Introduce a dedicated processor-backed customer tax-location update path. [VERIFIED: codebase grep] [ASSUMED]
**Warning signs:** Tests pass by asserting only `accrue_customers.data` or local changesets with no processor interaction. [VERIFIED: codebase grep]

### Pitfall 2: Treating all invalid-location failures as the same
**What goes wrong:** Recovery logic is wrong because manual finalization failures and subscription auto-disable behavior are conflated. [CITED: https://docs.stripe.com/tax/customer-locations]
**Why it happens:** Stripe uses both hard request errors and async recurring rollback behavior. [CITED: https://docs.stripe.com/tax/customer-locations]
**How to avoid:** Model both cases separately in Fake, projections, webhook handling, and docs. [CITED: https://docs.stripe.com/tax/customer-locations] [ASSUMED]
**Warning signs:** Plan language says only “surface `requires_location_inputs`” and ignores `disabled_reason` or `invoice.finalization_failed`. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/taxes]

### Pitfall 3: Logging address or raw Stripe errors
**What goes wrong:** Address PII leaks into logs, telemetry, traces, or copied CI failures. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] [VERIFIED: codebase grep]
**Why it happens:** Raw Stripe customer/update errors can include address context and current code preserves raw processor errors on exceptions. [VERIFIED: codebase grep]
**How to avoid:** Sanitize tax-location errors into stable codes/messages and keep address fields out of telemetry metadata and docs examples. [VERIFIED: codebase grep] [ASSUMED]
**Warning signs:** New tests assert on full `processor_error` structs or docs tell users to inspect raw logs for addresses. [VERIFIED: codebase grep] [ASSUMED]

### Pitfall 4: Assuming Checkout rollout updates old customers automatically
**What goes wrong:** Existing customers keep stale addresses, taxes remain wrong or disabled, and rollout appears flaky. [CITED: https://docs.stripe.com/payments/checkout/taxes]
**Why it happens:** Checkout only copies new address data back to existing customers when `customer_update[...]` is set. [CITED: https://docs.stripe.com/payments/checkout/taxes]
**How to avoid:** Document explicit customer-update settings for Checkout and separate that from the non-Checkout public Accrue API path. [CITED: https://docs.stripe.com/payments/checkout/taxes] [ASSUMED]
**Warning signs:** Rollout docs only say “enable automatic tax on Checkout” with no customer-update caveat. [CITED: https://docs.stripe.com/payments/checkout/taxes]

### Pitfall 5: Forgetting legacy recurring-item migration guidance
**What goes wrong:** Teams enable Stripe Tax and assume existing subscriptions, invoices, or payment links are now covered automatically. [CITED: https://docs.stripe.com/billing/taxes] [CITED: https://docs.stripe.com/payments/checkout/taxes]
**Why it happens:** New-flow setup docs are easy to confuse with rollout docs. [CITED: https://docs.stripe.com/billing/taxes]
**How to avoid:** Add a dedicated rollout section that explicitly distinguishes new flows from existing recurring objects. [CITED: https://docs.stripe.com/billing/taxes] [CITED: https://docs.stripe.com/payments/checkout/taxes]
**Warning signs:** Docs mention “turn on Stripe Tax” without any “existing recurring items” section. [CITED: https://docs.stripe.com/billing/taxes]

## Code Examples

Verified patterns from official sources and current Accrue seams:

### Stripe customer update with immediate validation
```bash
# Source: https://docs.stripe.com/billing/taxes
curl https://api.stripe.com/v1/customers/{{CUSTOMER_ID}} \
  -u "<>:" \
  -d "address[line1]"="27 Fredrick Ave" \
  -d "address[city]"="Brothers" \
  -d "address[state]"="OR" \
  -d "address[postal_code]"="97712" \
  -d "address[country]"="US" \
  -d "tax[validate_location]"=immediately
```

### Stripe invoice preview preflight for address sufficiency
```bash
# Source: https://docs.stripe.com/billing/taxes
curl https://api.stripe.com/v1/invoices/create_preview \
  -u "<>:" \
  -d "automatic_tax[enabled]"=true \
  -d "customer_details[address][postal_code]"="97712" \
  -d "customer_details[address][country]"="US" \
  -d "subscription_details[items][0][price]"="{{PRICE_ID}}"
```

### Existing-customer Checkout session that copies shipping back to the customer
```bash
# Source: https://docs.stripe.com/payments/checkout/taxes
curl https://api.stripe.com/v1/checkout/sessions \
  -u "<>:" \
  -d "automatic_tax[enabled]"=true \
  -d "customer"="{{CUSTOMER_ID}}" \
  -d "customer_update[shipping]"=auto \
  -d "shipping_address_collection[allowed_countries][0]=US" \
  -d mode=subscription
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Customer update validation defaulted to `deferred` in older customer update docs. [CITED: https://docs.stripe.com/api/customers/update?api-version=2024-06-20] | Stripe’s current preview customer update docs show `auto` as the default, recommended option, and mark `deferred` deprecated. [CITED: https://docs.stripe.com/api/customers/update?api-version=2025-12-15.preview] | `auto` added on 2024-10-28. [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto] | Phase 19 should not hardcode old `deferred` behavior into new API design. [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto] |
| Phase 18 projected only `automatic_tax` and `automatic_tax_status`. [VERIFIED: codebase grep] | Phase 19 needs `disabled_reason` and finalization-failure visibility for rollout-safe recurring tax behavior. [CITED: https://docs.stripe.com/tax/customer-locations] | Stripe recurring invalid-location docs already rely on `disabled_reason`. [CITED: https://docs.stripe.com/tax/customer-locations] | Admin/docs/projections must evolve beyond the Phase 18 fields. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating `tax.validate_location=deferred` as the forward-looking default is outdated for new update-path design. [CITED: https://docs.stripe.com/api/customers/update?api-version=2025-12-15.preview] [CITED: https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A new public API named `update_customer_tax_location/2` is the safest Accrue surface, rather than extending `update_customer/2`. | Architecture Patterns | Medium: plan might choose a different API shape or split it across host/admin surfaces. |
| A2 | Accrue should avoid storing full postal address PII in first-class customer columns unless a concrete query/UI requirement appears. | Concrete Accrue Modules Likely Affected | Medium: if admin UX requires structured address display/search, the schema plan changes. |
| A3 | Fake should simulate both pre-subscribe hard failure and post-rollout auto-disable behavior for invalid locations. | Summary / Common Pitfalls | Low: even if exact Fake mechanics differ, deterministic coverage is still required. |

## Open Questions (RESOLVED)

1. **Should Phase 19 persist any customer tax-location summary locally beyond raw provider data?**
   - Resolution: Phase 19 intentionally avoids first-class local customer address columns. Tax risk is projected through subscription and invoice fields, and customer-level persistence is limited to sanitized or derived tax-location summaries only if a plan explicitly adds them. [VERIFIED: codebase grep] [ASSUMED]

2. **Should `customer.updated` webhook reconciliation become real in Phase 19 or stay out of scope?**
   - Resolution: Phase 19 does not need broad `customer.updated` reconciliation unless a plan explicitly uses it. Invalid-location visibility comes from the explicit public customer tax-location update path plus invoice and subscription webhook projections, not from general customer webhook mirroring. [VERIFIED: codebase grep] [ASSUMED] [CITED: https://docs.stripe.com/payments/checkout/taxes]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core repo tests and compilation | ✓ | `1.19.5` | — |
| Mix | Test/verification commands | ✓ | `1.19.5` | — |
| Node.js | `accrue_admin` asset/test tasks if admin LiveView changes land | ✓ | `v22.14.0` | Avoid asset changes if not needed |
| npm | `accrue_admin` JS/CSS workflows | ✓ | `11.1.0` | Avoid asset rebuilds if LiveView markup-only changes are sufficient |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: local command checks]

**Missing dependencies with fallback:**
- Live Stripe credentials were not audited because Fake-backed coverage is the required phase gate; provider-parity coverage can remain advisory. [VERIFIED: codebase grep] [ASSUMED]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL sandbox and repo-local support modules. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/processor/fake_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `cd accrue && mix test && cd ../accrue_admin && mix test && cd ../examples/accrue_host && mix test` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TAX-02 | Public customer tax-location update validates location and blocks tax-enabled recurring create on invalid data | unit + integration | `cd accrue && mix test test/accrue/processor/stripe_test.exs test/accrue/processor/fake_test.exs test/accrue/billing/tax_location_test.exs` | ✅ planned in 19-01 and 19-02 |
| TAX-03 | Invalid-location rollback and finalization failure are visible in projections, webhook paths, admin surfaces, and the host repair flow | integration + LiveView | `cd accrue && mix test test/accrue/billing/invoice_projection_test.exs test/accrue/billing/subscription_projection_tax_test.exs test/accrue/webhook/default_handler_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoice_live_test.exs && cd ../examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs` | ✅ planned in 19-03 and 19-04 |
| TAX-04 | Docs explain legacy recurring-item rollout and Checkout existing-customer caveats | docs + regression | `cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs test/accrue/docs/tax_rollout_docs_test.exs` | ✅ planned in 19-05 |

### Sampling Rate
- **Per task commit:** targeted `mix test` for the touched package. [VERIFIED: codebase grep]
- **Per wave merge:** package-local full suite for every touched package. [VERIFIED: codebase grep]
- **Phase gate:** `accrue`, `accrue_admin`, and `examples/accrue_host` green on the final Phase 19 touch set. [VERIFIED: codebase grep] [ASSUMED]

### Wave 0 Expectations
- Phase 19 does not require a separate pre-execution Wave 0 scaffold plan. Each plan creates or extends its own verification files in-task.
- 19-01 verifies processor behavior in `accrue/test/accrue/processor/stripe_test.exs` and `accrue/test/accrue/processor/fake_test.exs`.
- 19-02 creates `accrue/test/accrue/billing/tax_location_test.exs` as the focused public API proof for TAX-02.
- 19-03 extends `accrue/test/accrue/billing/subscription_projection_tax_test.exs`, `accrue/test/accrue/billing/invoice_projection_test.exs`, and `accrue/test/accrue/webhook/default_handler_test.exs`.
- 19-04 extends the existing admin and host test files named in the plan instead of introducing new package-level Wave 0 test scaffolds.
- 19-05 extends `accrue/test/accrue/docs/troubleshooting_guide_test.exs` and adds `accrue/test/accrue/docs/tax_rollout_docs_test.exs`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app auth already owns who can reach public billing/admin surfaces. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] |
| V3 Session Management | no | No new session mechanism is introduced in this phase. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Public billing actions stay row-scoped by billable ownership and admin stays behind host-owned auth adapters. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Use `NimbleOptions`, Ecto changesets, and provider-side `tax.validate_location`; do not trust client-supplied address completeness. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/api/customers/update?api-version=2025-12-15.preview] |
| V6 Cryptography | no | No new cryptographic primitive is introduced; webhook signature verification remains existing mandatory behavior. [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Address PII leaked in logs/errors | Information Disclosure | Keep address out of telemetry attributes, avoid logging raw Stripe error bodies, and sanitize tax-location errors before surfacing them. [VERIFIED: codebase grep] [VERIFIED: /Users/jon/projects/accrue/CLAUDE.md] |
| Host bypasses processor validation and stores an unverified address locally | Tampering | Force the public tax-location update path through `Accrue.Processor.update_customer/3` with `tax.validate_location`. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations] |
| Admin/operator cannot see silent tax disable and keeps collecting untaxed invoices | Repudiation | Persist disabled/failure state locally, show it in admin, and keep troubleshooting docs explicit. [CITED: https://docs.stripe.com/tax/customer-locations] [VERIFIED: codebase grep] |
| Raw Stripe customer error copied into CI or issue trackers | Information Disclosure | Assert on stable Accrue error codes/messages in tests and docs, not on raw provider structs with possible address data. [VERIFIED: codebase grep] [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- Stripe customer location guide: https://docs.stripe.com/tax/customer-locations
- Stripe recurring tax guide: https://docs.stripe.com/billing/taxes
- Stripe subscription webhook guide: https://docs.stripe.com/billing/subscriptions/webhooks
- Stripe Checkout tax guide: https://docs.stripe.com/payments/checkout/taxes
- Stripe changelog (`auto` validation): https://docs.stripe.com/changelog/acacia/2024-10-28/tax-validate-location-auto
- Stripe changelog (address validation update): https://docs.stripe.com/changelog/basil/2025-04-30/updated-address-validations-for-tax
- Stripe customer update API reference opened in this session: https://docs.stripe.com/api/customers/update?api-version=2025-12-15.preview
- Accrue codebase grep across billing, processor, webhook, admin, guides, and tests. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- None. Primary sources and codebase evidence were sufficient. [VERIFIED: this research session]

### Tertiary (LOW confidence)
- None. Remaining uncertainty is captured as explicit assumptions, not unsupported facts. [VERIFIED: this research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 19 uses the existing Accrue/Stripe stack already present in the repo. [VERIFIED: codebase grep] [VERIFIED: accrue/mix.lock]
- Architecture: HIGH - the missing seams are concrete in the current codebase and Stripe’s official docs are explicit about the behaviors Accrue must surface. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations]
- Pitfalls: HIGH - the main failure modes are directly documented by Stripe and visible as gaps in current projections/webhook handling. [CITED: https://docs.stripe.com/tax/customer-locations] [CITED: https://docs.stripe.com/billing/taxes] [VERIFIED: codebase grep]

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 for codebase mapping; re-check Stripe docs sooner if the project upgrades Stripe API behavior.

## RESEARCH COMPLETE

- Add a dedicated public customer tax-location update/validation path before tax-enabled recurring creation. [VERIFIED: codebase grep] [CITED: https://docs.stripe.com/tax/customer-locations]
- Phase 19 must cover both hard validation errors and the recurring “automatic tax got disabled later” path. [CITED: https://docs.stripe.com/tax/customer-locations]
- The biggest code gaps are local-only customer update semantics, missing `disabled_reason` projection, and missing `invoice.finalization_failed` handling. [VERIFIED: codebase grep]
- Fake should model invalid-location behavior deterministically so the required phase gate stays local and reproducible. [VERIFIED: codebase grep] [ASSUMED]
