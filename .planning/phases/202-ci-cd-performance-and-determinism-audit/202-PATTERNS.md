# Phase 202: ci-cd-performance-and-determinism-audit - Pattern Map

**Mapped:** 2026-07-02  
**Files analyzed:** 1 direct phase artifact  
**Analogs found:** 1 / 1

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | documentation / audit artifact | batch + transform over static repo evidence; optional read-only request-response snapshot via `gh` | `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` plus `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | exact/self + role-match |

## Pattern Assignments

### `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` (documentation / audit artifact, batch + transform)

**Analog:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`  
**Style analog:** `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`  
**Downstream handoff analog:** `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`

**Header and scope pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` lines 1-5):

```markdown
# CI/CD Performance and Determinism Audit: Accrue v1.55

**Date:** 2026-07-01  
**Status:** Phase 202 draft baseline  
**Scope:** GitHub Actions workflows, `scripts/ci`, Mix aliases, package gates, host UAT, release/publish automation.
```

Copy this pattern, but update status/date if finalizing the audit. Keep the scope sentence bounded to CI/CD evidence surfaces, not product/API/DB/UI implementation.

**Executive summary pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` lines 7-17):

```markdown
## Executive Summary

Top recommended changes:

1. **Measure first:** add/collect job and step timings, cache-hit state, slowest tests, compile time, and retry/failure history before deleting or demoting gates.
2. **Split compatibility from repeated package gates:** `release-gate` currently repeats core/admin/portal format, compile, test, audit, docs, and dialyzer across matrix cells.
3. **Consolidate host browser setup:** CI installs Node/Chromium before `accrue_host_uat.sh`, while the delegated browser script installs again.
4. **Clarify provider/lane truth:** scheduled `live-stripe` is called mandatory but can skip when secrets are absent; Sigra/OpenTelemetry matrix labels need proof that they actually change compile/test conditions.
5. **Guard release recovery:** manual `publish-hex.yml` relies on human package order; add machine checks before admin/portal recovery.

Expected impact: faster PR feedback, less duplicated runner work, clearer red/green meaning, lower release risk. First PR should be observability/baseline only.
```

Planner should preserve the numbered, mechanism-led summary. If claims are changed, keep them evidence-backed and avoid measured runtime/savings language unless a labeled run snapshot is included.

**Current pipeline map pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` lines 19-32):

```markdown
## Current Pipeline Map

| Workflow | Trigger | Job shape | Cache/services | Quality signal | Likely bottleneck |
|---|---|---|---|---|---|
| `CI` | push/PR/main, manual, schedule | Main required gate plus scheduled `live-stripe` | Postgres, BEAM deps/PLTs, npm | Release and merge confidence | Long critical path |
| `release-gate` | non-schedule `CI` | 4 matrix cells: floor, primary, advisory Sigra, required OTel | Postgres 15, deps, PLT | Package format/compile/test/credo/dialyzer/docs/audit | Repeats too much per cell |
| `docs-contracts-shift-left` | non-schedule `CI` | bash docs/contracts + token harness | Node npm cache | Docs/support contract drift | Many serial shell checks |
```

Extend this table rather than replacing it with prose. It is the main CI-01 scan surface.

**Metrics-needed pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` lines 34-45):

```markdown
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
```

Keep this section even if a small `gh` snapshot is collected. Static-only completion remains valid; missing p50/p95, flake, cache, and provider counts are not blockers.

**Findings structure pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` lines 47-107):

```markdown
## Findings by Category

### Correctness

The pipeline is high-signal and intentionally release-oriented. Keep the host proof, package gates, docs contracts, release manifest checks, and provider parity lanes. Do not optimize by hiding risk.

### Performance

The biggest static waste is duplicated work:

- `release-gate` repeats package checks across matrix cells.
- `host-integration` and its browser script both prepare browser deps.
- `playwright-e2e` shards each do compile/build/seed/browser setup.
- Docker smoke cold-builds a dev image and waits up to 900 seconds.
```

Use category headings for correctness, performance, determinism, caching, matrix/version policy, test quality, security/supply chain, release, and DX/docs. Keep "do not optimize by hiding risk" as the constraint behind recommendations.

**Prioritized recommendation table pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` lines 108-121):

```markdown
## Prioritized Recommendations

| Priority | Title | Category | Current issue | Proposed change | Impact | Risk | Verify | Rollback |
|---|---|---|---|---|---|---|---|---|
| P0 | CI baseline summaries | Measurement | No timing/cache summary artifact | Add job summaries for versions, cache hits, slowest tests where cheap | High | Low | Compare two runs | Remove summaries |
| P0 | Live/provider proved-vs-skipped state | Correctness | Mandatory periodic can skip | Fail scheduled lane when required secrets absent, or rename as advisory skip-capable | High | Low/medium | Scheduled run shows proved/skipped | Revert condition |
```

For final Phase 202 output, planner should convert or supplement this with the locked Phase 204 handoff columns from D-19: area, evidence path, current risk, priority local to Phase 202, expected impact, tradeoff, implementation approach, verification, rollback, metric-needed status, and suggested milestone-slice fit.

**Target pipeline pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` lines 123-145):

```markdown
## Target Pipeline

**PR fast path**

- Docs/support contracts.
- One latest package gate for format/compile/test/credo/docs/audit.
- Compatibility-focused test cells only where they prove a compatibility promise.
- Host deterministic proof.
- Focused browser guardrails with no duplicate setup.
- Docker smoke only if relevant files changed or on main if too slow.
```

Keep recommendations as target shape, not an implementation commitment. Do not recommend deletion/demotion from static inspection alone.

**Evidence appendix pattern** (source: `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` lines 228-240):

```markdown
## Evidence Appendix

This appendix is the QLT-05 evidence map. Static repository evidence is the primary source. Bounded command output supports confidence; it is not a full release proof. When a claim needs live CI history, a live provider account, branch-protection settings, external scorecards, or production traffic data, it is labeled **metrics-needed** or **Assumption**.

### Bounded Command Evidence

| Command or inspection | Result | Score impact | Boundary label |
|---|---|---|---|
| `rg -n "live-stripe|continue-on-error|STRIPE_TEST_SECRET_KEY|schedule|workflow_dispatch" .github/workflows/ci.yml guides/testing-live-stripe.md` | CI and docs label `live-stripe` as manual/scheduled Stripe test-mode parity, with advisory/non-merge-blocking wording and skip/proved semantics | Supports Provider-parity clarity and Safety of defaults findings | Static semantics; proved-vs-skipped counts are metrics-needed |
```

Use this model for Phase 202 evidence: command/inspection, result, impact, and boundary label. Every dynamic claim needs a boundary label.

**Assumptions and metrics-needed pattern** (source: `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` lines 269-275):

```markdown
### Assumptions and Metrics-Needed Items

- **Assumption:** Branch protection required-check topology is inferred from `.github/workflows/ci.yml` comments and job names, not from live GitHub settings.
- **metrics-needed:** CI p50/p95 duration, cache hit/miss rates, slowest ExUnit tests, Playwright browser install cost, Docker smoke cold/warm duration, and retry/flake rates belong to Phase 202.
- **metrics-needed:** Live-Stripe scheduled proved-vs-skipped counts belong to Phase 202. Phase 201 records the lane semantics only.
```

Reuse the `**Assumption:**` and `**metrics-needed:**` prefixes exactly for unmeasured or inferred claims.

**Phase handoff pattern** (source: `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` lines 277-285):

```markdown
## Phase Handoff and Boundary

Phase 201 is an **audit-only** gate. Broad project verification, Docker boot proof, live provider proof, GitHub run-history metrics, flake-rate metrics, external scorecards, product behavior changes, public API changes, DB default changes, CI required-check topology changes, release automation changes, runtime UI changes, CSS changes, routes, and package metadata edits are **not required** and are not part of the **Phase 201 gate**.

