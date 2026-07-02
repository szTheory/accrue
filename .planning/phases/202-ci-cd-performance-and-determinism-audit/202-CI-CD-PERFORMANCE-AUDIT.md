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

The pipeline is high-signal and intentionally release-oriented. Keep the host proof, package gates, docs contracts, release manifest checks, and provider parity lanes. Do not optimize by hiding risk.

### Performance

The biggest static waste is duplicated work:

- `release-gate` repeats package checks across matrix cells.
- `host-integration` and its browser script both prepare browser deps.
- `playwright-e2e` shards each do compile/build/seed/browser setup.
- Docker smoke cold-builds a dev image and waits up to 900 seconds.

### Determinism / Flakiness

Known risk patterns:

- Many tests mutate `Application` env, so async conversion must be careful.
- Live/provider tests can skip under missing secrets.
- Browser tests use single-worker lanes in some guardrails, which is conservative but slow.

### Caching

Current cache keys include OS/OTP/Elixir/lockfile in many places, which is directionally good. Gaps:

- No Playwright browser cache.
- No Docker layer cache.
- Manual host UAT workflow still uses older action majors.
- Cache-hit state is not surfaced in a summary.

### Matrix / Version Policy

The floor/primary matrix is reasonable for a library. The Sigra/OpenTelemetry cells need proof that env flags change dependency/compile/test behavior. Otherwise they should be renamed to "label-only advisory" or redesigned.

### Test Suite Quality

The suite is large and likely valuable. Do not delete tests from static inspection. First classify:

- Must remain PR gate: core package tests, host deterministic proof, docs contract gates.
- Keep but optimize: browser/setup-heavy lanes, matrix repetition.
- Scheduled/manual: live provider parity and exhaustive compatibility if runtime grows.
- Fix/quarantine: any test relying on sleeps, global env leaks, or network.

### Security / Supply Chain

Good: no `pull_request_target`, top-level CI permissions are read-only, release/publish jobs are trusted workflows. Gaps:

- Third-party actions are tag-pinned, not SHA-pinned.
- Release Please has broad write permissions as expected but should stay isolated.
- Recovery publish should enforce prerequisites before publishing downstream packages.

### Release

Primary Release Please path is carefully ordered. Recovery path is weaker: package order is in input prose, not enforced by the workflow.

### DX / Docs

`scripts/ci/README.md` is detailed, but contributors need a shorter first-failure map. The local "run every release gate" instructions are accurate but heavy.

## Prioritized Recommendations

| Priority | Title | Category | Current issue | Proposed change | Impact | Risk | Verify | Rollback |
|---|---|---|---|---|---|---|---|---|
| P0 | CI baseline summaries | Measurement | No timing/cache summary artifact | Add job summaries for versions, cache hits, slowest tests where cheap | High | Low | Compare two runs | Remove summaries |
| P0 | Live/provider proved-vs-skipped state | Correctness | Mandatory periodic can skip | Fail scheduled lane when required secrets absent, or rename as advisory skip-capable | High | Low/medium | Scheduled run shows proved/skipped | Revert condition |
| P1 | Split release-gate check classes | Runtime | Matrix repeats too much | Run lint/docs/audit once, compatibility tests in matrix | High | Medium | p95 PR runtime down, same failures caught | Restore old job |
| P1 | Host harness consolidation | Runtime/DX | duplicated npm/Chromium setup | Single source for browser setup, no double install | Medium | Low | host run logs one install | Revert script |
| P1 | Release recovery guards | Release | manual order dependence | Check upstream Hex package/version before admin/portal publish | Medium | Low | attempted out-of-order recovery fails early | Remove check |
| P1 | Matrix fidelity | Correctness | Sigra/OTel labels may not prove behavior | Make env flags load deps/tests or rename cells | Medium | Medium | forced negative test fails expected cell | Revert matrix |
| P2 | Docker smoke SLA | Runtime | 900s cold boot tail | Add Docker layer cache or narrow trigger | Medium | Medium | smoke duration and hit rate improve | Disable cache |
| P2 | Playwright browser cache | Runtime | repeated browser downloads | Cache browser binaries with exact Playwright version | Medium | Medium | cache hit and no stale browser failures | Remove cache |
| P2 | Test value classification | QA | suite likely expensive | Produce keep/optimize/nightly/delete table from timings | Medium | Low | documented classification | n/a |
| P3 | Required check finalizer | Branch protection | many matrix names | Optional stable summary check | Low/medium | Medium | branch protection simplified | keep existing checks |

## Target Pipeline

**PR fast path**

- Docs/support contracts.
- One latest package gate for format/compile/test/credo/docs/audit.
- Compatibility-focused test cells only where they prove a compatibility promise.
- Host deterministic proof.
- Focused browser guardrails with no duplicate setup.
- Docker smoke only if relevant files changed or on main if too slow.

**Main**

- Same as PR plus broader smoke, cache warming, release manifest checks, Hex smoke when applicable.

**Scheduled**

- Live Stripe provider parity, full compatibility matrix if needed, dependency/security audit, long browser evidence.

**Release/tag**

- Release Please after green main, ordered publish, linked proof, release notes contract, host Hex smoke.

## Concrete Patch Strategy

PR 1: baseline only
- Add summaries and timing commands.
- Record cache hits.
- Add `mix test --slowest 20` where cheap.

PR 2: truth fixes
- Fix toolchain docs.
- Clarify `live-stripe` proved/skipped semantics.
- Verify Sigra/OTel matrix behavior.

PR 3: dedupe setup
- Consolidate host npm/Chromium setup.
- Remove duplicate browser install in either workflow or script.

PR 4: release-gate split
- Extract single-run lint/docs/audit.
- Keep compatibility matrix focused.

PR 5: release recovery hardening
- Add Hex prerequisite checks to `publish-hex.yml`.

## Validation Plan

Before/after metrics:

- PR p50/p95 runtime.
- Critical-path job duration.
- Cache hit rate.
- Failure/rerun rate.
- Slowest tests.
- Compile time.
- Docker smoke duration.
- Host browser setup time.
- Mean time to actionable failure.

Local diagnostics:

```bash
cd accrue && mix test --slowest 20
cd accrue && MIX_ENV=test mix compile --profile time
cd accrue && mix xref graph --format cycles --label compile-connected
cd examples/accrue_host && mix verify
cd examples/accrue_host && mix verify.full
```

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
