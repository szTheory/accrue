---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-10T21:52:21Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/ci/ci_baseline_workflow_policy.json
  - scripts/ci/capture_ci_baseline.sh
  - scripts/ci/verify_ci_baseline_contract.sh
  - .github/workflows/ci.yml
  - scripts/ci/README.md
findings:
  critical: 3
  warning: 3
  info: 0
  total: 6
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-10T21:52:21Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The manifest and CI hook are narrowly scoped, but the collector and verifier do not uphold several of the stated fail-closed evidence guarantees. In particular, an API failure can be reported as an authenticated absence, arbitrary sensitive data can be inserted into an otherwise-valid baseline, and the documented collector-to-verifier path is unusable.

## Critical Issues

### CR-01: Any classic-protection API failure is misreported as `not-found`

**File:** `scripts/ci/capture_ci_baseline.sh:74`
**Issue:** The `if ! api_get ...; then` branch converts every non-zero `gh api` result into `{"response_state":"not-found"}`. A network failure, expired token, 401/403, 5xx response, or malformed provider response therefore produces `none-enforced` whenever the effective-rules response is empty. This directly violates D-08's requirement that only a confirmed authenticated 404 may mean not-found, and can falsely assert that no checks are externally enforced.
**Fix:** Capture the HTTP status (for example with `gh api --include`), map only an authenticated 404 to `not-found`, and fail collection for every other status or transport error. Add fixtures/tests for 401, 403, 500, and network failures.

### CR-02: The privacy verifier permits raw secrets under arbitrary keys

**File:** `scripts/ci/verify_ci_baseline_contract.sh:67-68`
**Issue:** Privacy validation rejects only key names matching a short forbidden-word list and query-bearing URLs. It does not enforce the advertised allowlisted schema. Consequently, a candidate that is otherwise identical to the canonical baseline but adds `.runs[0].run.evidence = "ghp_exampletokenvalue"` passes `--input`; this was reproduced during review. A secret, payload, trace, or log content placed beneath a benign key can therefore be committed and pass the CI contract.
**Fix:** Validate exact allowed keys recursively for each schema object (and expected scalar/array types), rejecting all unknown keys rather than trying to blacklist sensitive key names. Add a self-test mutation that inserts a sensitive value below a benign unknown key.

### CR-03: `--input` cannot validate any JSON emitted by the collector

**File:** `scripts/ci/verify_ci_baseline_contract.sh:50-65`
**Issue:** The collector outputs a top-level metadata record containing `runs`, policy metadata, and the provider snapshot, but no `.cohort` or `.aggregates`. `validate_input` unconditionally requires the fixed three-run IDs plus complete cohort provenance and aggregates. A successful fixture collection of run `31322443304` was rejected by `verify_ci_baseline_contract.sh --input` during review. This breaks the documented contract that `--input PATH` validates a collected file and prevents validating a newly captured or single-run result before it is manually transformed into the checked-in cohort.
**Fix:** Split validation into a collector-output schema/privacy validator and a canonical-cohort validator. Have `--input` run the former (and optionally a clearly named `--canonical`/default mode run both), with tests proving that collector output is accepted and malformed output is rejected.

## Warnings

### WR-01: Collector can label an ineligible run's required job as proved

**File:** `scripts/ci/capture_ci_baseline.sh:67`
**Issue:** `proof_state` is derived solely from job policy and conclusion. A successful required job in a rerun, non-dispatch run, or otherwise ineligible run becomes `proved`, despite Phase 226's definition that proof requires an eligible first-attempt run. The aggregate currently ignores ineligible records, but the per-lane evidence is semantically false and can mislead future consumers.
**Fix:** Pass the run eligibility/attempt facts into job classification and emit `proved` only when the run is eligible, attempt one, the lane is required, and the conclusion is success; otherwise choose the appropriate non-proof state. Add an ineligible-rerun fixture assertion.

### WR-02: Failure signatures discard the failure conclusion

**File:** `scripts/ci/capture_ci_baseline.sh:69`
**Issue:** The signature tuple includes only `failed-lane` and lane identities. A failure, timeout, and cancellation of the same lane produce the same signature, although the Phase 226 contract calls for the signature to derive from normalized conclusions as well. This loses a material diagnostic distinction and makes a timeout indistinguishable from a test failure.
**Fix:** Construct the normalized tuple from sorted `{manifest_identity, normalized_conclusion}` pairs and validate/recompute that representation in the verifier. Add a mutation that changes a failed lane's conclusion and requires the signature to change.

### WR-03: Jobs and artifacts are silently truncated after the first API page

**File:** `scripts/ci/capture_ci_baseline.sh:59-60`
**Issue:** Both endpoints request `per_page=100` but do not follow pagination. When a workflow run has more than 100 jobs or artifacts, later records are omitted while capture still succeeds; omitted required jobs can make the evidence and derived proof incomplete.
**Fix:** Use `gh api --paginate` and merge/reduce each page before classification, or inspect and reject a response that advertises a next page. Add a multi-page fixture regression test.

---

_Reviewed: 2026-08-10T21:52:21Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
