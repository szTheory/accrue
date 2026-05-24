---
phase: 120-release-contract-audit
plan: 01
subsystem: planning
tags: [release, contract, scope, portal]

# Dependency graph
requires: []
provides:
  - Explicit Phase 120 release-scope token for downstream implementation
  - Maintainer rationale tying the release contract to current repo truth
affects: [120-02, 120-03, release docs, release workflows]

# Tech tracking
tech-stack:
  added: []
  patterns: [decision-token, scope-lock]

key-files:
  created:
    - .planning/phases/120-release-contract-audit/120-01-SUMMARY.md
  modified: []

key-decisions:
  - "Choose `promote-three-package` as the public release contract."
  - "Treat `accrue_portal` as a first-class published sibling package rather than a half-public sidecar."
  - "Align maintainer docs and recovery workflows to the existing automation and repo front-door story instead of hiding portal."

requirements-completed: [REL-09, PPX-15]

# Metrics
duration: ~30m
completed: 2026-05-07
---

# Phase 120 Plan 01: Freeze the release-scope decision

**Phase 120 is locked to `promote-three-package`: the public release contract is `accrue` + `accrue_admin` + `accrue_portal`, published in that order and documented as one coherent package suite.**

## Evidence
- `release-please-config.json` and `.release-please-manifest.json` already include `accrue_portal`.
- `.github/workflows/release-please.yml` already automates `publish-accrue-portal` after `publish-accrue-admin`.
- Root and package docs already present `accrue_portal` as a mounted customer-facing package, not an internal stub.
- `curl -fsSL https://hex.pm/api/packages/accrue_portal` returned `404`, so the release gap is public-publish truth, not lack of product intent.

## Decision
- Token: `promote-three-package`
- Reason: least surprise favors making the published contract match the existing repo story, automation, package boundaries, and host-facing router surface.

## Self-Check: PASSED

---
*Phase: 120-release-contract-audit*
*Completed: 2026-05-07*
