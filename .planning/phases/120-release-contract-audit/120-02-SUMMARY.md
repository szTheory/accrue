---
phase: 120-release-contract-audit
plan: 02
subsystem: release
tags: [release, docs, workflow, portal]

# Dependency graph
requires:
  - phase: 120-release-contract-audit
    provides: explicit `promote-three-package` scope token from Plan 01
provides:
  - Maintainer runbook aligned to the three-package linked release contract
  - Manual recovery workflow aligned to the automated publish scope and order
affects: [120-03, release docs, release workflows, maintainer DX]

# Tech tracking
tech-stack:
  added: []
  patterns: [linked-release-contract, same-workflow publish chain]

key-files:
  created: []
  modified:
    - RELEASING.md
    - CONTRIBUTING.md
    - .github/workflows/publish-hex.yml
    - accrue_portal/README.md

key-decisions:
  - "Promote `accrue_portal` to a first-class maintainer-facing release artifact instead of leaving it implied only by automation."
  - "Keep publish ordering explicit and stable: `accrue` before `accrue_admin` before `accrue_portal`."
  - "Treat manual recovery as part of the public release contract, not a separate undocumented exception lane."

requirements-completed: [REL-09, PPX-15]

# Metrics
duration: ~35m
completed: 2026-05-07
---

# Phase 120 Plan 02: Align the runbook and workflows

**The maintainer release story now tells one honest three-package truth: `accrue`, `accrue_admin`, and `accrue_portal` are released together, published in order, and recoverable through a matching manual workflow.**

## Accomplishments
- Rewrote `RELEASING.md` so the linked release contract, review checklist, fallback path, and bootstrap appendix all include `accrue_portal`.
- Updated `.github/workflows/publish-hex.yml` so manual recovery now supports `accrue_portal` with the same explicit ref/version checks and publish-mode env wiring as the other packages.
- Updated `CONTRIBUTING.md` and `accrue_portal/README.md` so maintainer setup and package-facing docs no longer imply a two-package suite.

## Verification
- `bash scripts/ci/verify_release_manifest_alignment.sh`
- `bash scripts/ci/verify_release_contract.sh`
- `bash scripts/ci/verify_package_docs.sh`

## Self-Check: PASSED

---
*Phase: 120-release-contract-audit*
*Completed: 2026-05-07*
