# Phase 227: Measured Critical-Path Improvement - Research

**Researched:** 2026-08-12
**Domain:** GitHub Actions dependency-graph optimization with durable CI evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Optimization Target And Dependency Boundary
- **D-01:** Optimize dependency ordering first. Change `host-integration` so its only upstream required prerequisite is `docs-contracts-shift-left`; it must no longer wait indirectly for `release-gate` through `admin-drift-docs`.
- **D-02:** Keep release/admin proof and host/browser proof as independent required work that runs to completion even when another independent lane fails. `annotation-sweep` remains the final required fan-in and must continue to report the aggregate failure.
- **D-03:** Make this a one-edge optimization. Preserve the `host-integration → playwright-e2e` dependency and every other graph edge unless a later measured phase authorizes another change.

### Before/After Proof Bar
- **D-04:** Require three successful, first-attempt, same-event-class post-change runs. Compare them with the frozen compatible Phase 226 before cohort, retain every individual observation, and report the exact workflow fingerprint, sample count, range, and exclusions. Reruns are reliability evidence, not independent performance samples.
- **D-05:** Use staged critical-path duration—`release-gate` start through the latest `playwright-e2e` shard completion—as the primary success metric. Report removed `host-integration` DAG wait as causal evidence and whole-workflow wall time as supporting context.
- **D-06:** Keep the optimization only if the three-run post-change median is at least 20% faster than the Phase 226 before median of 2,083 seconds (a post-change median of at most 1,666 seconds after integer rounding). No post-change observation may exceed the Phase 226 p95 of 2,602 seconds unless the evidence pack identifies and substantiates an external anomaly.
- **D-07:** Preserve the Phase 226 baseline unchanged. Publish a separate Phase 227 evidence pack with concise maintainer-facing Markdown and sanitized machine-readable comparison records containing immutable run links, workflow/cohort fingerprints, individual measurements, exclusions, calculations, proof results, and rollback evidence.

### Negative Control, Stable Contracts, And Rollback
- **D-08:** Supply two complementary negative controls: (1) a deterministic repository verifier that asserts the intended graph and external evidence contract, and (2) a controlled failing fixture or Actions run proving `annotation-sweep` fails while independent host/browser work completes and retains its failure or success artifacts.
- **D-09:** Guard an exact contract manifest covering required job IDs and display names, release-matrix compatibility/support labels, provider policy/proof labels, artifact names, upload conditions, and retention. Explicitly additive Phase 227 evidence is allowed; removal, rename, weakening, or silent substitution is not.
- **D-10:** Trigger rollback if any required identity, artifact, proof state, or failure propagation changes; a negative control fails; a new deterministic failure appears; or the three-run median misses the 20% improvement bar.
- **D-11:** Rollback is the exact inverse dependency patch restoring the original `host-integration` edge, followed by the static/negative-control verifier and a fresh successful first-attempt CI run demonstrating that the prior graph and evidence contract are restored. Do not add a lasting feature switch for this single YAML edge.

### the agent's Discretion
- The researcher and planner may choose the Phase 227 evidence filenames, machine-readable schema details, verifier implementation, and controlled-failure seam, provided D-01 through D-11 remain true.
- They may define a narrow, evidence-based rule for substantiating an external timing anomaly. Runner variance alone is not enough to discard a post-change observation silently; all exclusions must remain visible.

### Deferred Ideas (OUT OF SCOPE)
- Moving duplicated static work out of release-matrix cells requires its own measured, proof-preserving change after this one-edge optimization.
- Consolidating host/browser provisioning may be considered in a later measured slice; Playwright browser caching remains disfavored unless new measurements contradict current official and Phase 226 evidence.
- Further graph changes, including parallelizing Playwright independently of host integration, require separate measurement and authorization.
- Matrix collapse, branch-protection changes, required-gate demotion, cache rewrites, test deletion/retry masking, StoreKit/iPhone/Crosswake work, and Admin UI ratchet work remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PATH-01 | Identify the measured path and exact selected cost with before evidence and rollback. | Frozen baseline, explicit one-edge graph delta, comparison record and inverse-patch procedure. |
| PATH-02 | Reduce measured wait/work without removing release, host, browser, or provider evidence. | Three-run first-attempt metric gate plus exact workflow-contract manifest. |
| SAFE-01 | Preserve stable required-check identity and artifacts while evaluating CI changes. | Manifest validates IDs, display names, matrix/provider labels, artifact names, conditions, and retention. |
| SAFE-02 | Supply negative control and rollback; never hide a failure with deletion/retry. | Static verifier plus controlled failing run/fixture and recorded restoration run. |
</phase_requirements>

