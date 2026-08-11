# Phase 226: CI Baseline & Proof Semantics - Research

**Researched:** 2026-08-11
**Domain:** GitHub Actions CI evidence, provider-proof semantics, and host/CI setup ownership
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Make a checked-in, versioned Phase 226 evidence pack canonical: concise Markdown for maintainers plus sanitized machine-readable JSON or NDJSON for validation and later before/after comparison. GitHub `$GITHUB_STEP_SUMMARY` output may mirror run-local facts for convenience, but it is not the durable cross-run source of truth. Raw logs, traces, screenshots, reports, payloads, and provider data remain linked GitHub Actions artifacts and are not checked into the repository.
- **D-02:** Define a comparable cohort by immutable workflow/config fingerprint, event class, normalized branch class, runner image, required-job-set and matrix fingerprint, and provider configuration class. Keep pull request, push, full `workflow_dispatch`, and scheduled provider-only runs separate. Do not mix schedule-only `live-stripe` executions into full-CI timing cohorts.
- **D-03:** Use the latest 20 successful, first-attempt, full-CI runs in a rolling 90-day window for green-path duration statistics and preserve the Phase 226 snapshot as the frozen before-state. If fewer than 20 comparable observations exist, report the exact count and `insufficient sample`; do not manufacture percentiles or mix unlike runs to fill the cohort.
- **D-04:** Exclude failed, cancelled, skipped, and rerun attempts from green-path duration percentiles, but retain them in a companion reliability table. Group attempts by original run identity and SHA so a rerun is never a second sample. Normalize one root-failure signature across repeated matrix cells rather than inflating one cause into multiple incidents.
- **D-05:** Record workflow wall time, true runner queue time, dependency/DAG wait, job and step duration, rerun count, cache hit/miss plus restore/save duration and size where available, named Docker/browser/Node/npm/Phoenix/fixture/Playwright setup costs, provider proof state, and normalized root-failure signature. Derive root-job runner queue as job start minus run creation; derive a dependent job's DAG wait from the latest prerequisite completion. Never label dependency wait as runner queueing.
- **D-06:** Keep baseline rows privacy-safe: run ID and immutable URL, truncated SHA, timestamps, event/cohort fingerprints, job/step identity, calculated durations, cache observations, provider state, conclusions, and normalized signature are allowed. Actor, raw branch name, logs, secrets or secret-presence details, provider payloads, artifact contents, and user data are excluded.
- **D-07:** Validate schema version, cohort fingerprint and exclusions, stable job and matrix identities, provider-state exhaustiveness, duration arithmetic, rerun grouping, and root-signature normalization. Include deterministic fixtures covering a successful first attempt, failure, cancellation, rerun, provider non-run/misconfiguration, and one signature repeated across matrix cells.
- **D-08:** Represent lane enforcement policy and capability evidence as independent fields. `policy` is `required` or `advisory`; `proof_state` is `proved`, `failed`, `misconfigured`, `blocked`, `skipped`, or `non_run`. `stale` is a derived freshness condition on the latest proved record, never a substitute proof state. A GitHub job conclusion remains a separate raw fact and cannot itself assert provider proof.
- **D-09:** Use `proved` only when the provider suite actually executed with all required configuration and fixtures, selected at least one required test, passed its assertions, and emitted its privacy-safe evidence manifest. A green Fake-backed suite or a GitHub `success`/`skipped` conclusion is not live-provider proof.
- **D-10:** On triggers where a provider lane is not selected, record `non_run` with explicit copy that there is no provider proof for that SHA. On scheduled/manual provider runs, absent credentials, missing fixtures, or zero selected tests is `misconfigured` and must fail the periodic lane. Executed assertion failures are `failed`; runner cancellation or upstream inability is `blocked`; an explicitly selected but intentionally bypassed execution is `skipped` with a recorded reason.
- **D-11:** Derive `stale` from the documented provider cadence plus an explicit grace window. Surface both the latest proved SHA/time and its freshness; never imply that fresh proof covers a different current SHA.
- **D-12:** Emit a redacted machine-readable proof record and an `if: always()` human summary containing trigger, SHA, policy, proof state and reason, raw job conclusion, selected/passed/skipped counts, freshness, evidence links, and one exact next action. Never emit secret values or provider payloads. Use literal state words and accessible structure rather than color alone.
- **D-13:** Preserve the existing truth boundaries: deterministic Fake-backed behavior remains the contributor-facing merge proof; Floor, Primary, and Primary plus OpenTelemetry remain required release evidence; Sigra remains explicitly advisory; Stripe parity is proved only by an actually executed successful live test-mode suite.
- **D-14:** The example host owns the declared Node and Playwright versions, `package-lock.json`, Playwright configuration, fixtures, database/seed and server lifecycle, test semantics, and canonical host proof command. CI owns runner selection, pinned Node provisioning, Linux browser/OS dependency provisioning, cache transport and observation, step timing, and retained failure artifacts. Both local and CI paths invoke the same host-owned Playwright proof contract.
- **D-15:** Local host verification preflights required tooling and returns exact installation guidance rather than hiding a missing prerequisite inside an ambiguous browser-test failure. CI provisions its environment explicitly before calling the same proof contract. Phase 226 documents and measures today's duplicate provisioning; it does not remove that work before Phase 227 selects an evidence-backed optimization.
- **D-16:** Classify setup failures with stable codes at minimum for `node_missing_or_version`, `npm_lock_or_registry`, `playwright_binary_or_revision`, `linux_browser_dependency`, `browser_launch`, `port_or_server_readiness`, and `fixture_or_database`. A diagnostic leads with what failed, the owning boundary (`host` or `CI`), one narrow next command, and the artifact/log location.
- **D-17:** Record a compact privacy-safe setup fact with owner, command identity, Node/Playwright/lockfile identity, browser revision or non-sensitive path class, cache state, duration, and classified result. Redact URLs, tokens, environment values, payloads, and application data.
- **D-18:** Preserve existing single-worker and zero-retry browser semantics where they are part of required proof, along with failure-only traces/reports/server logs and accessibility evidence. Do not add Playwright browser caching by default: measure install and restore costs first, then let Phase 227 decide with a negative control and rollback.
- **D-19:** Optimize the evidence interface for the maintainer job: “When CI changes state, tell me what was and was not proved, where time went, who owns the failure, and the exact next action.” Lead every baseline/proof/setup summary with fact, state, owner, next command, then linked forensic detail.
- **D-20:** Use the current brandbook's measured, exact, proof-checkable voice. Keep Markdown scannable, literal, accessible, non-color-dependent, and consistent with the Phase 225 incident-index grammar. Hide collection mechanics and backend detail unless required to explain a fundamental evidence boundary.
- **D-21:** Treat clarity, truthfulness, privacy/security, accessibility, performance, resilience, consistency, observability, and maintainability as the design pillars. Prefer stable conventional Markdown tables and versioned records over a bespoke dashboard or product UI in this phase.

