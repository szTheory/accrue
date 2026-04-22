# Accrue

## What This Is

Accrue is an open-source Elixir/Phoenix payments and billing library, inspired by Pay (Rails) and Laravel Cashier but built idiomatically for the Elixir/Ecto/Plug/Phoenix ecosystem. It gives Phoenix SaaS developers a batteries-included "jumpstart" for everything a real SaaS business needs on day one — subscriptions, checkout, invoices, coupons, emails, PDFs, webhooks, admin UI, telemetry — without the migration pain and design regrets earlier libraries accumulated.

Tagline: *"Billing state, modeled clearly."*

## Core Value

**A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one** — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version. Everything else is in service of that.

## Current milestone

### v1.11 — Public Hex release + post-release continuity

**Goal:** Ship **`accrue`** and **`accrue_admin`** to Hex for the metering + accumulated work since **0.1.2**, using the **Release Please + linked-versions** path, then align first-user docs, verifiers, and planning callouts so **Hex / repo / guides** agree—without **PROC-08** or **FIN-03**.

**Target features:**

- Combined release PR, **`accrue` then `accrue_admin`** publish, and tag-level verification per **`RELEASING.md`** and **`release-please-config.json`**.
- Changelog + **`mix.exs` `@version`** consistency for the shipped SemVer (workspace currently targets **`0.3.0`**; exact number follows Release Please + maintainer choice at ship time).
- **`RELEASING.md`** (and any conflicting “bootstrap only” wording) accurate for **routine pre-1.0** linked releases.
- Post-publish continuity: **`verify_package_docs`**, **`first_hour`** / primary install **`~>`** snippets, and **PROJECT / MILESTONES / STATE** Hex lines updated to the published versions.

**v1.10 — Metered usage + Fake parity** is **archived** (2026-04-22). Phases **43–45**; **MTR-01..MTR-08** validated. Archives: `.planning/milestones/v1.10-ROADMAP.md`, `v1.10-REQUIREMENTS.md`. Spike retained: `.planning/research/v1.10-METERING-SPIKE.md`. Git tag **`v1.10`**.

**v1.9 — Observability & operator runbooks** is **archived** (2026-04-22). Archives: `.planning/milestones/v1.9-ROADMAP.md`, `v1.9-REQUIREMENTS.md`. Gap audit (research): `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`. Git tag **`v1.9`**.

**v1.7 Adoption DX + operator admin depth** is **archived** (2026-04-21). Archives: `.planning/milestones/v1.7-ROADMAP.md`, `v1.7-REQUIREMENTS.md`, `v1.7-MILESTONE-AUDIT.md` (**passed**). Git tag **`v1.7`**.

### Non-goals (until reprioritized in a future milestone)

**PROC-08** (second processor) and **FIN-03** (app-owned finance exports) remain **explicitly out of scope** until a later milestone prioritizes them with written boundaries. **Stripe Dashboard** meter setup UX stays host/Stripe documentation unless a future requirement explicitly pulls UI scope in.

## Current State

**Public Hex (last published):** **`accrue` 0.1.2**, **`accrue_admin` 0.1.2** — **v1.11** targets publishing the next linked versions from **`main`** (workspace **`mix.exs`** currently **`0.3.0`**; ship version is whatever Release Please + merge produce).

**Last shipped planning milestone:** **v1.10** — Phases **43–45** (2026-04-22): metering happy path + Fake determinism (**43**), failures + reconciler + webhook (**44**), docs + telemetry/runbook alignment (**45**); archives `.planning/milestones/v1.10-*`; planning git tag **`v1.10`**. Prior: **v1.9** — Phases **40–42**; archives `.planning/milestones/v1.9-*`; tag **`v1.9`**.

**Now:** **v1.11** active — root **`.planning/REQUIREMENTS.md`** + **`.planning/ROADMAP.md`** (Phases **46–47**) define release + continuity scope. After Hex is live, use **`/gsd-discuss-phase 48`** or a fresh **`/gsd-new-milestone`** slice for the next implementation theme.

## Shipped: v1.7 Adoption DX + operator admin depth (2026-04-21)

