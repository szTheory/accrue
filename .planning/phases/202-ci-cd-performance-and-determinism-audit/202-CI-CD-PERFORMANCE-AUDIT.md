# CI/CD Performance and Determinism Audit: Accrue v1.55

**Date:** 2026-07-02  
**Status:** Final Phase 202 audit  
**Scope:** GitHub Actions workflows, `scripts/ci`, Mix aliases, package gates, host UAT, release/publish automation.

**Evidence mode:** Static repository inspection is the primary evidence source. A bounded read-only GitHub Actions snapshot was collected with `gh` on 2026-07-02T20:56:01Z for workflow `CI`, branch `main`, limit 10. That snapshot is partial run-history evidence, not an exhaustive baseline and not branch-protection truth.

## Executive Summary

Top recommended changes:

1. **Measure first:** add or collect job and step timings, cache-hit state, slowest tests, compile time, Docker cold/warm duration, and retry/failure history before deleting, demoting, or optionalizing required gates.
2. **Split compatibility from repeated package gates:** static inspection shows `release-gate` repeats core/admin/portal format, compile, test, audit, docs, and dialyzer across four matrix cells. The partial snapshot supports that this lane is a long leg of the current graph: in run `28538686414`, required `release-gate` cells ran about 15m44s to 16m13s.
3. **Consolidate host browser setup only after measurement:** CI installs Node and Chromium before `accrue_host_uat.sh`, while the delegated browser script runs `npm ci` and `npm run e2e:install` again. Static inspection suggests duplicated setup; exact savings are metrics-needed.
4. **Clarify provider/lane truth:** scheduled `live-stripe` is called mandatory, but test modules skip when required secrets or price fixtures are absent. Provider parity is proved only when Stripe test mode actually runs; skipped means not proved.
5. **Guard release recovery:** Release Please publishes `accrue`, then `accrue_admin`, then `accrue_portal` through job dependencies. Manual `publish-hex.yml` relies on human package-order prose and should get machine preflight checks in a later hardening slice.

Expected impact: faster PR feedback, less duplicated runner work, clearer red/green meaning, and lower release risk. The first implementation PR should be observability/baseline only. This phase changed no CI topology, required-check semantics, release automation, source code, DB defaults, public APIs, or UI behavior.

## Current Pipeline Map

