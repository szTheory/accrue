---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-11T00:23:30Z
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
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-11T00:23:30Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The collector now handles pagination and the self-test passes, but the verifier does not actually bind stored job evidence to the workflow policy in either input mode. A fabricated or relabeled job can therefore remain valid evidence, defeating the baseline's required-lane proof claim.

## Critical Issues

### CR-01: Collector-record schema declares strict validators but never applies them

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_baseline_contract.sh:62-68`
**Issue:** `step`, `job`, `artifact`, `run`, and `sig` are fully defined at lines 62-67, but the predicate at line 68 repeats only shallow key/type checks instead of calling them. Consequently a collector record can contain arbitrary job names, policy/manifest identities, proof states, timestamps, cache states, or failure signatures as long as the few shallow fields still have the expected container types. The derived-facts pass only recalculates queue time and signatures; it never verifies that a job maps exactly once to `ci_baseline_workflow_policy.json` or that its proof state was derived from that mapping. A forged collector record can thus assert required-lane evidence that was not observed from a recognized CI job.
**Fix:** Apply the declared predicates to every nested value and bind every job to exactly one manifest lane, for example:

```jq
(.runs | type == "array" and length > 0 and all(.[];
  exact(["artifacts", "jobs", "root_failure_signature", "run"])
  and (.run | run)
  and (.jobs | type == "array" and all(.[]; job))
  and (.artifacts | type == "array" and all(.[]; artifact))
  and (.root_failure_signature | sig)
))
```

Then add an invariant that each job name matches exactly one policy lane and that its copied policy fields and `proof_state` equal the policy-derived values.

### CR-02: Canonical validation accepts fabricated job identities

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_baseline_contract.sh:91-131`
**Issue:** The canonical path validates recursive keys and scalar types, then validates aggregates, but never checks a job's `name`, `manifest_identity`, policy fields, or proof state against the policy manifest. This was reproduced by changing `.runs[0].jobs[0].name` to `"Fabricated release lane"` in a copy of `226-CI-BASELINE.json`; `bash scripts/ci/verify_ci_baseline_contract.sh --input <copy>` returned success. The stored JSON is supposed to be authoritative required/advisory proof, so accepting arbitrary relabeling makes it possible to preserve a green aggregate while losing the link to the actual Actions job.
**Fix:** Reuse the collector semantic validator for canonical runs (or define a shared `validate_run_record` jq predicate), and require a one-to-one match from each job name to the manifest regex with equal `manifest_identity`, `policy`, `required_for_release_proof`, `initial_queue_root`, and `staged_critical_chain_order`. Add a self-test that mutates a canonical job name and expects `--input` to fail.

---

_Reviewed: 2026-08-11T00:23:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
