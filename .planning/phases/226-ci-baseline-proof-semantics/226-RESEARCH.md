# Phase 226: CI Baseline & Proof Semantics - Research

**Researched:** 2026-08-09
**Domain:** GitHub Actions timing baselines, CI proof semantics, and Playwright setup ownership
**Confidence:** HIGH for repository evidence; MEDIUM for external API/tooling guidance.

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| BASE-01 | Durable, privacy-safe comparable-run baseline with timing, rerun, cache, setup, provider, and failure data. | A checked-in baseline document plus a reproducible metadata collector can use Actions run/job/artifact APIs without downloading logs. |
| BASE-02 | Required, skipped, and advisory evidence is visibly distinct. | Current workflow names, matrix `support`, `continue-on-error`, job conclusions, and `if:` conditions provide the source facts; the baseline needs an explicit proof-state vocabulary. |
| OWN-01 | Host maintainers can identify Node/browser/Playwright ownership and diagnose setup failures. | CI YAML and host README/script establish distinct CI provision and host-local bootstrap paths; the baseline/runbook should link both. |

## Project Constraints (from CLAUDE.md)

- Preserve the Elixir/Phoenix monorepo shape and its shared `.github/workflows/` CI.
- Do not weaken webhook, PII, or observability boundaries; sensitive Stripe fields are never logged.
- Preserve the release model’s meaningful CI assertions and stable proof paths.
- Core remains LiveView-runtime-free; browser work belongs to the host/admin proof surfaces.
- Follow the existing use of GitHub Actions artifacts for raw failure evidence, not committed raw logs.

## Summary

Phase 226 should create a **versioned, privacy-safe baseline record** for a small, explicitly comparable run cohort and a deterministic collector/contract for refreshing it. The immediate anchor is CI run `31322443304`: a first-attempt `workflow_dispatch` at repair SHA `ee940cf9e1f86b4d7c551b15ce113feb7f2a2997`, completed successfully on 2026-08-09. [VERIFIED: GitHub Actions API run 31322443304] Phase 225 already established why this is eligible proof: event, SHA, required/advisory classification, stable job identities, and artifact identities were independently recorded. [VERIFIED: .planning/phases/225-required-lane-signal-repair/225-03-SUMMARY.md]

The measured release-critical chain is not the roadmap’s tentative 33–36 minutes: its wall time is **39m40s** (15:56:11–16:35:51 UTC), and the dependency chain through the latest required release cell, `admin-drift-docs`, `host-integration`, and the slowest Playwright shard is about **39m36s**. The critical release cell began 11 seconds after run creation, so this sample does not support runner queueing as the main cause. [VERIFIED: GitHub Actions API run/job timestamps for 31322443304] Phase 226 must record this contrary result rather than optimize against the unmeasured assumption.

**Resolved implementation policy:** Add a metadata-only collector and a committed baseline/runbook that classify each job as `proved`, `skipped`, `advisory`, or `not-applicable`; use the Phase 225 repair run as the first datum, then require exactly two more fresh, first-attempt, same-workflow-shape green `workflow_dispatch` runs before Phase 227 chooses an optimization. Publish the post-Plan-01 commit to a dedicated remote branch named `phase-226-baseline-<12-char-SHA>`, verify that branch resolves remotely to the full local SHA, dispatch both runs from that branch, and require each provider-reported `head_sha` to equal the verified remote SHA. This three-run, dispatch-only policy is accepted for Phase 226; PR runs, reruns, historical dispatches, and replacement runs after a failed candidate are ineligible.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Capture run, job, step, attempt, and artifact metadata | CI / GitHub Actions API | Repository script | The provider owns timestamps/conclusions; a repo script makes collection repeatable. |
| Preserve durable baseline and proof taxonomy | Repository documentation | CI contract script | Checked-in documentation is reviewable; a contract prevents category/name drift. |
| Decide required/advisory/skipped proof state | CI workflow YAML | Baseline renderer | Workflow conditions and `continue-on-error` are authoritative; rendering must not reinterpret them. |
| Provision Node and Chromium in CI | CI workflow YAML | Actions runner | CI calls `actions/setup-node@v6`, `npm ci`, and Playwright install steps. |
| Bootstrap/diagnose host Playwright locally | Host README + `scripts/ci/accrue_host_verify_browser.sh` | Host maintainer environment | The host owns local Node/npm/browser availability, ports, database fixture, and server lifecycle. |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why standard |
|---|---:|---|---|
| GitHub CLI `gh` | 2.95.0 available | Query Actions run, job, and artifact metadata | Repository already uses `gh` in CI tooling; GitHub exposes read APIs for workflow runs/jobs. [VERIFIED: local `gh --version`; CITED: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28] |
| `jq` | 1.7.1 available | Reduce API JSON into a stable allowlisted record | Existing maintainer environment supports it; no new runtime dependency. [VERIFIED: local `jq --version`] |
| GitHub Actions REST API | versioned API | Run/job timestamps, steps, conclusions, attempt, and artifacts | Job responses contain timestamps and step details; attempt-specific job listing preserves rerun semantics. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28] |

