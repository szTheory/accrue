---
phase: 120-release-contract-audit
plan: 03
subsystem: ci
tags: [release, verifier, ci, shift-left]

# Dependency graph
requires:
  - phase: 120-release-contract-audit
    provides: aligned three-package runbook and workflows from Plan 02
provides:
  - Scope-aware release contract verifier bundle
  - Merge-blocking CI wiring for the linked release contract
affects: [phase-121, docs contracts, release CI]

# Tech tracking
tech-stack:
  added: []
  patterns: [bash-release-verifier, merge-blocking release-contract lane]

key-files:
  created:
    - scripts/ci/verify_release_contract.sh
  modified:
    - scripts/ci/verify_release_manifest_alignment.sh
    - scripts/ci/verify_package_docs.sh
    - .github/workflows/ci.yml

key-decisions:
  - "Enforce the release contract with small grep/jq assertions instead of broad parsers."
  - "Extend the existing `release-manifest-ssot` job rather than inventing a new CI lane."
  - "Shift the three-package decision left into docs and manifest verifiers so future drift fails before release day."

requirements-completed: [REL-09, PPX-15]

# Metrics
duration: ~25m
completed: 2026-05-07
---

# Phase 120 Plan 03: Make the release contract executable

**Phase 120 now treats release truth as a CI invariant: the manifest, linked components, runbook, automated publish workflow, and manual recovery workflow must all agree on the same three-package contract or CI fails.**

## Accomplishments
- Added `scripts/ci/verify_release_contract.sh` to assert the linked three-package scope, publish ordering, portal recovery path, and maintainer-facing runbook wording.
- Extended `scripts/ci/verify_release_manifest_alignment.sh` so it verifies all three package versions and checks that manifest keys match the linked release component set.
- Extended `scripts/ci/verify_package_docs.sh` so maintainers cannot silently drift `RELEASING.md`, `CONTRIBUTING.md`, or `accrue_portal/README.md` back toward a two-package story.
- Wired `bash scripts/ci/verify_release_contract.sh` into the merge-blocking `release-manifest-ssot` job in `.github/workflows/ci.yml`.

## Verification
- `bash scripts/ci/verify_release_manifest_alignment.sh`
- `bash scripts/ci/verify_release_contract.sh`
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`

## Self-Check: PASSED

---
*Phase: 120-release-contract-audit*
*Completed: 2026-05-07*
