# Phase 15: Trust Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 15-Trust Hardening
**Areas discussed:** Security Review Evidence, Performance Smoke Checks, Compatibility Matrix, Accessibility And Responsive Browser Coverage, Secret And PII Leakage Review, Release-Gate Language

---

## Workflow Note

`$gsd-next` routed to `$gsd-discuss-phase 15`. The structured question UI is unavailable in this Codex execution mode, so the workflow adapter fallback was used: present the implicit options, choose conservative recommended defaults, and record the choices explicitly.

## Security Review Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Artifact-first review | Create a checked-in review artifact covering webhook, auth, admin, replay, generated-host, logs, retained artifacts, and support intake boundaries. | yes |
| Tests only | Rely only on automated tests and CI output. | |
| Marketing trust page | Summarize confidence claims publicly without detailed maintainer evidence. | |

**User's choice:** Fallback selected artifact-first review.
**Notes:** This matches Phase 14's proof-backed claims constraint and avoids unsupported maturity language.

---

## Performance Smoke Checks

| Option | Description | Selected |
|--------|-------------|----------|
| Seeded smoke checks | Measure deterministic webhook ingest and admin page responsiveness from seeded host data. | yes |
| Full benchmark suite | Build broad benchmark infrastructure with statistically rigorous runs. | |
| Manual observation | Leave performance confidence to human local runs. | |

**User's choice:** Fallback selected seeded smoke checks.
**Notes:** The project already has a host seed/browser path and a project-level webhook request-path budget. Smoke-level checks are the right Phase 15 size.

---

## Compatibility Matrix

| Option | Description | Selected |
|--------|-------------|----------|
| Supported floor plus primary target | Verify documented supported floors and primary combinations, with forward-compat smoke where practical. | yes |
| Exhaustive dependency matrix | Test every meaningful Phoenix/LiveView/OTP combination. | |
| Documentation only | State supported versions without automated confirmation. | |

**User's choice:** Fallback selected supported floor plus primary target.
**Notes:** Existing CI already has BEAM matrix structure; planning should extend it rather than replace it.

---

## Accessibility And Responsive Browser Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Extend Playwright/axe path | Add responsive/mobile+desktop coverage to the existing canonical demo/admin browser test. | yes |
| Visual regression suite | Add broad screenshot diffing across many pages and breakpoints. | |
| Axe only | Keep accessibility checks but skip responsive viewport assertions. | |

**User's choice:** Fallback selected extending the existing Playwright/axe path.
**Notes:** Phase 13 already proved canonical admin/demo surfaces and critical/serious axe checks. Phase 15 should add responsive confidence without turning into a visual-regression product.

---

## Secret And PII Leakage Review

| Option | Description | Selected |
|--------|-------------|----------|
| Scanner plus focused redaction tests | Combine docs/template/artifact scanning with redaction-sensitive error tests. | yes |
| Manual review only | Rely on human audit of docs, logs, and artifacts. | |
| Hide diagnostics | Reduce output broadly to avoid leakage risk. | |

**User's choice:** Fallback selected scanner plus focused redaction tests.
**Notes:** This preserves actionable diagnostics while enforcing the Phase 12 and Phase 14 no-secrets direction.

---

## Release-Gate Language

| Option | Description | Selected |
|--------|-------------|----------|
| Required vs advisory labels | Keep deterministic required gates separate from provider-backed advisory checks. | yes |
| Make all trust checks required | Require every possible provider/live check for release. | |
| Leave release docs as-is | Do not update public release guidance after adding trust checks. | |

**User's choice:** Fallback selected required vs advisory labels.
**Notes:** This carries forward the Phase 14 Fake/test/live Stripe positioning and the current advisory live-Stripe workflow.

---

## the agent's Discretion

- Exact artifact filenames and section ordering.
- Exact seeded performance thresholds.
- Exact viewport sizes for responsive coverage.
- Exact scanner implementation.

## Deferred Ideas

- Hosted public demo.
- Tax, revenue/export, additional processor, and organization/multi-tenant billing implementation.
- Making live Stripe a required Accrue release gate.