### Supporting

| Tool | Purpose | When to use |
|---|---|---|
| `scripts/ci/annotation_sweep.sh` | Existing release-facing annotation taxonomy | Keep its advisory/ratchet exclusions synchronized with the baseline taxonomy. [VERIFIED: .github/workflows/ci.yml] |
| `scripts/ci/accrue_host_uat.sh` | Required host wrapper | Link it from the ownership diagnostics; do not duplicate host setup in a new script. [VERIFIED: scripts/ci/accrue_host_uat.sh] |
| `npm run e2e:install` | Host-local Chromium bootstrap | Use after `npm ci` for host browser diagnostics. [VERIFIED: examples/accrue_host/package.json] |

**Installation:** None. This phase should add no external package.

## Architecture Patterns

### System Architecture Diagram

```text
workflow_dispatch / pull_request / schedule
                 |
                 v
          GitHub Actions run metadata
                 |
     +-----------+------------+
     |                        |
     v                        v
run + attempt data       paginated jobs + steps + artifacts
     |                        |
     +-----------+------------+
                 v
    allowlist/filter (no logs, env, payloads, URLs with query strings)
                 v
  classify: proved | skipped | advisory | not-applicable
                 v
 checked-in baseline JSON/Markdown + maintenance runbook
                 v
 Phase 227 reads comparable cohort and selects one measured improvement
```

### Recommended Project Structure

```text
.planning/phases/226-ci-baseline-proof-semantics/
├── 226-CI-BASELINE.md            # human-readable comparable-run tables and conclusions
├── 226-CI-BASELINE.json          # allowlisted, machine-readable run/job/step facts
└── 226-SETUP-OWNERSHIP.md        # host vs CI matrix and failure diagnostics
scripts/ci/
├── capture_ci_baseline.sh         # metadata-only gh/jq collector
└── verify_ci_baseline_contract.sh # schema, taxonomy, and privacy guard
```

### Pattern 1: Comparable-run eligibility before aggregation

**What:** Treat runs as comparable only when all of these match: workflow name/file, triggering event, head SHA policy, attempt number, stable job-id topology, runner OS/image family, release matrix definitions, and relevant lockfile hashes. Store excluded runs with a reason rather than averaging them in. [VERIFIED: .github/workflows/ci.yml; CITED: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28]

**Use:** Start with the repaired first-attempt `workflow_dispatch` run. After Plan 01 is committed, push that exact commit to `refs/heads/phase-226-baseline-<12-char-SHA>`, prove `git ls-remote` returns the full commit SHA for that ref, and capture two additional fresh green first-attempt dispatches from the verified branch before computing median and range. The snapshot is comparable to the anchor only when the `.github/workflows/ci.yml` blob OID and the blob OIDs for `accrue/mix.lock`, `accrue_admin/mix.lock`, `accrue_admin/package-lock.json`, `examples/accrue_host/mix.lock`, `examples/accrue_host/package-lock.json`, and `examples/accrue_host/assets/package-lock.json` match the anchor commit. The only other successful dispatch currently visible (`28652090155`, 2026-07-03) predates this workflow shape and must be recorded as non-comparable, not used in the baseline. [VERIFIED: `gh run list --workflow ci.yml --event workflow_dispatch --status success`]

### Pattern 1a: Provider policy snapshot is authoritative for required checks

**Decision:** The authoritative GitHub-enforced required-check snapshot is the union of the effective ruleset response from `GET /repos/szTheory/accrue/rules/branches/main` and classic branch-protection status checks from `GET /repos/szTheory/accrue/branches/main/protection/required_status_checks`, captured with API version `2022-11-28`. Record response status plus allowlisted required-check names/app IDs; an empty rules response and classic-protection 404 mean GitHub currently enforces no required checks on `main`, not that workflow success or YAML comments imply protection. The 2026-08-09 read returned `[]` from effective rules and `404 Branch not protected` from classic protection. Workflow `support`, `continue-on-error`, job identity, and dependency edges remain the repository's proof taxonomy, but they are not represented as external branch protection unless the provider APIs say so.

