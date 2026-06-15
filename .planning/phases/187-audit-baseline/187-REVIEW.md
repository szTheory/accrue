---
phase: 187-audit-baseline
reviewed: 2026-06-15T03:12:11Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - accrue_admin/e2e/admin-baseline.spec.js
  - accrue_admin/e2e/admin-interactions.spec.js
  - accrue_admin/e2e/baseline-artifacts.mjs
  - accrue_admin/e2e/baseline-manifest.js
  - accrue_admin/e2e/score-visuals.mjs
  - accrue_admin/package.json
  - accrue_admin/test/support/e2e_auth_adapter.ex
  - accrue_admin/test/support/e2e_plug.ex
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 187: Code Review Report

**Reviewed:** 2026-06-15T03:12:11Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the Phase 187 Playwright baseline capture, visual scoring CLI, artifact aggregator, package scripts, and E2E auth/plug support. The main risk is audit integrity: several paths can silently produce incomplete or incorrectly labeled baseline evidence while still exiting successfully.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Targeted viewport probes corrupt later canonical captures

**Classification:** BLOCKER
**File:** `accrue_admin/e2e/admin-baseline.spec.js:241`
**Issue:** `captureTargetedSurface()` mutates the shared Playwright page viewport for every targeted breakpoint and leaves it at the final width, 1440px. The outer loop then continues to the next surface and calls `captureCanonicalSurface()` without restoring the project viewport. In the `chromium-mobile` project, every canonical surface after the first targeted-risk surface is captured at desktop width but recorded with mobile `viewport_width` metadata from the manifest. This corrupts the Phase 187 mobile baseline and any Phase 192 comparison built from it.
**Fix:**
```js
async function captureTargetedSurface(page, surface, route, projectName, observations) {
  if (!targetedRisk(surface)) return;

  const originalViewport = page.viewportSize();
  try {
    // existing targeted breakpoint loop
  } finally {
    if (originalViewport) {
      await page.setViewportSize(originalViewport);
    }
  }
}
```
Also consider explicitly setting the project viewport at the start of `captureCanonicalSurface()` so canonical captures do not depend on previous probe state.

### CR-02: Visual scoring drops malformed model responses and exits successfully

**Classification:** BLOCKER
**File:** `accrue_admin/e2e/score-visuals.mjs:221`
**Issue:** Parse failures, non-array responses, and responses missing the exact 12 dimensions are logged and skipped, but the process still exits 0. `baseline-artifacts.mjs` only sees a successful producer with a partial `findings.ndjson`, so missing screenshots are not represented as harness failures or defects. A transient LLM formatting issue can therefore remove visual evidence from the canonical baseline without failing the command.
**Fix:**
```js
let failedImages = 0;

// In each malformed-response branch:
failedImages++;
continue;

// After the loop:
if (failedImages > 0) {
  console.error(`[score-visuals] ${failedImages} image(s) could not be scored`);
  process.exit(1);
}
```
If partial output must be retained, also emit structured failure rows that `baseline-artifacts.mjs` can route into `harness_failures`.

### CR-03: Non-numeric or out-of-range LLM scores are accepted and later discarded

**Classification:** BLOCKER
**File:** `accrue_admin/e2e/score-visuals.mjs:255`
**Issue:** The scoring CLI copies `finding.score` directly into NDJSON without validating that it is an integer from 0 through 3. The artifact generator then ignores any non-number score in `defectFromFinding()` (`typeof finding.score !== "number"`), so a common model response like `"score": "1"` would be written as successful evidence but omitted from the defect ledger and `belowBar` count.
**Fix:**
```js
const score = Number(finding.score);
if (!Number.isInteger(score) || score < 0 || score > 3) {
  failedImages++;
  continue;
}

const enriched = {
  // ...
  score,
  // ...
};
```
Apply the same strict validation to required string fields before appending the NDJSON line.

## Warnings

### WR-01: Interaction observations reference a trace path that is never written

**Classification:** WARNING
**File:** `accrue_admin/e2e/admin-interactions.spec.js:60`
**Issue:** `makeRecorder()` hardcodes `accrue_admin/test-results/admin-interactions/${projectName}/trace.zip` as evidence for every observation, but this spec only writes `observations.ndjson` under that directory. Playwright trace output is managed by the test runner and normally lands under a per-test output directory, not this hardcoded path. The resulting observation ledger claims trace-backed evidence that downstream reviewers cannot open from the referenced location.
**Fix:** Capture the real trace artifact path from Playwright output, copy it into `test-results/admin-interactions/${projectName}/trace.zip`, or remove the file reference and use only a verifiable evidence URI until the artifact exists.

---

_Reviewed: 2026-06-15T03:12:11Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
