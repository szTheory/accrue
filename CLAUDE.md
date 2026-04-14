<!-- GSD:project-start source:PROJECT.md -->
## Project

**Accrue**

Accrue is an open-source Elixir/Phoenix payments and billing library, inspired by Pay (Rails) and Laravel Cashier but built idiomatically for the Elixir/Ecto/Plug/Phoenix ecosystem. It gives Phoenix SaaS developers a batteries-included "jumpstart" for everything a real SaaS business needs on day one — subscriptions, checkout, invoices, coupons, emails, PDFs, webhooks, admin UI, telemetry — without the migration pain and design regrets earlier libraries accumulated.

Tagline: *"Billing state, modeled clearly."*

**Core Value:** **A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one** — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version. Everything else is in service of that.

### Constraints

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
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Technologies — `accrue` package
| Technology | Version Constraint | Purpose | Rationale |
|------------|-------------------|---------|-----------|
| Elixir | `~> 1.17` | Language | Locked in PROJECT.md. Matches `config/runtime.exs` era, native `Ecto.Repo.transact/2`, OTP 27 baseline. |
| Erlang/OTP | `27+` | Runtime | Locked. Required for Elixir 1.17. |
| `:phoenix` | `~> 1.8` | HTTP layer (optional-not-required at runtime, but we target 1.8 conventions) | Locked. Needed for verified routes and the 1.8 LiveView stream/function-component shape in `accrue_admin`. |
| `:ecto` | `~> 3.13` | Domain modeling | Bumped from `~> 3.12` because `ecto_sql` current is **3.13.5** (2025-11-09), and Accrue's `Repo.transact/2` usage is cleanest on 3.12+. `~> 3.13` is strict enough to guarantee the API we need. |
| `:ecto_sql` | `~> 3.13` | Repo + migrations | Pinned to match `:ecto` minor. Current **3.13.5**. |
| `:postgrex` | `~> 0.22` | PG driver | Current stable is **0.22.0** (2026-01-10). Postgrex is still pre-1.0 and Ecto 3.13 accepts `~> 0.20 or ~> 1.0`; pin to `~> 0.22` to avoid a surprise `0.23` minor that could churn JSONB encoding. No extensions required — `gen_random_uuid()` is in core since PG 13, which satisfies Accrue's PG 14+ floor. Do NOT require `pg_uuidv7` — not worth the install burden. |
| `:lattice_stripe` | `~> 1.1` | Stripe API wrapper | Sibling lib, v1.1.0 shipped 2026-04-14 (Hex.pm). Full Billing (Subscription/SubscriptionItem/SubscriptionSchedule/Invoice/InvoiceItem/Price/Product/Coupon/PromotionCode), Payments, Connect, Checkout Sessions, plus 1.1 additions: `Billing.Meter` + `Billing.MeterEvent` + `Billing.MeterEventAdjustment` (usage-based billing with two-layer idempotency) and `BillingPortal.Session` with 5-module nested `FlowData` struct tree + built-in `Inspect` masking for `:url`/`:flow`. Use `~> 1.1` to track 1.x patch/minor releases. `BillingPortal.Configuration` is deferred to lattice_stripe 1.2 — Dashboard-managed in the interim (matches Pay/Cashier convention). |
| `:oban` | `~> 2.21` | Async jobs (webhooks, email) | Community edition current is **2.21.1** (2026-03-26). Oban 2.21 requires Elixir 1.15+, Erlang 24+, PostgreSQL 14.0+ — all satisfied by our floor. Community edition (not Pro) is sufficient for v1.0; all features we need (retries, priority queues, uniqueness, cron, pruning) are in open-source Oban. No PG extensions required. |
| `:swoosh` | `~> 1.25` | Email delivery | Current **1.25.0** (2026-04-02). Wrapped behind `Accrue.Mailer` facade — but we list it as a direct dep (not optional) since email is a table-stakes feature and Swoosh is the Phoenix default. |
| `:phoenix_swoosh` | `~> 1.2` | HEEx template rendering for emails | Current **1.2.1** (2024-01-07). Older but stable; provides the `render_body/3` helper that lets us reuse HEEx templates for both email HTML and the PDF-source HTML. This is the glue that makes "single source of truth HEEx → email + PDF" work. |
| `:mjml_eex` | `~> 0.13` | Responsive email via MJML | Current **0.13.0** (2025-12-15). The "swoosh_mjml" name from PROJECT.md does NOT exist on Hex — the idiomatic package is Alex Koutmos's `mjml_eex`, which compiles MJML via a Rustler NIF (default) with a NodeJS fallback. Integrates with phoenix_swoosh as a template engine. **Update PROJECT.md to say `mjml_eex` not `swoosh_mjml`.** |
| `:chromic_pdf` | `~> 1.17` | Default PDF adapter | Current **1.17.1** (2026-03-19). Requires Chrome/Chromium available on the host (Chrome ≥ 91 for full-page screenshots; core rendering works on older) and Ghostscript for PDF/A. Supervise via `{ChromicPDF, on_demand: true}` in dev/test and persistent pool in prod. In library design: ChromicPDF must NOT be started by the Accrue application — it's started by the host app's supervision tree, and the `Accrue.PDF.ChromicPDF` adapter only calls into it. In tests, use `Accrue.PDF.Test` adapter so no Chrome binary is needed in CI. |
| `:nimble_options` | `~> 1.1` | Config schema + validation | Current **1.1.1** (2024-05-25). Feature-complete; slow release cadence is fine. Use for `Accrue.Config` schema, surfaced via `NimbleOptions.docs/1` in the ExDoc for `Accrue` module. |
| `:telemetry` | `~> 1.3` | Event instrumentation | Current 1.3.x. No-brainer — already transitively pulled in by Phoenix/Ecto/Oban but declare explicitly. |
| `:telemetry_metrics` | `~> 1.1` | Metric aggregation helpers | Current **1.1.0** (2025-01-24). Only needed if Accrue ships default metric definitions for users to feed into their reporter; make it **optional** since users may prefer their own `telemetry_metrics` setup. |
| `:jason` | `~> 1.4` | JSON | Current stable **1.4.4** (2024-07-26). Still the Elixir community default; Poison is abandoned. Used for the `data` jsonb columns in `accrue_webhook_events` and `accrue_events`. |
### Core Technologies — `accrue_admin` package
| Technology | Version Constraint | Purpose | Rationale |
|------------|-------------------|---------|-----------|
| `:accrue` | `== <same version>` | Core billing lib | Sibling dep via `path:` in dev (monorepo) and version-pinned in published releases. Must be exact version match per release — documented in release script. |
| `:phoenix_live_view` | `~> 1.1` | LiveView dashboard | Current **1.1.28** (2026-03-27). LiveView 1.1 is the stable line; `~> 1.1` gets us 1.1.x patches without 1.2 surprises. Admin UI is the only place LiveView appears — core `accrue` stays LiveView-free. |
| `:phoenix` | `~> 1.8` | Router/Endpoint | Same as core. |
| `:phoenix_html` | `~> 4.2` | HEEx helpers | LiveView 1.1 requires phoenix_html 4.x. |
### Optional Dependencies
| Library | Version | Marker | Integration Point |
|---------|---------|--------|-------------------|
| `:sigra` | `~> 0.1` | `optional: true` | Auto-detected; conditionally compiles `Accrue.Integrations.Sigra` adapter. See "Conditional Compilation" section below. |
| `:opentelemetry` | `~> 1.7` | `optional: true` | Current **1.7.0** (2025-10-17). Accrue's OTel span helpers no-op if `:opentelemetry` is not loaded. |
| `:opentelemetry_ecto` | `~> 1.2` | `optional: true` | Current **1.2.0** (2024-02-06). User-wired, not Accrue-wired — we document the attach call in guides. |
| `:opentelemetry_phoenix` | `~> 2.0` | `optional: true` | Current **2.0.1** (2025-02-21). Same — user wires, we document. |
| `:telemetry_metrics` | `~> 1.1` | `optional: true` | Only if user opts into Accrue's default metrics module. |
### Development / Test Dependencies (`accrue` package)
| Library | Version | `only:` | Purpose |
|---------|---------|---------|---------|
| `:ex_doc` | `~> 0.40` | `[:dev]`, `runtime: false` | Current **0.40.1** (2026-01-31). ExDoc with guides + cheatmd. |
| `:credo` | `~> 1.7` | `[:dev, :test]`, `runtime: false` | Current **1.7.18** (2026-04-10). Use `credo --strict` in CI. |
| `:dialyxir` | `~> 1.4` | `[:dev, :test]`, `runtime: false` | Current **1.4.7** (2025-11-06). |
| `:mix_audit` | `~> 2.1` | `[:dev, :test]`, `runtime: false` | Current **2.1.5** (2025-06-09). Run in CI via `mix deps.audit`. |
| `:excoveralls` | `~> 0.18` | `[:test]` | Current **0.18.5** (2025-01-26). Coverage → Coveralls/Codecov. |
| `:stream_data` | `~> 1.3` | `[:dev, :test]` | Current **1.3.0** (2026-03-09). Property tests for money math (zero-decimal currencies, proration, rounding). Non-negotiable for a billing library. |
| `:mox` | `~> 1.2` | `[:test]` | Current **1.2.0** (2024-08-14). **See "Test Library Decision" below.** |
| `:bypass` | `~> 2.1` | `[:test]` | HTTP server fake for testing the Fake Processor + webhook plug. Not strictly required since lattice_stripe already has its own test helpers, but useful for end-to-end plug tests. Optional — add only if we find ourselves reaching for it. |
## Test Library Decision: Mox, Decisively
## Installation — mix.exs Template
### `accrue/mix.exs` (core)
### `accrue_admin/mix.exs`
## Version Compatibility Matrix
| Anchor Pin | Forces | Notes |
|------------|--------|-------|
| `elixir ~> 1.17` | OTP 27+, Phoenix 1.8+, LiveView 1.1+ | Locked. |
| `ecto ~> 3.13` | `ecto_sql ~> 3.13`, `postgrex ~> 0.22` | Ecto 3.13 supports `postgrex ~> 0.20 or ~> 1.0` but we pin tighter. |
| `oban ~> 2.21` | Postgres 14+, Ecto 3.12+ | Already matches our floor. Oban uses `ecto_sql` directly; no conflict. |
| `phoenix ~> 1.8` | `phoenix_html ~> 4.1+`, `plug ~> 1.16` | Transitive. |
| `phoenix_live_view ~> 1.1` | `phoenix ~> 1.7 or ~> 1.8`, `phoenix_html ~> 4.2` | Admin-only. |
| `chromic_pdf ~> 1.17` | Chrome/Chromium on host (runtime, not mix) | Document in install guide, not enforceable via deps. |
| `mjml_eex ~> 0.13` | Rustler NIF build OR local `node` + `mjml` npm package | Default is the Rustler-built binary (no Node required at runtime). Document Rustler fallback. |
| `sigra ~> 0.1` (optional) | If present: `phoenix ~> 1.8`, `ecto ~> 3.12`, `nimble_options ~> 1.1` | All already in our deps. Zero conflict risk. |
| `lattice_stripe ~> 0.2` | `finch ~> 0.19`, `plug_crypto ~> 2.0` | Finch pulls in Mint/Mimir — ~4 transitive packages. Acceptable. |
### Elixir / OTP / Phoenix CI Matrix
| Elixir | OTP | Phoenix | Notes |
|--------|-----|---------|-------|
| 1.17.x | 27 | 1.8.x | Floor — this is the minimum supported. |
| 1.18.x | 27 | 1.8.x | Primary development target. |
| 1.18.x | 28 | 1.8.x | Forward-compat smoke test. |
## Conditional Compilation for Optional Deps
### 1. Declare optional in `deps/0`
### 2. Silence compiler warnings for undefined optional modules
### 3. Guard the integration module at `use` time
### 4. Runtime dispatch via config, not compile-time
## Config Boundaries: Compile-time vs Runtime
| Setting | Where | Why |
|---------|-------|-----|
| `:auth_adapter`, `:pdf_adapter`, `:mailer_adapter`, `:processor` | `config/config.exs` (compile-time OK) | Adapter resolution is stable per-deploy; compile-time is fine and slightly faster at lookup. Use `Application.compile_env!/2` inside Accrue modules so misconfig fails at `mix compile`, not at runtime. |
| `:stripe_secret_key`, `:webhook_signing_secret` | `config/runtime.exs` (MUST be runtime) | Secrets come from env vars at release-start; compile-time reading leaks build secrets into release artifacts. |
| `:default_currency`, `:from_email`, brand colors | `config/runtime.exs` | Host-owned, may differ per-env. |
| `:oban` queue config | Host-owned, runtime | Accrue documents recommended queues (`accrue_webhooks: 10`, `accrue_mailers: 20`), host wires into their own Oban config. Accrue does NOT start its own Oban instance. |
| Feature flags (e.g., enable_dunning?) | `config/runtime.exs` | Want to toggle without recompile. |
## Monorepo Layout — grounded in precedent
- **Membrane Framework** (`membraneframework/membrane_core` + many `membrane_*_plugin` repos) — actually multi-repo, not monorepo. Reject as precedent.
- **Broadway** (`dashbitco/broadway` + `broadway_kafka` / `broadway_rabbitmq` / `broadway_sqs`) — multi-repo. Reject.
- **Nerves** (`nerves-project/nerves`) — single-repo single-package. Reject.
- **Absinthe** (`absinthe-graphql/absinthe` + `absinthe_phoenix`, `absinthe_plug`) — multi-repo. Reject.
- **Phoenix** itself (`phoenixframework/phoenix` + `phoenix_live_view` + `phoenix_ecto`) — multi-repo. Reject.
- **Oban** (`oban-bg/oban` + `oban_web` + `oban_pro`) — Oban core is single-repo; Oban Web is separate. Reject the "same repo, two packages" precedent here.
- **`lattice_stripe`** (sibling, same author) — single-repo single-package but already uses Release Please with `release-please-config.json`. Use as the template.
### Proposed layout
### Release Please config for 2-package Elixir monorepo
- v4 changed output naming — outputs are now prefixed with the package path (`accrue--release_created`, not `accrue.release_created`). Verify with a dry-run before relying on them.
- `release-type: "elixir"` natively updates `mix.exs` `@version` — no custom extra-files needed if `@version "x.y.z"` is at the top of `mix.exs` (which both sibling projects already do).
- `bump-minor-pre-major: true` + `bump-patch-for-minor-pre-major: false` means `feat:` → minor, `fix:` → minor (NOT patch) pre-1.0. This matches how `lattice_stripe` is configured. Flip `bump-patch-for-minor-pre-major` to `true` if we want patch bumps for fixes pre-1.0.
- Version lockstep between `accrue` and `accrue_admin` is NOT enforced by Release Please — both can drift independently. We handle the same-day-v1.0 release by manually coordinating the two release PRs.
## Dialyzer PLT Caching Pattern (GitHub Actions, 2026)
- name: Restore PLT cache
- name: Create PLTs
- name: Save PLT cache
- name: Run dialyzer
- `actions/cache/restore@v4` + `actions/cache/save@v4` split (not the combined `actions/cache@v4`) so saves only happen on cache miss — prevents cache thrashing.
- PLT path must be `priv/plts` (or whatever's in `mix.exs` `dialyzer.plt_local_path`).
- Cache key is OTP version × Elixir version × mix.lock hash — NOT on git SHA.
- `--format github` surfaces warnings as GitHub Actions annotations.
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `:mox` | `:mimic` | Only if we end up needing to mock modules we don't own (e.g., if we decide to mock `LatticeStripe.Customer` directly in adapter tests rather than dispatching through our own behaviour). We shouldn't, because the Fake Processor pattern eliminates this need. |
| `:mox` | `:hammox` | If we hit a case where Mox 1.2's contract-checking isn't strict enough. Unlikely. |
| `:chromic_pdf` | `:gotenberg` (sidecar) | When host app runs in a Chrome-hostile environment (some serverless, some locked-down containers). Documented as a custom `Accrue.PDF` adapter, not as a first-party default. |
| `:mjml_eex` | `:mjmleex` (Elonsoft) | `mjml_eex` has more downloads, active maintenance (0.13 in Dec 2025), and a Rustler NIF backend. Only choose `mjmleex` if Rustler build fails on a target arch. |
| `:phoenix_swoosh` | Hand-rolled EEx + Swoosh.Email | Phoenix Swoosh is 300 lines and provides exactly the template integration we need. No reason to hand-roll. |
| `:jason` | `:poison`, `:jiffy`, `JSON` (stdlib 1.18+) | **Reconsider `JSON` (OTP 28 stdlib module)** post-v1.0. For v1.0 stay on `:jason` — it's zero-dep in practice (already transitive through Phoenix/Ecto) and every Elixir library is tested against it. OTP 28's native `JSON` isn't universally adopted in the Phoenix ecosystem yet. |
| `:oban` (community) | `:oban_pro` | Oban Pro's features (workflows, batches, smart engines) are not needed for v1.0. Accrue only uses Oban for webhook retry and email dispatch — both core-edition features. |
| `:opentelemetry` as required dep | `:opentelemetry` as optional dep | We went with optional. OTel's dep tree is ~15 packages and forces users who just want `:telemetry` to carry it. |
| `:nimble_options` | `:vex`, hand-rolled `with`-chains | NimbleOptions is the ecosystem default since Phoenix started using it for router/plug opts. Hand-rolled validation fails at the "docs generation" step — NimbleOptions gives us `Accrue.Config` docs for free. |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `:stripity_stripe` | Pinned to 2019 Stripe API; Bling's dependence on it is exactly the gap we're replacing. | `:lattice_stripe` (our own, tracking Stripe `2026-03-25.dahlia`). |
| `:bamboo` | Maintenance-mode; Phoenix moved to Swoosh as default in 1.6. | `:swoosh`. |
| `:poison` | Abandoned; Jason is ~2× faster and is the ecosystem default. | `:jason`. |
| `:exq` / `:verk` / `:rihanna` | Either abandoned or niche. Oban is the Elixir job-queue standard in 2026. | `:oban`. |
| `:httpoison` / `:tesla` for Stripe calls | Accrue should not make HTTP calls directly — all Stripe traffic goes through `:lattice_stripe`, which uses `:finch` internally. | `:lattice_stripe`. |
| `:commanded` / `:eventstore` | CQRS/ES is the wrong abstraction for billing — already rejected in PROJECT.md key decisions. | Append-only `accrue_events` table. |
| `:pdf_generator` | Wraps wkhtmltopdf, which is archived and has unpatched CVEs. | `:chromic_pdf`. |
| `:absinthe` (GraphQL) | Accrue is not GraphQL-shaped — REST-ish context functions are idiomatic Phoenix. | Plain `Accrue.Billing` context. |
| `:ueberauth` | Not our layer — Accrue doesn't own auth. | `Accrue.Auth` behaviour, host app owns Ueberauth/Sigra/phx.gen.auth. |
| `:mock` (the library) | Global mutation, flaky under async, community consensus is to avoid. | `:mox`. |
| `pg_uuidv7` Postgres extension | Adds install burden; `gen_random_uuid()` is in PG 14 core and is good enough. UUIDv7 benefits are marginal for Accrue's access patterns. | Built-in `gen_random_uuid()`. |
| `:decimal` as an unpinned transitive | Pin it explicitly — money math correctness depends on it. | `{:decimal, "~> 2.0"}` (already transitive through Ecto, but pin it). |
## Full Expected Transitive Footprint
## Sources
- Hex.pm API (verified 2026-04-11, HIGH confidence):
- Sibling project source-of-truth (HIGH confidence):
- Release Please for Elixir (MEDIUM confidence — one primary source):
- Mocking library positioning (MEDIUM confidence — synthesis across sources):
- ChromicPDF requirements (MEDIUM confidence — official docs do not specify exact Chrome minimum for base rendering):
- Oban 2.21 requirements (HIGH confidence):
## Flags for Roadmap Consumer
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
