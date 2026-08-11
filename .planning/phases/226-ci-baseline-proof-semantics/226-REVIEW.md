---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-11T01:17:35Z
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

**Reviewed:** 2026-08-11T01:17:35Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The metadata and schema checks are extensive, and the self-test passes. However, the collector and verifier do not establish that evidence came from the declared `CI` workflow or that it covers every required lane. They can therefore certify incomplete or unrelated successful work as release proof. The policy manifest is also not checked against the complete live workflow topology, so it can silently become stale.

## Critical Issues

### CR-01: Collector accepts a run from any workflow

**File:** `scripts/ci/capture_ci_baseline.sh:91-105`
**Issue:** The collector reads `$raw.name` into `run.workflow`, but never compares it with `policy.workflow`. The verifier repeats this gap: its record schema only requires `run.workflow` to be a non-empty string (`verify_ci_baseline_contract.sh:96-99`) and candidate semantics only classify job display names (`:70-85`). A workflow other than `CI` that emits matching job names can consequently be captured and given `proof_state: "proved"` for required lanes.
**Fix:** Fail closed in the collector unless `$raw.name == $policy.workflow`, and independently require `.run.workflow == $policy[0].workflow` in both collector-record and canonical validation. Add a fixture that changes only the run name to a non-`CI` value and expects both collection and validation to fail.

### CR-02: A partial successful run is accepted as required-lane proof

**File:** `scripts/ci/verify_ci_baseline_contract.sh:70-85`
**Issue:** `candidate_job_semantics` validates `all(.jobs[]; ...)`, but never requires the observed job identities to include the policy's complete `required_for_release_proof` set. This is not merely theoretical: the self-test constructs a record containing only the docs and primary release-gate jobs and explicitly accepts it at lines 197-200. Such a record can contain `proved` required lanes despite omitting all other required gates, making it unsafe to consume as release proof.
**Fix:** For an eligible record, derive the unique observed `manifest_identity` values and require them to equal (or, where intentional conditional lanes are modeled, contain) the manifest's required lane identities; separately require all those required lanes to be `proved`. Add a negative fixture that removes one required lane from an otherwise valid eligible record.

### CR-03: The policy manifest is not bound to the complete live CI topology

**File:** `scripts/ci/verify_ci_baseline_contract.sh:167-178`
**Issue:** `validate_repository_contract` checks only six hard-coded job IDs plus a few chain substrings. It never verifies every policy lane's regex, policy tier, matrix expansion, or `initial_queue_root`/critical-chain designation against `.github/workflows/ci.yml`. `validate_policy_manifest` only compares the manifest to the fixed historical canonical document (lines 25-28). A later workflow edit can demote, rename, remove, or add a required lane while this CI gate continues to pass and the collector continues to assign proof according to stale policy.
**Fix:** Add a deterministic workflow-to-policy conformance check covering every configured lane and all matrix display-name expansions, including required/advisory behavior and the conditional `live-stripe` trigger. Make the CI contract fail when the policy and current workflow differ, and add mutation tests for a non-hard-coded lane (for example `phase18-tax-gate`) and a matrix support-tier change.

---

_Reviewed: 2026-08-11T01:17:35Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
