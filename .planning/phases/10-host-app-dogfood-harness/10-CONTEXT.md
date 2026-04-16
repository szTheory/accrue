# Phase 10: Host App Dogfood Harness - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 10 creates the canonical minimal Phoenix host app that proves a new user can install and use `accrue` and `accrue_admin` through public APIs. The phase is limited to the local dogfood harness: app scaffold, documented setup commands, Fake-backed billing flow, signed webhook flow, realistic admin mount/auth boundary, and local verification. CI release-gate wiring, docs/tutorial polish, adoption packaging, and quality hardening belong to later v1.1 phases.

</domain>

<decisions>
## Implementation Decisions

### Harness Location and Shape

- **D-01:** Create the dogfood app as a normal Phoenix app under `examples/accrue_host`, using a conventional host namespace such as `AccrueHost`. This keeps it visible to users and lets Phase 13 reuse the same path for adoption assets without turning Phase 10 into tutorial work.
- **D-02:** The host app must be rebuilt from a clean checkout using documented commands, with no hidden local database, private machine state, or manual setup outside the documented path.
- **D-03:** Default dogfood mode uses local path dependencies for `accrue` and `accrue_admin` so the harness validates the current repo. Leave Hex-style dependency validation for Phase 12 unless it is trivial to support without weakening the path-dependency proof.
- **D-04:** Treat generated installer output as part of the proof. The app should be created or refreshed through `mix accrue.install` and should not hand-wire private Accrue internals to make the harness pass.

### Host-Owned Domain and Auth Boundary

- **D-05:** Use a minimal host-owned `Accounts.User` billable schema with `use Accrue.Billable`; Accrue must not own the user schema.
- **D-06:** Prefer a simple Phoenix-auth-shaped host session boundary over Sigra for this harness. That tests the generic public adapter path instead of relying on another Jon-owned library.
- **D-07:** Mount `accrue_admin` at `/billing` through `AccrueAdmin.Router.accrue_admin/2`, threading only the host session keys needed to identify the current admin.
- **D-08:** Protect the admin mount through a realistic host-owned auth/session check. A test-only bypass is acceptable only if it is explicit, documented, and not the default browser path.

### Fake-Backed User Billing Flow

- **D-09:** The primary user-facing flow should be a small SaaS-style subscription path: signed-in user views a plan, starts a subscription through the generated `MyApp.Billing` facade, sees persisted billing state, and can perform at least one update action such as plan swap or cancel.
- **D-10:** The flow must run against `Accrue.Processor.Fake` with no network access and no live Stripe dependency.
- **D-11:** The host app may use deterministic fake price IDs such as `price_basic` and `price_pro`; the important proof is that calls go through public checkout/subscription APIs and persist normal Accrue state.
- **D-12:** Avoid a fake UI that only inserts rows. The host flow should exercise Accrue APIs and reducer paths so failures expose real first-user integration friction.

### Webhook Proof

- **D-13:** Mount a scoped webhook endpoint using the installer-generated route and the public `Accrue.Webhook.Plug` path, including raw-body handling and signature verification.
- **D-14:** The dogfood test should post a signed Fake/Stripe-shaped payload through the host endpoint rather than bypassing the Plug with direct reducer calls.
- **D-15:** The webhook flow should prove idempotent ingest, persisted `accrue_webhook_events`, dispatch through the normal handler path, and resulting billing/event-ledger state.

### Admin Flow and Audited Action

- **D-16:** The admin UAT path should inspect state created by the user-facing flow, including customer/subscription/webhook/event history visible through `accrue_admin`.
- **D-17:** The required audited admin action should be a low-risk webhook/admin operation such as replaying or requeueing a failed webhook event, because that uses existing admin semantics and avoids inventing refund/cancellation product policy in the dogfood app.
- **D-18:** The admin action proof must verify that an audit/event record is produced, not just that the UI flashes a success message.

### Local Verification

- **D-19:** Phase 10 should add local verification commands for setup, migrations, tests, and booting the host app. CI integration and required GitHub Actions gating are Phase 11.
- **D-20:** Include at least one browser-facing or browser-equivalent UAT path for the host app plus mounted admin UI. A local Playwright path is acceptable if it follows existing repo patterns; otherwise LiveView/Conn tests may cover the same end-to-end behavior until Phase 11 formalizes browser artifacts.
- **D-21:** The verification path must fail on private shortcuts: direct inserts that avoid public APIs, missing raw-body webhook handling, unauthenticated admin mount, hidden env requirements, or generated artifact drift.

### the agent's Discretion

