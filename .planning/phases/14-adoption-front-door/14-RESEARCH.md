# Phase 14: Adoption Front Door - Research

**Researched:** 2026-04-16
**Domain:** OSS adoption surfaces, package docs alignment, GitHub issue intake, release/support guidance
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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
- Exact drift-check implementation and placement, as long as canonical owner boundaries and public contract wording stay enforced.
- Exact release-guidance wording and table shape, as long as required vs provider-parity vs advisory/manual labels are unambiguous.

### Deferred Ideas (OUT OF SCOPE)

- Hosted public demo remains out of scope for v1.2 unless a future milestone explicitly adds it.
- Phase 15 trust hardening should decide whether and how to make security/performance/accessibility/compatibility evidence more prominent in the adoption front door.
- Expansion-feature positioning for tax, revenue/export, additional processors, and org billing belongs to Phase 16 discovery, not Phase 14 marketing copy.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | Root repository README explains Accrue, the two packages, the local demo, docs, and production-hardening path. | Root README should be a route map that points to `examples/accrue_host`, `accrue/guides/first_hour.md`, package READMEs, `RELEASING.md`, and `SECURITY.md`. [VERIFIED: repo files] |
| ADOPT-02 | Tutorial path already exists from install through first subscription, webhook ingest, admin inspection/replay, and focused host tests. | Keep tutorial ownership in `examples/accrue_host/README.md` and `accrue/guides/first_hour.md`; Phase 14 aligns entry surfaces to them rather than rewriting them. [VERIFIED: repo files] |
| ADOPT-03 | Users can choose Fake, Stripe test mode, and live Stripe through clear docs/release guidance. | Use three explicit labels: `canonical local demo`, `provider-parity checks`, and `advisory/manual before shipping`. [VERIFIED: repo files] [CITED: https://docs.stripe.com/testing-use-cases] [CITED: https://docs.stripe.com/webhooks] |
| ADOPT-04 | Users can find issue templates for bug reports, integration problems, documentation gaps, and feature requests. | Implement four YAML issue forms plus `.github/ISSUE_TEMPLATE/config.yml` with `blank_issues_enabled: false` and `contact_links`. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| ADOPT-05 | Users can identify supported public APIs and generated host-owned boundaries. | Repeat the public surface contract across root README, package README, First Hour, and release/upgrade surfaces; avoid private module examples. [VERIFIED: repo files] |
| ADOPT-06 | User-facing docs preserve Accrue’s brand voice and avoid unsupported claims. | Reuse the existing “Billing state, modeled clearly.” voice and keep proof near the top; defer trust-heavy claims to Phase 15. [VERIFIED: repo files] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- The repo is a sibling-package monorepo with `accrue/` and `accrue_admin/`; phase work should preserve shared docs/workflow ownership at the repo root. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory, raw-body setup must remain documented, and sensitive Stripe fields must never be logged or encouraged in docs/issues. [VERIFIED: CLAUDE.md]
- Secrets belong in runtime env vars or CI secret stores, not in source-controlled docs, workflows, issues, or logs. [VERIFIED: CLAUDE.md]
- Follow the established tag line and positioning: Accrue is an OSS Elixir/Phoenix billing library, not a broad processor platform. [VERIFIED: CLAUDE.md]
- `nyquist_validation` is enabled in `.planning/config.json`, so planning should include test additions for README/support-surface drift. [VERIFIED: .planning/config.json]

## Summary

Phase 14 should be planned as a documentation-routing and support-intake phase, not as a product or architecture phase. The repo already has the canonical tutorial (`examples/accrue_host/README.md` plus `accrue/guides/first_hour.md`), package landing pages, release runbook, security policy, and docs-drift tests. The missing pieces are the repo-level front door, GitHub issue intake, explicit Fake/test/live labeling across public docs, and a small extension of the existing verifier/test spine to catch drift across those new surfaces. [VERIFIED: repo files]

The root repository currently has no `README.md`, while package docs already encode the host-first model, public API contract, and verification labels. That means the safest plan is to add one concise root route-map, tighten `accrue/README.md` wording around the same path, keep `accrue_admin/README.md` admin-specific, and extend docs verification to cover the new root/support files. [VERIFIED: repo files]

GitHub’s current issue-form docs support YAML issue forms in `.github/ISSUE_TEMPLATE`, chooser configuration through `config.yml`, `blank_issues_enabled: false`, and `contact_links`. Stripe’s current docs still require per-endpoint webhook secrets and the raw, unmodified request body for signature verification, while its broader testing docs now distinguish live mode from testing environments and recommend keeping secrets out of source. Those official constraints fit the phase decisions exactly. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] [CITED: https://docs.stripe.com/webhooks] [CITED: https://docs.stripe.com/testing-use-cases]

**Primary recommendation:** Add a root `README.md`, four GitHub issue forms plus chooser config, and a verifier extension that treats README/support copy as enforceable contract alongside the existing package-docs tests. [VERIFIED: repo files]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Root adoption front door | Repo docs | GitHub UI | The repo root README is the first entry point and must route users to the canonical tutorial and support surfaces. [VERIFIED: repo files] |
| Package landing pages | Package docs | HexDocs output | `accrue/README.md` and `accrue_admin/README.md` already feed package-facing docs and should stay package-scoped. [VERIFIED: repo files] |
| Local demo tutorial | Example app docs | Package guide | `examples/accrue_host/README.md` owns clone-to-run evaluation; `accrue/guides/first_hour.md` mirrors it for package consumers. [VERIFIED: repo files] |
| Issue intake | GitHub issue forms | SECURITY.md / CONTRIBUTING.md | GitHub issue forms handle public triage, while security/private reports must be routed away from public issues. [VERIFIED: repo files] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] |
| Release guidance | `RELEASING.md` | `guides/testing-live-stripe.md` / CI workflows | Required vs advisory language belongs in the release runbook, with provider-parity detail linked out. [VERIFIED: repo files] |
| Docs drift enforcement | ExUnit + shell verifier | GitHub Actions CI | The repo already uses ExUnit and `scripts/ci/verify_package_docs.sh` for docs invariants, so this phase should extend that pattern. [VERIFIED: repo files] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GitHub issue forms | Platform feature, current docs as of 2026-04-16 | Public issue intake in `.github/ISSUE_TEMPLATE/*.yml` | GitHub officially supports chooser config, labels, assignees, issue type, and form inputs without adding repo dependencies. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| ExUnit via Elixir | Elixir 1.19.5 / Mix 1.19.5 in local env | Docs-contract tests | Existing docs verification already lives in ExUnit under `accrue/test/accrue/docs/`. [VERIFIED: local environment] [VERIFIED: repo files] |
| Bash verifier script | GNU bash 5.2.37 | Fixed-string docs parity checks | `scripts/ci/verify_package_docs.sh` already guards package README/guide invariants with low overhead. [VERIFIED: local environment] [VERIFIED: repo files] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `rg` | 15.1.0 | Fast text/file drift checks during implementation and CI scripts | Use for simple presence/absence checks or release/docs greps. [VERIFIED: local environment] |
| GitHub Actions workflows | Repo-local YAML | CI surface for docs/release wording alignment | Use when a support or release contract needs enforcement in CI. [VERIFIED: repo files] |
| Existing Accrue docs tests | Repo-local | Public boundary and tutorial-order verification | Reuse for root README/public-surface assertions instead of starting a new docs framework. [VERIFIED: repo files] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GitHub issue forms | Markdown templates | YAML forms give structured fields, default labels, and chooser config; Markdown is looser and weaker for no-secrets prompts. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| Extending docs verifier | Full docs generation pipeline | The repo already has narrow ExUnit and shell checks, so a generation system would be extra surface with little payoff for this phase. [VERIFIED: repo files] |
| Root README route map | Full duplicate tutorial | The tutorial already exists and is tested; duplication would create drift immediately. [VERIFIED: repo files] |

