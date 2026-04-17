# Phase 14: Adoption Front Door - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the public repository, package docs, and support surfaces explain what Accrue is, where to start, what is stable, and how to ask for help. This phase covers the root repository README, package README/docs alignment, issue templates, release/support guidance, Fake vs Stripe positioning, public API boundary messaging, and proof-backed adoption copy. It does not add billing capability, build a hosted demo, or perform the Phase 15 trust-hardening checks.

</domain>

<decisions>
## Implementation Decisions

### Root README Front Door

- **D-01:** Create a balanced root `README.md` front door. It should not be a full tutorial and should not be a bare link list.
- **D-02:** The root README should answer six questions in the first scan: what Accrue is, what the two packages do, where the canonical local demo lives, where the package tutorial starts, what public boundaries are stable, and how Fake/Stripe validation modes differ.
- **D-03:** Keep detailed setup commands owned by canonical docs: `examples/accrue_host/README.md` for executable local evaluation and `accrue/guides/first_hour.md` for package-facing setup. The root README may show the shortest demo entry snippet only if it links to the owning doc immediately.
- **D-04:** Avoid audience-split portal sprawl. The root README may have clear paths for evaluators, integrators, and maintainers, but the primary path must remain the Fake-backed local demo plus First Hour guide.

### Package Docs Alignment

- **D-05:** Preserve a three-layer documentation architecture:
  - root `README.md` is the adoption front door and route map.
  - `examples/accrue_host/README.md` owns clone-to-running local evaluation.
  - `accrue/guides/first_hour.md` owns the package-facing tutorial mirror.
- **D-06:** `accrue/README.md` should stay a compact package landing page, not a second full tutorial. It should point to First Hour, troubleshooting, webhooks, testing, upgrade, and the host demo.
- **D-07:** `accrue_admin/README.md` and `accrue_admin/guides/admin_ui.md` should document admin-specific mount, auth/session, branding, assets, and operator concerns. They should not become the product entry point before core billing/webhook setup.
- **D-08:** Topic guides such as testing, webhooks, troubleshooting, upgrade, and admin UI should remain focused references, not alternate onboarding flows.
- **D-09:** Planning should include lightweight drift checks where feasible for root/package README links, canonical command labels, public-boundary mentions, and Fake/test/live positioning.

### Fake vs Stripe Positioning

- **D-10:** Fake is the only canonical front-door evaluation path and the only required deterministic release gate for this phase's docs.
- **D-11:** Stripe test mode belongs behind an explicit `provider-parity checks` label. It proves Stripe response-shape drift, SCA/3DS branches, hosted Checkout behavior, and real signature flow where Fake cannot.
- **D-12:** Live Stripe belongs behind an explicit `advisory/manual before shipping your app` label. It must not be framed as required for cloning, local demo evaluation, CI, or Accrue release gating.
- **D-13:** Docs and release guidance must not imply Fake is full Stripe parity. They should state what Fake proves and what only Stripe-backed checks prove.
- **D-14:** Keep provider-backed checks out of the main CI/release lane. They may be tagged, scheduled, manual, or advisory, with secrets kept in environment variables/GitHub secrets only.

### Support Surfaces

- **D-15:** Add GitHub issue forms using a hybrid support model: four focused public issue forms plus private/security contact links. Disable blank issues.
- **D-16:** The issue taxonomy should be:
  - `bug`: confirmed or likely defect in `accrue` or `accrue_admin`.
  - `integration problem`: first-time setup, public API confusion, generator/host-boundary mismatch, webhook/config/auth/admin blockers.
  - `documentation gap`: missing, wrong, stale, or unclear docs.
  - `feature request`: problem-driven request, not implementation demand.
- **D-17:** Do not add a generic support-question issue template. Route general usage reading to First Hour and troubleshooting, while keeping legitimate Accrue integration failures public and triageable.
- **D-18:** Issue forms must ask for sanitized, useful context only. They must not ask users to paste Stripe keys, webhook secrets, customer data, production payloads, or PII.
- **D-19:** Template language should anchor users to public Accrue surfaces and host-owned boundaries, not private modules or tables.

### Public API Stability Message

- **D-20:** Repeat one short public-boundary contract anywhere a first user starts: supported first-time integration surfaces are generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, and `Accrue.ConfigError` for setup failures.
- **D-21:** State that generated files are host-owned after install. Accrue may regenerate pristine stamped files per installer policy, but user-edited generated files are not silently managed.
- **D-22:** State that internal schemas, webhook/event structs, reducer modules, worker internals, and demo-only setup helpers are not app-facing APIs.
- **D-23:** Keep public-boundary examples copy-paste safe. First-user snippets should use generated host facade calls and public macros/helpers rather than direct `Accrue.Billing.Customer`, `Accrue.Webhook.WebhookEvent`, `Accrue.Events.Event`, or private Fake GenServer calls.
- **D-24:** API-doc/module-level public/private labeling can supplement the front-door message, but it is not enough by itself because users copy README and guide snippets first.

### Brand Voice and Claims

