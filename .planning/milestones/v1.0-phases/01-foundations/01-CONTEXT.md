# Phase 1: Foundations - Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 delivers the **headless primitives** that every downstream phase depends on:

- `Accrue.Money` value type (zero/three-decimal currency safety, mismatched-currency arithmetic raises)
- `Accrue.Error` exception hierarchy mapped from Stripe errors
- `Accrue.Config` (NimbleOptions-backed runtime config)
- `Accrue.Telemetry` event naming conventions + optional `Accrue.Telemetry.Metrics`
- `Accrue.Application` empty-supervisor pattern (host owns Repo/Oban/Finch)
- `Accrue.Processor` behaviour + `Accrue.Processor.Fake` (primary test surface with deterministic IDs and manual test clock)
- `Accrue.Processor.Stripe` adapter — the *only* module that knows about `lattice_stripe`; maps raw Stripe errors to `Accrue.Error`
- Append-only `accrue_events` table with DB-enforced immutability (trigger + REVOKE grants)
- `Accrue.Events.record/1` + `Accrue.Events.record_multi/3` — transactional event recording API used by every downstream state mutation
- `Accrue.Mailer` behaviour + `Accrue.Mailer.Default` (ships working HEEx/MJML templates, Oban-backed async, Pay-style graduated overrides)
- `Accrue.PDF` behaviour + `Accrue.PDF.ChromicPDF` default adapter + `Accrue.PDF.Test` test adapter (Shape B: HTML binary in, PDF bytes out)
- `Accrue.Auth` behaviour + `Accrue.Auth.Default` fallback (dev-permissive, prod-refuses-to-boot)
- Monorepo layout: sibling mix projects `accrue/` + `accrue_admin/` with lockstep-major / independent-minor versioning
- Brand palette CSS variables (`Ink/Slate/Fog/Paper + Moss/Cobalt/Amber`) in `lib/accrue/brand.css`
- MIT `LICENSE` files
- `with_sigra` / `without_sigra` conditional-compile pattern passing `mix compile --warnings-as-errors`

**Out of scope for Phase 1:** Billing context (Customer, Subscription, Invoice schemas), webhook plug, specific email templates beyond skeleton, Admin UI. These land in Phase 2+ and all consume the primitives defined here.

</domain>

<decisions>
## Implementation Decisions

### Money Type

