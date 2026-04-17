# Accrue

## What This Is

Accrue is an open-source Elixir/Phoenix payments and billing library, inspired by Pay (Rails) and Laravel Cashier but built idiomatically for the Elixir/Ecto/Plug/Phoenix ecosystem. It gives Phoenix SaaS developers a batteries-included "jumpstart" for everything a real SaaS business needs on day one — subscriptions, checkout, invoices, coupons, emails, PDFs, webhooks, admin UI, telemetry — without the migration pain and design regrets earlier libraries accumulated.

Tagline: *"Billing state, modeled clearly."*

## Core Value

**A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one** — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version. Everything else is in service of that.

## Current State

Accrue v1.1 Stabilization + Adoption is shipped. The public Hex packages remain:

- `accrue` 0.1.2
- `accrue_admin` 0.1.2

The v1.0 milestone delivered the full billing library, companion admin UI, installer/test DX, release automation, docs, and OSS policy surface.

The v1.1 milestone proved the packages from a real Phoenix user's point of view:

- `examples/accrue_host` is a realistic host app that installs and uses `accrue` and `accrue_admin` through public APIs.
- The host app proves signed-in billing, signed webhook ingest, admin inspection/replay, audit evidence, clean-checkout rebuild, and local boot paths.
- CI runs a Fake-backed host integration gate with Playwright browser coverage, retained failure artifacts, Hex-mode smoke validation, and warning/error annotation sweeps.
- First-user DX is hardened through installer no-clobber reruns, conflict sidecars, shared setup diagnostics, host-first docs, troubleshooting anchors, and package-doc verification.

Milestone history and requirements are archived in `.planning/milestones/`.

## Next Milestone Goals

The next milestone is not defined yet. Candidate themes to validate through `$gsd-new-milestone`:

- Adoption assets: maintained example/demo path, tutorial docs, README positioning, issue templates, and release guidance.
- Quality hardening: security, performance, compatibility, accessibility/responsive admin checks, and clearer release-gate boundaries.
- Expansion discovery: tax, revenue exports, additional processors, and organization/multi-tenant billing decisions.

## Requirements

### Validated

v1.0 Initial Release shipped and validated on 2026-04-16. Detailed requirement outcomes are archived in `.planning/milestones/v1.0-REQUIREMENTS.md`.

v1.1 Stabilization + Adoption shipped and validated on 2026-04-17. Detailed requirement outcomes are archived in `.planning/milestones/v1.1-REQUIREMENTS.md`.

- ✓ Minimal host-app dogfood harness exercises the real install and user-facing billing/admin paths — v1.1
- ✓ CI runs the host-app integration and browser flows as a release gate — v1.1
- ✓ Focused host-flow proofs are hermetic when run directly after the canonical host UAT wrapper — v1.1
- ✓ Installer, docs, diagnostics, package metadata, and dependency-mode checks are hardened from the host-app experience — v1.1

### Active

Next active requirements are intentionally unset until `$gsd-new-milestone` defines the next milestone. Candidate areas are adoption assets, quality hardening, and expansion discovery.

### Validated v1.0 Scope Summary

