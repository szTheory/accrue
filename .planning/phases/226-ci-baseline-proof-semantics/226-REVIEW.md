---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-11T18:58:20Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - accrue/test/test_helper.exs
  - examples/accrue_host/package.json
  - scripts/ci/accrue_host_uat.sh
  - scripts/ci/accrue_host_verify_browser.sh
  - scripts/ci/ci_setup_diagnostic.sh
  - scripts/ci/collect_ci_baseline.mjs
  - scripts/ci/provider_proof.mjs
  - scripts/ci/render_ci_baseline.mjs
  - scripts/ci/render_provider_summary.mjs
  - scripts/ci/verify_ci_baseline.mjs
  - scripts/ci/verify_ci_setup_diagnostics.sh
  - scripts/ci/verify_provider_proof.mjs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-11T18:58:20Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The formatter, host verification scripts, diagnostics, baseline collector, proof classifier, renderers, and their fixtures were reviewed. The included fixture commands pass, but the live baseline collection path contradicts the cohort qualification rule and can never establish the requested full-CI timing cohort. Timestamp validation also accepts impossible calendar dates and silently normalizes them, allowing inaccurate evidence and freshness state.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Live collection excludes every full-CI run from percentile samples (BLOCKER)

**File:** `scripts/ci/collect_ci_baseline.mjs:161,263`

**Issue:** `liveRuns` assigns `provider_state: "non_run"` to every collected CI run, which correctly distinguishes ordinary CI from provider proof. However, `summarizeCohorts` then requires `provider_state !== "non_run"` for qualifying timing samples. Consequently, even 20 successful full-CI runs collected from GitHub produce `sample_count: 0` and `insufficient_sample`; p50/p95 can never be calculated. This is masked because the fixtures use a successful run whose provider state is not `non_run`.

**Fix:** Qualification for the CI timing cohort should exclude provider-only scheduled runs by topology/event, not exclude the `non_run` provider-proof state. For example:

```js
.filter(({ normalized }) =>
  normalized.event_class !== "schedule" &&
  normalized.conclusion === "success" &&
  normalized.run_attempt === 1 &&
  Date.parse(normalized.completed_at) >= cutoff
)
```

Add a regression fixture with 20 successful `provider_state: "non_run"` push/pull-request runs and assert a ready cohort.

## Warnings

### WR-01: Impossible timestamps are accepted and silently rewritten by `Date.parse` (WARNING)

**File:** `scripts/ci/collect_ci_baseline.mjs:23-26`; `scripts/ci/provider_proof.mjs:21-24`

**Issue:** Both validators rely on `Date.parse` after only a superficial check (and the provider validator has no format check at all). JavaScript accepts calendar-invalid values such as `2026-02-30T00:00:00Z` and normalizes them to `2026-03-02T00:00:00Z`. That permits corrupted manifest or collected timestamps to alter durations, cohort inclusion, and stale-proof calculations without rejection.

**Fix:** Require the canonical UTC format and round-trip it through `new Date(value).toISOString()` before accepting it:

```js
if (!/^\d{4}-\d\d-\d\dT\d\d:\d\d(?:\.\d{3})?Z$/.test(value) ||
    new Date(value).toISOString() !== value) {
  fail(`${field} must be a valid canonical UTC timestamp`);
}
```

Add invalid-day and invalid-leap-day cases to both verifier fixtures.

---

_Reviewed: 2026-08-11T18:58:20Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