### the agent's Discretion

- The researcher and planner may choose exact filenames, JSON versus NDJSON, schema field names, signature hashing/normalization mechanics, Markdown table layout, and the provider freshness grace window, provided D-01 through D-21 remain true.
- The planner may select the exact deterministic fixture mechanism and narrow verification entrypoints. No selection may change CI topology, remove setup work, or weaken proof in Phase 226.

### Deferred Ideas (OUT OF SCOPE)

- Remove or consolidate a measured duplicate Node/npm/browser/setup cost in Phase 227 after Phase 226 establishes before-state evidence, negative controls, and rollback expectations.
- Add Playwright browser caching only if measured restore behavior beats installation and preserves Linux dependency correctness; this is a Phase 227 decision.
- Adopt an external CI-observability vendor only if a future authorized multi-repository monitoring/alerting need justifies credentials, retention, access control, and operational ownership.
- Release-matrix reshaping, branch-protection changes, required-gate demotion, cache rewrites, test deletion/retry masking, StoreKit/iPhone/Crosswake work, and Admin UI ratchet work remain outside Phase 226.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BASE-01 | Durable, privacy-safe comparable-run timing, cache, provider, and root-failure baseline. | Versioned NDJSON snapshot + derived Markdown, GitHub run/job/step collector, schema validator, and deterministic fixtures. |
| BASE-02 | Required, skipped, and advisory provider evidence visibly differs. | Independent `policy`, raw `job_conclusion`, and exhaustive `proof_state` fields plus always-run redacted summary. |
| OWN-01 | Host maintainer can identify Node/browser/Playwright ownership and setup failure modes. | Ownership matrix, preflight/diagnostic adapter, compact setup facts, and canonical host proof commands. |
</phase_requirements>

