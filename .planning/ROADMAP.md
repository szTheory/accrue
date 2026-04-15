# Roadmap: Accrue

## Overview

Accrue is built in a strictly topological sequence dictated by research: foundations first (value types, behaviours, Fake processor, error hierarchy, event ledger), then schemas and webhook plumbing, then the core subscription lifecycle, then advanced billing + webhook hardening, then Connect, then email/PDF rendering, then the Admin LiveView UI, then installer and testing polish, then release machinery. The Fake Processor is **primary test surface** from day one — not a test afterthought — and the Money value type lands in Phase 1 so no schema is ever built with a bare-integer amount.

## Phases

**Phase Numbering:**
- Integer phases (1–9): Planned milestone work
- Decimal phases (e.g. 3.1): Urgent insertions

- [ ] **Phase 1: Foundations** — Money, behaviours, Fake processor, error hierarchy, event ledger, brand primitives
- [ ] **Phase 2: Schemas + Webhook Plumbing** — polymorphic Customer, all Billing schemas, scoped raw-body plug, signature verify, Oban dispatch, DB idempotency
- [ ] **Phase 3: Core Subscription Lifecycle** — subscribe/swap/cancel/resume/pause/trial, invoice state machine, charges, PI/SI, payment methods, refunds
- [ ] **Phase 4: Advanced Billing + Webhook Hardening** — metered, schedules, coupons, checkout/portal, DLQ/replay, out-of-order, event ledger query API, ops telemetry
- [ ] **Phase 5: Connect** — connected accounts, destination charges, separate charges + transfers, multi-endpoint webhooks with per-account secret routing
- [ ] **Phase 6: Email + PDF** — 13+ transactional emails via Mailer behaviour, ChromicPDF adapter, shared HEEx templates, MJML responsive layouts
- [ ] **Phase 7: Admin UI (accrue_admin)** — LiveView dashboard, customer/subscription/invoice pages, webhook inspector with one-click replay, Sigra auth adapter
- [ ] **Phase 8: Install + Polish + Testing** — `mix accrue.install` idempotent generator, test helpers (advance_clock, trigger_event, assert_email_sent, assert_pdf_rendered), OTel span helpers
- [ ] **Phase 9: Release** — CI matrix (format, warnings-as-errors, Credo strict, Dialyzer, docs), Release Please, ExDoc guides, SECURITY.md, same-day v1.0 publish of accrue + accrue_admin

## Phase Details

### Phase 1: Foundations
**Goal**: A Phoenix developer can depend on `accrue` and get the Money value type, error hierarchy, processor behaviour, Fake processor, and an append-only event ledger — enough primitives to unit-test everything downstream against the Fake processor without touching Stripe.
**Depends on**: Nothing (first phase)
**Requirements**: FND-01, FND-02, FND-03, FND-04, FND-05, FND-06, FND-07, PROC-01, PROC-03, PROC-07, EVT-01, EVT-02, EVT-03, EVT-07, EVT-08, AUTH-01, AUTH-02, MAIL-01, PDF-01, OBS-01, OBS-06, OSS-11, TEST-01
**Success Criteria** (what must be TRUE):
  1. A developer can add `accrue` as a path dep and call `Accrue.Money.new(1000, :usd)` and have it reject `Accrue.Money.new(100, :jpy) * 100` bare-integer math — zero-decimal currencies round-trip correctly and mixed-currency arithmetic raises.
  2. A developer can configure `Accrue.Processor.Fake` in test env and call the full `Accrue.Processor` behaviour (create_customer, create_subscription, etc.) without any network I/O; IDs are deterministic and a test clock can be advanced in-memory.
  3. Every `Accrue.Error` raised in the library is pattern-matchable via `%Accrue.CardError{}`, `%Accrue.RateLimitError{}`, `%Accrue.SignatureError{}`, etc., and Stripe errors surfaced through `Accrue.Processor.Stripe` are mapped to this hierarchy with metadata preserved.
  4. A write to `accrue_events` cannot be updated or deleted by the application role — attempting `Repo.update/delete` on an event row raises a Postgres permission/trigger error.
  5. `mix compile --warnings-as-errors` succeeds in both `with_sigra` and `without_sigra` builds of the monorepo, proving the conditional-compile pattern is correct on day one.
