---
phase: 227-measured-critical-path-improvement
reviewed: 2026-08-28T20:05:05Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/test/accrue/docs/release_guidance_test.exs
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - scripts/ci/README.md
  - scripts/ci/verify_ci_baseline.mjs
  - scripts/ci/verify_ci_critical_path.mjs
  - scripts/ci/verify_ci_setup_diagnostics.sh
  - scripts/ci/verify_provider_proof.mjs
findings:
  critical: 6
  warning: 1
  info: 0
  total: 7
status: issues_found
---

# Phase 227: Code Review Report

**Reviewed:** 2026-08-28T20:05:05Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

The critical-path verifier is not safe to use as a decision gate. It accepts duplicate or wrong-event timing samples, does not enforce the contract's required job identities, accepts repeated job URLs as three Playwright shards, scans only top-level evidence keys for secrets, and silently succeeds for unknown/no-op invocations. Its documented fixture/preflight command also fails against the reviewed workflow because the fixture is coupled to a frozen digest and an obsolete provider condition.

The other scoped fixture and test commands passed: the CI baseline fixtures, provider-proof fixtures, setup-diagnostics verifier, and seven targeted ExUnit tests.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Comparison evidence accepts duplicate, non-dispatch observations

**Classification:** BLOCKER

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:101-119`

**Issue:** `eligible` admits pull-request and push records even though the contract authorizes only attempt-1 `workflow_dispatch` samples. `verifyComparisonEvidence` requires merely `accepted.length >= 3`; it does not require exactly three records, unique run IDs, one immutable SHA, `provider_state: non_run`, the contract fingerprint, or the required proof vector. Three references to the same fabricated push record therefore return `{keep: true}`. This directly contradicts the documented prohibition on reruns, replacement cohorts, pull requests, and mutable/non-candidate samples.

**Fix:** Validate every admission predicate from `contract.measurement_topology` and `contract.run_budget`, then require exactly three unique `(run_id, sha)` observations at the one candidate SHA. Reject records unless `event_class === "workflow_dispatch"`, `run_attempt === 1`, `provider_state === "non_run"`, and the fingerprint equals `contract.measurement_topology.candidate_fingerprint`. Add negative fixtures for duplicate records, push/PR records, mixed SHAs, extra fourth samples, and missing provider state.

#### CR-02: Candidate admission ignores the required job identities

**Classification:** BLOCKER

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:144-164`

**Issue:** `candidateRequiredPathPassed` only checks that at least ten arbitrary object values have `conclusion: "success"`. It never compares the keys with `contract.proof_vector.required_job_identities`, which contains twelve exact identities. The fixture itself reinforces the gap by using `job_0` through `job_9`. Replacing the real evidence's job keys with forged names still passes `verifyFinalDecision`, so missing required gates can be represented as a complete candidate path.

**Fix:** Normalize and compare the exact key set against `contract.proof_vector.required_job_identities`, reject missing and unexpected identities, and validate the expected cardinality and per-identity conclusion. Replace the synthetic `job_N` fixture with the twelve contractual identities and add missing/renamed/extra-job rejection cases.

#### CR-03: Rollback proof accepts repeated or incorrectly identified job URLs

**Classification:** BLOCKER

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:168-181,197-215,374-420`

**Issue:** Offline rollback validation checks only that three Playwright URL strings exist and look repository-bound; it does not require three distinct shard IDs. Live validation resolves the recorded job ID and conclusion but never checks the job's stable identity against the requested role. Replacing all three recorded shard URLs with the same first-shard URL still passes `verifyFinalDecision`. The same weakness lets arbitrary successful jobs stand in for host, annotation, or provider roles.

**Fix:** Require unique job IDs, require exactly shards 1/3, 2/3, and 3/3, and compare each fetched job's normalized name to its expected contract identity. Apply the same identity check to host, annotation, release, and provider jobs. Add adversarial fixtures for duplicate shard URLs and role-swapped URLs.

#### CR-04: Nested evidence can carry secrets or provider payloads

**Classification:** BLOCKER

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:279-297`

**Issue:** The privacy filter checks only `Object.keys(record)`. Evidence is deeply nested (`restoration_run.provider`, `required_path`, `temporary_ref`, and other objects), so forbidden keys such as `provider_payload`, `token`, `logs`, or `user_data` pass when placed below the top level. A final-decision invocation containing `nested.provider_payload: "sk_test_secret"` exited successfully. This permits credentials or provider data to enter the durable NDJSON evidence that the contract claims is privacy-safe.

**Fix:** Recursively walk every object and array, reject forbidden keys at any depth, and validate values against an explicit schema/allowlist rather than relying only on key-name regexes. Add nested-object and nested-array privacy-rejection fixtures, including the allowed credential-status field with a strictly boolean/enum value schema.

#### CR-05: The documented fixture/preflight verifier is broken against the reviewed workflow

**Classification:** BLOCKER

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:48-50,80-86,229-243`

**Issue:** `verifyFixtures` reads the mutable current workflow and compares its normalized digest with a frozen Phase 227 digest. The reviewed workflow now has the provider-trigger job and a different `live-stripe` condition, while `verifyMeasurementPreflight` still hard-codes the older schedule/manual-only condition. The documented command at `scripts/ci/README.md:67-70` fails immediately with `workflow changed outside the one permitted host prerequisite deletion`; refreshing only the digest would then fail the obsolete condition check. The verifier's own fixture suite is therefore permanently red on the source tree it ships with.

**Fix:** Make fixture tests load an immutable Phase 227 workflow fixture rather than the mutable live workflow. If current-workflow compatibility remains supported, model allowed later topology changes explicitly and validate the current provider-trigger semantics instead of matching one obsolete condition string. Update the README so historical measurement instructions cannot be mistaken for a runnable current preflight.

#### CR-06: Unknown or no-op CLI invocations exit successfully

**Classification:** BLOCKER

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_ci_critical_path.mjs:441-491`

**Issue:** Argument validation rejects only unknown flags beginning with `--require-`. There is no allowlist for other options and no requirement that at least one verification action execute. A typo such as `--verify-live-action` (singular) with valid evidence exits 0 without reading or verifying anything. CI or operator automation can therefore report a successful verification after performing no check.

**Fix:** Parse arguments through one strict option table, reject every unknown flag, validate option values, and require at least one action (`--fixtures`, `--workflow`, a supported `--require-*`, `--render-evidence`, or `--verify-live-actions`). Emit a usage error and nonzero exit when no action runs. Add typo and no-action regression tests.

### Warnings

#### WR-01: Provider-proof verifier misresolves checkout paths containing spaces

**Classification:** WARNING

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_provider_proof.mjs:15`

**Issue:** `new URL(import.meta.url).pathname` leaves percent escapes intact. In a checkout such as `/tmp/accrue checkout`, the computed path contains `%20`, so fixture and workflow reads target a nonexistent directory. The critical-path verifier already uses the correct Node conversion helper.

**Fix:** Import `fileURLToPath` from `node:url` and compute the root with `path.dirname(fileURLToPath(import.meta.url))`.

---

_Reviewed: 2026-08-28T20:05:05Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
