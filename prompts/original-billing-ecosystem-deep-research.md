# The higher-level billing library landscape across web frameworks

**Only two ecosystems — Ruby and PHP — have mature, framework-integrated billing libraries. Elixir/Phoenix has a clear and well-documented gap.** The Pay gem (Ruby/Rails) and Laravel Cashier (PHP/Laravel) represent the gold standard for "billing-as-a-library" — attaching subscription management, webhook handling, and state synchronization directly to your ORM models. Python's dj-stripe comes close but is a data-sync layer, not a billing abstraction. Java, Node.js, and Go have nothing comparable. The Elixir ecosystem's only attempt, Bling (v0.5), is pre-1.0 with a single maintainer and depends on the staling stripity_stripe. This creates a significant opportunity for a well-designed, actively maintained billing library built on lattice_stripe.

---

## The Elixir/Phoenix ecosystem has exactly one attempt — and a sea of low-level SDKs

The Elixir Stripe landscape is dominated by **stripity_stripe** (v3.2.0, 5.6M all-time downloads, ~3,300 daily), but the library hasn't released since May 2024 and targets Stripe API version **2019-10-17** — over six years behind. ElixirForum threads titled "Is Stripity Stripe maintained?" reflect growing community concern. Several newer low-level SDKs are emerging: **pin_stripe** (built on Req per Dashbit's recommendation), **tiger_stripe** (190 services, 307 resources, fully typed), and **tiny_elixir_stripe** (webhook DSL). All are low-level API wrappers.

The sole higher-level library is **Bling** (v0.5.0, by ozziexsh), explicitly inspired by Laravel Cashier. It provides Ecto schemas for customers and subscriptions, polymorphic billable models, subscription lifecycle management (create, cancel, resume, swap, trial, quantities), webhook handling via Plug, and a `mix bling.install` generator. Its companion **Bankroll** provides a pre-built subscription management UI. A separate **bling_paddle** package covers Paddle. However, Bling is pre-1.0, maintained by a single developer, and depends on stripity_stripe's aging SDK.

ElixirForum threads consistently reveal the gap. In a June 2024 thread "What do you use for payment plans, credits, etc?", a developer writes: *"I failed to figure any standard libraries and advices on how to handle it in Elixir."* Responses suggest using Stripe Billing directly, Chargebee, or Bling — no clear consensus. Multiple paid SaaS boilerplates (Phoenix SaaS Kit, FullStackPhoenix) include billing, but these are templates, not reusable libraries.

**What's missing compared to Pay gem/Cashier:** mature multi-maintainer library, multi-provider support, invoice PDF generation, metered/usage-based billing helpers, Stripe Checkout integration helpers, customer portal integration, admin UI, robust test infrastructure, and up-to-date Stripe API coverage.

---

## Pay gem: the gold standard for developer experience

The Ruby Pay gem (v11.6.1, ~2,200 stars, 1.67M downloads) is the most feature-complete billing library across any ecosystem. Maintained by Chris Oliver (GoRails) and Jason Charnes with **zero open issues** at time of research, it supports **six processors**: Stripe, Braintree, Paddle Billing, Paddle Classic, Lemon Squeezy, and a Fake Processor for testing.

### Domain model: five core tables with polymorphic ownership

Pay creates standalone tables linked to any model via polymorphic associations:

| Table | Key Columns | Purpose |
|-------|------------|---------|
| `pay_customers` | `owner_type/id`, `processor`, `processor_id`, `default`, `data` (JSON), `stripe_account` | Links any model (User, Team) to a payment processor |
| `pay_subscriptions` | `customer_id`, `name`, `processor_id`, `processor_plan`, `quantity`, `status`, `trial_ends_at`, `ends_at`, `current_period_start/end`, `metered`, `pause_behavior`, `object` (JSON) | Full subscription lifecycle |
| `pay_charges` | `customer_id`, `subscription_id`, `processor_id`, `amount`, `amount_refunded`, `currency`, `card_type/last4`, `object` (JSON) | Payment records |
| `pay_payment_methods` | `customer_id`, `processor_id`, `default`, `payment_method_type`, `data` (JSON) | Stored payment instruments |
| `pay_merchants` | `owner_type/id`, `processor`, `processor_id` | Stripe Connect marketplace support |