**Required fields:**

```json
{
  "run": {
    "id": 31322443304,
    "event": "workflow_dispatch",
    "head_sha": "ee940cf9e1f86b4d7c551b15ce113feb7f2a2997",
    "attempt": 1,
    "created_at": "2026-08-09T15:56:11Z",
    "completed_at": "2026-08-09T16:35:51Z",
    "wall_seconds": 2380,
    "critical_queue_seconds": 11
  },
  "privacy": { "logs_downloaded": false, "env_values_recorded": false }
}
```

The collector should derive duration only from provider timestamps, set `critical_queue_seconds` to the latest start among roots on the required chain minus `created_at`, and retain `null` instead of fabricating a value when a provider omits a timestamp. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28]

### Pattern 2: Proof state is a typed fact, not a conclusion alias

Use the following immutable rendered fields per provider/job:

| State | Definition | Can satisfy release proof? | Current example |
|---|---|---|---|
| `proved` | Required job ran and concluded `success` on a qualifying run. | Yes | Floor, Primary, and Primary + OpenTelemetry release cells in run 31322443304. [VERIFIED: GitHub Actions API run 31322443304] |
| `skipped` | Job or step conclusion is `skipped`, including a relevance-gated or failure-only upload that did not run. | No | Clean-run Playwright report/traces uploads under `host-integration` were skipped. [VERIFIED: GitHub Actions API job 93270329839] |
| `advisory` | Job/lane is explicitly non-blocking (`continue-on-error`) even if it succeeds. | No | `Primary + Sigra [advisory]`; parked ratchet job. [VERIFIED: .github/workflows/ci.yml; VERIFIED: GitHub Actions API run 31322443304] |
| `not-applicable` | Event policy intentionally excludes the lane. | No | Default CI jobs use `if: github.event_name != 'schedule'`; scheduled `live-stripe` is a separate periodic lane. [VERIFIED: .github/workflows/ci.yml] |

Do not infer `proved` from workflow-level success, a green advisory cell, a skipped upload, or artifact presence. Store both workflow declaration (`required`/`advisory` policy) and observed conclusion (`success`/`skipped`/`failure`) so reviews can see why a lane is not proof.

### Pattern 3: Setup ownership matrix with first diagnostic command

