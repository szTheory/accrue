# Phase 15: Trust Hardening - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the quality evidence a billing-library adopter expects before trusting Accrue in a real Phoenix app. This phase covers security review artifacts, seeded performance smoke checks, supported-version compatibility checks, accessibility and responsive browser coverage for demo/admin flows, secret/PII leakage review, and required-vs-advisory release-gate clarity. It does not implement tax, revenue/export, additional processor, organization billing, hosted demos, or core billing architecture changes.

</domain>

<decisions>
## Implementation Decisions

### Security Review Evidence

- **D-01:** Produce a checked-in security review artifact that is explicit and boring: webhook verification/raw-body ordering, auth/session and step-up assumptions, admin mount/replay authorization, generated-host boundaries, replay/idempotency, retained artifacts, logs, and public issue intake.
- **D-02:** Treat the artifact as evidence for maintainers and adopters, not as a marketing claim. It should identify what is verified, what is host-owned, and what remains advisory or environment-specific.
- **D-03:** Security review should connect to existing Phase 14 no-secrets support routing and should not ask users to paste production payloads, customer data, Stripe keys, webhook secrets, tokens, or PII.

### Performance Smoke Checks

- **D-04:** Keep performance checks seeded, deterministic, and smoke-level. They should prove that webhook ingest and admin pages stay within reasonable local budgets, not attempt benchmark-suite precision.
- **D-05:** Webhook ingest should measure the signed request path through verify/persist/enqueue/response. Admin responsiveness should measure the seeded dashboard/detail/replay pages used by the canonical demo.
- **D-06:** Performance output should be easy to inspect locally and usable in CI. Store compact metrics or summaries only; avoid retaining raw payloads, logs with secrets, or large noisy artifacts.

### Compatibility Matrix

- **D-07:** Compatibility should verify the supported floor and primary target combinations already documented by the project: Elixir 1.17+, OTP 27+, Phoenix 1.8+, LiveView 1.0+ for public support, with existing forward-compat smoke where practical.
- **D-08:** Required release gates should stay focused on supported combinations. Optional/advisory cells, such as unpublished optional integrations or provider-backed checks, must remain clearly labeled and must not silently block deterministic CI.
- **D-09:** Prefer extending existing GitHub Actions and package/host verification scripts over introducing a separate compatibility system.

### Accessibility And Responsive Browser Coverage

- **D-10:** Build on the existing Playwright + axe path from Phase 13. Keep critical/serious axe violations release-blocking for the canonical demo/admin flow.
- **D-11:** Add responsive browser coverage for the same user-facing surfaces rather than inventing a broad visual-regression product. Cover at least a small mobile viewport and a desktop viewport for subscription, admin dashboard, webhook detail/replay, and replay audit states.
- **D-12:** Screenshots are useful as review artifacts, but tests should assert behavior and accessibility/responsive basics directly. Failure artifacts may be uploaded; success artifacts should remain compact and should not contain secrets or PII.

### Secret And PII Leakage Review

- **D-13:** Review public errors, logs, docs, issue templates, CI output, Playwright artifacts, and retained screenshots/traces for Stripe secrets, webhook secrets, tokens, production payloads, customer data, and PII leakage.
- **D-14:** Add automated guardrails where they are cheap and high-signal: docs/template scanners, log/artifact allowlist checks, and focused tests around redaction-sensitive errors.
- **D-15:** Do not weaken diagnostics to avoid leakage. Keep actionable messages, but name config keys/classes and remediation paths instead of raw values.

### Release-Gate Language

- **D-16:** Release guidance must distinguish required deterministic gates from advisory checks. Required gates include package checks, host integration, generated drift/docs drift, security/trust artifacts, seeded performance smoke, compatibility floor/target checks, and browser accessibility/responsive checks.
- **D-17:** Provider-backed Stripe test/live checks remain advisory unless a future phase explicitly changes the release model. They may run manually, on schedule, or with `continue-on-error`, using GitHub/environment secrets only.
- **D-18:** Public copy may become more confident after this phase, but only to the level supported by the new evidence. Avoid broad unsupported claims such as `battle-tested` or blanket `enterprise-grade`.

### the agent's Discretion