**Goal:** Clearer evaluator **VERIFY-01** / adoption doc paths; honest **installer + CI** semantics; **operator-first** admin entry, drill, and nav; **token-safe** dashboard surfaces with **`AccrueAdmin.Copy`** SSOT; **audit corpus** + verifier ownership + dual-contract documentation.

**Delivered (high level):** Phases **32–33** (ADOPT-01..06), **34** (OPS-01..03), **35** (OPS-04..05), **36** (integration hardening + forward-coupling). Evidence lives under `.planning/phases/32-*` … `36-*` and milestone archives.

## Shipped: v1.6 Admin UI / UX polish (2026-04-20)

**Goal:** Bring the companion admin (and evaluator-visible mounted paths) to a **consistent, accessible, mobile-credible** bar aligned to Phase 20/21 UI-SPEC contracts—without new billing domain scope or third-party UI kits.

**Delivered:**

- Phase **25** — Route matrix, component coverage notes, and UI-SPEC alignment artifacts under `.planning/phases/25-admin-ux-inventory/`.
- Phase **26** — `ax-*` hierarchy on money indexes, detail pages, and webhooks; theme token discipline with documented exceptions.
- Phase **27** — Operator microcopy pass and `AccrueAdmin.Copy` for stable literals in tests.
- Phase **28** — Focus, captions, contrast verification, and mounted-admin axe in VERIFY-01.
- Phase **29** — Mobile Playwright coverage and README mobile shell guidance for mounted admin.

The v1.0 milestone delivered the full billing library, companion admin UI, installer/test DX, release automation, docs, and OSS policy surface.

The v1.1 milestone proved the packages from a real Phoenix user's point of view:

- `examples/accrue_host` is a realistic host app that installs and uses `accrue` and `accrue_admin` through public APIs.
- The host app proves signed-in billing, signed webhook ingest, admin inspection/replay, audit evidence, clean-checkout rebuild, and local boot paths.
- CI runs a Fake-backed host integration gate with Playwright browser coverage, retained failure artifacts, Hex-mode smoke validation, and warning/error annotation sweeps.
- First-user DX is hardened through installer no-clobber reruns, conflict sidecars, shared setup diagnostics, host-first docs, troubleshooting anchors, and package-doc verification.

The v1.2 milestone made Accrue ready for new Phoenix teams to evaluate and trust: `examples/accrue_host` is the canonical local demo/tutorial path, the repository and package docs are host-first, mature OSS support assets are in place, trust evidence is checked in and executable, and expansion discovery ranked Stripe Tax, organization billing, and finance handoff as the next expansion candidates.

## Last Shipped Milestone: v1.3 Tax + Organization Billing

**Goal:** Let Phoenix SaaS teams bill organizations with Stripe Tax enabled, preserve tenant boundaries through Sigra or equivalent host-owned scopes, and hand finance workflows to Stripe-native reporting without Accrue owning accounting semantics.

**Delivered:**

- Stripe Tax on subscriptions and checkout with Fake-backed regression coverage and narrow local tax observability.
- Public tax-location updates, invalid-location recovery, finalization-failure surfacing, and rollout-safety documentation.
- Sigra-first org billing proof, owner-scoped admin queries, webhook replay ambiguity handling, and cross-tenant denial UX.
- VERIFY-01 executable proof (host tests + Playwright + README/CI contract) plus finance handoff guide and doc contract test (Phase 22).

## Earlier milestone: v1.2 Adoption + Trust

**Goal:** Make Accrue feel ready for a new Phoenix team to evaluate, integrate, and trust by polishing the canonical demo/onboarding path, adding mature-library quality signals, and deciding the next expansion bet without partially implementing it.

**Delivered:**
- Canonical local demo path built around `examples/accrue_host`, with documented setup, seeded Fake-backed billing/admin flow, and CI-equivalent verification.
- Host-first tutorial and public docs front door that connect install, first subscription, signed webhook ingest, admin inspection/replay, troubleshooting, production hardening, and package support policy.
- Mature OSS adoption assets: repository README, issue templates, release guidance, and clear Fake vs Stripe test vs live Stripe positioning.
- Trust hardening bundle covering webhook/auth/admin security, seeded performance smoke checks, compatibility, accessibility/responsive browser checks, secret/PII log review, and required-vs-advisory release-gate boundaries.
- Expansion discovery for tax, revenue/export, additional processors, and organization/multi-tenant billing captured as ranked future recommendations only.