## Summary

Phase 227 is a deliberately narrow DAG change, not a caching or test-suite project: replace `host-integration.needs: [admin-drift-docs, docs-contracts-shift-left]` with `host-integration.needs: [docs-contracts-shift-left]`. The current workflow keeps `admin-drift-docs` behind `release-gate`, then makes host work wait for it; `playwright-e2e` already correctly waits only for `host-integration`. [VERIFIED: codebase grep]

The frozen Phase 226 compatible cohort establishes the primary metric as release-gate start through the latest Playwright shard completion, with parallel shards unsummed; its p50 is 2,083 seconds and p95 is 2,602 seconds. The post-change evidence therefore needs exactly three successful, first-attempt compatible observations, all retained, and a median of at most 1,666 seconds. [VERIFIED: `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md`]

GitHub Actions treats `needs` as successful prerequisites, while a final job can use `if: always()` to run after all declared prerequisites regardless of conclusion. Preserve the existing independent lanes and final aggregation rather than making `host-integration` depend on a failing release lane or changing `annotation-sweep` fan-in. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

**Primary recommendation:** Implement one YAML-edge deletion, a dependency-free Node contract/evidence verifier, and a separate Phase 227 evidence pack; retain the frozen Phase 226 files byte-for-byte.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Job scheduling and dependency removal | CI workflow | — | `.github/workflows/ci.yml` owns `needs` and job execution order. [VERIFIED: codebase grep] |
| Check/artifact/provider identity preservation | CI workflow | Repository verifier | YAML declares the externally visible contracts; a deterministic verifier prevents accidental drift. [VERIFIED: codebase grep] |
| Timing collection and comparison | Repository CI tooling | GitHub Actions API | Existing Node tools collect sanitized job/run timing and render durable reports. [VERIFIED: `scripts/ci/collect_ci_baseline.mjs`] |
| Evidence-pack validation | Repository CI tooling | GitHub Actions artifacts | Checked-in sanitized facts are reviewable; raw forensic artifacts remain Actions-owned. [VERIFIED: `227-CONTEXT.md`] |
| Aggregate failure reporting | CI workflow | Repository annotation script | `annotation-sweep` is the final fan-in and runs the annotation script over all lanes. [VERIFIED: `.github/workflows/ci.yml`] |

## Project Constraints (from AGENTS.md)

`AGENTS.md` is absent. [VERIFIED: codebase file scan]