- Exact Phoenix app generator command and whether to commit generated static assets, as long as clean checkout rebuild remains documented and deterministic.
- Exact host auth implementation details, as long as it is host-owned, session-backed, and protects `accrue_admin` realistically.
- Exact route names and page copy inside the dogfood app.
- Whether the local browser UAT uses Playwright immediately or starts with Phoenix-level browser-equivalent tests, provided Phase 11 can promote it to CI without redesign.
- Exact admin action selected from existing `accrue_admin` capabilities, provided it is audited and visible in persisted state.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/PROJECT.md` — v1.1 stabilization goal, Accrue philosophy, constraints, brand, and key product decisions.
- `.planning/REQUIREMENTS.md` — Phase 10 requirement IDs `HOST-01` through `HOST-08` and related out-of-scope boundaries.
- `.planning/ROADMAP.md` — Phase 10 goal, dependencies, success criteria, and relationship to Phases 11-15.
- `.planning/STATE.md` — Current project state and recent prior decisions.

### Prior Decisions

- `.planning/milestones/v1.0-phases/07-admin-ui-accrue-admin/07-CONTEXT.md` — `accrue_admin` router macro, package-owned admin UI, admin auth/session threading, dev surfaces, and browser UAT patterns.
- `.planning/milestones/v1.0-phases/08-install-polish-testing/08-CONTEXT.md` — Installer safety model, generated `MyApp.Billing` facade, generated webhook handler, Fake-first test facade, and testing guide direction.
- `.planning/milestones/v1.0-phases/02-schemas-webhook-plumbing/02-CONTEXT.md` — Raw-body webhook pipeline, idempotent ingest, and host-owned billable schema boundary.
- `.planning/milestones/v1.0-phases/03-core-subscription-lifecycle/03-CONTEXT.md` — Public subscription lifecycle APIs and Fake-backed billing state behavior.

### Existing Code

- `accrue/lib/mix/tasks/accrue.install.ex` — Public installer task that Phase 10 must dogfood.
- `accrue/priv/accrue/templates/install/billing.ex.eex` — Generated host-owned billing facade template.
- `accrue/priv/accrue/templates/install/billing_handler.ex.eex` — Generated host webhook side-effect handler template.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` — Existing installer UAT patterns and temporary Phoenix fixture expectations.
- `accrue/test/support/install_fixture.ex` — Existing Phoenix-shaped install fixture helper.
- `accrue/lib/accrue/test.ex` — Public host-facing test helper facade.
- `accrue/lib/accrue/test/webhooks.ex` — Synthetic webhook helper; useful reference, but Phase 10 should also prove the Plug route.
- `accrue/lib/accrue/test/factory.ex` — Fake-backed billing factory primitives for realistic state.
- `accrue/lib/accrue/webhook/plug.ex` — Public signed webhook Plug path to mount in the host app.
- `accrue/lib/accrue/webhook/ingest.ex` — Normal ingest/idempotency/Oban/event-ledger path.
- `accrue_admin/lib/accrue_admin/router.ex` — Public `accrue_admin "/billing"` mount macro.
- `accrue_admin/test/support/live_case.ex` — Current mounted admin test router/session example.
- `accrue_admin/test/support/e2e_server.ex` — Existing local admin E2E server startup pattern.
- `accrue_admin/e2e/phase7-uat.spec.js` — Current Playwright UAT shape for admin flows.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Mix.Tasks.Accrue.Install`: already parses the required installer flags, discovers Phoenix-shaped projects, renders host-owned templates, patches router/config, and reports redacted setup status.
- `Accrue.Install.Templates` and installer templates: already generate `MyApp.Billing`, webhook handler, runtime config, and event immutability migration material.
- `Accrue.Test`: imports the public host test facade and configures Fake, mail, PDF, event assertions.
- `Accrue.Test.Factory`: creates realistic Fake-backed customers/subscriptions without direct Stripe/network calls.
- `Accrue.Webhook.Plug`: verifies signatures from raw request bodies and runs normal ingest.
- `AccrueAdmin.Router.accrue_admin/2`: mounts the admin UI with package-owned routes, assets, LiveSession, auth hook, and session key threading.
- `accrue_admin` Playwright setup: existing browser UAT infrastructure can guide host-app browser verification if Playwright is used.

### Established Patterns

- Host app owns its schemas, Repo, routing, auth/session boundary, and generated facade; Accrue owns billing/provider/webhook internals.
- Fake Processor is the mandatory local test surface and should be preferred over live Stripe for deterministic dogfood verification.
- Public APIs and generated host-facing modules are the integration boundary; direct inserts are acceptable only for setup/fixtures when they do not replace the user-facing proof.
- Admin UI is mounted like Phoenix LiveDashboard/Oban.Web and should not require host asset pipeline or layout edits.
- Sensitive values must be redacted from installer output, logs, docs, test artifacts, and planning docs.

### Integration Points

- Root repo will gain a host app path, expected as `examples/accrue_host`.
- Host app `mix.exs` depends on local `../../accrue` and `../../accrue_admin` path dependencies from `examples/accrue_host`.
- Host router integrates generated webhook route and `accrue_admin "/billing"`.
- Host app config sets `Accrue.Repo`, `Accrue.Processor.Fake`, webhook signing secret, auth adapter, and Oban wiring for local dogfood.
- Host tests/UAT exercise user pages, webhook POST route, admin mount, and audited admin action.

</code_context>

<specifics>
## Specific Ideas

- The harness should feel like a real Phoenix SaaS app, not a unit-test-only fixture.
- Keep the host app minimal, but include enough UI to prove the first-user path: sign in, subscribe/update, see billing state, inspect in admin.
- Prefer boring Phoenix conventions and explicit commands over clever generated shortcuts.
- Phase 10 should expose failures that Phase 12 can turn into installer, docs, and diagnostics fixes.

</specifics>

<deferred>
## Deferred Ideas

- Mandatory GitHub Actions gate for the host app — Phase 11.
- Hex-style dependency validation and first-hour troubleshooting polish — Phase 12 unless trivial to include safely.
- Public tutorial/demo packaging, screenshots, and README positioning — Phase 13.
- Security, performance, accessibility, responsive, and compatibility hardening — Phase 14.
- Hosted public demo environment — future requirement `HOST-09`, not Phase 10.

</deferred>

---

*Phase: 10-host-app-dogfood-harness*
*Context gathered: 2026-04-16*
