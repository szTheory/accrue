---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-11T01:54:37Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .github/workflows/ci.yml
  - scripts/ci/README.md
  - scripts/ci/capture_ci_baseline.sh
  - scripts/ci/ci_baseline_workflow_policy.json
  - scripts/ci/verify_ci_baseline_contract.sh
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-11T01:54:37Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The CI hook, policy manifest, collector, and verifier were reviewed, and the supplied `--self-test` passes. However, the public collector-record validation accepts tampered derived timing and failure-category facts, so an untrusted baseline record can be certified with incorrect evidence.

## Critical Issues

### CR-01 [BLOCKER]: Collector record accepts forged critical-chain duration

**File:** `scripts/ci/verify_ci_baseline_contract.sh:131-136`
**Issue:** For an eligible collector record, the verifier recomputes and compares `runner_queue_seconds`, but only checks that `staged_critical_chain_seconds` is non-null. It never recomputes the duration from the configured critical-chain jobs' timestamps. A record with that field increased by 42 seconds was accepted by `bash scripts/ci/verify_ci_baseline_contract.sh --input ...`, despite no corresponding timestamp change. This lets a fabricated duration affect later baseline/selection decisions.
**Fix:** Derive the chain duration in this predicate and require equality, mirroring the collector computation:

```jq
([.jobs[] | select(.staged_critical_chain_order != null)]
 | sort_by(.staged_critical_chain_order)) as $chain |
($chain | map(.started_at | fromdateiso8601) | min) as $start |
(($chain | map(.completed_at | fromdateiso8601) | max) - $start) as $duration |
$record.run.staged_critical_chain_seconds == $duration
```

Also add a self-test mutation that changes only this derived field and expects rejection.

### CR-02 [BLOCKER]: Failure signature category is not bound to failing lanes

**File:** `scripts/ci/verify_ci_baseline_contract.sh:130-135`
**Issue:** The verifier confirms the lane-conclusion list and confirms that the ID is a hash of the *supplied* category plus that list, but never requires `category` to be `no-failure` when the list is empty and `failed-lane` otherwise. Changing a successful run's category to `failed-lane` and recomputing its ID is accepted. The baseline can therefore report a false root-cause category while still passing the contract.
**Fix:** Derive the category and include it in the equality checks:

```jq
(if ($pairs | length) == 0 then "no-failure" else "failed-lane" end) as $category |
$record.root_failure_signature.category == $category and
$record.root_failure_signature.id == ("ci-root-v2-" + (([$category, $pairs] | tojson | @base64) | gsub("="; "")))
```

Add positive and negative self-test cases for both categories.

## Warnings

### WR-01 [WARNING]: Collector schema leaves declared integer identifiers unchecked

**File:** `scripts/ci/verify_ci_baseline_contract.sh:117-125`
**Issue:** `validate_collector_record` defines strict `run`, `job`, and `artifact` validators, but the final predicate uses only abbreviated inline checks instead. Consequently, it accepts a collector record whose `runs[0].run.id` is `1.5`; GitHub Actions run identifiers are integers. This weakens the documented schema boundary and can produce invalid identifiers in downstream consumers.
**Fix:** Apply the declared validators in the final predicate (for example, `(.run | run)`, `all(.jobs[]; job)`, and `all(.artifacts[]; artifact)`) or duplicate their integer constraints into the inline checks. Add a fractional-ID rejection test.

---

_Reviewed: 2026-08-11T01:54:37Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
