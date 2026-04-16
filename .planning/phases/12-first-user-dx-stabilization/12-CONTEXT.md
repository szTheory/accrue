# Phase 12: First-User DX Stabilization - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 12 tightens the first-hour experience for a Phoenix developer integrating `accrue` and `accrue_admin`. The phase is limited to installer rerun behavior, setup diagnostics, quickstart/troubleshooting docs, dependency-mode validation, package docs/version/link correctness, and public API clarity surfaced by `examples/accrue_host`. Adoption/demo packaging belongs to Phase 13. Security, performance, accessibility, responsive-browser checks, and compatibility hardening belong to Phase 14.

</domain>

<decisions>
## Implementation Decisions

### Installer Rerun Behavior

- **D-01:** Use a no-clobber, pristine-update installer contract. Reruns may overwrite only Accrue-stamped pristine generated files.
- **D-02:** Stamped generated files whose fingerprint no longer matches must always be treated as user-edited and skipped. `--force` must not clobber these files.
- **D-03:** Unmarked existing files must be skipped by default. `--force` may overwrite only unmarked existing files, making the destructive behavior narrow and explicit.
- **D-04:** `--write-conflicts` must become real. It should write rendered replacements or patch/manual snippets as sidecar conflict artifacts outside live compile/config paths, preferably under a dedicated dotdir such as `.accrue/conflicts/`, with target path and reason included.
- **D-05:** Installer summary output must distinguish `created`, `updated pristine`, `skipped user-edited`, `skipped exists`, `manual`, and conflict artifact paths so CI failures and first-user reruns are diagnosable.

### Actionable Setup Failures

- **D-06:** Create a centralized setup-diagnostic contract shared by installer/preflight, boot-time configuration checks, and selected webhook/admin runtime checks. The user-facing shape should include stable `code`, concise summary, fix instructions, and docs path/anchor.
- **D-07:** Keep boot-fatal setup issues as `Accrue.ConfigError` or a compatible setup exception: missing repo config, pending/missing migrations, Oban not configured or not supervised when required, production use of dev/test auth adapters, and missing webhook signing secret.
- **D-08:** Keep public HTTP webhook responses generic: bad signatures return generic `400`; host misconfiguration returns a generic server error. Detailed diagnostics belong in logs/exceptions, redacted and linked to docs.
- **D-09:** Preflight or boot checks should catch first-hour wiring mistakes where practical: webhook route missing, raw-body reader missing or in the wrong pipeline, webhook mounted behind browser/CSRF/auth pipeline, admin mount missing, and auth adapter/admin protection missing.
- **D-10:** All diagnostics must redact secret-like values (`sk_*`, `whsec_*`, env var values with `SECRET`/`KEY`) and should name env var keys/classes rather than raw values.

### Docs Shape

- **D-11:** Use a split documentation structure, not one monolithic quickstart. Keep README/package landing copy compact, create or expand a host-app-derived "First Hour" guide as the canonical setup walkthrough, and add a troubleshooting matrix linked from failure-prone steps.
- **D-12:** The First Hour guide must follow the `examples/accrue_host` path in Phoenix order: deps, installer, runtime config, migrations, Oban, webhook route/raw-body, auth/admin mount, first Fake-backed subscription, signed webhook proof, admin inspection, and tests.
- **D-13:** The troubleshooting matrix should be organized by symptom and stable diagnostic code, with "what happened", "why Accrue cares", "fix", and "how to verify" columns.
- **D-14:** Existing topic guides should stay focused: testing guide for `Accrue.Test` and Fake, webhook guide for signatures/raw body/replay, admin guide for mount/auth/session, upgrade guide for generated-code ownership.
- **D-15:** Docs copy should stay calm, precise, and host-app-evidence-based. Avoid marketing claims not proven by the dogfood harness.

### Path Dependency And Hex Validation