**Plans**: 6 plans
- [ ] 01-01-bootstrap-PLAN.md — Wave 0: mix scaffold (accrue + accrue_admin), Mox/ExUnit test harness, MIT LICENSE
- [ ] 01-02-money-errors-config-telemetry-PLAN.md — Accrue.Money (ex_money wrapper, property tests), Error hierarchy, NimbleOptions Config, Telemetry + Actor
- [ ] 01-03-event-ledger-PLAN.md — accrue_events table + trigger + REVOKE stub, Accrue.Events.record/record_multi, immutability integration tests
- [ ] 01-04-processor-PLAN.md — Accrue.Processor behaviour, deterministic Fake adapter with test clock, Stripe adapter + error mapper + facade lockdown
- [ ] 01-05-mailer-pdf-auth-PLAN.md — Mailer behaviour + Default + Oban worker + PaymentSucceeded (corrected mjml_eex pattern), PDF behaviour + ChromicPDF/Test adapters, Auth behaviour + dev/prod Default
- [ ] 01-06-application-sigra-brand-ci-PLAN.md — Accrue.Application empty supervisor + boot checks, conditional-compile Sigra scaffold, brand.css, GitHub Actions CI matrix with with_sigra/without_sigra
**UI hint**: no (headless foundations only; brand CSS variables land in `accrue/priv/static/brand.css` for downstream consumers but no LiveView)

### Phase 2: Schemas + Webhook Plumbing
**Goal**: All Billing schemas exist as polymorphic Ecto modules with `data` jsonb + deep-merge metadata, the `use Accrue.Billable` macro makes any host schema billable, and a scoped raw-body webhook pipeline verifies signatures, deduplicates on `UNIQUE(processor_event_id)`, and enqueues Oban jobs transactionally — all driven end-to-end through the Fake processor without any lattice_stripe Billing dependency.
**Depends on**: Phase 1
**Requirements**: BILL-01, BILL-02, PROC-04, PROC-06, WH-01, WH-02, WH-03, WH-04, WH-05, WH-06, WH-07, WH-10, WH-11, WH-12, WH-14, EVT-04, TEST-09
**Success Criteria** (what must be TRUE):
  1. A developer can `use Accrue.Billable` on a host `User` or `Organization` schema and see that schema become queryable as a polymorphic Customer (`owner_type`/`owner_id`) via the Billing context, with a round-trip create/fetch working against the Fake processor.
  2. A test POSTs a signed webhook payload at the scoped webhook route and the request returns 200 in under 100ms, persisting exactly one `accrue_webhook_events` row and enqueuing exactly one Oban job — all in a single `Repo.transact/1`. A duplicate POST of the same event ID returns 200 without creating a second row or job.
  3. Mounting `Accrue.Webhook.Plug` does not affect streaming or body parsing on any non-webhook route — the raw-body capture is scoped to the webhook pipeline only, verified by a test that asserts `Plug.Parsers` still runs globally.
  4. Every Billing context write that mutates state emits a corresponding `accrue_events` row in the **same transaction** as the state mutation — asserted by a test that triggers a rollback and sees both the state change and event disappear together.
  5. Webhook signature verification rejects a payload with a tampered body AND accepts a payload signed by any one of multiple configured rotation secrets.
**Plans**: 6 plans
Plans:
- [x] 02-01-PLAN.md — Ecto schemas (Customer, PaymentMethod, Subscription, SubscriptionItem, Charge, Invoice, Coupon, WebhookEvent) + migrations
- [x] 02-02-PLAN.md — use Accrue.Billable macro + Accrue.Billing context with lazy customer fetch-or-create
- [x] 02-03-PLAN.md — Webhook plug pipeline: CachingBodyReader, Signature wrapper, Router macro, mix.exs deps
- [x] 02-04-PLAN.md — Transactional ingest + Oban dispatch + Handler behaviour + DefaultHandler + Pruner
- [x] 02-05-PLAN.md — Deterministic idempotency keys + API version override + EVT-04 rollback proof
- [x] 02-06-PLAN.md — Test infrastructure: ConnCase, WebhookFixtures, StreamData property tests, Oban test config
**UI hint**: no

