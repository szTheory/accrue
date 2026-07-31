---
phase: 214-docs-truth-reconciliation
reviewed: 2026-07-31T04:06:00Z
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 214: Code Review Report

**Reviewed:** 2026-07-31T04:06:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the documentation/release contract changes and the advisory entitlement refresh public seam in context. Focused contract scripts and tests pass at the current version, but the new release verifier prevents the next Release Please version bump from passing CI.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The release contract rejects the Release Please version it is meant to ship

**File:** `scripts/ci/verify_release_notes_contract.sh:33-35`
**Issue:** The verifier requires all package `@version` values to be exactly `1.4.0`. Release Please updates those values to `1.5.0` before the release PR is validated, so that PR will fail this script even when all packages remain aligned and the generated `1.5.0` changelog sections are correct. The existing ExUnit coverage only runs against the current `1.4.0` fixture, so it cannot catch the post-bump failure. This blocks the intended release pipeline.
**Fix:** Remove the fixed-version assertions and validate the invariant that matters: all three versions match and the release notes contain the discovered current version. Add a fixture test with all three `mix.exs` files set to `1.5.0` (and a generated numbered changelog section) to prove the Release Please state passes.

```bash
[[ "$accrue_version" == "$accrue_admin_version" ]] || fail "accrue and accrue_admin versions diverged"
[[ "$accrue_version" == "$accrue_portal_version" ]] || fail "accrue and accrue_portal versions diverged"
# Do not pin the current version: Release Please advances it in the release PR.
```

---

_Reviewed: 2026-07-31T04:06:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