The `object` JSON column storing full processor API responses is a key design decision — it enables re-syncing without additional API calls. Named subscriptions (`name: "default"`, `name: "addon"`) allow multiple subscriptions per customer.

### DX that developers love

Setup takes three commands: `bundle install`, `rails generate pay:install`, `rails db:migrate`. The core API is beautifully expressive:

```ruby
# Make any model billable
class User < ApplicationRecord
  pay_customer
end

# Subscribe
current_user.set_payment_processor :stripe
current_user.payment_processor.subscribe(plan: "price_xxx")

# Check status
current_user.payment_processor.on_trial_or_subscribed?

# Stripe Checkout
@session = current_user.payment_processor.checkout(
  mode: 'subscription', line_items: "price_xxx",
  success_url: root_url, cancel_url: root_url
)

# Webhook customization
Pay::Webhooks.delegator.subscribe "stripe.checkout.session.completed", FulfillCheckout.new
```

The **Fake Processor** is particularly brilliant — it creates local subscription records for card-less trials and testing without hitting any external API. The webhook handling uses a **delegator pub/sub pattern** where built-in handlers process standard events (subscription created/updated/deleted, charge succeeded/refunded) and developers can subscribe additional handlers for custom logic.

### Pain points from the community

**Migration complexity between major versions** is the most cited issue. The v2→v3 migration moved from columns on the User model to separate tables — a significant rewrite. Column additions, renames (`name` → `type`), and association changes between versions require careful migration planning. **Onboarding confusion** around webhook setup is common: GitHub Discussion #1066 highlighted confusion about whether to manually create customer records or let webhooks handle it (answer: you must associate the Stripe Customer ID before webhooks work). **Processor discrepancies** are acknowledged in Pay's own docs: *"They function differently so keep that in mind... It would be best to stick with a single payment provider."* Paddle and Lemon Squeezy's webhook-only subscription creation model differs fundamentally from Stripe's API-first approach.

### Multi-gateway architecture

Pay uses STI (Single Table Inheritance) — the `processor` column determines which Ruby class handles behavior. Base models define the common interface; STI subclasses (`Pay::Stripe::Subscription`, `Pay::Braintree::Subscription`) override with processor-specific implementations. This works well for Ruby but the abstraction necessarily leaks at the edges.

---

## Laravel Cashier: first-party framework integration with a different philosophy

Laravel Cashier (v16.5.0, ~2,500 stars) takes a fundamentally different architectural approach from Pay: instead of standalone tables with polymorphic associations, it adds **columns directly to the users table** (`stripe_id`, `pm_type`, `pm_last_four`, `trial_ends_at`) and creates separate `subscriptions` and `subscription_items` tables. It uses a PHP **trait** (`Billable`) mixed into the User model, providing ~50+ methods.

The DX mirrors Pay's expressiveness but with PHP flavor:

```php
// Subscribe via Checkout
$user->newSubscription('default', 'price_basic_monthly')
    ->trialDays(5)->allowPromotionCodes()
    ->checkout(['success_url' => route('dashboard')]);

// Per-seat billing
$subscription->updateQuantity(10);

// Invoice PDF generation
$user->downloadInvoice($invoiceId, ['vendor' => 'My Company']);

// Billing portal redirect
$user->redirectToBillingPortal(route('dashboard'));
```

Cashier's **most notable design difference** is that **invoices are NOT stored locally** — they're fetched from Stripe's API on demand. This simplifies the data model but adds latency for users with many invoices. Payment methods are also API-fetched, with only `pm_type` and `pm_last_four` cached on the user.