### Phase 3: Core Subscription Lifecycle
**Goal**: A full Stripe subscription can be created, swapped (with explicit proration), paused, resumed, canceled-at-period-end, canceled-now, and trial-managed end-to-end against real Stripe via `lattice_stripe` 0.3 — with invoice state machine, charge/PaymentIntent/SetupIntent tagged returns for 3DS/SCA, payment method management with fingerprint dedup, and fee-aware refunds.
**Depends on**: Phase 2
**Requirements**: PROC-02, BILL-03, BILL-04, BILL-05, BILL-06, BILL-07, BILL-08, BILL-09, BILL-10, BILL-17, BILL-18, BILL-19, BILL-20, BILL-21, BILL-22, BILL-23, BILL-24, BILL-25, BILL-26, WH-09, TEST-08
**Success Criteria** (what must be TRUE):
  1. A developer can call `MyApp.Billing.subscribe(user, price_id)` and observe a `trialing → active` transition, then call `swap_plan(subscription, new_price, proration: :create_prorations)` and see the correct prorated line items — with the `:proration` option **always explicit**, never inherited from a Stripe default.
  2. `Accrue.Billing.Subscription.active?/1` returns false for an `incomplete` subscription that has passed its 23-hour window, and `canceling?/1` returns true for a `cancel_at_period_end=true` subscription whose `status` is still `active` — raw `status` is never exposed as the access-control primitive.
  3. A charge against a 3DS-required test card returns `{:ok, :requires_action, %PaymentIntent{}}` (not `{:ok, intent}`), and a pattern-match on that tag in user code forces the SCA flow to be handled explicitly.
  4. A refund against a Stripe charge surfaces both `stripe_fee_refunded_amount` and `merchant_loss_amount` on the `Accrue.Billing.Refund` record — the asymmetric fee loss is visible, not silently swallowed.
  5. Two webhook events for the same subscription delivered out of order result in Accrue resolving state from the newest event by Stripe `created` timestamp, with the handler re-fetching the current Stripe object rather than trusting either payload snapshot.
  6. `preview_upcoming_invoice/2` returns a prorated line-item preview before `swap_plan/3` commits, enabling user-facing "you will be charged $X on Y" UX.
**Plans**: 8 plans
Plans:
- [x] 03-01-PLAN.md — Wave 1: Clock, Actor operation_id, Config, Phase 3 Error types, Credo NoRawStatusAccess check, BillingCase, StripeFixtures
- [x] 03-02-PLAN.md — Wave 1: Phase 3 migrations + Ecto schemas (Subscription/Invoice/InvoiceItem/Charge/Refund/PaymentMethod/Customer/Coupon/UpcomingInvoice) + Billing.Query fragments
- [x] 03-03-PLAN.md — Wave 1: Processor behaviour extension + Fake (transition/advance/synth) + Stripe adapter lattice_stripe delegation + Idempotency module
- [x] 03-04-PLAN.md — Wave 2: Accrue.Billing subscribe/swap_plan/cancel/cancel_at_period_end/resume/pause/unpause/update_quantity/preview_upcoming_invoice/trial_end normalizer + intent_result wrapping
- [x] 03-05-PLAN.md — Wave 2: Invoice workflow (finalize/void/pay/mark_uncollectible/send_invoice) + InvoiceProjection decomposer
- [x] 03-06-PLAN.md — Wave 2: Charge/PaymentIntent/SetupIntent + PaymentMethod fingerprint dedup + set_default_payment_method + Refund fee math
- [x] 03-07-PLAN.md — Wave 3: Webhook DefaultHandler Phase 3 reducers (skip-stale + refetch + out-of-order) + operation_id plug/LiveView/Oban middleware + reconciler jobs + DetectExpiringCards
- [x] 03-08-PLAN.md — Wave 3: Nine test factories + 24-event schema registry + Upcaster behaviour + property tests + VALIDATION.md population
**UI hint**: no