## Summary

Phase 226 should add a small, repository-owned evidence system rather than an observability service or CI optimization. Use a versioned NDJSON source of truth and a generated Markdown reading surface in this phase directory; collect only sanctioned GitHub Actions run/job/step metadata and link raw artifacts externally. GitHub’s REST job response provides job and step timestamps/conclusions, while run records include `run_attempt`; those are sufficient inputs for duration, queue, retry, and reliability derivations. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2026-03-10] [CITED: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10]

The existing CI graph makes the claimed 33–36 minute path a hypothesis, not a fact. The Phase 225 repair run `31322443304` was a first-attempt successful `workflow_dispatch` run with a 39m40s workflow wall interval; `host-integration` started after its declared prerequisites and the three `playwright-e2e` shards started after host completion. Therefore measure DAG wait separately from runner queue, freeze the cohort result, and state whether the staged route confirms or refutes the hypothesis. [VERIFIED: GitHub Actions API + `.github/workflows/ci.yml`]

Current `live-stripe` mechanics conflict with the locked Phase 226 semantics: the workflow runs it only for schedule/manual triggers, while the Mix alias and several modules can cleanly skip when configuration is absent. Preserve the contributor-facing Fake lane and the existing required/advisory release matrix, but make a scheduled/manual provider run with missing prerequisites `misconfigured` and failing, never “proved.” [VERIFIED: `.github/workflows/ci.yml`, `accrue/mix.exs`, and `guides/testing-live-stripe.md`]