### Multi-gateway: deliberately separate packages

Laravel intentionally maintains **completely separate packages** for Stripe (`laravel/cashier-stripe`) and Paddle (`laravel/cashier-paddle`) with **no shared interface or abstract class**. Each has its own `Billable` trait, models, migrations, and webhook controller. The API surfaces are similar in spirit but not interchangeable. This was a deliberate choice after early versions tried (and failed) to maintain abstraction parity across Stripe and Braintree. The ecosystem also includes **Lemon Squeezy for Laravel** (by the same maintainer) and community packages for Mollie.

### Key pain points

**State sync** between local DB and Stripe is the most persistent source of bugs — webhooks arriving out of order, failing silently, or being delayed. **Multiple billable models** (User and Team) require significant workarounds since Cashier assumes a single billable model. **No pause support for Stripe** (only Paddle). **No built-in admin UI** — Cashier relies on Stripe's Dashboard and Customer Portal, with community packages for Nova and Filament integration.

**Laravel Spark** ($99/site) sits above Cashier as a higher-level product with pre-built subscription portal UI, plan configuration, and per-seat billing — illustrating that even the best library often needs a UI layer on top.

---

## Python, Java, Node.js, and Go: the gap is ecosystem-wide

**dj-stripe** (Python/Django, ~1,749 stars, 10+ years old) is the most interesting comparison point. Rather than providing subscription management helpers, it **mirrors all Stripe objects as Django models** — syncing via webhooks so developers can query Stripe data through Django's ORM: `Customer.objects.filter(subscriptions__status="active")`. After a decade, its maintainers concluded that keeping 1:1 parity with Stripe's rapidly-changing API was *"clearly no longer a reasonable goal"* — version 2.10 stores key fields as columns but delegates the rest to a `stripe_data` JSON blob with property accessors. This evolution is a crucial design lesson: **start with the JSON blob approach rather than trying to model every Stripe field as a database column**.

dj-stripe is explicitly not a Pay gem equivalent — it provides the data layer but developers must build subscription management flows themselves. **django-payments** (jazzband) offers multi-gateway abstraction for one-time payments but not subscriptions. **No Django library provides `user.subscribe()` / `user.charge()` style helpers.**

**Java/Spring Boot has no higher-level payment library whatsoever.** Developers use `stripe-java` directly, building custom entities, Spring services, and webhook endpoints from scratch. The enterprise Java ecosystem relies on external billing platforms (Kill Bill) or direct SDK integration.

**Node.js has no equivalent either** — the fragmentation across Express, Fastify, Next.js, and Nest.js makes a single "blessed" payment library impossible. Developers use the `stripe` npm package directly or adopt billing-as-a-service platforms (Stigg, Orb, Lago). **Go** follows the same pattern: `stripe-go` directly or external billing engines.

This landscape reveals that **framework-integrated billing libraries are the exception, not the norm**. Only ecosystems with dominant, opinionated frameworks (Rails, Laravel) have produced them. Phoenix, as the dominant Elixir web framework with strong conventions, is naturally positioned for this pattern.

---

## Domain model and key abstractions distilled across ecosystems

### The minimum viable domain model: five tables

Analyzing Pay gem, Cashier, Bling, and dj-stripe, the core domain model converges on five entities:

- **Customer** — Polymorphic link between any billable schema (User, Team, Org) and a payment processor. Key fields: `owner_type/id`, `processor`, `processor_id`, `default`, `data` (JSON).
- **Subscription** — Lifecycle tracking for recurring billing. Key fields: `customer_id`, `processor_id`, `status`, `price_id`, `quantity`, `trial_ends_at`, `ends_at`, `current_period_start/end`, `pause_behavior`, `metadata` (JSON).
- **Charge** — Individual payment records. Key fields: `customer_id`, `subscription_id` (optional), `processor_id`, `amount`, `amount_refunded`, `currency`, `card_type/last4`.
- **PaymentMethod** — Stored payment instruments. Key fields: `customer_id`, `processor_id`, `type`, `default`, `card_last4/exp`.
- **WebhookEvent** — Idempotency tracking. Key fields: `processor_event_id`, `event_type`, `status`, `processed_at`.