- **D-01: Thin wrapper over `:ex_money`.** `Accrue.Money` is our public value type; internally delegates currency table, formatting, and CLDR correctness to `:ex_money` (Kip Cole's lib). We own the API shape; we inherit 180+ currency correctness.
- **D-02: Ecto representation is two columns: `amount_minor :bigint` + `currency :string` (ISO 4217 code).** Cast to `Accrue.Money` via a custom `Accrue.Ecto.Money` type. Works naturally with zero-decimal (JPY) and three-decimal (KWD) currencies; indexable and analytics-friendly.
- **D-03: Primary constructor is `Accrue.Money.new(minor_units :: integer, currency :: atom)`.** `Accrue.Money.new(1000, :usd)` = $10.00. Matches Stripe's API directly so developers paste Stripe integers and it just works. Passing a `Decimal` or float to `new/2` raises `ArgumentError` (explicit conversion via `Accrue.Money.from_decimal/2` is available as a secondary helper).
- **D-04: Cross-currency arithmetic raises `Accrue.Money.MismatchedCurrencyError`.** Success criterion #1 demands this. No silent failures, no tagged-tuple returns on math.

### Error Hierarchy & Return Style

- **D-05: Ecto-style dual API: tuple primary + raise! variants.** Every public function in `Accrue.Billing` and `Accrue.Processor` has two forms: `create_subscription/2` returning `{:ok, sub} | {:error, %Accrue.CardError{}}`, and `create_subscription!/2` that raises. Matches `Ecto.Repo`, Phoenix context conventions, and pipeline idioms.
- **D-06: Rich error structs.** `%Accrue.CardError{code, message, decline_code, param, processor_error, request_id, http_status}` and siblings (`%Accrue.RateLimitError{}`, `%Accrue.SignatureError{}`, `%Accrue.APIError{}`, `%Accrue.IdempotencyError{}`, `%Accrue.DecodeError{}`, `%Accrue.ConfigError{}`). Each implements `Exception` so raise works; each is pattern-matchable for retry logic. Mirrors Stripe's error object 1:1 plus our fields.
- **D-07: Stripe-error-to-Accrue.Error mapping happens in `Accrue.Processor.Stripe` only.** The processor adapter is the ONLY place that knows about `lattice_stripe`. Billing context and everything downstream sees only `Accrue.Error` subtypes. Enforces the facade principle from PROJECT.md.
- **D-08: `Accrue.SignatureError` raises, does not return a tuple.** A bad webhook signature means either config error or an attacker — neither is recoverable at the call site. The webhook plug's error translator returns HTTP 400 on raise.

### Event Ledger Immutability

- **D-09: Both BEFORE UPDATE/DELETE trigger AND REVOKE grants.** Defense in depth. The trigger protects single-role dev setups; the REVOKE grants protect against trigger-disabling superusers. Success criterion #4 is satisfied by either; we ship both.
- **D-10: Role management is host-owned with strong docs + runtime check.** Accrue does NOT create Postgres roles. `mix accrue.install` generates a migration stub showing the `REVOKE UPDATE, DELETE, TRUNCATE ON accrue_events FROM accrue_app` statements for the user to run. `Accrue.Application` boot runs `SELECT has_table_privilege(current_user, 'accrue_events', 'UPDATE')`; if the role CAN update, logs a warning (or raises in prod when `config :accrue, enforce_immutability: true`).
- **D-11: Trigger raises with custom SQLSTATE `45A01` and a clear message.** Elixir side pattern-matches `%Postgrex.Error{postgres: %{code: :accrue_event_immutable}}` and re-raises as `Accrue.EventLedgerImmutableError` via Repo wrapper. No fragile message-string parsing.
- **D-12: `Accrue.Events.Event` Ecto schema exists for reads and `changeset/2` for writes, but the module does NOT expose update/delete helpers.** Typed reads for timeline queries, replay, and analytics. Any attempted mutation would hit the trigger anyway.

### Events.record Ergonomics

- **D-13: Both `Accrue.Events.record/1` (inside `Repo.transact/2` blocks) AND `Accrue.Events.record_multi/3` (for `Ecto.Multi` pipelines).** Downstream phases pick the style that fits their call site. Both paths go through the same validated changeset. Mirrors Ecto's dual `Multi.insert` / `Repo.insert` surface.
- **D-14: `idempotency_key` is optional caller-provided with a nullable unique index.** Webhook path passes the Stripe event ID so replay is a no-op via `on_conflict: :nothing` returning the existing row. Internal path leaves it `nil`. No auto-generated UUIDs — idempotency keys must come from upstream to actually deduplicate.
- **D-15: Actor context via process dictionary + explicit override.** `Accrue.Actor.put_current/1` is called by `Accrue.Plug.PutActor` (reads `Accrue.Auth.current_user/1`) and by Oban worker middleware. `Events.record/1` reads `Accrue.Actor.current/0` by default; accepts `actor: ...` keyword to override. Actor enum values are fixed: `user | system | webhook | oban | admin`.
- **D-16: OpenTelemetry trace_id auto-captured via `Accrue.Telemetry.current_trace_id/0`** which reads from `OpenTelemetry.Tracer.current_span_ctx` when `:opentelemetry` is loaded, returns `nil` otherwise (conditional compile). Zero boilerplate for OTel users; graceful no-op for others.

### Telemetry

- **D-17: 4-level event names.** `[:accrue, :billing, :subscription, :create, :start]` etc. Domain layer (`:billing`, `:events`, `:webhooks`, `:mail`, `:pdf`, `:processor`) sits between `:accrue` and the resource. Suffixes follow the `:telemetry.span/3` convention: `:start`, `:stop`, `:exception`. Matches Ecto's `[:ecto, :repo, :query]` and Phoenix's `[:phoenix, :endpoint, :start]` depth.
- **D-18: Ship `Accrue.Telemetry.Metrics` as an optional helper module** that returns a list of `Telemetry.Metrics` definitions (counters, distributions, last_values) users merge into their own `Telemetry.Supervisor`. Optional dep on `:telemetry_metrics` per CLAUDE.md.

### Processor.Fake

- **D-19: Explicit test clock with `Accrue.Processor.Fake.advance/2`.** Fake holds an in-memory clock; tests call `Accrue.Processor.Fake.advance(server, duration)` to move time forward, which triggers time-dependent events (trial_ending, subscription_renewed, invoice.finalized). All Fake timestamps derive from this clock — never wall-clock. Matches Stripe's own test-clock API so tests read like production behavior.
- **D-20: Deterministic IDs with per-resource prefixed counters.** `cus_fake_00001`, `sub_fake_00001`, `in_fake_00001`, `pi_fake_00001`, `pm_fake_00001`. Resettable via `Accrue.Processor.Fake.reset/0` in ExUnit setup. Readable in test output; deterministic across runs.

### Mailer Behaviour (Pay-style, Pow-compatible)

- **D-21: Single callback `c:deliver(type :: atom, assigns :: map)` — semantic API, NOT `%Swoosh.Email{}`-based.** Research verdict: Pow's `Pow.Phoenix.Mailer` behaviour is the closest Elixir precedent for "library wraps Swoosh"; it takes semantic args, not structs. Accepting `%Swoosh.Email{}` would leak Swoosh into the public API AND break Oban serialization (structs with function refs don't round-trip JSON).
- **D-22: `Accrue.Mailer.Default` is the default adapter; pipeline is:**
  1. `Accrue.Mailer.deliver(:payment_succeeded, %{customer_id: id, invoice_id: id})` (Oban-safe atoms + IDs, no structs in args)
  2. Default adapter looks up `Accrue.Emails.PaymentSucceeded` (one module per email type, each `use Phoenix.Swoosh` with `formats: %{"mjml" => :html_body, "text" => :text_body}`)
  3. Module's `build/1` re-hydrates entities from DB, builds `%Swoosh.Email{}` via `phoenix_swoosh` + `mjml_eex`
  4. Delivers via `Accrue.Mailer.Swoosh` (`use Swoosh.Mailer, otp_app: :accrue`)
  5. By default, enqueues `Accrue.Workers.Mailer` Oban job on queue `:accrue_mailers` — async delivery