**Installation:**
```bash
# No new package dependencies are required for Phase 14.
```

**Version verification:** No new Hex/NPM dependency is required by this phase; the relevant execution tools already exist locally (`elixir`, `mix`, `bash`, `npm`, `rg`, `git`). [VERIFIED: local environment]

## Architecture Patterns

### System Architecture Diagram

```text
GitHub / Hex / Repo visitor
        |
        v
    root README
        |
        +--> examples/accrue_host/README.md  --> local Fake-backed evaluation
        |
        +--> accrue/guides/first_hour.md     --> package-facing integration tutorial
        |
        +--> accrue/README.md                --> core package landing + public API boundary
        |
        +--> accrue_admin/README.md          --> admin-specific mount/auth/assets docs
        |
        +--> CONTRIBUTING.md / SECURITY.md   --> contribution and private-security routing
        |
        +--> RELEASING.md / guides/testing-live-stripe.md --> required vs parity vs advisory checks

Maintainer edits docs/support files
        |
        v
ExUnit docs tests + verify_package_docs.sh
        |
        v
CI / release gate catches drift before publish
```

### Recommended Project Structure

```text
README.md                          # Root adoption front door
.github/ISSUE_TEMPLATE/            # Four YAML forms + config.yml chooser
accrue/README.md                   # Compact package landing page
accrue/guides/                     # Canonical package-facing tutorial and references
accrue_admin/README.md             # Admin-specific landing page
examples/accrue_host/README.md     # Executable local demo path
scripts/ci/verify_package_docs.sh  # Lightweight docs drift verifier
accrue/test/accrue/docs/           # Docs/public-surface contract tests
RELEASING.md                       # Release gate language
SECURITY.md                        # Private vulnerability route
CONTRIBUTING.md                    # Contributor/support entry
```

