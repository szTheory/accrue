# Phase 15: Trust Hardening - Research

**Researched:** 2026-04-17
**Domain:** Trust evidence for security, smoke performance, compatibility, accessibility/responsive behavior, and secret-safe release gates
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- Hosted public demo remains out of scope for v1.2.
- Tax, revenue/export, additional processor, and organization/multi-tenant billing remain Phase 16 discovery topics.
- Making live Stripe required for Accrue release gating is deferred unless provider instability becomes a release-blocking class of bug.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUST-01 | Maintainer has a security review artifact for webhook, auth, admin, replay, and generated-host boundaries. | Add one checked-in trust review document that maps real Accrue boundaries to repo evidence, existing tests, and host-owned assumptions rather than inventing a new security process. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md] |
| TRUST-02 | Maintainer can run seeded performance smoke checks for webhook ingest latency and admin page responsiveness. | Extend `examples/accrue_host` seeded flow and `mix verify.full` contract with compact latency assertions for signed webhook POST and seeded admin routes. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md] |
| TRUST-03 | Maintainer can verify supported Elixir, OTP, Phoenix, and LiveView compatibility at the package or host-app level. | Keep compatibility in `.github/workflows/ci.yml` by extending the existing BEAM matrix and labeling advisory cells explicitly with `continue-on-error`. [VERIFIED: repo files] [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] |
| TRUST-04 | User-facing admin flows used by the demo have accessibility and responsive-browser checks. | Reuse Phase 13 Playwright + axe coverage, add a mobile project for the host demo flow, and keep accessibility assertions focused on critical/serious issues for seeded screens. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/accessibility-testing] [CITED: https://playwright.dev/docs/emulation] |
| TRUST-05 | Public errors, logs, docs, and retained artifacts are reviewed for Stripe secrets, webhook secrets, tokens, and PII leakage. | Build a narrow allowlist/redaction review around existing docs tests, log-safe structs, and artifact upload patterns instead of a generic secret-scanning suite. [VERIFIED: repo files] |
| TRUST-06 | Release-gate docs clearly distinguish required blockers from advisory checks such as live Stripe validation. | Update `RELEASING.md`, `CONTRIBUTING.md`, and CI job labels to keep Fake-backed checks required and Stripe-backed lanes advisory. [VERIFIED: repo files] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Supported floor remains Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, LiveView `1.0+`, PostgreSQL `14+`; Phase 15 should harden evidence around that stack instead of widening support. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory and non-bypassable; raw-body capture must stay ahead of `Plug.Parsers`, and sensitive Stripe fields must never be logged. [VERIFIED: CLAUDE.md]
- The webhook request path budget is `<100ms p99` for verify -> persist -> enqueue -> `200`; any smoke threshold must stay conservative relative to that budget. [VERIFIED: CLAUDE.md]
- Observability expectations already require `:telemetry` on public entry points, so trust checks should reuse those surfaces where helpful. [VERIFIED: CLAUDE.md]
- The monorepo structure and existing root workflows are the right place for compatibility and trust gates; Phase 15 should not create a separate release system. [VERIFIED: CLAUDE.md]
- `workflow.nyquist_validation` is enabled in `.planning/config.json`, so the planner should include test and verification work, not only docs/process artifacts. [VERIFIED: .planning/config.json]

## Summary

Phase 15 should be planned as an evidence phase, not a feature phase. The repo already contains most of the primitives needed for trust hardening: signed webhook ingest tests, admin replay tests, a seeded host walkthrough, existing Playwright traces/screenshots, BEAM compatibility cells, release-lane wording, no-secrets issue intake, and multiple redaction tests around webhook bodies, URLs, setup diagnostics, and telemetry metadata. [VERIFIED: repo files]

The safest plan is to extend those existing proof paths in place. Put the security review in a checked-in artifact, add smoke-level latency measurements to the seeded host harness, widen the host Playwright config from desktop-only to desktop-plus-mobile, tighten release docs around required versus advisory gates, and add cheap leakage checks around docs, logs, and retained artifacts. That stays aligned with the phase decisions to avoid a second matrix system, a benchmark suite, or a generic visual-regression product. [VERIFIED: 15-CONTEXT.md] [VERIFIED: repo files]

Current official guidance reinforces that direction: GitHub Actions matrix jobs already support explicit `continue-on-error`, `fail-fast`, and `max-parallel` handling for advisory cells; Playwright recommends Axe for accessibility testing and device emulation through named projects; and OWASP ASVS 5.0 positions itself as a basis for web-application security verification rather than a marketing certification. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] [CITED: https://playwright.dev/docs/next/accessibility-testing] [CITED: https://playwright.dev/docs/emulation] [CITED: https://owasp.org/www-project-application-security-verification-standard/]

**Primary recommendation:** Extend the existing host verification lane and CI matrix with one checked-in trust review, one seeded smoke metrics path, mobile Playwright coverage, focused leakage scanners, and explicit required-versus-advisory release language. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Security review artifact | Repo docs / planning docs | ExUnit and CI evidence | The artifact itself is documentation, but its value comes from linking to concrete tests, workflows, and host-owned boundaries already in the repo. [VERIFIED: repo files] |
| Webhook ingest smoke latency | Host app test harness | Core webhook pipeline | The measurable path is the seeded host request from signed POST through Accrue ingest and enqueue, not an isolated library benchmark. [VERIFIED: repo files] |
| Admin responsiveness smoke | Playwright host browser flow | LiveView pages in `accrue_admin` | Responsiveness is user-facing page behavior in seeded `/billing` flows, so the browser harness should own the measurement. [VERIFIED: repo files] |
| Compatibility matrix | GitHub Actions workflow | Package test suites / host integration job | The repo already centralizes supported-version proof in `.github/workflows/ci.yml` and the downstream host gate. [VERIFIED: repo files] |
| Accessibility and responsive checks | Playwright projects | Seeded host data | Official Playwright device emulation and the current seeded demo flow are the right place to prove desktop/mobile behavior and Axe scans. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/emulation] [CITED: https://playwright.dev/docs/next/accessibility-testing] |
| Secret / PII leakage review | Docs/tests/scripts | CI artifact upload policy | Leakage risk crosses docs, logs, traces, screenshots, and issue intake, so the phase should combine static checks with artifact-retention rules. [VERIFIED: repo files] |
| Required vs advisory release labeling | `RELEASING.md` and `CONTRIBUTING.md` | CI job names and workflow comments | The release contract is documented in repo runbooks and reinforced by workflow naming and advisory job settings. [VERIFIED: repo files] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit / Mix | Elixir `1.19.5`, Mix `1.19.5` in local env | File-shape tests, host proof tests, and any new smoke assertions | The repo already expresses release gates and docs contracts through ExUnit and Mix aliases, including `mix verify.full` in `examples/accrue_host`. [VERIFIED: local environment] [VERIFIED: repo files] |
| Playwright Test | `1.59.1` published 2026-04-01 | Browser assertions, device projects, failure traces/screenshots | The repo already uses Playwright in both `examples/accrue_host` and `accrue_admin`, and official docs support project-based device emulation and failure-only artifacts. [VERIFIED: npm registry] [VERIFIED: repo files] [CITED: https://playwright.dev/docs/emulation] [CITED: https://playwright.dev/docs/next/test-use-options] |
| `@axe-core/playwright` | `4.11.1` published 2026-02-03 | Accessibility scans inside Playwright tests | Official Playwright accessibility guidance points to Axe integration, and the host demo already uses it for release-blocking checks. [VERIFIED: npm registry] [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/accessibility-testing] |
| GitHub Actions matrix in `.github/workflows/ci.yml` | `actions/checkout@v6`, `actions/setup-node@v6`, `actions/upload-artifact@v7`, `erlef/setup-beam@v1` | Supported-version proof and advisory-cell separation | The workflow already proves floor, primary, forward-compat, and advisory cells, which matches the phase decisions to extend existing CI instead of creating a second compatibility system. [VERIFIED: repo files] [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `scripts/ci/accrue_host_uat.sh` + `examples/accrue_host` `mix verify.full` | Repo-local | Canonical deterministic host gate | Use as the primary entrypoint for any new smoke and browser trust checks so maintainers still run one familiar command. [VERIFIED: repo files] |
| Playwright device projects | `Desktop Chrome`, `Pixel 5` patterns in repo and docs | Responsive desktop/mobile coverage | Use named projects for stable viewport coverage rather than custom per-test viewport hacks. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/emulation] |
| Failure-only traces and screenshots | `trace: "retain-on-failure"`, `screenshot: "only-on-failure"` | Debuggable failures with compact success artifacts | Use for failure artifacts only; keep success artifacts limited to a compact screenshot set that the phase explicitly wants to retain. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/test-use-options] |
| OWASP ASVS 5.0 | Current stable released 2025-05-30 | Security review taxonomy | Use ASVS as a checklist scaffold for the trust review, not as a certification claim. [CITED: https://owasp.org/www-project-application-security-verification-standard/] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending `mix verify.full` | A separate `trust-ci` script or workflow | A second entrypoint would duplicate seeded setup and weaken the canonical proof path already documented in Phase 13. [VERIFIED: repo files] |
| Playwright + Axe | Dedicated visual-regression SaaS | The phase needs behavior, accessibility, and responsive assertions more than pixel baselines, and the repo already has the right harness. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/accessibility-testing] |
| GitHub Actions matrix include cells | Bespoke compatibility runner | GitHub already supports advisory cells and controlled failure behavior, so a custom matrix system adds maintenance without new capability. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] |
| Seeded smoke timings | Benchee or a benchmark suite | The context explicitly calls for deterministic smoke checks rather than benchmark precision, so benchmark tooling is the wrong abstraction here. [VERIFIED: 15-CONTEXT.md] |

