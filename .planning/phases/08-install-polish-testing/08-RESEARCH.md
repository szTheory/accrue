# Phase 08: Install + Polish + Testing - Research

**Researched:** 2026-04-15  
**Domain:** Elixir/Phoenix installer DX, generated host wiring, billing test helpers, optional OpenTelemetry spans  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Installer Flow and Overwrite Safety

- **D8-01:** Build `mix accrue.install` on an Igniter-style diff/review patching model, not a plain `Mix.Generator` overwrite prompt. The installer must present planned changes, support review before apply, and make router/config/application edits through structured patchers where possible.
- **D8-02:** Prompts are only for genuine product choices: billable schema, billing context module, webhook path, admin mount path, whether to wire `accrue_admin` when present, and whether to wire Sigra when detected. Every prompt must have a flag so CI and scripted installs can run non-interactively.
- **D8-03:** Required installer flags: `--dry-run` for review-only, `--yes` or `--non-interactive` for CI/default acceptance, `--manual` for generate snippets without mutating existing host files, and `--force` only for regenerating pristine Accrue-owned generated files.
- **D8-04:** Re-runs are idempotent and never silently clobber edited host files. If an existing file matches the previous generated fingerprint, it may be updated. If it has user edits, the installer must skip with actionable instructions or show a reviewable diff. Conflict markers are allowed only behind an explicit expert flag such as `--write-conflicts`.
- **D8-05:** The installer should advise users to commit first, matching Phoenix generator norms, then report exactly what changed, what was skipped, and what manual follow-up remains.

### Generated Host-App Surface

- **D8-06:** Generate a thin host-owned `MyApp.Billing` facade over library-owned Accrue core APIs. Host code owns app policy, naming, routing, Repo wiring, and auth boundaries; Accrue keeps provider normalization, billing operations, signature verification, event decoding, idempotency primitives, and admin internals library-owned.
- **D8-07:** Generate/copy host migrations for Accrue tables, including event immutability REVOKE stub material from Phase 1. Migrations belong in the host repo because the host owns Repo and deployment order.
- **D8-08:** Generate a small webhook endpoint scaffold that delegates verification, idempotent ingest, dispatch, and built-in reducers to Accrue while giving the host explicit handler callbacks for custom side effects.
- **D8-09:** Router changes should be explicit and reviewable. The installer may patch the router in the default flow only through the safe diff/review mechanism; `--manual` prints exact snippets instead.
- **D8-10:** When `accrue_admin` is present, offer to mount `accrue_admin "/billing"` using the existing `AccrueAdmin.Router` macro. Admin UI remains library-owned; the generated host surface only mounts and protects it.
- **D8-11:** When Sigra is detected, auto-wire `Accrue.Integrations.Sigra` as the auth adapter. When absent, configure `Accrue.Auth.Default` with the existing prod fail-closed warning behavior and print the supported community-adapter path.
- **D8-12:** Generate or patch test-support setup for Accrue's Fake Processor and assertion helpers, but keep helper implementation in Accrue. Host tests should import a stable public facade rather than copied helper internals.
- **D8-13:** Oban queue/supervision wiring is detected and patched when safe; otherwise the installer prints exact queue and supervision snippets. Accrue must not assume it owns the host Oban lifecycle.

### Test Helper API

- **D8-14:** Ship a unified `Accrue.Test` facade for host apps, backed by focused internal modules. The default host experience should be one import/use from `DataCase` or `ConnCase`, while internals stay modular to avoid a junk drawer.
- **D8-15:** Action helpers are functions, not macros: `advance_clock/2`, `trigger_event/2`, and any Oban/Fake setup helpers return useful values and compose in normal Elixir tests.
- **D8-16:** Assertion helpers may be macros when failure messages materially improve DX. Public assertions include `assert_email_sent/1`, `assert_email_sent/2`, `assert_pdf_rendered/1`, `assert_event_recorded/1`, and refute/no-op companions where useful.
- **D8-17:** Matchers should accept keyword filters, structs/subjects, partial maps, and one-arity predicate functions. Failure output must show what Accrue observed and why it did not match.
- **D8-18:** Captures are process-owned and async-safe by default, following the existing mail/PDF helper pattern. Cross-process/background assertions use an explicit owner/global mode documented with the same caution as Mox and Swoosh global modes.
- **D8-19:** `advance_clock/2` should accept both readable duration forms and precise keyword forms, then drive the Fake Processor/test clock rather than sleeping. The helper should surface lifecycle effects such as trial ending, renewal, invoice finalization, dunning, and cancellation.
- **D8-20:** `trigger_event/2` should synthesize Accrue/Stripe-shaped webhook events through the normal handler path, not bypass reducers. Tests should prove the same idempotency, event ledger, mail, PDF, and Oban behavior users get in production.

### OpenTelemetry Span Policy

- **D8-21:** Implement true OpenTelemetry spans through a small `Accrue.Telemetry.OTel` adapter invoked by the existing `Accrue.Telemetry.span/3` path. When OpenTelemetry is absent, the adapter is a no-op and the project still compiles cleanly with warnings as errors.
- **D8-22:** Keep `:telemetry` as the stable Elixir-native surface. OTel spans mirror the same event naming and do not replace telemetry handlers or metrics recipes.
- **D8-23:** Span names are derived consistently from Accrue telemetry names, for example `[:accrue, :billing, :subscription, :create]` becomes `accrue.billing.subscription.create`.
- **D8-24:** Span attributes must be explicit, sanitized, and allowlisted. Allowed business attributes include `accrue.processor`, `accrue.customer_id`, `accrue.subscription_id`, `accrue.invoice_id`, `accrue.event_type`, and operation/result status fields. Never attach raw Stripe payloads, card data, emails, addresses, request bodies, API keys, signing secrets, or large metadata blobs.
- **D8-25:** Avoid macro-generated broad instrumentation as the default. Safe attribute extraction is the hard part, so call sites or small wrappers must pass explicit business metadata.
- **D8-26:** Tests must cover both `with_opentelemetry` and `without_opentelemetry` compile paths, no undefined warnings, no double instrumentation assumptions, and privacy guardrails for prohibited attributes.