- Preserve the project’s CI posture: release, host, browser, provider proof, zero-retry behavior, and failure artifacts remain evidence, not optimization candidates. [VERIFIED: `CLAUDE.md`; `227-CONTEXT.md`]
- Use the established dependency-free Node ESM and shell-verifier patterns; do not add a package for workflow parsing or report generation. [VERIFIED: `scripts/ci/verify_ci_baseline.mjs`; `227-CONTEXT.md`]
- The repository has an unrelated untracked milestone-audit file; plans must not overwrite or rely on it. [VERIFIED: `git status --short`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GitHub Actions workflow YAML | Existing `actions/checkout@v6`, `upload-artifact@v7` | Owns job graph, stable checks, and artifact behavior. | No new action is needed for a `needs` edge deletion. [VERIFIED: `.github/workflows/ci.yml`] |
| Node.js built-ins | Installed v22.14.0 | Parse/read fixture data, assert static contracts, calculate comparison statistics, render Markdown. | Existing baseline verifier is dependency-free ESM using Node built-ins. [VERIFIED: `node --version`; `scripts/ci/verify_ci_baseline.mjs`] |
| Existing Phase 226 CI tools | Repository-local | Collect, render, and validate sanitized records and staged-path metrics. | Reuse preserves the frozen evidence grammar and trust boundary. [VERIFIED: `scripts/ci/{collect_ci_baseline,render_ci_baseline,verify_ci_baseline}.mjs`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GitHub CLI | Installed 2.95.0 | Trigger/view post-change and rollback Actions evidence. | Only for explicitly recorded live-run collection and verification. [VERIFIED: `gh --version`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Static manifest verifier | A YAML parsing dependency | Adds supply-chain scope and still cannot prove live job/artifact behavior; existing scripts already use deterministic text/fixture contracts. [VERIFIED: codebase grep] |
| Three independent first attempts | Reruns of a failed/slow run | GitHub supports reruns, but reruns are not independent performance observations under D-04. [CITED: https://docs.github.com/en/actions/how-tos/manage-workflow-runs] |

**Installation:** None. This phase must add no package or action. [VERIFIED: `227-CONTEXT.md`]

## Architecture Patterns

### System Architecture Diagram

```text
push / pull_request / workflow_dispatch
                |
                v
docs-contracts-shift-left -----> host-integration -----> playwright-e2e (matrix shards)
                |                         |                         |
                v                         |                         v
release-gate -> admin-drift-docs ---------+                         |
     |                                                              |
     +---------------- release/admin proof ------------------------+
                                                                    v
                           all required/advisory lane conclusions -> annotation-sweep

Phase 226 frozen baseline + 3 first-attempt post-change runs
        -> Phase 227 collector/comparison -> Markdown + NDJSON evidence pack
        -> static contract verifier + negative control -> keep or rollback
```

The diagram reflects the intended post-change graph: only the dashed conceptual dependency through `admin-drift-docs` is removed; `annotation-sweep` continues to wait for both independent lanes. [VERIFIED: `227-CONTEXT.md`; `.github/workflows/ci.yml`]

### Recommended Project Structure

```text
.planning/phases/227-measured-critical-path-improvement/
├── 227-CI-CRITICAL-PATH.md       # concise before/after and rollback report
├── 227-CI-CRITICAL-PATH.ndjson   # sanitized immutable observations/comparison
├── 227-ci-contract.json          # exact permitted workflow identity manifest
└── 227-VERIFICATION.md           # executed static, negative-control, live, rollback proof
scripts/ci/
└── verify_ci_critical_path.mjs   # dependency-free static/evidence verifier
```

These filenames are a prescriptive discretionary choice; keeping artifacts phase-local prevents mutation of the frozen Phase 226 before state. [VERIFIED: `227-CONTEXT.md`]

### Pattern 1: Independent required lanes with an explicit final fan-in

**What:** Permit host/browser work to start after its actual prerequisite, while the finalizer waits for every required/advisory lane and reports aggregate failure.

**When to use:** A prerequisite is only historical/organizational, not a data or safety dependency; all underlying proofs remain required at the final fan-in. [VERIFIED: `227-CONTEXT.md`]

**Example:**

```yaml
# Source: .github/workflows/ci.yml
host-integration:
  needs: [docs-contracts-shift-left]

playwright-e2e:
  needs: [host-integration]

annotation-sweep:
  needs: [release-gate, admin-drift-docs, host-integration, playwright-e2e]
```

Use the complete current `annotation-sweep.needs` list in implementation, not this abbreviated illustration. [VERIFIED: `.github/workflows/ci.yml`]

### Pattern 2: Immutable before state plus additive comparison record

**What:** Read Phase 226 NDJSON as input; write a new sanitized record per post-change run and derive results from all retained rows.

**When to use:** Any measurement claim controls whether a CI change is retained or reverted. [VERIFIED: `227-CONTEXT.md`]

**Example:**

```js
// Source: existing scripts/ci/verify_ci_baseline.mjs style
const beforeMedianSeconds = 2083;
const thresholdSeconds = 1666;
const post = firstAttemptSuccessfulCompatibleRuns;
assert.equal(post.length, 3);
assert.ok(median(post.map((row) => row.staged_path_seconds)) <= thresholdSeconds);
```

The final verifier must additionally compare fingerprint/event class, preserve run URLs and exclusion reasons, enforce the 2,602-second per-observation ceiling unless a documented external anomaly is substantiated, and validate the unchanged Phase 226 hash/content. [VERIFIED: `227-CONTEXT.md`]

### Pattern 3: Exact external-contract manifest and self-negative fixture

**What:** Put every stable job ID/display name, matrix/provider label, artifact name, upload condition, and retention value in a checked-in manifest; the verifier reads YAML/fixtures and rejects any removal, rename, weakening, or unexpected substitution.

**When to use:** CI labels and artifacts are externally consumed required-check contracts. [VERIFIED: `227-CONTEXT.md`]

**Anti-Patterns to Avoid**

- **Changing `annotation-sweep` to depend on fewer lanes:** This hides independent failures rather than shortening the staged path. [VERIFIED: `227-CONTEXT.md`]
- **Using `continue-on-error`, retries, or test deletion as a timing fix:** This violates the explicit evidence and zero-retry contract. [VERIFIED: `227-CONTEXT.md`]
- **Treating workflow wall time as the primary metric:** It confounds unrelated parallel work; staged release-to-latest-shard duration is the locked metric. [VERIFIED: `227-CONTEXT.md`]
- **Silently discarding slow post-change observations as runner variance:** Exclusions require a visible, externally substantiated cause. [VERIFIED: `227-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CI timing data model | A second run/job collector | Phase 226 collection/normalization and staged-path helpers | It already handles run attempts, immutable URLs, DAG waits, queue delay, fingerprints, and privacy constraints. [VERIFIED: `scripts/ci/collect_ci_baseline.mjs`; `scripts/ci/render_ci_baseline.mjs`] |
| Proof-state classification | A new provider-status interpretation | Existing provider proof verifier/manifest | It keeps `proved`, `skipped`, and advisory states literal. [VERIFIED: `scripts/ci/verify_provider_proof.mjs`; `227-CONTEXT.md`] |
| Workflow test framework | New test runner | Node built-in `assert`, temp fixtures, and one executable verifier | This is the established repository pattern and needs no dependency. [VERIFIED: `scripts/ci/verify_ci_baseline.mjs`] |

**Key insight:** the optimization is only credible when the measurement and safety proof reuse the same durable evidence boundary as Phase 226. [VERIFIED: `227-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Breaking failure propagation while removing a dependency

**What goes wrong:** Host/browser work starts earlier, but final failure aggregation loses an independent failed lane. [VERIFIED: `227-CONTEXT.md`]

**Why it happens:** `needs` controls both order and default success gating; a job dependent on a failed/skipped prerequisite is normally skipped unless its condition allows continuation. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

**How to avoid:** Change only `host-integration.needs`; assert the exact unchanged `annotation-sweep.needs` list and execute a failure control where annotation sweep fails after host/browser completion. [VERIFIED: `227-CONTEXT.md`]

**Warning signs:** A required job is skipped/cancelled, a finalizer job has fewer upstream IDs, or expected artifacts are absent. [VERIFIED: `227-CONTEXT.md`]

### Pitfall 2: Measuring reruns as fresh performance samples

**What goes wrong:** The apparent three-run cohort includes a retry/re-run and overstates reproducibility. [VERIFIED: `227-CONTEXT.md`]

**How to avoid:** Require run attempt 1, same event class, successful completion, compatible fingerprint, and one immutable run URL per observation; retain reruns only as reliability evidence. [VERIFIED: `227-CONTEXT.md`]

### Pitfall 3: Artifact proof becomes weaker by accident

**What goes wrong:** A renamed upload, changed `if`, `if-no-files-found`, or retention value leaves failures less recoverable. [VERIFIED: `227-CONTEXT.md`; `.github/workflows/ci.yml`]

**How to avoid:** Manifest every upload-artifact identity/condition/retention and assert both static YAML and the controlled run’s available artifacts. GitHub permits artifact-specific retention settings, so retention must be treated as part of the contract. [CITED: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts]

### Pitfall 4: Overfitting the baseline

**What goes wrong:** A faster whole workflow is claimed even though the locked staged path did not improve, or a changed workflow fingerprint makes runs non-comparable. [VERIFIED: `227-CONTEXT.md`]

**How to avoid:** Gate on staged duration; report whole-workflow wall time only as context; reject incompatible fingerprints and list every exclusion. [VERIFIED: `227-CONTEXT.md`]

## Code Examples

### Static graph and evidence-contract assertion

```js
// Source: repository pattern in scripts/ci/verify_ci_baseline.mjs
assert.deepEqual(workflow.jobs["host-integration"].needs, ["docs-contracts-shift-left"]);
assert.deepEqual(workflow.jobs["playwright-e2e"].needs, ["host-integration"]);
assert.deepEqual(workflow.jobs["annotation-sweep"].needs, manifest.annotationSweepNeeds);
assert.deepEqual(extractArtifactContracts(workflow), manifest.artifacts);
```

Implementation should parse only the constrained workflow constructs it validates or use existing project-native textual fixture patterns; it must not introduce a dependency merely to parse one known YAML file. [VERIFIED: `227-CONTEXT.md`; `scripts/ci/verify_ci_baseline.mjs`]

### Recorded keep/rollback calculation

```js
const postDurations = records.map(({ staged_path_seconds }) => staged_path_seconds);
const medianSeconds = median(postDurations);
const exceedsBeforeP95 = postDurations.some((seconds) => seconds > 2602);

const keep = records.length === 3 &&
  medianSeconds <= 1666 &&
  (!exceedsBeforeP95 || records.every(hasSubstantiatedExternalAnomaly)) &&
  staticContractPasses && negativeControlPasses;
```

The report must show the raw values, range, median, fingerprints, links, exclusions, and whether the inverse YAML patch was executed/verified when `keep` is false. [VERIFIED: `227-CONTEXT.md`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ad hoc CI speed claims | Phase 226 frozen, repository-bound sanitized timing baseline | Phase 226, 2026-08-12 | Phase 227 can make a falsifiable before/after claim. [VERIFIED: `226-CI-BASELINE.md`] |
| Implicit release → host serialization | Explicitly measured one-edge dependency removal | Phase 227 scope | Starts host/browser work after its actual docs-contract prerequisite without reducing final proof coverage. [VERIFIED: `227-CONTEXT.md`] |

**Deprecated/outdated:**

- Broad cache/matrix/branch-protection changes in this phase: explicitly out of scope until this one-edge experiment is proven. [VERIFIED: `227-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The controlled failure uses an isolated temporary evidence branch from the exact candidate commit, with one transient success-returning annotation-emission step in an already-successful independent required lane; the candidate branch is never mutated and the temporary branch is removed after automated evidence verification. | Open Questions (RESOLVED) | The seam matches the repository's existing annotation-sweep behavior and Plan 02's bounded branch procedure. |
| A2 | A timing outlier is excludable only when its observation is tied to an externally corroborated GitHub incident/status event or explicit runner/infrastructure failure evidence. | Open Questions (RESOLVED) | Ordinary runner variance and an unexplained slow run remain eligible observations and cannot be excluded. |

## Open Questions (RESOLVED)

1. **Controlled failure seam selection**
   - What we know: The negative control must prove `annotation-sweep` fails while independent host/browser work completes and keeps artifacts. [VERIFIED: `227-CONTEXT.md`]
   - Resolution: Use an isolated temporary evidence branch from the exact candidate commit. Add one transient step in an already-successful independent required lane that emits the uniquely named Phase 227 test annotation while returning success; dispatch that branch, verify the immutable run automatically, then remove the branch. The candidate branch and normal push/pull-request behavior never contain the control mutation. [RESOLVED: Plan 02 temporary-branch procedure]

2. **External timing anomaly standard**
   - What we know: Runner variance alone cannot justify exclusion. [VERIFIED: `227-CONTEXT.md`]
   - Resolution: Allow exclusion only when the observation is tied to an externally corroborated GitHub incident/status event or explicit runner/infrastructure failure evidence for that run. Retain the raw observation and its corroboration in the durable record. Ordinary runner variance and an unexplained slow run are not excludable. [RESOLVED: D-06 discretionary anomaly rule]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Static verifier and evidence rendering | ✓ | v22.14.0 | — [VERIFIED: `node --version`] |
| GitHub CLI | Recorded Actions run/artifact evidence | ✓ | 2.95.0 | GitHub web/API, but CLI is the established local path. [VERIFIED: `gh --version`] |
| GitHub Actions access/authentication | Three post-change runs and rollback run | Unknown in this session | — | Human maintainer triggers/records runs if local auth lacks repository authority. [ASSUMED] |

**Missing dependencies with no fallback:** None detected locally; live CI execution still requires repository Actions authority. [ASSUMED]

**Missing dependencies with fallback:** None. [VERIFIED: local environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node built-in assertions plus shell workflow contracts. [VERIFIED: `scripts/ci/verify_ci_baseline.mjs`] |
| Config file | None at repository root; CI verifier is executable. [VERIFIED: codebase file scan] |
| Quick run command | `node scripts/ci/verify_ci_critical_path.mjs --fixtures` |
| Full suite command | `node --check scripts/ci/verify_ci_critical_path.mjs && node scripts/ci/verify_ci_critical_path.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path --expected-repository szTheory/accrue && node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PATH-01 | Exact graph delta, frozen before-state, calculation, inverse patch/rollback record | static + fixture + recorded live evidence | `node scripts/ci/verify_ci_critical_path.mjs --fixtures` | ❌ Wave 0 |
| PATH-02 | Three compatible first attempts meet threshold without proof removal | comparison fixture + recorded live evidence | `node scripts/ci/verify_ci_critical_path.mjs --evidence .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson` | ❌ Wave 0 |
| SAFE-01 | IDs, display names, matrices/provider labels, artifacts, conditions, retention unchanged | static manifest contract | `node scripts/ci/verify_ci_critical_path.mjs --fixtures` | ❌ Wave 0 |
| SAFE-02 | Failing lane retains independent host/browser completion and artifacts; inverse patch restores graph | fixture + controlled Actions run + rollback record | `node scripts/ci/verify_ci_critical_path.mjs --fixtures` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `node scripts/ci/verify_ci_critical_path.mjs --fixtures`
- **Per wave merge:** Full suite command above.
- **Phase gate:** Static contract, controlled negative control, three qualifying first attempts, and rollback-result record all pass before verification.

### Wave 0 Gaps

- [ ] `scripts/ci/verify_ci_critical_path.mjs` — exact graph, manifest, comparison, and rollback verifier.
- [ ] `.planning/phases/227-measured-critical-path-improvement/227-ci-contract.json` — stable external-contract manifest.
- [ ] `227-CI-CRITICAL-PATH.ndjson` and `227-CI-CRITICAL-PATH.md` — separate post-change evidence pack.
- [ ] Controlled failure procedure/fixture and a recorded immutable Actions result.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase does not add an application identity flow. [VERIFIED: phase scope] |
| V3 Session Management | No | Phase does not alter application sessions. [VERIFIED: phase scope] |
| V4 Access Control | Yes | Preserve protected required check identities and final failure propagation; do not weaken gates. [VERIFIED: `227-CONTEXT.md`] |
| V5 Input Validation | Yes | Fail closed on workflow text, manifest, evidence schema, attempts, URLs, and arithmetic. [VERIFIED: `scripts/ci/verify_ci_baseline.mjs`; `227-CONTEXT.md`] |
| V6 Cryptography | No | No cryptographic implementation is in scope. [VERIFIED: phase scope] |

### Known Threat Patterns for GitHub Actions evidence

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Required check/artifact rename or condition weakening | Tampering | Exact manifest and static verifier, then live artifact inspection. [VERIFIED: `227-CONTEXT.md`] |
| Failed lane masked by dependency/cancellation semantics | Repudiation | Final fan-in preserves all lane IDs; controlled negative control proves aggregate failure. [VERIFIED: `227-CONTEXT.md`] |
| Forged or incomparable timing claim | Tampering | Repository-bound immutable URLs, first-attempt/fingerprint checks, visible exclusions, frozen before hash. [VERIFIED: Phase 226 verifier pattern; `227-CONTEXT.md`] |
| Sensitive CI content written into durable report | Information Disclosure | Reuse Phase 226 sanitized record model; link Actions artifacts instead of embedding raw logs. [VERIFIED: `226-CI-BASELINE.md`; `227-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) - current graph, check identities, final fan-in, and artifact contracts.
- [`227-CONTEXT.md`](227-CONTEXT.md) - locked D-01 through D-11 scope and acceptance bar.
- [`226-CI-BASELINE.md`](../226-ci-baseline-proof-semantics/226-CI-BASELINE.md) - frozen before-state and staged-path statistics.
- [`scripts/ci/`](../../../scripts/ci/) - existing collector, renderer, provider, and deterministic verifier conventions.

### Secondary (MEDIUM confidence)

- [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) - `needs` and `always()` semantics.
- [GitHub artifact retention](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts) - retention behavior.
- [GitHub workflow-run management](https://docs.github.com/en/actions/how-tos/manage-workflow-runs) - rerun behavior.

### Tertiary (LOW confidence)

- None; the two implementation-discretion questions are resolved above.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - no new stack; repository-local tooling and installed runtime verified.
- Architecture: HIGH - the exact permitted graph change and evidence requirements are locked in CONTEXT.md and observable in CI YAML.
- Pitfalls: HIGH - failure/artifact and measurement risks are explicitly recorded in locked decisions; GitHub dependency semantics are documented.

**Research date:** 2026-08-12
**Valid until:** 2026-09-11 (reconfirm live Actions behavior before executing a later phase).