- **D-16:** Keep a single canonical checked-in host app at `examples/accrue_host`. Do not create dual committed example apps for path and Hex modes.
- **D-17:** Add a dependency-mode switch for the host app: path dependencies by default for monorepo dogfood, Hex-style dependencies via an explicit env flag or script mode.
- **D-18:** Hex validation should be a focused smoke, not the full Phase 13 demo path: `mix deps.get`, rerun `mix accrue.install`, compile, migrate, and run a narrow host proof suite.
- **D-19:** Keep the existing path-mode host UAT as the primary PR/release gate. Add Hex-mode validation as a package correctness check that proves install snippets and published package metadata work.
- **D-20:** Treat package versions, source refs, and HexDocs links as checked invariants. A repo script should parse package `mix.exs` values and assert README install snippets, `docs.source_ref` tag shapes, relative ExDoc links, and package guide links are correct.

### Public API Clarity

- **D-21:** Elevate the host-first API boundary as the public integration story: generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, and setup errors through `Accrue.ConfigError`.
- **D-22:** Do not teach first users to depend on private/internal tables or modules such as `Accrue.Billing.Customer`, `Accrue.Billing.Subscription`, `Accrue.Webhook.WebhookEvent`, `Accrue.Events.Event`, direct Fake GenServer functions, worker internals, or package repo cleanup patterns.
- **D-23:** Add host-facing read helpers to the generated facade if needed so example UI/tests can inspect billing state without direct schema/repo coupling.
- **D-24:** Webhook examples should stay at the generated handler boundary (`MyApp.BillingHandler.handle_event/3` or equivalent) and not require reducer or dispatch-worker internals.
- **D-25:** `Accrue.ConfigError` is the setup/runtime misconfiguration contract, not everyday control flow. Docs should show how to fix it, not pattern-match on it for normal business behavior.

### Coherent Recommendation

- **D-26:** The phase should optimize for principle of least surprise: generated code is host-owned; reruns are safe; failures name the fix; docs mirror the real host path; package validation proves both monorepo and published modes; public APIs remain small and Phoenix-context-shaped.

### the agent's Discretion

- Exact module names for the diagnostic formatter/checker.
- Exact `.accrue/conflicts/` file naming scheme, as long as artifacts are outside compile/config paths and include target path/reason.
- Whether the preflight surface is `mix accrue.install --check`, `mix accrue.doctor`, or both, as long as installer and runtime diagnostics share one taxonomy.
- Exact guide names and ExDoc sidebar grouping, as long as the split docs shape and stable anchors are preserved.
- Exact narrow Hex-mode proof suite, as long as it covers installer rerun, compile, migrations, and one host-facing billing/webhook/admin proof.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/PROJECT.md` - v1.1 stabilization goal, product philosophy, brand voice, and host-owned Phoenix integration principles.
- `.planning/REQUIREMENTS.md` - Phase 12 requirement IDs `DX-01` through `DX-07`.
- `.planning/ROADMAP.md` - Phase 12 goal, dependencies, success criteria, and boundary from Phases 13-15.
- `.planning/STATE.md` - Current progress and recent host-app/CI decisions.
- `.planning/phases/10-host-app-dogfood-harness/10-CONTEXT.md` - Canonical host app decisions and deferred Phase 12 scope.

### Installer And Generated-Code Safety

- `accrue/lib/mix/tasks/accrue.install.ex` - Current installer task, output, redaction, install summary, and unused conflict flag surface.
- `accrue/lib/accrue/install/options.ex` - Installer flags including `--force` and `--write-conflicts`.
- `accrue/lib/accrue/install/fingerprints.ex` - Existing generated-file marker/fingerprint/no-clobber primitive.
- `accrue/lib/accrue/install/patches.ex` - Router/config patch behavior and manual snippet fallback.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` - Existing installer UAT pattern, if present.
- `examples/accrue_host/test/install_boundary_test.exs` - Host-app proof that generated facade/router/runtime config stay at public boundaries.

