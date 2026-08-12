---
phase: 226-ci-baseline-proof-semantics
reviewed: 2026-08-12T15:43:15Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - accrue/test/accrue/live_proof_formatter_test.exs
  - accrue/test/support/live_proof_formatter.ex
  - accrue/test/test_helper.exs
  - examples/accrue_host/README.md
  - examples/accrue_host/package.json
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
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 226: Code Review Report

**Reviewed:** 2026-08-12T15:43:15Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The CI evidence and provider-proof changes were reviewed, including the attempt-specific Actions fetch, privacy-safe records, trusted runner classification, and bounded historical DAG logic. The supplied fixture suites pass, but the new collector is not fail-closed for all unknown historical topology or job identities. The host wrapper also bypasses its diagnostic contract when its initial database readiness check fails.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Historical DAG compatibility accepts unaudited pre-cutoff topology

**Classification:** BLOCKER

**File:** `scripts/ci/collect_ci_baseline.mjs:253-258`

**Issue:** A compatibility exception is granted solely from repository name, `created_at` being before the cutoff, event name, and a job-name prefix. It never verifies the immutable workflow revision that the run actually executed. Consequently, any unknown old `szTheory/accrue` run with a matching display name and a missing prerequisite is accepted as one of the audited historical workflow generations. This contradicts the stated bounded-inventory/fail-closed contract and can create durable timing/DAG evidence from an incompatible topology.

**Fix:** Bind every compatibility row to an immutable workflow identity. Fetch and parse the workflow at the run's `head_sha` (or use a verified immutable workflow revision supplied by the API), and apply an exception only when that revision and the exact job identity match the allowlist; otherwise retain the missing prerequisite and fail collection. Add fixtures for an unknown pre-cutoff revision and a same-name job that must be rejected.

### CR-02: Prefix matching turns unknown jobs into trusted runner contracts

**Classification:** BLOCKER

**File:** `scripts/ci/collect_ci_baseline.mjs:322-330`

**Issue:** `workflowRunnerImage` accepts any normalized name beginning with a workflow job ID or display name. For example, the current implementation classifies `Host integration (required deterministic gate) malicious-shard` and `Release gate attacker` as `github-hosted/ubuntu-24.04`, rather than rejecting them. The same broad prefix strategy is used by `workflowNeeds` at lines 264-268 and historical matching at line 257. This makes unknown jobs look like trusted, declared jobs and defeats the required fail-closed runner/topology boundary; their measurements can enter cohort evidence under an incorrect runner class.

**Fix:** Use exact normalized identities by default. Where a job legitimately has matrix-generated names, enumerate the expected identities or accept only a narrowly defined matrix suffix (for example, a shard-number pattern) associated with that one job. Reject every other suffix and add regression fixtures for spoofed prefix names.

## Warnings

### WR-01: Postgres readiness failure skips the setup diagnostic entirely

**Classification:** WARNING

**File:** `scripts/ci/accrue_host_uat.sh:28-35`

**Issue:** With `set -e`, a nonzero `pg_isready` exits the wrapper before `mix verify.full` and before the failure branch that emits/renders `host_gate_failure`. The setup-facts artifact is therefore empty and no stable `SETUP_CODE`/owner/repair command is printed for a common host-integration prerequisite failure, despite this script being the diagnostic boundary.

**Fix:** Run `pg_isready` under an explicit status check. On failure, emit the appropriate fixed registry code (for example `fixture_or_database`), render it, print `FAILED_GATE=host-integration`, and exit with the captured status. Add a fixture that shadows `pg_isready` to fail and asserts the fact and rendered diagnostic.

---

_Reviewed: 2026-08-12T15:43:15Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
