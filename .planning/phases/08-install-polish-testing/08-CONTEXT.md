# Phase 8: Install + Polish + Testing - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 8 delivers the public developer experience for installing and testing Accrue in a Phoenix app: `mix accrue.install`, generated host-app billing/webhook/admin/auth/config surfaces, idempotent re-run behavior, public test helpers, OpenTelemetry span support, and the testing guide. Release automation, CI matrix, Hex publishing, README quickstart, and broad ExDoc guide set remain Phase 9.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion

- Exact Igniter dependency classification and fallback implementation details, as long as the installer provides safe diff/review, dry-run, noninteractive, and no-clobber behavior.
- Exact generated file names and module names beyond `MyApp.Billing` as the conventional default.
- Exact matcher syntax for assertions, as long as keyword filters, partial maps, subjects, and predicates are supported.
- Exact OTel adapter internals and status mapping, as long as optional compile/no-op behavior and attribute allowlists are enforced.
- Exact ordering and prose of the testing guide, as long as the Fake-first scenario playbook comes before reference material.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope

- `.planning/PROJECT.md` — Accrue vision, install/DX requirements, key decisions, brand and ecosystem constraints.
- `.planning/REQUIREMENTS.md` — Phase 8 requirement IDs: `INST-01` through `INST-10`, `AUTH-04`, `AUTH-05`, `TEST-02` through `TEST-07`, `TEST-10`, and `OBS-02`.
- `.planning/ROADMAP.md` — Phase 8 goal, success criteria, and boundary with Phase 9 release work.
- `.planning/STATE.md` — Current project state and prior decisions affecting Phase 8.

### Prior Decisions

- `.planning/phases/01-foundations/01-CONTEXT.md` — Hybrid lib + generator decision, Fake Processor primary test surface, event immutability install stub, telemetry/OTel base, Auth.Default/Sigra conditional compile pattern.
- `.planning/phases/02-schemas-webhook-plumbing/02-CONTEXT.md` — Webhook pipeline, host-owned billable schema, metadata/data semantics, idempotency, API-version override.
- `.planning/phases/06-email-pdf/06-CONTEXT.md` — Mail/PDF testing helpers, no Chrome/SMTP normal test path, shared render behavior.
- `.planning/phases/07-admin-ui-accrue-admin/07-CONTEXT.md` — Admin router macro, package-owned admin UI, Sigra adapter, dev surfaces, asset/theming patterns.

### Existing Code

- `accrue/lib/accrue/processor/fake.ex` — Existing Fake Processor, deterministic IDs, test clock, transition and synthetic event primitives.
- `accrue/lib/accrue/test/mailer_assertions.ex` — Existing process-local mail assertion style to preserve/extend.
- `accrue/lib/accrue/test/pdf_assertions.ex` — Existing process-local PDF assertion style to preserve/extend.
- `accrue/lib/accrue/telemetry.ex` — Current telemetry span helper and optional trace id behavior.
- `accrue/guides/telemetry.md` — Span naming, metadata, and prohibited sensitive attribute guidance.
- `accrue/lib/accrue/auth.ex` — Auth behaviour and optional step-up callbacks.
- `accrue/lib/accrue/auth/default.ex` — Default auth adapter prod fail-closed behavior.
- `accrue/lib/accrue/integrations/sigra.ex` — Sigra conditional compile/autodetection pattern.
- `accrue_admin/lib/accrue_admin/router.ex` — Existing `accrue_admin` mount macro to reuse from the installer.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Processor.Fake`: already provides deterministic resource state, `advance/2`, `advance_subscription/2`, `transition/3`, `scripted_response/2`, and synthetic event paths that Phase 8 test helpers should wrap rather than replace.
- `Accrue.Test.MailerAssertions` and `Accrue.Test.PdfAssertions`: existing async-safe process-mailbox assertion modules. `Accrue.Test` should import/delegate to these rather than changing their core capture model.
- `Accrue.Telemetry.span/3`: the existing central instrumentation path. OTel should hook here through a small adapter instead of adding unrelated tracing APIs.
- `AccrueAdmin.Router.accrue_admin/2`: existing mount macro for admin routes. Installer should wire this when the companion package is present.
- `Accrue.Config.schema/0` and NimbleOptions docs generation: usable for install-time validation and config documentation output.

### Established Patterns

- Optional integrations use `Code.ensure_loaded?/1` and no-warn compile attributes, visible in Sigra and telemetry-related modules.
- Host-owned lifecycle is a locked pattern: host owns Repo, Oban supervision, router, auth schema, and generated app policy code.
- Public Accrue APIs favor explicit Elixir/Phoenix shapes: context facades, behaviours for extension points, tuple returns plus bang variants, and process-local test captures for async safety.
- Admin UI is package-owned and mounted through a router macro rather than generated into the host app.

### Integration Points

- Installer connects to host `mix.exs`, config files, router, endpoint/webhook pipeline, app supervision snippets, migrations, test support, and optional `accrue_admin` and Sigra deps.
- Test helpers connect to Fake Processor, webhook fixtures/handlers, Oban testing, event ledger assertions, mail/PDF capture messages, and host `DataCase`/`ConnCase` imports.
- OTel spans connect to existing `Accrue.Telemetry.span/3` call sites and the telemetry guide's naming/privacy policy.

</code_context>

<specifics>
## Specific Ideas

- User asked for research-backed, one-shot recommendations using subagents, emphasizing idiomatic Elixir/Plug/Ecto/Phoenix, lessons from successful billing libraries, great DX, least surprise, cohesive architecture, and recommendations that can be treated as locked.
- Installer recommendation intentionally blends Phoenix generator familiarity with Igniter-style safe patching because Phase 8 needs to mutate existing router/config/test support without clobbering host code.
- Generated host surface follows a coherent ownership line: host gets the thin app-specific facade and wiring; Accrue keeps risky payment/webhook/provider logic upgradeable.
- Test helper and testing guide decisions reinforce each other: `Accrue.Test` makes the guide copy-pasteable, and the guide demonstrates the whole local Fake-first story.
- OTel decision preserves Elixir telemetry as the primary ecosystem surface while providing true spans for teams that have OpenTelemetry installed.
- External research considered Phoenix `phx.gen.auth`, `Mix.Generator`, Igniter generators, Pow, Oban install/testing, Phoenix LiveDashboard, Swoosh assertions, Mox async/global modes, Stripe testing/test clocks/webhooks, Rails Pay, Laravel Cashier, and dj-stripe.

</specifics>

<deferred>
## Deferred Ideas

- Broad release machinery, GitHub Actions matrix, Release Please, Hex publishing, README quickstart, and full ExDoc guide set belong to Phase 9.
- First-party non-Stripe processors, revenue recognition, tax calculation, and customer-facing pricing page generation remain out of scope per project requirements.

</deferred>

---

*Phase: 08-install-polish-testing*
*Context gathered: 2026-04-15*