- **D-23: Pay-style graduated override ladder.**
  1. `config :accrue, emails: [payment_succeeded: false]` — kill switch per email type
  2. `config :accrue, emails: [trial_ending: {MyApp.Billing, :should_send?, []}]` — conditional MFA callback
  3. `config :accrue, email_overrides: [payment_succeeded: MyApp.Emails.CustomReceipt]` — replace one template module (implements `c:build/1` → `%Swoosh.Email{}`)
  4. `config :accrue, mailer: MyApp.AccrueMailer` — replace the whole pipeline wholesale
- **D-24: Rich global brand config read from `Accrue.Config` by every default email template.** `business_name`, `business_address`, `logo_url`, `support_email`, `from_email`, `from_name`, brand color tokens. 90% of users never publish templates; setting brand config once updates everything.
- **D-25: Per-email toggle via `config :accrue, emails: [...]`** supports `boolean | {Mod, :fun, args}` — Pay-literal convention.
- **D-26: Accrue.Mailer.Swoosh is `use Swoosh.Mailer, otp_app: :accrue`** so host can point it at their existing adapter (`config :accrue, Accrue.Mailer.Swoosh, adapter: ...`) without configuring SendGrid twice. Default uses `Swoosh.Adapters.Local` in dev, delegates to host in prod.
- **D-27: Oban worker payload is `{type :: atom, %{entity IDs only}}`. Worker re-hydrates from DB at delivery time** — prevents stale snapshots, survives JSON round-trips, keeps the queue small.
- **D-28: Accrue telemetry emits `[:accrue, :mailer, :deliver, :start|:stop|:exception]` with `%{email_type: t, customer_id: id}` metadata.** Swoosh's own `[:swoosh, :deliver, ...]` events fire underneath — two clean layers, both attachable.
- **D-29: Test helpers: ship BOTH.** `Swoosh.TestAssertions.assert_email_sent/1` works automatically (default path terminates in `Swoosh.Adapters.Test`). Additionally ship `Accrue.Test.Mailer.assert_email_sent(:payment_succeeded, customer: c)` for semantic assertions on type + assigns without parsing rendered HTML.
- **D-30: MJML templates are the default email format via `mjml_eex`**, with automatic text-body fallback via `"text" => :text_body` in `formats:`. Plain HEEx HTML is supported as the fallback when MJML Rustler NIF build fails on unusual arches.
- **D-31: `mix accrue.gen.emails` is a Mix task that copies default templates into `priv/accrue/templates/` in the host app** when users want to edit HEEx/MJML directly without writing override modules.