- **D-25:** Use a framework-native, proof-backed voice: calm, precise, Phoenix/Ecto/Plug-aware, and specific about what the host demo proves.
- **D-26:** Lead with identity and operating model, not ambition: Accrue is the open-source Elixir/Ecto/Phoenix billing library that keeps billing state queryable in the host app.
- **D-27:** Put proof near the top of the adoption front door: start one Fake-backed subscription, post one signed webhook, inspect/replay the result in admin, and run the focused proof suite.
- **D-28:** Avoid unsupported maturity claims such as `battle-tested`, `enterprise-grade`, or broad `production-grade` claims until Phase 15 creates trust evidence. If broader claims are used, narrow them to what the checked-in host app and current gates prove.
- **D-29:** Avoid fintech/marketing language such as `revenue engine`, `monetize faster`, wallet/card/coin imagery, or processor-breadth claims beyond the current Stripe-first model.
- **D-30:** Preferred copy direction:
  - Headline: `Billing state, modeled clearly.`
  - Descriptor: `Accrue is an open-source billing library for Elixir, Ecto, and Phoenix. Your app owns the billing facade, routes, auth boundary, and runtime config; Accrue owns the billing engine behind them.`
  - Proof strip: `Start one Fake-backed subscription. Post one signed webhook. Inspect and replay the result in admin. Run the focused proof suite.`

### Coherent Recommendation

- **D-31:** Phase 14 should make the adoption surface feel mature by being boring in the right ways: one front door, one executable local demo, one package tutorial mirror, one explicit public-boundary contract, one Fake-first validation story, and structured support intake.

### the agent's Discretion

