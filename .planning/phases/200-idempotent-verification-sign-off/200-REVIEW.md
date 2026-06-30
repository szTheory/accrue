---
phase: 200-idempotent-verification-sign-off
reviewed: 2026-06-30T18:51:12Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue_admin/e2e/admin-group-contracts.spec.js
  - accrue_admin/e2e/admin-page-flow-phase200.spec.js
  - accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js
  - accrue_admin/e2e/phase200-judge.mjs
  - accrue_admin/e2e/phase200-scorecard.mjs
  - accrue_admin/e2e/phase200-signoff.mjs
  - accrue_admin/e2e/phase200-storybook-helpers.js
  - accrue_admin/lib/accrue_admin/dev/storybook.ex
  - accrue_admin/lib/accrue_admin/router.ex
  - accrue_admin/package.json
  - accrue_admin/storybook/_support/registry_story.ex
  - accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs
  - accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs
  - accrue_admin/test/accrue_admin/theme_test.exs
  - scripts/ci/generate_phase200_closeout_reports.mjs
  - scripts/ci/verify_phase200_admin_guardrails.sh
  - scripts/ci/verify_phase200_ci_contract.sh
  - scripts/ci/verify_phase200_guardrail_contract.sh
  - scripts/ci/verify_phase200_scorecard.mjs
  - scripts/ci/verify_phase200_signoff.mjs
  - storybook/components/component_registry.story.exs
  - storybook/groups/component_groups.story.exs
findings:
  critical: 5
  warning: 0
  info: 0
  total: 5
status: issues_found
---

# Phase 200: Code Review Report

**Reviewed:** 2026-06-30T18:51:12Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

Reviewed the Phase 200 CI, Playwright evidence writers, scorecard reducer/verifier, judge/sign-off generator/verifier, Storybook support, and related Elixir tests. The main defects are false-green paths: invalid coverage evidence can be upgraded to covered, missing evidence files can satisfy the scorecard verifier, failed Storybook closeout can still ACCEPT, and CI can pass a REJECT sign-off or skip final scorecard verification.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Invalid coverage evidence is normalized to covered

**Classification:** BLOCKER
**File:** `accrue_admin/e2e/phase200-scorecard.mjs:169`
**Issue:** `normalizeCoverage()` returns `"covered"` for any missing or unknown `coverage_status`, and `contractedCell()` applies that to evidence rows at line 325. A malformed/failing evidence row such as `coverage_status: "failed"` is therefore converted into a covered final cell instead of producing a regression. I verified this with a temp fixture: the reducer returned `{"regressions":0,"finalCoverage":"covered","finalScore":3}` for a row marked `"failed"`.
**Fix:**
```js
function normalizeCoverage(value, label = "coverage_status") {
  const coverage = String(value ?? "").trim();
  if (!COVERAGE_RANK.has(coverage)) {
    throw new Error(`${label}: invalid coverage_status "${value}"`);
  }
  return coverage;
}
```
Call this from `contractedCell()` with the row/cell id in the label, and add a self-test that an unknown status produces a blocking regression.

#### CR-02: The scorecard verifier accepts evidence refs for files that do not exist

**Classification:** BLOCKER
**File:** `scripts/ci/verify_phase200_scorecard.mjs:281`
**Issue:** `validateEvidence()` only checks that a ref is syntactically allowed and present in `artifacts.manifest.json`; it never verifies that `accrue_admin/test-results/...` or `.planning/phases/200...` refs exist on disk. A temp verifier fixture with `evidence_refs: ["accrue_admin/test-results/phase200/does-not-exist.json"]` and a matching manifest entry returned `ok: true` while the file was absent. This means final cells can be signed off with phantom evidence.
**Fix:** For every file-backed repo-relative evidence ref, resolve it under the repo root and require `fs.existsSync`, `isFile()`, `bytes > 0`, and a matching SHA-256 when the manifest supplies one. Only exempt explicit non-file schemes such as `playwright-trace:` if those are intentionally external.

#### CR-03: Failed or missing Storybook evidence can still produce ACCEPT

**Classification:** BLOCKER
**File:** `scripts/ci/generate_phase200_closeout_reports.mjs:268`
**Related:** `accrue_admin/e2e/phase200-judge.mjs:654`, `accrue_admin/e2e/phase200-signoff.mjs:150`
**Issue:** `renderStorybookCoverage()` marks the report as fail when Storybook rows are empty or failed, but `applyCommandStatuses()` unconditionally writes `storybook: { status: "passed" }`. The judge skips missing optional `storybook-a11y.json`, and sign-off never parses `200-STORYBOOK-COVERAGE.md` status. I verified a fixture with `200-STORYBOOK-COVERAGE.md` set to `**Status:** fail` and manifest `storybook: passed`; `generatePhase200Signoff()` still returned `decision: "ACCEPT"`.
**Fix:** Derive manifest command statuses from `summary.storybook.length`, `summary.storyFailures`, page-flow closure, and host leak evidence. Treat missing `storybook-a11y.json` as blocking for STY-03, or make sign-off parse and reject non-pass `200-STORYBOOK-COVERAGE.md`.

#### CR-04: CI can pass a REJECT sign-off

**Classification:** BLOCKER
**File:** `scripts/ci/verify_phase200_signoff.mjs:347`
**Related:** `scripts/ci/verify_phase200_admin_guardrails.sh:33`, `accrue_admin/package.json:26`
**Issue:** The sign-off verifier treats a structurally valid `Final maintainer decision: REJECT` as `ok: true`; the self-test explicitly asserts this. The CI runner calls `npm run phase200:signoff`, which is only `node ../scripts/ci/verify_phase200_signoff.mjs`, so the merge-blocking Phase 200 guardrail can be green while the final decision is REJECT. I verified a REJECT markdown fixture with no artifact package returned `{"ok":true,"decision":"REJECT","failures":0}`.
**Fix:** Add a CI mode such as `--require-accept` that fails unless `decision === "ACCEPT"`, and use it from `phase200:signoff` / `verify_phase200_admin_guardrails.sh`. Keep REJECT structural validation as a separate local/draft mode if needed.

#### CR-05: The guardrail runner skips full scorecard verification when final artifacts are absent

**Classification:** BLOCKER
**File:** `scripts/ci/verify_phase200_admin_guardrails.sh:22`
**Related:** `accrue_admin/package.json:25`
**Issue:** The runner executes only the baseline-only scorecard script, then conditionally runs the full verifier only if final artifacts already exist. If they are absent, it prints “baseline verifier already passed” and continues. That makes the final artifact package optional in the main guardrail path and relies on stale/preexisting files plus the sign-off verifier behavior above.
**Fix:** After the evidence-producing Playwright steps, run `node accrue_admin/e2e/phase200-scorecard.mjs` and `node scripts/ci/verify_phase200_scorecard.mjs` unconditionally. Remove the “if files exist” skip, and update the CI/guardrail contract tests so missing `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, or `artifacts.manifest.json` fails closed.

---

_Reviewed: 2026-06-30T18:51:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