### Pattern 1: Root README As Route Map
**What:** A short root README that answers identity, package map, first path, stable boundaries, and support mode labels without duplicating setup. [VERIFIED: repo files]
**When to use:** For repo-level orientation only. Send all executable steps to the owning docs. [VERIFIED: repo files]
**Example:**
```markdown
# Accrue

Billing state, modeled clearly.

- Start locally: `examples/accrue_host/README.md`
- Integrate into your app: `accrue/guides/first_hour.md`
- Stable public surfaces: `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, `Accrue.ConfigError`
- Validation modes: Fake = canonical local demo; Stripe test mode = provider parity; live Stripe = advisory/manual
```

### Pattern 2: Issue Forms As Triage Router
**What:** Four focused YAML issue forms plus chooser config with blank issues disabled and security/private contact links. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository]
**When to use:** For any public support intake in this repo. [VERIFIED: repo files]
**Example:**
```yaml
name: Integration problem
description: Report a first-time setup or public-boundary integration blocker.
title: "[Integration]: "
labels: ["integration", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Do not paste API keys, webhook secrets, production payloads, or customer data.
  - type: textarea
    id: what_happened
    attributes:
      label: What happened?
    validations:
      required: true
```

### Pattern 3: Drift Checks On Public Contract Copy
**What:** Reuse ExUnit plus the existing shell verifier to assert route-map links, command labels, public-boundary phrases, and Fake/test/live wording. [VERIFIED: repo files]
**When to use:** Whenever README/support copy becomes part of the stable adoption contract. [VERIFIED: repo files]
**Example:**
```bash
grep -Fq "examples/accrue_host/README.md" README.md
grep -Fq "Fake" README.md
grep -Fq "provider-parity" RELEASING.md
grep -Fq "advisory/manual" RELEASING.md
```

### Anti-Patterns to Avoid

- **Root README as second tutorial:** This duplicates `examples/accrue_host/README.md` and `accrue/guides/first_hour.md`, creating immediate drift. [VERIFIED: repo files]
- **Admin-first onboarding:** `accrue_admin` is an integration detail after core billing/webhook setup, not the main front door. [VERIFIED: repo files]
- **Generic support issue template:** The phase decisions explicitly reject a catch-all support form. [VERIFIED: 14-CONTEXT.md]
- **Secret-bearing prompts:** Public issues must not solicit Stripe keys, webhook secrets, production payloads, or customer PII. [VERIFIED: SECURITY.md] [CITED: https://docs.stripe.com/testing-use-cases]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public issue intake | Custom support workflow or generic Markdown issue | GitHub YAML issue forms + `config.yml` chooser | GitHub already supports structured forms, labels, and contact links. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| Docs contract enforcement | New docs linter framework | Existing ExUnit docs tests + `scripts/ci/verify_package_docs.sh` | The repo already has working patterns for this exact kind of drift check. [VERIFIED: repo files] |
| Public API teaching examples | Private schema/module walkthroughs | Generated host facade and public macros/helpers | Existing docs tests explicitly forbid private-module examples in first-user docs. [VERIFIED: repo files] |

**Key insight:** Phase 14 should increase precision, not surface area. Every new public sentence should either route to an existing owner doc or be enforced by an existing-style test. [VERIFIED: repo files]

## Common Pitfalls

### Pitfall 1: Root README duplicates First Hour
**What goes wrong:** The root README starts carrying install commands, route snippets, and troubleshooting detail that already live elsewhere. [VERIFIED: repo files]
**Why it happens:** README authors try to make the front door “complete” instead of navigational. [ASSUMED]
**How to avoid:** Limit the root README to identity, package map, stable boundaries, proof strip, and clear route links. [VERIFIED: 14-CONTEXT.md]
**Warning signs:** The same shell commands appear in three places and only two are under test. [VERIFIED: repo files]

### Pitfall 2: Fake/test/live language blurs release expectations
**What goes wrong:** Maintainers or users infer that Stripe test mode or live Stripe is required for every clone, CI run, or release. [VERIFIED: repo files]
**Why it happens:** Release docs and testing docs describe multiple lanes without explicit labels. [VERIFIED: repo files]
**How to avoid:** Put the same three labels in root README, package README, `RELEASING.md`, and live-Stripe guide. [VERIFIED: repo files]
**Warning signs:** “required” and “advisory” are not present near provider-backed commands. [VERIFIED: repo files]

### Pitfall 3: Issue forms collect unsafe data
**What goes wrong:** Public issues include secrets, webhook payloads, or customer data. [VERIFIED: SECURITY.md]
**Why it happens:** Templates ask for “full config,” “full payload,” or screenshot uploads without redaction guidance. [ASSUMED]
**How to avoid:** Put a no-secrets markdown notice at the top of every form and ask for sanitized config snippets, reproducible steps, and public-surface references only. [VERIFIED: SECURITY.md] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms]
**Warning signs:** Fields ask for raw logs, full webhook bodies, or secrets by name. [VERIFIED: SECURITY.md]

### Pitfall 4: Drift checks miss repo-root and support surfaces
**What goes wrong:** Package docs stay aligned, but the root README, issue templates, or release guidance diverge. [VERIFIED: repo files]
**Why it happens:** Existing verifier coverage is package-oriented today. [VERIFIED: repo files]
**How to avoid:** Extend the current script/tests to include root README and support-surface assertions. [VERIFIED: repo files]
**Warning signs:** CI only references `accrue/README.md`, `accrue_admin/README.md`, and guide files. [VERIFIED: repo files]

## Code Examples

Verified patterns from official sources and the repo:

### GitHub chooser config
```yaml
blank_issues_enabled: false
contact_links:
  - name: Security vulnerability
    url: https://github.com/szTheory/accrue/security/advisories/new
    about: Report vulnerabilities privately. Do not open a public issue.
```
Source: [GitHub Docs](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository). [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository]

### Existing docs verifier entry point
```bash
bash scripts/ci/verify_package_docs.sh
```
Source: repo script and test. [VERIFIED: repo files]

### Public webhook boundary in docs
```elixir
defmodule MyApp.BillingHandler do
  use Accrue.Webhook.Handler

  @impl Accrue.Webhook.Handler
  def handle_event(type, event, ctx) do
    MyApp.Billing.handle_webhook(type, event, ctx)
  end
end
```
Source: repo docs and public behaviour. [VERIFIED: repo files]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Markdown issue templates only | GitHub YAML issue forms with chooser config, top-level metadata, and typed body inputs | Current GitHub docs still document YAML forms as the structured path; issue forms remain public preview. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] | Accrue should use YAML forms for the four-form taxonomy and contact routing. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| Stripe “test mode only” framing | Stripe now distinguishes test mode and Sandboxes as testing environments, while live mode remains separate. [CITED: https://docs.stripe.com/testing-use-cases] | Present in current Stripe docs on 2026-04-16. [CITED: https://docs.stripe.com/testing-use-cases] | Accrue can keep its locked Fake/test/live copy for this phase, but should avoid claiming Stripe test mode is the only Stripe-side testing environment. [ASSUMED] |

**Deprecated/outdated:**
- Relying on a root `issue_template.md` plus enabled blank issues is weaker than chooser-based YAML forms for this phase. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The most maintainable root README is shorter than the current package README and should remain mostly navigational. | Common Pitfalls / Summary | Low; this affects shape and scope, not correctness. |
| A2 | Asking for “full config” or “full logs” is the main path by which issue templates would encourage unsafe disclosures. | Common Pitfalls | Medium; wording might need adjustment if the project wants stricter or looser intake. |
| A3 | Accrue should avoid surfacing Stripe Sandboxes in Phase 14 copy even though Stripe now documents them, because the locked decisions emphasize Fake, Stripe test mode, and live Stripe. | State of the Art | Low; this is mainly a scoping choice. |

## Open Questions

1. **Should the root README link directly to GitHub security-advisory creation, or only to `SECURITY.md`?**
   - What we know: GitHub chooser `contact_links` can send users to an external/private URL, and `SECURITY.md` already defines the private route. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] [VERIFIED: SECURITY.md]
   - What's unclear: Whether the repo has security-advisory UI enabled and stable for all maintainers. [ASSUMED]
   - Recommendation: Link issue-template contact routing to `SECURITY.md` unless advisory-creation URL access is verified during implementation. [VERIFIED: SECURITY.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` / `mix` | ExUnit docs tests | ✓ | Elixir 1.19.5 / Mix 1.19.5 | — |
| `bash` | `verify_package_docs.sh` | ✓ | 5.2.37 | — |
| `git` | Repo/CI workflows and local verification | ✓ | 2.41.0 | — |
| `rg` | Fast local/search-based drift checks | ✓ | 15.1.0 | `grep` |
| `npm` | Existing workflow tooling only; not required for Phase 14 docs edits | ✓ | 11.1.0 | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Elixir 1.19.5 / Mix 1.19.5 [VERIFIED: local environment] |
| Config file | none; standard Mix/ExUnit project layout [VERIFIED: repo files] |
| Quick run command | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/first_hour_guide_test.exs` [VERIFIED: repo files] |
| Full suite command | `cd accrue && mix test --warnings-as-errors` [VERIFIED: accrue/mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-01 | Root README routes to demo, package docs, admin package, support, and hardening docs | unit/docs contract | `cd accrue && mix test test/accrue/docs/root_readme_test.exs` | ❌ Wave 0 |
| ADOPT-02 | Existing tutorial ownership stays canonical | unit/docs contract | `cd accrue && mix test test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/first_hour_guide_test.exs` | ✅ |
| ADOPT-03 | Fake vs test vs live labels stay explicit across docs/release guidance | unit/docs contract + shell verifier | `cd accrue && mix test test/accrue/docs/root_readme_test.exs test/accrue/docs/release_guidance_test.exs` | ❌ Wave 0 |
| ADOPT-04 | Four issue forms and chooser config exist with blank issues disabled | unit/file-shape test | `cd accrue && mix test test/accrue/docs/issue_templates_test.exs` | ❌ Wave 0 |
| ADOPT-05 | Public API boundary wording stays on supported surfaces | unit/docs contract | `cd accrue && mix test test/accrue/docs/root_readme_test.exs test/accrue/docs/first_hour_guide_test.exs` | ❌ / ✅ mixed |
| ADOPT-06 | Brand voice avoids unsupported maturity claims | unit/docs content test | `cd accrue && mix test test/accrue/docs/root_readme_test.exs test/accrue/docs/release_guidance_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/canonical_demo_contract_test.exs`
- **Per wave merge:** `cd accrue && mix test --warnings-as-errors`
- **Phase gate:** Full suite green plus a grep/smoke check that `.github/ISSUE_TEMPLATE/config.yml` disables blank issues. [VERIFIED: repo files] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/docs/root_readme_test.exs` — covers ADOPT-01, ADOPT-03, ADOPT-05, ADOPT-06
- [ ] `accrue/test/accrue/docs/issue_templates_test.exs` — covers ADOPT-04 and no-secrets intake rules
- [ ] `accrue/test/accrue/docs/release_guidance_test.exs` — covers ADOPT-03 and required/advisory wording in `RELEASING.md` / `guides/testing-live-stripe.md`
- [ ] Extend `scripts/ci/verify_package_docs.sh` — add root README and release-guidance invariants

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Docs must point to host-owned auth boundary rather than inventing auth flows. [VERIFIED: repo files] |
| V3 Session Management | no | Same as above; admin README should reference host session forwarding only. [VERIFIED: repo files] |
| V4 Access Control | yes | Keep `accrue_admin` framed as mounted behind host auth/admin policy. [VERIFIED: repo files] |
| V5 Input Validation | yes | GitHub forms should restrict prompts to sanitized, bounded text and avoid secret-bearing requests. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] [VERIFIED: SECURITY.md] |
| V6 Cryptography | yes | Docs must keep webhook signature verification and per-endpoint secrets explicit; never hand-roll alternatives. [VERIFIED: CLAUDE.md] [CITED: https://docs.stripe.com/webhooks] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secrets pasted into public issues | Information Disclosure | Top-of-form warning, no generic support form, private security contact links, and no request for keys/secrets/payload dumps. [VERIFIED: SECURITY.md] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] |
| Users bypass raw-body verification guidance | Spoofing / Tampering | Keep `/webhooks/stripe` raw-body + signature-verification guidance in first-user docs and support templates. [VERIFIED: repo files] [CITED: https://docs.stripe.com/webhooks] |
| Public docs imply private modules are stable APIs | Tampering / Repudiation | Repeat the public-boundary contract and keep private modules out of examples. [VERIFIED: repo files] |
| Release docs imply advisory provider checks are mandatory | Denial of Service (process) | Label required vs provider-parity vs advisory/manual explicitly in release docs. [VERIFIED: repo files] |

## Sources

### Primary (HIGH confidence)

- Repo files inspected on 2026-04-16: `accrue/README.md`, `accrue_admin/README.md`, `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/testing.md`, `accrue/guides/webhooks.md`, `accrue/guides/troubleshooting.md`, `accrue/guides/upgrade.md`, `guides/testing-live-stripe.md`, `RELEASING.md`, `SECURITY.md`, `CONTRIBUTING.md`, `.github/workflows/ci.yml`, `.github/workflows/accrue_host_uat.yml`, `scripts/ci/verify_package_docs.sh`, and docs tests under `accrue/test/accrue/docs/`. [VERIFIED: repo files]
- GitHub Docs: configuring issue templates and issue-form syntax.  
  - https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository  
  - https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms
- Stripe Docs: testing environments and webhook verification.  
  - https://docs.stripe.com/testing-use-cases  
  - https://docs.stripe.com/webhooks

### Secondary (MEDIUM confidence)

- None. [VERIFIED: research session]

### Tertiary (LOW confidence)

- None beyond the assumptions explicitly logged above. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - This phase needs no new dependencies and reuses verified repo tooling plus official GitHub/Stripe docs.
- Architecture: HIGH - The owning docs and support surfaces are already present in the repo; the missing pieces are additive and constrained.
- Pitfalls: HIGH - Most pitfalls are directly visible from existing docs/tests/security policy and supported by official platform docs.

**Research date:** 2026-04-16
**Valid until:** 2026-05-16
