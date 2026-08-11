---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-11T18:45:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - accrue/test/test_helper.exs
  - examples/accrue_host/README.md
  - examples/accrue_host/package.json
  - guides/testing-live-stripe.md
  - scripts/ci/README.md
  - scripts/ci/accrue_host_uat.sh
  - scripts/ci/accrue_host_verify_browser.sh
  - scripts/ci/ci_setup_diagnostic.sh
  - scripts/ci/collect_ci_baseline.mjs
  - scripts/ci/provider_proof.mjs
  - scripts/ci/render_ci_baseline.mjs
  - scripts/ci/render_provider_summary.mjs
  - scripts/ci/verify_ci_baseline.mjs
  - scripts/ci/verify_ci_setup_diagnostics.sh
  - scripts/ci/verify_phase225_required_lane_evidence.sh
  - scripts/ci/verify_provider_proof.mjs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-11T18:45:00Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

The evidence and CI-boundary implementation was reviewed at standard depth, including its formatter, CI workflow wiring, shell diagnostics, and baseline/proof tools. The fixture and syntax checks pass, but the baseline collector can manufacture a `proved` provider state for ordinary push/PR data, directly contradicting the documented proof model. Two further defects can produce incorrect diagnostic or timing evidence.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Missing provider state is treated as completed provider proof

**File:** `scripts/ci/collect_ci_baseline.mjs:95`
**Issue:** When a caller omits `provider_state`, every non-scheduled workflow defaults to `"proved"`. `collectBaseline` is exported and accepts fixture/manual input, so a normal successful push or pull-request timing record without an explicit state is persisted as provider proof even though the live Stripe lane did not run. The rendered baseline explicitly says full-CI runs are not provider proof, so this creates false evidence under the tool's own contract.
**Fix:** Default omitted state to `"non_run"` (or reject it as required) and add a regression test for a successful push/PR with no `provider_state`.

```js
const providerState = run.provider_state ?? "non_run";
if (!PROVIDER_STATES.has(providerState)) {
  fail(`run.provider_state is unsupported: ${providerState}`);
}
```

## Warnings

### WR-01: Wrapper records every host-gate failure as a browser-launch failure

**File:** `scripts/ci/accrue_host_uat.sh:48-50`
**Issue:** `mix verify.full` covers more than Playwright launch. Any failure it returns—including a Mix compilation, format, generated-artifact, database, or other host proof failure—is unconditionally emitted and rendered as `browser_launch`. This adds a false ownership/repair fact to the artifact and summary, undermining the documented “literal state” triage model; it can also accompany the correctly classified record from the inner browser script.
**Fix:** Do not emit a fallback fact when the delegated command has already produced one. If a fallback is needed, introduce a distinct, accurately named `host_verify_full_failure` code and only emit it when no setup fact exists.

### WR-02: Unknown prerequisite names are serialized as a null DAG wait

**File:** `scripts/ci/collect_ci_baseline.mjs:112-119`
**Issue:** A job declaring `needs` whose entries are absent from `completedByName` produces `Math.max(...[])` (`-Infinity`). `dagWait` becomes `Infinity`, and JSON serialization converts it to `null`, indistinguishable from a root job's legitimate no-wait value. The collector therefore silently corrupts dependency timing instead of rejecting incomplete workflow topology.
**Fix:** Require every declared prerequisite to resolve before calculating the wait and fail closed otherwise.

```js
const prerequisiteEnds = needs.map((need) => completedByName.get(normalizedIdentity(need, "job.needs")));
if (needs.length > 0 && prerequisiteEnds.some((end) => end == null)) {
  fail("job prerequisite completion is missing");
}
const dagWait = needs.length === 0 ? null : start - Math.max(...prerequisiteEnds);
```

---

_Reviewed: 2026-08-11T18:45:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
