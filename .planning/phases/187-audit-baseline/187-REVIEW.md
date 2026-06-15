---
phase: 187-audit-baseline
reviewed: 2026-06-15T03:23:47Z
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 187: Code Review Report

**Reviewed:** 2026-06-15T03:23:47Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Re-reviewed the Phase 187 Playwright baseline capture, live interaction probes, visual scoring CLI, artifact generator, package scripts, and E2E auth/plug support after the prior fixes. The prior findings for viewport restoration, malformed score response failures, score validation, and unverifiable trace evidence are resolved in the current source. One audit-integrity blocker remains: when visual scoring is skipped for missing credentials, the artifact generator records only an observation and still produces artifacts with zero harness failures for that condition.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Missing visual scoring is not represented as a failure or defect

**Classification:** BLOCKER
**File:** `accrue_admin/e2e/score-visuals.mjs:35`, `accrue_admin/e2e/baseline-artifacts.mjs:699`
**Issue:** `score-visuals.mjs` exits 0 when `ANTHROPIC_API_KEY` is absent, and `baseline-artifacts.mjs` handles the missing `findings.ndjson` by appending a `vision-scoring-unavailable` observation only. That observation is not added to `harness_failures`, `commandDefects`, or `defects.ndjson`, so a baseline can be generated with screenshot cells marked covered, `score: null`, no visual scoring findings, and no failing status for the missing scorer. This preserves the prior partial-failure fix for malformed responses, but the no-key path still silently removes the visual rubric from the canonical baseline.
**Fix:** Make no-key scoring produce a nonzero producer status for baseline runs, or route the missing findings file into a concrete harness failure/defect. For example:
```js
if (!fs.existsSync(INPUTS.findings)) {
  const evidence_ref = "accrue_admin/test-results/admin-visuals/findings.ndjson";
  harnessFailures.push({
    kind: "harness-error",
    evidence_ref,
    message: "Vision findings are unavailable; run score-visuals with ANTHROPIC_API_KEY or record an explicit waiver."
  });
  commandDefects.push({
    severity: "high",
    surface: "score-visuals producer",
    surface_type: "page-flow",
    persona_job: "Produce Phase 187 visual rubric evidence.",
    reproduction: "Run npm run score-visuals before npm run baseline:artifacts.",
    expected: "Every captured visual screenshot has 12 scored rubric dimensions or a traceable waiver.",
    actual: "admin-visuals/findings.ndjson is missing.",
    rubric_dimension: "state-coverage",
    overlay_tags: [],
    cell_id: "phase187__score-visuals__producer-status",
    evidence_refs: [evidence_ref],
    owner_phase: "187",
    status: "gap",
    notes: "Visual scoring was skipped or unavailable."
  });
}
```

---

_Reviewed: 2026-06-15T03:23:47Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