### Testing Guide

- **D8-27:** The testing guide should be a Fake-first scenario playbook, not a helper catalog. It should make Accrue's differentiator obvious by proving realistic billing flows locally without Stripe, Chrome, or SMTP.
- **D8-28:** The guide should open with one copy-pasteable Phoenix test that creates a billable customer, subscribes through the Fake Processor, advances time, triggers/handles a billing event, asserts persisted state, asserts Oban work, asserts email, asserts PDF, and asserts event ledger output.
- **D8-29:** Scenario sections should cover successful checkout, trial conversion, failed renewal and retry, cancellation/grace period, invoice email/PDF, webhook replay, background jobs, and provider-parity tests.
- **D8-30:** Include a concise helper reference after the scenario path, then an external-provider appendix explaining when to use real Stripe test mode, Stripe test clocks, 3DS cards, and live webhook forwarding.
- **D8-31:** The guide must warn against common footguns: testing Accrue internals instead of host flows, using sleeps instead of test clocks/events, making real Stripe sandbox calls the default test path, mixing live/test keys, hiding webhook setup, and failing to assert side effects.

### Claude's Discretion

- Exact Igniter dependency classification and fallback implementation details, as long as the installer provides safe diff/review, dry-run, noninteractive, and no-clobber behavior.
- Exact generated file names and module names beyond `MyApp.Billing` as the conventional default.
- Exact matcher syntax for assertions, as long as keyword filters, partial maps, subjects, and predicates are supported.
- Exact OTel adapter internals and status mapping, as long as optional compile/no-op behavior and attribute allowlists are enforced.
- Exact ordering and prose of the testing guide, as long as the Fake-first scenario playbook comes before reference material.

### Deferred Ideas (OUT OF SCOPE)

- Broad release machinery, GitHub Actions matrix, Release Please, Hex publishing, README quickstart, and full ExDoc guide set belong to Phase 9.
- First-party non-Stripe processors, revenue recognition, tax calculation, and customer-facing pricing page generation remain out of scope per project requirements.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INST-01 | Generate migrations | Use host-owned copied migrations from `accrue/priv/repo/migrations`; planner must include fingerprinted generated files and migration timestamp collision handling. [VERIFIED: codebase rg] |
| INST-02 | Generate `MyApp.Billing` facade | Generate a thin app context delegating to `Accrue.Billing` and host policy hooks. [VERIFIED: 08-CONTEXT.md] |
| INST-03 | Inject router mounts/webhook endpoint | Use `Accrue.Router`/`Accrue.Webhook.Plug` and manual snippets when safe patching fails. [VERIFIED: codebase rg] |
| INST-04 | Inject admin routes when package present | Mount `AccrueAdmin.Router.accrue_admin/2` only when `:accrue_admin` is present. [VERIFIED: accrue_admin/lib/accrue_admin/router.ex] |
| INST-05 | Billable schema prompt/detection | Prompt with flags; detect schemas by `use Accrue.Billable` or Phoenix context naming heuristics. [VERIFIED: 08-CONTEXT.md] [ASSUMED] |
| INST-06 | Sigra auto-detection/auth wiring | Detect `:sigra` in deps/loaded code and configure `Accrue.Integrations.Sigra`; fallback to `Accrue.Auth.Default`. [VERIFIED: accrue/lib/accrue/integrations/sigra.ex] |
| INST-07 | Idempotent re-run/no clobber | Use Igniter-style patch review plus generated-file fingerprints. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] [VERIFIED: 08-CONTEXT.md] |
| INST-08 | `mix accrue.gen.handler` | Generate a handler using `Accrue.Webhook.Handler` fallthrough behavior. [VERIFIED: codebase rg] |
| INST-09 | NimbleOptions validation at install | Call `Accrue.Config.validate!/1` against planned config. [VERIFIED: accrue/lib/accrue/config.ex] [CITED: https://hexdocs.pm/nimble_options/1.1.1/nimble_options] |
| INST-10 | Config doc generation | Surface `NimbleOptions.docs/1` output from `Accrue.Config` in install output/docs. [VERIFIED: accrue/lib/accrue/config.ex] |
| AUTH-04 | Sigra install auto-detect | Same as INST-06; include compile matrix coverage. [VERIFIED: accrue/lib/accrue/integrations/sigra.ex] |
| AUTH-05 | Community adapter docs | Add adapter pattern guide for phx.gen.auth/Pow/Assent shape; exact examples are documentation work. [VERIFIED: .planning/REQUIREMENTS.md] [ASSUMED] |
| TEST-02 | `advance_clock/2` | Wrap `Accrue.Processor.Fake.advance/2` and `advance_subscription/2`; Stripe integration path can map to Stripe Test Clocks. [VERIFIED: accrue/lib/accrue/processor/fake.ex] [CITED: https://docs.stripe.com/billing/testing/test-clocks/api-advanced-usage] |
| TEST-03 | `trigger_event/2` | Synthesize webhook events through existing DefaultHandler/ingest path. [VERIFIED: accrue/lib/accrue/processor/fake.ex] |
| TEST-04 | `assert_email_sent/1` | Re-export and extend existing process-mailbox assertions. [VERIFIED: accrue/lib/accrue/test/mailer_assertions.ex] |
| TEST-05 | `assert_pdf_rendered/1` | Re-export and extend existing process-mailbox PDF assertions. [VERIFIED: accrue/lib/accrue/test/pdf_assertions.ex] |
| TEST-06 | `assert_event_recorded/1` | Query `Accrue.Events` with matcher predicates and clear failure output. [VERIFIED: accrue/lib/accrue/events.ex] |
| TEST-07 | Mock adapters | Keep Fake/Mailer.Test/PDF.Test/Auth.Default public test setup stable; use Mox only for behaviour mocks where needed. [VERIFIED: accrue/mix.exs] |
| TEST-10 | Testing guide | Write Fake-first scenario playbook before helper reference. [VERIFIED: 08-CONTEXT.md] |
| OBS-02 | Optional OTel spans | Add `Accrue.Telemetry.OTel` behind `Code.ensure_loaded?` and call it from `Accrue.Telemetry.span/3`. [VERIFIED: accrue/lib/accrue/telemetry.ex] [CITED: https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/README.md] |
</phase_requirements>

## Summary

Phase 8 should be planned as a developer-experience integration phase, not as new billing-domain work. [VERIFIED: 08-CONTEXT.md] The core architecture is already present: Accrue owns billing, webhooks, Fake processor state, mail/PDF test captures, config validation, and admin routing; the installer should generate host-owned wiring and a small `MyApp.Billing` facade while preserving Accrue-owned internals. [VERIFIED: codebase rg]

Use `:igniter` as the primary installer/patching dependency and keep `Mix.Generator` only for simple generated files or fallback/manual snippets. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html] Current Igniter supports `--dry-run` and `--yes`; Accrue must add the product-specific flags from D8-03 and its own generated-file fingerprint/conflict policy. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] [VERIFIED: 08-CONTEXT.md]