### PDF Behaviour (Shape B)

- **D-32: `c:render(html :: binary(), opts :: keyword())` — Shape B, HTML binary in, PDF bytes out.** Zero open-source Elixir PDF projects use a template-module callback shape; every real-world Phoenix+ChromicPDF example uses Shape B. Matches ChromicPDF's own public API (`{:html, binary}` / `{:url, _}` / `{:plug, _}`).
- **D-33: `Accrue.PDF.ChromicPDF` is the default adapter.** Calls `ChromicPDF.Template.source_and_options(content: html, size: :a4, ...) |> ChromicPDF.print_to_pdf()`. ChromicPDF is started by the HOST application's supervision tree, NOT by Accrue — document this loudly in the install guide.
- **D-34: `Accrue.PDF.Test` test adapter** sends `{:pdf_rendered, html, opts}` to `self()` and returns `{:ok, "%PDF-TEST"}`. Tests assert on HTML input, not PDF bytes. Runs Chrome-free in CI.
- **D-35: `opts` supported on `Accrue.PDF.render/2`:** `size` (`:a4 | :letter`), `header_html`, `footer_html`, `header_height`, `footer_height`, `archival` (`true` flips to `print_to_pdfa/2`, requires Ghostscript — not default). Pass-through to `ChromicPDF.Template.source_and_options/1` — don't opinionate on header/footer structure.
- **D-36: Core stays LiveView-free.** Callers flatten their own `Phoenix.Component` via `Phoenix.HTML.Safe.to_iodata/1 |> IO.iodata_to_binary/1` before calling `Accrue.PDF.render/2`. The Shape-A niceness ships in `accrue_admin` where LiveView is already a hard dep: `AccrueAdmin.PDF.render_component(component_fun, assigns, opts)` flattens + delegates. Single source of truth (one component drives email + PDF) is preserved at the caller layer, not inside Accrue.
- **D-37: Gotenberg adapter is documented as a custom-adapter path, not a first-party default.** For hosts in Chrome-hostile environments (serverless, locked-down containers).
- **D-38: Stripe-hosted PDF passthrough ships in Phase 2 (Billing context) as `Accrue.Billing.invoice_pdf(invoice, source: :auto | :stripe | :local)`.** `:auto` (default) tries Stripe first, falls back to local. Phase 1 only ships the generic `Accrue.PDF.render/2` primitive; the `source:` routing is a Phase 2 concern but noted here so Phase 2 planner knows the shape.
- **D-39: Auto-attach invoice PDF to the receipt email by default.** When `emails: [payment_succeeded: true]` fires, `Accrue.Workers.Mailer` renders the invoice PDF inside the worker (not at enqueue time) and attaches via `Swoosh.Email.attachment/2`. Disable via `config :accrue, attach_invoice_pdf: false`. If PDF rendering fails, log + send email without attachment rather than fail the whole send. PDFs NEVER live in Oban job args — too large and too ephemeral. (Note: this is Phase 2 behavior but the Phase 1 Mailer+PDF behaviours must be shaped to support it.)