| Surface | Owner | CI action | Host-local action | First failure diagnosis |
|---|---|---|---|---|
| Node runtime | CI | `actions/setup-node@v6` at Node 22 | Maintainer’s Node/npm installation | `node --version && npm --version`; then rerun `npm ci`. [VERIFIED: .github/workflows/ci.yml; VERIFIED: examples/accrue_host/README.md] |
| Playwright package lock | CI | `npm ci` before browser install | `cd examples/accrue_host && npm ci` | Lockfile/install error: remove only local `node_modules`, preserve lockfile, rerun `npm ci`. [VERIFIED: .github/workflows/ci.yml; VERIFIED: examples/accrue_host/README.md] |
| Chromium binary/system dependencies | CI | `npx playwright install --with-deps chromium` in admin lanes; host uses `npm run e2e:install` | `npm run e2e:install` installs Chromium only | `npx playwright install chromium`; on CI compare the separate install-step conclusion/duration. [VERIFIED: .github/workflows/ci.yml; CITED: https://playwright.dev/docs/ci] |
| Host app/database/fixture/server | CI + host script | Postgres service plus `accrue_host_uat.sh` | host provisions local Postgres and runs `mix verify.full` | Check port ownership, fixture seed, then server log from `accrue_host_verify_browser.sh`. [VERIFIED: scripts/ci/accrue_host_verify_browser.sh; VERIFIED: examples/accrue_host/README.md] |

### Anti-patterns to Avoid

- **Treating a rerun as a fresh repair proof:** retain `attempt` and reject attempts other than 1 for the clean baseline cohort; a rerun may be useful diagnostics but not replacement evidence. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28]
- **Equating cache restore duration with a cache hit:** capture `steps.<id>.outputs.cache-hit` when exposed, plus cache key and restore/save conclusion; short duration alone is not proof of a hit. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]
- **Counting skipped artifacts as missing release proof:** a clean failure-only upload can legitimately be skipped, but it must remain `skipped`, not `proved`. [VERIFIED: .github/workflows/ci.yml]
- **Turning the baseline collector into a log archive:** raw logs/traces/screenshots can include user data, server output, headers, payloads, or secrets. Keep only allowlisted metadata, artifact names/sizes/expiry, normalized root signature, and immutable URLs without secret query strings. [VERIFIED: .planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| CI timing telemetry | Instrumented timers around each shell step | GitHub Actions run/job/step timestamps | Provider timestamps cover queue, job, and step boundaries consistently. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28] |
| Browser provisioning | Custom Chromium download/cache logic | Playwright’s documented install command | Browser revision and OS dependencies must match the installed Playwright version. [CITED: https://playwright.dev/docs/ci] |
| Artifact preservation | Commit reports/traces/logs to git | Existing `actions/upload-artifact` paths and metadata links | Preserves raw evidence under Actions retention without introducing PII-bearing repository data. [VERIFIED: .github/workflows/ci.yml] |

## Measured Baseline: Run 31322443304

| Metric | Observed value | Interpretation |
|---|---:|---|
| Run wall time | 2,380s / 39m40s | Measured end-to-end wall time. |
| Earliest job queue delay | 2s | Created 15:56:11; earliest jobs started 15:56:13. |
| Required release-chain queue delay | 11s | OpenTelemetry required cell started 15:56:22. |
| Longest required release cell | 1,334s / 22m14s | Primary + OpenTelemetry; it gates `admin-drift-docs`. |
| Admin drift/docs | 202s / 3m22s | Runs after the release matrix. |
| Host integration | 544s / 9m04s | Runs after admin drift/docs. Its `Run host integration gate` consumed 470s. |
| Slowest Playwright shard | 239s / 3m59s | Runs only after host integration; shard 3 was slowest. |
| Final annotation sweep | 13s | Finishes after the relevant proof lanes. |

The required critical path is therefore `release-gate (OpenTelemetry) → admin-drift-docs → host-integration → playwright-e2e shard 3 → annotation-sweep`; it is staged work, not queue wait. [VERIFIED: .github/workflows/ci.yml dependency graph; VERIFIED: GitHub Actions API run/job timestamps for 31322443304]

### Cache and browser setup observations

- Required release cells skipped `Create accrue PLTs`, which is direct evidence that the `accrue` PLT restoration path was hit; each did create `accrue_admin` PLTs (265–274s), so that cache is a substantial measured cold/miss cost in this run. [VERIFIED: GitHub Actions API jobs 93267406379, 93267406378, 93267406381]
- Browser setup is not the critical-path driver in this sample: host Node setup was 2s, `npm ci` 3s, and Chromium 9s before a 470s host gate. Browser setup still must be recorded because it repeats in all browser-oriented jobs and can dominate on a cold or provider-regressed runner. [VERIFIED: GitHub Actions API job 93270329839]
- The baseline must label cache state `observed-hit`, `observed-miss`, or `unknown`; never claim a hit if only a restore step timestamp is available. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]

## Common Pitfalls

### Pitfall 1: Mixing incomparable runs

**What goes wrong:** A historical dispatch, pull request, schedule, rerun, or changed workflow topology is averaged with current runs.

**Avoidance:** Persist an eligibility record and exclusion reason for each candidate. The July dispatch is a useful historical reference but not a baseline member because it predates the current Phase 225 topology. [VERIFIED: `gh run list --workflow ci.yml --event workflow_dispatch --status success`]

### Pitfall 2: Losing the difference between skipped and advisory

**What goes wrong:** A non-running relevance gate or a non-blocking provider lane is presented as green proof.

**Avoidance:** Render policy state, observed conclusion, and proof state in separate columns. Require all three required release cells and required host/browser evidence for `proved` aggregate status. [VERIFIED: .github/workflows/ci.yml; VERIFIED: .planning/phases/225-required-lane-signal-repair/225-03-SUMMARY.md]

### Pitfall 3: Capturing unsafe evidence

**What goes wrong:** Collector downloads logs or serializes environment variables, URLs with signed parameters, test payloads, traces, screenshots, or server logs into planning files.