## Shipped: v1.5 Adoption proof hardening (2026-04-18)

**Goal:** Make VERIFY-01 + Fake CI + Stripe test-mode parity discoverable for evaluators; ship an evaluator screen-recording checklist; document B2C-shaped API vs org-first LiveView coverage.

**Delivered:**

- `examples/accrue_host/docs/adoption-proof-matrix.md` and `evaluator-walkthrough-script.md`, linked from the host README and enforced by `verify_verify01_readme_contract.sh`.
- `accrue/guides/testing.md` cross-links the matrix and `guides/testing-live-stripe.md`; live-Stripe guide states job id vs Stripe mode.
- GitHub Actions `live-stripe` job **display name** now reads **Stripe test-mode parity (advisory)** (job id unchanged for `act` compatibility).
- `AccrueHost.BillingFacadeTest` module doc references the adoption matrix (PROOF-02 traceability).

## Shipped: v1.4 Ecosystem stability + demo visuals (2026-04-17)

**Goal:** Stay current on published **`lattice_stripe`** within `~> 1.1`, and make the Fake-backed **host + mounted admin** walkthrough trivial to **see** (screenshots + CI artifacts).

**Delivered:**

- `lattice_stripe` lockfiles refreshed across `accrue`, `accrue_admin`, and `examples/accrue_host` (latest on Hex at time of work: **1.1.0**).
- Visual walkthrough docs, `npm run e2e:visuals`, and CI artifact pointers; Playwright trust lane green on desktop + mobile.
- Committed **`accrue_admin` `priv/static` JS/CSS** is a real esbuild bundle so mounted admin LiveView works in the browser; `mix verify.full` rebuilds admin assets before Playwright.

**Explicitly deferred:** **PROC-08** (second processor), **FIN-03** product exports — revisit in a later milestone. **ORG-04** is **in scope for v1.8** (recipes + host integration depth).

Continue to treat `tax rollout correctness`, `cross-tenant billing leakage`, and `wrong-audience finance exports` as release risks regardless of milestone.

## Requirements

### Validated

v1.0 Initial Release shipped and validated on 2026-04-16. Detailed requirement outcomes are archived in `.planning/milestones/v1.0-REQUIREMENTS.md`.

v1.1 Stabilization + Adoption shipped and validated on 2026-04-17. Detailed requirement outcomes are archived in `.planning/milestones/v1.1-REQUIREMENTS.md`.

- ✓ Minimal host-app dogfood harness exercises the real install and user-facing billing/admin paths — v1.1
- ✓ CI runs the host-app integration and browser flows as a release gate — v1.1
- ✓ Focused host-flow proofs are hermetic when run directly after the canonical host UAT wrapper — v1.1
- ✓ Installer, docs, diagnostics, package metadata, and dependency-mode checks are hardened from the host-app experience — v1.1

v1.2 Adoption + Trust shipped and validated on 2026-04-17. Detailed requirement outcomes are archived in `.planning/milestones/v1.2-REQUIREMENTS.md`.

- ✓ Phoenix developers can clone the repository, run the canonical local demo, create a Fake-backed subscription, inspect/replay billing state in admin, and run the focused proof suite without hidden state — v1.2
- ✓ New users can follow a host-first tutorial and docs front door that explains integration order, supported public APIs, production hardening, and Fake/test/live Stripe choices — v1.2
- ✓ Maintainers and adopters have mature OSS support assets, including issue templates and release guidance aligned with the established Accrue voice — v1.2
- ✓ Security, performance, compatibility, accessibility/responsive behavior, and secret/PII safety have explicit checks or review artifacts before the next release — v1.2
- ✓ Tax, revenue/export, additional processor, and organization/multi-tenant billing expansion options are researched and ranked for the next implementation milestone without changing the current billing API — v1.2

### Validated v1.5 (archived in `.planning/milestones/v1.5-REQUIREMENTS.md`; milestone closed 2026-04-18)

- [x] **PROOF-01** — VERIFY-01 / Fake CI cross-linked with Stripe test-mode parity lane; CI + guide naming clarity.
- [x] **PROOF-02** — Host adoption proof matrix documents archetype coverage (including user billable ExUnit vs org-first LiveView).
- [x] **PROOF-03** — Evaluator screen-recording checklist doc linked from host README.