### Phase 4: Advanced Billing + Webhook Hardening
**Goal**: The subscription system covers the long tail — metered usage, multi-item subscriptions, free/comped tiers, dunning/grace, subscription schedules, coupons/promotion codes, Checkout + Customer Portal — and the webhook pipeline is hardened with DLQ, replay tooling, out-of-order resolution, and high-signal ops telemetry separated from the low-signal firehose.
**Depends on**: Phase 3
**Requirements**: BILL-11, BILL-12, BILL-13, BILL-14, BILL-15, BILL-16, BILL-27, BILL-28, CHKT-01, CHKT-02, CHKT-03, CHKT-04, CHKT-05, CHKT-06, WH-08, WH-13, EVT-05, EVT-06, EVT-10, OBS-03, OBS-04, OBS-05
**Success Criteria** (what must be TRUE):
  1. A developer can create a metered subscription, report meter events via `Accrue.Billing.report_usage/3`, and see usage aggregate correctly on the next invoice; a comped/free-tier subscription can be created without any PaymentMethod attached.
  2. A failed payment drives a subscription through `past_due → unpaid` per configured dunning policy, emitting `[:accrue, :ops, :dunning_exhaustion]` telemetry at the terminal transition — observable by an SRE on-call dashboard.
  3. A dead-lettered webhook event can be requeued individually or via DLQ bulk-requeue, and DLQ rows are pruned after the configured retention (default 90 days) via an Oban cron job.
  4. `Accrue.Events.timeline_for(subject)` returns the full append-only history for any subject, `state_as_of(subject, ts)` replays state at a past timestamp using upcasters for older `schema_version` entries, and `bucket_by/3` aggregates events by day/week/month for analytics.
  5. A developer can create a Stripe Checkout Session via `Accrue.Checkout.Session.create/2` and a Customer Portal Session with a sane default portal config that prevents "cancel without dunning" footguns — both return URLs that round-trip through Stripe test mode.
  6. A coupon or promotion code applied at subscription, invoice, or Checkout level produces the correct discounted total and a `coupon_applied` event in the ledger.
**Plans**: 8 plans
Plans:
- [x] 04-01-PLAN.md — Wave 1: lattice_stripe 1.1 bump + Accrue.Config extensions (:dunning, :webhook_endpoints, DLQ keys) + 6 schema/alter migrations (accrue_meter_events, accrue_subscription_schedules, accrue_promotion_codes, subscription dunning/pause cols, invoice discount cols, events type index)
- [x] 04-02-PLAN.md — Wave 2: Metered billing (BILL-13) — MeterEvent schema + report_usage/3 outbox pattern + Fake/Stripe processor + ReconcilerJob + billing.meter.error_report_triggered webhook
- [x] 04-03-PLAN.md — Wave 3: Advanced subscription surface (BILL-11 pause_behavior, BILL-12 multi-item, BILL-14 comp, BILL-16 SubscriptionSchedule) — schema + actions + webhook handlers
- [x] 04-04-PLAN.md — Wave 4: Dunning (BILL-15) — pure Dunning policy module + DunningSweeper Oban cron + dunning_exhaustion telemetry diff on webhook path
- [x] 04-05-PLAN.md — Wave 5: Coupons & PromotionCodes (BILL-27, BILL-28) — PromotionCode schema + apply_promotion_code + invoice discount denormalization via force_discount_changeset
- [x] 04-06-PLAN.md — Wave 6: Webhook hardening (WH-08, WH-13, EVT-05, EVT-06, EVT-10) — Accrue.Webhooks.DLQ library + Mix tasks + Pruner + multi-endpoint plug + Events query API + UpcasterRegistry
- [x] 04-07-PLAN.md — Wave 7: Checkout + Portal (CHKT-01..06) — Accrue.Checkout + Accrue.BillingPortal contexts + LineItem helper + reconcile/1 + Inspect URL mask + portal config checklist guide
- [x] 04-08-PLAN.md — Wave 8: Observability (OBS-03, OBS-04, OBS-05) — Accrue.Telemetry.Ops emit helper + Accrue.Telemetry.Metrics default recipe + guides/telemetry.md span naming guide
**UI hint**: no

### Phase 5: Connect
**Goal**: Marketplace platforms can onboard connected accounts (Standard/Express/Custom), route every processor call via per-request `Stripe-Account` header, run destination charges and separate charges + transfers, compute platform fees, and receive webhooks from multiple endpoints with per-account secret routing.
**Depends on**: Phase 4
**Requirements**: PROC-05, CONN-01, CONN-02, CONN-03, CONN-04, CONN-05, CONN-06, CONN-07, CONN-08, CONN-09, CONN-10, CONN-11
**Success Criteria** (what must be TRUE):
  1. A developer can onboard a connected account via `Accrue.Connect.create_account_link/2`, redirect to Stripe, return to the host app, and see account status (`charges_enabled`, `details_submitted`, `payouts_enabled`, capabilities) sync correctly.
  2. A destination charge and a separate-charge-plus-transfer flow both succeed end-to-end against Stripe test mode, with correct platform fee amounts computed by `Accrue.Connect.platform_fee/2`.
  3. Every processor call taking a connected-account context threads `Stripe-Account` through `lattice_stripe` without leaking platform-scoped secrets; platform-scoped and connected-account-scoped calls are both reachable via the same API with explicit context.
  4. A webhook arriving at a Connect-variant endpoint is verified against the Connect-variant secret (not the platform secret) and routed to the correct handler; a platform-level webhook is verified against the platform secret.
  5. An Express dashboard login link can be generated and clicked through to Stripe's dashboard for a connected account.
