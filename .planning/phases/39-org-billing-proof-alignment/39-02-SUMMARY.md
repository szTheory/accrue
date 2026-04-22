---
phase: 39-org-billing-proof-alignment
plan: 02
subsystem: infra
tags: [ci, bash, org-09]

requires:
  - phase: 39-org-billing-proof-alignment
    provides: ORG-09 matrix literals in adoption-proof-matrix.md
provides:
  - Merge-blocking `verify_adoption_proof_matrix.sh` in host-integration
  - Contributor ORG gates table + triage in scripts/ci/README.md
affects: []

tech-stack:
  added: []
  patterns:
    - "Bash substring gate mirroring verify_verify01 for matrix SSOT"

key-files:
  created:
    - scripts/ci/verify_adoption_proof_matrix.sh
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/README.md

key-decisions:
  - "host-integration runs ORG-09 script immediately after VERIFY-01 README contract step."

patterns-established: []

requirements-completed: [ORG-09]

duration: 10min
completed: 2026-04-21
---

# Phase 39 — Plan 02

**ORG-09 matrix literals are enforced by a new bash verifier in `host-integration`, with contributor-facing ORG gate documentation.**

## Self-Check: PASSED

- `bash scripts/ci/verify_adoption_proof_matrix.sh` returns OK on clean tree.

## Accomplishments

- Added `scripts/ci/verify_adoption_proof_matrix.sh` with `require_substring` checks aligned to Plan 01 needles.
- Wired step **ORG-09 adoption proof matrix literals** into `host-integration`.
- Documented ORG-09 in `scripts/ci/README.md` with triage mapping `verify_adoption_proof_matrix:` → ORG-09.

## Deviations

- None.
