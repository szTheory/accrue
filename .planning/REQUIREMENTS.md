# Requirements: Accrue

**Defined:** 2026-04-11
**Core Value:** A Phoenix developer can install Accrue + accrue_admin and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, with tamper-evident audit, great observability, and zero breaking-change pain through the first major version.

## v1 Requirements

Requirements for the first public release (v1.0). Accrue ships complete — no MVP iteration cycle. Each requirement maps to a roadmap phase and is backed by feature IDs from `research/FEATURES.md`.

### Foundations

- [ ] **FND-01**: `Accrue.Money` value type with zero-decimal and three-decimal currency safety, rejects bare integers at API boundaries
- [ ] **FND-02**: `Accrue.Error` exception hierarchy (`APIError`, `CardError`, `RateLimitError`, `IdempotencyError`, `DecodeError`, `SignatureError`, `ConfigError`)
- [ ] **FND-03**: `Accrue.Config` runtime config via NimbleOptions with auto-generated docs
- [ ] **FND-04**: `Accrue.Telemetry` event naming conventions module (`[:accrue, :domain, :action, :start|:stop|:exception]`)
- [ ] **FND-05**: `Accrue.Application` empty-supervisor pattern (host owns Repo/Oban/Finch lifecycle)
- [ ] **FND-06**: Monorepo layout — sibling mix projects `accrue/` + `accrue_admin/`, independent Hex publishing
- [ ] **FND-07**: Brand palette CSS variables (Ink/Slate/Fog/Paper + Moss/Cobalt/Amber)

### Processor

- [ ] **PROC-01**: `Accrue.Processor` behaviour with callbacks for every Stripe operation Accrue needs
- [x] **PROC-02**: `Accrue.Processor.Stripe` first-party adapter delegating to lattice_stripe 0.3
- [ ] **PROC-03**: `Accrue.Processor.Fake` in-memory ETS adapter — primary test surface (deterministic IDs, test clock, scriptable responses, event-trigger API)
- [ ] **PROC-04**: Deterministic idempotency keys derived from `{operation, subject_id, canonical_params}` with retry-safe reuse
- [x] **PROC-05**: Stripe Connect context (Stripe-Account header) threaded through every processor call
- [ ] **PROC-06**: Per-request API version override
- [ ] **PROC-07**: Stripe error mapping to `Accrue.Error` hierarchy

### Billing Domain