### Setup Diagnostics

- `accrue/lib/accrue/errors.ex` - `Accrue.ConfigError` and error taxonomy.
- `accrue/lib/accrue/config.ex` - Runtime configuration validation and webhook secret lookup.
- `accrue/lib/accrue/repo.ex` - Host Repo configuration failure surface.
- `accrue/lib/accrue/auth/default.ex` - Default/dev-test auth behavior and production fail-closed checks.
- `accrue/lib/accrue/webhook/plug.ex` - Signed webhook Plug path and raw-body/signature failure surface.
- `examples/accrue_host/config/runtime.exs` - Host runtime config path and Fake/webhook defaults.
- `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` - Host signed webhook proof.

### Docs And Host App

- `accrue/README.md` - Package landing page and install snippet surface.
- `accrue/guides/quickstart.md` - Current abbreviated quickstart that Phase 12 should reshape.
- `accrue/guides/testing.md` - Public Fake/test helper docs.
- `accrue/guides/webhooks.md` - Webhook setup/troubleshooting doc if present or target guide if added.
- `accrue/guides/upgrade.md` - Generated-code ownership and versioning guidance.
- `accrue_admin/guides/admin_ui.md` - Admin mount/session docs.
- `examples/accrue_host/README.md` - Executable host app setup path.

### Dependency Mode And Package Correctness

- `examples/accrue_host/mix.exs` - Host dependency declarations and target for path/Hex mode switch.
- `scripts/ci/accrue_host_uat.sh` - Existing host UAT gate if present.
- `.github/workflows/ci.yml` - Release gate and place for Hex-mode validation.
- `accrue/mix.exs` - Package version, docs source refs, Hex metadata, guide extras.
- `accrue_admin/mix.exs` - Package version, docs source refs, Hex metadata, and existing env-gated sibling dependency pattern.
- `accrue_admin/README.md` - Admin package install snippet/version surface.

### Public API Boundary

