---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-11T02:27:34Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .github/workflows/ci.yml
  - scripts/ci/README.md
  - scripts/ci/capture_ci_baseline.sh
  - scripts/ci/ci_baseline_workflow_policy.json
  - scripts/ci/verify_ci_baseline_contract.sh
findings:
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-11T02:27:34Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The new baseline gate has a passing self-test, but it does not consistently bind collected evidence to the branch-protection scope or bind its policy/topology snapshots to the facts it claims to protect. This permits a stale or non-main run to be accepted as release proof, and permits a matrix display-name drift that breaks future collection while the CI contract still passes.

## Critical Issues

### CR-01: Canonical baseline accepts a stale policy-manifest version

**File:** `scripts/ci/verify_ci_baseline_contract.sh:201`
**Issue:** The canonical discriminator checks only that `policy_manifest.schema_version` is an integer. It never requires it to equal the current manifest's version. The checked-in manifest is schema version `3`, while the canonical evidence declares version `2`, yet `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` passes. This makes the supposedly versioned baseline proof accept evidence attributed to a different policy contract.
**Fix:** Bind canonical `policy_manifest.schema_version` (and workflow in the same predicate) to `$policy_manifest`, as the collector-record validator already does. For example, pass the policy via `--slurpfile policy` and require `.policy_manifest == {schema_version: $policy[0].schema_version, workflow: $policy[0].workflow}`; update the canonical evidence deliberately when the policy schema changes.

### CR-02: Matrix display-name topology is declared but never validated

**File:** `scripts/ci/verify_ci_baseline_contract.sh:253`
**Issue:** `workflow_topology[].display_names` is part of the policy contract, but the only loop over it is a no-op (`do :; done`). The release-gate validation checks merely the required/advisory counts. Changing a matrix `compatibility` value (for example, `Floor` to `Foundation`) changes the Actions job display name and makes the collector's anchored lane regex reject subsequent runs, but this repository gate still passes. The same gap exists for the policy's generated display-name contract generally.
**Fix:** Parse the relevant matrix values (or use a YAML parser) and assert that the rendered matrix display names exactly equal `.display_names` for every matrix role. At minimum, remove the no-op and compare the release matrix's rendered expected names and the Playwright shard names to the manifest values.

### CR-03: Collector accepts runs outside the `main` protection scope

**File:** `scripts/ci/capture_ci_baseline.sh:91-100`
**Issue:** The collector accepts any successful first-attempt `workflow_dispatch` run named `CI`, but it never checks the run's branch/ref. Later it snapshots required checks specifically from `/branches/main` (lines 111-114). A manually dispatched CI run from a feature branch or fork can therefore be represented alongside `main` branch-protection data and marked eligible/release-proved, even though the protection policy being claimed did not govern that run.
**Fix:** Retain and validate `head_branch`/ref from the run response and require `main` before setting a run eligible or publishing it. Ideally also record the verified ref in the reduced record and reject a run whose SHA/ref cannot be tied to the `main` policy snapshot.

---

_Reviewed: 2026-08-11T02:27:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