### Auth

- **D-40: `Accrue.Auth.Default` is dev-permissive, prod-refuses-to-boot.** In `:dev` and `:test`, returns `%{id: "dev", email: "dev@localhost", role: :admin}`. In `:prod`, raises `Accrue.ConfigError` during `Accrue.Application.start/2` (or an earlier config validation step) with a clear error pointing at install docs. `require_admin_plug/0` is a no-op in dev/test, raises in prod.
- **D-41: Sigra auto-detection via compile-time conditional compile** (CLAUDE.md pattern). When `:sigra` is loaded, `Accrue.Integrations.Sigra` compiles as the auto-wired adapter and `Accrue.Auth.Default` is never invoked. When absent, `Accrue.Integrations.Sigra` module is not defined at all.

### Monorepo & Release

- **D-42: Sibling mix projects `accrue/` + `accrue_admin/`, non-umbrella.** CLAUDE.md locked this. Root directory holds `README.md`, `LICENSE`, `.github/workflows/`, `release-please-config.json`, `guides/` (shared ExDoc guides), `scripts/`.
- **D-43: Lockstep major versions, independent minor/patch.** `accrue_admin/mix.exs` pins `{:accrue, "~> 1.0"}` (tracks 1.x only). Minors and patches drift independently; both tag 1.0.0 from the same commit on day one. Release Please config has per-package entries with `release-type: "elixir"` and `bump-minor-pre-major: true`. Release PRs coordinated manually for the same-day 1.0.
- **D-44: `mix accrue.install` Mix task generates migrations, a `MyApp.Billing` context skeleton, router mounts, admin LiveView routes (when `accrue_admin` detected), and the REVOKE migration stub. Detects `:sigra` and auto-wires `Accrue.Integrations.Sigra`. Validates Chrome presence and warns if missing.** (Mix task implementation detail is Phase-1 planner decision.)

### Conditional Compile (Sigra)

- **D-45: Follow CLAUDE.md's 4-pattern conditional compile** exactly: optional dep in `deps/0`, `@compile {:no_warn_undefined, Sigra.X}` to silence warnings, guard integration module at `use` time, runtime dispatch via config not compile-time. Must pass `mix compile --warnings-as-errors` in both `with_sigra` and `without_sigra` matrices (success criterion #5).

### Claude's Discretion

The following are left to the Phase 1 planner / executor to decide:

- Exact module organization inside `lib/accrue/` (whether `Accrue.Money` is one file or split into `Money`, `Money.Currency`, `Money.Ecto`)
- `Accrue.Config` NimbleOptions schema field-by-field layout (the *what* is documented above; the schema details are implementation)
- Test organization (`test/accrue/`, property test placement, fixture strategy) — the only constraint is that `Accrue.Processor.Fake` is the primary test surface per TEST-01
- Exact migration filenames and order (just needs `accrue_events` table + trigger + REVOKE stub)
- `Accrue.Application.start/2` body specifics — empty-supervisor pattern is locked, but child list (if any — e.g., registry for Fake processor instances) is planner's call
- Internal naming of workers, middlewares, plugs beyond what's listed above
- Whether `Accrue.Mailer.Default` lives in `lib/accrue/mailer/default.ex` or is inlined
- Exact `Accrue.Emails.*` module count for Phase 1 — the behaviour and one reference template (`Accrue.Emails.PaymentSucceeded`) are Phase 1; the other ~14 templates can land in Phase 2+ when their triggering domain events exist
- Exact shape of `Accrue.Test.Mailer` / `Accrue.Test.PDF` helper modules

### Folded Todos