| Workflow / job | Trigger | Job graph and matrix shape | Services and cache posture | Quality signal | Likely critical path and evidence boundary |
|---|---|---|---|---|---|
| `CI` workflow | push to `main`, pull request to `main`, `workflow_dispatch`, daily schedule | Required pull-request graph plus schedule/manual `live-stripe`; stable job-id comments list required checks | Global read-only permissions; job-local Postgres, BEAM caches, PLT caches, and npm caches | Merge and release confidence | Static inspection: the graph fans out early, then `host-integration` and `playwright-e2e` serialize before `annotation-sweep`. Branch-protection settings were not queried. |
| `release-manifest-ssot` | non-schedule `CI` | independent release manifest and linked-release contract check | no service; bash/jq file checks | Release version truth | Static inspection: short gate in partial snapshot, but release-critical and should stay PR-blocking. |
| `docs-contracts-shift-left` | non-schedule `CI` | serial bash support-contract, posture, docs, Docker DX, token determinism, and brand-token checks | Node 22 with npm cache for token harness | Docs, support-contract, and planning mirror drift | Static inspection: many serial shell checks; partial snapshot run `28538686414` completed this job in 19s, so not a measured bottleneck in that sample. |
| `release-gate` | non-schedule `CI` | four matrix cells: floor required, primary required, Sigra advisory, OpenTelemetry required | Postgres 15; per-cell BEAM deps caches; split restore/save PLT caches; admin/portal deps caches | Package format, compile, test, credo, dialyzer, docs, and audit across core/admin/portal | Static inspection: repeats high-cost package gates across cells. Partial snapshot: required cells ran about 15m44s to 16m13s. Metric-needed: step timing and cache-hit state per cell. |
| admin guardrails (`admin-group-contracts`, `admin-hardening-guardrails`, `admin-phase200-guardrails`) | non-schedule `CI` | separate admin browser/storybook/scorecard guardrail jobs | Postgres 15; Node/npm; BEAM deps; Chromium install in each browser lane | Admin UI regression and deterministic page-flow proof | Static inspection: duplicate browser setup and one-worker Playwright lanes preserve fidelity but add setup cost. Metric-needed: browser install and test step durations. |
| `host-integration` | after `admin-drift-docs` and `docs-contracts-shift-left` | one deterministic host proof: `mix verify.full`, host Hex smoke, Playwright artifacts on failure | Postgres 15; Node/npm cache; host deps cache; browser install before delegating to `accrue_host_uat.sh` | Phoenix host adoption proof, seeded trust lane, browser accessibility/responsive checks | Static inspection: canonical host proof and likely late critical-path leg. Partial snapshot: about 10m37s in run `28538686414`. |
| `playwright-e2e` | after `host-integration` | three shard matrix cells | Postgres 15 per shard; Node/npm cache; host deps cache; compile/build/seed/browser install in each shard | Full host browser coverage | Static inspection: duplicates setup in every shard. Partial snapshot: shards ran about 3m45s to 4m30s after host proof. |
| `host-docker-smoke` | non-schedule `CI`; after `docs-contracts-shift-left` | Docker compose cold boot and 900-second readiness loop | Docker build/cache behavior not summarized; no explicit layer cache | Docker evaluator boot proof | Static inspection: cold-build long-tail risk. Partial snapshot: about 7m13s in run `28538686414`, but cold/warm split is metrics-needed. |
| `annotation-sweep` | after release manifest, docs/contracts, release gate, tax gate, admin guardrails, host integration, Playwright, Docker smoke | single finalizer querying check annotations for release-facing jobs; advisory cells excluded by name | `gh` token/API access; no service | Release-facing warning/failure annotation gate | Static inspection: waits on almost every required lane, so any slow prerequisite delays it. Partial snapshot: finalizer itself was 14s. |
| `live-stripe` | `workflow_dispatch` and schedule only | single Stripe test-mode parity lane; no push/PR execution | Postgres 15; `STRIPE_TEST_SECRET_KEY`, `ACCRUE_LIVE_BASIC_PRICE`, `ACCRUE_LIVE_PRO_PRICE` from secrets | Provider API drift canary | Static inspection: mandatory periodic name but tests can skip without secrets/fixtures. Snapshot: latest successful push run recorded the job as skipped because event did not match; scheduled failures in the 10-run sample need separate job-log review before assigning cause. |
| `Release Please` workflow | push to `main`, manual bootstrap | release job, then ordered `publish-accrue` -> `publish-accrue-admin` -> `publish-accrue-portal`, then linked release proof | Postgres 16 in proof; Hex publish secrets; `gh`, `jq`, Hex and HexDocs checks | Ordered package release and linked proof | Static inspection: primary path encodes ordering and proof. Do not alter in Phase 202. |
| `Publish Hex Recovery` workflow | manual `workflow_dispatch` | one selected package per run | no inter-run dependency; each job verifies local `@version`, dry-runs, then publishes | Recovery publish path | Static inspection: input prose says run `accrue` before `accrue_admin` before `accrue_portal`; machine preflight ordering is absent and belongs to Phase 204-ranked follow-up. |

## Baseline Metrics Needed

Static inspection is not enough to tune this safely. The collected 10-run snapshot is partial and cannot replace a baseline. It does show that recent successful push runs are roughly 34 minutes end to end, but it is not enough to declare p95, flake rate, cache health, or safe gate removals.

Collect these before changing topology:

- **metrics-needed:** p50/p95 wall time by workflow and job for at least the last 20-50 comparable non-release and release-adjacent runs.
- **metrics-needed:** step timings for `release-gate`, `host-integration`, `playwright-e2e`, `host-docker-smoke`, admin guardrails, and `annotation-sweep`.
- **metrics-needed:** cache-hit state, cache miss state, restore time, save time, and cache sizes for BEAM deps, PLTs, npm, and any future Playwright browser cache.
- **metrics-needed:** top 20 slowest ExUnit tests per package via `mix test --slowest 20` and slowest modules where useful.
- **metrics-needed:** compile profile via `MIX_ENV=test mix compile --profile time` for core, admin, portal, and host package contexts.
- **metrics-needed:** flake/rerun rate by job, with reruns separated from intentional stabilization commits.
- **metrics-needed:** scheduled `live-stripe` proved-vs-skipped count, with proved requiring Stripe test mode execution against required secrets and fixtures.
- **metrics-needed:** Docker smoke cold vs warm duration, including dependency fetch, compile, migration, asset build, and readiness wait.
- **assumption:** Branch-protection required-check truth is inferred from committed `ci.yml` comments and stable job IDs unless a later read-only branch-protection query labels otherwise.

