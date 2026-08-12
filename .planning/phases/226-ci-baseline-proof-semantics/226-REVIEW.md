---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-11T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - accrue/test/test_helper.exs
  - examples/accrue_host/README.md
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-11T00:00:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The host diagnostics and provider-proof path were reviewed along with the CI-baseline collector and renderers. Fixture suites pass, but the live collector can combine data from different rerun attempts and incorrectly labels every executed runner as GitHub-hosted. Either defect can produce a false comparable-cohort/critical-path claim.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Historical jobs from earlier workflow attempts contaminate the current run

**File:** `scripts/ci/collect_ci_baseline.mjs:276`
**Issue:** The collector requests `jobs?filter=all` but emits one run record using the workflow run's current `run_attempt` and conclusion. GitHub's `all` filter includes jobs from prior attempts of the same workflow run. Those prior jobs are then put in the same run as the current attempt without an attempt identifier. A failed first attempt followed by a successful rerun can therefore contribute old successful stage timings, old failure signatures, or duplicate stage identities to the successful run. The renderer selects jobs by `run_id`, so its release/host/Playwright path can be assembled from different attempts and reported as valid evidence.

**Fix:** Request only the latest attempt's jobs (use `filter=latest`, or omit the filter if that is the documented API default), and add a fixture with two attempts to prove previous jobs cannot appear in the normalized run.

```js
const jobs = (await fetchPages(
  `/repos/${repo}/actions/runs/${run.id}/jobs?filter=latest&per_page=100`
))
  .flatMap((page) => page.jobs || []);
```

### CR-02: Runner-image cohorting is fabricated instead of observed

**File:** `scripts/ci/collect_ci_baseline.mjs:278`
**Issue:** `runner_image` is set to `"github-hosted"` whenever GitHub supplies a `runner_name`. Both GitHub-hosted and self-hosted jobs have a runner name, and the value does not identify the OS/image. The cohort fingerprint relies on this field (lines 67-68), so changes from Ubuntu 22 to Ubuntu 24, or a switch to self-hosted runners, can be silently mixed into a supposedly comparable timing cohort. That makes the p50/p95 and critical-path evidence materially incorrect after a runner change.

**Fix:** Obtain and persist a real, privacy-safe runner class/image from a trusted workflow/config mapping (for example, map known workflow job identities to their `runs-on` class), fail closed when it cannot be determined, and include tests that demonstrate distinct images/classes yield distinct fingerprints.

---

_Reviewed: 2026-08-11T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