None — no backlog items matched Phase 1.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project governance
- `/Users/jon/projects/accrue/CLAUDE.md` — project instructions, constraints, full tech stack decisions, conditional-compile pattern, monorepo layout precedent, dialyzer/CI recipes
- `/Users/jon/projects/accrue/.planning/PROJECT.md` — vision, core value, requirements shape
- `/Users/jon/projects/accrue/.planning/REQUIREMENTS.md` — requirement IDs FND-01..07, PROC-01/03/07, EVT-01/02/03/07/08, AUTH-01/02, MAIL-01, PDF-01, OBS-01/06, TEST-01, OSS-11 (all within Phase 1 scope)
- `/Users/jon/projects/accrue/.planning/ROADMAP.md` — Phase 1 goal, success criteria, depends-on

### External library docs (fetch via Context7 or webfetch at plan time)
- `:ex_money` on hex.pm — Kip Cole's Money lib; reference for `Accrue.Money` wrapper (D-01..04)
- `ChromicPDF` hexdocs — https://hexdocs.pm/chromic_pdf/ChromicPDF.html and `ChromicPDF.Template` — reference for `Accrue.PDF.ChromicPDF` adapter (D-32..37)
- `phoenix_swoosh` hexdocs — https://hexdocs.pm/phoenix_swoosh/Phoenix.Swoosh.html — `render_body/3` + MJML `formats:` option (D-22, D-30)
- `mjml_eex` — https://github.com/akoutmos/mjml_eex — Rustler NIF MJML compiler (D-30)
- `Swoosh.Mailer` — https://hexdocs.pm/swoosh/Swoosh.Mailer.html — `otp_app:` runtime adapter resolution (D-26)
- `Swoosh.TestAssertions` — https://hexdocs.pm/swoosh/Swoosh.TestAssertions.html — test compatibility (D-29)
- `Pow.Phoenix.Mailer` — https://github.com/pow-auth/pow — closest Elixir precedent for wrapping Swoosh behind a semantic behaviour (D-21)
- `lattice_stripe ~> 0.2` — sibling library; reference for error shapes to map in `Accrue.Processor.Stripe` (D-07)
- `Oban` docs — https://hexdocs.pm/oban — unique constraints, queue config, worker middleware for actor context (D-15, D-27)
- `Ecto.Multi` + `Repo.transact/2` — https://hexdocs.pm/ecto/Ecto.Multi.html, https://hexdocs.pm/ecto/Ecto.Repo.html#c:transact/2 — reference for `Events.record` dual API (D-13)
- `NimbleOptions` — https://hexdocs.pm/nimble_options — `Accrue.Config` schema + auto-generated docs

### Prior art (consult for API shape, NOT for code copying)
- Pay (Rails) — https://github.com/pay-rails/pay — `lib/pay.rb` config shape, `app/mailers/pay/user_mailer.rb` graduated override ladder, `lib/pay/receipts.rb` PDF pattern (what to do: graduated overrides, rich brand config, auto-attach; what NOT to do: Prawn DSL layout)
- Laravel Cashier — https://github.com/laravel/cashier-stripe — `src/Invoices/DompdfInvoiceRenderer.php` pluggable renderer contract (what to copy: pluggable adapter; what NOT to do: Dompdf default, no brand config, all-or-nothing template publishing; see issues #677, #973, #1311)

### Real-world HEEx→PDF examples (read before writing `Accrue.PDF.ChromicPDF`)
- https://abulasar.com/adding-pdf-generate-feature-in-phoenix-liveview-app — canonical Shape-B pattern
- https://github.com/bitcrowd/chromic_pdf README — `ChromicPDF.Template.source_and_options/1` usage
- https://www.yellowduck.be/posts/rendering-a-heex-component-in-code — flattening `Phoenix.Component` without LiveView