- Exact root README section order and wording, as long as the first screen covers identity, package map, canonical demo path, public boundaries, and Fake/Stripe mode labels.
- Exact issue form filenames and YAML field names, as long as the four-form taxonomy and no-secrets constraints are preserved.
- Exact drift-check implementation and placement, as long as canonical owner boundaries and public API mentions are checked somewhere reasonable.
- Exact release-guidance placement for Fake/test/live labels, as long as required vs advisory checks are unambiguous.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/PROJECT.md` - v1.2 Adoption + Trust goal, brand voice, project philosophy, public boundaries, and current milestone constraints.
- `.planning/REQUIREMENTS.md` - Phase 14 requirements `ADOPT-01` through `ADOPT-06`.
- `.planning/ROADMAP.md` - Phase 14 goal and success criteria.
- `.planning/STATE.md` - Current project state and recent phase position.

### Prior Decisions

- `.planning/phases/12-first-user-dx-stabilization/12-CONTEXT.md` - First Hour guide shape, public API clarity, setup diagnostics, safe generated-code reruns, and host-first docs decisions.
- `.planning/phases/13-canonical-demo-tutorial/13-CONTEXT.md` - Canonical host demo/tutorial split, command labels, Fake-first local path, seeded history label, and drift guard direction.

### Adoption And Docs Surfaces

- `README.md` - Target root adoption front door; currently absent and should be created.
- `accrue/README.md` - Core package landing page and install/public API surface.
- `accrue_admin/README.md` - Admin package landing page and mount/auth/session pointer.
- `examples/accrue_host/README.md` - Canonical executable local evaluation path.
- `accrue/guides/first_hour.md` - Package-facing tutorial mirror.
- `accrue/guides/quickstart.md` - Compact setup guide that should not conflict with First Hour.
- `accrue/guides/troubleshooting.md` - Troubleshooting/support routing target.
- `accrue/guides/testing.md` - Fake-first testing guidance and provider-parity appendix.
- `accrue/guides/webhooks.md` - Signed webhook setup guidance.
- `accrue/guides/upgrade.md` - Generated-code ownership and deprecation policy.
- `accrue_admin/guides/admin_ui.md` - Admin UI integration guide.

### Support And Release Surfaces

- `.github/ISSUE_TEMPLATE/` - Target directory for Phase 14 issue forms.
- `.github/workflows/accrue_host_uat.yml` - Required host UAT gate context.
- `.github/workflows/ci.yml` - Broader CI and advisory-provider-check context.
- `CONTRIBUTING.md` - Contributor setup and release-gate guidance.
- `SECURITY.md` - Private vulnerability disclosure route.
- `RELEASING.md` - Release guidance that should distinguish required vs advisory checks.
- `guides/testing-live-stripe.md` - Existing live Stripe advisory/provider-parity guidance.
- `scripts/ci/accrue_host_uat.sh` - Required deterministic host UAT wrapper.
- `scripts/ci/accrue_host_hex_smoke.sh` - Hex-mode smoke validation, separate from canonical local demo.

### Existing Code And Tests

- `examples/accrue_host/mix.exs` - Host aliases such as `mix setup`, `mix verify`, and `mix verify.full`.
- `examples/accrue_host/lib/accrue_host/billing.ex` - Generated host-owned billing facade and public tutorial boundary.
- `examples/accrue_host/lib/accrue_host/billing_handler.ex` - Generated host webhook handler boundary.
- `examples/accrue_host/lib/accrue_host_web/router.ex` - Host webhook/admin mount shape.
- `accrue/lib/accrue/test.ex` - Public host-facing test facade.
- `accrue/lib/accrue/webhook/handler.ex` - Public webhook handler macro/behaviour.
- `accrue_admin/lib/accrue_admin/router.ex` - Public admin mount macro.
- `accrue/test/accrue/docs/first_hour_guide_test.exs` - Existing docs/public-boundary contract test.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Existing package docs verifier.
- `scripts/ci/verify_package_docs.sh` - Existing package docs invariant script.

### Ecosystem References

- `https://github.com/phoenixframework/phoenix` - Concise framework README precedent.
- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` - Generated-code ownership precedent.
- `https://hexdocs.pm/phoenix/contexts.html` - Phoenix context boundary precedent.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` - Router macro/mounted integration precedent.
- `https://hexdocs.pm/oban/installation.html` - Mature Elixir setup/install docs precedent.
- `https://github.com/pay-rails/pay` - Billing-library README, fake processor, and route/webhook lessons.
- `https://github.com/pay-rails/pay/blob/main/docs/fake_processor/1_overview.md` - Fake processor positioning precedent.
- `https://laravel.com/docs/11.x/billing` - Cashier billing/webhook/testing guidance and footguns.
- `https://dj-stripe.dev/docs/dev/installation` - Explicit app/webhook setup precedent.
- `https://dj-stripe.dev/docs/dev/usage/webhooks` - Webhook setup and mode clarity precedent.
- `https://docs.stripe.com/webhooks` - Stripe webhook endpoint/signature/testing guidance.
- `https://docs.stripe.com/billing/subscriptions/webhooks` - Billing webhook expectations.
- `https://docs.stripe.com/testing-use-cases` - Stripe test-mode positioning.
- `https://docs.stripe.com/billing/testing/test-clocks` - Provider-parity lifecycle testing.
- `https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository` - GitHub issue form configuration.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/accrue_host`: already exists as the single canonical checked-in host app and local evaluation path.
- `examples/accrue_host/README.md`: already documents the Fake-backed first-run path, seeded history path, and verification modes.
- `accrue/guides/first_hour.md`: already mirrors the host path in package-facing terms and names the public boundaries.
- `accrue/README.md`: already has compact package landing structure that Phase 14 can align rather than replace.
- `accrue_admin/README.md`: already keeps admin-specific setup focused around mount/auth/assets.
- `guides/testing-live-stripe.md`: already frames live Stripe as fidelity/advisory coverage, not the default local path.
- `RELEASING.md`: existing release runbook can be updated to distinguish deterministic required gates from provider-advisory checks.
- `CONTRIBUTING.md`: existing contributor setup can point to host/demo verification and issue routing.

### Established Patterns

- Host apps own schemas, Repo, routing, auth/session boundary, generated `MyApp.Billing`, and runtime config.
- Accrue owns billing internals and should expose small public facades/macros/helpers rather than teaching private schemas.
- Fake Processor is the deterministic local test/demo surface; Stripe-backed checks are provider-parity/advisory.
- Docs are human-written, with small tests/scripts enforcing command/link/public-boundary drift.
- Sensitive values must be redacted from docs, issue templates, logs, retained artifacts, and release guidance.

### Integration Points

- Root `README.md` should connect repository-level orientation to `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, package READMEs, support templates, and release/trust guidance.
- Issue templates connect `.github/ISSUE_TEMPLATE/`, `SECURITY.md`, `CONTRIBUTING.md`, First Hour, troubleshooting, and public-boundary docs.
- Release guidance connects `RELEASING.md`, `guides/testing-live-stripe.md`, host UAT scripts/workflows, Hex smoke, and provider-advisory checks.
- Drift guards can extend existing docs tests/scripts rather than inventing a new docs generation system.

</code_context>

<specifics>
## Specific Ideas

- Root README first screen should read roughly: `Billing state, modeled clearly.` then a compact descriptor, package map, and proof strip.
- Use mode labels consistently: `Canonical local demo: Fake`, `Provider parity: Stripe test mode`, `Advisory/manual: live Stripe`.
- Add issue chooser copy that routes security vulnerabilities to `SECURITY.md` and tells users not to paste secrets, webhook payloads with PII, or production customer data.
- For feature requests, ask for the problem, current workaround, affected public API surface, and why it belongs in Accrue rather than host app code.
- Keep all examples anchored to generated `MyApp.Billing` and public macros/helpers.

</specifics>

<deferred>
## Deferred Ideas

- Hosted public demo remains out of scope for v1.2 unless a future milestone explicitly adds it.
- Phase 15 trust hardening should decide whether and how to make security/performance/accessibility/compatibility evidence more prominent in the adoption front door.
- Expansion-feature positioning for tax, revenue/export, additional processors, and org billing belongs to Phase 16 discovery, not Phase 14 marketing copy.

</deferred>

---

*Phase: 14-adoption-front-door*
*Context gathered: 2026-04-17*