| Handoff | Phase 201 finding | Owner for implementation-grade detail |
|---|---|---|
| Phase 202 | CI/CD signal fidelity is the weakest quality dimension because static topology suggests duplicated work and ambiguous provider/lane truth | `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` owns timings, cache behavior, flake/rerun history, target pipeline, and proved-vs-skipped counts |
```

Phase 202 should mirror the audit-only boundary and hand off implementation-grade work to Phase 204 rather than creating issue-ready implementation cards.

**Phase 204 consumer shape pattern** (source: `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` lines 7-20):

```markdown
## Ranked Top 10 Changes

| Rank | Change | Area | Improves | Impact | Effort | Risk Reduction | Timing | Done Looks Like |
|---:|---|---|---|---|---|---|---|---|
| 1 | Add CI timing/cache baseline summaries | `.github/workflows`, `scripts/ci` | CI/CD | High | Low | High | before showing to strangers | CI logs show versions, cache hits, key step timings, and slowest tests where cheap |
| 2 | Fix public toolchain/version truth | `CONTRIBUTING.md`, READMEs, release docs | OSS trust | High | Low | High | before next release | One current table for Elixir/OTP/Postgres/Node/package versions |
```

Phase 202's final `Phase 204 Handoff` should be richer than this baseline, but this is the downstream planner's current consumption style: ranked, tabular, risk-oriented, and implementation-sized.

**Validation pattern** (source: `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-VALIDATION.md` lines 20-23):

```markdown
| **Framework** | Document/source assertion checks |
| **Config file** | none - audit-only planning artifact |
| **Quick run command** | `test -s .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md && rg -n "Baseline Metrics Needed|Phase 204 Handoff|Static|GitHub run|proved|skipped|rollback|metric" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` |
| **Full suite command** | `test -s .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md && rg -n "release-gate|host-integration|playwright-e2e|host-docker-smoke|annotation-sweep|live-stripe|publish-hex|release-please" .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` |
```

Planner should keep verification at document/source assertion level. Do not add test framework or CI execution requirements for this audit-only phase.

## Evidence Source Patterns

These files are evidence sources only. They are not Phase 202 modification targets.

### CI Topology And Required-Check Truth

**Source:** `.github/workflows/ci.yml`

**Stable job-id and required-check comment pattern** (lines 3-14):

```yaml
# Job id contract — stable YAML `jobs:` keys relied on by docs, `act`, and anchors:
# `release-manifest-ssot`, `release-gate`, `phase18-tax-gate`, `admin-drift-docs`,
# `admin-group-contracts`, `admin-hardening-guardrails`,
# `admin-phase200-guardrails`, `host-integration`, `playwright-e2e`,
# `host-docker-smoke`, `annotation-sweep`, `live-stripe`.
# Merge-blocking on pull_request: `release-manifest-ssot`, `docs-contracts-shift-left`,
# `release-gate`, `phase18-tax-gate`, `admin-drift-docs`, `admin-group-contracts`,
# `admin-hardening-guardrails`, `admin-phase200-guardrails`,
# `host-integration`, `playwright-e2e`, `host-docker-smoke`,
# `annotation-sweep`.
# Mandatory periodic: `live-stripe` (Stripe test-mode parity) runs on
# `workflow_dispatch` and `schedule` only to catch upstream Stripe API drift.
```

Use this as the source for inferred required-check topology. If live branch-protection settings are not queried, label this as inferred from committed workflow comments.

**Matrix and advisory-cell pattern** (lines 131-197):

```yaml
release-gate:
  name: Release gate (${{ matrix.compatibility }}; elixir=${{ matrix.elixir }} otp=${{ matrix.otp }} sigra=${{ matrix.sigra }} opentelemetry=${{ matrix.opentelemetry }})${{ matrix.support == 'advisory' && ' [advisory]' || '' }}
  if: github.event_name != 'schedule'

  strategy:
    fail-fast: false
    matrix:
      include:
        - elixir: '1.19.0'
          otp: '28.0'
          sigra: 'off'
          opentelemetry: 'off'
          compatibility: 'Floor'
          support: 'required'
        - elixir: '1.19.5'
          otp: '28.0'
          sigra: 'on'
          opentelemetry: 'off'
          compatibility: 'Primary dev target'
          support: 'advisory'

  # Required cells remain release-blocking; only clearly labeled advisory cells may use continue-on-error.
  continue-on-error: ${{ matrix.support == 'advisory' }}