### Partial GitHub Run Snapshot

Collected evidence: `gh run list --workflow CI --branch main --limit 10` plus `gh run view 28538686414 --json jobs`, collected 2026-07-02T20:56:01Z. Scope: branch `main`, workflow `CI`, 10 latest runs, partial and not exhaustive.

| Snapshot item | Result | Boundary |
|---|---|---|
| 10 latest `main` CI runs | 2 success, 8 failure; failures include recent push stabilization runs and scheduled runs | Collected-evidence sample, not flake rate |
| Partial workflow wall time | sample p50 about 23m26s; sample p95 about 34m52s | Collected-evidence sample, not stable p50/p95 baseline |
| Latest successful run inspected | `28538686414`, push to `main`, `test: align admin browser uat with current drawers`, success, 2026-07-01T18:21:06Z to 2026-07-01T18:55:58Z | Collected-evidence single run |
| Long legs in latest successful run | `release-gate` required cells about 15m44s-16m13s; `host-integration` about 10m37s; Playwright shards about 3m45s-4m30s; Docker smoke about 7m13s | Collected-evidence single run; step timing and cache state remain metrics-needed |
| Provider lane in latest successful push run | `Stripe test-mode parity (mandatory periodic)` reported skipped because `live-stripe` only runs on schedule/manual | Static workflow semantics plus collected push-run job state; provider proved-vs-skipped count remains metrics-needed |

## Findings by Category

### Correctness

The pipeline is high-signal and intentionally release-oriented. Keep the host proof, package gates, docs contracts, release manifest checks, Fake-backed deterministic tests, provider canary, and release proof. Do not optimize by hiding risk.

The correctness gap is claim precision. A green Fake-backed default test path proves Accrue's deterministic billing behavior. A green `live-stripe` lane proves Stripe parity only when Stripe test mode actually runs with `STRIPE_TEST_SECRET_KEY` and the required price/account fixtures. A skipped provider test is skipped/not proved; it is not parity proof.

`release-gate`, `host-integration`, `playwright-e2e`, `host-docker-smoke`, `annotation-sweep`, `live-stripe`, `publish-hex`, and `release-please` all carry real release-confidence work. The target pipeline should clarify what each gate proves before changing where it runs.

### Performance

The biggest static waste is duplicated work, but the project should measure first before moving anything out of the PR path:

- `release-gate` repeats package checks across matrix cells.
- `host-integration` and `scripts/ci/accrue_host_verify_browser.sh` both prepare browser deps.
- `playwright-e2e` shards each do compile/build/seed/browser setup.
- `host-docker-smoke` cold-builds a dev image and waits up to 900 seconds.
- `annotation-sweep` waits on almost every required lane, so it inherits the slowest prerequisite.

Partial run data supports the static concern: in inspected run `28538686414`, the required `release-gate` cells took about 16 minutes, `host-integration` about 11 minutes, Playwright shards about 4 minutes after host proof, and Docker smoke about 7 minutes. That is enough to prioritize instrumentation, not enough to delete or demote checks.

### Determinism / Flakiness

Known risk patterns:

- Many tests mutate `Application` env, so async conversion must be careful.
- Live/provider tests can skip under missing secrets or missing Stripe fixture IDs.
- Browser tests use single-worker lanes in some guardrails; that is conservative and slow, but it avoids hidden order-dependent failures.
- `accrue_host_verify_browser.sh` disables duplicate Playwright global seeding when it already seeded the fixture, which is good determinism evidence and should be preserved.
- Schedule runs in the 10-run snapshot failed quickly; without job-log review, treat them as provider/schedule investigation needed, not as a quantified flake rate.