**Plans**: 7 plans
Plans:
- [x] 05-01-PLAN.md — Wave 0: webhook endpoint persistence gap + PROC-05 Stripe-Account threading (resolve_stripe_account + build_client + Processor behaviour + Config :connect + Oban middleware)
- [x] 05-02-PLAN.md — Wave 1: accrue_connect_accounts migration + Account schema/projection/predicates + Accrue.Connect facade (with_account/CRUD) + PutConnectedAccount plug + Fake Connect lifecycle with account-scoped ETS
- [x] 05-03-PLAN.md — Wave 1: AccountLink + LoginLink credential structs with Inspect masking + create_account_link/create_login_link facade + Stripe adapter delegations
- [x] 05-04-PLAN.md — Wave 1: platform_fee/2 pure Money helper + NimbleOptions config + StreamData property tests across JPY/USD/KWD
- [x] 05-05-PLAN.md — Wave 2: destination_charge/2 + separate_charge_and_transfer/2 + transfer/2 + telemetry spans + force_platform header safety
- [x] 05-06-PLAN.md — Wave 2: Accrue.Webhook.ConnectHandler full reducer set (account.*, capability.*, payout.*, person.*) + out-of-order seeding + ops telemetry
- [x] 05-07-PLAN.md — Wave 3: dual-scope integration test + live_stripe Connect suite + guides/connect.md + boot-time secret-collision warning + VALIDATION nyquist sign-off
**UI hint**: no

### Phase 6: Email + PDF
**Goal**: Every lifecycle event that should notify the customer sends a branded, responsive transactional email (plain-text + HTML + MJML), and every invoice can render as a branded PDF via ChromicPDF from the **same HEEx template** that drives the email HTML body — with `Mailer.Test` and `PDF.Test` adapters for assertion-based testing.
**Depends on**: Phase 3 and Phase 4 (domain events)
**Requirements**: MAIL-02, MAIL-03, MAIL-04, MAIL-05, MAIL-06, MAIL-07, MAIL-08, MAIL-09, MAIL-10, MAIL-11, MAIL-12, MAIL-13, MAIL-14, MAIL-15, MAIL-16, MAIL-17, MAIL-18, MAIL-19, MAIL-20, MAIL-21, PDF-02, PDF-03, PDF-04, PDF-05, PDF-06, PDF-07, PDF-08, PDF-09, PDF-10, PDF-11
**Success Criteria** (what must be TRUE):
  1. A successful payment triggers a `receipt` email and a `payment_failed` event triggers a `payment_failed` email with a retry link — both sent asynchronously via Oban and assertable via `assert_email_sent(:receipt, to: customer.email)`.
  2. An invoice PDF rendered via `Accrue.PDF.ChromicPDF` is byte-identical in layout to the HTML email body for the same invoice, because both render from the same HEEx template. A branding config change (logo, accent color, from-name) reflects immediately in both.
  3. All 13+ email types (`receipt`, `payment_failed`, `trial_ending`, `trial_ended`, `invoice_finalized`, `invoice_paid`, `invoice_payment_failed`, `subscription_canceled`, `subscription_paused`, `subscription_resumed`, `refund_issued`, `coupon_applied`, plus multipart variants) render correctly in both plain-text and HTML multipart and pass MJML responsive rendering in Outlook + Gmail + Apple Mail.
  4. `Accrue.PDF.Null` adapter returns a graceful documented error in Chrome-hostile deploy environments (e.g. minimal Alpine containers without Chromium), enabling hosts to opt out of PDF rendering without breaking the library.
  5. Currency amounts and dates in all emails and PDFs are formatted using CLDR-backed localization with correct timezone threading from the render context.
**Plans**: TBD
**UI hint**: yes (email HEEx templates, PDF layout, branding theme — template/rendering work, not LiveView)