```

Use this as the evidence basis for provider/matrix truth: required versus advisory is already encoded; Phase 202 should audit whether labels correspond to distinct behavior.

**Host integration duplicated setup pattern** (lines 776-866):

```yaml
host-integration:
  # host-integration proves Phoenix 1.8 / LiveView 1.1 by running the seeded host app
  name: Host integration (required deterministic gate)
  needs: [admin-drift-docs, docs-contracts-shift-left]

  steps:
    - name: Set up Node
      uses: actions/setup-node@v6
      with:
        node-version: '22'
        cache: npm
        cache-dependency-path: examples/accrue_host/package-lock.json

    - name: Install browser deps
      run: |
        cd examples/accrue_host && npm ci
        cd assets && npm ci

    - name: Install Chromium
      run: cd examples/accrue_host && npm run e2e:install

    - name: Run host integration gate
      # Canonical trust lane: seeded performance smoke + browser accessibility/responsive checks.
      run: bash scripts/ci/accrue_host_uat.sh
```

Pair with `scripts/ci/accrue_host_uat.sh` and `scripts/ci/accrue_host_verify_browser.sh` evidence when discussing duplicated browser setup.

**Playwright shard and Docker smoke critical-path pattern** (lines 902-1077):

```yaml
playwright-e2e:
  name: Playwright E2E shard ${{ matrix.shard }}/${{ strategy.job-total }}
  needs: [host-integration]
  strategy:
    fail-fast: false
    matrix:
      shard: [1, 2, 3]

  steps:
    - name: Compile host
      run: cd examples/accrue_host && mix compile --warnings-as-errors
    - name: Build host assets
      run: cd examples/accrue_host && mix assets.build
    - name: Install Chromium
      run: cd examples/accrue_host && npm run e2e:install
    - name: Run Playwright shard
      run: cd examples/accrue_host && npx playwright test --shard=${{ matrix.shard }}/${{ strategy.job-total }}

host-docker-smoke:
  name: Host Docker boot smoke
  needs: [docs-contracts-shift-left]
  steps:
    - name: Build and boot Docker host app
      run: cd examples/accrue_host && docker compose up --build -d
    - name: Wait for Docker host app
      run: |
        for _ in $(seq 1 900); do
```

Use this as static evidence for duplicated setup and likely long-tail work. Do not convert it into measured duration without run data.

**Annotation-sweep critical-path pattern** (lines 1050-1077):

```yaml
annotation-sweep:
  name: Annotation sweep
  needs:
    [
      release-manifest-ssot,
      docs-contracts-shift-left,
      release-gate,
      phase18-tax-gate,
      admin-drift-docs,
      admin-group-contracts,
      admin-hardening-guardrails,
      admin-phase200-guardrails,
      host-integration,
      playwright-e2e,
      host-docker-smoke,
    ]