Do not turn this into broad async conversion. First classify env-mutating tests, sleep-based tests, network/provider tests, and deterministic Fake-backed tests.

### Caching

Current cache keys include OS, OTP, Elixir, optional-dependency labels, and lockfiles in many places, which is directionally sound. The gaps are visibility and proof:

- Cache-hit state is not surfaced in job summaries, so maintainers cannot tell whether slow jobs are cold, warm, or thrashing.
- There is no Docker layer cache evidence for `host-docker-smoke`.
- There is no Playwright browser cache, but Playwright browser-binary caching should not be added by default on Linux without measured restore-vs-download data.
- Manual host UAT still uses older action majors than the main CI path, which is static drift risk for manual reproduction.

### Matrix / Version Policy

The floor/primary matrix is reasonable for a Phoenix library. The Sigra and OpenTelemetry cells must materially change dependency, compile, or test behavior. Sigra is visibly advisory through `continue-on-error`; OpenTelemetry is required. That distinction is fine only if each label proves a distinct condition.

The OpenTelemetry test explicitly compiles with `ACCRUE_OTEL_MATRIX=without_opentelemetry` and `with_opentelemetry`, which is stronger than a label-only cell. Sigra still needs current proof that the CI environment changes what gets resolved and compiled; otherwise keep it advisory, rename it, or redesign it after Phase 204 ranks the work.

### Test Suite Quality

The suite is large and likely valuable. Do not delete tests from static inspection. First classify:

- Must remain PR gate: core package tests, host deterministic proof, docs contract gates.
- Keep but optimize: browser/setup-heavy lanes, matrix repetition.
- Scheduled/manual: live provider parity and exhaustive compatibility if runtime grows.
- Fix/quarantine: any test relying on sleeps, global env leaks, or network.

Fake-backed tests remain the merge-blocking default because they are deterministic and local. Live Stripe is a provider canary for upstream API drift and provider-specific behavior. The audit should never trade Fake-backed confidence for a skip-capable network lane.

### Security / Supply Chain

Good: no `pull_request_target`, top-level CI permissions are read-only, release/publish jobs are trusted workflows. Gaps:

- Third-party actions are tag-pinned, not SHA-pinned.
- Release Please has broad write permissions as expected but should stay isolated.
- Recovery publish should enforce prerequisites before publishing downstream packages.
- Provider secrets are only discussed by name; no secret values were read or recorded in this audit.

### Release

Primary Release Please is carefully ordered: `publish-accrue-admin` depends on core publish, `publish-accrue-portal` depends on core and admin publish, and linked proof checks tags, GitHub Releases, Hex API truth, HexDocs, and release snapshots.

The recovery path is weaker. `publish-hex.yml` publishes one selected package and relies on input prose: "Run accrue before accrue_admin before accrue_portal when recovering a same-day release." That is release-confidence debt. Do not change it in Phase 202; hand it to Phase 204 as a machine-preflight candidate.

### Developer Experience / Docs

`scripts/ci/README.md` is detailed and useful for maintainers. The developer-experience gap is first-failure routing. A contributor needs to answer: what failed, what does this gate prove, what local command reproduces the smallest useful slice, and whether provider parity was actually proved or merely skipped.

Keep the maintainer map. Add short failure summaries later only after the baseline identifies the high-churn gates. The audit itself should stay as the proof-checkable source for Phase 204, not become a public contributor doc rewrite.

## Prioritized Recommendations