**Avoidance:** Make the collector API-only and field-allowlisted. Permit run ID, commit SHA, timestamps, job/step names/conclusions, duration, matrix labels, normalized signature ID, artifact name/size/expiry, and canonical Actions page URL. Reject values matching secret names, `github.token`, `STRIPE_*`, URLs with `?`, raw logs, and artifact content. [VERIFIED: Phase 225 incident privacy posture]

## Code Examples

### Metadata-only collection skeleton

```bash
# Source: GitHub Actions workflow runs/jobs REST API
run_id="$1"
gh run view "$run_id" \
  --json databaseId,workflowName,event,headSha,attempt,status,conclusion,createdAt,updatedAt,url \
  > "$tmpdir/run.json"

gh api "repos/szTheory/accrue/actions/runs/$run_id/attempts/1/jobs?per_page=100" \
  --paginate > "$tmpdir/jobs.json"

gh api "repos/szTheory/accrue/actions/runs/$run_id/artifacts?per_page=100" \
  --paginate > "$tmpdir/artifacts.json"

# Render only an explicitly allowlisted schema. Do not call job-log endpoints.
jq '{run: {id: .databaseId, event, headSha, attempt, createdAt, updatedAt, url}}' "$tmpdir/run.json"
```

The actual implementation should accept `owner/repo` from `git remote`, validate a first attempt rather than hard-code `1`, and use `mktemp`/cleanup. The official API exposes both normal and attempt-specific job-list endpoints. [CITED: https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| “Green CI” as a workflow-level assertion | SHA/event/attempt-bound run metadata plus job/step/artifact facts | A maintainer can distinguish a repair proof, a rerun, a skipped lane, and advisory evidence. [VERIFIED: Phase 225 summary and incident index] |
| Browser setup implied by a passing Playwright job | Separate Node, npm install, Chromium install, host seed/server, and test steps | Setup regressions can be attributed to CI provisioning or the host contract. [VERIFIED: .github/workflows/ci.yml; VERIFIED: scripts/ci/accrue_host_verify_browser.sh] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Baseline artifacts live in the Phase 226 directory rather than a long-lived CI evidence directory. | Project Structure | Future maintainers may want a promoted central index; Phase 227 must consume the committed Phase 226 path unless a later decision promotes it. |

## Resolved Questions

1. **RESOLVED — Cohort size, trigger, and ref policy:** The accepted cohort is the anchor plus exactly two new `workflow_dispatch` runs, all attempt 1. The new runs use the dedicated verified remote branch `phase-226-baseline-<12-char-SHA>` pointing to the exact post-Plan-01 commit. Eligibility requires provider `head_sha` equality plus exact anchor equality for the workflow blob and the six listed critical-chain lockfile blobs. A failed dispatched candidate is retained and halts the cohort; it is not replaced.
2. **RESOLVED — Branch-protection source of truth:** GitHub's effective branch-rules API and classic required-status-check protection API are authoritative for externally enforced checks. Capture both read-only responses for `main`, including explicit empty/404 state. The current snapshot has no provider-enforced required checks; YAML declarations remain the repository proof taxonomy only and must not be described as branch protection.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| `gh` | Actions metadata/artifact collection | ✓ | 2.95.0 | GitHub REST `curl` only if a maintainer supplies authenticated token handling. |
| `jq` | Deterministic JSON reduction | ✓ | 1.7.1 | Node 22 formatter, but avoid adding one unless needed. |
| Node/npm | Existing host/browser diagnostics | ✓ | Node 22.14.0 / npm 11.1.0 | None for Playwright diagnostics. |
| Docker | Existing host/Docker lanes only | ✓ | 29.5.2 | Not required to collect the baseline. |

**Missing dependencies with no fallback:** None for the proposed metadata collector.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Bash contract test plus live read-only `gh` smoke |
| Config file | none — add a dedicated contract script |
| Quick run command | `bash scripts/ci/verify_ci_baseline_contract.sh` |
| Full evidence command | `tmp_file="$(mktemp)" && trap 'rm -f "$tmp_file"' EXIT && bash scripts/ci/capture_ci_baseline.sh --run-id 31322443304 --output "$tmp_file" && bash scripts/ci/verify_ci_baseline_contract.sh --input "$tmp_file"` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| BASE-01 | Baseline schema contains allowlisted run/job/step/cache/artifact/root-signature data and rejects unsafe content. | contract | `bash scripts/ci/verify_ci_baseline_contract.sh` | ❌ Wave 0 |
| BASE-02 | Every lane has policy, observed conclusion, and `proved`/`skipped`/`advisory`/`not-applicable` state; advisory/skipped cannot satisfy aggregate proof. | contract | `bash scripts/ci/verify_ci_baseline_contract.sh` | ❌ Wave 0 |
| OWN-01 | Ownership runbook names CI and host bootstrap commands plus diagnostics for Node/browser/fixture/server failures. | contract | `bash scripts/ci/verify_ci_baseline_contract.sh` | ❌ Wave 0 |

### Wave 0 Gaps

- [ ] `scripts/ci/capture_ci_baseline.sh` — API-only collector with fixture mode for testability.
- [ ] `scripts/ci/verify_ci_baseline_contract.sh` — schema/taxonomy/privacy checks.
- [ ] `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.{md,json}` — initial measured cohort record.
- [ ] `.planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md` — host/CI ownership matrix and diagnostics.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes | Use existing `gh` authenticated session/read-only Actions permissions; never commit a token. |
| V3 Session Management | No | No application session handling is introduced. |
| V4 Access Control | Yes | Collector is read-only; do not require workflow write/rerun permission. |
| V5 Input Validation | Yes | Validate numeric run ID, trusted `owner/repo`, known job IDs/state enum, and exact JSON allowlist. |
| V6 Cryptography | No | No cryptographic operation is needed; do not hand-roll secret redaction. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Secret/PII copied from logs or artifacts | Information disclosure | Do not download logs/artifact archives; schema only permits metadata. |
| Artifact URL with bearer/signed query | Information disclosure | Store canonical Actions pages or artifact IDs, never URLs containing `?`. |
| Workflow job-name spoofing/drift | Tampering | Verify stable YAML job IDs and exact expected display-name patterns in a contract test. |
| Rerun presented as fresh proof | Repudiation | Store `event`, `head_sha`, `attempt`, and eligibility result per run. |

## Plan Recommendations

1. **Plan 226-01 — Establish collector, schema, and privacy contract.** Add a metadata-only `gh`/`jq` collector with fixture input, exact field allowlist, attempt/event capture, duration derivation, cache-state enum, and a negative test proving logs/env/query-string URLs are rejected. Keep raw artifacts in Actions.
2. **Plan 226-02 — Publish measured baseline and proof-state/ownership runbook.** Publish and verify the immutable post-Plan-01 cohort branch, capture run 31322443304, dispatch two comparison runs from that branch, verify their returned head SHA plus anchor workflow/lock blob equality, render the chain and cache/setup figures, make the 39m36 contrary result explicit, classify every required/advisory/skipped/not-applicable lane, and document Node/Playwright ownership diagnostics.
3. **Plan 226-03 — Bind durable docs to workflow semantics.** Add the contract to the existing shift-left or release-facing CI surface without changing required-check topology. Assert stable job IDs, matrix support labels, required/advisory taxonomy, artifact names, and ownership command references; preserve Phase 225’s proof semantics.

## Sources

### Primary

- GitHub Actions API run `31322443304` and its jobs/artifacts — concrete timing, step, attempt, conclusion, and artifact evidence. [VERIFIED]
- `.github/workflows/ci.yml` — matrix support policy, dependencies, runner setup, browser install, artifacts, and stable job IDs. [VERIFIED]
- `.planning/phases/225-required-lane-signal-repair/225-03-SUMMARY.md` and `225-CI-INCIDENTS.md` — current SHA-bound proof and privacy boundary. [VERIFIED]
- `scripts/ci/accrue_host_verify_browser.sh`, `scripts/ci/accrue_host_uat.sh`, and `examples/accrue_host/README.md` — host setup ownership and diagnostics. [VERIFIED]

### Secondary

- [GitHub workflow jobs REST API](https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28) — job/step timestamps and attempt-specific listing. [CITED]
- [GitHub workflow runs REST API](https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2022-11-28) — workflow run retrieval and filtering. [CITED]
- [GitHub dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching) — cache semantics. [CITED]
- [Playwright CI documentation](https://playwright.dev/docs/ci) — browser installation in CI. [CITED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all tools are installed and repository-native; external API semantics are cited.
- Architecture: HIGH — derived from current CI YAML and Phase 225 proof records.
- Pitfalls: HIGH — privacy and proof-state pitfalls are demonstrated by the current workflow/incident design.

**Research date:** 2026-08-09
**Valid until:** 2026-09-08, unless CI workflow topology, Actions APIs, or provider policy changes.