- [ ] **BILL-01**: Polymorphic `Accrue.Billing.Customer` with `owner_type`/`owner_id`, `data` jsonb, default-management, metadata deep-merge
- [ ] **BILL-02**: `use Accrue.Billable` macro — any host schema (User, Organization, Team) becomes billable
- [x] **BILL-03**: `Accrue.Billing.Subscription` create/retrieve/swap/cancel/resume/pause
- [x] **BILL-04**: Subscription state machine: trialing → active → past_due → incomplete/incomplete_expired → unpaid/paused → canceled
- [x] **BILL-05**: Three canonical predicates: `active?/1`, `canceling?/1`, `canceled?/1` (never expose raw `status`)
- [x] **BILL-06**: Trial support with `trial_end` (`:now` or unix timestamp), `trial_will_end` webhook handling
- [x] **BILL-07**: `cancel_at_period_end` with grace period tracking (status stays `active` until period ends)
- [x] **BILL-08**: Immediate cancel with optional final-invoice handling
- [x] **BILL-09**: Plan swap with **explicit** `:proration` option (never silently inherits Stripe's default)
- [x] **BILL-10**: `preview_upcoming_invoice/2` for proration preview UX before swap commits
- [x] **BILL-11**: Pause/resume with `pause_behavior` option
- [x] **BILL-12**: Multi-item subscriptions (SubscriptionItem)
- [x] **BILL-13**: Metered billing via Stripe BillingMeters + MeterEvents
- [x] **BILL-14**: Free-tier / comped subscriptions (no PaymentMethod required)
- [x] **BILL-15**: Dunning / grace period handling with `past_due` → `unpaid` transitions
- [x] **BILL-16**: Subscription Schedules for multi-phase intro pricing
- [x] **BILL-17**: `Accrue.Billing.Invoice` state machine (draft → open → paid | void | uncollectible)
- [x] **BILL-18**: Invoice line items, discounts, tax
- [x] **BILL-19**: `finalize/2`, `void/2`, `mark_uncollectible/2`, `pay/3`, `send/2` workflow actions
- [x] **BILL-20**: `Accrue.Billing.Charge` wrapper with idempotency
- [x] **BILL-21**: `Accrue.Billing.PaymentIntent` with tagged `{:ok, :requires_action, intent}` return for 3DS/SCA
- [x] **BILL-22**: `Accrue.Billing.SetupIntent` for off-session card-on-file
- [x] **BILL-23**: `Accrue.Billing.PaymentMethod` with fingerprint-based dedup
- [x] **BILL-24**: Expiring-card warnings surfaced via telemetry + events
- [x] **BILL-25**: Default-payment-method management per customer
- [x] **BILL-26**: `Accrue.Billing.Refund` with fee-aware schema (`stripe_fee_refunded_amount`, `merchant_loss_amount`)
- [x] **BILL-27**: `Accrue.Billing.Coupon` + `Accrue.Billing.PromotionCode` with customer-facing apply flow
- [x] **BILL-28**: Discount application at subscription, invoice, and checkout-session level

### Checkout + Portal

- [x] **CHKT-01**: `Accrue.Checkout.Session` create/retrieve helpers with sensible defaults
- [x] **CHKT-02**: Embedded and hosted Checkout modes
- [x] **CHKT-03**: Line-item helpers for Checkout
- [x] **CHKT-04**: `Accrue.BillingPortal.Session` create helper
- [x] **CHKT-05**: Portal configuration helper with sane defaults (defends against "cancel without dunning")
- [x] **CHKT-06**: Checkout success/cancel URL routing with state reconciliation

### Connect (Marketplaces)

- [x] **CONN-01**: Connected account onboarding (Standard/Express/Custom)
- [x] **CONN-02**: Account Link generation for onboarding/update flows
- [x] **CONN-03**: Account status sync (capabilities, `charges_enabled`, `details_submitted`, `payouts_enabled`)
- [x] **CONN-04**: Destination charges
- [x] **CONN-05**: Separate charges + transfers flow
- [x] **CONN-06**: Platform fee computation helper
- [x] **CONN-07**: Express dashboard login link
- [x] **CONN-08**: Payout schedule configuration
- [x] **CONN-09**: Capability management
- [x] **CONN-10**: Per-account webhook secret routing
- [x] **CONN-11**: Platform-scoped and connected-account-scoped API calls

### Webhooks

- [ ] **WH-01**: `Accrue.Webhook.Plug` raw-body capture **scoped to webhook routes only** (never global)
- [ ] **WH-02**: Stripe signature verification with multi-secret rotation support
- [ ] **WH-03**: DB idempotency via `accrue_webhook_events` with `UNIQUE(processor_event_id)`
- [ ] **WH-04**: Oban-backed async dispatch with exponential backoff retry
- [ ] **WH-05**: Dead-letter queue after N attempts (default 25)
- [ ] **WH-06**: User handler behaviour with pattern-matchable event types
- [ ] **WH-07**: Default handler for built-in state reconciliation (subscription/invoice/charge updates)
- [x] **WH-08**: Replay tooling (requeue individual or bulk DLQ'd events)
- [x] **WH-09**: Out-of-order delivery resolution (resolve state from newest event by Stripe `created`)
- [ ] **WH-10**: Handler re-fetches current object instead of trusting snapshot payload
- [ ] **WH-11**: Configurable DLQ retention, default 90 days, pruned via Oban cron
- [ ] **WH-12**: Webhook pipeline p99 latency <100ms (verify → persist → enqueue → 200)
- [x] **WH-13**: Multi-endpoint webhook support with Connect-variant secret
- [ ] **WH-14**: Webhook event type constants module (or dependency on lattice_stripe's)

### Event Ledger

- [ ] **EVT-01**: `accrue_events` append-only table with Postgres role grants / trigger enforcing immutability (`REVOKE UPDATE/DELETE`)
- [ ] **EVT-02**: Schema: id, type, schema_version, actor_type (NOT NULL enum), actor_id, subject_type, subject_id, data jsonb, trace_id, idempotency_key, inserted_at
- [ ] **EVT-03**: `Accrue.Events.record/1` helper with Ecto.Multi support for transactional writes alongside state mutations
- [ ] **EVT-04**: Every Billing context function that mutates state emits a corresponding event in the same transaction
- [x] **EVT-05**: `Accrue.Events.Upcaster` pattern for schema_version evolution with `upcast/1` callback
- [x] **EVT-06**: Query API: `timeline_for/2`, `state_as_of/3`, `bucket_by/3` for analytics
- [ ] **EVT-07**: OpenTelemetry `trace_id` correlation captured on every event write
- [ ] **EVT-08**: Actor context enum: `user | system | webhook | oban | admin` with required actor_type
- [ ] **EVT-09**: `Accrue.Integrations.Sigra` bridges Accrue events to `Sigra.Audit` when present
- [x] **EVT-10**: Analytics helper: bucket events by month/week/day with type filters

### Email

- [ ] **MAIL-01**: `Accrue.Mailer` behaviour wrapping Swoosh (host configures Swoosh adapter)
- [x] **MAIL-02**: `Mailer.Test` adapter for `assert_email_sent/1` helper
- [ ] **MAIL-03**: Email: `receipt` (payment succeeded)
- [ ] **MAIL-04**: Email: `payment_failed` with retry guidance
- [ ] **MAIL-05**: Email: `trial_ending` (3 days before, from `trial_will_end` webhook)
- [ ] **MAIL-06**: Email: `trial_ended`
- [ ] **MAIL-07**: Email: `invoice_finalized` (optional attachment of PDF)
- [ ] **MAIL-08**: Email: `invoice_paid`
- [ ] **MAIL-09**: Email: `invoice_payment_failed` with payment action required link
- [ ] **MAIL-10**: Email: `subscription_canceled`
- [ ] **MAIL-11**: Email: `subscription_paused` / `subscription_resumed`
- [ ] **MAIL-12**: Email: `refund_issued` with fee breakdown
- [ ] **MAIL-13**: Email: `coupon_applied`
- [x] **MAIL-14**: HEEx templates shared between email HTML body and invoice PDF (single source of truth)
- [ ] **MAIL-15**: Plain-text AND HTML multipart mandatory (not optional)
- [x] **MAIL-16**: Single-point branding config: logo, colors, from-name, from-address
- [x] **MAIL-17**: Per-template override for full customization
- [x] **MAIL-18**: MJML support via `mjml_eex` for responsive templates rendering across email clients
- [x] **MAIL-19**: Outlook MSO conditional block compatibility
- [x] **MAIL-20**: Async email sending via Oban
- [x] **MAIL-21**: Localization support via CLDR (currency formatting, date formatting)

### PDF

- [ ] **PDF-01**: `Accrue.PDF` behaviour with `render/2` callback
- [ ] **PDF-02**: `Accrue.PDF.ChromicPDF` default adapter
- [x] **PDF-03**: `Accrue.PDF.Test` adapter for assertion-based testing
- [x] **PDF-04**: `Accrue.PDF.Null` adapter for Chrome-hostile deploys (fails gracefully with documented error)
- [x] **PDF-05**: Invoice PDF template shared HEEx with email HTML body
- [x] **PDF-06**: Branded PDF with logo, colors, tagline inheriting from Mailer branding config
- [ ] **PDF-07**: PDF download route helper
- [ ] **PDF-08**: PDF attachment on email helpers
- [ ] **PDF-09**: Async PDF render via Oban with cache
- [x] **PDF-10**: Timezone and locale threading through render context
- [x] **PDF-11**: Gotenberg sidecar documented as custom adapter path

### Admin UI (accrue_admin package)

- [ ] **ADMIN-01**: Phoenix LiveView dashboard with KPIs (MRR, active subs, recent charges, webhook health)
- [ ] **ADMIN-02**: Mobile-first responsive layout (usable from phone)
- [ ] **ADMIN-03**: Light + dark mode with consistent contrast across components
- [ ] **ADMIN-04**: Brand palette theme (Ink/Slate/Fog/Paper + Moss/Cobalt/Amber); Amber reserved for warning/grace states
- [ ] **ADMIN-05**: Breadcrumbs + flash notifications
- [ ] **ADMIN-06**: Brandable: logo, accent color, app name via runtime config
- [ ] **ADMIN-07**: Customer list + search + filter
- [ ] **ADMIN-08**: Customer detail page with tabs (subscriptions, invoices, charges, payment methods, events, metadata)
- [ ] **ADMIN-09**: Subscription list + detail with timeline from events ledger
- [ ] **ADMIN-10**: Subscription admin actions (cancel, pause/resume, swap plan, comp) with confirmation + audit
- [ ] **ADMIN-11**: Invoice list + detail (line items, status, PDF preview, download)
- [ ] **ADMIN-12**: Invoice admin actions (void, mark uncollectible, manual pay)
- [ ] **ADMIN-13**: Charge list + detail with fee breakdown (Stripe fee, platform fee, net)
- [ ] **ADMIN-14**: Refund admin action with fee-aware UI surfacing `merchant_loss_amount`
- [ ] **ADMIN-15**: Coupon + PromotionCode management UI
- [ ] **ADMIN-16**: Webhook event inspector: list, filter by status/type, raw payload viewer, attempt history, signature verification status
- [ ] **ADMIN-17**: Webhook replay: one-click requeue individual; DLQ bulk requeue
- [ ] **ADMIN-18**: Activity feed sourced from `accrue_events`
- [ ] **ADMIN-19**: Connect: connected accounts list + detail + capability inspector
- [ ] **ADMIN-20**: Connect: platform fee configuration UI
- [ ] **ADMIN-21**: Step-up auth / re-auth prompt for destructive actions (refund, manual cancel)
- [ ] **ADMIN-22**: Admin action audit logging to `accrue_events` with `actor_type: :admin`
- [ ] **ADMIN-23**: Admin actions linked causally to webhook-driven events (`caused_by_event_id`)
- [ ] **ADMIN-24**: Dev-only test-clock advance UI (compile-time env gate, not runtime config)
- [ ] **ADMIN-25**: `accrue_admin.router` macro for mounting (`accrue_admin "/billing"`)
- [ ] **ADMIN-26**: `on_mount` hook for auth enforcement (not just `handle_event`)
- [ ] **ADMIN-27**: Shared LiveView component library (tables, timelines, detail cards, money formatter)

### Auth Integration

- [ ] **AUTH-01**: `Accrue.Auth` behaviour (`current_user/1`, `require_admin_plug/0`, `user_schema/0`, `log_audit/2`, `actor_id/1`)
- [ ] **AUTH-02**: `Accrue.Auth.Default` fallback adapter (dev-only; fails closed in prod)
- [ ] **AUTH-03**: `Accrue.Integrations.Sigra` first-party adapter, conditionally compiled via `Code.ensure_loaded?(Sigra)`
- [ ] **AUTH-04**: `mix accrue.install` auto-detects sigra in deps and auto-wires adapter config
- [ ] **AUTH-05**: Documentation for community adapters (`Accrue.Integrations.PhxGenAuth`, `.Pow`, `.Assent` patterns)

### Install + Generator

- [ ] **INST-01**: `mix accrue.install` generates migrations (customers, subscriptions, invoices, charges, payment_methods, refunds, webhook_events, events + trigger)
- [ ] **INST-02**: Generates `MyApp.Billing` context facade stub
- [ ] **INST-03**: Injects router mounts and webhook endpoint scaffold
- [ ] **INST-04**: Injects accrue_admin routes if package is in deps
- [ ] **INST-05**: Billable schema prompt/detection
- [ ] **INST-06**: Sigra auto-detection and auth wiring
- [ ] **INST-07**: **Idempotent re-run** — detects existing files, offers diff/review, never clobbers user edits
- [ ] **INST-08**: `mix accrue.gen.handler` for webhook handler scaffolding
- [ ] **INST-09**: NimbleOptions validation at install time
- [ ] **INST-10**: Config doc generation

### Observability

- [ ] **OBS-01**: `:telemetry` events for every public entry point with `:start`/`:stop`/`:exception`
- [ ] **OBS-02**: OpenTelemetry span helpers for every Billing context function (optional-compiled, gated on `:opentelemetry` presence)
- [x] **OBS-03**: High-signal ops event stream (`[:accrue, :ops, :revenue_loss | :webhook_dlq | :dunning_exhaustion | :incomplete_expired]`) separated from low-signal firehose
- [x] **OBS-04**: Structured trace/span naming conventions documented in a guide
- [x] **OBS-05**: Default `Telemetry.Metrics` recipe for SRE teams
- [ ] **OBS-06**: Stripe error mapping to structured `Accrue.Error` with metadata preserved

### Testing

- [ ] **TEST-01**: Fake Processor as primary test surface (Phase 1 foundation, not afterthought)
- [ ] **TEST-02**: `Accrue.Test.advance_clock/2` — drives both Fake and Stripe test-clock API in integration env
- [ ] **TEST-03**: `Accrue.Test.trigger_event/2` — synthetic webhook event injection
- [ ] **TEST-04**: `assert_email_sent/1` assertion helper
- [ ] **TEST-05**: `assert_pdf_rendered/1` assertion helper
- [ ] **TEST-06**: `assert_event_recorded/1` assertion helper
- [ ] **TEST-07**: Mock adapters (`Accrue.Auth.Mock`, `Accrue.Mailer.Test`, `Accrue.PDF.Test`)
- [x] **TEST-08**: Test fixtures for common subscription states
- [ ] **TEST-09**: Oban.Testing integration for async assertions
- [ ] **TEST-10**: Testing guide as marketing asset (shows the Fake Processor story is a differentiator)

### OSS Hygiene + Release

- [ ] **OSS-01**: Monorepo with sibling mix projects, per-package `CHANGELOG.md`, shared `.github/workflows/`
- [ ] **OSS-02**: GitHub Actions CI: `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`, `mix docs --warnings-as-errors`, `mix hex.audit`
- [ ] **OSS-03**: Elixir/OTP version matrix in CI
- [ ] **OSS-04**: Dialyzer PLT caching with OS × OTP × Elixir × mix.lock key
- [ ] **OSS-05**: CI matrix includes `with_sigra` and `without_sigra` to exercise conditional compilation
- [ ] **OSS-06**: CI matrix includes `with_opentelemetry` and `without_opentelemetry`
- [ ] **OSS-07**: Release Please + Conventional Commits for automated version bumps + CHANGELOG
- [ ] **OSS-08**: Per-package Release Please configs (accrue + accrue_admin independent)
- [ ] **OSS-09**: Hex publishing workflow with API token secret
- [ ] **OSS-10**: Same-day v1.0 release of accrue + accrue_admin (release runbook documented)
- [ ] **OSS-11**: MIT `LICENSE` file at monorepo root, per-package copies as needed
- [ ] **OSS-12**: `CONTRIBUTING.md` — PRs welcome, conventional commits, no CLA
- [ ] **OSS-13**: `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1
- [ ] **OSS-14**: `SECURITY.md` with vulnerability disclosure process
- [ ] **OSS-15**: Public API facade documentation with stability guarantees and deprecation policy
- [ ] **OSS-16**: ExDoc guides: quickstart (30s install), configuration, testing, Sigra integration, custom processors, custom PDF adapter, brand customization, admin UI setup, webhook gotchas field guide, upgrade guide
- [ ] **OSS-17**: README with 30-second quickstart
- [ ] **OSS-18**: llms.txt auto-generated via ExDoc for AI-friendly reference

## v2 Requirements

Deferred to post-1.0 release. Tracked but not in current roadmap.

### Gift Cards (deferred)

- **GIFT-01**: Gift card schema (purchasable, redeemable, balance tracking)
- **GIFT-02**: Gift card purchase flow
- **GIFT-03**: Gift card redemption flow
- **GIFT-04**: Email: `gift_sent`
- **GIFT-05**: Email: `gift_redeemed`
- **GIFT-06**: Admin UI for gift card management

### Multi-Provider (deferred)

- **MP-01**: First-party `Accrue.Processor.Paddle` adapter
- **MP-02**: First-party `Accrue.Processor.LemonSqueezy` adapter
- **MP-03**: First-party `Accrue.Processor.Braintree` adapter
- **MP-04**: Provider-selection UX at install time

### Advanced Observability (deferred)

- **OBS-07**: Oban Web webhook events extension
- **OBS-08**: Built-in Grafana dashboard templates
- **OBS-09**: Sentry/Honeybadger error reporter adapter

## Out of Scope

Explicitly excluded from v1.0 AND v1.x. Documented to prevent scope creep.

| Feature | Reason |
|---|---|
| MVP / iterate-in-public release | First release is complete; no v0.x cycle |
| MySQL / SQLite support | 7 load-bearing Postgres features have no clean fallback |
| Full CQRS/Event Sourcing (Commanded) | Wrong abstraction; Stripe is mutable state + events, not ES |
| Revenue recognition / GAAP accounting | Out of domain; integrate dedicated accounting systems downstream |
| Tax calculation / compliance engine | Surface Stripe Tax via lattice_stripe; no first-party tax resolution |
| Customer-facing pricing page generator | Host app's territory, not the library's |
| Dual-license / commercial tier at launch | MIT only; future commercial via hosted/services |
| Phoenix 1.7 and earlier | Phoenix 1.8+ only |
| Non-Stripe processors at launch | Stripe-first; behaviour preserved for future adapters |
| Accrue owning the User schema | Accrue references host-owned schemas polymorphically |
| Admin UI in core `accrue` package | Lives in companion `accrue_admin` |
| Hard Phoenix/LiveView dep in core | Core must work for headless/worker-only apps |

## Traceability

Which phases cover which requirements. Every v1 requirement maps to exactly one phase.

| Requirement | Phase | Status |
|---|---|---|
| FND-01 | Phase 1 | Pending |
| FND-02 | Phase 1 | Pending |
| FND-03 | Phase 1 | Pending |
| FND-04 | Phase 1 | Pending |
| FND-05 | Phase 1 | Pending |
| FND-06 | Phase 1 | Pending |
| FND-07 | Phase 1 | Pending |
| PROC-01 | Phase 1 | Pending |
| PROC-02 | Phase 3 | Complete |
| PROC-03 | Phase 1 | Pending |
| PROC-04 | Phase 2 | Pending |
| PROC-05 | Phase 5 | Complete |
| PROC-06 | Phase 2 | Pending |
| PROC-07 | Phase 1 | Pending |
| BILL-01 | Phase 2 | Pending |
| BILL-02 | Phase 2 | Pending |
| BILL-03 | Phase 3 | Complete |
| BILL-04 | Phase 3 | Complete |
| BILL-05 | Phase 3 | Complete |
| BILL-06 | Phase 3 | Complete |
| BILL-07 | Phase 3 | Complete |
| BILL-08 | Phase 3 | Complete |
| BILL-09 | Phase 3 | Complete |
| BILL-10 | Phase 3 | Complete |
| BILL-11 | Phase 4 | Complete |
| BILL-12 | Phase 4 | Complete |
| BILL-13 | Phase 4 | Complete |
| BILL-14 | Phase 4 | Complete |
| BILL-15 | Phase 4 | Complete |
| BILL-16 | Phase 4 | Complete |
| BILL-17 | Phase 3 | Complete |
| BILL-18 | Phase 3 | Complete |
| BILL-19 | Phase 3 | Complete |
| BILL-20 | Phase 3 | Complete |
| BILL-21 | Phase 3 | Complete |
| BILL-22 | Phase 3 | Complete |
| BILL-23 | Phase 3 | Complete |
| BILL-24 | Phase 3 | Complete |
| BILL-25 | Phase 3 | Complete |
| BILL-26 | Phase 3 | Complete |
| BILL-27 | Phase 4 | Complete |
| BILL-28 | Phase 4 | Complete |
| CHKT-01 | Phase 4 | Complete |
| CHKT-02 | Phase 4 | Complete |
| CHKT-03 | Phase 4 | Complete |
| CHKT-04 | Phase 4 | Complete |
| CHKT-05 | Phase 4 | Complete |
| CHKT-06 | Phase 4 | Complete |
| CONN-01 | Phase 5 | Complete |
| CONN-02 | Phase 5 | Complete |
| CONN-03 | Phase 5 | Complete |
| CONN-04 | Phase 5 | Complete |
| CONN-05 | Phase 5 | Complete |
| CONN-06 | Phase 5 | Complete |
| CONN-07 | Phase 5 | Complete |
| CONN-08 | Phase 5 | Complete |
| CONN-09 | Phase 5 | Complete |
| CONN-10 | Phase 5 | Complete |
| CONN-11 | Phase 5 | Complete |
| WH-01 | Phase 2 | Pending |
| WH-02 | Phase 2 | Pending |
| WH-03 | Phase 2 | Pending |
| WH-04 | Phase 2 | Pending |
| WH-05 | Phase 2 | Pending |
| WH-06 | Phase 2 | Pending |
| WH-07 | Phase 2 | Pending |
| WH-08 | Phase 4 | Complete |
| WH-09 | Phase 3 | Complete |
| WH-10 | Phase 2 | Pending |
| WH-11 | Phase 2 | Pending |
| WH-12 | Phase 2 | Pending |
| WH-13 | Phase 4 | Complete |
| WH-14 | Phase 2 | Pending |
| EVT-01 | Phase 1 | Pending |
| EVT-02 | Phase 1 | Pending |
| EVT-03 | Phase 1 | Pending |
| EVT-04 | Phase 2 | Pending |
| EVT-05 | Phase 4 | Complete |
| EVT-06 | Phase 4 | Complete |
| EVT-07 | Phase 1 | Pending |
| EVT-08 | Phase 1 | Pending |
| EVT-09 | Phase 7 | Pending |
| EVT-10 | Phase 4 | Complete |
| MAIL-01 | Phase 1 | Pending |
| MAIL-02 | Phase 6 | Complete |
| MAIL-03 | Phase 6 | Pending |
| MAIL-04 | Phase 6 | Pending |
| MAIL-05 | Phase 6 | Pending |
| MAIL-06 | Phase 6 | Pending |
| MAIL-07 | Phase 6 | Pending |
| MAIL-08 | Phase 6 | Pending |
| MAIL-09 | Phase 6 | Pending |
| MAIL-10 | Phase 6 | Pending |
| MAIL-11 | Phase 6 | Pending |
| MAIL-12 | Phase 6 | Pending |
| MAIL-13 | Phase 6 | Pending |
| MAIL-14 | Phase 6 | Complete |
| MAIL-15 | Phase 6 | Pending |
| MAIL-16 | Phase 6 | Complete |
| MAIL-17 | Phase 6 | Complete |
| MAIL-18 | Phase 6 | Complete |
| MAIL-19 | Phase 6 | Complete |
| MAIL-20 | Phase 6 | Complete |
| MAIL-21 | Phase 6 | Complete |
| PDF-01 | Phase 1 | Pending |
| PDF-02 | Phase 6 | Pending |
| PDF-03 | Phase 6 | Complete |
| PDF-04 | Phase 6 | Complete |
| PDF-05 | Phase 6 | Complete |
| PDF-06 | Phase 6 | Complete |
| PDF-07 | Phase 6 | Pending |
| PDF-08 | Phase 6 | Pending |
| PDF-09 | Phase 6 | Pending |
| PDF-10 | Phase 6 | Complete |
| PDF-11 | Phase 6 | Complete |
| ADMIN-01 | Phase 7 | Pending |
| ADMIN-02 | Phase 7 | Pending |
| ADMIN-03 | Phase 7 | Pending |
| ADMIN-04 | Phase 7 | Pending |
| ADMIN-05 | Phase 7 | Pending |
| ADMIN-06 | Phase 7 | Pending |
| ADMIN-07 | Phase 7 | Pending |
| ADMIN-08 | Phase 7 | Pending |
| ADMIN-09 | Phase 7 | Pending |
| ADMIN-10 | Phase 7 | Pending |
| ADMIN-11 | Phase 7 | Pending |
| ADMIN-12 | Phase 7 | Pending |
| ADMIN-13 | Phase 7 | Pending |
| ADMIN-14 | Phase 7 | Pending |
| ADMIN-15 | Phase 7 | Pending |
| ADMIN-16 | Phase 7 | Pending |
| ADMIN-17 | Phase 7 | Pending |
| ADMIN-18 | Phase 7 | Pending |
| ADMIN-19 | Phase 7 | Pending |
| ADMIN-20 | Phase 7 | Pending |
| ADMIN-21 | Phase 7 | Pending |
| ADMIN-22 | Phase 7 | Pending |
| ADMIN-23 | Phase 7 | Pending |
| ADMIN-24 | Phase 7 | Pending |
| ADMIN-25 | Phase 7 | Pending |
| ADMIN-26 | Phase 7 | Pending |
| ADMIN-27 | Phase 7 | Pending |
| AUTH-01 | Phase 1 | Pending |
| AUTH-02 | Phase 1 | Pending |
| AUTH-03 | Phase 7 | Pending |
| AUTH-04 | Phase 8 | Pending |
| AUTH-05 | Phase 8 | Pending |
| INST-01 | Phase 8 | Pending |
| INST-02 | Phase 8 | Pending |
| INST-03 | Phase 8 | Pending |
| INST-04 | Phase 8 | Pending |
| INST-05 | Phase 8 | Pending |
| INST-06 | Phase 8 | Pending |
| INST-07 | Phase 8 | Pending |
| INST-08 | Phase 8 | Pending |
| INST-09 | Phase 8 | Pending |
| INST-10 | Phase 8 | Pending |
| OBS-01 | Phase 1 | Pending |
| OBS-02 | Phase 8 | Pending |
| OBS-03 | Phase 4 | Complete |
| OBS-04 | Phase 4 | Complete |
| OBS-05 | Phase 4 | Complete |
| OBS-06 | Phase 1 | Pending |
| TEST-01 | Phase 1 | Pending |
| TEST-02 | Phase 8 | Pending |
| TEST-03 | Phase 8 | Pending |
| TEST-04 | Phase 8 | Pending |
| TEST-05 | Phase 8 | Pending |
| TEST-06 | Phase 8 | Pending |
| TEST-07 | Phase 8 | Pending |
| TEST-08 | Phase 3 | Complete |
| TEST-09 | Phase 2 | Pending |
| TEST-10 | Phase 8 | Pending |
| OSS-01 | Phase 9 | Pending |
| OSS-02 | Phase 9 | Pending |
| OSS-03 | Phase 9 | Pending |
| OSS-04 | Phase 9 | Pending |
| OSS-05 | Phase 9 | Pending |
| OSS-06 | Phase 9 | Pending |
| OSS-07 | Phase 9 | Pending |
| OSS-08 | Phase 9 | Pending |
| OSS-09 | Phase 9 | Pending |
| OSS-10 | Phase 9 | Pending |
| OSS-11 | Phase 1 | Pending |
| OSS-12 | Phase 9 | Pending |
| OSS-13 | Phase 9 | Pending |
| OSS-14 | Phase 9 | Pending |
| OSS-15 | Phase 9 | Pending |
| OSS-16 | Phase 9 | Pending |
| OSS-17 | Phase 9 | Pending |
| OSS-18 | Phase 9 | Pending |

**Coverage:**
- v1 requirements: 191 total (FND 7, PROC 7, BILL 28, CHKT 6, CONN 11, WH 14, EVT 10, MAIL 21, PDF 11, ADMIN 27, AUTH 5, INST 10, OBS 6, TEST 10, OSS 18)
- Mapped to phases: 191 (100%)
- Unmapped: 0 ✓

**Phase distribution:**
- Phase 1 (Foundations): 23 requirements
- Phase 2 (Schemas + Webhook Plumbing): 17 requirements
- Phase 3 (Core Subscription Lifecycle): 21 requirements
- Phase 4 (Advanced Billing + Webhook Hardening): 22 requirements
- Phase 5 (Connect): 12 requirements
- Phase 6 (Email + PDF): 30 requirements
- Phase 7 (Admin UI): 29 requirements
- Phase 8 (Install + Polish + Testing): 20 requirements
- Phase 9 (Release): 17 requirements
- **Total: 191 ✓**

---
*Requirements defined: 2026-04-11*
*Last updated: 2026-04-11 — traceability populated by gsd-roadmapper*