| Priority | Title | Category | Current issue | Proposed change | Impact | Risk | Verify | Rollback |
|---|---|---|---|---|---|---|---|---|
| P0 | CI baseline summaries | Measurement | No timing/cache summary artifact | Add summaries for versions, cache-hit state, key step timings, and slowest tests where cheap | High | Low | Compare two comparable runs and check summary fields | Remove summaries |
| P0 | Live/provider proved-vs-skipped state | Correctness | Mandatory periodic can skip under missing secrets/fixtures | Choose: fail scheduled lane when required inputs are absent, or rename as advisory skip-capable | High | Low/medium | Scheduled run reports proved, skipped/not proved, or failed | Revert condition or label |
| P1 | Split release-gate check classes | Runtime | Matrix repeats package gates | After p50/p95 and step timing baseline, run lint/docs/audit once and keep compatibility tests in matrix | High | Medium | Same failures caught; p95 PR runtime improves | Restore old job |
| P1 | Host harness consolidation | Runtime/DX | duplicated npm/Chromium setup | After setup timing, make one owner for host browser setup | Medium | Low | host run logs one install path | Revert workflow/script change |
| P1 | Release recovery guards | Release | manual order dependence | Add preflight checks for upstream Hex package/version before admin/portal recovery publish | Medium | Low | attempted out-of-order recovery fails before publish | Remove preflight |
| P1 | Matrix fidelity | Correctness | optional-dependency labels may not prove behavior | Make env flags load deps/tests or rename cells as advisory/label-only | Medium | Medium | forced negative test fails the expected cell | Revert matrix edits |
| P2 | Docker smoke SLA | Runtime | 900s cold boot tail | After cold/warm data, add layer cache or make path/main policy explicit | Medium | Medium | smoke duration and cache hit rate improve | Disable cache or restore trigger |
| P2 | Playwright browser cache | Runtime | repeated browser downloads | Measure download vs restore time before caching browser binaries | Medium | Medium | cache hit and no stale browser failures | Remove cache |
| P2 | Test value classification | QA | suite likely expensive | Produce keep/optimize/nightly/delete table from timings and failure history | Medium | Low | classification references measured slowest tests | n/a |
| P3 | Required check finalizer | Branch protection | many matrix names | Consider stable summary check only after branch-protection data and failure routing prove value | Low/medium | Medium | branch protection simpler without losing signal | keep existing checks |

## Target Pipeline

This is a target shape for Phase 204 ranking, not a Phase 202 implementation. Preserve high-value gates until measured evidence supports a change.

**PR fast path**

- Keep docs/support contracts and release manifest checks PR-blocking.
- Keep one latest package gate for format, compile, test, credo, docs, and audit.
- Keep compatibility-focused matrix cells only where they prove a supported Elixir/OTP/provider/optional-dependency promise.
- Keep Fake-backed deterministic tests and `host-integration` as merge-blocking proof.
- Keep one focused browser proof on PRs; move duplicate full-suite coverage only after measured step timing and failure-history evidence.
- Keep `host-docker-smoke` PR-blocking until Docker cold/warm data supports a path-aware, main-only, or release-only policy.
- Keep `annotation-sweep` release-facing, but require its critical-path cost to be measured.

**Main**

- Same as PR plus broader smoke, cache warming, release manifest checks, and host Hex smoke when applicable.

**Scheduled**

- Live Stripe provider canary with binary proved/skipped/not-proved output, full compatibility matrix only if it proves supported promises, dependency/security audit, and long browser evidence.

**Release/tag**

- Release Please after green main, ordered publish, linked proof, release notes contract, and host Hex smoke.

## Concrete Patch Strategy

PR 1: baseline only
- Add summaries and timing commands.
- Record cache-hit state.
- Add `mix test --slowest 20` where cheap.

PR 2: truth fixes
- Clarify `live-stripe` proved/skipped semantics.
- Verify Sigra/OTel matrix behavior.
- Keep Fake-backed deterministic tests as the merge-blocking default.

PR 3: dedupe setup
- Consolidate host npm/Chromium setup.
- Remove duplicate browser install in either workflow or script only after setup timing proves it is duplicated cost.

PR 4: release-gate split
- Extract single-run lint/docs/audit after a step-timing baseline.
- Keep compatibility matrix focused on distinct compile/test behavior.

PR 5: release recovery hardening
- Add Hex prerequisite checks to `publish-hex.yml`.

## Validation Plan

Before/after metrics:

- PR p50/p95 runtime, separated by push, pull request, release-please branch, schedule, and manual events.
- Critical-path job duration and step timing for `release-gate`, `host-integration`, `playwright-e2e`, `host-docker-smoke`, and `annotation-sweep`.
- Cache-hit rate, restore duration, save duration, and cache size for BEAM deps, PLTs, npm, and any browser cache trial.
- Failure/rerun rate by job, with human reruns separated from new commits.
- Slowest tests and slowest modules for core/admin/portal/host.
- Compile time and compile-connected xref output before changing matrix shape.
- Docker smoke cold/warm duration.
- Host browser setup time before and after any setup consolidation.
- Provider proved-vs-skipped counts for scheduled/manual `live-stripe`.
- Mean time to actionable failure, using job summary and first failing gate name.

