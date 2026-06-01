---
phase: 162-close-gap-rel-01-rel-03-linked-release-proof
plan: "03"
subsystem: docs
tags:
  - linked-release
  - proof-verification
  - release-notes
  - documentation
dependency_graph:
  requires:
    - 162-01
  provides:
    - Reconciled release docs for Phase 159 completion
  affects:
    - accrue/guides/release-notes.md
    - scripts/ci/README.md
    - RELEASING.md
tech_stack:
  added: []
  patterns:
    - maintainer-runbook
    - release-notes-story
key_files:
  created: []
  modified:
    - accrue/CHANGELOG.md
    - accrue_admin/CHANGELOG.md
    - accrue_portal/CHANGELOG.md
    - accrue/guides/release-notes.md
    - scripts/ci/README.md
    - RELEASING.md
metrics:
  duration: 15
  completed_date: 2026-06-01
key_decisions:
  - Document the recovery append path in the CI map to prevent uncontrolled manual publish retries.
  - Retain the Phase 159 ledger as the singular source of canonical release truth, with maintainer docs pointing back to it rather than establishing new proof records.
---

# Phase 162 Plan 03: Linked Release Artifact Reconciliation Summary

**Goal:** Reconcile public release mirrors and maintainer release docs to the exact proof-backed linked release line without weakening the canonical-ledger rule.

## Execution Details
- Reconciled `accrue/guides/release-notes.md` to document the 1.4.0 target release story, maintaining its status as a mirror rather than an authoritative source.
- Verified that `accrue/CHANGELOG.md`, `accrue_admin/CHANGELOG.md`, and `accrue_portal/CHANGELOG.md` exactly align with the 1.4.0 proof-backed line.
- Updated `scripts/ci/README.md` to reference the Phase 159 ledger for authoritative proof and updated the triage advice for `capture_linked_release_proof.sh` to enforce the canonical structured recovery path.
- Updated `RELEASING.md` with the verified proof-backed workflow date and reinforced the canonical-ledger recovery path for partial Hex publish failures.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None

## Threat Flags
None
## Self-Check: PASSED