### Validated v1.6 (archived in `.planning/milestones/v1.6-REQUIREMENTS.md`; milestone closed 2026-04-20)

- [x] **INV-01..03** — Admin route matrix, component coverage vs kitchen, Phase 20/21 spec alignment (Phase 25).
- [x] **UX-01..04** — List/detail/webhook hierarchy and theme token discipline (Phase 26).
- [x] **COPY-01..03** — Operator microcopy and stable literals via `AccrueAdmin.Copy` (Phase 27).
- [x] **A11Y-01..04** — Focus, tables, contrast verification, mounted-admin axe in CI (Phase 28).
- [x] **MOB-01..03** — Mobile overflow/nav and admin-heavy `@mobile` / `chromium-mobile` coverage (Phase 29).

### Validated v1.7 (archived in `.planning/milestones/v1.7-REQUIREMENTS.md`; milestone closed 2026-04-21)

- [x] **ADOPT-01..03** — Root README → VERIFY-01 within two hops; host README single proof subsection; guide cross-links (Phase 32).
- [x] **ADOPT-04..06** — Installer rerun docs + anchors; doc contract coverage; merge-blocking vs advisory CI language (Phase 33).
- [x] **OPS-01..03** — Operator home KPIs; customer→invoice drill; `AccrueAdmin.Nav` + README route inventory (Phase 34).
- [x] **OPS-04..05** — Dashboard `ax-*` / token discipline; operator strings via `AccrueAdmin.Copy` + aligned Playwright (Phase 35).

### Validated v1.8 (archived in `.planning/milestones/v1.8-REQUIREMENTS.md`; milestone closed 2026-04-22)

Theme: **ORG-04** — non-Sigra org billing recipes, host integration depth, VERIFY/adoption-proof alignment; **PROC-08** and **FIN-03** not in this milestone.

- [x] **ORG-05** — Single non-Sigra doc spine for session → billable + ORG-03 checklist (`accrue/guides/organization_billing.md` + cross-links). **Validated in Phase 37.**
- [x] **ORG-06** — phx.gen.auth-oriented checklist in that spine (Accrue.Auth, Accrue.Billable, host billing facade). **Validated in Phase 37.**
- [x] **ORG-07** — Pow-oriented recipe + honest maintenance notes. **Validated in Phase 38.**
- [x] **ORG-08** — Custom org model checklist + ORG-03 anti-patterns. **Validated in Phase 38.**
- [x] **ORG-09** — Adoption proof matrix ORG-09 section, merge-blocking bash verifier, contributor map, guide cross-links + ExUnit. **Validated in Phase 39.**

### Validated v1.9 (milestone shipped 2026-04-22)

- [x] **OBS-01, OBS-03, OBS-04** — `guides/telemetry.md` ops catalog + firehose split + gap audit reconciliation. **Validated in Phase 40.**
- [x] **OBS-02, TEL-01** — `MetricsOpsParityTest`, cross-domain host subscription example in guide + `examples/accrue_host`. **Validated in Phase 41.**
- [x] **RUN-01** — `guides/operator-runbooks.md` (Oban topology, Stripe verification pattern, four mini-playbooks) linked from `guides/telemetry.md`. **Validated in Phase 42.**

### Validated v1.10 (archived in `.planning/milestones/v1.10-REQUIREMENTS.md`; milestone closed 2026-04-22)

Theme: **usage metering** + **Fake parity** + **telemetry/docs** alignment; **PROC-08** and **FIN-03** not in this milestone.

- [x] **MTR-01..MTR-03** — Public `report_usage` API, meter event persistence semantics, Fake happy path. **Validated in Phase 43.**
- [x] **MTR-04..MTR-06** — Sync failure + idempotent retry telemetry, reconciler recovery, webhook meter error path. **Validated in Phase 44.**
- [x] **MTR-07..MTR-08** — Metering guide boundaries + telemetry/runbook alignment for `meter_reporting_failed` sources. **Validated in Phase 45.**

### Validated v1.4 (archived here; milestone closed 2026-04-17)