Local diagnostics:

```bash
cd accrue && mix test --slowest 20
cd accrue && MIX_ENV=test mix compile --profile time
cd accrue && mix xref graph --format cycles --label compile-connected
cd examples/accrue_host && mix verify
cd examples/accrue_host && mix verify.full
```

Phase 204 verification for any implementation slice should include before/after CI run links, job summary screenshots or logs, and rollback proof. A cleanup PR that cannot prove the same high-value gates still run should not merge.

## Recommended Local Commands

Fast contributor path:

```bash
cd examples/accrue_host && mix verify
```

Full host proof:

```bash
cd examples/accrue_host && mix verify.full
```

Package-local gate:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix hex.audit
```

Release and recovery diagnostics:

```bash
bash scripts/ci/verify_release_manifest_alignment.sh
bash scripts/ci/verify_release_contract.sh
bash scripts/ci/capture_linked_release_proof.sh --help
bash scripts/ci/accrue_host_hex_smoke.sh
```

## Evidence Appendix

Static repository evidence is the source of truth for Phase 202. The GitHub run snapshot below is bounded, read-only, and partial. It supports prioritization, not topology deletion.

| Command or inspection | Result | Audit impact | Boundary label |
|---|---|---|---|
| `rg -n "Job id contract|Merge-blocking|Mandatory periodic" .github/workflows/ci.yml` | `ci.yml` declares stable job IDs, pull-request merge-blocking jobs, and `live-stripe` as mandatory periodic | Supports topology map and required-check inference | Static inspection; branch protection not queried |
| `rg -n "needs:|matrix:|continue-on-error|actions/cache|playwright|docker|live-stripe" .github/workflows/ci.yml` | Shows the `release-gate` matrix, advisory Sigra cell, OpenTelemetry required cell, cache use, host/Playwright/Docker jobs, and schedule-only live Stripe lane | Supports CI-01 and CI-02 findings | Static inspection |
| `sed -n '776,1088p' .github/workflows/ci.yml` | Shows `host-integration` needs, `playwright-e2e` needs, Docker smoke wait loop, and `annotation-sweep` fan-in | Supports likely critical path | Static inspection plus partial run snapshot |
| `sed -n '1089,1162p' .github/workflows/ci.yml` and `rg -n "STRIPE_TEST_SECRET_KEY|@moduletag :skip|ACCRUE_LIVE" accrue/test/live_stripe` | Workflow provides secrets to `mix test.live`; tests skip when required secrets or price fixtures are absent | Supports provider proved-vs-skipped language | Static inspection; live provider counts metrics-needed |
| `sed -n '1,220p' scripts/ci/accrue_host_verify_browser.sh` | Host browser proof reseeds deterministic fixtures, builds admin assets, runs `npm ci`, installs Chromium, starts Phoenix, and runs Playwright | Supports duplicate setup and deterministic host proof findings | Static inspection; step timing metrics-needed |
| `sed -n '1,220p' .github/workflows/release-please.yml` and `sed -n '1,120p' .github/workflows/publish-hex.yml` | Release Please encodes ordered publish dependencies; recovery publish relies on manual package-order prose | Supports release recovery risk | Static inspection |
| `gh run list --workflow CI --branch main --limit 10` | 10-run branch snapshot collected 2026-07-02T20:56:01Z; 2 success, 8 failure; partial p50/p95 workflow wall time observed | Supports measured-boundary section only | Collected evidence; partial sample |
| `gh run view 28538686414 --json jobs` | Latest successful inspected run shows `release-gate`, `host-integration`, `playwright-e2e`, Docker, and `annotation-sweep` durations | Supports likely critical-path prioritization | Collected evidence; single run |

## Assumptions and Metrics-Needed Items

- Branch protection required-check list was inferred from workflow comments, not GitHub settings.
- Runtime durations require GitHub run history; this document does not claim measured p95 values yet.
- Official docs consulted: GitHub Actions dependency caching, ExUnit async behavior, Ecto schema/migration prefixes, and `erlef/setup-beam` versioning guidance.