- Exact artifact filenames and section ordering, as long as downstream readers can trace each `TRUST-*` requirement to a concrete check or review artifact.
- Exact performance thresholds, as long as they are conservative, documented, deterministic enough for CI, and aligned with the project-level webhook request-path budget.
- Exact viewport choices, as long as both mobile and desktop are covered and the canonical demo/admin surfaces remain the target.
- Exact scanner implementation, as long as it is maintainable and covers the sensitive value classes named above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/PROJECT.md` - v1.2 Adoption + Trust goal, supported stack, security/performance constraints, release model, and proof-backed claims principle.
- `.planning/REQUIREMENTS.md` - Phase 15 requirements `TRUST-01` through `TRUST-06`.
- `.planning/ROADMAP.md` - Phase 15 goal and success criteria.
- `.planning/STATE.md` - Current project state and phase position.

### Prior Decisions

- `.planning/phases/12-first-user-dx-stabilization/12-CONTEXT.md` - Setup diagnostics, `Accrue.ConfigError`, and redaction expectations for setup failures.
- `.planning/phases/13-canonical-demo-tutorial/13-CONTEXT.md` - Canonical demo path, host command manifest, Playwright/axe walkthrough, and screenshot artifact precedent.
- `.planning/phases/14-adoption-front-door/14-CONTEXT.md` - No-secrets support intake, Fake/test/live Stripe positioning, proof-backed adoption copy, and required-vs-advisory release guidance.

### Existing Gates And Scripts

- `.github/workflows/ci.yml` - Current release-gate matrix, host integration gate, artifact upload behavior, annotation sweep, and advisory live-Stripe job.
- `.github/workflows/accrue_host_uat.yml` - Manual host UAT workflow shape.
- `scripts/ci/accrue_host_uat.sh` - Required deterministic host UAT wrapper.
- `scripts/ci/accrue_host_browser_smoke.cjs` - Existing browser smoke path that can inform performance/admin responsiveness checks.
- `scripts/ci/accrue_host_seed_e2e.exs` - Seeded host data for browser and admin flows.
- `scripts/ci/verify_package_docs.sh` - Existing docs/package invariant script.
- `scripts/ci/accrue_host_hex_smoke.sh` - Hex-mode smoke validation, separate from canonical local and advisory provider checks.
- `guides/testing-live-stripe.md` - Advisory live Stripe guidance and secrets-handling expectations.
- `RELEASING.md` - Release runbook to clarify required vs advisory trust gates.
- `CONTRIBUTING.md` - Contributor setup and release-gate guidance.
- `SECURITY.md` - Private vulnerability disclosure route.

### Demo And Browser Surfaces

- `examples/accrue_host/mix.exs` - Host `mix verify`, `mix verify.full`, dev boot, browser smoke, and dependency-mode aliases.
- `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` - Existing canonical Playwright walkthrough, axe checks, and screenshot artifact pattern.
- `examples/accrue_host/README.md` - Canonical local evaluation docs that trust checks should reinforce.
- `accrue/guides/first_hour.md` - Package-facing tutorial mirror.
- `accrue_admin/guides/admin_ui.md` - Admin mount/auth/session/operator guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The Phase 13 Playwright spec already logs in as normal and admin users, starts a Fake-backed subscription, posts a signed webhook, opens admin dashboard/detail/replay/audit pages, runs axe critical/serious checks, and captures screenshots.
- `scripts/ci/accrue_host_uat.sh` delegates to host-local `mix verify.full`, which already controls dev boot, full host regression, browser smoke, and generated install verification.
- `.github/workflows/ci.yml` already separates deterministic release gates from the advisory live-Stripe job and uploads Playwright/server artifacts only when useful.
- Existing docs tests and `scripts/ci/verify_package_docs.sh` give a pattern for drift/scanner-style guardrails without generating docs.

### Established Patterns

- Fake-backed local/CI checks are deterministic and release-blocking; Stripe-backed checks are provider-parity/advisory unless explicitly changed.
- Host app owns auth, routes, Repo, generated billing facade, runtime secrets, and production configuration; Accrue owns package internals and public integration macros/facades.
- Trust evidence should be specific and traceable, not broad maturity marketing.
- Sensitive values are described by key/class and docs path, not by raw value.

### Integration Points

- Security review artifacts should connect `SECURITY.md`, issue templates, release guidance, webhook docs, admin UI docs, and host generated-boundary docs.
- Performance and responsive checks should extend the host UAT/browser flow so a maintainer can run one familiar verification command.
- Compatibility checks should extend the existing BEAM matrix and host/package workflows where possible.
- Secret/PII scans should cover docs, issue templates, release docs, CI logs/artifacts, screenshots/traces, and redaction-sensitive error paths.

</code_context>

<specifics>
## Specific Ideas

- Add a `TRUST-01` security review markdown artifact under the Phase 15 planning directory or a project docs location, then link it from release guidance if useful.
- Add a seeded performance smoke command that reports webhook ingest latency and admin page responsiveness in plain text or compact JSON.
- Reuse the current admin pages in the Phase 13 browser test for responsive coverage instead of creating a separate artificial UI.
- Use the same wording discipline from Phase 14: `required deterministic gate`, `provider parity`, and `advisory/manual` should remain distinct labels.
- Keep success artifacts compact. Failure artifacts can be richer, but scanners should guard against accidental secret/PII retention.

</specifics>

<deferred>
## Deferred Ideas

- Hosted public demo remains out of scope for v1.2.
- Tax, revenue/export, additional processor, and organization/multi-tenant billing remain Phase 16 discovery topics.
- Making live Stripe required for Accrue release gating is deferred unless provider instability becomes a release-blocking class of bug.

</deferred>

---

*Phase: 15-trust-hardening*
*Context gathered: 2026-04-17*