- [x] **STAB-01** — Latest published `lattice_stripe` compatible with `~> 1.1` across monorepo lockfiles; gates green.
- [x] **UX-DEMO-01** — Visual walkthrough docs + optional `npm run e2e:visuals` for the Phase 15 trust Playwright path.

### Validated v1.3 (archived)

v1.3 Tax + Organization Billing shipped and validated on 2026-04-17. Outcomes: `.planning/milestones/v1.3-REQUIREMENTS.md`.

- ✓ TAX-01 through TAX-04 — Phases 18–19
- ✓ ORG-01 through ORG-03 — Phase 20
- ✓ VERIFY-01 — Phases 21–22 (executable proof + finance handoff narrative)
- ✓ FIN-01 and FIN-02 — Phase 22 (`accrue/guides/finance-handoff.md`)

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
- **`sigra`** (`/Users/jon/projects/sigra`, v0.1.0) — authentication library for Phoenix 1.8+, "Devise with lessons learned." Hybrid lib + generator pattern (security-critical code in lib, schemas/contexts/routes generated into host). Local Sigra now ships logical multi-tenancy through organizations, memberships, invitations, active organization scope/session hydration, tenant-aware audit columns, org-aware admin, impersonation, and audit/export surfaces. Accrue's `Accrue.Integrations.Sigra` adapter plugs into it, and v1.3 should use Sigra-first examples while keeping generic host-owned billables supported.

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
| Treat adoption, quality, and expansion as next-milestone candidates after stabilization | The v1.1 audit validated HOST/CI/DX scope; remaining ADOPT/QUAL/DISC ideas need fresh prioritization instead of automatic carryover | ✓ Good |
| v1.2 focuses on Adoption + Trust before large feature expansion | The biggest remaining gap is confidence for new users evaluating a billing library, not another core billing primitive; polish should stop once it hits diminishing returns and expansion should be decided deliberately | ✓ Good |
| Keep v1.2 expansion to discovery only | Tax, revenue exports, processors, and org billing are likely next-level features, but partial implementation would distract from onboarding and trust hardening | ✓ Good |
| Record the Phase 16 ranking as recommendation-only planning guidance | `Stripe Tax support` is the recommended `Next milestone`; `Organization / multi-tenant billing` and `Revenue recognition / exports` remain `Backlog`; `Official second processor adapter` remains a `Planted seed`, and no v1.2 billing API, schema, or processor-abstraction implementation is implied | ✓ Good |
| v1.3 combines Stripe Tax with Sigra-first organization billing and finance handoff | Stripe Tax is still the safest first expansion; Sigra org support is now concrete enough for host-proofed org billing; finance should stay Stripe-native before Accrue owns accounting semantics | ✓ Good |
| v1.6 closes admin UX polish without new billing primitives | Operator trust (a11y, mobile, copy) advances adoption without PROC-08/FIN-03 scope creep | ✓ Good |
| Post-ship Phases 30–31 close audit corpus + advisory integration without Hex release churn | Keeps evaluator-facing proof contracts aligned while preserving existing `v1.6` tag semantics | ✓ Good |
| v1.7 combines adoption/DX with operator admin depth without billing primitive expansion | After v1.6 polish, the highest leverage is clearer VERIFY-01 + install/docs matrices plus intentional admin entry flows—not PROC/FIN/ORG scope creep | ✓ Good |
| v1.8 delivers ORG-04 after Sigra-first org proof | Non-Sigra teams need first-class recipes and proof that **ORG-03** boundaries hold; scope stays docs + host patterns + VERIFY alignment—no PROC-08/FIN-03 | ✓ Good |
| v1.9 prioritizes observability + runbooks before meter milestone | Post–v1.8 plan: telemetry discoverability and ops runbooks maximize adoption ROI; metered billing (v1.10+) follows with Fake parity | ✓ Good |
| v1.10 delivers metered usage with Fake parity before second processor | Usage reporting, outbox, reconciler, and webhook error paths must be **host-testable** on Fake with stable telemetry keys; PROC-08 stays out of scope | ✓ Good |
| v1.11 ships Hex before the next feature milestone | Evaluators and hosts need published packages that include metering + accumulated work; release automation and doc verifiers must stay aligned with linked-versions monorepo reality | ✓ Good |

## Current Milestone Notes