```

Use this as evidence that annotation sweep waits on nearly the full non-scheduled CI graph.

### Provider Truth

**Source:** `.github/workflows/ci.yml`

**Live Stripe workflow pattern** (lines 1100-1162):

```yaml
# Requires STRIPE_TEST_SECRET_KEY to be configured as a repository
# secret. Individual tests skip cleanly in setup_all when the secret
# is absent.
live-stripe:
  # Job id stays `live-stripe` for `act -j live-stripe` compatibility; display
  # name reflects Stripe *test mode* keys (`STRIPE_TEST_SECRET_KEY`), not live mode.
  name: Stripe test-mode parity (mandatory periodic)
  if: github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'

  env:
    STRIPE_TEST_SECRET_KEY: ${{ secrets.STRIPE_TEST_SECRET_KEY }}
    ACCRUE_LIVE_BASIC_PRICE: ${{ secrets.ACCRUE_LIVE_BASIC_PRICE }}
    ACCRUE_LIVE_PRO_PRICE: ${{ secrets.ACCRUE_LIVE_PRO_PRICE }}

  - name: Run live-Stripe suite
    run: cd accrue && mix test.live
```

Classify provider truth as `proved` only when this job actually runs tests with required secrets/fixtures. Missing secrets are `skipped/not proved`.

**Live Stripe docs pattern** (source: `guides/testing-live-stripe.md` lines 1-17 and 43-55):

```markdown
The GitHub Actions job id is `live-stripe` for historical reasons; it runs
against **Stripe test mode** (`STRIPE_TEST_SECRET_KEY`), not live-mode production
keys.

1. **Fake-asserted correctness tests** — run on every `mix test`, use
   the in-process `Accrue.Processor.Fake`, and prove that every
   code path stays wired end-to-end. These run in CI on every PR.

2. **Live-Stripe fidelity tests** — run against real Stripe test mode,
   gated by the `:live_stripe` ExUnit tag (excluded by default) and
   by the presence of a `STRIPE_TEST_SECRET_KEY` environment variable.