### Phase 7: Admin UI (accrue_admin)
**Goal**: The `accrue_admin` companion package ships a mobile-first, light/dark-mode Phoenix LiveView dashboard covering customers, subscriptions, invoices, charges, refunds, coupons, Connect accounts, and a webhook event inspector with one-click replay and DLQ bulk requeue — auth-protected via the `Accrue.Auth` adapter with first-party Sigra auto-detection.
**Depends on**: Phase 4 (domain data), Phase 5 (Connect pages), Phase 6 (PDF preview)
**Requirements**: ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-08, ADMIN-09, ADMIN-10, ADMIN-11, ADMIN-12, ADMIN-13, ADMIN-14, ADMIN-15, ADMIN-16, ADMIN-17, ADMIN-18, ADMIN-19, ADMIN-20, ADMIN-21, ADMIN-22, ADMIN-23, ADMIN-24, ADMIN-25, ADMIN-26, ADMIN-27, AUTH-03, EVT-09
**Success Criteria** (what must be TRUE):
  1. A developer can mount `accrue_admin "/billing"` in their router, navigate to the dashboard on a phone, and see MRR, active subscription count, recent charges, and webhook health KPIs — with light/dark mode toggling via brand palette CSS variables (Ink/Slate/Fog/Paper + Moss/Cobalt/Amber).
  2. Opening a customer's detail page shows tabbed views (subscriptions, invoices, charges, payment methods, events, metadata), and the events tab is sourced directly from `accrue_events` showing the full activity timeline for that customer.
  3. A failed webhook event can be inspected in the webhook inspector (raw payload, signature verification status, attempt history, DLQ status) and requeued with one click; a DLQ bulk-requeue operation works on multi-select.
  4. A refund initiated from the admin UI walks through a step-up auth prompt, records an `actor_type: :admin` event in `accrue_events` with `caused_by_event_id` linked to the original charge event, and surfaces the Stripe-fee-not-refunded breakdown in the UI.
  5. When `sigra` is present in the host's deps, the admin UI auto-wires Sigra as the auth adapter (no manual config required), enforces auth via `on_mount` hooks (not just `handle_event`), and bridges admin events to `Sigra.Audit`.
  6. A dev-only test-clock advance UI is available in `:dev`/`:test` environments only — the control is gated by compile-time `Mix.env/0` check, not runtime config, and does not ship in production builds.
**Plans**: TBD
**UI hint**: yes

### Phase 8: Install + Polish + Testing
**Goal**: A Phoenix developer can run `mix accrue.install` in a fresh app and be running against Stripe test mode within 30 seconds, with generated migrations + `MyApp.Billing` context + router mounts + webhook endpoint + admin routes (if `accrue_admin` is present) + Sigra wiring (if present) — and have a complete test helper suite to assert billing behavior without hitting Stripe, Chrome, or real SMTP.
**Depends on**: Phase 7
**Requirements**: INST-01, INST-02, INST-03, INST-04, INST-05, INST-06, INST-07, INST-08, INST-09, INST-10, AUTH-04, AUTH-05, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-10, OBS-02
**Success Criteria** (what must be TRUE):
  1. A developer can run `mix accrue.install` in a fresh `phx.new` app, answer a billable-schema prompt, and see generated migrations, a `MyApp.Billing` context facade, router mounts, an admin LiveView route, and a webhook endpoint scaffold — with NimbleOptions config validation catching any invalid settings at install time.
  2. Re-running `mix accrue.install` on an already-installed app is **idempotent**: it detects existing files, offers a diff/review for any changes, and never clobbers user edits to generated files.
  3. A test can call `Accrue.Test.advance_clock(subscription, "1 month")` and observe the subscription transition through `trialing → active → canceled` without waiting real wall-clock time, and `trigger_event(:invoice_payment_failed, invoice)` injects a synthetic webhook the Handler processes normally.
  4. `assert_email_sent(:receipt, to: user.email)`, `assert_pdf_rendered(invoice)`, and `assert_event_recorded(subject, type: :subscription_created)` are all available as test assertion helpers and fail clearly with a useful message when the assertion is not met.
  5. When `sigra` is present in deps, `mix accrue.install` auto-detects it and wires `Accrue.Integrations.Sigra` as the auth adapter without any user config; when absent, the install falls back to `Accrue.Auth.Default` with a clear prod-safety warning.
  6. OpenTelemetry span helpers wrap every Billing context function when `:opentelemetry` is present, with span attributes containing `customer_id`, `subscription_id`, `event_type`, `processor` — and the library compiles cleanly with `--warnings-as-errors` in both `with_opentelemetry` and `without_opentelemetry` CI matrix entries.