**Core billing domain**
- [x] Polymorphic `Accrue.Billing.Customer` — any host schema (User, Org, Team) can be billable via `use Accrue.Billable`
- [x] `Accrue.Billing.Subscription` with full lifecycle (trials, proration, pause/resume, swap, cancel-at-period-end, immediate cancel, dunning, grace periods)
- [x] `Accrue.Billing.Invoice` with draft/open/paid/void/uncollectible state machine, line items, discounts, tax
- [x] `Accrue.Billing.Charge` / `PaymentIntent` / `SetupIntent` wrappers with async-state handling (requires_action, 3DS/SCA)
- [x] `Accrue.Billing.PaymentMethod` with default-management, fingerprinting
- [x] `Accrue.Billing.Refund` with Stripe fee awareness (gotcha #14)
- [x] `Accrue.Billing.Coupon` / `PromotionCode` / gift card redemption
- [x] Free-tier / trial / comped subscription support (no PaymentMethod required)
- [x] Multi-currency (including zero-decimal currency safety — JPY/KRW etc)
- [x] Subscription Schedules for multi-phase billing
- [x] Customer Portal Session + Checkout Session helpers
- [x] Stripe Connect (Standard/Express/Custom) support for marketplaces: destination charges, separate charges + transfers, platform onboarding

**Processor abstraction**
- [x] Stripe processor (via `lattice_stripe` dep)
- [x] Fake processor for test-first development (no Stripe API calls, test clock, time advancement, event triggering)
- [x] `Accrue.Processor` behaviour designed so future adapters (Paddle, Lemon Squeezy, Braintree) can implement it without false-parity abstraction over processor-specific capabilities

**Webhooks**
- [x] Raw-body capture Plug (mandatory before `Plug.Parsers`)
- [x] Signature verification
- [x] DB idempotency via `accrue_webhook_events` table with `UNIQUE(processor_event_id)`
- [x] Oban-backed async dispatch with exponential backoff retry, dead-letter after N attempts
- [x] User handler contract with pattern-matchable event types
- [x] Replay tooling (requeue failed / dead-lettered events)

**Event ledger**
- [x] Append-only `accrue_events` table, immutable at the Postgres role/trigger level
- [x] Transactional event recording alongside state mutations (atomicity guarantee)
- [x] `schema_version` inside `data` jsonb + upcaster pattern for evolution
- [x] OpenTelemetry `trace_id` correlation per event
- [x] Query API: timeline for subject, replay/rewind state as-of, analytics bucketing
- [x] Bridge to `Sigra.Audit` when sigra adapter is active

**Email**
- [x] Swoosh-based transactional email via `Accrue.Mailer` facade (behaviour-wrapped so library doesn't leak Swoosh to users)
- [x] Full email type set: receipt, payment_succeeded, payment_failed, trial_ending, trial_ended, invoice_finalized, invoice_paid, invoice_payment_failed, subscription_canceled, subscription_paused, subscription_resumed, refund_issued, coupon_applied, gift_sent, gift_redeemed
- [x] HEEx templates that work in plain-text AND HTML, rendering consistently across major email clients
- [x] Single-point branding config (logo, colors, from-name, from-address) for 80% case
- [x] Per-template override for full customization
- [x] MJML support via `mjml_eex` for responsive templates

**PDF**
- [x] `Accrue.PDF` behaviour with `Accrue.PDF.ChromicPDF` default adapter, `Accrue.PDF.Test` for assertion-based testing, documented path for custom adapters (Gotenberg sidecar, external services)
- [x] Branded invoice PDFs from the same HEEx template that drives the email HTML body (single source of truth)
- [x] Attachment and download paths for generated PDFs

**Admin UI (companion package `accrue_admin`)**
- [x] Phoenix LiveView dashboard: customers, subscriptions, invoices, charges, coupons, webhook events
- [x] Mobile-first responsive layout
- [x] Light + dark mode
- [x] Default theme follows Accrue brand palette (Ink / Slate / Fog / Paper foundation + Moss / Cobalt / Amber accents)
- [x] Branding customization (logo, accent color, app name) for internal-tool style
- [x] Webhook event inspector with raw payload, status, retry history, one-click replay, dead-letter bulk requeue
- [x] Activity feed sourced from `accrue_events`
- [x] Auth protection via `Accrue.Auth` adapter (Sigra-auto-wired when present)
- [x] Released same day as `accrue` v1.0, from the same monorepo

**Auth integration**
- [x] `Accrue.Auth` behaviour (current_user, require_admin_plug, user_schema, log_audit, actor_id)
- [x] `Accrue.Auth.Default` fallback adapter
- [x] `Accrue.Integrations.Sigra` first-party adapter, conditionally compiled, auto-detected by installer
- [x] Documented path for community adapters (`Accrue.Integrations.PhxGenAuth`, `.Pow`, `.Assent`)

**Install + DX**
- [x] `mix accrue.install` task that generates migrations, `MyApp.Billing` context, router mounts, admin LiveView routes; detects sigra and auto-wires auth; uses configurable billable schema
- [x] Discoverable, intuitive configuration with NimbleOptions-backed validation and doc generation
- [x] `Accrue.Billing` context facade hides lattice_stripe from the user-facing API

**Observability**
- [x] First-class `:telemetry` events with consistent `[:accrue, :domain, :action, :start|:stop|:exception]` naming
- [x] OpenTelemetry span helpers with business-meaningful attributes (customer_id, subscription_id, event_type, processor)
- [x] High-signal ops events for SRE/on-call (revenue-loss, webhook DLQ, dunning exhaustion) with low-signal firehose available separately
- [x] Structured, pattern-matchable error hierarchy (`Accrue.Error` → `Accrue.CardError`, `.RateLimitError`, etc.)

**Testing**
- [x] Fake Processor as the primary test surface — not an afterthought
- [x] Test helpers: time advancement, event triggering, state inspection, `assert_email_sent`, `assert_pdf_rendered`
- [x] Mock adapters for `Accrue.Auth`, `Accrue.Mailer`, `Accrue.PDF` so host apps can test billing flows without hitting Stripe / Chrome / real SMTP

**OSS hygiene and release**
- [x] Monorepo with sibling mix projects (`accrue/`, `accrue_admin/`), each published independently to Hex
- [x] GitHub Actions CI: Elixir/OTP matrix, `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`, `mix docs --warnings-as-errors`, `mix hex.audit`
- [x] Release Please + Conventional Commits for automated version bumps + CHANGELOG
- [x] ExDoc with guides: quickstart, configuration, testing, Sigra integration, custom processors, custom PDF adapter, brand customization, admin UI setup, upgrade guide
- [x] MIT license, single-root `LICENSE` file, no CLA
- [x] `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `SECURITY.md` for vulnerability disclosure
- [x] Semantic versioning with documented deprecation policy; minimize breaking changes through v1.x via stable public API facade

### Out of Scope

- **MVP / iterate-in-public release strategy** — user wants the first public release to be fully complete; no v0.1→v0.2→v0.3 cadence. Phases in this project are internal build milestones, not public releases.
- **Multi-provider at launch** — Stripe-only for v1.0. Processor behaviour is designed to support future adapters (Paddle, Lemon Squeezy, Braintree), but building those actual adapters is post-1.0. If existing Elixir libs exist for other processors they can be wrapped later; if not, those libraries will be built separately in future Jon-owned projects.
- **Multi-database support** — PostgreSQL 14+ only. MySQL and SQLite lose too many load-bearing features (jsonb/GIN, partial indexes, unique-where, advisory locks, exclusion constraints). Revisit only if real user demand emerges post-1.0, using Oban's multi-engine playbook.
- **Dual-license / commercial tier at launch** — MIT only for v1.0. Future commercial paths go through vertical integration (hosted service, compliance/tax bundling) rather than paid features in the core library.
- **Full CQRS/Event Sourcing via Commanded** — rejected in favor of append-only audit log pattern. Commanded is mature but wrong abstraction for billing, which Stripe itself models as mutable state + event notifications.
- **Accrue owning the auth user schema** — Accrue's polymorphic `owner_type`/`owner_id` references host-owned schemas (via sigra, phx.gen.auth, Pow, or other). Accrue never owns `users`.
- **First-party Paddle/Lemon Squeezy/Braintree adapters** — post-1.0.
- **Revenue recognition / GAAP accounting** — out of scope; Accrue is a billing/subscription library, not an accounting system. Users integrate downstream accounting tools themselves.
- **Tax calculation** — out of scope for v1.0; users can surface Stripe Tax through Accrue's existing APIs, but no first-party tax resolution/compliance support at launch.

## Context

**Ecosystem gap.** Elixir/Phoenix has no mature billing library in 2026. Bling is pre-1.0 with single-maintainer risk and depends on stripity_stripe pinned to a 2019 API. The Phoenix community has paid a real cost for this gap — Rails has Pay + Jumpstart, Laravel has Cashier + Spark, Django has dj-stripe. Accrue fills that niche with the benefit of those libraries' lessons learned.

**Lessons learned from prior art** (extracted from Pay/Cashier/dj-stripe research):
- *Pay v2→v3 migration pain* — moving from User-table columns to separate polymorphic tables broke many users. Accrue starts polymorphic from day one.
- *Cashier's separate-package decision* — shared multi-processor abstraction is a beautiful lie; Laravel explicitly split Stripe and Paddle into separate packages because generic abstraction failed. Accrue ships Stripe-first and resists false parity.
- *dj-stripe's JSON blob strategy* — after a decade, dj-stripe converged on storing full Stripe API responses in `data` columns rather than maintaining 1:1 column parity. Accrue adopts this from day one.
- *Webhook handling is the #1 value-add* — every ecosystem's users cite it as the highest-ROI feature a billing lib can provide. Accrue makes it a first-class citizen.
- *The Fake Processor is table stakes, not an edge case* — Pay's fake processor transforms the test story from "slow, flaky, expensive" to "fast, reliable, local". Accrue builds it on day one as the primary test surface.
- *Raw-body gotcha* — most web frameworks (Phoenix included) parse bodies before handler runs, destroying the raw bytes needed for webhook signature verification. This is the single most common webhook integration bug. Accrue provides the plug that solves it.

**Sibling projects** (same author: Jon):
- **`lattice_stripe`** (`/Users/jon/projects/lattice_stripe`, v0.2.0, Stripe API `2026-03-25.dahlia`) — thin Elixir wrapper over the Stripe SDK. Covers Tier 1–2 (payments, customers, payment methods, refunds, checkout, webhooks, errors, telemetry). Accrue depends on it directly. **Gap:** no Billing (Subscription/Product/Price/Invoice/Meter) coverage yet — Accrue will need lattice_stripe to add these, or build them upstream as lattice_stripe contributions. Also lacks v2 include support, Connect context helpers, and event type constants.
- **`sigra`** (`/Users/jon/projects/sigra`, v0.1.0) — authentication library for Phoenix 1.8+, "Devise with lessons learned." Hybrid lib + generator pattern (security-critical code in lib, schemas/contexts/routes generated into host). Organizations/multi-tenancy planned for future milestone. Admin UI milestone in progress. Accrue's `Accrue.Integrations.Sigra` adapter plugs into it; multi-tenancy will flow through naturally once sigra ships orgs (Accrue's polymorphic billable already supports `owner_type = Team`).

**Brand** (from `prompts/accrue brand book.md`):
- Positioning: Elixir-native, framework-integrated, not a fintech. Calm, measured, technically precise.
- Tagline: *"Billing state, modeled clearly."*
- Palette: Ink #111418, Slate #24303B, Fog #E9EEF2, Paper #FAFBFC foundation; Moss #5E9E84 primary; Cobalt #5D79F6 interactive; Amber #C8923B warnings/grace periods.
- Typography: neutral sans (Inter/Geist/IBM Plex Sans), JetBrains/IBM Plex Mono for code and event labels.
- Visual vocabulary: stacked lines, offset blocks, timelines, state diagrams. No coin/card/wallet clichés.
- Messaging pillars: native to Phoenix, billing as queryable app state (not black-box remote calls), webhooks without chaos, good open-source taste.

**Philosophy:**
- Idiomatic Elixir/OTP: pure functions at core, processes only for real state/concurrency, `{:ok, result} | {:error, exception}` returns with bang variants, behaviours for real extension points, protocols for data-type polymorphism, no macro abuse.
- Idiomatic Ecto: thin schemas, context functions as public API, explicit preloads, database-enforced integrity, `Ecto.Multi` for dynamic multi-step writes, `Repo.transact` for linear, schemas have `redact: true` on sensitive fields.
- Idiomatic Phoenix: business logic in `MyApp.Billing` context, web code in `MyAppWeb`, LiveView function components with `attr`/`slot`, `~p` verified routes, authz on action not just mount, Phoenix optional-not-required for headless core.
- OSS hygiene: small public API, layered façade, clear namespace (`Accrue.*`), runtime options over app env, first-class telemetry, exception hierarchy, ExDoc guides for every non-trivial topic.
- DDD-respecting: Accrue and its admin UI stay inside a `Billing` context so they don't pollute the host app's core domain(s). Same principle Sigra applies to authentication.

## Constraints

- **Tech stack**: Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. No legacy OTP support.
- **Dependencies (required)**: `lattice_stripe` (Stripe calls), `oban` (webhook async + email async + scheduled jobs), `swoosh` (email), `ecto_sql`, `postgrex`, `nimble_options` (config validation), `telemetry`, `chromic_pdf` (default PDF adapter — pullable via `accrue_admin` and core).
- **Dependencies (optional)**: `sigra` (`optional: true`), `phoenix_live_view` (hard dep in `accrue_admin`, not in core).
- **Release model**: ship complete. No public v0.x iteration cycle. Internal phases are build milestones, not public releases. First public release is v1.0 (or `0.1.0` if strict semver-pre-1 is preferred, but conceptually "complete").
- **Compatibility**: Phoenix 1.8+, LiveView 1.0+. No attempt at backward compatibility with Phoenix 1.7 or earlier.
- **Security**: Webhook signature verification mandatory and non-bypassable. Raw-body plug must run before `Plug.Parsers`. Sensitive Stripe fields never logged. Payment method details stored as Stripe references, never as PII.
- **Performance**: webhook request path <100ms p99 (verify → persist → enqueue → 200); async handler latency budget set by Oban queue config, user-configurable.
- **Observability**: all public entry points emit `:telemetry` start/stop/exception events. OTel span helpers available for every Billing context function.
- **Monorepo**: `accrue/` and `accrue_admin/` as sibling mix projects in one git repo. Shared `.github/workflows/`, shared `guides/`, per-package `mix.exs`, `CHANGELOG.md` per package.
- **License**: MIT for both packages.

## Key Decisions

| Decision | Rationale | Outcome |
|---|---|---|
| Stripe-only for v1.0 (processor behaviour designed for future adapters) | False multi-processor parity was Laravel Cashier's most-cited regret; lessons learned dominate breadth | ✓ Good |
| Polymorphic billable (`owner_type`/`owner_id`) + `use Accrue.Billable` macro | Pay v2→v3 migration pain; future sigra org support flows through with zero schema churn | ✓ Good |
| PostgreSQL 14+ only | 7 load-bearing PG features have no clean fallback; ~0% of serious Phoenix apps use MySQL/SQLite in production | ✓ Good |
| Hybrid lib + `mix accrue.install` generator | Matches sigra's pattern, upgrade-safe, best install DX; Phoenix community already knows this shape via phx.gen.auth | ✓ Good |
| Admin UI as companion `accrue_admin` package (monorepo, same-day release) | Core stays LiveView-free for headless users; `phoenix_live_dashboard` / `oban_web` pattern is idiomatic | ✓ Good |
| Swoosh (wrapped behind `Accrue.Mailer` facade) | Phoenix default since 1.6, larger adapter catalog, better test ergonomics, ecosystem alignment | ✓ Good |
| PDF via `Accrue.PDF` behaviour + `ChromicPDF` default | Seam pays for itself on the testing story alone (no Chrome in tests); escape hatch for Chrome-hostile deploys comes free | ✓ Good |
| Oban-backed async webhook dispatch (Oban required dep) | Retries survive deploys, DB idempotency at layer boundary, Oban is THE Elixir job standard, already needed for async email | ✓ Good |
| `Accrue.Auth` behaviour + `Accrue.Integrations.Sigra` adapter | Centralizes 15+ integration points to one dispatch, matches Plug/Ecto/Swoosh idiom, path for community adapters | ✓ Good |
| Append-only `accrue_events` table + Sigra.Audit bridge (NOT Commanded) | Matches Stripe's mental model (mutable state + events), ~150 LOC vs ~600+ for CQRS, transactional atomicity via Postgres | ✓ Good |
| MIT license, no CLA, single LICENSE file | Matches Elixir ecosystem norm; future commercial path via services not dual-license | ✓ Good |
| Context name `MyApp.Billing` | Industry-standard term, matches Stripe product naming, covers subs + one-time + refunds cleanly | ✓ Good |
| Build complete, ship v1.0 (no MVP-iterate cadence) | User explicit: won't have real users until fully usable; avoids Pay-style v2→v3 migration pain for early adopters | ✓ Good |
| Dogfood through a real Phoenix host app before broader adoption work | Real install, auth, webhook, admin, and clean-checkout paths exposed integration gaps that package-local tests could not catch | ✓ Good |
| Make Fake-backed host browser flow mandatory and live Stripe advisory | Deterministic CI should block regressions while live Stripe remains useful but non-deterministic | ✓ Good |
| Move host UI reads through generated `MyApp.Billing` facade | First-user docs should teach host-owned public boundaries, not private Accrue table queries | ✓ Good |
| Treat adoption, quality, and expansion as next-milestone candidates after stabilization | The v1.1 audit validated HOST/CI/DX scope; remaining ADOPT/QUAL/DISC ideas need fresh prioritization instead of automatic carryover | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-17 after v1.1 milestone completion*
