# CI/CD Performance and Determinism Audit: Accrue v1.55

**Date:** 2026-07-01  
**Status:** Phase 202 draft baseline  
**Scope:** GitHub Actions workflows, `scripts/ci`, Mix aliases, package gates, host UAT, release/publish automation.

## Executive Summary

Top recommended changes:

1. **Measure first:** add/collect job and step timings, cache-hit state, slowest tests, compile time, and retry/failure history before deleting or demoting gates.
2. **Split compatibility from repeated package gates:** `release-gate` currently repeats core/admin/portal format, compile, test, audit, docs, and dialyzer across matrix cells.
3. **Consolidate host browser setup:** CI installs Node/Chromium before `accrue_host_uat.sh`, while the delegated browser script installs again.
4. **Clarify provider/lane truth:** scheduled `live-stripe` is called mandatory but can skip when secrets are absent; Sigra/OpenTelemetry matrix labels need proof that they actually change compile/test conditions.
5. **Guard release recovery:** manual `publish-hex.yml` relies on human package order; add machine checks before admin/portal recovery.

Expected impact: faster PR feedback, less duplicated runner work, clearer red/green meaning, lower release risk. First PR should be observability/baseline only.

## Current Pipeline Map

| Workflow | Trigger | Job shape | Cache/services | Quality signal | Likely bottleneck |
|---|---|---|---|---|---|
| `CI` | push/PR/main, manual, schedule | Main required gate plus scheduled `live-stripe` | Postgres, BEAM deps/PLTs, npm | Release and merge confidence | Long critical path |
| `release-gate` | non-schedule `CI` | 4 matrix cells: floor, primary, advisory Sigra, required OTel | Postgres 15, deps, PLT | Package format/compile/test/credo/dialyzer/docs/audit | Repeats too much per cell |
| `docs-contracts-shift-left` | non-schedule `CI` | bash docs/contracts + token harness | Node npm cache | Docs/support contract drift | Many serial shell checks |
| `admin-* guardrails` | non-schedule `CI` | Playwright/admin guardrails | Postgres, Node, npm, deps | UI regression | Browser install + overlap |
| `host-integration` | non-schedule `CI` | `mix verify.full` + Hex smoke | Postgres, Node, host deps | Host adoption proof | setup + browser + full tests |
| `playwright-e2e` | after host integration | 3 shards | Postgres, Node, host deps | Full host browser coverage | duplicate compile/build/seed/browser install per shard |
| `host-docker-smoke` | non-schedule `CI` | Docker compose cold boot | Docker only | Docker evaluator proof | 900s loop, cold image build |
| `annotation-sweep` | after most jobs | GitHub annotation query | gh token | release-facing warning gate | waits on almost everything |
| `Release Please` | push main/manual | release PR, publish core/admin/portal, proof | Postgres in proof | release automation | complex fallback logic |
| `Publish Hex Recovery` | manual | one selected package | no enforced inter-run order | recovery | human order dependence |

## Baseline Metrics Needed

Static inspection is not enough to tune this safely. Collect:

- p50/p95 wall time by workflow and job for last 20-50 runs.
- Step timings for `release-gate`, `host-integration`, `playwright-e2e`, Docker smoke.
- Cache hit/miss rates and cache sizes for BEAM deps, PLTs, npm, Playwright browsers.
- Top 20 slowest ExUnit tests per package via `mix test --slowest 20`.
- Compile time via `MIX_ENV=test mix compile --profile time`.
- Flake/rerun rate by job.
- Scheduled `live-stripe` proved vs skipped count.
- Docker smoke cold vs warm duration.

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

## Assumptions

- Branch protection required-check list was inferred from workflow comments, not GitHub settings.
- Runtime durations require GitHub run history; this document does not claim measured p95 values yet.
- Official docs consulted: GitHub Actions dependency caching, ExUnit async behavior, Ecto schema/migration prefixes, and `erlef/setup-beam` versioning guidance.
