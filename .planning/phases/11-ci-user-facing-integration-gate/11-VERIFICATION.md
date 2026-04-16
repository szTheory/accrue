---
phase: 11-ci-user-facing-integration-gate
verified: 2026-04-16T19:12:54Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 0
---

# Phase 11: CI User-Facing Integration Gate Verification Report

**Phase Goal:** Pull requests and `main` pushes fail when the host-app user experience regresses, making realistic integration coverage part of the release gate instead of an optional local check.
**Verified:** 2026-04-16T19:12:54Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | GitHub Actions runs host-app compile/test/setup and Fake-backed E2E flows on pull requests and pushes to `main`. | ✓ VERIFIED | `.github/workflows/ci.yml` triggers on `push` and `pull_request` for `main`, then runs `host-integration` on non-scheduled events after package gates. The job executes `bash scripts/ci/accrue_host_uat.sh`, and that script reruns installer setup, warning-clean compile/tests, and the Playwright E2E gate. |
| 2 | CI fails on compile warnings, test failures, browser failures, docs-link drift, generated artifact drift, or warning/error annotations. | ✓ VERIFIED | `release-gate` runs `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, and `mix docs --warnings-as-errors` for both packages; `admin-drift-docs` blocks on rebuilt asset drift plus guide drift checks; `scripts/ci/accrue_host_uat.sh` exits on generated host drift and browser failure; `annotation-sweep` runs `scripts/ci/annotation_sweep.sh` and fails on warning/failure/error annotations. |
| 3 | Package-local tests and host-app user-facing flows run in a clear order so failures point at the right layer. | ✓ VERIFIED | `ci.yml` expresses `release-gate -> admin-drift-docs -> host-integration -> annotation-sweep` through explicit `needs`, so package failures stop before host/browser work starts. |
| 4 | Browser failures publish enough artifacts to debug without rerunning locally where practical. | ✓ VERIFIED | `examples/accrue_host/playwright.config.js` retains trace and screenshots on failure and emits `playwright-report` plus `test-results`; `ci.yml` uploads the Playwright report, traces, and host server log on `failure()`. |
| 5 | Live Stripe remains opt-in/advisory while Fake-backed user-facing flows are mandatory. | ✓ VERIFIED | `live-stripe` runs only for `workflow_dispatch` or `schedule` and is `continue-on-error: true`; the mandatory PR/main path is the Fake-backed `host-integration` job. |
| 6 | The mandatory host browser gate runs as Playwright Test instead of a raw node smoke script. | ✓ VERIFIED | `examples/accrue_host/package.json` defines `npm run e2e` as `playwright test`, and `scripts/ci/accrue_host_uat.sh` invokes `npm run e2e` after booting Phoenix and seeding fixtures. No workflow calls the old raw browser smoke script. |
| 7 | The browser gate proves the real signed-in host and admin replay flow at 1280x900. | ✓ VERIFIED | `examples/accrue_host/playwright.config.js` uses a single `chromium-desktop` project at `1280x900`; `examples/accrue_host/e2e/phase11-host-gate.spec.js` logs in through `/users/log-in`, starts and cancels a subscription, then replays a webhook through `/billing/webhooks/:id` and checks the resulting admin event. |
| 8 | The host shell gate reproduces the release-blocking setup, compile, test, and browser flow in one local command. | ✓ VERIFIED | `scripts/ci/accrue_host_uat.sh` performs deps/install, generated-drift blocking, compile, asset build, focused tests, full regression tests, bounded boot smoke, fixture seeding, and Playwright execution in one script. |
| 9 | If release-facing jobs still emit workflow annotations, the CI gate can fail on them explicitly. | ✓ VERIFIED | `scripts/ci/annotation_sweep.sh` requires the current run context, queries job/check-run annotations through `gh api` or `curl`, and exits nonzero on `warning`, `failure`, or `error`; `ci.yml` runs it as the final `annotation-sweep` job. |
| 10 | Pull requests and `main` pushes use `ci.yml` as the single blocking gate while auxiliary host/admin workflows are manual-only. | ✓ VERIFIED | `.github/workflows/accrue_host_uat.yml` and `.github/workflows/accrue_admin_assets.yml` are `workflow_dispatch` only, so they no longer compete with the canonical PR/main gate in `ci.yml`. |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `examples/accrue_host/package.json` | Host-local Playwright dependency and scripts | ✓ VERIFIED | Substantive manifest with `@playwright/test`, `e2e`, and `e2e:install`; used by the host UAT script and CI host job. |
| `examples/accrue_host/playwright.config.js` | Host Playwright runner with retained failure artifacts and browser wiring | ✓ VERIFIED | Defines `testDir`, failure artifact retention, HTML report path, `test-results`, and Chromium desktop project; `npx playwright test --list` discovers the phase gate from this config. |
| `examples/accrue_host/e2e/phase11-host-gate.spec.js` | Blocking browser spec for user billing plus admin replay | ✓ VERIFIED | Real end-to-end assertions against shipped routes and copy, backed by fixture data rather than placeholders. |
| `scripts/ci/accrue_host_uat.sh` | Deterministic host setup/test/browser gate | ✓ VERIFIED | Substantive script, syntax-valid, and wired from `ci.yml` plus local/manual workflows. |
| `scripts/ci/annotation_sweep.sh` | Annotation blocker for release-facing jobs | ✓ VERIFIED | Reads current run metadata, pages through annotations, fails closed on API or annotation issues, and is invoked by `ci.yml`. |
| `.github/workflows/ci.yml` | Ordered release workflow with drift/docs stage, host integration, annotation sweep, and failure uploads | ✓ VERIFIED | Valid YAML with PR/main triggers, ordered jobs, host artifact upload, and advisory live Stripe policy. |
| `.github/workflows/accrue_admin_assets.yml` | Legacy admin-assets workflow demoted out of the PR/main gate | ✓ VERIFIED | Manual-only workflow; blocking logic now lives in `ci.yml`. |
| `.github/workflows/accrue_host_uat.yml` | Legacy host-UAT workflow demoted out of the PR/main gate | ✓ VERIFIED | Manual-only workflow; blocking logic now lives in `ci.yml`. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `examples/accrue_host/playwright.config.js` | `examples/accrue_host/e2e/phase11-host-gate.spec.js` | `testDir ./e2e` and `npm run e2e` | ✓ WIRED | The config points Playwright at `./e2e`, and `npx playwright test --list` enumerates the phase gate spec. |
| `examples/accrue_host/e2e/phase11-host-gate.spec.js` | `scripts/ci/accrue_host_seed_e2e.exs` | `ACCRUE_HOST_E2E_FIXTURE` data contract | ✓ WIRED | The spec reads `ACCRUE_HOST_E2E_FIXTURE`; the shell gate populates it by running the seed script before `npm run e2e`. |
| `scripts/ci/accrue_host_uat.sh` | `examples/accrue_host/package.json` | `npm ci`, `npm run e2e:install`, and `npm run e2e` | ✓ WIRED | The script installs browser deps and Chromium from the host manifest, then runs the host Playwright gate. |
| `scripts/ci/annotation_sweep.sh` | `.github/workflows/ci.yml` | Final `annotation-sweep` job | ✓ WIRED | `ci.yml` exports `GITHUB_REPOSITORY`, `GITHUB_RUN_ID`, and `GH_TOKEN` before calling the sweep script. |
| `.github/workflows/ci.yml` | `scripts/ci/accrue_host_uat.sh` | `host-integration` job | ✓ WIRED | The job calls the script directly and sets the stable host/browser log path. |
| `.github/workflows/ci.yml` | `scripts/ci/annotation_sweep.sh` | `annotation-sweep` job | ✓ WIRED | The release-facing workflow ends with an explicit annotation blocker. |
| `.github/workflows/ci.yml` | `.github/workflows/accrue_admin_assets.yml` | asset-freshness logic moved into `admin-drift-docs` | ✓ WIRED | `admin-drift-docs` now contains the blocking asset/guide checks; the legacy workflow is manual-only. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `examples/accrue_host/e2e/phase11-host-gate.spec.js` | `fixture.normal_email`, `fixture.admin_email`, `fixture.webhook_id` | `scripts/ci/accrue_host_seed_e2e.exs` writes `ACCRUE_HOST_E2E_FIXTURE` after creating users, billing records, webhook rows, and event history in the repo DB | Yes | ✓ FLOWING |
| `scripts/ci/annotation_sweep.sh` | matched jobs and annotation rows | GitHub Actions Jobs API plus check-run annotations, fetched with `gh api` or `curl` using the current run id | Yes | ✓ FLOWING |
| `.github/workflows/ci.yml` host failure uploads | `playwright-report`, `test-results`, and `accrue-host-server.log` | Generated by the Playwright config and `scripts/ci/accrue_host_uat.sh` when the browser gate runs or fails | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Workflow YAML parses | `/Users/jon/.asdf/installs/ruby/3.3.4/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci.yml"); YAML.load_file(".github/workflows/accrue_host_uat.yml"); YAML.load_file(".github/workflows/accrue_admin_assets.yml"); puts "workflow YAML OK"'` | `workflow YAML OK` | ✓ PASS |
| Shell gate scripts are syntactically valid | `bash -n scripts/ci/accrue_host_uat.sh && bash -n scripts/ci/annotation_sweep.sh` | `shell syntax OK` | ✓ PASS |
| Host Playwright contract is discoverable and scoped to one Chromium desktop test | `cd examples/accrue_host && npx playwright test --list` | Listed one `chromium-desktop` test: `phase11-host-gate.spec.js:69:1` | ✓ PASS |
| Full host integration gate executes end to end | `CI=true bash scripts/ci/accrue_host_uat.sh` | Orchestrator-provided verification passed: focused host tests `16/16`, full host suite `127/127`, boot smoke passed, Playwright browser gate `1/1` passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| CI-01 | 11-03 | GitHub Actions runs the host app setup and integration suite on pull requests and pushes to `main`. | ✓ SATISFIED | `ci.yml` triggers on PR/main and runs the non-scheduled `host-integration` job that executes `bash scripts/ci/accrue_host_uat.sh`. |
| CI-02 | 11-01, 11-02, 11-03 | CI fails on host-app compile warnings, test failures, browser failures, docs-link drift, and generated artifact drift. | ✓ SATISFIED | Warning-as-error compile/tests and docs builds run in `ci.yml`; host generated drift fails in `scripts/ci/accrue_host_uat.sh`; browser failures fail the Playwright gate; admin guide drift and asset freshness block in `admin-drift-docs`. |
| CI-03 | 11-03 | CI exercises both package-local tests and host-app user-facing flows in a clear release-gate order. | ✓ SATISFIED | Explicit `needs` chain in `ci.yml` orders package checks before admin drift/docs before host integration before annotation sweep. |
| CI-04 | 11-01, 11-03 | CI publishes useful artifacts for failed host-app browser runs, including screenshots or traces where practical. | ✓ SATISFIED | Playwright config retains traces/screenshots/report; `ci.yml` uploads report, traces, and server log on failure. |
| CI-05 | 11-03 | CI keeps live Stripe checks opt-in/advisory while making Fake-backed user-facing flows mandatory. | ✓ SATISFIED | `live-stripe` is schedule/manual only and advisory; `host-integration` is the required PR/main Fake-backed path. |
| CI-06 | 11-02, 11-03 | CI annotation sweeps remain warning/error blockers for release-facing jobs. | ✓ SATISFIED | `annotation-sweep` runs after the release-facing jobs and the script exits nonzero on warning/failure/error annotations. |

No orphaned Phase 11 requirements found. All six Phase 11 requirement IDs appear in plan frontmatter and map to implementation evidence.

### Anti-Patterns Found

No blocker, warning, or info-level anti-patterns were found in the Phase 11 implementation files scanned. Placeholder/stub patterns were absent, and the only grep hits were ordinary list initializations inside `annotation_sweep.sh`, not user-visible stubs.

### Gaps Summary

No automated gaps found. The workflow wiring, host Playwright gate, artifact retention, annotation blocker, and advisory live-Stripe policy all exist in the codebase and are connected to the canonical PR/main CI path.

---

_Verified: 2026-04-16T19:12:54Z_
_Verifier: Claude (gsd-verifier)_