The **full surface area** adds SubscriptionItem (multi-price subscriptions), Invoice, Refund, Coupon/Discount, Plan/Price (local mirror), and MeterEvent (usage-based). Most libraries recommend **not** storing Plans/Prices locally — let Stripe be the source of truth for those.

### Core operations every library must support

The essential verbs: **subscribe**, **cancel** (at period end), **cancel_now** (immediately), **resume**, **swap** (change plan), **charge** (one-time), **refund**, and **sync** (webhook-driven state update). Extended operations include **pause/unpause**, **update_quantity** (per-seat), **create_checkout_session**, **create_portal_session**, **extend_trial**, and status predicates: `active?`, `on_trial?`, `canceled?`, `on_grace_period?`, `past_due?`, `paused?`.

### The critical design decision: local state vs. Stripe as source of truth

Three approaches exist across libraries. **The winning pattern** (used by Pay gem and Cashier) stores minimal state locally — just enough to check subscription status without API calls — and uses webhooks as the primary sync mechanism. dj-stripe's full-mirror approach is more powerful for querying but creates a maintenance nightmare keeping up with Stripe's API changes. The key insight from dj-stripe's decade of experience: **use a JSON column (`object` or `stripe_data`) to store the full API response**, with explicit database columns only for fields you need to query or index.

---

## Webhook handling is the highest-value and hardest abstraction

Every ecosystem's developers cite webhook handling as the **single most valuable feature** a billing library can provide, and the single biggest source of bugs when done wrong. The universal architecture pattern:

1. Receive POST → verify signature → return 200 immediately → process asynchronously
2. Track event IDs in a `webhook_events` table with unique constraints for idempotency
3. Use the event to trigger a **sync** — fetch the latest object from Stripe's API (don't trust the webhook payload alone) and upsert the local record
4. Dispatch to registered handlers for custom business logic

**Common webhook pain points** across all ecosystems: events arriving out of order, heavy processing inside the handler causing Stripe timeouts (20 seconds) and triggering retries, "users paid but don't have access" bugs from unhandled events, and the difficulty of testing webhook flows locally. Stripe retries failed webhooks for up to 3 days with exponential backoff.

For Elixir/Phoenix specifically, **Oban** is the natural choice for async webhook processing — receive the webhook in a Plug, verify the signature, enqueue an Oban job, return 200 immediately. Oban provides built-in retry logic, unique job constraints (idempotency), and observability. Phoenix **PubSub** can broadcast billing events to LiveView admin dashboards in real-time.

---

## Admin UIs are companion products, not core library features

No major billing library ships a built-in admin dashboard. Pay gem provides a mountable engine with webhook endpoints and a payment confirmation page, but the actual admin UI lives in **Jumpstart Rails** (the paid starter kit by the same author). Laravel Cashier provides nothing — developers use Stripe's Dashboard, the Customer Portal, or community plugins for Nova/Filament. Bling created **Bankroll** as a separate downloadable companion.

The pattern is clear: **the library provides the backend; the admin UI is a separate, optional layer**. For Elixir/Phoenix, a LiveView-based admin dashboard would be a significant differentiator — real-time subscription status updates, webhook event logs, customer detail panels, and inline actions (cancel, refund, swap). This maps perfectly to Phoenix's strengths.

Admin UIs typically support: customer search/filter, subscription overview with status breakdowns, charge/payment history, refund management, webhook event log with processing status, and basic revenue metrics (MRR, churn, trial conversion).

---

## Multi-gateway support: start Stripe-only, design for extensibility