**Plans**: TBD
**UI hint**: no

### Phase 9: Release
**Goal**: `accrue` v1.0.0 and `accrue_admin` v1.0.0 ship same-day to Hex via automated Release Please, with a GitHub Actions matrix CI enforcing format, warnings-as-errors, Credo strict, Dialyzer, ExDoc, and hex.audit; a full ExDoc guide set (quickstart, config, testing, Sigra integration, custom processors, custom PDF adapter, brand customization, admin UI, webhook gotchas, upgrade); MIT license; CONTRIBUTING, CODE_OF_CONDUCT (Contributor Covenant 2.1), and SECURITY.md.
**Depends on**: Phase 8
**Requirements**: OSS-01, OSS-02, OSS-03, OSS-04, OSS-05, OSS-06, OSS-07, OSS-08, OSS-09, OSS-10, OSS-12, OSS-13, OSS-14, OSS-15, OSS-16, OSS-17, OSS-18
**Success Criteria** (what must be TRUE):
  1. A clean clone of the monorepo runs `mix deps.get && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer && mix docs --warnings-as-errors && mix hex.audit` successfully across the full Elixir/OTP version matrix, with both `with_sigra`/`without_sigra` and `with_opentelemetry`/`without_opentelemetry` matrix entries passing.
  2. A Conventional Commit on `main` triggers Release Please to open per-package release PRs for `accrue` and `accrue_admin` with correct CHANGELOG entries and version bumps; merging those PRs publishes both packages to Hex same-day.
  3. A new user following the 30-second README quickstart goes from `mix new` to a working billing context with Stripe test mode in under 30 seconds (or has a clear error message explaining what's missing).
  4. Every ExDoc guide exists and is linked from the package README: quickstart, configuration, testing guide (as differentiator), Sigra integration, custom processors, custom PDF adapter, brand customization, admin UI setup, webhook gotchas field guide, upgrade guide. `llms.txt` is auto-generated for AI-friendly reference.
  5. `LICENSE` (MIT), `CONTRIBUTING.md` (no CLA, Conventional Commits), `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), and `SECURITY.md` (vulnerability disclosure process) all exist at the monorepo root, and the public-API facade is documented with a stability guarantee and deprecation policy.
**Plans**: TBD
**UI hint**: no

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundations | 0/TBD | Not started | - |
| 2. Schemas + Webhook Plumbing | 0/6 | Planned | - |
| 3. Core Subscription Lifecycle | 0/TBD | Not started | - |
| 4. Advanced Billing + Webhook Hardening | 0/TBD | Not started | - |
| 5. Connect | 1/7 | In Progress|  |
| 6. Email + PDF | 0/TBD | Not started | - |
| 7. Admin UI (accrue_admin) | 0/TBD | Not started | - |
| 8. Install + Polish + Testing | 0/TBD | Not started | - |
| 9. Release | 0/TBD | Not started | - |

## Parallelization Notes

Config has `parallelization: true`. Within a phase, plans should be labeled for parallel execution where independent:

- **Phase 1:** Money + Error hierarchy + Telemetry + brand palette are fully independent. Event ledger trigger work is independent of the behaviour definitions. Expect ~4–5 parallel plans.
- **Phase 2:** Schema work (per domain object) parallelizes; webhook pipeline is a single serial plan.
- **Phase 3:** Subscription, Invoice, Charge/PI/SI, PaymentMethod, Refund each parallelize cleanly — each is a context slice with its own Fake-processor tests.
- **Phase 6:** Email and PDF parallelize (different adapters, same HEEx templates — template work serializes first, then adapters parallelize).
- **Phase 7:** Admin pages parallelize per domain object (customers page, subscriptions page, invoices page, webhook inspector — each is an independent LiveView).
- **Phase 9:** CI config, Release Please config, ExDoc guides, LICENSE/CONTRIBUTING/COC/SECURITY — all independent docs + config work, fully parallel.

Phases 3, 4, 5 have the most serial dependencies (state-machine work). Phases 1, 2, 6, 7, 9 have the most parallel opportunity.

---
*Roadmap created: 2026-04-11*
*9 phases, 191 v1 requirements, 100% coverage*