**Primary recommendation:** Implement `mix accrue.install` as an Igniter-backed safe patcher plus a public `Accrue.Test` facade that wraps existing Fake/mail/PDF/event/Oban helpers, then wire optional OpenTelemetry spans through `Accrue.Telemetry.span/3`. [VERIFIED: codebase rg] [CITED: https://hexdocs.pm/oban/Oban.Testing.html]

## Project Constraints (from CLAUDE.md)

- Target Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. [VERIFIED: CLAUDE.md]
- Required deps include `lattice_stripe`, `oban`, `swoosh`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, and `chromic_pdf`; optional deps include `sigra` and `opentelemetry`. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/mix.exs]
- Core Accrue must not own host Repo, Oban, Finch, ChromicPDF, router, or auth lifecycle. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/lib/accrue/application.ex]
- Webhook signature verification is mandatory and raw-body capture must be scoped to webhook routes. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/lib/accrue/router.ex]
- Sensitive Stripe fields, raw payloads, card data, emails, addresses, request bodies, API keys, and signing secrets must not be logged or attached as span attributes. [VERIFIED: CLAUDE.md] [VERIFIED: 08-CONTEXT.md]
- All public entry points emit `:telemetry`; OTel helpers are additive and optional. [VERIFIED: CLAUDE.md] [VERIFIED: accrue/lib/accrue/telemetry.ex]
- No project-local `.claude/skills` or `.agents/skills` were found. [VERIFIED: find .claude/skills .agents/skills]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Installer CLI and file patching | Host build-time / Mix | Accrue package | `mix accrue.install` runs in the host app and mutates host files; task code ships in Accrue. [VERIFIED: 08-CONTEXT.md] |
| Generated Billing facade | Host app / API context | Accrue core | Host owns policy and names; Accrue owns billing implementation. [VERIFIED: 08-CONTEXT.md] |
| Webhook verification/ingest | API / Backend | Host router | Host router forwards raw route; Accrue verifies signature and persists/enqueues. [VERIFIED: accrue/lib/accrue/webhook/plug.ex] |
| Admin routes | Frontend Server / Phoenix Router | accrue_admin package | Host mounts `accrue_admin`; admin LiveViews remain package-owned. [VERIFIED: accrue_admin/lib/accrue_admin/router.ex] |
| Test clock/events | Test runtime | Processor Fake | `Accrue.Test` is facade; `Accrue.Processor.Fake` owns deterministic state and synthetic events. [VERIFIED: accrue/lib/accrue/processor/fake.ex] |
| Mail/PDF assertions | Test runtime | Accrue adapters | Existing captures are process-local messages emitted by test adapters. [VERIFIED: accrue/lib/accrue/test/mailer_assertions.ex] [VERIFIED: accrue/lib/accrue/test/pdf_assertions.ex] |
| OTel spans | Observability adapter | Telemetry core | `Accrue.Telemetry.span/3` remains the central path; OTel is optional bridge. [VERIFIED: accrue/lib/accrue/telemetry.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:igniter` | `~> 0.7.9` latest 0.7.9, published 2026-04-11 | Project patching and installer diff/review model | Provides installer tasks with dry-run/yes semantics and project patching surface. [VERIFIED: Hex API] [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] |
| `:nimble_options` | existing `~> 1.1`, latest 1.1.1 | Install-time and boot-time config validation/docs | Existing `Accrue.Config` already uses schema, `validate!/1`, `validate_at_boot!/0`, and `NimbleOptions.docs/1`. [VERIFIED: Hex API] [VERIFIED: accrue/lib/accrue/config.ex] |
| `:opentelemetry` | existing optional `~> 1.7`, latest 1.7.0 | Optional true spans | Official API provides `OpenTelemetry.Tracer.with_span`, `set_attributes`, and `set_status`. [VERIFIED: Hex API] [CITED: https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/README.md] |
| `:oban` | existing `~> 2.21`, latest 2.21.1 | Async assertions and host setup snippets | Oban.Testing provides `assert_enqueued`, `refute_enqueued`, `perform_job`, and `with_testing_mode`. [VERIFIED: Hex API] [CITED: https://hexdocs.pm/oban/Oban.Testing.html] |
| `:mox` | existing test `~> 1.2`, latest 1.2.0 | Behaviour mocks only | Existing project already declares Mox and defines mocks in test helper. [VERIFIED: Hex API] [VERIFIED: accrue/mix.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mix.Generator` | Elixir 1.19.5 local; docs opened at Mix main | Create/copy pristine files/templates | Use for new generated files after Accrue's fingerprint/no-clobber policy, not for router/config AST patching. [VERIFIED: local `mix --version`] [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html] |
| `:rewrite` | latest 1.3.0, published 2026-03-06 | AST/source fallback if Igniter lacks a needed patcher | Use only through Igniter where possible; direct use is a fallback for source history/update/write primitives. [VERIFIED: Hex API] [CITED: https://hexdocs.pm/rewrite/Rewrite.Source.html] |
| Stripe CLI | local 1.21.7 | Optional external-provider guide examples | Use only in testing guide appendix; Fake-first tests must not require it. [VERIFIED: local command] [CITED: https://docs.stripe.com/stripe-cli/triggers] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Igniter patching | Plain `Mix.Generator` | Mix.Generator prompts on overwrite but does not provide the structured diff/review model locked by D8-01. [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html] [VERIFIED: 08-CONTEXT.md] |
| Process-local captures | Global ETS/event bus | Existing mail/PDF captures are async-safe process messages; global state would create cross-test leakage unless explicitly owned. [VERIFIED: accrue/lib/accrue/test/mailer_assertions.ex] |
| OTel as required dep | Optional adapter | Project already declares OTel optional and requires warning-free with/without compilation. [VERIFIED: accrue/mix.exs] [VERIFIED: 08-CONTEXT.md] |

**Installation:**

```bash
# accrue/mix.exs
{:igniter, "~> 0.7.9", runtime: false}
```

**Version verification:** `mix hex.info` and Hex API were checked on 2026-04-15 for `igniter`, `rewrite`, `nimble_options`, `opentelemetry`, `oban`, `swoosh`, `phoenix`, `ecto_sql`, and `mox`. [VERIFIED: mix hex.info] [VERIFIED: Hex API]

## Architecture Patterns

### System Architecture Diagram

```text
Host developer
  |
  v
mix accrue.install --billable MyApp.Accounts.User --yes
  |
  v
Installer option parsing + project discovery
  |
  +--> Detect Phoenix app module, Repo, router, endpoint, Oban, deps
  |       |
  |       +--> :sigra present? ---- yes --> config auth_adapter Accrue.Integrations.Sigra
  |       |                         no  --> config auth_adapter Accrue.Auth.Default + prod warning
  |       |
  |       +--> :accrue_admin present? -- yes --> patch router with accrue_admin "/billing"
  |                                  no  --> skip admin mount with note
  |
  v
Build planned changes through Igniter/source patchers
  |
  +--> Generated files: migrations, MyApp.Billing, BillingHandler, test support
  +--> Patched files: config, router, endpoint/raw webhook pipeline, app supervision snippets
  |
  v
Validate planned Accrue config with NimbleOptions
  |
  +--> valid --> dry-run/review/apply
  +--> invalid --> fail install with NimbleOptions error
  |
  v
Final report: changed / skipped / conflicts / manual follow-up
```

### Recommended Project Structure

```text
accrue/
├── lib/mix/tasks/accrue.install.ex       # installer entrypoint [VERIFIED: existing task location pattern]
├── lib/mix/tasks/accrue.gen.handler.ex   # webhook handler generator [VERIFIED: existing Mix task pattern]
├── lib/accrue/install/                   # planner should create focused installer modules [ASSUMED]
│   ├── options.ex
│   ├── project.ex
│   ├── patches.ex
│   ├── templates.ex
│   └── fingerprints.ex
├── lib/accrue/test.ex                    # public facade [VERIFIED: 08-CONTEXT.md]
├── lib/accrue/test/clock.ex              # wraps Fake/Test Clock [VERIFIED: Fake API]
├── lib/accrue/test/webhooks.ex           # synthetic event injection [VERIFIED: Fake API]
├── lib/accrue/test/event_assertions.ex   # event ledger assertions [VERIFIED: Events API]
└── lib/accrue/telemetry/otel.ex          # optional OTel bridge [VERIFIED: telemetry central path]
```

### Pattern 1: Installer Entry with Strict Flags

**What:** Parse Accrue-specific flags, build an Igniter change set, run NimbleOptions validation before writing, and print a final change report. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] [VERIFIED: 08-CONTEXT.md]

**When to use:** `mix accrue.install` and `mix accrue.gen.handler`. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: Accrue Mix task pattern + Igniter install switch docs
def run(argv) do
  Mix.Task.run("loadpaths")
  {opts, _args, invalid} = OptionParser.parse(argv, strict: @switches)
  invalid == [] || Mix.raise("Invalid options: #{inspect(invalid)}")

  plan =
    argv
    |> Accrue.Install.Options.parse!()
    |> Accrue.Install.Project.discover!()
    |> Accrue.Install.Patches.build!()
    |> Accrue.Install.Config.validate!()

  Accrue.Install.Apply.run!(plan, opts)
end
```

### Pattern 2: Public `Accrue.Test` Facade

**What:** One `use Accrue.Test` imports assertion macros and aliases action helpers while keeping internals split by concern. [VERIFIED: 08-CONTEXT.md]

**When to use:** Host `DataCase`/`ConnCase` and Accrue's own public helper tests. [VERIFIED: 08-CONTEXT.md]

**Example:**

```elixir
# Source: existing MailerAssertions/PdfAssertions __using__ pattern
defmodule Accrue.Test do
  defmacro __using__(_opts) do
    quote do
      import Accrue.Test.MailerAssertions
      import Accrue.Test.PdfAssertions
      import Accrue.Test.EventAssertions

      alias Accrue.Test.Clock
      alias Accrue.Test.Webhooks
    end
  end

  defdelegate advance_clock(subject, duration), to: Accrue.Test.Clock, as: :advance
  defdelegate trigger_event(type, subject), to: Accrue.Test.Webhooks, as: :trigger
end
```

### Pattern 3: Optional OTel Adapter Under Telemetry

**What:** Keep `Accrue.Telemetry.span/3` as the only call path; inside it, invoke `Accrue.Telemetry.OTel.span/3` when OpenTelemetry modules are loaded. [VERIFIED: accrue/lib/accrue/telemetry.ex]

**When to use:** Every Billing context public function and existing telemetry span wrapper. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: OpenTelemetry Erlang API docs
if Code.ensure_loaded?(OpenTelemetry.Tracer) do
  def span(name, attrs, fun) do
    require OpenTelemetry.Tracer

    OpenTelemetry.Tracer.with_span name, %{attributes: attrs} do
      try do
        result = fun.()
        OpenTelemetry.Tracer.set_status(:ok, "")
        result
      rescue
        exception ->
          OpenTelemetry.Tracer.set_status(:error, Exception.message(exception))
          reraise exception, __STACKTRACE__
      end
    end
  end
else
  def span(_name, _attrs, fun), do: fun.()
end
```

### Anti-Patterns to Avoid

- **Plain overwrite generator for router/config:** `Mix.Generator` overwrite prompts are not enough for D8-01's diff/review and no-clobber requirement. [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html] [VERIFIED: 08-CONTEXT.md]
- **Copying helper internals into host apps:** Host tests should import `Accrue.Test`; copied code would freeze bugs into user repos. [VERIFIED: 08-CONTEXT.md]
- **Synthetic events that bypass reducers:** `trigger_event/2` must exercise the same DefaultHandler/ledger/mail/PDF/Oban path as production. [VERIFIED: 08-CONTEXT.md] [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex]
- **Auto-attaching arbitrary span metadata:** OTel attributes must be allowlisted and sanitized. [VERIFIED: 08-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Project source patching | Regex router/config edits | Igniter patchers; Rewrite fallback only where needed | Source-aware patching reduces syntax corruption and enables reviewable changes. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] |
| Option/config validation | Custom `with` chains | `NimbleOptions.validate!/2` via `Accrue.Config` | Existing config schema and docs generation already solve validation and error messages. [VERIFIED: accrue/lib/accrue/config.ex] |
| Background job test assertions | Custom Oban job queries | `Oban.Testing` | Official helpers cover `assert_enqueued`, `refute_enqueued`, `all_enqueued`, and `perform_job`. [CITED: https://hexdocs.pm/oban/Oban.Testing.html] |
| OpenTelemetry spans | Manual process dictionary span lifecycle | `OpenTelemetry.Tracer.with_span` | Official macro/function starts, activates, and ends spans. [CITED: https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/README.md] |
| Stripe-like local time travel | Sleeps/timers | `Accrue.Processor.Fake.advance_subscription/2` and Stripe Test Clocks appendix | Existing Fake supports deterministic clock and event synthesis. [VERIFIED: accrue/lib/accrue/processor/fake.ex] |
| Mail/PDF capture store | Global ETS unless explicitly owned | Existing process-mailbox assertions | Existing mail/PDF assertions are process-local and async-safe. [VERIFIED: accrue/lib/accrue/test/mailer_assertions.ex] |

**Key insight:** Phase 8's hard part is safe host mutation and trustworthy local test behavior; both already have ecosystem or project primitives and should not be rebuilt from regexes, sleeps, global state, or raw OTel APIs. [VERIFIED: 08-CONTEXT.md] [VERIFIED: codebase rg]

## Common Pitfalls

### Pitfall 1: Installing By Regex

**What goes wrong:** Router/config/application files are syntactically valid but semantically wrong, or user edits are overwritten. [ASSUMED]  
**Why it happens:** Regex patchers do not understand Elixir AST or Phoenix router structure. [ASSUMED]  
**How to avoid:** Use Igniter/source-aware patchers where possible and fall back to `--manual` snippets when structure is ambiguous. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] [VERIFIED: 08-CONTEXT.md]  
**Warning signs:** Installer cannot find a router pipeline, multiple endpoints/repos exist, or `mix format --check-formatted` fails after install. [ASSUMED]

### Pitfall 2: Treating `--force` as Normal Reinstall

**What goes wrong:** User-edited generated files get clobbered. [VERIFIED: 08-CONTEXT.md]  
**Why it happens:** Standard generator overwrite semantics are too coarse for generated files that become host-owned. [VERIFIED: 08-CONTEXT.md]  
**How to avoid:** Store generator fingerprint comments/metadata; only auto-update pristine generated files; otherwise skip or show diff. [VERIFIED: 08-CONTEXT.md]  
**Warning signs:** Existing file lacks Accrue fingerprint or fingerprint does not match generated content. [ASSUMED]

### Pitfall 3: Test Helpers Bypass Production Path

**What goes wrong:** Tests pass while production webhooks fail idempotency, reducer, mail/PDF, or Oban behavior. [VERIFIED: 08-CONTEXT.md]  
**Why it happens:** Helpers mutate rows directly instead of synthesizing webhook events through handler paths. [VERIFIED: 08-CONTEXT.md]  
**How to avoid:** `trigger_event/2` must route through the normal Accrue webhook event/handler path; event assertion helpers should query persisted ledger rows. [VERIFIED: accrue/lib/accrue/webhook/default_handler.ex] [VERIFIED: accrue/lib/accrue/events.ex]  
**Warning signs:** Helper tests do not insert `accrue_webhook_events`, enqueue Oban jobs, or record `accrue_events`. [ASSUMED]

### Pitfall 4: Optional Dependency Warnings

**What goes wrong:** `mix compile --warnings-as-errors` fails in without-OTel or without-Sigra matrix cells. [VERIFIED: 08-CONTEXT.md]  
**Why it happens:** Optional modules are referenced without `Code.ensure_loaded?` and `@compile {:no_warn_undefined, ...}` patterns. [VERIFIED: accrue/lib/accrue/integrations/sigra.ex]  
**How to avoid:** Mirror the Sigra conditional-compile pattern for `Accrue.Telemetry.OTel`. [VERIFIED: accrue/lib/accrue/integrations/sigra.ex]  
**Warning signs:** Undefined module/function warnings for `OpenTelemetry.Tracer`, `:otel_tracer`, or `Sigra.*`. [VERIFIED: accrue/lib/accrue/telemetry.ex]

### Pitfall 5: Span Privacy Leaks

**What goes wrong:** Stripe payloads, emails, raw request bodies, or secrets appear in traces. [VERIFIED: 08-CONTEXT.md]  
**Why it happens:** Broad instrumentation forwards function args or webhook payloads wholesale. [VERIFIED: 08-CONTEXT.md]  
**How to avoid:** Build attributes from a fixed allowlist and reject/drop prohibited keys in tests. [VERIFIED: 08-CONTEXT.md]  
**Warning signs:** Span attributes include maps named `data`, `metadata`, `raw_body`, `email`, `card`, `api_key`, or `secret`. [ASSUMED]

## Code Examples

### Generated Host Billing Facade

```elixir
# Source: Accrue.Billing public facade and D8-06 host-owned policy boundary
defmodule MyApp.Billing do
  @moduledoc """
  Host-owned billing facade generated by Accrue.
  """

  defdelegate subscribe(billable, price, opts \\ []), to: Accrue.Billing
  defdelegate cancel(subscription, opts \\ []), to: Accrue.Billing
  defdelegate resume(subscription, opts \\ []), to: Accrue.Billing
  defdelegate preview_upcoming_invoice(subject, opts \\ []), to: Accrue.Billing
end
```

### Webhook Handler Scaffold

```elixir
# Source: Accrue.Webhook.Handler docs pattern in codebase
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  @impl true
  def handle_event("invoice.payment_failed", event, _ctx) do
    # Host-specific side effects go here.
    {:ok, event}
  end
end
```

### Event Assertion Matcher Shape

```elixir
# Source: existing process-local assertion style + Accrue.Events query API
assert_event_recorded user,
  type: :subscription_created,
  data: %{processor: :stripe},
  matches: fn event -> event.subject_id == user.id end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plain `Mix.Generator` overwrite prompts | Igniter-style project patching with dry-run/yes and Accrue no-clobber fingerprints | Igniter 0.7.9 current as of 2026-04-15 | Planner should build a patch plan, not a file-copy-only generator. [VERIFIED: Hex API] [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html] |
| Real Stripe/Chrome/SMTP as default tests | Fake Processor + test mail/PDF adapters + Oban.Testing | Existing Accrue code through Phase 7 | Planner should make local tests deterministic and reserve Stripe CLI/Test Clocks for appendix/integration mode. [VERIFIED: codebase rg] |
| Raw `:telemetry` only | `:telemetry` plus optional OTel span bridge | OBS-02 Phase 8 | Planner must cover with/without OTel compile paths and attribute privacy tests. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**
- Regex-only router/config editing is not acceptable for this phase because D8-01 requires reviewable safe patching. [VERIFIED: 08-CONTEXT.md]
- Sleeps/timers in billing tests are not acceptable because Fake already exposes deterministic clock advancement. [VERIFIED: accrue/lib/accrue/processor/fake.ex]
- Required OTel dependency is not acceptable because the project already declares OTel optional. [VERIFIED: accrue/mix.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Installer can detect likely billable schemas from `use Accrue.Billable` and Phoenix context naming heuristics. | Phase Requirements | Planner may need a simpler prompt-only flow. |
| A2 | `lib/accrue/install/*` is the best internal module layout. | Recommended Project Structure | Low; planner can rename modules without changing architecture. |
| A3 | Regex patching failure warning signs include multi-router/multi-endpoint host apps. | Common Pitfalls | Planner should validate against generated phx.new and one nonstandard app. |
| A4 | Generated file fingerprints can be implemented as comments/metadata. | Common Pitfalls | Planner may choose a sidecar manifest instead. |

## Open Questions

1. **Should `:igniter` be a regular runtime-false dependency or generated-code-only dev dependency?**
   - What we know: `mix accrue.install` runs from the published Accrue dependency in a host app, so the task's dependency must be available to that host compile/runtime environment. [VERIFIED: Mix task model in codebase]
   - What's unclear: Whether Accrue wants to expose Igniter as a transitive dependency to all users. [ASSUMED]
   - Recommendation: Add `{:igniter, "~> 0.7.9", runtime: false}` to `accrue/mix.exs`; document it as installer-only. [VERIFIED: Hex API]

2. **How much router/application patching should be automatic for nonstandard Phoenix apps?**
   - What we know: D8-09 allows default patching only through safe diff/review and `--manual` snippets otherwise. [VERIFIED: 08-CONTEXT.md]
   - What's unclear: The exact complexity threshold for falling back to manual mode. [ASSUMED]
   - Recommendation: Auto-patch fresh `phx.new` shape and simple routers; otherwise produce exact snippets and a skipped report. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | Build/test/install tasks | yes | Elixir 1.19.5 / Mix 1.19.5 / OTP 28 | none needed; exceeds floor. [VERIFIED: local command] |
| PostgreSQL client | Local tests/migrations | yes | psql 14.17 | CI service DB if local DB unavailable. [VERIFIED: local command] |
| Docker | Fresh app/install smoke containers | yes | 29.3.1 | Local phx.new app without container. [VERIFIED: local command] |
| Stripe CLI | External-provider testing appendix | yes | 1.21.7 | Fake Processor helpers; Stripe CLI not required for normal tests. [VERIFIED: local command] |
| Node/npx | Context7 docs lookup only | yes | Node v22.14.0 / npx 11.1.0 | Official HexDocs/web docs. [VERIFIED: local command] |

**Missing dependencies with no fallback:** None found for research/planning. [VERIFIED: local command]  
**Missing dependencies with fallback:** None found. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox, Oban.Testing, Mox, StreamData. [VERIFIED: accrue/test/test_helper.exs] |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `accrue/mix.exs`. [VERIFIED: codebase] |
| Quick run command | `cd accrue && mix test test/accrue/test test/accrue/config_test.exs test/accrue/telemetry_test.exs` [VERIFIED: test files exist] |
| Full suite command | `cd accrue && mix test.all && cd ../accrue_admin && mix test` [VERIFIED: mix aliases] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INST-01..10 | Installer generates/patches safely and idempotently | integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs` | no, Wave 0 |
| AUTH-04 | Sigra detected and auth adapter wired | unit/integration | `cd accrue && mix test test/accrue/install/sigra_detection_test.exs` | no, Wave 0 |
| AUTH-05 | Community adapter docs include pattern | docs test | `cd accrue && mix test test/accrue/docs/community_auth_test.exs` | no, Wave 0 |
| TEST-02 | Clock advances Fake lifecycle | unit/integration | `cd accrue && mix test test/accrue/test/clock_test.exs` | no, Wave 0 |
| TEST-03 | Synthetic events enter normal handler path | integration | `cd accrue && mix test test/accrue/test/webhooks_test.exs` | no, Wave 0 |
| TEST-04 | Email assertions fail clearly | unit | `cd accrue && mix test test/accrue/test/mailer_assertions_test.exs` | yes |
| TEST-05 | PDF assertions fail clearly | unit | `cd accrue && mix test test/accrue/test/pdf_assertions_test.exs` | yes |
| TEST-06 | Event assertions match ledger rows | unit/integration | `cd accrue && mix test test/accrue/test/event_assertions_test.exs` | no, Wave 0 |
| TEST-07 | Test adapters setup is public and stable | unit | `cd accrue && mix test test/accrue/test/facade_test.exs` | no, Wave 0 |
| TEST-10 | Testing guide examples compile/run | docs/integration | `cd accrue && mix test test/accrue/docs/testing_guide_test.exs` | no, Wave 0 |
| OBS-02 | OTel optional spans compile with/without dep | compile/unit | `cd accrue && mix test test/accrue/telemetry/otel_test.exs` | no, Wave 0 |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/test test/accrue/config_test.exs test/accrue/telemetry_test.exs` [VERIFIED: test files exist]
- **Per wave merge:** `cd accrue && mix test.all` plus targeted `cd accrue_admin && mix test test/accrue_admin/router_test.exs` for admin route install. [VERIFIED: mix aliases]
- **Phase gate:** Run fresh `phx.new` install smoke, `cd accrue && mix test.all`, `cd accrue_admin && mix test`, and compile matrix checks for with/without OTel/Sigra. [VERIFIED: 08-CONTEXT.md]

### Wave 0 Gaps

- [ ] `accrue/test/mix/tasks/accrue_install_test.exs` — covers INST-01..10. [VERIFIED: file absent]
- [ ] `accrue/test/mix/tasks/accrue_gen_handler_test.exs` — covers INST-08. [VERIFIED: file absent]
- [ ] `accrue/test/accrue/test/clock_test.exs` — covers TEST-02. [VERIFIED: file absent]
- [ ] `accrue/test/accrue/test/webhooks_test.exs` — covers TEST-03. [VERIFIED: file absent]
- [ ] `accrue/test/accrue/test/event_assertions_test.exs` — covers TEST-06. [VERIFIED: file absent]
- [ ] `accrue/test/accrue/test/facade_test.exs` — covers TEST-07 facade imports/setup. [VERIFIED: file absent]
- [ ] `accrue/test/accrue/telemetry/otel_test.exs` — covers OBS-02. [VERIFIED: file absent]
- [ ] Fresh Phoenix fixture/sandbox helper for install smoke. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Sigra auto-wiring or `Accrue.Auth.Default` fail-closed prod warning. [VERIFIED: accrue/lib/accrue/auth/default.ex] |
| V3 Session Management | yes for admin mount | Host browser pipeline/session remains host-owned; admin macro threads explicit session keys. [VERIFIED: accrue_admin/lib/accrue_admin/router.ex] |
| V4 Access Control | yes | Admin mount uses `AccrueAdmin.AuthHook` via `accrue_admin/2`; installer must not mount unprotected custom admin code. [VERIFIED: accrue_admin/lib/accrue_admin/router.ex] |
| V5 Input Validation | yes | `NimbleOptions` for install/config opts; Ecto changesets for DB writes. [VERIFIED: accrue/lib/accrue/config.ex] |
| V6 Cryptography | yes | Webhook signing verification delegated to `LatticeStripe.Webhook.construct_event!`; no custom HMAC. [VERIFIED: accrue/lib/accrue/webhook/signature.ex] |
| V7 Error Handling | yes | Installer should report invalid config/conflicts without leaking secrets. [VERIFIED: CLAUDE.md] |
| V10 Malicious Code | yes | Installer must not execute user-provided modules beyond static detection/compilation paths. [ASSUMED] |

### Known Threat Patterns for Elixir/Phoenix Installer + Billing Tests

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Webhook raw body captured globally | Information Disclosure / Tampering | Patch route-scoped raw-body parser only. [VERIFIED: accrue/lib/accrue/router.ex] |
| User edits clobbered by reinstall | Tampering | Fingerprints + diff review + skip on modified files. [VERIFIED: 08-CONTEXT.md] |
| Secrets printed in install report | Information Disclosure | Redact Stripe keys, webhook secrets, raw bodies, and env values. [VERIFIED: CLAUDE.md] |
| OTel trace PII leakage | Information Disclosure | Attribute allowlist and prohibited-key tests. [VERIFIED: 08-CONTEXT.md] |
| Admin mounted without auth | Elevation of Privilege | Use `AccrueAdmin.Router.accrue_admin/2` default hook and require host protection notes. [VERIFIED: accrue_admin/lib/accrue_admin/router.ex] |

## Sources

### Primary (HIGH confidence)

- `accrue/lib/accrue/processor/fake.ex` — Fake clock, transitions, synthetic event primitives. [VERIFIED: codebase]
- `accrue/lib/accrue/test/mailer_assertions.ex` and `accrue/lib/accrue/test/pdf_assertions.ex` — existing process-local assertion patterns. [VERIFIED: codebase]
- `accrue/lib/accrue/config.ex` — NimbleOptions schema, docs, validation. [VERIFIED: codebase]
- `accrue/lib/accrue/telemetry.ex` — central `span/3` and optional trace id pattern. [VERIFIED: codebase]
- `accrue/lib/accrue/integrations/sigra.ex` — optional dependency compile pattern. [VERIFIED: codebase]
- `accrue_admin/lib/accrue_admin/router.ex` — admin mount macro. [VERIFIED: codebase]
- Hex API / `mix hex.info` — current versions for Igniter, Rewrite, NimbleOptions, OpenTelemetry, Oban, Swoosh, Phoenix, Ecto SQL, Mox. [VERIFIED: Hex API]
- Context7/HexDocs Igniter — installer task flags. [CITED: https://hexdocs.pm/igniter/Mix.Tasks.Igniter.Install.html]
- HexDocs NimbleOptions 1.1.1 — validation/docs behavior. [CITED: https://hexdocs.pm/nimble_options/1.1.1/nimble_options]
- OpenTelemetry Erlang API docs — span, attributes, status. [CITED: https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/README.md]
- HexDocs Oban.Testing 2.21.1 — testing helpers. [CITED: https://hexdocs.pm/oban/Oban.Testing.html]
- HexDocs Mix.Generator — generator overwrite behavior. [CITED: https://hexdocs.pm/mix/main/Mix.Generator.html]

### Secondary (MEDIUM confidence)

- Stripe CLI trigger docs — external-provider appendix and sandbox event triggering. [CITED: https://docs.stripe.com/stripe-cli/triggers]
- Stripe Test Clocks docs — integration-environment clock concepts. [CITED: https://docs.stripe.com/billing/testing/test-clocks/api-advanced-usage]

### Tertiary (LOW confidence)

- Assumptions A1-A4 above. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified from Hex and official docs; dependencies already align with project stack. [VERIFIED: Hex API]
- Architecture: HIGH — responsibility boundaries are locked in context and present in code. [VERIFIED: 08-CONTEXT.md] [VERIFIED: codebase]
- Pitfalls: MEDIUM — no-clobber/optional-dep/privacy pitfalls are verified; some router complexity failure modes are inferred. [VERIFIED: 08-CONTEXT.md] [ASSUMED]

**Research date:** 2026-04-15  
**Valid until:** 2026-04-22 for Igniter/OTel/Oban version-sensitive details; 2026-05-15 for project architecture findings. [ASSUMED]