**Installation:**
```bash
cd examples/accrue_host && npm ci
cd accrue_admin && npm ci
```

**Version verification:** Current repo/runtime versions verified in this session: Playwright `1.59.1` (npm publish 2026-04-01), `@axe-core/playwright` `4.11.1` (npm publish 2026-02-03), Phoenix `1.8.5` (Hex publish 2026-03-05), LiveView `1.1.28` (Hex publish 2026-03-27), Ecto / `ecto_sql` `3.13.5`, Oban `2.21.1`, `lattice_stripe` `1.1.0`, `chromic_pdf` `1.17.1`, Swoosh `1.25.0`, Telemetry `1.4.1`. [VERIFIED: npm registry] [VERIFIED: npm lockfile] [VERIFIED: Hex.pm API] [VERIFIED: repo files]

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer runs trust gate
        |
        v
examples/accrue_host mix verify.full
        |
        +--> seeded DB + signed webhook fixture
        |         |
        |         v
        |   webhook POST -> verify signature -> persist -> enqueue -> latency summary
        |
        +--> Playwright desktop/mobile projects
        |         |
        |         +--> /billing dashboard -> responsiveness assertions
        |         +--> /billing/webhooks/:id -> replay + accessibility assertions
        |         +--> /billing/events?... -> audit/replay state assertions
        |         +--> compact success screenshots / failure-only traces
        |
        +--> docs / log / artifact scanners
        |
        v
