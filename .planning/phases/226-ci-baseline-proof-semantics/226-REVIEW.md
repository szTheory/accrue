---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-12T02:44:11Z
depth: standard
files_reviewed: 18
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
  - scripts/ci/verify_provider_proof.mjs
findings:
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-12T02:44:11Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

The runtime evidence path has a blocking correctness failure: the live-suite formatter treats every excluded default test as a failed selected provider test. I reproduced this with `ACCRUE_PROVIDER_MANIFEST=... mix test.live`: ExUnit reported 10 skipped live tests and 2,114 excluded tests, while the manifest recorded `selected_count: 2124` and `failed_count: 2114`. The baseline collector also derives matrix-dependent timing from arbitrary response ordering rather than the matrix boundary.

## Critical Issues

### CR-01: Excluded tests are recorded as failed provider assertions

**File:** `accrue/test/support/live_proof_formatter.ex:43-49`

**Classification:** BLOCKER

**Issue:** `mix test.live` emits a `:test_finished` event for every test excluded by `--only live_stripe`. Those events have an excluded state, but the catch-all clause increments both `selected_count` and `failed_count`. Therefore the live provider manifest includes the entire ordinary suite as failed provider evidence. With configured credentials, the finalizer will still classify the manifest as `failed`; with missing credentials it also reports a wildly false selected count. The formatter unit test only supplies pass/skip/failure states, so it never exercises an actual `mix test.live` run or an excluded state.

**Fix:** Explicitly ignore excluded test states, then add an integration test that runs a tagged suite with at least one excluded test and asserts only selected live tests enter the manifest.

```elixir
defp increment(state, {:excluded, _reason}), do: state

defp increment(state, nil), do: %{state | selected_count: state.selected_count + 1,
  passed_count: state.passed_count + 1}
```

## Warnings

### WR-01: DAG wait uses an arbitrary release-matrix shard completion

**File:** `scripts/ci/collect_ci_baseline.mjs:148`

**Classification:** WARNING

**Issue:** The completion map is built with `new Map(...)`, so repeated normalized job names overwrite one another according to REST response order. `release-gate` is a matrix job and all its display names normalize to `release-gate`; a dependent job waits for every shard, but the collector retains only one arbitrary shard completion. This makes `dag_wait_ms` non-deterministic and can overstate wait time by measuring from an earlier shard instead of the final prerequisite.

**Fix:** Reduce completions by normalized identity, retaining the maximum completion timestamp, and add a fixture with two `release-gate` matrix jobs returned in both orders.

```js
const completed = new Map();
for (const job of run.jobs || []) {
  const key = normalizedIdentity(job.name, "job.name");
  const endedAt = timestamp(job.completed_at, "job.completed_at");
  completed.set(key, Math.max(completed.get(key) ?? -Infinity, endedAt));
}
```

### WR-02: Critical-path percentiles select an arbitrary release-matrix shard

**File:** `scripts/ci/render_ci_baseline.mjs:29-41`

**Classification:** WARNING

**Issue:** `jobs.find(...)` chooses the first `release-gate` record. Because the release gate is a matrix, this depends on record/API ordering and verifies host start only against that one shard. The reported span may begin after another release shard started and does not prove that host started after the entire release stage. Consequently the "measured critical path" percentile can be incorrect despite having 20 samples.

**Fix:** Collect all successful release-gate shards, require host to start after their latest completion, and define the stage start deterministically (normally the earliest release-shard start for wall-clock path measurement). Cover reordered matrix rows in `verify_ci_baseline.mjs`.

### WR-03: Manual-dispatch documentation claims a workflow setting that does not exist

**File:** `guides/testing-live-stripe.md:129-132`

**Classification:** WARNING

**Issue:** The guide says `continue-on-error: true` makes `live-stripe` advisory, but `.github/workflows/ci.yml` does not set `continue-on-error` on that job. A failed manual dispatch therefore has a failed job/workflow, contrary to the stated operational behavior.

**Fix:** Either add an explicit job-level `continue-on-error: true` if that is the intended policy, or update the guide to say that the lane is non-merge-blocking because it is not selected for pull requests, while its selected runs still fail visibly.

---

_Reviewed: 2026-08-12T02:44:11Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