### Testing-lib refs
- `Mox 1.2` — https://hexdocs.pm/mox — behaviour-backed mocking for all adapters (Processor, Mailer, PDF, Auth); CLAUDE.md locked Mox as the choice
- `StreamData 1.3` — https://hexdocs.pm/stream_data — property tests for `Accrue.Money` math (zero/three-decimal round-trips, mismatched-currency raises)

</canonical_refs>

<code_context>
## Existing Code Insights

**Greenfield project** — `/Users/jon/projects/accrue/` currently contains only `CLAUDE.md` and `.planning/`. No source code exists. Phase 1 is the codebase's first commit of Elixir code.

### Reusable Assets
- None in-repo. External reusable primitives (all declared as required deps in CLAUDE.md):
  - `:ex_money` for `Accrue.Money` wrapping
  - `:chromic_pdf` for PDF rendering
  - `:phoenix_swoosh` + `:mjml_eex` for email templates
  - `:nimble_options` for config validation
  - `:lattice_stripe` for Stripe HTTP (used by `Accrue.Processor.Stripe`)

### Established Patterns
None — Phase 1 IS the pattern-establishing phase for every downstream phase. Every decision above (Money constructor shape, error return style, Events.record API, telemetry depth, mailer semantic API, PDF Shape B) becomes a locked pattern after Phase 1 ships.

### Integration Points
- Host application's supervision tree — must start `ChromicPDF` and `Oban` themselves, NOT Accrue
- Host application's `MyApp.Mailer` — optional delegation target for `Accrue.Mailer.Swoosh` via `adapter:` config
- Host application's Repo — Accrue uses it via `config :accrue, :repo, MyApp.Repo`; does not supervise or start the Repo

</code_context>

<specifics>
## Specific Ideas

- **Pay's graduated override ladder is the specific model for D-23.** Four rungs (kill switch, MFA callback, template override, full pipeline replace) in that exact order.
- **Pow's `Pow.Phoenix.Mailer` behaviour shape is the specific model for D-21.** Semantic args, not `%Swoosh.Email{}`. Research verdict.
- **Ecto's dual `Multi.insert` / `Repo.insert` is the specific model for D-13** (`record_multi/3` + `record/1`).
- **Ecto's `Repo.insert/1` + `Repo.insert!/1` dual surface is the specific model for D-05** (tuple primary + raise variants).
- **ChromicPDF README invoice example is the reference implementation for `Accrue.PDF.ChromicPDF`** (D-33).
- **Stripe's test-clock API is the specific model for D-19** (`advance` helper, deterministic time).

</specifics>

<deferred>
## Deferred Ideas

These came up during discussion but belong in later phases. Noted so they're not lost and not re-surfaced as "missed" in future planning:

- **`Accrue.Billing.invoice_pdf(invoice, source: :auto | :stripe | :local)`** — Stripe-hosted PDF passthrough wrapping `lattice_stripe`. Depends on Phase 2 Invoice schema. D-38 documents the shape so Phase 2 planner knows what to build.
- **Auto-attach invoice PDF to receipt email** — requires Phase 2 Invoice + Customer schemas to exist. D-39 documents the intended default.
- **Full ~15-template email catalog** (`receipt`, `payment_action_required`, `subscription_renewing`, `trial_will_end`, `trial_ended`, `refund`, `invoice_finalized`, `invoice_paid`, `invoice_payment_failed`, `subscription_canceled`, `subscription_paused`, `subscription_resumed`, `coupon_applied`, `gift_sent`, `gift_redeemed`) — lands in Phase 2+ alongside the domain events that trigger them. Phase 1 ships the behaviour + `Accrue.Emails.PaymentSucceeded` as the reference template.
- **`Accrue.Integrations.Sigra` concrete callbacks** — the conditional-compile scaffold is Phase 1; actual adapter methods depend on `:sigra` API stabilization.
- **Customer Portal Session / Checkout Session helpers** — pure Stripe wrappers, Phase 2+.
- **Stripe Connect (Standard/Express/Custom)** — marketplace feature, later phase.

</deferred>

---

*Phase: 01-foundations*
*Context gathered: 2026-04-11*
