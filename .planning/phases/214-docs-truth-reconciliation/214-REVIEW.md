---
phase: 214-docs-truth-reconciliation
reviewed: 2026-07-31T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - CLAUDE.md
  - accrue/CHANGELOG.md
  - accrue/guides/entitlements.md
  - accrue/guides/jobs_to_be_done.md
  - accrue/guides/release-notes.md
  - accrue/lib/accrue/entitlements/stripe_sync.ex
  - accrue/lib/accrue/processor.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue/test/accrue/docs/release_notes_contract_test.exs
  - accrue_admin/CHANGELOG.md
  - accrue_portal/CHANGELOG.md
  - examples/accrue_host/docs/adoption-proof-matrix.md
  - scripts/ci/verify_package_docs.sh
  - scripts/ci/verify_release_notes_contract.sh
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 214: Code Review Report

**Reviewed:** 2026-07-31T00:00:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the documentation reconciliation, entitlement public-surface metadata, and both CI contracts. The focused scripts and their 54 associated tests pass, but the new release-notes contract is hard-coded to a single upcoming release and will reject every subsequent normal linked release.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Release gate permanently rejects the next release after 1.5.0

**File:** `scripts/ci/verify_release_notes_contract.sh:48-52`

**Issue:** The contract accepts only `1.4.0` and `1.5.0`; an aligned stable `1.6.0` (or any later linked version) fails before its changelog/release-note sections are inspected. This gate is run as part of the package documentation/release contract, so the next routine minor or patch release will be blocked unless this phase-specific script is edited first. The test suite only covers the hard-coded `1.5.0` candidate, so it cannot detect that regression.

**Fix:** Derive the release state from changelog structure or pass the expected candidate version explicitly from the release workflow. For example, retain the `Unreleased` validation for the current checked-in release, but in candidate mode use the parsed shared version rather than a fixed `1.5.0` literal; add a fixture for a later aligned version such as `1.6.0`.

---

_Reviewed: 2026-07-31T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