CI workflow
        |
        +--> required floor/target cells
        +--> advisory cells with continue-on-error
        +--> upload failure artifacts only
        |
        v
Checked-in trust review + release docs
```

### Recommended Project Structure

```text
.planning/phases/15-trust-hardening/   # trust review artifact and phase docs
.github/workflows/ci.yml               # compatibility matrix and host gate
scripts/ci/                            # seeded host wrappers and scanners
examples/accrue_host/                  # canonical seeded demo + browser flow
examples/accrue_host/e2e/              # accessibility/responsive walkthrough
examples/accrue_host/test/             # signed webhook and admin replay proofs
accrue/test/accrue/docs/               # release/docs/leakage contract tests
RELEASING.md                           # required vs advisory release wording
CONTRIBUTING.md                        # contributor-facing lane labels
SECURITY.md                            # private vulnerability intake
```

### Pattern 1: Evidence-Centric Security Review
**What:** Write one review document that enumerates real boundaries, links each boundary to repo evidence, and states which parts remain host-owned. [VERIFIED: 15-CONTEXT.md] [VERIFIED: repo files]
**When to use:** For TRUST-01 and release confidence artifacts. [VERIFIED: 15-CONTEXT.md]
**Example:**
```markdown
## Webhook boundary
- Raw body must be captured before JSON parsing. [VERIFIED: repo files]
- Unsigned or tampered payloads must fail before ingest. [VERIFIED: repo files]
- Replay is authorized through admin mount + audit event, not public webhook input. [VERIFIED: repo files]
- Host app still owns session setup, runtime secrets, and route placement. [VERIFIED: repo files]
```

### Pattern 2: Seeded Smoke Measurement Inside The Canonical Host Gate
**What:** Measure latency in the seeded host path itself and emit a compact JSON or plain-text summary. [VERIFIED: 15-CONTEXT.md] [VERIFIED: repo files]
**When to use:** For webhook ingest latency and admin responsiveness smoke checks only. [VERIFIED: 15-CONTEXT.md]
**Example:**
```elixir
start = System.monotonic_time()
conn = post_signed_webhook(payload, signature)
elapsed_ms = System.convert_time_unit(System.monotonic_time() - start, :native, :millisecond)
assert conn.status == 200
assert elapsed_ms <= budget_ms
```

### Pattern 3: Responsive Browser Coverage Through Playwright Projects
**What:** Express desktop and mobile coverage as separate Playwright projects, then run the same seeded flow across both. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/emulation]
**When to use:** For responsive checks in TRUST-04. [VERIFIED: 15-CONTEXT.md]
**Example:**
```javascript
projects: [
  { name: "chromium-desktop", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
  { name: "chromium-mobile", use: { ...devices["Pixel 5"] } }
]
```

### Pattern 4: Accessibility Assertions With Axe In Real Page State
**What:** Run Axe only after the page reaches the seeded state you actually care about. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/accessibility-testing]
**When to use:** For first-run billing, admin dashboard, webhook detail, replay audit, and any new mobile admin surfaces. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md]
**Example:**
```javascript
const results = await new AxeBuilder({ page }).analyze();
const blocking = results.violations.filter((v) => ["critical", "serious"].includes(v.impact || ""));
expect(blocking).toEqual([]);
```

### Anti-Patterns to Avoid

- **Benchmark-suite creep:** Benchee-style benchmarking is the wrong fit because the phase calls for deterministic smoke-level evidence, not statistical performance research. [VERIFIED: 15-CONTEXT.md]
- **Second compatibility system:** Duplicating `.github/workflows/ci.yml` with a separate matrix runner would split the support contract across two sources of truth. [VERIFIED: repo files]
- **Always-on heavy artifacts:** Success-path traces, videos, and full logs increase retention risk and storage cost without adding release signal. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/test-use-options]
- **Accessibility without responsive assertions:** Axe catches only part of the problem; mobile layout regressions still need viewport-specific behavior checks. [CITED: https://playwright.dev/docs/next/accessibility-testing] [CITED: https://playwright.dev/docs/emulation]
- **Treating advisory cells as hard blockers:** `continue-on-error` must stay explicit for advisory jobs, or maintainers will misread support scope. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] [VERIFIED: repo files]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accessibility scanning | Custom DOM rule checks | `@axe-core/playwright` | Playwright explicitly points accessibility testing toward Axe integration, and the repo already uses it successfully. [CITED: https://playwright.dev/docs/next/accessibility-testing] [VERIFIED: repo files] |
| Mobile/desktop emulation | Manual viewport flags sprinkled through tests | Playwright device projects | Named projects give stable device parameters and keep responsive coverage readable. [CITED: https://playwright.dev/docs/emulation] |
| Compatibility orchestration | A bespoke matrix generator | GitHub Actions matrix include cells | GitHub already supports include/exclude, `continue-on-error`, and `max-parallel` for this exact problem. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] |
| Security review taxonomy | An ad hoc checklist with no shared vocabulary | OWASP ASVS sections mapped to Accrue boundaries | ASVS is meant to provide a basis for testing web-application technical security controls and trust level. [CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| Provider-parity gating | Live Stripe as a required release blocker | Existing Fake-first required lane plus advisory Stripe jobs | The repo already documents and enforces Stripe-backed checks as advisory/provider-parity, which matches the phase decisions. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md] |

**Key insight:** Phase 15 should add evidence by tightening existing proof loops, not by introducing new frameworks or a second release lane. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Measuring Setup Noise Instead Of The User Path
**What goes wrong:** A smoke check times DB reset, seed creation, Node install, or server boot instead of the signed webhook request or seeded page load. [VERIFIED: repo files]
**Why it happens:** `mix verify.full` already includes setup steps, so it is easy to measure the whole alias instead of the narrow path named in D-05. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md]
**How to avoid:** Start timing immediately around the webhook POST or browser navigation/assertion segment and emit those timings separately from setup. [VERIFIED: 15-CONTEXT.md]
**Warning signs:** Large timing variance between runs and failures that disappear when dependencies are already warm. [ASSUMED]

### Pitfall 2: Letting Advisory Cells Drift Into Support Commitments
**What goes wrong:** A forward-compat or unpublished optional-dependency cell starts reading like a supported release blocker. [VERIFIED: repo files]
**Why it happens:** Matrix jobs are easy to add, but job names, docs, and `continue-on-error` labels are often left ambiguous. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations]
**How to avoid:** Keep required floor/target cells separate, label advisory cells in both workflow YAML and release docs, and preserve `continue-on-error` only where the support policy says advisory. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md]
**Warning signs:** Release docs say “supported” while workflow YAML says `continue-on-error: true`, or vice versa. [VERIFIED: repo files]

### Pitfall 3: Retaining Too Much Browser Artifact Data
**What goes wrong:** Success-path traces, logs, or screenshots keep more state than the phase needs and expand leakage surface. [VERIFIED: repo files]
**Why it happens:** Playwright makes artifact retention easy, and CI upload steps often get copied without revisiting sensitivity or usefulness. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/test-use-options]
**How to avoid:** Keep failure-only traces/screenshots, upload success screenshots only when they are explicitly part of the trust artifact, and add allowlist checks for retained files. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md]
**Warning signs:** CI uploads entire `test-results` trees on success or screenshots contain realistic user data instead of seeded fixtures. [VERIFIED: repo files]

### Pitfall 4: Accessibility Checks That Ignore Actual LiveView State
**What goes wrong:** Axe runs before the page is hydrated or before the seeded state is visible, producing false confidence. [VERIFIED: repo files]
**Why it happens:** Official guidance notes that scans should happen after the page is in the desired state. [CITED: https://playwright.dev/docs/next/accessibility-testing]
**How to avoid:** Reuse the current “wait for LiveView connection / target screen visible” pattern before each accessibility scan. [VERIFIED: repo files]
**Warning signs:** Intermittent accessibility results or scans that pass even when seeded content failed to render. [VERIFIED: repo files]

## Code Examples

Verified patterns from official sources and the current repo:

### Playwright Failure-Only Artifact Policy
```javascript
// Source: examples/accrue_host/playwright.config.js
use: {
  baseURL,
  trace: "retain-on-failure",
  screenshot: "only-on-failure"
}
```

### Playwright Responsive Projects
```javascript
// Source: examples/accrue_host/playwright.config.js + accrue_admin/playwright.config.js
projects: [
  {
    name: "chromium-desktop",
    use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } }
  },
  {
    name: "chromium-mobile",
    use: { ...devices["Pixel 5"] }
  }
]
```

### Axe In A Seeded Flow
```javascript
// Source: examples/accrue_host/e2e/phase13-canonical-demo.spec.js
const results = await new AxeBuilder({ page }).analyze();
const blocking = results.violations.filter((violation) =>
  ["critical", "serious"].includes(violation.impact || "")
);
expect(blocking).toEqual([]);
```

### Advisory Compatibility Cell
```yaml
# Source: .github/workflows/ci.yml
- elixir: '1.18.0'
  otp: '27.0'
  sigra: 'on'
  opentelemetry: 'off'
  continue-on-error: true
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Playwright `page.accessibility` tree inspection | Axe integration through Playwright | Current docs mark Playwright Accessibility API deprecated; current docs recommend Axe. [CITED: https://playwright.dev/docs/api/class-accessibility] [CITED: https://playwright.dev/docs/next/accessibility-testing] | TRUST-04 should stay on Axe rather than reviving deprecated API paths. |
| Desktop-only host browser walkthrough | Desktop + mobile Playwright projects | Repo already uses desktop+mobile in `accrue_admin`; host demo is currently desktop-only. [VERIFIED: repo files] | Phase 15 should bring host demo coverage up to the same responsive standard without creating a second browser suite. |
| Ambiguous extra compatibility jobs | Matrix cells with explicit `continue-on-error` semantics | Current GitHub Actions docs describe this as the standard way to keep experimental jobs advisory. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations] | Support scope should be encoded in workflow semantics, not only prose. |
| Full artifact retention by default | Failure-only traces/screenshots with compact success artifacts | Current Playwright config docs and repo usage favor failure-only retention for debugging efficiency. [CITED: https://playwright.dev/docs/next/test-use-options] [VERIFIED: repo files] | Phase 15 should preserve small success artifacts and keep the heavier data failure-only. |

**Deprecated/outdated:**
- Playwright Accessibility class for accessibility testing: deprecated in current docs; use Axe integration instead. [CITED: https://playwright.dev/docs/api/class-accessibility] [CITED: https://playwright.dev/docs/next/accessibility-testing]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Smoke timing variance warning will mainly come from warm/cold setup differences. | Common Pitfalls | Low; thresholds may need tuning, but the plan still centers on narrow path timing. [ASSUMED] |

## Open Questions

1. **What exact local budgets should block TRUST-02?**
   - What we know: The project-level webhook path budget is `<100ms p99`, and the context wants conservative smoke thresholds rather than benchmark precision. [VERIFIED: CLAUDE.md] [VERIFIED: 15-CONTEXT.md]
   - What's unclear: The exact deterministic threshold that stays stable on GitHub runners and common maintainer laptops. [VERIFIED: 15-CONTEXT.md]
   - Recommendation: Plan a short calibration task that records seeded timings locally and in CI, then lock a budget with headroom rather than choosing numbers in advance. [VERIFIED: 15-CONTEXT.md]

2. **Should compatibility proof stop at the existing BEAM matrix, or add a host-level LiveView floor cell?**
   - What we know: Public support is Phoenix `1.8+` and LiveView `1.0+`, while the current repo matrix already covers Elixir/OTP cells and host integration on the primary target. [VERIFIED: CLAUDE.md] [VERIFIED: repo files]
   - What's unclear: Whether a separate host cell for the lowest supported LiveView combination is necessary for this phase or better deferred to later support expansion work. [VERIFIED: repo files]
   - Recommendation: Keep Phase 15 focused on one explicit floor/target compatibility story unless a gap appears during implementation. [VERIFIED: 15-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | ExUnit, Mix aliases, host/package gates | ✓ | `1.19.5` | — [VERIFIED: local environment] |
| Mix | All package and host verification commands | ✓ | `1.19.5` | — [VERIFIED: local environment] |
| Node.js | Playwright browser checks | ✓ | `v22.14.0` | — [VERIFIED: local environment] |
| npm / npx | Installing and running Playwright suites | ✓ | `11.1.0` / `11.1.0` | — [VERIFIED: local environment] |
| PostgreSQL | Host and package test databases | ✓ | CLI `14.17`; localhost `5432` accepting connections | Docker service available if local server setup changes. [VERIFIED: local environment] |
| Docker | Optional `act` / containerized workflow replay | ✓ | `29.3.1` | Native local services already work. [VERIFIED: local environment] |
| Playwright package in `examples/accrue_host` | Host browser smoke | ✓ | `1.59.1` | `npm ci` reinstalls it. [VERIFIED: repo files] [VERIFIED: local environment] |
| Browser binary via Homebrew `chromium` | Local browser execution | ✗ | broken wrapper to missing `/Applications/Chromium.app` | Use Playwright-managed browser install via `npm run e2e:install`. [VERIFIED: local environment] |

**Missing dependencies with no fallback:**
- None identified. [VERIFIED: local environment]

**Missing dependencies with fallback:**
- System `chromium` is not usable locally, but Playwright-managed Chromium install is already the repo-standard fallback. [VERIFIED: local environment] [VERIFIED: repo files]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5` plus Playwright Test `1.59.1` with `@axe-core/playwright` `4.11.1`. [VERIFIED: local environment] [VERIFIED: npm registry] [VERIFIED: repo files] |
| Config file | [`examples/accrue_host/playwright.config.js`](/Users/jon/projects/accrue/examples/accrue_host/playwright.config.js), [`accrue_admin/playwright.config.js`](/Users/jon/projects/accrue/accrue_admin/playwright.config.js), Mix aliases in [`examples/accrue_host/mix.exs`](/Users/jon/projects/accrue/examples/accrue_host/mix.exs). [VERIFIED: repo files] |
| Quick run command | `cd examples/accrue_host && mix verify.full` for the canonical host lane; `cd examples/accrue_host && npm run e2e` for browser-only iteration. [VERIFIED: repo files] |
| Full suite command | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors && cd ../examples/accrue_host && mix verify.full`. [VERIFIED: repo files] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRUST-01 | Security review artifact exists and maps webhook/auth/admin/replay/generated-host boundaries to real evidence. | docs contract | `cd accrue && mix test test/accrue/docs/trust_review_test.exs -x` | ❌ Wave 0 [VERIFIED: repo files] |
| TRUST-02 | Seeded webhook ingest and admin responsiveness stay within documented smoke budgets. | integration / smoke | `cd examples/accrue_host && mix test test/accrue_host_web/trust_smoke_test.exs -x` or equivalent seeded script command | ❌ Wave 0 [VERIFIED: repo files] |
| TRUST-03 | Supported floor/target combinations are exercised, and advisory cells stay labeled. | CI matrix | `.github/workflows/ci.yml` release-gate + host-integration job | ✅ existing workflow, likely needs edits [VERIFIED: repo files] |
| TRUST-04 | Demo/admin flows pass desktop/mobile behavior checks and critical/serious Axe scans. | browser e2e | `cd examples/accrue_host && npm run e2e` | ✅ existing host suite, needs mobile extension [VERIFIED: repo files] |
| TRUST-05 | Docs, logs, public errors, and retained artifacts are scanned for secrets/PII leakage. | docs/log contract | `cd accrue && mix test test/accrue/docs/trust_leakage_test.exs -x` plus targeted script checks | ❌ Wave 0 [VERIFIED: repo files] |
| TRUST-06 | Release docs and workflow labels distinguish required blockers from advisory checks. | docs contract | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs -x` and `bash scripts/ci/verify_package_docs.sh` | ✅ existing release docs test likely needs expansion [VERIFIED: repo files] |

### Sampling Rate
- **Per task commit:** Run the narrow command for the touched surface, usually `cd accrue && mix test <file> -x`, `cd examples/accrue_host && mix test <file> -x`, or `cd examples/accrue_host && npm run e2e -- --project=<project>`. [VERIFIED: repo files]
- **Per wave merge:** Run `cd examples/accrue_host && mix verify.full` plus any touched package docs tests. [VERIFIED: repo files]
- **Phase gate:** Required CI floor/target cells green, host trust lane green, advisory cells clearly non-blocking, and trust artifacts/doc tests committed before `/gsd-verify-work`. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md]

### Wave 0 Gaps
- [ ] `accrue/test/accrue/docs/trust_review_test.exs` — covers TRUST-01. [VERIFIED: repo files]
- [ ] `examples/accrue_host/test/accrue_host_web/trust_smoke_test.exs` or equivalent scripted contract test — covers TRUST-02. [VERIFIED: repo files]
- [ ] Host Playwright mobile project in [`examples/accrue_host/playwright.config.js`](/Users/jon/projects/accrue/examples/accrue_host/playwright.config.js) — covers TRUST-04. [VERIFIED: repo files]
- [ ] Leakage contract tests for docs/artifacts/log-safe copy — covers TRUST-05. [VERIFIED: repo files]
- [ ] Release-guidance contract expansion if current `release_guidance_test.exs` does not cover new required trust gates — covers TRUST-06. [VERIFIED: repo files]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep admin/browser access tied to host-owned auth boundary and document `Accrue.Auth` / mounted session assumptions explicitly. [VERIFIED: repo files] |
| V3 Session Management | yes | Keep `/billing` inside the authenticated browser scope and treat session setup as host-owned in the trust review. [VERIFIED: repo files] |
| V4 Access Control | yes | Replay and admin inspection stay behind billing-admin authorization and emit audit events. [VERIFIED: repo files] |
| V5 Input Validation | yes | Signed webhook verification, raw-body ordering, and refusal of tampered payloads are already proven by tests and should anchor TRUST-01. [VERIFIED: repo files] |
| V6 Cryptography | yes | Use Stripe signature verification and existing secret-handling boundaries; never hand-roll crypto in Phase 15. [VERIFIED: CLAUDE.md] [VERIFIED: repo files] |

### Known Threat Patterns for Accrue's stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsigned or tampered webhook ingest | Tampering | Raw-body capture before parsing plus signature verification tests and host docs that keep secrets in runtime config only. [VERIFIED: repo files] [VERIFIED: CLAUDE.md] |
| Admin replay without authorization | Elevation of Privilege | Mount `accrue_admin` inside authenticated browser scope and verify replay through admin-only flows with audit events. [VERIFIED: repo files] |
| Secret/PII leakage through docs, issue intake, or artifacts | Information Disclosure | No-secrets issue templates, redacted structs/diagnostics, and failure-only artifact retention. [VERIFIED: repo files] |
| Generated-host boundary confusion | Spoofing / Tampering | Security review must state clearly which surfaces are host-owned after install and which are package-owned. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md] |
| Advisory CI lane misread as support contract | Repudiation / Process risk | Use explicit workflow labels and release-doc language for required vs advisory cells. [VERIFIED: repo files] [VERIFIED: 15-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- Repo files inspected in this session: [`CLAUDE.md`](/Users/jon/projects/accrue/CLAUDE.md), [`RELEASING.md`](/Users/jon/projects/accrue/RELEASING.md), [`CONTRIBUTING.md`](/Users/jon/projects/accrue/CONTRIBUTING.md), [`SECURITY.md`](/Users/jon/projects/accrue/SECURITY.md), [`examples/accrue_host/mix.exs`](/Users/jon/projects/accrue/examples/accrue_host/mix.exs), [`examples/accrue_host/e2e/phase13-canonical-demo.spec.js`](/Users/jon/projects/accrue/examples/accrue_host/e2e/phase13-canonical-demo.spec.js), [`examples/accrue_host/playwright.config.js`](/Users/jon/projects/accrue/examples/accrue_host/playwright.config.js), [`accrue_admin/playwright.config.js`](/Users/jon/projects/accrue/accrue_admin/playwright.config.js), [`accrue_admin/e2e/phase7-uat.spec.js`](/Users/jon/projects/accrue/accrue_admin/e2e/phase7-uat.spec.js), [`scripts/ci/accrue_host_uat.sh`](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh), [`scripts/ci/accrue_host_seed_e2e.exs`](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs), [`scripts/ci/accrue_host_browser_smoke.cjs`](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs), [`.github/workflows/ci.yml`](/Users/jon/projects/accrue/.github/workflows/ci.yml), [`.github/workflows/accrue_admin_browser.yml`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml), and the relevant webhook/admin/redaction tests. [VERIFIED: repo files]
- Hex.pm package API for Phoenix, LiveView, Ecto, Ecto SQL, Oban, Telemetry, ChromicPDF, LatticeStripe, and Swoosh current versions and release timestamps. [VERIFIED: Hex.pm API]
- NPM registry for Playwright and `@axe-core/playwright` current versions and publish timestamps. [VERIFIED: npm registry]
- GitHub Actions matrix docs: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations]
- Playwright docs: https://playwright.dev/docs/next/accessibility-testing, https://playwright.dev/docs/emulation, https://playwright.dev/docs/next/test-use-options, https://playwright.dev/docs/api/class-accessibility [CITED: https://playwright.dev/docs/next/accessibility-testing] [CITED: https://playwright.dev/docs/emulation] [CITED: https://playwright.dev/docs/next/test-use-options] [CITED: https://playwright.dev/docs/api/class-accessibility]
- OWASP ASVS project page: https://owasp.org/www-project-application-security-verification-standard/ [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Secondary (MEDIUM confidence)
- None. Primary sources were sufficient. [VERIFIED: research session]

### Tertiary (LOW confidence)
- None beyond the single explicit assumption logged above. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The repo already uses the recommended tools, and current versions were verified against Hex.pm and npm. [VERIFIED: repo files] [VERIFIED: Hex.pm API] [VERIFIED: npm registry]
- Architecture: HIGH - The phase decisions line up tightly with existing host/browser/CI structure, so the planning recommendation is an extension path rather than a speculative redesign. [VERIFIED: 15-CONTEXT.md] [VERIFIED: repo files]
- Pitfalls: MEDIUM - Most are grounded in current repo behavior and official docs, but the exact smoke-threshold behavior still needs implementation calibration. [VERIFIED: repo files] [CITED: https://playwright.dev/docs/next/accessibility-testing]

**Research date:** 2026-04-17
**Valid until:** 2026-05-01 for tool/version details; repo-structure findings remain valid until the next trust-gate refactor. [VERIFIED: research session]