`mix test.live` is an alias (defined in `accrue/mix.exs`) for
`mix test --only live_stripe`. Without the env vars set, the tests
tag themselves `:skip` at module load time and produce a clean
"0 tests, X skipped" report — no errors.
```

Use this exact Fake-versus-live distinction in Phase 202. It is the canonical explanation for deterministic merge-blocking proof versus provider canary proof.

**Mix alias pattern** (source: `accrue/mix.exs` lines 127-139):

```elixir
defp aliases do
  [
    "test.all": [
      "format --check-formatted",
      "credo --strict",
      "compile --warnings-as-errors",
      "test"
    ],
    # Opt-in live-Stripe fidelity suite. Gated on the `:live_stripe` tag,
    # which is excluded by default in `test/test_helper.exs`. Individual
    # test modules in `test/live_stripe/` are expected to skip cleanly in
    # `setup_all` when `STRIPE_TEST_SECRET_KEY` is unset.
    "test.live": ["test --only live_stripe"]
```

Use this when explaining why Fake-backed tests remain the contributor loop and live Stripe remains opt-in/scheduled.

**Skip behavior pattern** (source: `accrue/test/live_stripe/charge_3ds_live_test.exs` lines 42-60):

```elixir
# Conditional skip: if no secret is set in the environment, tag the
# whole module `:skip` so `mix test.live` on a bare environment
# reports "skipped" instead of dying in setup_all.
unless System.get_env("STRIPE_TEST_SECRET_KEY") do
  @moduletag :skip
end

setup_all do
  secret = System.get_env("STRIPE_TEST_SECRET_KEY")

  if is_nil(secret) do
    {:ok, skip: true}
```

This is the concrete source for "green can still mean skipped" risk. The audit must not call a skipped live-provider lane provider parity.

### Release And Recovery

**Source:** `.github/workflows/release-please.yml`

**Ordered primary publish pattern** (lines 216-314):

```yaml
publish-accrue:
  name: Publish accrue
  needs: release
  if: ${{ needs.release.outputs.accrue_release_created == 'true' }}

publish-accrue-admin:
  name: Publish accrue_admin
  needs: [release, publish-accrue]
  if: ${{ always() && needs.release.outputs.accrue_admin_release_created == 'true' && (needs.release.outputs.accrue_release_created != 'true' || needs.publish-accrue.result == 'success') }}

publish-accrue-portal:
  name: Publish accrue_portal
  needs: [release, publish-accrue, publish-accrue-admin]
  if: ${{ always() && needs.release.outputs.accrue_portal_release_created == 'true' && (needs.release.outputs.accrue_release_created != 'true' || needs.publish-accrue.result == 'success') && (needs.release.outputs.accrue_admin_release_created != 'true' || needs.publish-accrue-admin.result == 'success') }}

linked-release-proof:
  name: Linked release proof
  needs: [release, publish-accrue, publish-accrue-admin, publish-accrue-portal]
```

Use this as the contrast for recovery risk: primary path encodes ordering through `needs` and conditions.

**Linked proof artifact pattern** (source: `.github/workflows/release-please.yml` lines 354-393):

```yaml
- name: Capture linked release proof
  run: bash scripts/ci/capture_linked_release_proof.sh --auto --output "$LINKED_RELEASE_PROOF"

- name: Run host Hex smoke
  run: |
    set -euo pipefail
    {
      echo
      echo "#### Host Hex smoke"
      echo
      echo '```text'
    } >> "$LINKED_RELEASE_PROOF"
    bash scripts/ci/accrue_host_hex_smoke.sh 2>&1 | tee -a "$LINKED_RELEASE_PROOF"
    echo '```' >> "$LINKED_RELEASE_PROOF"

- name: Upload linked release proof
  if: always()
  uses: actions/upload-artifact@v7
  with:
    name: linked-release-proof
    path: linked-release-proof.md
```

Use this as a pattern for proof artifacts: append evidence, publish summary, upload artifact.

**Manual recovery risk pattern** (source: `.github/workflows/publish-hex.yml` lines 1-21 and 52-114):

```yaml
name: Publish Hex Recovery

on:
  workflow_dispatch:
    inputs:
      package:
        description: 'Package to publish. Run accrue before accrue_admin before accrue_portal when recovering a same-day release.'
        required: true
        type: choice
        options:
          - accrue
          - accrue_admin
          - accrue_portal
      release_version:
        description: 'Expected package version at the selected ref.'
        required: true
        type: string

publish-accrue-admin:
  if: ${{ inputs.package == 'accrue_admin' }}
  ...
  - name: Dry run accrue_admin Hex publish
    run: cd accrue_admin && mix hex.publish --dry-run

publish-accrue-portal:
  if: ${{ inputs.package == 'accrue_portal' }}
  ...
  - name: Dry run accrue_portal Hex publish
    run: cd accrue_portal && mix hex.publish --dry-run
```

Use this as evidence that recovery order is human prose, not an enforced inter-job dependency. Phase 202 can recommend future machine preflight checks, not implement them.

### Local Gate And Maintainer Triage

**Source:** `scripts/ci/README.md`

**Contributor map pattern** (lines 1-5):

```markdown
# scripts/ci — contributor map

This directory hosts merge-adjacent bash gates and host-app checks. Use it as the first stop when CI fails on documentation or VERIFY-01 contracts.

**After a push:** from the repo root, **`bash scripts/ci/watch_ci.sh`** waits on the latest GitHub Actions **CI** run for **`main`** (optional branch argument). Requires the **`gh`** CLI and auth (`gh auth login`).
```

Use this as evidence for maintainer-facing gate map. If recommending DX changes, keep them grounded in this existing triage surface.

**Host integration triage pattern** (lines 177-186):

```markdown
### Triage: host-integration / `accrue_host_uat.sh`

Failures on **`host-integration`** start from **`bash scripts/ci/accrue_host_uat.sh`**, which runs **`mix verify.full`** inside **`examples/accrue_host`**.

- **`[host-integration] phase=bounded_mix_tests`** — bounded ExUnit slice (`mix verify`-style subset).
- **`[host-integration] phase=full_mix_tests`** — full **`mix test`** for the host app.
- **`[host-integration] phase=dev_boot_smoke`** — bounded **`mix phx.server`** boot check.
- **`[host-integration] phase=browser_playwright`** — headless Playwright gate.
```

This is the maintainer job-to-be-done framing for "what failed?" and "where do I start?"

**Release gate proof chain pattern** (source: `scripts/ci/README.md` lines 201-231):

```markdown
## REL gates (v1.48 linked release readiness + publish proof)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| REL-01 | `scripts/ci/verify_release_pr_scope.sh`; `scripts/ci/verify_release_manifest_alignment.sh`; `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` (`PR_NUMBER`, `TARGET_VERSION`) | — | `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` |
| REL-03 | `scripts/ci/capture_linked_release_proof.sh`; `scripts/ci/accrue_host_hex_smoke.sh`; `.github/workflows/release-please.yml`; `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` (`RUN_ID`) | — | `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` |

- The ledger is append-only: the script records workflow ordering, git tags, GitHub release URLs, and Hex API truth for `accrue`, `accrue_admin`, and `accrue_portal`.
- The current proof chain is `verify_release_manifest_alignment.sh` -> `capture_linked_release_proof.sh` -> `accrue_host_hex_smoke.sh`, with all outcomes recorded in the Phase 159 ledger.
```

Use this pattern to keep release findings tied to named REL gates and append-only proof.

**Read-only CI watch pattern** (source: `scripts/ci/watch_ci.sh` lines 1-23):

```bash
#!/usr/bin/env bash
# Wait for the latest GitHub Actions "CI" workflow run on a branch (default: main).
# Requires: gh CLI, authenticated for this repo (gh auth login).
set -euo pipefail

branch="${1:-main}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

run_id="$(gh run list --branch "$branch" --workflow CI --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$run_id" --exit-status
```

Use this as the repo-local precedent for `gh` read-only interaction. For Phase 202, prefer bounded `gh run list` / `gh run view` snapshots and label collection date, branch/filter, run count, and partial/exhaustive status.

### Host Proof Entrypoints

**Source:** `examples/accrue_host/mix.exs`

**Mix alias pattern** (lines 146-205):

```elixir
defp aliases do
  [
    verify: [verify_command()],
    "verify.full": [
      "verify.install",
      "verify",
      "compile --warnings-as-errors",
      "assets.build",
      verify_regression_command(),
      verify_dev_boot_command(),
      verify_browser_command()
    ],
    precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
  ]
end

defp verify_browser_command do
  cmd_run_script("accrue_host_verify_browser.sh")
end
```

Use this as evidence that host proof already has a Phoenix-native Mix entrypoint. Recommendations should preserve `mix verify` / `mix verify.full` clarity.

**Playwright package script pattern** (source: `examples/accrue_host/package.json` lines 4-17 and `accrue_admin/package.json` lines 4-17):

```json
"scripts": {
  "e2e": "env -u NO_COLOR playwright test",
  "e2e:a11y": "env -u NO_COLOR playwright test e2e/verify01-admin-a11y.spec.js",
  "e2e:install": "playwright install chromium"
},
"devDependencies": {
  "@axe-core/playwright": "^4.11.1",
  "@playwright/test": "^1.57.0"
}
```

Use package scripts as the canonical browser command source. Do not invent a new browser runner recommendation.

## Shared Patterns

### Audit-Only Boundary

**Source:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` lines 7-12 and 173-180  
**Apply to:** Entire Phase 202 plan

```markdown
Phase 202 produces `202-CI-CD-PERFORMANCE-AUDIT.md`: an evidence-backed audit of Accrue's GitHub Actions workflow topology, static critical path, measurement needs, bottlenecks, flaky/determinism risks, cache risks, provider-lane truth, release-lane risks, and target pipeline recommendations.

This phase is audit-only. It must not change CI workflow topology, branch protection, package release automation, runtime behavior, public APIs, DB defaults, UI implementation, or required-check semantics.

Deferred Ideas:
- Any actual CI topology changes, branch protection changes, required-check changes, job finalizer work, reusable workflow extraction, cache changes, Docker layer-cache work, Playwright setup changes, or workflow path filters.
- Any live-Stripe behavior change: fail-on-missing-secrets, rename to advisory, summary emission, provider proved/skipped counter, or fixture/secrets management.
- Any release recovery preflight implementation in `publish-hex.yml`.
```

Planner should enforce this as a hard scope fence. The only direct write target is the audit document.

### Measurement Honesty

**Source:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` lines 23-27  
**Apply to:** All performance/cache/flake/provider statements

```markdown
- Phase 202 is **static-first and audit-only**. Static workflow/config/script inspection is sufficient to complete the phase when live run-history data is unavailable.
- Missing or incomplete live metrics do **not** block Phase 202.
- Dynamic claims need explicit labels. The audit can say static inspection suggests duplication, cache risk, or likely critical-path drag; it must not claim measured runtime savings, cache hit rates, or flake rates without collected evidence.
```

Use "static inspection suggests" for static findings. Use "measured" only with labeled run-history evidence.

### Phase 204 Handoff Columns

**Source:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` lines 43-47  
**Apply to:** Final section of `202-CI-CD-PERFORMANCE-AUDIT.md`

```markdown
Each Phase 204 handoff row must include: area, evidence path, current risk, priority local to Phase 202, expected impact, tradeoff, implementation approach, verification, rollback, metric-needed status, and suggested milestone-slice fit.
```

Use this exact column set, even if the rest of the report uses shorter tables.

### Accrue Voice

**Source:** `brandbook/voice.md` lines 11-17, 25-32, and 123-128  
**Apply to:** All audit prose and recommendation wording

```markdown
**Measured.** Accrue doesn't oversell. Every claim is sized to what the library actually does — no superlatives, no adjective-led marketing copy. A measured sentence names a mechanism.

**Exact.** Accrue names things precisely: context functions, append-only ledgers, merge-blocking CI, Fake-backed proof paths.

**Native.** Accrue speaks in Phoenix-developer idioms — Ecto schemas, OTP supervision, mix tasks, plugs, contexts.

State capability as a mechanism or named artifact, not an adjective.
Substantiate strong claims with a verifiable mechanism the reader can inspect.
```

Audit language should be blunt but mechanism-led. Avoid generic "best practice" recommendations unless paired with Accrue-specific evidence.

### Verification Boundary

**Source:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-VALIDATION.md` lines 28-33 and 57-63  
**Apply to:** Planner verification steps

```markdown
- **After every task commit:** Run the quick document/source assertion command.
- **After every plan wave:** Run the full document/source assertion command.
- **Before `/gsd:verify-work`:** Confirm the audit covers CI-01 through CI-05 and that `git diff -- .github/workflows scripts/ci accrue accrue_admin accrue_portal examples` shows no implementation changes from this phase.

| Static evidence separation from live metrics | CI-03, CI-05 | Requires human review of wording and claim provenance |
| No implementation/topology changes | CI-01..CI-05 | The phase output is a document; git status is the source of truth |
```

The verification pattern is document assertion plus scope-boundary check, not CI mutation or full CI execution.

## No Analog Found

No direct Phase 202 write target lacks an analog. Implementation/workflow/source files are intentionally excluded from modification classification because Phase 202 is audit-only.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| N/A | N/A | N/A | Sole direct target has exact/self analog and Phase 201 role-match analog |

## Metadata

**Analog search scope:** `.planning/phases`, `.github/workflows`, `scripts/ci`, `accrue/test/live_stripe`, `accrue/mix.exs`, `examples/accrue_host`, `accrue_admin`, `brandbook`  
**Files scanned:** 36 primary sources/sections plus project-instruction existence checks  
**Project instructions:** `AGENTS.md` not present; project-local `.codex/skills/` and `.agents/skills/` not present  
**Pattern extraction date:** 2026-07-02  
**Write target for this pattern map:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-PATTERNS.md`  
**Phase write target:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` only
