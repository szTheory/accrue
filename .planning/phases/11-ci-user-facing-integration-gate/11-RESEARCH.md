# Phase 11: CI User-Facing Integration Gate - Research

**Researched:** 2026-04-16
**Domain:** GitHub Actions release gating, Phoenix host-app CI, Playwright failure artifacts
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

No phase-specific `11-CONTEXT.md` exists yet. Planning is constrained by Phase 11 in [`ROADMAP.md`](/Users/jon/projects/accrue/.planning/ROADMAP.md), the milestone requirements in [`REQUIREMENTS.md`](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md), and the completed Phase 10 host-app harness artifacts. [VERIFIED: repo grep]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CI-01 | GitHub Actions runs the host app setup and integration suite on pull requests and pushes to `main`. | Put the host job inside the main ordered release gate instead of relying on the current separate `accrue_host_uat.yml` workflow. GitHub Actions `needs` supports explicit job ordering. [VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |
| CI-02 | CI fails on host-app compile warnings, test failures, browser failures, docs-link drift, and generated artifact drift. | Keep package docs builds and warning-clean compiles in `ci.yml`, and add host generated-drift plus browser failure reporting to the same blocking workflow. [VERIFIED: repo grep] |
| CI-03 | CI exercises both package-local tests and host-app user-facing flows in a clear release-gate order. | Use sequential jobs: package gate -> drift/docs gate -> host integration gate -> annotation sweep. `needs` gives the failure ordering the roadmap asks for. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax][VERIFIED: repo grep] |
| CI-04 | CI publishes useful artifacts for failed host-app browser runs, including screenshots or traces where practical. | Replace the current custom host browser smoke script with Playwright Test so CI can retain HTML reports, traces, and screenshots on failure. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/ci-intro][CITED: https://playwright.dev/docs/api/class-testoptions] |
| CI-05 | CI keeps live Stripe checks opt-in/advisory while making Fake-backed user-facing flows mandatory. | The existing `live-stripe` job already runs only on `workflow_dispatch` and `schedule` with `continue-on-error: true`; keep that model and make the Fake-backed host gate mandatory in `ci.yml`. [VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |
| CI-06 | CI annotation sweeps remain warning/error blockers for release-facing jobs. | Preserve current warning-as-error surfaces and add a final sweep job only if release-facing jobs can still emit warning/error annotations without failing directly. GitHub exposes workflow jobs and check-run annotations through the REST API. [VERIFIED: repo grep][CITED: https://docs.github.com/en/rest/actions/workflow-jobs][CITED: https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28] |
</phase_requirements>

## Summary

Phase 11 is not starting from zero. The repo already has three important building blocks: a strict package release gate in [`ci.yml`](/Users/jon/projects/accrue/.github/workflows/ci.yml), a host-app proof harness in [`scripts/ci/accrue_host_uat.sh`](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh), and a proven Playwright artifact pattern in [`accrue_admin_browser.yml`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml) plus [`playwright.config.js`](/Users/jon/projects/accrue/accrue_admin/playwright.config.js). [VERIFIED: repo grep]

The main planning decision is orchestration. Right now the release-facing checks are split across multiple workflows, and the host browser path still uses a custom Node smoke script instead of Playwright Test. That is enough for local proof, but it does not give the ordered gate, failure-layer isolation, or first-class traces/screenshots the roadmap now requires. [VERIFIED: repo grep]

**Primary recommendation:** Fold the mandatory host-app gate into the main `ci.yml` workflow as a downstream blocking job, keep live Stripe advisory, and promote the host browser path from `scripts/ci/accrue_host_browser_smoke.cjs` to Playwright Test with failure artifact upload. [VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax][CITED: https://playwright.dev/docs/ci-intro]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release-gate orchestration | Frontend Server (GitHub Actions control plane) | API / Backend | Job sequencing, cache restores, artifact upload, and branch-blocking all live in workflow YAML rather than the Phoenix app itself. [VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |
| Package compile/test/docs blockers | API / Backend | Frontend Server (GitHub Actions) | `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix docs --warnings-as-errors`, Credo, Dialyzer, and Hex audit all execute inside the package jobs. [VERIFIED: repo grep] |
| Host setup + Fake-backed integration gate | API / Backend | Database / Storage | The host gate exercises Phoenix, Accrue, Oban, and Postgres behavior end to end; GitHub Actions only schedules it. [VERIFIED: repo grep] |
| Browser debugging artifacts | Browser / Client | Frontend Server (GitHub Actions) | Traces, screenshots, and HTML reports come from the browser test runner and are then uploaded by CI. [CITED: https://playwright.dev/docs/ci-intro][CITED: https://playwright.dev/docs/api/class-testoptions] |
| Annotation sweep | Frontend Server (GitHub Actions control plane) | API / Backend | The sweep inspects workflow job/check metadata after jobs complete; it is CI metadata analysis, not application logic. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs][CITED: https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28] |

## Project Constraints (from CLAUDE.md)

- Supported floors remain Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. Phase 11 should not recommend a CI cell below that floor. [VERIFIED: CLAUDE.md]
- The repo is a monorepo with sibling `accrue/` and `accrue_admin/` Mix projects plus the Phase 10 host app under `examples/accrue_host`; CI planning should preserve that shape. [VERIFIED: CLAUDE.md][VERIFIED: repo grep]
- Webhook signature verification and raw-body handling are mandatory; host-app CI must keep exercising the installed `/webhooks/stripe` path rather than bypassing it. [VERIFIED: CLAUDE.md][VERIFIED: repo grep]
- Host auth remains host-owned; CI should verify mounted `accrue_admin` behind the host session boundary, not a package shortcut. [VERIFIED: CLAUDE.md][VERIFIED: repo grep]
- Warnings and GitHub annotations are already treated as release blockers in project history and should remain so for release-facing jobs. [VERIFIED: .planning/MILESTONES.md][VERIFIED: .planning/STATE.md]

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GitHub Actions workflow with ordered jobs | Repo-pinned YAML using `ubuntu-24.04`, `actions/checkout@v6`, `erlef/setup-beam@v1`, `actions/cache@v5`, `actions/upload-artifact@v7` in the main gate. [VERIFIED: repo grep] | Release-blocking orchestration | The repo already uses these actions successfully in its main gate and auxiliary browser workflows. [VERIFIED: repo grep] |
| Phoenix | `1.8.5` published `2026-03-05`. [VERIFIED: hex.pm registry] | Host app framework under test | The host example and package support floor are already anchored here; Phase 11 should test the real supported surface, not a downgraded fixture. [VERIFIED: repo grep][VERIFIED: CLAUDE.md] |
| Phoenix LiveView | `1.1.28` published `2026-03-27`. [VERIFIED: hex.pm registry] | Mounted auth/admin/browser flows | The host app and `accrue_admin` both rely on LiveView paths that the browser gate must exercise. [VERIFIED: repo grep] |
| Oban | `2.21.1` published `2026-03-26`. [VERIFIED: hex.pm registry] | Host webhook dispatch and admin replay state | The host gate only proves replay/idempotence if Oban-backed state is present in the CI database. [VERIFIED: repo grep] |
| PostgreSQL service | `postgres:15` in current workflows. [VERIFIED: repo grep] | Durable CI backing store | All current CI and host UAT workflows already depend on a Postgres service, and the host harness expects `localhost:5432`. [VERIFIED: repo grep][VERIFIED: local environment probe] |
| Playwright Test | `1.59.1` published `2026-04-01`. [VERIFIED: npm registry] | Host browser gate with traces/screenshots/reporting | Official Playwright CI guidance and the existing admin browser workflow both use Playwright Test plus artifact upload. [CITED: https://playwright.dev/docs/ci-intro][VERIFIED: repo grep] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bandit | `1.10.4` published `2026-03-26`. [VERIFIED: hex.pm registry] | Host HTTP server boot path | Use the real host server path for browser and boot smoke coverage; the example app already ships on Bandit. [VERIFIED: repo grep] |
| Ecto SQL | `3.13.5` published `2026-03-03`. [VERIFIED: hex.pm registry] | Migrations and repo setup in CI | Required for `ecto.create`, `ecto.migrate`, and real persistence-backed host proofs. [VERIFIED: repo grep] |
| Postgrex | `0.22.0` published `2026-01-10`. [VERIFIED: hex.pm registry] | PostgreSQL adapter | Required by the host app and package test surfaces that hit Postgres. [VERIFIED: repo grep] |
| GitHub REST workflow jobs API | API version `2026-03-10` on the current docs page. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs] | Optional final annotation sweep | Use only if the workflow still needs a post-job sweep for surviving warning/error annotations. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs][CITED: https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One ordered `ci.yml` gate | Keep `ci.yml`, `accrue_host_uat.yml`, and `accrue_admin_assets.yml` as separate required workflows | Separate workflows are workable, but they do not express failure-layer order inside one gate, and branch protection becomes more brittle. [VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |
| Playwright Test for host browser flows | Keep `scripts/ci/accrue_host_browser_smoke.cjs` as the browser runner | The custom script proves behavior, but it does not natively emit retained traces/screenshots/HTML reports the way Playwright Test does. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/ci-intro][CITED: https://playwright.dev/docs/api/class-testoptions] |
| Fold asset drift into the blocking gate | Keep `accrue_admin_assets.yml` path-filtered and separate | Separate asset drift checks can miss the “single release gate” goal and make branch protection policy harder to reason about. [VERIFIED: repo grep] |

**Installation:**
```bash
cd examples/accrue_host
npm init -y
npm install --save-dev @playwright/test
npx playwright install --with-deps chromium
```
[CITED: https://playwright.dev/docs/ci-intro]

## Architecture Patterns

### System Architecture Diagram

```text
pull_request / push(main)
  -> ci.yml
    -> package release gate job(s)
      -> accrue compile/test/docs/credo/dialyzer/audit
      -> accrue_admin compile/test/docs/credo/dialyzer/audit
      -> asset freshness / docs drift blockers
    -> host integration job (needs package gate)
      -> mix deps.get
      -> mix accrue.install --yes
      -> generated drift check
      -> ecto create/migrate
      -> targeted host integration tests
      -> full host regression tests
      -> browser UAT via Playwright
      -> upload report/traces/screenshots on failure
    -> optional annotation sweep job (needs prior jobs)
      -> query workflow jobs / check annotations
      -> fail on warning/error annotations outside explicit allowlist

workflow_dispatch / schedule
  -> advisory live-stripe job
    -> never blocks pull_request/main release gate
```
[VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

### Recommended Project Structure
```text
.github/workflows/
├── ci.yml                         # mandatory ordered release gate
└── optional auxiliary workflows   # manual/advisory only after Phase 11

examples/accrue_host/
├── e2e/                           # new Playwright specs for host user/admin flows
├── playwright.config.js           # host-specific webServer + artifact config
├── package.json                   # local Playwright dependency if Phase 11 localizes it here
└── test/                          # existing ExUnit host integration tests

scripts/ci/
├── accrue_host_uat.sh             # shell orchestration for non-browser host checks
└── annotation_sweep.sh            # optional Phase 11 follow-up if API-based sweep is kept
```
[VERIFIED: repo grep][CITED: https://playwright.dev/docs/ci-intro]

### Pattern 1: Ordered Release Gate Inside One Workflow
**What:** Use `needs` so the host integration job only runs after the package-local blockers pass. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
**When to use:** For the mandatory PR and `main` release gate. [VERIFIED: .planning/ROADMAP.md]
**Example:**
```yaml
# Source: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
jobs:
  packages:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v6
      - name: Run package gate
        run: ./.github/scripts/package_gate.sh

  host-integration:
    needs: packages
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v6
      - name: Run host integration gate
        run: bash scripts/ci/accrue_host_uat.sh
```

### Pattern 2: Promote Host Browser Smoke to Playwright Test
**What:** Move host browser assertions into Playwright Test with `webServer`, `trace`, `screenshot`, and HTML report output. [CITED: https://playwright.dev/docs/ci-intro][CITED: https://playwright.dev/docs/api/class-testoptions]
**When to use:** For the mandatory Fake-backed browser proof path and CI artifact publishing. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```javascript
// Source: https://playwright.dev/docs/ci-intro
// Source: https://playwright.dev/docs/api/class-testoptions
const { defineConfig, devices } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./e2e",
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
  use: {
    baseURL: "http://127.0.0.1:4101",
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: {
    command: "MIX_ENV=test PORT=4101 mix phx.server",
    url: "http://127.0.0.1:4101/",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  },
  projects: [{ name: "chromium-desktop", use: { ...devices["Desktop Chrome"] } }]
});
```

### Pattern 3: Artifact Upload Only for Failed Browser Runs
**What:** Upload Playwright reports, traces, screenshots, and server logs only when the browser job fails. [CITED: https://playwright.dev/docs/ci-intro][CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
**When to use:** On the host browser job in `ci.yml`. [VERIFIED: .planning/ROADMAP.md]
**Example:**
```yaml
# Source: https://playwright.dev/docs/ci-intro
# Source: https://docs.github.com/en/actions/tutorials/store-and-share-data
- name: Run host browser UAT
  run: npx playwright test

- name: Upload Playwright report
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-host-playwright-report
    path: examples/accrue_host/playwright-report
    retention-days: 14

- name: Upload Playwright traces
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-host-playwright-traces
    path: examples/accrue_host/test-results
```

### Anti-Patterns to Avoid

- **Separate mandatory workflows for ordered blockers:** Multiple workflows can all be required, but they cannot express the clear within-gate sequence this phase asks for. [VERIFIED: repo grep][CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- **Custom browser runner without artifact semantics:** The current host browser smoke script is good proof code, but it is the wrong long-term CI surface for retained debugging artifacts. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/ci-intro]
- **Path-filtered-only mandatory gate:** A user-facing regression can come from shared package code, workflow code, or generated install logic; the blocking release gate should be unconditional on PRs and `main` pushes. [VERIFIED: repo grep][VERIFIED: .planning/ROADMAP.md]
- **Making live Stripe part of the blocking PR gate:** The current project requirement and existing workflow model both keep it advisory. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: repo grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser artifact retention | Custom zip/log plumbing around a raw Node browser script | Playwright Test `html` reporter plus `trace: "retain-on-failure"` and `screenshot: "only-on-failure"` | The built-in runner already solves trace/report retention and matches the repo’s admin browser pattern. [CITED: https://playwright.dev/docs/ci-intro][CITED: https://playwright.dev/docs/api/class-testoptions][VERIFIED: repo grep] |
| Job sequencing | Ad hoc status files or shell chaining across workflows | `jobs.<job_id>.needs` | GitHub Actions already provides native dependency ordering and failure propagation. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] |
| Annotation inspection transport | Scraping HTML from the Actions UI | GitHub REST workflow jobs/check runs endpoints | The REST APIs are the supported machine-readable surface for job metadata and annotations. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs][CITED: https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28] |

**Key insight:** Phase 11 should mostly compose proven repo pieces into one blocking path; the only genuinely new surface is the host Playwright runner needed for artifact-rich browser failures. [VERIFIED: repo grep]

## Common Pitfalls

### Pitfall 1: Treating Separate Workflows as an Ordered Gate
**What goes wrong:** Package jobs, asset drift checks, and host UAT all run, but failures do not point to the right layer or block in the intended order. [VERIFIED: repo grep]
**Why it happens:** The repo currently splits release-facing concerns across `ci.yml`, `accrue_host_uat.yml`, and `accrue_admin_assets.yml`. [VERIFIED: repo grep]
**How to avoid:** Move mandatory host/drift blockers into one `ci.yml` workflow with `needs`-based sequencing. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
**Warning signs:** A PR shows several unrelated workflows racing in parallel, or the host UAT starts before package docs/drift checks finish. [VERIFIED: repo grep]

### Pitfall 2: Keeping the Host Browser Gate on the Custom Smoke Script
**What goes wrong:** CI tells you the browser path failed, but you do not get retained traces/screenshots or an HTML report. [VERIFIED: repo grep]
**Why it happens:** `scripts/ci/accrue_host_browser_smoke.cjs` drives Chromium directly and exits on failure without the Playwright Test artifact model. [VERIFIED: repo grep]
**How to avoid:** Port the existing browser assertions into `examples/accrue_host/e2e/*.spec.js` under Playwright Test. [CITED: https://playwright.dev/docs/ci-intro]
**Warning signs:** Browser failures require rerunning locally to see state, and there is nothing to upload besides raw stdout/stderr. [VERIFIED: repo grep]

### Pitfall 3: Missing Generated-Artifact Drift in the Blocking Workflow
**What goes wrong:** The host app or admin package drifts from generated output, but the main branch gate still passes because the drift check lives elsewhere. [VERIFIED: repo grep]
**Why it happens:** The current host drift check lives in `accrue_host_uat.sh`, and admin asset drift lives in a separate path-filtered workflow. [VERIFIED: repo grep]
**How to avoid:** Keep both host generated-drift and admin asset drift as mandatory steps inside the ordered blocking workflow. [VERIFIED: repo grep]
**Warning signs:** Branch protection requires only `CI`, while drift failures show up in auxiliary workflows. [VERIFIED: repo grep]

### Pitfall 4: Accidentally Upgrading Live Stripe from Advisory to Blocking
**What goes wrong:** PRs fail because Stripe flakes or secrets are absent. [VERIFIED: repo grep][VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** It is tempting to fold every fidelity check into one gate. [ASSUMED]
**How to avoid:** Leave `live-stripe` on `workflow_dispatch` and `schedule` with advisory semantics, and keep the mandatory path Fake-backed. [VERIFIED: repo grep]
**Warning signs:** `live-stripe` appears under `pull_request` or `push` in the blocking workflow. [VERIFIED: repo grep]

### Pitfall 5: Annotation Sweep Without a Clear Allowlist Boundary
**What goes wrong:** The sweep either misses real warning/error annotations or fails on expected notices. [VERIFIED: .planning/MILESTONES.md][VERIFIED: .planning/STATE.md]
**Why it happens:** Project history already mentions one expected Browser UAT notice, so the sweep cannot be “fail on any annotation” without policy. [VERIFIED: .planning/MILESTONES.md]
**How to avoid:** Prefer direct job failures for warnings where possible; if a final sweep remains necessary, make the allowlist explicit and tiny. [VERIFIED: repo grep][CITED: https://docs.github.com/en/rest/actions/workflow-jobs]
**Warning signs:** The sweep script contains broad substring ignores or suppresses all non-error annotations. [ASSUMED]

## Code Examples

### Ordered Host Gate in `ci.yml`
```yaml
# Source: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
jobs:
  release-gate:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v6
      - name: Accrue compile
        run: cd accrue && mix compile --warnings-as-errors
      - name: Accrue admin docs
        run: cd accrue_admin && MIX_ENV=dev mix docs --warnings-as-errors

  host-integration:
    needs: release-gate
    runs-on: ubuntu-24.04
    services:
      postgres:
        image: postgres:15
    steps:
      - uses: actions/checkout@v6
      - name: Run host gate
        run: bash scripts/ci/accrue_host_uat.sh
```

### Current Host Drift Boundary
```bash
# Source: /Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh
mix accrue.install --yes \
  --billable AccrueHost.Accounts.User \
  --billing-context AccrueHost.Billing \
  --admin-mount /billing \
  --webhook-path /webhooks/stripe

git -C "$repo_root" diff --quiet -- \
  examples/accrue_host \
  ':!examples/accrue_host/README.md'
```
[VERIFIED: repo grep]

### Existing Playwright Artifact Pattern Worth Reusing
```javascript
// Source: /Users/jon/projects/accrue/accrue_admin/playwright.config.js
module.exports = defineConfig({
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: {
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  }
});
```
[VERIFIED: repo grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw browser smoke scripts with ad hoc failure logging | Playwright Test with HTML report artifact upload in CI docs and existing repo browser workflow | Playwright docs current as of `2026-04-16`; repo already adopted this in `accrue_admin_browser.yml`. [CITED: https://playwright.dev/docs/ci-intro][VERIFIED: repo grep] | Phase 11 should follow the already-proven Playwright artifact path for the host app too. |
| Independent workflows for related checks | One workflow with explicit `needs` chains for ordered blockers | GitHub Actions workflow syntax documents native sequential job dependencies. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] | This is the cleanest way to make failures point at the right layer. |
| Manual post-release annotation review | Machine-readable workflow jobs/check run APIs | Current GitHub REST docs expose workflow jobs and check runs, including annotations. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs][CITED: https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28] | Phase 11 can automate the sweep if direct failures are not sufficient. |

**Deprecated/outdated:**
- Keeping the host browser check only as [`accrue_host_browser_smoke.cjs`](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs) is outdated for a mandatory CI artifact gate because it lacks first-class retained traces/screenshots/reports. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/ci-intro]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A final post-job annotation sweep may still be needed after direct job failures are tightened. [ASSUMED] | Phase Requirements / Common Pitfalls | Medium: planner may overbuild the sweep if current failing surfaces are already sufficient. |
| A2 | Expected non-blocking Browser UAT notices, if any remain, should be handled through a tiny explicit allowlist rather than removed entirely. [ASSUMED] | Common Pitfalls | Medium: policy may differ from project intent once the new gate is in place. |

## Open Questions

1. **Should Phase 11 fully replace `accrue_host_uat.yml`, or keep it as a fast-path duplicate after `ci.yml` absorbs the blocking gate?**
   - What we know: The current separate workflow duplicates release-facing host work and cannot participate in an in-workflow `needs` chain. [VERIFIED: repo grep]
   - What's unclear: Whether the project wants one canonical gate only or also a narrower path-filtered convenience workflow. [ASSUMED]
   - Recommendation: Make `ci.yml` the only required gate first; keep any auxiliary workflow non-required and clearly labeled convenience/debug. [VERIFIED: repo grep]

2. **Where should host Playwright live?**
   - What we know: The repo already has Playwright dependencies under `accrue_admin/`, while the host example has no `package.json` yet. [VERIFIED: repo grep]
   - What's unclear: Whether the project prefers a package-local Playwright dependency under `examples/accrue_host/` or a shared root/tooling location. [ASSUMED]
   - Recommendation: Prefer `examples/accrue_host/package.json` unless the planner finds a strong monorepo reason to centralize JS tooling, because the browser gate is specific to the host app. [VERIFIED: repo grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | package + host CI commands | ✓ [VERIFIED: local environment probe] | `1.19.5` locally; workflows pin `1.17.3`, `1.18.0`, `1.18.4`. [VERIFIED: local environment probe][VERIFIED: repo grep] | GitHub Actions runner pins exact versions. [VERIFIED: repo grep] |
| Node.js | Playwright/browser gate | ✓ [VERIFIED: local environment probe] | `22.14.0` local; workflows use Node `22`. [VERIFIED: local environment probe][VERIFIED: repo grep] | None needed for browser artifacts. |
| npm | Playwright install | ✓ [VERIFIED: local environment probe] | `11.1.0`. [VERIFIED: local environment probe] | None. |
| PostgreSQL | host app + package CI DB-backed tests | ✓ [VERIFIED: local environment probe] | Local `pg_isready` passes on `localhost:5432`; workflows use `postgres:15`. [VERIFIED: local environment probe][VERIFIED: repo grep] | None for the mandatory host gate. |
| Chromium / Playwright browser | browser UAT | ✓ [VERIFIED: local environment probe] | Local `chromium` plus Playwright `1.59.1`. [VERIFIED: local environment probe][VERIFIED: npm registry] | No practical fallback if CI must publish browser artifacts. |
| `gh` + `jq` | optional annotation sweep scripting | ✓ [VERIFIED: local environment probe] | `gh 2.89.0`, `jq 1.7.1`. [VERIFIED: local environment probe] | `curl` + `jq` only, if `gh` is not used on runners. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs] |

**Missing dependencies with no fallback:**
- None on the current workstation for planning research. [VERIFIED: local environment probe]

**Missing dependencies with fallback:**
- None identified for the mandatory Fake-backed gate; the only optional tool is `gh`, which can be replaced by direct REST calls. [VERIFIED: local environment probe][CITED: https://docs.github.com/en/rest/actions/workflow-jobs]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit for packages and host app; Playwright Test for existing admin browser UAT. [VERIFIED: repo grep] |
| Config file | [`accrue_admin/playwright.config.js`](/Users/jon/projects/accrue/accrue_admin/playwright.config.js); no host Playwright config yet. [VERIFIED: repo grep] |
| Quick run command | `bash scripts/ci/accrue_host_uat.sh` for current host equivalence. [VERIFIED: repo grep] |
| Full suite command | `gh workflow run` is not the right local equivalent; Phase 11 should keep local reproduction in shell commands and CI reproduction in `ci.yml`. [ASSUMED] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-01 | PR/main runs package + host setup/integration suite | workflow + integration | `bash scripts/ci/accrue_host_uat.sh` plus `ci.yml` job wiring [VERIFIED: repo grep] | Partial: host script exists, workflow integration missing |
| CI-02 | warnings/docs/drift/browser failures block | workflow + shell + browser | `cd accrue && MIX_ENV=dev mix docs --warnings-as-errors` and `cd accrue_admin && MIX_ENV=dev mix docs --warnings-as-errors` and `bash scripts/ci/accrue_host_uat.sh` [VERIFIED: repo grep] | Partial |
| CI-03 | clear layer order | workflow | `ci.yml` with `needs` chain [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] | ❌ Wave 0 |
| CI-04 | failed browser runs publish useful artifacts | browser + workflow | `npx playwright test` with `actions/upload-artifact` [CITED: https://playwright.dev/docs/ci-intro][CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] | ❌ Wave 0 |
| CI-05 | live Stripe advisory only | workflow | existing `live-stripe` job policy in `ci.yml` [VERIFIED: repo grep] | ✅ |
| CI-06 | warning/error annotations remain blockers | workflow + optional API check | shell script using workflow jobs/check-runs REST APIs if needed [CITED: https://docs.github.com/en/rest/actions/workflow-jobs][CITED: https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28] | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bash scripts/ci/accrue_host_uat.sh` after host-gate changes, plus the touched package-local `mix test`/`mix docs` command. [VERIFIED: repo grep]
- **Per wave merge:** Run the updated `ci.yml` locally where reproducible, then in GitHub Actions. [ASSUMED]
- **Phase gate:** Updated `ci.yml` green on a pull request before `/gsd-verify-work`. [VERIFIED: .planning/ROADMAP.md]

### Wave 0 Gaps
- [ ] [`examples/accrue_host/playwright.config.js`](/Users/jon/projects/accrue/examples/accrue_host/playwright.config.js) — host browser gate with retained artifacts. [VERIFIED: repo grep]
- [ ] [`examples/accrue_host/e2e/host-billing.spec.js`](/Users/jon/projects/accrue/examples/accrue_host/e2e/host-billing.spec.js) — migrate current browser smoke assertions into Playwright Test. [VERIFIED: repo grep]
- [ ] [`examples/accrue_host/package.json`](/Users/jon/projects/accrue/examples/accrue_host/package.json) — local Playwright dependency if Phase 11 localizes browser tooling. [VERIFIED: repo grep]
- [ ] [`scripts/ci/annotation_sweep.sh`](/Users/jon/projects/accrue/scripts/ci/annotation_sweep.sh) — only if the planner decides a post-job API sweep is still necessary. [ASSUMED]
- [ ] [`ci.yml`](/Users/jon/projects/accrue/.github/workflows/ci.yml) host/drift ordering changes — current main gate does not yet run the host app flow. [VERIFIED: repo grep]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: repo grep] | Host session auth must still guard `/billing` in the CI browser path. [VERIFIED: repo grep] |
| V3 Session Management | yes [VERIFIED: repo grep] | The host browser gate should verify the real Phoenix-auth session cookie path, not a bypass. [VERIFIED: repo grep] |
| V4 Access Control | yes [VERIFIED: repo grep] | Admin replay remains behind the host-owned billing-admin boundary. [VERIFIED: repo grep] |
| V5 Input Validation | yes [VERIFIED: repo grep] | CI must keep exercising signed webhook input through the installed raw-body pipeline. [VERIFIED: repo grep][VERIFIED: CLAUDE.md] |
| V6 Cryptography | yes [VERIFIED: CLAUDE.md] | Webhook signature verification stays mandatory and must remain part of the host gate. [VERIFIED: CLAUDE.md][VERIFIED: repo grep] |

### Known Threat Patterns for This Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Webhook signature bypass in CI-only shortcuts | Spoofing | Keep the host gate on `/webhooks/stripe` with raw-body + signature verification instead of reducer shortcuts. [VERIFIED: repo grep][VERIFIED: CLAUDE.md] |
| Anonymous access to mounted admin UI | Elevation of Privilege | Run browser/admin tests through real host login and billing-admin authorization. [VERIFIED: repo grep] |
| Sensitive failure artifacts leaking secrets | Information Disclosure | Keep using Fake-backed flows by default and treat Playwright traces/reports as sensitive artifacts. [CITED: https://playwright.dev/docs/ci-intro][VERIFIED: .planning/REQUIREMENTS.md] |
| Drifted generated install output hiding runtime regressions | Tampering | Re-run `mix accrue.install --yes` and fail on diffs inside the blocking gate. [VERIFIED: repo grep] |

## Sources

### Primary (HIGH confidence)
- [`ROADMAP.md`](/Users/jon/projects/accrue/.planning/ROADMAP.md) - Phase 11 goal, dependency, success criteria, and requirement IDs. [VERIFIED: repo grep]
- [`REQUIREMENTS.md`](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md) - CI-01 through CI-06 definitions and live-Stripe advisory boundary. [VERIFIED: repo grep]
- [`ci.yml`](/Users/jon/projects/accrue/.github/workflows/ci.yml) - current package release gate, advisory live-Stripe job, and blocking commands. [VERIFIED: repo grep]
- [`accrue_host_uat.yml`](/Users/jon/projects/accrue/.github/workflows/accrue_host_uat.yml) - current host UAT workflow shape. [VERIFIED: repo grep]
- [`accrue_admin_browser.yml`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml) - existing Playwright CI artifact pattern. [VERIFIED: repo grep]
- [`scripts/ci/accrue_host_uat.sh`](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh) - current host setup/test/browser/drift orchestration. [VERIFIED: repo grep]
- [`scripts/ci/accrue_host_browser_smoke.cjs`](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs) - current custom host browser runner. [VERIFIED: repo grep]
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax - native job ordering with `needs` and workflow control semantics. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- https://docs.github.com/en/actions/tutorials/store-and-share-data - artifact upload and retention semantics. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]
- https://docs.github.com/en/rest/actions/workflow-jobs - workflow jobs REST endpoints for optional sweep automation. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs]
- https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28 - check-run annotation API surface. [CITED: https://docs.github.com/en/rest/checks/runs?apiVersion=2022-11-28]
- https://playwright.dev/docs/ci-intro - CI setup, artifact upload example, report/trace guidance, and secrets warning. [CITED: https://playwright.dev/docs/ci-intro]
- https://playwright.dev/docs/api/class-testoptions - `trace`, `screenshot`, and related test runner options. [CITED: https://playwright.dev/docs/api/class-testoptions]

### Secondary (MEDIUM confidence)
- Hex.pm package API for `phoenix`, `phoenix_live_view`, `oban`, `bandit`, `ecto_sql`, and `postgrex` version/date verification. [VERIFIED: hex.pm registry]
- npm registry for `@playwright/test` version/date verification. [VERIFIED: npm registry]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Repo CI surfaces, official GitHub/Playwright docs, and current registry versions all agree. [VERIFIED: repo grep][CITED: https://playwright.dev/docs/ci-intro]
- Architecture: HIGH - The repo already contains the package gate, host harness, and browser workflow pieces Phase 11 must compose. [VERIFIED: repo grep]
- Pitfalls: MEDIUM-HIGH - Most pitfalls are directly visible in current workflow layout; the annotation-sweep policy details still need implementation choice. [VERIFIED: repo grep][ASSUMED]

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 for repo-structure findings; re-check registry/docs versions sooner if Phase 11 planning is delayed. [VERIFIED: hex.pm registry][VERIFIED: npm registry]
