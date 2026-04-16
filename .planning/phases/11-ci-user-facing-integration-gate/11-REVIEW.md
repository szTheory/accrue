---
phase: 11-ci-user-facing-integration-gate
reviewed: 2026-04-16T19:08:10Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - .github/workflows/accrue_admin_assets.yml
  - .github/workflows/accrue_host_uat.yml
  - .github/workflows/ci.yml
  - examples/accrue_host/e2e/phase11-host-gate.spec.js
  - examples/accrue_host/package.json
  - examples/accrue_host/playwright.config.js
  - scripts/ci/accrue_host_uat.sh
  - scripts/ci/annotation_sweep.sh
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-04-16T19:08:10Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the new CI gate, Playwright host integration, and annotation sweep path. The main release-blocking additions are structurally sound, but there are two correctness gaps in CI behavior: the scheduled workflow currently runs far more than the advisory Stripe job, and the browser gate suppresses CI-mode Playwright reporting so failure artifacts and GitHub annotations are lost.

`examples/accrue_host/package-lock.json` was loaded for dependency context but excluded from the formal review scope per the lockfile filter rule.

## Warnings

### WR-01: Scheduled CI Still Runs The Full Release Gate

**File:** `.github/workflows/ci.yml:9-13`
**Issue:** The workflow comment says the daily cron should run only the advisory `live-stripe` job, but `release-gate`, `admin-drift-docs`, `host-integration`, and `annotation-sweep` have no `if:` guard excluding `schedule`. On a scheduled run, GitHub Actions evaluates all of those jobs too. That changes the workflow from a cheap advisory probe into a full release-blocking pipeline on every day, which is a CI behavior regression and contradicts the documented contract.
**Fix:**
```yaml
release-gate:
  if: github.event_name != 'schedule'

admin-drift-docs:
  if: github.event_name != 'schedule'

host-integration:
  if: github.event_name != 'schedule'

annotation-sweep:
  if: github.event_name != 'schedule'

live-stripe:
  if: github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'
```

### WR-02: Browser Gate Disables CI Reporters And Hides Failure Evidence

**File:** `scripts/ci/accrue_host_uat.sh:195-200`
**Issue:** The script explicitly runs Playwright with `CI=` cleared. In `examples/accrue_host/playwright.config.js:13-15`, that switches reporting from `github` + HTML to plain `list`. As a result, the `host-integration` workflow does not emit Playwright GitHub annotations, and the `examples/accrue_host/playwright-report` artifact uploaded on failure is usually missing. The gate still fails, but the verification signal and debugging evidence that Phase 11 is trying to add are suppressed.
**Fix:**
```bash
(
  cd "$host_dir"
  ACCRUE_HOST_REUSE_SERVER=1 \
    ACCRUE_HOST_BROWSER_PORT="$browser_port" \
    ACCRUE_HOST_E2E_FIXTURE="$fixture_file" \
    npm run e2e
)
```

```js
webServer: {
  command: `PORT=${port} PHX_SERVER=true MIX_ENV=test mix phx.server`,
  url: `${baseURL}/`,
  reuseExistingServer:
    process.env.ACCRUE_HOST_REUSE_SERVER === "1" || !process.env.CI,
  timeout: 120_000
}
```

## Info

### IN-01: Manual Host UAT Workflow Still Targets The Old Playwright Package Location

**File:** `.github/workflows/accrue_host_uat.yml:46-65`
**Issue:** The manual `accrue_host_uat.yml` workflow still restores the npm cache from `accrue_admin/package-lock.json` and runs `npm ci` / `playwright install` under `accrue_admin`, while the new Phase 11 E2E package lives in `examples/accrue_host`. The script currently compensates by reinstalling from the host app later, so this is drift rather than an immediate breakage, but the manual workflow is no longer exercising the same dependency tree as the release gate.
**Fix:** Point `cache-dependency-path`, `npm ci`, and browser installation at `examples/accrue_host`, or remove those duplicated steps and let `scripts/ci/accrue_host_uat.sh` own Node setup consistently.

---

_Reviewed: 2026-04-16T19:08:10Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