**Primary recommendation:** Implement a dependency-free Node collector/validator under `scripts/ci/`, a frozen phase-local NDJSON+Markdown evidence pack, and an always-run provider/setup summary; do not alter job IDs, DAG, caches, retries, or matrix membership.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Comparable-run collection and derivation | API / Backend | CDN / Static | GitHub Actions REST data is collected and normalized outside a browser; checked-in files are the durable interface. [VERIFIED: GitHub Actions API] |
| Run-local maintainer summary | Frontend Server (SSR) | API / Backend | The runner writes accessible Markdown through `GITHUB_STEP_SUMMARY`; it mirrors, not owns, evidence. [CITED: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions] |
| Provider proof state | API / Backend | — | The CI job determines selection, test counts, raw conclusion, and manifest evidence. [VERIFIED: `.github/workflows/ci.yml`] |
| Browser setup ownership and diagnostics | API / Backend | Browser / Client | CI prepares a Linux runner; the example host owns Playwright configuration and test contract. [VERIFIED: `.github/workflows/ci.yml` and `examples/accrue_host/playwright.config.js`] |
| Raw reports/traces/logs | CDN / Static | API / Backend | Actions artifact storage remains the forensic layer; only links/metadata belong in baseline records. [VERIFIED: `.github/workflows/ci.yml`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Node.js built-ins (`node:fs`, `node:crypto`, `node:assert`) | Existing Node 22 CI runtime | Parse fixtures, validate schema/arithmetic, emit NDJSON/Markdown. | No package is needed for a bounded deterministic JSON evidence tool. [VERIFIED: `.github/workflows/ci.yml`] |
| GitHub REST API via existing `gh` CLI | Existing `gh` workflow/auth surface | Fetch workflow runs and jobs/steps. | Official endpoint returns timestamps, conclusions, steps, and attempts needed for the baseline. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2026-03-10] |
| GitHub Actions `GITHUB_STEP_SUMMARY` | GitHub-hosted runner facility | Run-local accessible summary mirror. | Per-step Markdown is grouped into the job summary after completion. [CITED: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jq` | 1.7.1 installed locally | Ad-hoc maintainer inspection only. | Do not make the canonical validator depend on it; Node is already provisioned in CI. [VERIFIED: local environment audit] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Checked-in NDJSON + generated Markdown | External CI observability vendor | Deferred by D-01/D-21; adds credentials, retention, and operational ownership. [VERIFIED: CONTEXT.md D-01, deferred ideas] |
| Node built-ins | New schema/CLI dependency | Adds supply-chain and availability work with no Phase 226 need. [VERIFIED: phase scope] |

**Installation:** No external packages. [VERIFIED: phase scope]

## Architecture Patterns

### System Architecture Diagram

```text
GitHub Actions API / CI runtime
   | run, attempt, job, step, cache/setup facts
   v
scripts/ci/collect_ci_baseline.mjs
   |-- reject non-comparable event/fingerprint/attempt --> reliability rows
   |-- normalize repeated matrix signature -------------> one root incident
   |-- calculate queue vs DAG wait / durations --------> schema-v1 NDJSON
   v
scripts/ci/render_ci_baseline.mjs ---------------------> 226-CI-BASELINE.md
   |                                                      (fact, state, owner,
   |                                                       next command, links)
   |-- validate fixtures & arithmetic -----------------> CI contract check
   v
live-stripe / host browser paths
   | provider counts + setup fact + raw conclusion
   v
if: always() job summary + linked Actions artifacts
```

### Recommended Project Structure

```text
.planning/phases/226-ci-baseline-proof-semantics/
├── 226-CI-BASELINE.ndjson        # frozen, sanitized canonical records
├── 226-CI-BASELINE.md            # generated maintainer reading surface
├── fixtures/                     # deterministic API/provider/setup cases
└── schema-v1.json                # explicit record contract
scripts/ci/
├── collect_ci_baseline.mjs       # API input → normalized records
├── render_ci_baseline.mjs        # records → Markdown
└── verify_ci_baseline.mjs        # schema, arithmetic, fixture validation
```

### Pattern 1: Raw Facts, Derived Facts, and Claims Are Separate

**What:** Preserve `job_conclusion` and timestamps as raw observations; calculate `runner_queue_ms`, `dag_wait_ms`, `duration_ms`, `rerun_count`, and `freshness`; derive `proof_state` only from explicit prerequisite/count predicates. [VERIFIED: CONTEXT.md D-04, D-05, D-08 through D-12]

**When to use:** Every baseline/provider/setup record, including failures and non-runs. [VERIFIED: CONTEXT.md D-04 and D-07]

**Example:**

```javascript
// Source: locked D-05 and D-08 semantics
const proofState = !laneSelected ? "non_run"
  : !configured || selected === 0 ? "misconfigured"
  : cancelledOrUpstreamBlocked ? "blocked"
  : intentionallyBypassed ? "skipped"
  : failed > 0 ? "failed"
  : passed === selected && manifestWritten ? "proved"
  : "misconfigured";

const runnerQueueMs = rootJob
  ? Date.parse(job.started_at) - Date.parse(run.created_at)
  : null;
const dagWaitMs = dependentJob
  ? Date.parse(job.started_at) - latestPrerequisiteCompletionMs
  : null;
```

### Pattern 2: Fingerprinted Cohorts, Not “Latest Green Runs”

**What:** Create a deterministic `cohort_fingerprint` from workflow file/config revision, event class, normalized branch class, runner image, required job-set/matrix fingerprint, and provider configuration class. Report fewer than 20 qualifying observations as `insufficient sample`; retain failures/cancellations/reruns in reliability records only. [VERIFIED: CONTEXT.md D-02 through D-04]

**When to use:** Before calculating p50/p95 or making any timing claim. [VERIFIED: CONTEXT.md D-03]

### Pattern 3: Provider Proof as a Typed State Machine

**What:** Store `{policy, proof_state, reason_code, raw_job_conclusion, selected_count, passed_count, skipped_count, manifest_url, latest_proved_sha, latest_proved_at, stale}`. Treat `stale` as a presentation calculation against a documented cadence + grace window, not an alternative state. [VERIFIED: CONTEXT.md D-08 through D-12]

**When to use:** All triggers: PR/push get explicit `non_run`; scheduled/manual executions produce `proved`, `failed`, `misconfigured`, `blocked`, or intentional `skipped`. [VERIFIED: CONTEXT.md D-10]

### Pattern 4: Ownership-First Setup Diagnostics

**What:** Have host scripts emit a redacted setup fact and stable failure code. The action summary places failure, owner, exact command, and artifact/log location before technical detail. [VERIFIED: CONTEXT.md D-14 through D-19]

**Anti-Patterns to Avoid**

- **Using job `success` as provider proof:** A skipped test suite can still leave a green job. Require selected tests, passing assertions, prerequisites, and an evidence manifest. [VERIFIED: CONTEXT.md D-09; current `mix test.live` skips without env]
- **Calling all pre-start delay “queue”:** Dependency wait begins after a job’s prerequisites finish; root-runner queue begins at workflow creation. Store both. [VERIFIED: CONTEXT.md D-05]
- **Checking raw logs/secret presence into git:** Keep only allowed fields and immutable artifact links. [VERIFIED: CONTEXT.md D-01 and D-06]
- **Fixing duplicate setup now:** Measure the duplicate Node/npm/Chromium provisioning and defer removal/caching to Phase 227. [VERIFIED: CONTEXT.md D-15 and D-18]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GitHub run/job/step timing transport | Log scraper or timestamp regexes | GitHub Actions REST jobs/run endpoints through `gh api` | The official response already carries structured run attempts, conclusions, job timestamps, and step timestamps. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2026-03-10] |
| Run-local status UI | Bespoke dashboard | `GITHUB_STEP_SUMMARY` Markdown table | It is native, accessible when literal state words are printed, and is shown on the run summary. [CITED: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions] |
| JSON schema parser dependency | New validation package | Explicit schema-v1 validator with Node built-ins | The record shape is small and deterministic; no installation is justified. [VERIFIED: phase scope] |

**Key insight:** The hard part is evidence semantics and cohort hygiene, not collection technology; a small validator is safer than a new reporting stack. [VERIFIED: CONTEXT.md D-01 through D-12]

## Common Pitfalls

### Pitfall 1: Mixing incomparable trigger topologies

**What goes wrong:** Schedule-only `live-stripe` runs take only the provider lane and will collapse full-CI timing statistics if mixed with PR/push/manual full runs. [VERIFIED: `.github/workflows/ci.yml` and CONTEXT.md D-02]

**How to avoid:** Include event/cohort fingerprints in each row; calculate only within one full-CI cohort. [VERIFIED: CONTEXT.md D-02 and D-03]

### Pitfall 2: Inflated incidents and percentile samples from reruns

**What goes wrong:** Attempt-level API results can represent the same triggering run/SHA more than once, and a repeated matrix signature can appear in multiple jobs. [CITED: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10]

**How to avoid:** Key reliability by original run identity + SHA, retain `run_attempt`, deduplicate green statistics to first successful attempts, and group matrix cells by normalized signature. [VERIFIED: CONTEXT.md D-04]

### Pitfall 3: Provider green that proves nothing

**What goes wrong:** Current `mix test.live` intentionally skips tests when relevant environment configuration is absent; its current documentation also describes the lane as advisory, which does not satisfy the new periodic proof contract. [VERIFIED: `accrue/mix.exs`, `accrue/test/live_stripe/*`, and `guides/testing-live-stripe.md`]

**How to avoid:** Add a provider preflight and manifest writer; on scheduled/manual runs turn missing configuration/fixtures or zero selected tests into `misconfigured` and a failing lane. [VERIFIED: CONTEXT.md D-09 through D-12]

### Pitfall 4: Host/CI ownership blurred by the wrapper

**What goes wrong:** CI runs Node provisioning and Chromium installation before invoking `accrue_host_uat.sh`, while the host’s browser script also executes `npm ci` and `npm run e2e:install`; missing tools can be misreported as browser-test failures. [VERIFIED: `.github/workflows/ci.yml` and `scripts/ci/accrue_host_verify_browser.sh`]

**How to avoid:** Preserve both paths this phase, emit ownership-tagged setup facts, and implement narrow preflight errors with the locked codes and commands. [VERIFIED: CONTEXT.md D-14 through D-18]

## Code Examples

### Collect structured job and step facts

```bash
# Source: GitHub Actions REST job endpoint
gh api \
  "/repos/${OWNER}/${REPO}/actions/runs/${RUN_ID}/jobs?filter=all&per_page=100" \
  --paginate > run-jobs.json
```

[CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2026-03-10]

### Produce an always-run literal summary

```yaml
- name: Provider proof summary
  if: always()
  run: node scripts/ci/render_provider_summary.mjs --record "$RUNNER_TEMP/provider-proof.json" >> "$GITHUB_STEP_SUMMARY"
```

The renderer must print literal `policy`, `proof_state`, counts, SHA, freshness, reason, artifact link, and exact next command; it must not emit values of secrets or provider payloads. [VERIFIED: CONTEXT.md D-12]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Job conclusion / skipped test output used informally as evidence | Independent policy, proof state, raw conclusion, counts, manifest, and freshness | Phase 226 locked decision | A green provider job cannot be misread as live proof. [VERIFIED: CONTEXT.md D-08 through D-13] |
| Single-run/partial timing snapshot | Fingerprinted 20-run rolling cohort plus frozen before-state | Phase 226 locked decision | Timing claims become comparable and Phase 227 can make a before/after decision. [VERIFIED: CONTEXT.md D-02 through D-05] |

**Deprecated/outdated:** Treating the documented skip-cleanly live Stripe suite as adequate periodic provider evidence is obsolete for this phase; preserve Fake proof but add provider preflight and state classification. [VERIFIED: CONTEXT.md D-09 through D-13]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A 48-hour provider freshness grace is a suitable default for a daily cadence. | Open Questions | It changes stale reporting only; planner must choose/document it. |

## Open Questions

1. **Provider freshness grace window**
   - What we know: The cadence must be documented and `stale` derived, but its exact grace window is discretionary. [VERIFIED: CONTEXT.md D-11]
   - What's unclear: The maintainer-approved tolerance for delayed scheduled Actions runs.
   - Recommendation: Start with a documented 48-hour grace, make it a schema/config constant, and label it `[ASSUMED]` until maintainer confirmation.

2. **Current cohort cardinality by fingerprint**
   - What we know: Recent Actions history contains multiple event classes and successful full runs, including the Phase 225 repair run and Phase 226 baseline branch runs. [VERIFIED: GitHub Actions API]
   - What's unclear: Whether any exact immutable fingerprint has 20 successful first-attempt full-CI observations in the rolling 90 days.
   - Recommendation: Have the collector calculate and record exact count/`insufficient sample`; do not infer it from the visible run list. [VERIFIED: CONTEXT.md D-03]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| GitHub CLI authenticated to repository | Historical run/job collection | ✓ | 2.95.0 | GitHub REST HTTPS API with Actions-read token. [VERIFIED: local environment audit] |
| Node.js | Collector, renderer, validator | ✓ | v22.14.0 | None needed; CI already pins Node 22. [VERIFIED: local environment audit and CI workflow] |
| npm | Existing host/Playwright contract | ✓ | 11.1.0 | None; existing CI contract needs it. [VERIFIED: local environment audit] |
| jq | Optional ad-hoc inspection | ✓ | 1.7.1 | Node built-in parser is canonical. [VERIFIED: local environment audit] |
| Stripe test-mode configuration | Actual provider proof execution | Unknown/secret-bound | — | `non_run` on unselected triggers; `misconfigured` and failing scheduled/manual lane when selected but incomplete. [VERIFIED: CONTEXT.md D-10] |

**Missing dependencies with no fallback:** None for the repository-owned evidence tooling. Provider credentials/fixtures are intentionally not audited or exposed; selected runs fail with a classified state when absent. [VERIFIED: CONTEXT.md D-06 and D-10]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node built-in assertions for collector fixtures; existing ExUnit and Playwright suites remain source proof. [VERIFIED: repository scan] |
| Config file | `examples/accrue_host/playwright.config.js`; `accrue_admin/playwright.config.js`; no root Node test config. [VERIFIED: repository scan] |
| Quick run command | `node scripts/ci/verify_ci_baseline.mjs --fixtures` |
| Full suite command | `node scripts/ci/verify_ci_baseline.mjs --fixtures && bash scripts/ci/verify_phase225_required_lane_evidence.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BASE-01 | schema, privacy allowlist, cohort exclusion, duration arithmetic, rerun and signature grouping | deterministic unit/fixture | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | ❌ Wave 0 |
| BASE-02 | every policy/state branch and no `success`→`proved` shortcut | deterministic unit/fixture | `node scripts/ci/verify_provider_proof.mjs --fixtures` | ❌ Wave 0 |
| OWN-01 | ownership matrix and each stable setup code returns owner/next command | deterministic integration/contract | `bash scripts/ci/verify_ci_setup_diagnostics.sh` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** relevant new fixture command plus `node --check` on changed `.mjs` files. [VERIFIED: project’s existing script-driven CI pattern]
- **Per wave merge:** all three Phase 226 verification commands. [VERIFIED: requirement coverage]
- **Phase gate:** Full Phase 226 validation green and frozen snapshot inspected before Phase 227 planning. [VERIFIED: CONTEXT.md D-01 through D-07]

### Wave 0 Gaps

- [ ] `scripts/ci/verify_ci_baseline.mjs` and fixtures — BASE-01
- [ ] `scripts/ci/verify_provider_proof.mjs` and fixtures — BASE-02
- [ ] `scripts/ci/verify_ci_setup_diagnostics.sh` — OWN-01

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Collection uses existing repository Actions-read access; do not introduce a new credential. [VERIFIED: `.github/workflows/ci.yml`] |
| V3 Session Management | no | No end-user sessions are in scope. [VERIFIED: phase scope] |
| V4 Access Control | yes | Keep workflow permissions read-only for collection; provider secrets remain Actions secrets and are never serialized. [VERIFIED: `.github/workflows/ci.yml` and CONTEXT.md D-06] |
| V5 Input Validation | yes | Strict schema-v1 allowlist, enum validation, timestamp arithmetic, and fixture tests. [VERIFIED: CONTEXT.md D-06 and D-07] |
| V6 Cryptography | no | Do not implement cryptography; use a non-secret deterministic signature normalization/hash only if needed. [VERIFIED: phase scope] |

### Known Threat Patterns for GitHub Actions evidence

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret or provider payload copied into checked-in evidence | Information disclosure | Allowlist fields; prohibit secret-presence details, logs, payloads, artifacts, actors, and raw branch names; test redaction fixture. [VERIFIED: CONTEXT.md D-06, D-12, D-17] |
| Green skipped provider job asserted as proof | Tampering | Derive typed proof only from selection, prerequisite, count, result, and manifest predicates. [VERIFIED: CONTEXT.md D-08 through D-10] |
| Artifact URL/content treated as stable checked-in data | Integrity | Store immutable link/ID only; artifacts stay Actions-owned forensic evidence. [VERIFIED: CONTEXT.md D-01] |
| Untrusted API data written directly into Markdown/JSON | Tampering | Normalize/allowlist identifiers and escape renderer output; never execute API field content. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/226-ci-baseline-proof-semantics/226-CONTEXT.md` — locked scope, schema semantics, privacy, provider states, and ownership decisions. [VERIFIED: codebase]
- `.github/workflows/ci.yml` — actual graph, stable job IDs, triggers, provider lane, caches, setup, and artifact behavior. [VERIFIED: codebase]
- `scripts/ci/accrue_host_uat.sh`, `scripts/ci/accrue_host_verify_browser.sh`, `examples/accrue_host/playwright.config.js` — current canonical host path and browser semantics. [VERIFIED: codebase]
- GitHub Actions run `31322443304` and jobs queried with authenticated `gh api` — first-attempt repair-run timing and dependency evidence. [VERIFIED: GitHub Actions API]

### Secondary (MEDIUM confidence)

- https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2026-03-10 — jobs, steps, timestamps, pagination, and historical attempts. [CITED: docs.github.com]
- https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10 — workflow runs and attempts. [CITED: docs.github.com]
- https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions — `GITHUB_STEP_SUMMARY` behavior. [CITED: docs.github.com]

### Tertiary (LOW confidence)

- None, except the explicitly logged renderer-escaping and 48-hour-grace assumptions.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new packages; existing CI runtime and official Actions endpoints were inspected.
- Architecture: HIGH — constrained by locked phase decisions and current workflow/scripts.
- Pitfalls: HIGH — confirmed against current skip behavior, CI graph, and Phase 225 evidence.

**Research date:** 2026-08-11
**Valid until:** 2026-09-10 (recheck GitHub API behavior and CI topology before implementation if delayed).
