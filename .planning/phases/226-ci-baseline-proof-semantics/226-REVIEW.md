---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-12T17:56:43Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - accrue/test/test_helper.exs
  - examples/accrue_host/README.md
  - examples/accrue_host/package.json
  - guides/testing-live-stripe.md
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-12T17:56:43Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The provider-proof, host-diagnostic, and CI-baseline sources were reviewed in context, including the CI workflow they consume. The included fixture suites pass, but two defects make the resulting CI evidence unreliable: historical runs are evaluated against the current workflow DAG, and a syntactically complete but forged NDJSON record can alter the rendered evidence report.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Historical runs are parsed with the current workflow topology

**Classification:** BLOCKER
**File:** `/Users/jon/projects/accrue/scripts/ci/collect_ci_baseline.mjs:280-385`
**Issue:** `liveRuns` fetches the workflow file at each run's `head_sha` only to hash it at line 365. All subsequent identity, runner, and dependency resolution at lines 372-385 calls `workflowRunnerContracts()` without that fetched content, which defaults to the repository's current `ci.yml`. A legitimate historical run whose job names, matrix aliases, or `needs` differ from the current workflow is therefore rejected as unresolved or assigned the wrong DAG/runner metrics. This defeats the collector's stated revision-aware historical baseline and can produce a falsely incomplete or incorrect timing cohort after normal workflow evolution.

**Fix:** Parse and retain contracts from the fetched `workflowSource` for that run, then pass those contracts to `resolveWorkflowJobIdentity`, `workflowRunnerImage`, and `workflowNeeds`. Use the current workflow only when collecting a current local fixture intentionally has no historical source.

### CR-02: Renderer validates field names but permits forged Markdown evidence

**Classification:** BLOCKER
**File:** `/Users/jon/projects/accrue/scripts/ci/render_ci_baseline.mjs:84-90`
**Issue:** The renderer calls `validateRecord`, but that function only checks schema version, record kind, allowed fields, and a few enums; it does not validate URLs, timestamps, IDs, or numeric fields. The raw `run_url` and `job_url` are then interpolated directly into Markdown links. For example, a valid-field run record with `run_url: "https://x.test/)\\n# forged"` renders an injected `# forged` heading. Since this command accepts arbitrary `--input` NDJSON and produces an artifact presented as immutable, privacy-safe CI evidence, a tampered record can forge report content and evidence links.

**Fix:** Make `validateRecord` perform full per-kind semantic validation (or re-normalize each record) before rendering, including `immutableUrl` for URL fields and timestamp/integer validation. Additionally escape or reject `]`, `(`, `)`, and line breaks in link destinations rather than interpolating untrusted URL strings.

---

_Reviewed: 2026-08-12T17:56:43Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
