---
phase: 160-stable-core-public-positioning
reviewed: 2026-05-31T21:39:42Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - .github/workflows/ci.yml
  - README.md
  - accrue/README.md
  - accrue/guides/first_hour.md
  - accrue/guides/jobs_to_be_done.md
  - accrue/guides/maturity-and-maintenance.md
  - accrue/guides/release-notes.md
  - accrue_admin/README.md
  - accrue_portal/README.md
  - examples/accrue_host/README.md
  - examples/accrue_host/docs/adoption-proof-matrix.md
  - scripts/ci/README.md
  - scripts/ci/verify_release_notes_contract.sh
  - scripts/ci/verify_stable_core_posture.sh
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---
# Phase 160: Code Review Report

**Reviewed:** 2026-05-31T21:39:42Z  
**Depth:** standard  
**Files Reviewed:** 14  
**Status:** issues_found

## Summary

Review covered Phase 160 docs/CI/verifier surfaces with emphasis on CI contract integrity and drift resistance. No exploitable security issue was found, but four verifier/docs contract defects can permit stale public truth or create operator confusion.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Root README documents an incomplete `docs-contracts-shift-left` script set

**Classification:** WARNING  
**File:** `README.md:11`  
**Issue:** The README enumerates the shift-left scripts but omits `verify_stable_core_posture.sh` and `verify_release_notes_contract.sh`, both of which are now in `docs-contracts-shift-left` (`.github/workflows/ci.yml:73-77`). This creates immediate docs drift in the primary contributor entrypoint and weakens triage accuracy.
**Fix:**
Update the script list in `README.md` to include both:
- `bash scripts/ci/verify_stable_core_posture.sh`
- `bash scripts/ci/verify_release_notes_contract.sh`

### WR-02: `verify_release_notes_contract.sh` can false-pass without section placement correctness

**Classification:** WARNING  
**File:** `scripts/ci/verify_release_notes_contract.sh:42-44`  
**Issue:** The contract only enforces that the current version heading appears at least twice globally. This can pass when both headings are in the wrong section (for example, duplicated under `## accrue`), while `## accrue_admin` for the current release is missing.
**Fix:**
Scope checks to section ranges instead of global count, e.g. verify one heading exists between `## accrue` and `## accrue_admin`, and one exists after `## accrue_admin`.

### WR-03: `verify_stable_core_posture.sh` under-enforces release-note linkage while claiming stronger contract

**Classification:** WARNING  
**File:** `scripts/ci/verify_stable_core_posture.sh:67`  
**Issue:** The script accepts any one of `maturity-and-maintenance.md|first_hour.md|jobs_to_be_done.md` in release notes, but failure messaging in `verify_release_notes_contract.sh` and POS-03 framing indicates stronger canonical linkage expectations. This permissive `OR` allows partial drift to pass.
**Fix:**
Replace the single alternation regex with separate required checks for each expected anchor, or explicitly relax/document the contract everywhere to match the current implementation.

### WR-04: Duplicate tail block in release-notes guide introduces public-doc inconsistency

**Classification:** WARNING  
**File:** `accrue/guides/release-notes.md:121-123`  
**Issue:** The final “How we version” lines are duplicated (`adopt incrementally...` and `When in doubt...` repeated). This is a quality defect in a release-facing guide and can trigger future drift or mistaken edits.
**Fix:**
Remove the duplicated lines at the end of the file so the section appears once.

---

_Reviewed: 2026-05-31T21:39:42Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