- `examples/accrue_host/lib/accrue_host/billing.ex` - Generated host billing facade and likely read-helper extension point.
- `examples/accrue_host/lib/accrue_host/billing_handler.ex` - Generated host webhook handler boundary.
- `examples/accrue_host/lib/accrue_host_web/router.ex` - Host router webhook/admin mount shape.
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` - Tests proving generated facade contract.
- `examples/accrue_host/test/support/accrue_case.ex` - Host-facing test helper usage.
- `accrue/lib/accrue/test.ex` - Public host test facade.
- `accrue/lib/accrue/billing.ex` - Package billing facade under generated host facade.
- `accrue/lib/accrue/webhook/handler.ex` - Public handler macro/behaviour if present.
- `accrue_admin/lib/accrue_admin/router.ex` - Public admin mount macro.

### Ecosystem References

- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` - Phoenix generator precedent: generated auth code becomes host-owned.
- `https://hexdocs.pm/phoenix/routing.html` - Phoenix router pipeline and verified-route context.
- `https://hexdocs.pm/plug/Plug.Parsers.html` - Plug body reader/raw-body pattern relevant to Stripe webhook signatures.
- `https://hexdocs.pm/phoenix/releases.html` - Runtime config/release setup expectations.
- `https://hexdocs.pm/phoenix/ecto.html` - Phoenix/Ecto migrate-first setup pattern.
- `https://hexdocs.pm/oban/2.17.0/installation.html` - Oban migration/supervision setup expectations.
- `https://docs.stripe.com/webhooks/event-notification-handlers` - Stripe webhook handler expectations and common failure modes.
- `https://laravel.com/docs/11.x/billing` - Cashier lessons: concise happy path, webhook caveats, testing guidance, async subscription status caveats.
- `https://github.com/pay-rails/pay` - Pay lessons: generated migrations, route/webhook docs, fake processor, multi-processor caveats.
- `https://dj-stripe.dev/docs/dev/installation` - dj-stripe lessons: installation docs include webhook URL/setup rather than assuming it.
- `https://dj-stripe.dev/docs/dev/usage/webhooks` - dj-stripe webhook setup lessons.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html` - Hex package build validation.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` - Hex dry-run/publish validation.
- `https://hexdocs.pm/ex_doc/readme.html` - ExDoc extras/link/source configuration expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Accrue.Install.Fingerprints`: already stamps generated files and can distinguish pristine generated files from user-edited generated files.
- `Mix.Tasks.Accrue.Install`: already centralizes installer output, redaction, config validation, template writes, patching, and summary counts.
- `Accrue.Install.Options`: already exposes `--force` and `--write-conflicts`, but `--write-conflicts` currently needs behavior.
- `Accrue.Install.Patches`: already returns changed/skipped/manual patch results and manual snippets, making it the natural place to add conflict artifacts for patch failures.
- `Accrue.ConfigError`: existing configuration failure type that should become the stable setup-diagnostic carrier or wrap one.
- `examples/accrue_host`: existing host app can remain the single dogfood app for both path and Hex validation modes.
- `Accrue.Test`: existing host-facing test facade that docs should prefer over private Fake internals.
- `AccrueAdmin.Router.accrue_admin/2`: established public admin mount surface.

### Established Patterns

- Phoenix generator code is host-owned after generation; Accrue should respect that by updating only pristine generated files and never clobbering edited generated files.
- Host apps own schemas, Repo, auth/session boundary, routing, and generated `MyApp.Billing`; Accrue owns billing internals and exposes small host-facing facades.
- Fake Processor remains the deterministic local test surface; live Stripe stays advisory or explicit.
- Sensitive values must be redacted in installer output, diagnostics, logs, docs, tests, and artifacts.
- Docs should prefer public host paths and generated facades over private module knowledge.

### Integration Points

- Installer rerun/conflict behavior connects `Accrue.Install.Fingerprints`, `Accrue.Install.Patches`, and `Mix.Tasks.Accrue.Install` summary output.
- Setup diagnostics connect installer/preflight, boot-time config checks, webhook Plug failures, Oban setup, and admin mount/auth checks.
- Docs updates connect `accrue/README.md`, `accrue/guides/quickstart.md`, a new troubleshooting guide, existing testing/webhook/admin guides, and `examples/accrue_host/README.md`.
- Dependency-mode validation connects `examples/accrue_host/mix.exs`, host UAT scripts, package `mix.exs` metadata, README snippets, and CI.
- Public API clarity connects generated host facade templates, host example tests/UI, `Accrue.Test`, webhook handler docs, and admin router docs.

</code_context>

<specifics>
## Specific Ideas

- Favor `mix accrue.install --check` as the preflight surface if it avoids inventing a new task, but a `mix accrue.doctor` alias is acceptable if it improves discoverability.
- Conflict artifacts should not be written beside live `.ex` or `.exs` files where compilers, formatters, or editors might treat them as app code.
- Troubleshooting rows should be anchored so diagnostics can link directly to `quickstart.html#missing-oban`-style or `troubleshooting.html#accrue-dx-oban-not-running`-style anchors.
- Use the current package version source of truth to fix stale snippets such as `~> 1.0.0` when published packages are still `0.1.2`.
- If host UI/tests currently inspect billing state through package schemas, Phase 12 should add generated facade read helpers rather than documenting those schemas as first-user APIs.

</specifics>

<deferred>
## Deferred Ideas

- Maintained public demo/tutorial packaging, screenshots, README positioning as adoption assets - Phase 13.
- Security/audit pass for webhook/auth/admin boundaries - Phase 14.
- Performance, accessibility, responsive-browser, and compatibility matrices - Phase 14.
- Hosted public demo environment - future requirement `HOST-09`, not Phase 12.

</deferred>

---

*Phase: 12-first-user-dx-stabilization*
*Context gathered: 2026-04-16*
