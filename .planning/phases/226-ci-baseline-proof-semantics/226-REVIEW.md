---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-12T02:07:10Z
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

**Reviewed:** 2026-08-12T02:07:10Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The CI baseline and provider-proof paths were reviewed in their workflow context. Two defects make the emitted evidence incorrect or prevent it from being collected: the host dependency uses a workflow ID where the collector requires a normalized display name, and a freshly proved provider run is still labelled stale.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Live baseline collection cannot resolve host-integration's real prerequisite

**File:** `scripts/ci/collect_ci_baseline.mjs:234`
**Issue:** `workflowNeeds` assigns `host-integration` the prerequisite `admin-drift-docs`, but the collector indexes jobs by `normalizedIdentity(job.name)`. The actual workflow job's display name is `Admin drift and docs`, which normalizes to `admin-drift-and-docs`, not the YAML job ID `admin-drift-docs`. Consequently, every real run with the host job reaches `prerequisiteCompletions` with an unresolved prerequisite and `collectBaseline` aborts, so the documented live baseline command cannot produce records.
**Fix:** Use the same identity namespace for dependencies and observed jobs. For the current display names, return `admin-drift-and-docs`; preferably parse/work from stable workflow job IDs rather than deriving dependencies from display names. Add an integration fixture using the actual workflow display names.

### CR-02: A successfully finalized provider proof is always reported stale without prior input

**File:** `scripts/ci/provider_proof.mjs:91`
**Issue:** `baseRecord` computes `stale` solely from `latest_proved_at`. The workflow never supplies `--latest-proved`, and `classifyProviderProof` does not set the current successful run as the latest proof. Therefore a valid scheduled/manual run is classified `proved` yet carries `stale: true` and is rendered as `Freshness: stale`, falsely telling maintainers that a proof completed moments ago is overdue.
**Fix:** On a `proved` result, set `latest_proved_sha` to the current SHA and `latest_proved_at` to a trusted completion timestamp, then recompute freshness (or render current successful proof as fresh). Pass that timestamp through the workflow and add a fixture asserting that a newly proved record is not stale.

---

_Reviewed: 2026-08-12T02:07:10Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