The evidence from both Pay gem and Laravel Cashier points strongly toward **Stripe-first, multi-gateway later**. Pay's own documentation warns: *"It would be best to stick with a single payment provider"* for complex billing. Laravel deliberately split Cashier into separate packages per processor with no shared interface, acknowledging that abstracting across fundamentally different payment APIs creates leaky abstractions.

The core challenge is that processors differ in fundamental ways:

- Stripe allows API-driven subscription creation; Paddle and Lemon Squeezy require webhook-driven creation via hosted checkout
- Braintree can't swap plans natively (Pay works around this by canceling and recreating)
- Paddle is a Merchant of Record (handles taxes); Stripe is not
- Not all features exist across all processors (metered billing, pause, per-item quantities)

**Recommended approach for Elixir**: Use Elixir's **behaviour** pattern to define a clean processor interface (`subscribe/2`, `cancel/1`, `sync/1`, etc.) that Stripe implements fully. Don't build other adapters until there's demonstrated demand. The behaviour contract ensures the architecture supports future processors without premature abstraction.

---

## The real value proposition: what saves developers meaningful time

The highest-value abstractions, ranked by time saved and bug prevention:

1. **Webhook handling + automatic state sync** — Without this, every developer reinvents fragile webhook processing, idempotency tracking, and state synchronization. This is the #1 reason libraries like Pay gem exist.
2. **Subscription lifecycle helpers** — `subscribe()`, `cancel()`, `swap()`, `resume()` with proper grace period, proration, and trial handling. The edge cases (canceled but in grace period, trial expired but subscription active, past_due but not yet canceled) are subtle and error-prone.
3. **Status predicates** — `active?()`, `on_trial?()`, `on_grace_period?()` seem trivial but encode complex business logic. Getting these wrong means users lose access when they shouldn't (or get free access when they shouldn't).
4. **Database schema + generators** — Pre-built migrations and Ecto schemas with the right columns, indexes, and associations.
5. **Billable model integration** — Adding billing to any Ecto schema (User, Team, Organization) via a clean macro or use statement.
6. **Payment failure resolution** — Pre-built flows for SCA/3DS confirmation when off-session payments fail.
7. **Fake/test processor** — Pay gem's Fake Processor pattern is universally praised: create local subscription records for trials and testing without touching any external API.

Abstractions that **aren't** worth building: full Stripe API wrappers (that's what lattice_stripe does), multi-gateway adapters (premature), custom pricing table UIs (Stripe provides these), and full invoice storage (use Stripe's API).

---

## Conclusion: actionable insights for building the Elixir/Phoenix billing library

The opportunity is real and well-defined. **Only Ruby and PHP have solved this problem at the framework level**, while Python, Java, Node.js, and Go developers are left building everything from scratch. Phoenix's opinionated conventions, Ecto's migration system, LiveView's real-time capabilities, and Oban's job processing create a uniquely strong foundation.

The most important architectural decisions based on cross-ecosystem evidence: **use separate billing tables with polymorphic ownership** (not columns on the user schema, per Pay gem's v3 lesson), **store full Stripe API responses in a JSON column** (per dj-stripe's decade of experience), **process webhooks asynchronously via Oban** (acknowledge immediately, process reliably), and **design the processor interface as a behaviour but implement Stripe only** until multi-gateway demand materializes. The Fake Processor pattern from Pay gem should be a day-one feature — it transforms testing and enables card-less trials elegantly.

The minimum viable surface: Customer + Subscription + Charge + PaymentMethod + WebhookEvent schemas, a `use Billable` macro for any Ecto schema, subscription lifecycle functions (subscribe/cancel/resume/swap/pause), status predicates, webhook processing with idempotency, a `mix billing.install` generator, and clear escape hatches to the underlying lattice_stripe SDK for anything the library doesn't cover. The LiveView admin dashboard and invoice PDF generation are compelling differentiators but can follow v1.