- Phase 17 verified that v1.2 has no remaining requirement, integration, flow, or cleanup gaps before milestone archival.
- Phase 16 recorded a recommendation, not a feature delivery: `Stripe Tax support` is the recommended next implementation milestone because it deepens the current Stripe-first path without promising any v1.2 schema, API, or processor changes.
- `Organization / multi-tenant billing` remains a recommendation-only backlog candidate until host-owned org semantics, row-scoped tenancy checks, and `cross-tenant billing leakage` protections are explicit.
- `Revenue recognition / exports` remains a recommendation-only backlog candidate until host-authorized export audiences, storage, and delivery rules are explicit, preserving the `wrong-audience finance exports` boundary.
- `Official second processor adapter` remains a recommendation-only planted seed because Accrue is still Stripe-first and host-owned, and future work must avoid a `processor-boundary downgrade`.
- Any future tax milestone must preserve `tax rollout correctness` by requiring `customer location` capture plus `legacy recurring-item migration` planning before maintainers schedule implementation.
- v1.3 planning resolves the Phase 16 backlog tradeoff by implementing Stripe Tax and Sigra-first org billing together, while keeping finance work to Stripe Revenue Recognition, Sigma, and Data Pipeline handoff documentation.
- Phase 18 validated the first Stripe Tax slice: public subscription and checkout tax enablement, Stripe/Fake adapter parity, and narrow local automatic-tax observability.
- Phase 19 validated tax-location capture/update, immediate invalid-location error handling, recurring tax-risk projection/admin visibility, host repair flow, and legacy recurring-item rollout safety guidance.
- v1.6 (Phases 25–29) archived 2026-04-20: admin inventory, visual hierarchy, microcopy registry, a11y gates, and mobile CI without PROC-08/FIN-03/product-schema changes.
- v1.6 planning line closed 2026-04-21: Phases **30–31** remediated milestone audit gaps (verification corpus, SUMMARY traceability) and advisory VERIFY-01 / Copy / Playwright integration notes; audit status **passed** in `milestones/v1.6-MILESTONE-AUDIT.md`.
- v1.7 opened 2026-04-21: **ADOPT** + **OPS** requirements and **Phases 32–36** roadmap; research summarized in `.planning/research/SUMMARY.md`.
- v1.7 archived 2026-04-21: requirements + roadmap + milestone audit under `.planning/milestones/v1.7-*`; root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.7`**.
- v1.8 opened 2026-04-21: **ORG-04** (non-Sigra org billing recipes + host integration depth); phases **37+**; **PROC-08** and **FIN-03** remain deferred.
- v1.8 closed 2026-04-22: Phases **37–39** complete; **ORG-05..ORG-09** validated; adoption matrix + `verify_adoption_proof_matrix.sh` + `scripts/ci/README.md` ORG gates shipped; milestone archived under `.planning/milestones/v1.8-*`; root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.8`**.
- v1.9 opened 2026-04-21: **Observability & operator runbooks** after post–v1.8 prioritization; phases **40–42**; **PROC-08** / **FIN-03** unchanged as non-goals.
- v1.9 archived 2026-04-22: Phases **40–42** complete; **OBS/RUN/TEL** requirements validated; `.planning/milestones/v1.9-*`; root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.9`**.
- v1.10 opened 2026-04-21: **Metered usage + Fake parity**; phases **43–45**; requirements **MTR-01..MTR-08**; `phases.clear` skipped to preserve **40–42** phase trees.
- Phase **45** closed **2026-04-22**: docs + telemetry/runbook alignment (**MTR-07**, **MTR-08**) — metering guide, telemetry semantics anchor, runbook branches, optional testing/README cross-links.
- **2026-04-22:** `.planning/REQUIREMENTS.md` **MTR-01..MTR-06** checkboxes + traceability table aligned to **Phase 43** / **44** passed verification (was still “Pending” after Phase 45 close).
- **2026-04-22:** **v1.10** milestone archived (`milestones/v1.10-*`); root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.10`**.
- **2026-04-22:** **v1.11** opened — **Hex release + post-release continuity**; Phases **46–47**; requirements **REL-01..REL-04**, **DOC-01..DOC-02**, **HYG-01**.

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
*Last updated: 2026-04-22 — **v1.11** (Hex release + continuity) opened after **v1.10** archival.*
