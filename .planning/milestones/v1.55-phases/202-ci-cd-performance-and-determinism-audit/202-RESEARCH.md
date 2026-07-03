# Phase 202: ci-cd-performance-and-determinism-audit - Research

**Researched:** 2026-07-02  
**Domain:** GitHub Actions CI/CD performance, determinism, provider truth, and release automation audit  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Provenance for this entire section: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` [VERIFIED: codebase grep].

### Locked Decisions

## Implementation Decisions

### Research And Recommendation Method
- **D-01:** Discuss all four phase-gray areas as one coherent decision set: measurement boundary, recommendation stance, provider/determinism truth, and Phase 204 handoff shape.
- **D-02:** Use specialist research and local repo evidence to make one-shot recommendations. The user explicitly prefers not to review every tradeoff manually; downstream agents should treat the captured recommendations as locked unless new repo evidence contradicts them.
- **D-03:** Use Accrue's committed voice: measured, exact, Phoenix-native, durable, mechanism-led, and proof-checkable. Call out real CI risk plainly, but avoid hype, generic "best practice" claims, and public shaming.

### Measurement Boundary
- **D-04:** Phase 202 is **static-first and audit-only**. Static workflow/config/script inspection is sufficient to complete the phase when live run-history data is unavailable.
- **D-05:** The audit may include an **opportunistic read-only GitHub Actions run-history snapshot** when `gh` access is available. If collected, label it with collection date, branch/filter, run count, and whether it is partial. Do not treat a small snapshot as exhaustive p50/p95 truth.
- **D-06:** Missing or incomplete live metrics do **not** block Phase 202. Uncollected p50/p95 job duration, step timings, cache-hit state, flake/rerun rate, slowest tests, compile profile, Docker cold/warm duration, and provider proved-vs-skipped counts must stay in `Baseline Metrics Needed`.
- **D-07:** Dynamic claims need explicit labels. The audit can say static inspection suggests duplication, cache risk, or likely critical-path drag; it must not claim measured runtime savings, cache hit rates, or flake rates without collected evidence.

### Audit Stance And Target Pipeline Shape
- **D-08:** Be **blunt but measure-first**. Name duplicated CI work, skip-capable "mandatory" lanes, and release recovery order dependence as release-confidence debt, not just runtime cost.
- **D-09:** Do **not** recommend deleting, demoting, or making required gates optional from static inspection alone. First collect job duration, step timing, cache-hit state, flake/rerun rate, and proved-vs-skipped provider counts.
- **D-10:** Target pipeline recommendations should preserve high-value gates: docs/contracts, release manifest checks, core/admin/portal package gates, host deterministic proof, provider-parity truth, and release proof.
- **D-11:** The target pipeline shape should be: docs/contracts and release manifest stay PR-blocking; package lint/docs/audit/dialyzer run once on the primary cell; compatibility matrix cells run compile/test only where they prove supported Elixir/OTP/provider promises; host integration stays PR-blocking with one browser setup owner; Playwright keeps one PR browser proof and moves duplicate full-suite coverage to the sharded lane or main/schedule based on metrics; Docker smoke becomes path-aware or main-only if run data confirms a long tail; annotation sweep remains release-facing but must justify its critical-path cost.
- **D-12:** Release recovery should replace human package-order prose with machine preflight checks before downstream package publish. Phase 202 should recommend this as follow-up only; implementation belongs to a later hardening slice if Phase 204 ranks it.

### Provider And Determinism Truth
- **D-13:** Provider parity truth is binary: classify live provider lanes as **proved** only when CI actually runs against Stripe test mode with required secrets/fixtures. Missing secrets/fixtures must be classified as **skipped/not proved**, not green parity.
- **D-14:** Future CI work should either fail scheduled `live-stripe` early when required secrets/fixtures are absent, or rename it as advisory/skip-capable. The audit should present both paths and recommend choosing based on whether maintainers can guarantee Stripe test-mode credentials and fixtures.
- **D-15:** Fake-backed deterministic tests remain the merge-blocking default. Live Stripe belongs as a periodic/manual provider canary for API drift and provider-specific behavior, not as the primary contributor loop.
- **D-16:** Required matrix cells must materially change dependency, compile, or test behavior. Sigra remains advisory until resolvable; OpenTelemetry is required only if with/without cells prove distinct code paths. Label-only matrix cells should be renamed or redesigned.
- **D-17:** Cache, flake, and runtime claims must stay separated as static risk versus measured baseline. Cache recommendations should consider GitHub cache behavior and Playwright's guidance that browser-binary caching is often not worth it on Linux unless measured.

### Phase 204 Handoff Shape
- **D-18:** Optimize for both maintainer readability and Phase 204 consumption. Keep the CI/CD audit as a readable evidence-backed report, then end with a structured `Phase 204 Handoff` table.
- **D-19:** Each Phase 204 handoff row must include: area, evidence path, current risk, priority local to Phase 202, expected impact, tradeoff, implementation approach, verification, rollback, metric-needed status, and suggested milestone-slice fit.
- **D-20:** Phase 202 priorities are local CI/CD audit priorities, not final cross-audit roadmap ranking. Phase 204 decides final ordering after consuming Phases 201, 202, and 203.
- **D-21:** Avoid issue-ready implementation cards in Phase 202. The audit may outline patch strategy, but should not create implementation commitments before Phase 204 ranks cross-quality work.

### Developer Experience And JTBD Lens
- **D-22:** Treat UI/UX here as developer experience. The CI audit should serve the maintainer/reviewer/contributor jobs: "what failed?", "what does this gate prove?", "what should I run locally?", "is this provider parity actually proved?", and "what is safe to optimize later?"
- **D-23:** Prefer a small number of named, proof-checkable gates whose failures map to clear owners over many repeated matrix failures that all say the same thing. Hide CI internals from casual contributors where possible; expose exact mechanisms to maintainers.
- **D-24:** Keep the audit coherent with Accrue's stable-core posture: optimize proof honesty, release confidence, maintainer speed, and adopter trust. Do not use CI cleanup as a pretext for broad product behavior, UI, API, or schema work.

### the agent's Discretion
- The planner/researcher may choose the exact table layout and section ordering as long as D-01 through D-24 hold.
- The planner/researcher may collect a bounded read-only `gh` snapshot if credentials are already available; if not, continue with static evidence and keep the metric gaps explicit.
- The planner/researcher may tune wording to match `brandbook/voice.md`, but must not soften concrete risks into vague language.

### Deferred Ideas (OUT OF SCOPE)
- Any actual CI topology changes, branch protection changes, required-check changes, job finalizer work, reusable workflow extraction, cache changes, Docker layer-cache work, Playwright setup changes, or workflow path filters.
- Any live-Stripe behavior change: fail-on-missing-secrets, rename to advisory, summary emission, provider proved/skipped counter, or fixture/secrets management.
- Any Sigra/OpenTelemetry matrix redesign or optional-dependency compile/test implementation.
- Any release recovery preflight implementation in `publish-hex.yml`.
- Any public docs rewrite beyond what the Phase 202 audit recommends for follow-up hardening.
- Any UI/admin/portal design-system work.

### Reviewed Todos (not folded)
- `Shared page_header component for accrue_admin list pages` - UI/admin todo, likely resolved by v1.54 PageHeader work; not related to CI/CD audit scope.
- `White-label billing portal design system` - future portal/UI hardening candidate; not related to CI/CD audit scope.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Accrue is an Elixir/Phoenix billing library with sibling packages `accrue`, `accrue_admin`, and `accrue_portal`; GitHub Actions workflows are shared at repo root [VERIFIED: CLAUDE.md].
- Current project posture is stable-core / demand-driven expansion; v1.55 is audit-only maintenance/release-readiness/support-contract hardening, not feature implementation [VERIFIED: CLAUDE.md].
- Phase 202 must not change product behavior, public APIs, DB defaults, CI required-check topology, or release automation; it produces evidence-backed audit output only [VERIFIED: .planning/ROADMAP.md].
- Accrue voice must be measured, exact, Phoenix-native, durable, mechanism-led, and proof-checkable; avoid generic "best practice" claims without a mechanism [VERIFIED: brandbook/voice.md].
- Project-local skill directories `.claude/skills/` and `.agents/skills/` were absent or empty; no project skill rules need to be loaded [VERIFIED: codebase grep].
- The general GitHub workflow skill applies, but its preferred `scripts/ci_monitor.cjs` helper does not exist in this repo; the existing read-only helper is `scripts/ci/watch_ci.sh` and it requires `gh` auth [VERIFIED: codebase grep].

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CI-01 | Maintainer can see current CI workflow/job topology, trigger model, matrix shape, service usage, cache posture, and likely critical path in one document. | Use `.github/workflows/ci.yml` as the topology source, job `needs` as critical-path source, and other workflows as secondary topology [VERIFIED: codebase grep]. |
| CI-02 | The CI audit identifies duplicated setup, slow/static bottlenecks, flaky/determinism risks, cache risks, release risks, and provider-parity risks with repo evidence. | Use workflow lines for duplicated matrix/package/browser/Docker work, `scripts/ci` for local gate semantics, live-stripe tests for skip behavior, and release workflows for recovery order risk [VERIFIED: codebase grep]. |
| CI-03 | The CI audit recommends a target pipeline that preserves high-value gates while measuring before demoting or deleting checks. | Locked D-09/D-10/D-11 require preservation of high-value gates and measurement-before-demotion [VERIFIED: 202-CONTEXT.md]. |
| CI-04 | The CI audit classifies follow-up work by priority, expected impact, tradeoff, implementation approach, verification, and rollback. | End the audit with a `Phase 204 Handoff` table containing those fields plus metric-needed status and evidence path [VERIFIED: 202-CONTEXT.md]. |
| CI-05 | The CI audit records required baseline metrics still needing live GitHub run data rather than pretending static inspection is enough. | Keep p50/p95 duration, step timing, cache-hit state, flake/rerun rate, slowest tests, compile bottlenecks, Docker cold/warm, and provider proved-vs-skipped counts in `Baseline Metrics Needed` unless a bounded snapshot is collected [VERIFIED: 202-CONTEXT.md]. |
</phase_requirements>

## Summary

Plan Phase 202 as a document-production audit over checked-in GitHub Actions configuration, CI scripts, Mix aliases, test surfaces, provider-lane semantics, and release workflows [VERIFIED: codebase grep]. The implementation work should read and refine the seeded draft `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`, but the final audit must cite primary repo evidence rather than inheriting draft claims [VERIFIED: codebase grep].

The most important planning constraint is measurement honesty: static inspection can identify duplicated setup, likely critical path, skip-capable provider lanes, cache-risky areas, and release recovery risk, but it must not claim p50/p95, cache hit rate, flake rate, or runtime savings without a labeled GitHub run-history sample [VERIFIED: 202-CONTEXT.md]. GitHub CLI is installed and authenticated in this workspace, so an optional read-only run-history snapshot is feasible, but the plan must keep it bounded and partial if used [VERIFIED: gh CLI].

**Primary recommendation:** produce the final `202-CI-CD-PERFORMANCE-AUDIT.md` as a static-first, evidence-backed report with an optional read-only GitHub run snapshot, explicit `Baseline Metrics Needed`, and a structured Phase 204 handoff table; do not edit workflows, scripts, branch protection, package release automation, or test code in Phase 202 [VERIFIED: 202-CONTEXT.md].

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| CI topology and critical path audit | GitHub Actions workflow tier | Repository documentation | `.github/workflows/ci.yml` declares triggers, permissions, services, matrix cells, `needs`, and stable job IDs; docs only mirror this source [VERIFIED: codebase grep]. |
| Static duplicate-work detection | Repository script/config tier | GitHub Actions workflow tier | Duplicated work is visible by comparing CI steps with `scripts/ci` and Mix aliases, especially host browser setup and release-gate package checks [VERIFIED: codebase grep]. |
| Live run-history metrics | GitHub Actions API tier | Local `gh`/`jq` tooling | GitHub REST/job payloads expose job and step timestamps, and local `gh` auth can read them for bounded snapshots [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28] [VERIFIED: gh CLI]. |
| Provider parity truth | Test/provider lane tier | External Stripe test-mode service | `live-stripe` only proves Stripe test-mode parity when required secrets and fixtures exist; otherwise tests can skip [VERIFIED: codebase grep]. |
| Release recovery risk | Release workflow tier | Hex registry | `release-please.yml` enforces ordered linked publish, while `publish-hex.yml` recovery relies on human package-order prose and lacks machine upstream checks [VERIFIED: codebase grep]. |
| Phase 204 handoff | Planning artifact tier | Audit report tier | Phase 204 consumes the audit rows to rank follow-up work; Phase 202 priorities are local CI priorities, not final roadmap ranking [VERIFIED: 202-CONTEXT.md]. |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GitHub Actions workflow YAML | Current GitHub hosted service | CI/CD topology, job graph, service containers, matrix cells, permissions, and release workflows | The repository already uses GitHub Actions as the CI/CD source of truth [VERIFIED: codebase grep] and GitHub documents these workflow controls as first-class syntax [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]. |
| `gh` CLI | 2.95.0 | Optional read-only run list/job timing snapshot | Installed and authenticated with `repo`/`workflow` scopes in this workspace [VERIFIED: gh CLI]. |
| `jq` | 1.7.1 | Structured JSON reduction for `gh` output | Installed locally and avoids ad hoc parsing of GitHub API JSON [VERIFIED: environment probe]. |
| Existing `scripts/ci/*.sh` | Repo-local | Maintainer-facing gate map, host UAT, annotation sweep, release proof, and verifier scripts | The scripts are the project-owned CI mechanism surface and are cited by workflow steps and `scripts/ci/README.md` [VERIFIED: codebase grep]. |
| Mix / ExUnit | Mix 1.19.5, Elixir 1.19.5 / OTP 28 | Package-local tests, warning gates, slowest-test diagnostics, and xref diagnostics | All packages use Mix, and current local toolchain matches CI cell versions [VERIFIED: environment probe] [VERIFIED: codebase grep]. |
| Playwright | `@playwright/test` 1.57.0 in host/admin package manifests | Browser proof lanes, sharding, trace/report output | Existing host/admin E2E suites already use Playwright [VERIFIED: codebase grep]; Playwright documents CI install and sharding patterns [CITED: https://playwright.dev/docs/ci] [CITED: https://playwright.dev/docs/test-sharding]. |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| GitHub REST Actions API | `2022-11-28` API version in docs | Read workflow runs/jobs and step timings | Use only for bounded run-history snapshots labeled by date, branch/filter, run count, and partial/exhaustive status [CITED: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28]. |
| Docker / Docker Compose | Docker 29.5.2 daemon available | Understand and optionally measure host Docker smoke cold/warm path | Use for measurement only if Phase 202 execution chooses local reproduction; static audit does not require Docker execution [VERIFIED: environment probe]. |
| Hex publish tooling | `mix hex.publish` from Hex docs; local Mix 1.19.5 | Release recovery risk analysis and dry-run preflight recommendations | Use in recommendations only; do not publish or change workflows in this phase [CITED: https://hex.pm/docs/publish]. |
| Stripe test mode | External service | Provider parity semantics for `live-stripe` | Use as provider-canary context; do not treat missing secrets/fixtures as green parity [CITED: https://docs.stripe.com/testing] [VERIFIED: codebase grep]. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `gh` + `jq` read-only snapshot | GitHub web UI manual inspection | UI inspection is harder to reproduce and weaker for Phase 204 handoff; use UI only if CLI auth breaks [ASSUMED]. |
| GitHub REST job timing | Scraping workflow logs | Logs are slower to parse and can redact or omit cache state; REST job payloads expose structured timing fields [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28]. |
| Existing Playwright CLI sharding | Custom browser test runner | Existing Playwright sharding is documented and already in use; custom orchestration adds low-value maintenance surface [CITED: https://playwright.dev/docs/test-sharding] [VERIFIED: codebase grep]. |
| Mix `--slowest` diagnostics | Hand-timed ExUnit wrappers | Mix already reports slowest tests/modules; custom wrappers are unnecessary for audit planning [VERIFIED: local mix help]. |

**Installation:**

```bash
# No new package installation is recommended for Phase 202.
```

**Version verification:** no new external packages are installed in this phase [VERIFIED: 202-CONTEXT.md]. Existing tool versions were probed locally: `gh 2.95.0`, `node v22.14.0`, `npm 11.1.0`, `Elixir 1.19.5`, `Mix 1.19.5`, `Docker 29.5.2`, `jq 1.7.1`, `python3 3.14.4`, and `curl 8.7.1` [VERIFIED: environment probe].

## Package Legitimacy Audit

This phase installs no external packages [VERIFIED: 202-CONTEXT.md].

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | - | - | - | - | - | No install |

**Packages removed due to [SLOP] verdict:** none [VERIFIED: no package install].  
**Packages flagged as suspicious [SUS]:** none [VERIFIED: no package install].

## Architecture Patterns

### System Architecture Diagram

```text
Checked-in workflow YAML
  -> static topology map
  -> job dependency graph from `needs`
  -> likely critical path and duplicated setup findings
  -> repo-evidence findings in 202-CI-CD-PERFORMANCE-AUDIT.md

Optional read-only GitHub run snapshot
  -> `gh run list` / `gh run view --json jobs`
  -> job and step timing sample
  -> clearly labeled partial metrics section
  -> remaining gaps in Baseline Metrics Needed

CI scripts + Mix aliases + package manifests
  -> gate ownership map
  -> determinism/flakiness/cache/provider/release risk analysis
  -> Phase 204 Handoff rows
```

This diagram is the recommended audit data flow, not an implementation change [VERIFIED: 202-CONTEXT.md].

### Recommended Project Structure

```text
.planning/phases/202-ci-cd-performance-and-determinism-audit/
├── 202-CONTEXT.md                    # locked phase decisions
├── 202-RESEARCH.md                   # this planning research
└── 202-CI-CD-PERFORMANCE-AUDIT.md    # final phase output to produce/refine
```

### Pattern 1: Static Evidence First

**What:** map the workflow from committed YAML and scripts before looking at run history [VERIFIED: 202-CONTEXT.md].  
**When to use:** every finding about topology, static critical path, duplicated setup, cache keys, skip-capable lanes, and release order risk [VERIFIED: codebase grep].  
**Example:**

```bash
rg -n "^[[:space:]]{2}[a-zA-Z0-9_-]+:|needs:|matrix:|continue-on-error|actions/cache|playwright|docker|live-stripe" .github/workflows/ci.yml
```

### Pattern 2: Metrics Labeled Separately

**What:** if a `gh` snapshot is collected, label collection date, branch/filter, run count, event types, conclusion mix, and partial/exhaustive status [VERIFIED: 202-CONTEXT.md].  
**When to use:** any p50/p95, job duration, step duration, cache-hit, flake/rerun, or provider proved-vs-skipped statement [VERIFIED: 202-CONTEXT.md].  
**Example:**

```bash
gh run list --workflow CI --branch main --limit 20 \
  --json databaseId,status,conclusion,createdAt,updatedAt,headBranch,event,url
```

### Pattern 3: Phase 204 Handoff Rows

**What:** each recommendation ends with structured ranking inputs for Phase 204 [VERIFIED: 202-CONTEXT.md].  
**When to use:** all recommended follow-up work, including baseline metrics, live provider truth, release-gate split, browser setup consolidation, Docker smoke policy, and release recovery guards [VERIFIED: 202-CONTEXT.md].  
**Example:**

```markdown
| Area | Evidence path | Current risk | Priority | Expected impact | Tradeoff | Implementation approach | Verification | Rollback | Metric-needed status | Suggested slice |
|------|---------------|--------------|----------|-----------------|----------|-------------------------|--------------|----------|----------------------|-----------------|
```

### Anti-Patterns to Avoid

- **Runtime claims from static YAML:** static inspection can identify likely drag but not measured p50/p95 or savings [VERIFIED: 202-CONTEXT.md].
- **Deleting gates from one run:** D-09 forbids deleting, demoting, or optionalizing required checks from static inspection alone [VERIFIED: 202-CONTEXT.md].
- **Treating skipped provider tests as proved parity:** live Stripe tests set skip tags when required secrets/fixtures are absent [VERIFIED: codebase grep].
- **Browser cache by default:** Playwright warns Linux browser-binary cache restore can be comparable to download time, so measure before recommending it [CITED: https://playwright.dev/docs/ci].
- **String parsing JSON:** use `gh --json` and `jq` for run/job payloads [VERIFIED: environment probe].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Workflow topology parsing | Custom YAML parser or regex-only "parser" | Read YAML directly plus `rg`/manual evidence table | Phase output is an audit document; full parser adds risk without implementation need [VERIFIED: 202-CONTEXT.md]. |
| Run history timing | Log scraper | `gh run list`, `gh run view --json jobs`, or GitHub REST Actions jobs endpoint | Job payloads contain job and step timestamps [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28]. |
| Test slowest list | Custom timers inside tests | `mix test --slowest N` and `--slowest-modules N` | Current Mix help documents these flags [VERIFIED: local mix help]. |
| Compile dependency audit | Manual import graph | `mix xref graph --format cycles --label compile-connected` and `--format stats` | Current Mix xref help documents compile-connected graph usage [VERIFIED: local mix help]. |
| Browser test parallelization | Custom sharder | Playwright `--shard=x/y` with GitHub matrix jobs | Playwright documents this exact pattern [CITED: https://playwright.dev/docs/test-sharding]. |
| Cache semantics | Homegrown cache invalidation scheme | GitHub `actions/cache` and explicit cache-key/restore-key review | GitHub caches are immutable once created, so key design is the control point [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]. |
| CI summaries | External dashboard | `$GITHUB_STEP_SUMMARY` for cheap Markdown summaries | GitHub workflow commands support job summaries [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands]. |
| Release recovery preflight | Human prose only | Machine checks around Hex version/order before publish | `publish-hex.yml` currently relies on input description prose for package order [VERIFIED: codebase grep]. |

**Key insight:** Phase 202 should improve the accuracy of the next plan, not the pipeline itself; every recommendation should preserve proof gates until metrics and Phase 204 ranking justify change [VERIFIED: 202-CONTEXT.md].

## Common Pitfalls

### Pitfall 1: Static Critical Path Overclaim
**What goes wrong:** the audit says a job is the measured bottleneck when only `needs` and step duplication were inspected [VERIFIED: 202-CONTEXT.md].  
**Why it happens:** YAML dependency order feels like runtime measurement but omits actual queue time, cache state, retries, and runner variance [ASSUMED].  
**How to avoid:** call it "likely critical path" unless a labeled run snapshot supports the duration claim [VERIFIED: 202-CONTEXT.md].  
**Warning signs:** p50/p95 or "saves X minutes" appears without collection date/run count [VERIFIED: 202-CONTEXT.md].

### Pitfall 2: Mandatory Live Stripe That Can Skip
**What goes wrong:** maintainers read green `live-stripe` as provider parity proved [VERIFIED: codebase grep].  
**Why it happens:** CI names the job mandatory periodic, while test modules mark themselves skipped when required secrets or price fixtures are missing [VERIFIED: codebase grep].  
**How to avoid:** classify scheduled provider output as `proved`, `skipped/not proved`, or `failed`, and recommend a future choice between fail-fast required secrets or advisory naming [VERIFIED: 202-CONTEXT.md].  
**Warning signs:** audit text says "live Stripe is green" without secrets/fixture evidence [VERIFIED: 202-CONTEXT.md].

### Pitfall 3: Repeating Package Gates Across Compatibility Cells
**What goes wrong:** format, docs, audit, docs, and dialyzer run in every release-gate matrix cell even when only compile/test compatibility differs [VERIFIED: codebase grep].  
**Why it happens:** a monolithic matrix is easy to reason about but expensive when every cell repeats non-compatibility work [VERIFIED: codebase grep].  
**How to avoid:** recommend single-run lint/docs/audit/dialyzer on the primary cell and compatibility cells that prove materially distinct behavior [VERIFIED: 202-CONTEXT.md].  
**Warning signs:** matrix labels change but dependency/test behavior does not [VERIFIED: 202-CONTEXT.md].

### Pitfall 4: Browser Setup Duplication
**What goes wrong:** the workflow installs Node/browser dependencies and Chromium, then delegated host/admin scripts do more browser setup [VERIFIED: codebase grep].  
**Why it happens:** workflow-level setup and script-level setup both try to own hermeticity [ASSUMED].  
**How to avoid:** recommend one browser setup owner, but implement only after metrics confirm cost and Phase 204 ranks the slice [VERIFIED: 202-CONTEXT.md].  
**Warning signs:** `npm ci` and `playwright install` appear in both workflow steps and a called script [VERIFIED: codebase grep].

### Pitfall 5: Cache Optimism
**What goes wrong:** the audit recommends caching Playwright browsers or Docker layers without knowing restore time, key churn, or stale binary risk [CITED: https://playwright.dev/docs/ci].  
**Why it happens:** "cache it" sounds universally beneficial but GitHub cache restore and Docker layer reuse are workload-dependent [ASSUMED].  
**How to avoid:** separate cache-risk findings from cache-change recommendations; require cache-hit state and cold/warm timings first [VERIFIED: 202-CONTEXT.md].  
**Warning signs:** no `cache-hit` or cold/warm field in baseline metrics [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching].

### Pitfall 6: Async/Partitioning Without State Classification
**What goes wrong:** tests become flaky after enabling async/partitioning broadly [ASSUMED].  
**Why it happens:** 215 test files declare `async: false`, 132 test files mutate Application env, and Fake processor/test DB state appears in shared setup [VERIFIED: codebase grep].  
**How to avoid:** recommend classification first; ExUnit says async should be enabled only when tests do not change global state [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html].  
**Warning signs:** proposal says "turn on async" without listing global env/Fake/DB isolation risks [VERIFIED: codebase grep].

### Pitfall 7: Release Recovery Order Prose
**What goes wrong:** manual recovery publishes `accrue_admin` or `accrue_portal` before upstream package versions are available on Hex [VERIFIED: codebase grep].  
**Why it happens:** `publish-hex.yml` encodes package order in the dispatch input description, not a machine preflight [VERIFIED: codebase grep].  
**How to avoid:** recommend future Hex prerequisite checks, but do not implement them in Phase 202 [VERIFIED: 202-CONTEXT.md].  
**Warning signs:** release workflow has `needs`, recovery workflow has only per-package `if` branches [VERIFIED: codebase grep].

## Code Examples

Verified patterns from local and official sources:

### Bounded CI Run Snapshot

```bash
gh run list --workflow CI --branch main --limit 20 \
  --json databaseId,status,conclusion,createdAt,updatedAt,headBranch,event,url
```

Source: GitHub CLI availability and auth were verified locally [VERIFIED: gh CLI]. GitHub run/job APIs support read access with Actions permission [CITED: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28].

### Job Duration Extraction

```bash
gh run view "$RUN_ID" --json jobs |
  jq -r '.jobs[] |
    [.name, .conclusion, .startedAt, .completedAt,
     ((.completedAt | fromdateiso8601) - (.startedAt | fromdateiso8601))]
    | @tsv'
```

Source: one successful run (`28538686414`) returned job and step timing fields with this shape [VERIFIED: gh CLI]. GitHub job payload docs show job and step `started_at` / `completed_at` fields [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28].

### Slowest ExUnit Diagnostics

```bash
cd accrue && mix test --slowest 20
cd accrue && mix test --slowest-modules 20
```

Source: current local `mix help test` documents `--slowest` and `--slowest-modules` [VERIFIED: local mix help].

### Compile Dependency Diagnostics

```bash
cd accrue && mix xref graph --format cycles --label compile-connected
cd accrue && mix xref graph --format stats --label compile-connected
```

Source: current local `mix help xref` documents compile-connected cycles/stats patterns [VERIFIED: local mix help].

### Phase 204 Handoff Row Shape

```markdown
| Area | Evidence path | Current risk | Priority local to Phase 202 | Expected impact | Tradeoff | Implementation approach | Verification | Rollback | Metric-needed status | Suggested milestone-slice fit |
|------|---------------|--------------|-----------------------------|-----------------|----------|-------------------------|--------------|----------|----------------------|-------------------------------|
```

Source: D-18 through D-21 require a structured Phase 204 handoff table [VERIFIED: 202-CONTEXT.md].

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Delete or demote slow checks from static inspection | Measure job/step timings, cache-hit state, flake/rerun rate, and provider proved-vs-skipped state first | Locked for Phase 202 on 2026-07-02 | Prevents runtime-cost guesses from weakening release confidence [VERIFIED: 202-CONTEXT.md]. |
| Monolithic compatibility matrix repeats every package gate | Run full lint/docs/audit/dialyzer once, and matrix only compatibility-proving compile/test cells | Target recommendation, not implemented | Preserves gate value while separating compatibility proof from repeated static checks [VERIFIED: 202-CONTEXT.md]. |
| "Green provider lane" as parity truth | Binary `proved` vs `skipped/not proved` vs `failed` provider state | Locked for Phase 202 on 2026-07-02 | Prevents skipped live-provider tests from inflating provider confidence [VERIFIED: 202-CONTEXT.md]. |
| Cache every heavy dependency | Measure cache hit, restore cost, and stale-risk before recommending cache changes | Current Playwright/GitHub guidance | Avoids cache thrash and misleading speed claims [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching] [CITED: https://playwright.dev/docs/ci]. |
| Human package-order recovery prose | Future machine preflight before downstream recovery publish | Target recommendation, not implemented in Phase 202 | Reduces linked-release recovery risk without changing release automation in the audit phase [VERIFIED: 202-CONTEXT.md]. |

**Deprecated/outdated:**
- Treating `live-stripe` as merge-blocking PR truth is out of scope and contrary to current Fake-backed deterministic merge-blocking posture [VERIFIED: 202-CONTEXT.md].
- Using unbounded or unlabeled run-history samples as p50/p95 truth is explicitly disallowed by D-05 and D-07 [VERIFIED: 202-CONTEXT.md].

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GitHub UI manual inspection is weaker than `gh`/REST JSON for reproducible Phase 204 handoff. | Standard Stack / Alternatives | Planner might over-prefer CLI even if UI screenshots are requested by a human reviewer. |
| A2 | Workflow/script owners duplicated browser setup because each layer tried to own hermeticity. | Common Pitfalls | Root cause wording could be wrong; evidence of duplication remains true. |
| A3 | Cache benefit is workload-dependent beyond the official Playwright warning. | Common Pitfalls / State of the Art | Planner should still require measurement before cache changes. |
| A4 | Broad async/partitioning can create flake when global state is mutated. | Common Pitfalls | ExUnit docs support the control, but exact Accrue flake risk needs measured/classified test evidence. |

## Open Questions (RESOLVED)

1. **What are the current branch-protection required checks?**
   - What we know: `ci.yml` comments list merge-blocking job IDs [VERIFIED: codebase grep].
   - What's unclear: live branch protection settings were not queried in this research [ASSUMED].
   - Recommendation: Phase 202 may mention required-check topology only as inferred from committed workflow comments unless a read-only branch-protection check is collected and labeled [VERIFIED: 202-CONTEXT.md].
   - RESOLVED: Treat branch protection as static-inferred from committed workflow comments for Phase 202 unless a separate read-only inspection is explicitly collected and labeled; this does not block the audit [VERIFIED: 202-CONTEXT.md].

2. **How many recent CI runs are representative enough for baseline metrics?**
   - What we know: `gh run list --workflow CI --limit 8` returned recent runs, but they mix schedule/push, success/failure, and post-stabilization states [VERIFIED: gh CLI].
   - What's unclear: appropriate p50/p95 needs a larger, filtered sample and possibly only successful push/PR runs [ASSUMED].
   - Recommendation: collect 20-50 runs if feasible; otherwise keep metrics in `Baseline Metrics Needed` [VERIFIED: 202-CONTEXT.md].
   - RESOLVED: Metrics-needed. Representative run sample size is intentionally deferred to `Baseline Metrics Needed`; Phase 202 can proceed with static findings and may only cite bounded snapshots as partial, non-authoritative evidence [VERIFIED: 202-CONTEXT.md].

3. **Do Sigra and OpenTelemetry matrix cells prove distinct behavior?**
   - What we know: CI sets `ACCRUE_CI_SIGRA`, `ACCRUE_CI_OPENTELEMETRY`, and `ACCRUE_OTEL_MATRIX`; `compile_matrix.sh` still documents older Sigra advisory assumptions; core `mix.exs` declares OpenTelemetry optional and not Sigra [VERIFIED: codebase grep].
   - What's unclear: whether each cell materially changes dependency, compile, or test behavior today [VERIFIED: 202-CONTEXT.md].
   - Recommendation: classify as matrix-fidelity research in the audit and do not implement matrix redesign in Phase 202 [VERIFIED: 202-CONTEXT.md].
   - RESOLVED: Matrix fidelity is an audit finding and verification target, not a blocker; Sigra remains advisory until resolvable, and OpenTelemetry should be treated as required only if with/without cells prove distinct code paths [VERIFIED: 202-CONTEXT.md].

4. **Are recent run timings stable enough to rank runtime work?**
   - What we know: one successful run showed release-gate cells around 15-16 minutes, host integration around 10.6 minutes, Docker smoke around 7.2 minutes, and Playwright shards around 3.8-4.5 minutes [VERIFIED: gh CLI].
   - What's unclear: this is one run only and must not be treated as p50/p95 [VERIFIED: 202-CONTEXT.md].
   - Recommendation: include it only as an optional partial snapshot if the implementation plan decides it improves the audit; otherwise use it as proof that the measurement method works [VERIFIED: gh CLI].
   - RESOLVED: Metrics-needed. Timing stability remains in `Baseline Metrics Needed`; the one-run data can support measurement feasibility but must not rank runtime work or imply p50/p95 stability [VERIFIED: 202-CONTEXT.md].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `git` | Static repo inspection | yes | 2.41.0 | - |
| `gh` | Optional run-history snapshot | yes | 2.95.0 | Use static evidence only, or GitHub web UI manually [VERIFIED: environment probe]. |
| GitHub auth | Optional run-history snapshot | yes | account authenticated with `repo` and `workflow` scopes | Static evidence remains sufficient [VERIFIED: gh CLI]. |
| `jq` | JSON reduction for `gh` output | yes | 1.7.1 | Use `python3 -m json.tool` or small read-only Python reducers [VERIFIED: environment probe]. |
| `node` / `npm` | Existing Playwright/package scripts and token harness context | yes | Node 22.14.0 / npm 11.1.0 | Static inspection if command execution is not needed [VERIFIED: environment probe]. |
| `elixir` / `mix` | Existing Mix aliases and diagnostics | yes | Elixir 1.19.5 / Mix 1.19.5 / OTP 28 | Static inspection if command execution is not needed [VERIFIED: environment probe]. |
| Docker daemon | Docker smoke context | yes | Docker 29.5.2 Linux daemon | Do not run local Docker metrics; leave cold/warm duration as baseline-needed [VERIFIED: environment probe]. |
| `python3` | Existing scripts and JSON helpers | yes | Python 3.14.4 | `jq` for most JSON tasks [VERIFIED: environment probe]. |
| `curl` | API fallback and Docker smoke HTTP checks | yes | 8.7.1 | `gh api` for GitHub API access [VERIFIED: environment probe]. |

**Missing dependencies with no fallback:** none for research/planning [VERIFIED: environment probe].

**Missing dependencies with fallback:** `scripts/ci_monitor.cjs` from the generic GitHub workflow skill is not present; use existing `scripts/ci/watch_ci.sh`, `gh run list`, or static evidence [VERIFIED: codebase grep].

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Documentation/static audit validation via shell, `rg`, and optional `gh` JSON; no new test framework [VERIFIED: .planning/config.json]. |
| Config file | `.planning/config.json` has `workflow.nyquist_validation: true` [VERIFIED: codebase grep]. |
| Quick run command | `test -s .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md && rg -n "Baseline Metrics Needed|Phase 204 Handoff|Static|GitHub" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` |
| Full suite command | `rg -n "CI-01|CI-02|CI-03|CI-04|CI-05" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md .planning/REQUIREMENTS.md` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CI-01 | Audit includes topology, triggers, matrix, services, cache posture, and likely critical path. | static doc check | `rg -n "Current Pipeline|Topology|trigger|matrix|service|cache|critical path" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | yes baseline draft [VERIFIED: codebase grep] |
| CI-02 | Audit identifies duplicated setup, bottlenecks, flake/determinism, cache, release, and provider risks with evidence. | static doc check | `rg -n "Duplicated|determinism|cache|release|provider|evidence" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | yes baseline draft [VERIFIED: codebase grep] |
| CI-03 | Audit recommends a target pipeline preserving high-value gates and measuring before demotion/deletion. | static doc check | `rg -n "Target Pipeline|measure|demot|delete|preserve|high-value" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | yes baseline draft [VERIFIED: codebase grep] |
| CI-04 | Audit includes follow-up classification with priority, impact, tradeoff, implementation, verification, rollback. | static doc check | `rg -n "Priority|Expected impact|Tradeoff|Implementation|Verification|Rollback|Phase 204 Handoff" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | partial baseline draft [VERIFIED: codebase grep] |
| CI-05 | Audit records baseline metrics still needing live GitHub run data. | static doc check | `rg -n "Baseline Metrics Needed|p50|p95|cache-hit|flake|proved|skipped" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | yes baseline draft [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** run quick static doc checks only; Phase 202 must not run full CI or edit CI [VERIFIED: 202-CONTEXT.md].
- **Per wave merge:** read the final audit once against CI-01 through CI-05 and ensure every dynamic metric claim is labeled as collected or baseline-needed [VERIFIED: 202-CONTEXT.md].
- **Phase gate:** `202-CI-CD-PERFORMANCE-AUDIT.md` exists, includes evidence paths, separates static findings from live metrics, and contains a Phase 204 handoff table [VERIFIED: .planning/ROADMAP.md].

### Wave 0 Gaps

- [ ] Final audit should add or verify a `Phase 204 Handoff` table if the seeded draft's recommendation table is not yet in the exact D-19 shape [VERIFIED: 202-CONTEXT.md].
- [ ] Final audit should explicitly label any `gh` run-history sample as partial and non-authoritative unless it meets the selected run-count/filter threshold [VERIFIED: 202-CONTEXT.md].
- [ ] Final audit should include a clear `Baseline Metrics Needed` section even if a small snapshot is collected [VERIFIED: 202-CONTEXT.md].

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No app auth changes; GitHub auth is read-only for optional metrics [VERIFIED: 202-CONTEXT.md]. |
| V3 Session Management | no | No runtime session changes [VERIFIED: 202-CONTEXT.md]. |
| V4 Access Control | yes | Preserve least-privilege GitHub token posture; current CI top-level permissions are read-only, while release workflow separately grants write permissions [VERIFIED: codebase grep]. |
| V5 Input Validation | yes | Treat `gh`/REST output as structured JSON through `jq`; do not eval or parse logs with shell interpolation [VERIFIED: environment probe]. |
| V6 Cryptography | no | No cryptographic implementation; do not handle Stripe or Hex secrets beyond classifying their presence/absence [VERIFIED: 202-CONTEXT.md]. |
| V10 Malicious Code / Supply Chain | yes | Review action pin posture, cache keys, release tokens, and publish recovery checks as CI supply-chain risk surfaces [VERIFIED: codebase grep]. |
| V14 Configuration | yes | Separate static workflow config truth from live branch-protection/run-history state [VERIFIED: 202-CONTEXT.md]. |

### Known Threat Patterns for GitHub Actions CI/CD

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overbroad workflow tokens | Elevation of privilege | Keep CI permissions read-only; isolate release workflows that need write permissions [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax] [VERIFIED: codebase grep]. |
| Skipped live-provider tests represented as parity | Repudiation | Emit or document proved/skipped/failure state; do not count missing secrets as green provider proof [VERIFIED: 202-CONTEXT.md]. |
| Cache poisoning or stale cache assumptions | Tampering | Key caches by OS/toolchain/lockfile and record `cache-hit`; GitHub caches are immutable, so new contents require new keys [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]. |
| Release recovery out of order | Tampering / Repudiation | Recommend future machine preflight checks that upstream Hex package versions exist before downstream publish [VERIFIED: codebase grep]. |
| Secret leakage in audit output | Information disclosure | Do not print token values, Stripe keys, or Hex API keys; only record whether required secrets/fixtures are present when run-history proves it [VERIFIED: 202-CONTEXT.md]. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` - locked phase decisions, discretion, deferred scope [VERIFIED: codebase grep].
- `.planning/REQUIREMENTS.md` - CI-01 through CI-05 descriptions and traceability [VERIFIED: codebase grep].
- `.planning/ROADMAP.md` - Phase 202 boundary, success criteria, and audit-only non-goals [VERIFIED: codebase grep].
- `.planning/STATE.md` - current v1.55 status and Phase 202 readiness [VERIFIED: codebase grep].
- `CLAUDE.md` and `brandbook/voice.md` - project posture, stack, workflow, and voice constraints [VERIFIED: codebase grep].
- `.github/workflows/ci.yml` - primary CI topology, matrix, services, cache posture, live-stripe lane, Docker smoke, annotation sweep [VERIFIED: codebase grep].
- `.github/workflows/release-please.yml` and `.github/workflows/publish-hex.yml` - release and recovery topology [VERIFIED: codebase grep].
- `scripts/ci/README.md`, `scripts/ci/accrue_host_uat.sh`, `scripts/ci/accrue_host_verify_browser.sh`, `scripts/ci/annotation_sweep.sh`, `scripts/ci/compile_matrix.sh`, `scripts/ci/watch_ci.sh` - gate map and local CI semantics [VERIFIED: codebase grep].
- `accrue/mix.exs`, `examples/accrue_host/mix.exs`, `accrue_admin/package.json`, `examples/accrue_host/package.json`, `accrue/test/live_stripe/*` - Mix aliases, Playwright scripts, and provider skip/proof behavior [VERIFIED: codebase grep].
- Local environment probes and bounded `gh` snapshot from 2026-07-02 - tool availability and one-run measurement feasibility [VERIFIED: environment probe] [VERIFIED: gh CLI].

### Secondary (LOW confidence by GSD classifier, official docs cited)
- GitHub workflow syntax - `needs`, matrix, permissions, services, continue-on-error [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax].
- GitHub dependency caching - cache keys, restore keys, immutable cache contents, cache-hit output [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching].
- GitHub REST Actions workflow runs/jobs - read-only run/job timing payloads [CITED: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28] [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28].
- GitHub workflow commands - `$GITHUB_STEP_SUMMARY` job summaries [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands].
- Playwright CI and sharding docs - install, browser cache caution, and `--shard=x/y` [CITED: https://playwright.dev/docs/ci] [CITED: https://playwright.dev/docs/test-sharding].
- ExUnit and Mix docs - async state guidance, test slowest/partition options, xref compile-connected graph usage [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html].
- Stripe testing docs - test API keys, test-mode rate-limit caution, Billing test clocks/sandboxes [CITED: https://docs.stripe.com/testing] [CITED: https://docs.stripe.com/billing/testing].
- Hex publish docs - package metadata, Hex dependencies, docs build/publish behavior [CITED: https://hex.pm/docs/publish].

### Tertiary (LOW confidence)
- Assumptions listed in the Assumptions Log [ASSUMED].

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new package installs; tools and repo surfaces are locally verified [VERIFIED: environment probe].
- Architecture: HIGH - workflow topology and script boundaries are visible in checked-in files [VERIFIED: codebase grep].
- Pitfalls: HIGH for repo-backed risks, MEDIUM for general CI causal explanations, LOW for assumptions explicitly listed [VERIFIED: codebase grep] [ASSUMED].

**Research date:** 2026-07-02  
**Valid until:** 2026-08-01 for local repo facts; 2026-07-09 for GitHub Actions/Playwright/GitHub API docs and run-history assumptions because CI/CD services and action versions can change quickly [ASSUMED].
